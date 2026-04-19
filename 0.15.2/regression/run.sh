#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/cases/manifest.sh"

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

print_usage() {
	cat <<'EOF'
Usage: ./0.15.2/regression/run.sh [case-id...]

Environment:
  ZIG  path to the Zig executable to test

Options:
  --help  show this help text
  --list  list available regression cases
EOF
}

resolve_zig() {
	local candidate="${ZIG:-}"
	if [[ -n "$candidate" ]]; then
		[[ -x "$candidate" ]] || die "ZIG is not executable: $candidate"
		printf '%s\n' "$candidate"
		return 0
	fi

	if command -v zig >/dev/null 2>&1; then
		command -v zig
		return 0
	fi

	return 1
}

print_log_excerpt() {
	local log_file="$1"
	local line_count=0

	while IFS= read -r line; do
		printf '      %s\n' "$line"
		line_count=$((line_count + 1))
		if [[ "$line_count" -ge 12 ]]; then
			break
		fi
	done <"$log_file"
}

run_compile() {
	local zig_exe="$1"
	local source_file="$2"
	local optimize="$3"
	local work_dir="$4"
	local log_file="$5"

	mkdir -p "$work_dir"

	(
		cd "$work_dir"
		"$zig_exe" build-obj \
			-target xtensa-freestanding-none \
			-mcpu esp32s3 \
			"-O$optimize" \
			"$source_file"
	) >"$log_file" 2>&1
}

emit_asm() {
	local zig_exe="$1"
	local source_file="$2"
	local optimize="$3"
	local work_dir="$4"
	local asm_file="$5"
	local log_file="$6"

	(
		cd "$work_dir"
		"$zig_exe" build-obj \
			-target xtensa-freestanding-none \
			-mcpu esp32s3 \
			"-O$optimize" \
			-femit-asm="$asm_file" \
			"$source_file"
	) >>"$log_file" 2>&1
}

verify_fixup_v4_high_group_asm() {
	local asm_file="$1"

	awk '
		{
			lines[NR] = $0
			if ($0 ~ /^[[:space:]]*extui[[:space:]].*,[[:space:]]*4,[[:space:]]*4$/) {
				saw_extui = 1
				start = NR - 8
				if (start < 1) {
					start = 1
				}
				saw_shift = 0
				saw_wsr = 0
				for (i = start; i < NR; i++) {
					if (lines[i] ~ /^[[:space:]]*_?slli[[:space:]].*,[[:space:]]*4$/) {
						saw_shift = 1
					}
					if (lines[i] ~ /^[[:space:]]*wsr[[:space:]].*,[[:space:]]*br$/) {
						saw_wsr = 1
					}
				}
				if (saw_shift && saw_wsr) {
					matched = 1
				}
			}
		}
		END {
			if (!saw_extui) {
				print "missing high-group BR4 extract (extui ..., 4, 4)"
				exit 1
			}
			if (!matched) {
				print "missing high-group BR4 writeback shift (slli ..., 4 before wsr ..., br)"
				exit 1
			}
		}
	' "$asm_file"
}

verify_load_hi_subvector_asm() {
	local asm_file="$1"

	awk '
		/^[[:space:]]*srli[[:space:]].*,[[:space:]]*2$/ {
			shifted = 1
		}
		/^[[:space:]]*extui[[:space:]].*,[[:space:]]*2,[[:space:]]*2$/ {
			shifted = 1
		}
		END {
			if (!shifted) {
				print "missing high-half bool subvector shift/extract"
				exit 1
			}
		}
	' "$asm_file"
}

verify_phi_spill_function_asm() {
	local asm_file="$1"
	local func_name="$2"
	local arity="$3"

	awk -v func_name="$func_name" -v arity="$arity" '
		function fail(msg) {
			print func_name ": " msg
			exit 1
		}

		function finish() {
			if (!saw_rsr) {
				fail("missing rsr ..., br")
			}
			if (extract_count < 2) {
				fail("missing paired extui ..., 0, " arity)
			}
			if (!saw_store) {
				fail("missing s8i spill")
			}
			if (!saw_load) {
				fail("missing l8ui reload")
			}
			if (!saw_wsr) {
				fail("missing wsr ..., br")
			}
			if (saw_bad_align) {
				fail("unexpected AE_VALIGN spill/reload path")
			}
			done = 1
		}

		$0 ~ ("^[[:space:]]*[^[:space:]]*" func_name "[^[:space:]]*:[[:space:]]*") {
			found = 1
			in_func = 1
			next
		}

		in_func && $0 ~ /^[[:space:]]*[[:alnum:]_$][[:alnum:]_.$]*:$/ {
			finish()
			exit 0
		}

		in_func {
			if ($0 ~ /^[[:space:]]*rsr[[:space:]].*,[[:space:]]*br$/) {
				saw_rsr = 1
			}
			if ($0 ~ ("^[[:space:]]*extui[[:space:]].*,[[:space:]]*0,[[:space:]]*" arity "$")) {
				extract_count += 1
			}
			if ($0 ~ /^[[:space:]]*s8i[[:space:]]/) {
				saw_store = 1
			}
			if ($0 ~ /^[[:space:]]*l8ui[[:space:]]/) {
				saw_load = 1
			}
			if ($0 ~ /^[[:space:]]*wsr[[:space:]].*,[[:space:]]*br$/) {
				saw_wsr = 1
			}
			if ($0 ~ /ae_[sl]align64/) {
				saw_bad_align = 1
			}
		}

		END {
			if (done) {
				exit 0
			}
			if (found) {
				finish()
				exit 0
			}
			fail("missing function label")
		}
	' "$asm_file"
}

verify_phi_spill_asm() {
	local asm_file="$1"

	verify_phi_spill_function_asm "$asm_file" "spill_phi_ret_v2" 2
	verify_phi_spill_function_asm "$asm_file" "spill_phi_ret_v4" 4
}

verify_case_output() {
	local case_id="$1"
	local zig_exe="$2"
	local source_file="$3"
	local optimize="$4"
	local work_dir="$5"
	local log_file="$6"

	case "$case_id:$optimize" in
	xtensa-bool-phi-spill:Debug)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_phi_spill_asm "$asm_file" >>"$log_file" 2>&1
		;;
	xtensa-bool-load-hi-subvector:Debug)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_load_hi_subvector_asm "$asm_file" >>"$log_file" 2>&1
		;;
	xtensa-bool-fixup-v4-high-group:Debug)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_fixup_v4_high_group_asm "$asm_file" >>"$log_file" 2>&1
		;;
	esac

	return 0
}

run_one() {
	local case_id="$1"
	local zig_exe="$2"
	local source_file="$3"
	local optimize="$4"
	local work_dir="$5"
	local log_file="$6"

	if run_compile "$zig_exe" "$source_file" "$optimize" "$work_dir" "$log_file"; then
		if verify_case_output "$case_id" "$zig_exe" "$source_file" "$optimize" "$work_dir" "$log_file"; then
			printf '    %-12s %s\n' "$optimize" "PASS"
			return 0
		fi
		printf '    %-12s %s\n' "$optimize" "FAIL"
		print_log_excerpt "$log_file"
		return 1
	fi

	printf '    %-12s %s\n' "$optimize" "FAIL"
	print_log_excerpt "$log_file"
	return 1
}

list_cases() {
	local case_id

	for case_id in "${CASE_IDS[@]}"; do
		printf '%s\t%s\t%s\n' \
			"$case_id" \
			"$(case_patches "$case_id")" \
			"$(case_description "$case_id")"
	done
}

main() {
	local zig_exe
	local failure_count=0
	local case_id
	local -a selected_cases=()

	if [[ "${1:-}" == "--help" ]]; then
		print_usage
		exit 0
	fi

	if [[ "${1:-}" == "--list" ]]; then
		list_cases
		exit 0
	fi

	if [[ $# -eq 0 ]]; then
		selected_cases=("${CASE_IDS[@]}")
	else
		for case_id in "$@"; do
			case_exists "$case_id" || die "Unknown case: $case_id"
			selected_cases+=("$case_id")
		done
	fi

	zig_exe="$(resolve_zig)" || die "Unable to locate zig. Set ZIG."

	printf 'Using zig: %s\n\n' "$zig_exe"

	for case_id in "${selected_cases[@]}"; do
		local source_file
		local patches
		local description
		local optimize
		local case_failed=0
		local case_tmp

		source_file="$(case_source "$case_id")"
		patches="$(case_patches "$case_id")"
		description="$(case_description "$case_id")"
		case_tmp="$(mktemp -d "${TMPDIR:-/tmp}/xtensa-regression.${case_id}.XXXXXX")"

		printf '== %s ==\n' "$case_id"
		printf '  patches: %s\n' "$patches"
		printf '  detail:  %s\n' "$description"

		for optimize in Debug ReleaseSafe ReleaseFast ReleaseSmall; do
			if ! run_one "$case_id" "$zig_exe" "$source_file" "$optimize" "$case_tmp/$optimize" "$case_tmp/$optimize.log"; then
				case_failed=1
			fi
		done

		rm -rf "$case_tmp"

		if [[ "$case_failed" -eq 1 ]]; then
			failure_count=$((failure_count + 1))
			printf '  result: FAIL\n\n'
		else
			printf '  result: PASS\n\n'
		fi
	done

	if [[ "$failure_count" -ne 0 ]]; then
		die "Regression run failed with $failure_count failing case(s)"
	fi

	printf 'Regression run passed\n'
}

main "$@"
