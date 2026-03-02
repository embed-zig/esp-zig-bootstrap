#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

list_versions() {
	local found=false

	for dir in "$SCRIPT_DIR"/*/; do
		[[ -d "$dir" ]] || continue
		local name
		name="$(basename "$dir")"
		if [[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			printf '  %s\n' "$name"
			found=true
		fi
	done

	if [[ "$found" == false ]]; then
		printf '  No version folders found\n'
	fi
}

show_usage() {
	cat <<'EOF'
Usage: ./bootstrap.sh <version> <target> <mcpu>
	       ./bootstrap.sh clean <version> <target> <mcpu>

Examples:
  ./bootstrap.sh 0.15.2 aarch64-macos-none baseline
	  ./bootstrap.sh clean 0.15.2 aarch64-linux-gnu baseline

Available versions:
EOF

	list_versions
}

download_file() {
	local url="$1"
	local output="$2"

	if command -v wget >/dev/null 2>&1; then
		wget "$url" -c -O "$output"
		return
	fi

	if command -v curl >/dev/null 2>&1; then
		curl -L "$url" -o "$output"
		return
	fi

	die "Error: neither wget nor curl is available"
}

if [[ $# -eq 0 ]]; then
	show_usage >&2
	exit 1
fi

if [[ "$1" == "clean" ]]; then
	if [[ $# -ne 4 ]]; then
		die "Error: clean requires <version> <target> <mcpu>"
	fi

	VERSION_DIR="$2"
	CLEAN_TARGET="$3"
	CLEAN_MCPU="$4"

	VERSION_PATH="$SCRIPT_DIR/$VERSION_DIR"
	if [[ ! -d "$VERSION_PATH" ]]; then
		die "Error: Version directory '$VERSION_DIR' does not exist"
	fi

	BUILD_DIR="$VERSION_PATH/.build-${CLEAN_TARGET}-${CLEAN_MCPU}"
	VERSION_OUT_DIR="$VERSION_PATH/.out/zig-${CLEAN_TARGET}-${CLEAN_MCPU}"
	ROOT_OUT_DIR="$SCRIPT_DIR/.out/zig-${CLEAN_TARGET}-${CLEAN_MCPU}"

	printf 'Cleaning %s for target=%s mcpu=%s...\n' "$VERSION_DIR" "$CLEAN_TARGET" "$CLEAN_MCPU"

	for dir in "$BUILD_DIR" "$VERSION_OUT_DIR" "$ROOT_OUT_DIR"; do
		if [[ -e "$dir" ]]; then
			printf '  Removing %s...\n' "$dir"
			rm -rf "$dir"
		fi
	done

	printf 'Clean complete!\n'
	exit 0
fi

if [[ $# -ne 3 ]]; then
	show_usage >&2
	exit 1
fi

VERSION_DIR="$1"
TARGET="$2"
MCPU="$3"

VERSION_PATH="$SCRIPT_DIR/$VERSION_DIR"
if [[ ! -d "$VERSION_PATH" ]]; then
	die "Error: Version directory '$VERSION_DIR' does not exist"
fi

cd "$VERSION_PATH"

printf 'Working in: %s\n\n' "$VERSION_PATH"

printf '=== Step 1: Downloading and Extracting ===\n'
mkdir -p .downloads
pushd .downloads >/dev/null

if [[ ! -d llvm-project ]]; then
	llvm_url="$(sed -n '1p' ../llvm-project)"
	[[ -n "$llvm_url" ]] || die "Error: ./llvm-project source definition is empty"

	printf 'Downloading llvm-project...\n'
	download_file "$llvm_url" llvm-project.tar.gz
	mkdir -p llvm-project
	tar -xf llvm-project.tar.gz --strip-components=1 -C llvm-project
else
	printf 'Using cached llvm-project\n'
fi

if [[ ! -d zig-bootstrap ]]; then
	zig_source="$(sed -n '1p' ../zig-bootstrap)"
	zig_ref="$(sed -n '2p' ../zig-bootstrap)"

	[[ -n "$zig_source" ]] || die "Error: ./zig-bootstrap source definition is empty"

	if [[ "$zig_source" == *.tar.gz ]]; then
		printf 'Downloading zig-bootstrap via tarball...\n'
		download_file "$zig_source" zig-bootstrap.tar.gz
		mkdir -p zig-bootstrap
		tar -xf zig-bootstrap.tar.gz --strip-components=1 -C zig-bootstrap
	else
		[[ -n "$zig_ref" ]] || die "Error: git source requires ref on line 2 in ./zig-bootstrap"
		printf 'Cloning zig-bootstrap (shallow) from %s tag: %s...\n' "$zig_source" "$zig_ref"
		git clone --depth 1 --branch "$zig_ref" "$zig_source" zig-bootstrap
	fi
else
	printf 'Using cached zig-bootstrap\n'
fi

popd >/dev/null

printf '\n=== Step 2: Creating build folder ===\n'
BUILD_DIR=".build-${TARGET}-${MCPU}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

pushd "$BUILD_DIR" >/dev/null

cp -R ../.downloads/zig-bootstrap/zig zig
cp -R ../.downloads/zig-bootstrap/zlib zlib
cp -R ../.downloads/zig-bootstrap/zstd zstd
cp -R ../.downloads/zig-bootstrap/build build
cp -R ../.downloads/llvm-project/llvm llvm
cp -R ../.downloads/llvm-project/clang clang
cp -R ../.downloads/llvm-project/lld lld
cp -R ../.downloads/llvm-project/cmake cmake

printf '\n=== Step 3: Applying patch to %s ===\n' "$BUILD_DIR"
patch -p1 <../espressif.patch
printf 'patch applied successfully\n'

printf '\n=== Step 4: Building Zig ===\n'

if command -v nproc >/dev/null 2>&1; then
	CPU_CORES="$(nproc)"
elif command -v sysctl >/dev/null 2>&1; then
	CPU_CORES="$(sysctl -n hw.ncpu)"
else
	CPU_CORES=4
fi

if [[ "$CPU_CORES" -gt 8 ]]; then
	CPU_CORES=8
fi

export CMAKE_BUILD_PARALLEL_LEVEL="$CPU_CORES"
printf 'Using %s parallel jobs for compilation\n' "$CPU_CORES"

export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR=""
./build "$TARGET" "$MCPU"

popd >/dev/null

printf '\n=== Copying output to .out/ ===\n'
ROOT_OUT_DIR="$SCRIPT_DIR/.out"
ROOT_OUT_PATH="$ROOT_OUT_DIR/zig-${TARGET}-${MCPU}"
mkdir -p "$ROOT_OUT_DIR"
rm -rf "$ROOT_OUT_PATH"
cp -R "$BUILD_DIR/out/zig-${TARGET}-${MCPU}" "$ROOT_OUT_DIR/"

printf '\n=== Build Complete ===\n'
printf 'Output: %s\n' "$ROOT_OUT_PATH"
ls -la "$ROOT_OUT_PATH"
