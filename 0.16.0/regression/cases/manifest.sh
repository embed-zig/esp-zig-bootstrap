#!/usr/bin/env bash

MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CASE_IDS=(
	xtensa-bool-build-or
	xtensa-bool-bitwise
	xtensa-bool-insert
	xtensa-bool-return
	xtensa-bool-scalar-select
	xtensa-bool-phi-spill
	xtensa-bool-fp-select
	xtensa-bool-fp-vector-cmp
	xtensa-bool-v3-legalize
	xtensa-bool-reduce-odd
	xtensa-bool-load-hi-subvector
	xtensa-bool-v1-call
	xtensa-bool-extract
	xtensa-bool-extend-extract
	xtensa-bool-fixup-v4
	xtensa-bool-fixup-v4-high-group
	xtensa-bool-negated-extract
	xtensa-bool-v2-roundtrip
	xtensa-bool-v2-vselect-shuffle
	xtensa-bool-shuffle-select
	xtensa-bool-shuffle
	xtensa-bool-v8-bitcast
	xtensa-bool-vselect
	xtensa-scalar-bool-return
	xtensa-scalar-bool-return-inverted
	xtensa-scalar-bool-export-return
	xtensa-scalar-bool-not-return
	xtensa-scalar-bool-call
	xtensa-scalar-bool-call-inverted
	xtensa-frame-scavenge
	xtensa-frame-narrow-offsets
	xtensa-l32r-const-island
)

case_exists() {
	local case_id="$1"

	case "$case_id" in
	xtensa-bool-build-or | \
	xtensa-bool-bitwise | \
	xtensa-bool-insert | \
	xtensa-bool-return | \
	xtensa-bool-scalar-select | \
	xtensa-bool-phi-spill | \
	xtensa-bool-fp-select | \
	xtensa-bool-fp-vector-cmp | \
	xtensa-bool-v3-legalize | \
	xtensa-bool-reduce-odd | \
	xtensa-bool-load-hi-subvector | \
	xtensa-bool-v1-call | \
	xtensa-bool-extract | \
	xtensa-bool-extend-extract | \
	xtensa-bool-fixup-v4 | \
	xtensa-bool-fixup-v4-high-group | \
	xtensa-bool-negated-extract | \
	xtensa-bool-v2-roundtrip | \
	xtensa-bool-v2-vselect-shuffle | \
	xtensa-bool-shuffle-select | \
	xtensa-bool-shuffle | \
	xtensa-bool-v8-bitcast | \
	xtensa-bool-vselect | \
	xtensa-scalar-bool-return | \
	xtensa-scalar-bool-return-inverted | \
	xtensa-scalar-bool-export-return | \
	xtensa-scalar-bool-not-return | \
	xtensa-scalar-bool-call | \
	xtensa-scalar-bool-call-inverted | \
	xtensa-frame-scavenge | \
	xtensa-frame-narrow-offsets | \
	xtensa-l32r-const-island)
		return 0
		;;
	esac

	return 1
}

case_source() {
	local case_id="$1"
	printf '%s/%s.zig\n' "$MANIFEST_DIR" "$case_id"
}

case_patches() {
	local case_id="$1"

	case "$case_id" in
	xtensa-bool-build-or)
		printf '090'
		;;
	xtensa-bool-bitwise)
		printf '090'
		;;
	xtensa-bool-insert)
		printf '090'
		;;
	xtensa-bool-return)
		printf '090'
		;;
	xtensa-bool-scalar-select)
		printf '090'
		;;
	xtensa-bool-phi-spill)
		printf '116'
		;;
	xtensa-bool-fp-select)
		printf '090'
		;;
	xtensa-bool-fp-vector-cmp)
		printf '090'
		;;
	xtensa-bool-v3-legalize)
		printf '090'
		;;
	xtensa-bool-reduce-odd)
		printf '090'
		;;
	xtensa-bool-load-hi-subvector)
		printf '090'
		;;
	xtensa-bool-v1-call)
		printf '090,100'
		;;
	xtensa-bool-extract)
		printf '090,100'
		;;
	xtensa-bool-extend-extract)
		printf '090'
		;;
	xtensa-bool-fixup-v4)
		printf '110'
		;;
	xtensa-bool-fixup-v4-high-group)
		printf '110,117'
		;;
	xtensa-bool-negated-extract)
		printf '090'
		;;
	xtensa-bool-v2-roundtrip)
		printf '090,100'
		;;
	xtensa-bool-v2-vselect-shuffle)
		printf '100'
		;;
	xtensa-bool-shuffle-select)
		printf '090'
		;;
	xtensa-bool-shuffle)
		printf '090'
		;;
	xtensa-bool-v8-bitcast)
		printf '090'
		;;
	xtensa-bool-vselect)
		printf '090'
		;;
	xtensa-scalar-bool-return)
		printf '126'
		;;
	xtensa-scalar-bool-return-inverted)
		printf '126'
		;;
	xtensa-scalar-bool-export-return)
		printf '126'
		;;
	xtensa-scalar-bool-not-return)
		printf '126'
		;;
	xtensa-scalar-bool-call)
		printf '126'
		;;
	xtensa-scalar-bool-call-inverted)
		printf '126'
		;;
	xtensa-frame-scavenge)
		printf '115,120'
		;;
	xtensa-frame-narrow-offsets)
		printf '115,120'
		;;
	xtensa-l32r-const-island)
		printf '125'
		;;
	esac
}

case_description() {
	local case_id="$1"

	case "$case_id" in
	xtensa-bool-build-or)
		printf 'build_vector plus boolean OR lowering'
		;;
	xtensa-bool-bitwise)
		printf 'v2 boolean AND plus v4 boolean XOR lowering'
		;;
	xtensa-bool-insert)
		printf 'lane insertion into @Vector(4, bool)'
		;;
	xtensa-bool-return)
		printf 'v2/v4 bool-vector return values rebuilt from scalarized i2/i4 masks'
		;;
	xtensa-bool-scalar-select)
		printf 'scalar-condition SELECT and SELECT_CC lowering for v1/v2/v4 bool vectors'
		;;
	xtensa-bool-phi-spill)
		printf 'Debug multi-block v2/v4 bool-vector phi spill and reload path'
		;;
	xtensa-bool-fp-select)
		printf 'float-compare scalar selects of v2/v3/v4 bool vectors'
		;;
	xtensa-bool-fp-vector-cmp)
		printf 'vector float compares feeding bool-vector pack reduce extract and select'
		;;
	xtensa-bool-v3-legalize)
		printf 'custom widening of @Vector(3, bool) through Xtensa small-bool lowering'
		;;
	xtensa-bool-reduce-odd)
		printf 'odd-width bool-vector reductions after extract_subvector legalization'
		;;
	xtensa-bool-load-hi-subvector)
		printf 'Debug high-half extract_subvector from a loaded bool vector'
		;;
	xtensa-bool-v1-call)
		printf 'v1 boolean vector call and return path in Debug and optimized builds'
		;;
	xtensa-bool-extract)
		printf 'lane extraction and existing vector_extract patterns'
		;;
	xtensa-bool-extend-extract)
		printf 'extended lane extraction from @Vector(4, bool)'
		;;
	xtensa-bool-fixup-v4)
		printf 'v4 boolean register load/store and fixup path'
		;;
	xtensa-bool-fixup-v4-high-group)
		printf 'Debug high-group BR4 fixup writeback/extract alignment'
		;;
	xtensa-bool-negated-extract)
		printf 'negated extracted lanes and bool-to-int lowering'
		;;
	xtensa-bool-v2-roundtrip)
		printf 'v2 boolean vector insert/extract/or round-trip path'
		;;
	xtensa-bool-v2-vselect-shuffle)
		printf 'v2 bool-vector @select with shuffle-derived arm and BR2 physreg copies'
		;;
	xtensa-bool-shuffle-select)
		printf 'v2 bool shuffle with scalar-if-produced input in Debug and optimized builds'
		;;
	xtensa-bool-shuffle)
		printf 'v2 and v4 boolean vector shuffle lowering'
		;;
	xtensa-bool-v8-bitcast)
		printf 'bitcast from u8 to @Vector(8, bool) followed by extraction and shuffle'
		;;
	xtensa-bool-vselect)
		printf 'boolean vector @select lowering in Debug and optimized builds'
		;;
	xtensa-scalar-bool-return)
		printf 'scalar bool return promotion for internal fastcc helpers'
		;;
	xtensa-scalar-bool-return-inverted)
		printf 'inverted scalar bool return promotion for internal fastcc helpers'
		;;
	xtensa-scalar-bool-export-return)
		printf 'exported scalar bool return promotion'
		;;
	xtensa-scalar-bool-not-return)
		printf 'explicit scalar bool negation return promotion'
		;;
	xtensa-scalar-bool-call)
		printf 'scalar bool argument promotion for internal fastcc helpers'
		;;
	xtensa-scalar-bool-call-inverted)
		printf 'inverted scalar bool argument promotion for internal fastcc helpers'
		;;
	xtensa-frame-scavenge)
		printf 'frame scavenging and emergency spill slot path'
		;;
	xtensa-frame-narrow-offsets)
		printf 'narrow u8/u16 stack offsets under scavenging pressure'
		;;
	xtensa-l32r-const-island)
		printf 'Debug large-function L32R constant-island placement under mixed stack accesses'
		;;
	esac
}
