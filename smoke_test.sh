#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"
TMP_VERSION="smoke-test-tmp"
ROOT_OUT_BACKUP=""

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
	if [[ -n "$ROOT_OUT_BACKUP" && -d "$ROOT_OUT_BACKUP" ]]; then
		rm -rf "$SCRIPT_DIR/.out"
		mv "$ROOT_OUT_BACKUP" "$SCRIPT_DIR/.out"
	fi
}

trap cleanup EXIT

[[ -x "$BOOTSTRAP" ]] || fail "bootstrap.sh is missing or not executable"
[[ -f "$SCRIPT_DIR/0.15.2/llvm-project" ]] || fail "0.15.2/llvm-project missing"
[[ -f "$SCRIPT_DIR/0.15.2/zig-bootstrap" ]] || fail "0.15.2/zig-bootstrap missing"
[[ -f "$SCRIPT_DIR/0.15.2/espressif.patch" ]] || fail "0.15.2/espressif.patch missing"

if [[ -d "$SCRIPT_DIR/.out" ]]; then
	ROOT_OUT_BACKUP="$SCRIPT_DIR/.out.smoke-backup.$$"
	rm -rf "$ROOT_OUT_BACKUP"
	mv "$SCRIPT_DIR/.out" "$ROOT_OUT_BACKUP"
fi

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
mkdir -p "$SCRIPT_DIR/.out/zig-aarch64-macos-none-baseline"
mkdir -p "$SCRIPT_DIR/.out/zig-x86_64-macos-none-baseline"

"$BOOTSTRAP" clean "$TMP_VERSION" aarch64-macos-none baseline >/dev/null

[[ ! -e "$SCRIPT_DIR/$TMP_VERSION/.build-aarch64-macos-none-baseline" ]] || fail ".build-* should be removed by clean"
[[ ! -e "$SCRIPT_DIR/$TMP_VERSION/.out/zig-aarch64-macos-none-baseline" ]] || fail "version .out target should be removed by clean"
[[ ! -e "$SCRIPT_DIR/.out/zig-aarch64-macos-none-baseline" ]] || fail "root .out target should be removed by clean"
[[ -d "$SCRIPT_DIR/$TMP_VERSION/.out/zig-x86_64-macos-none-baseline" ]] || fail "other version target should be kept"
[[ -d "$SCRIPT_DIR/.out/zig-x86_64-macos-none-baseline" ]] || fail "other root target should be kept"
[[ -d "$SCRIPT_DIR/$TMP_VERSION/.downloads" ]] || fail ".downloads should remain after clean"

printf 'smoke test passed\n'
