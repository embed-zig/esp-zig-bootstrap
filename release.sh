#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
	cat <<'EOF'
Usage: ./release.sh <version> <target> <mcpu> --build-number <n> [--publish]

Examples:
  ./release.sh 0.15.2 aarch64-macos-none baseline --build-number 1
  ./release.sh 0.16.0 aarch64-macos-none baseline --build-number r1 --publish

Behavior:
  1) Package .out/zig-<target>-<mcpu> into release/v<version-rN>/zig-v<version-rN>-<target>-<mcpu>.tar.xz
  2) Generate/refresh release/v<version-rN>/SHA256SUMS
  3) (optional) Publish via gh release create v<version-rN>
EOF
}

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

if [[ $# -lt 3 ]]; then
	usage >&2
	exit 1
fi

VERSION="$1"
TARGET="$2"
MCPU="$3"
PUBLISH=false
BUILD_NUMBER=""

shift 3

while [[ $# -gt 0 ]]; do
	case "$1" in
	--publish)
		PUBLISH=true
		shift
		;;
	--build-number)
		[[ $# -ge 2 ]] || die "Error: --build-number requires a value"
		if [[ ! "$2" =~ ^r?[0-9]+$ ]]; then
			die "Error: build number must be digits or r<digits>"
		fi
		BUILD_NUMBER="${2#r}"
		shift 2
		;;
	*)
		die "Error: unknown option '$1'"
		;;
	esac
done

if [[ -z "$BUILD_NUMBER" ]]; then
	die "Error: --build-number is required; releases must use v<version>-rN tags"
fi

VERSION_LABEL="v${VERSION}-r${BUILD_NUMBER}"

VERSION_DIR="$SCRIPT_DIR/$VERSION"
OUT_NAME="zig-${TARGET}-${MCPU}"
OUT_DIR="$SCRIPT_DIR/.out/$OUT_NAME"
ARTIFACT_NAME="zig-${VERSION_LABEL}-${TARGET}-${MCPU}.tar.xz"
RELEASE_DIR="$SCRIPT_DIR/release/$VERSION_LABEL"
ARTIFACT_PATH="$RELEASE_DIR/$ARTIFACT_NAME"
CHECKSUM_PATH="$RELEASE_DIR/SHA256SUMS"

[[ -d "$VERSION_DIR" ]] || die "Error: version directory '$VERSION' does not exist"
[[ -d "$OUT_DIR" ]] || die "Error: build output '$OUT_DIR' not found, run bootstrap first"

mkdir -p "$RELEASE_DIR"

printf 'Packaging %s -> %s\n' "$OUT_DIR" "$ARTIFACT_PATH"
tar -C "$SCRIPT_DIR/.out" -cJf "$ARTIFACT_PATH" "$OUT_NAME"

printf 'Generating checksum file: %s\n' "$CHECKSUM_PATH"
(
	cd "$RELEASE_DIR"
	shasum -a 256 "$ARTIFACT_NAME" >SHA256SUMS
)

printf 'Package ready:\n'
printf '  - %s\n' "$ARTIFACT_PATH"
printf '  - %s\n' "$CHECKSUM_PATH"

if [[ "$PUBLISH" == true ]]; then
	command -v gh >/dev/null 2>&1 || die "Error: gh CLI is required for --publish"

	TAG="$VERSION_LABEL"
	printf 'Publishing release %s ...\n' "$TAG"
	gh release create "$TAG" "$ARTIFACT_PATH" "$CHECKSUM_PATH" \
		--title "$TAG" \
		--notes "Manual local build release for ${VERSION_LABEL} (${TARGET}/${MCPU})."
	printf 'Release published: %s\n' "$TAG"
fi
