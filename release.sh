#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
	cat <<'EOF'
Usage: ./release.sh <version> <target> <mcpu> [--publish]

Examples:
  ./release.sh 0.15.2 aarch64-macos-none baseline
  ./release.sh 0.15.2 aarch64-macos-none baseline --publish

Behavior:
  1) Package .out/zig-<target>-<mcpu> into release/<version>/zig-<version>-<target>-<mcpu>.tar.xz
  2) Generate/refresh release/<version>/SHA256SUMS
  3) (optional) Publish via gh release create v<version>
EOF
}

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
	usage >&2
	exit 1
fi

VERSION="$1"
TARGET="$2"
MCPU="$3"
PUBLISH=false

if [[ $# -eq 4 ]]; then
	if [[ "$4" != "--publish" ]]; then
		die "Error: unknown option '$4'"
	fi
	PUBLISH=true
fi

VERSION_DIR="$SCRIPT_DIR/$VERSION"
OUT_NAME="zig-${TARGET}-${MCPU}"
OUT_DIR="$SCRIPT_DIR/.out/$OUT_NAME"
ARTIFACT_NAME="zig-${VERSION}-${TARGET}-${MCPU}.tar.xz"
RELEASE_DIR="$SCRIPT_DIR/release/$VERSION"
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

	TAG="v${VERSION}"
	printf 'Publishing release %s ...\n' "$TAG"
	gh release create "$TAG" "$ARTIFACT_PATH" "$CHECKSUM_PATH" \
		--title "$TAG" \
		--notes "Manual local build release for ${VERSION} (${TARGET}/${MCPU})."
	printf 'Release published: %s\n' "$TAG"
fi
