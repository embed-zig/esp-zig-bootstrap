#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"
TMP_VERSION="smoke-test-tmp"

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_file_contains() {
	local file="$1"
	local pattern="$2"
	if ! grep -q "$pattern" "$file"; then
		fail "expected '$pattern' in $(basename "$file")"
	fi
}

cleanup() {
	rm -rf "$SCRIPT_DIR/$TMP_VERSION"
}

trap cleanup EXIT

[[ -x "$BOOTSTRAP" ]] || fail "bootstrap.sh is missing or not executable"
[[ -f "$SCRIPT_DIR/0.15.2/llvm-project" ]] || fail "0.15.2/llvm-project missing"
[[ -f "$SCRIPT_DIR/0.15.2/zig-bootstrap" ]] || fail "0.15.2/zig-bootstrap missing"
[[ -d "$SCRIPT_DIR/0.15.2/patches" ]] || fail "0.15.2/patches missing"
compgen -G "$SCRIPT_DIR/0.15.2/patches/*.patch" >/dev/null || fail "0.15.2/patches has no patch files"

usage_log="$(mktemp)"
if "$BOOTSTRAP" >"$usage_log" 2>&1; then
	fail "bootstrap.sh without args should fail"
fi
assert_file_contains "$usage_log" "Usage:"
rm -f "$usage_log"

missing_log="$(mktemp)"
if "$BOOTSTRAP" 0.15.3 aarch64-macos-none baseline >"$missing_log" 2>&1; then
	fail "invalid version should fail"
fi
assert_file_contains "$missing_log" "Version directory"
rm -f "$missing_log"

mkdir -p "$SCRIPT_DIR/$TMP_VERSION/.build-aarch64-macos-none-baseline"
mkdir -p "$SCRIPT_DIR/$TMP_VERSION/.out/zig-aarch64-macos-none-baseline"
mkdir -p "$SCRIPT_DIR/$TMP_VERSION/.out/zig-x86_64-macos-none-baseline"
mkdir -p "$SCRIPT_DIR/$TMP_VERSION/.downloads"

"$BOOTSTRAP" clean "$TMP_VERSION" aarch64-macos-none baseline >/dev/null

[[ ! -e "$SCRIPT_DIR/$TMP_VERSION/.build-aarch64-macos-none-baseline" ]] || fail ".build-* should be removed by clean"
[[ ! -e "$SCRIPT_DIR/$TMP_VERSION/.out/zig-aarch64-macos-none-baseline" ]] || fail "version .out target should be removed by clean"
[[ -d "$SCRIPT_DIR/$TMP_VERSION/.out/zig-x86_64-macos-none-baseline" ]] || fail "other version target should be kept"
[[ -d "$SCRIPT_DIR/$TMP_VERSION/.downloads" ]] || fail ".downloads should remain after clean"

printf 'smoke test passed\n'
