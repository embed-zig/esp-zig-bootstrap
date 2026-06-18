#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPILE_TIMEOUT_SECONDS="${XTENSA_REGRESSION_TIMEOUT_SECONDS:-120}"

source "$SCRIPT_DIR/cases/manifest.sh"

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

print_usage() {
	cat <<'EOF'
Usage: ./0.16.0/regression/run.sh [case-id...]

Environment:
  ZIG  path to the Zig executable to test
  XTENSA_REGRESSION_TIMEOUT_SECONDS  per-compile timeout, defaults to 120

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
	local timeout_marker="$work_dir/timeout.marker"

	mkdir -p "$work_dir"
	rm -f "$timeout_marker"

	(
		cd "$work_dir"
		exec "$zig_exe" build-obj \
			-target xtensa-freestanding-none \
			-mcpu esp32s3 \
			"-O$optimize" \
			"$source_file"
	) >"$log_file" 2>&1 &
	local compile_pid=$!

	(
		sleep "$COMPILE_TIMEOUT_SECONDS"
		if kill -0 "$compile_pid" 2>/dev/null; then
			printf 'compile timed out after %s seconds\n' "$COMPILE_TIMEOUT_SECONDS" >"$timeout_marker"
			kill -TERM "$compile_pid" 2>/dev/null || true
			sleep 2
			kill -KILL "$compile_pid" 2>/dev/null || true
		fi
	) &
	local watchdog_pid=$!

	local compile_status=0
	wait "$compile_pid" 2>/dev/null || compile_status=$?
	kill "$watchdog_pid" 2>/dev/null || true
	wait "$watchdog_pid" 2>/dev/null || true

	if [[ -f "$timeout_marker" ]]; then
		cat "$timeout_marker" >>"$log_file"
		rm -f "$timeout_marker"
		return 124
	fi

	return "$compile_status"
}

emit_asm() {
	local zig_exe="$1"
	local source_file="$2"
	local optimize="$3"
	local work_dir="$4"
	local asm_file="$5"
	local log_file="$6"
	local timeout_marker="$work_dir/timeout.marker"

	rm -f "$timeout_marker"
	(
		cd "$work_dir"
		exec "$zig_exe" build-obj \
			-target xtensa-freestanding-none \
			-mcpu esp32s3 \
			"-O$optimize" \
			-femit-asm="$asm_file" \
			"$source_file"
	) >>"$log_file" 2>&1 &
	local compile_pid=$!

	(
		sleep "$COMPILE_TIMEOUT_SECONDS"
		if kill -0 "$compile_pid" 2>/dev/null; then
			printf 'compile timed out after %s seconds\n' "$COMPILE_TIMEOUT_SECONDS" >"$timeout_marker"
			kill -TERM "$compile_pid" 2>/dev/null || true
			sleep 2
			kill -KILL "$compile_pid" 2>/dev/null || true
		fi
	) &
	local watchdog_pid=$!

	local compile_status=0
	wait "$compile_pid" 2>/dev/null || compile_status=$?
	kill "$watchdog_pid" 2>/dev/null || true
	wait "$watchdog_pid" 2>/dev/null || true

	if [[ -f "$timeout_marker" ]]; then
		cat "$timeout_marker" >>"$log_file"
		rm -f "$timeout_marker"
		return 124
	fi

	return "$compile_status"
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

verify_optional_enum_return_asm() {
	local asm_file="$1"

	awk '
		function split_inst(line, parts) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			return split(line, parts, /[[:space:],]+/)
		}

		function trim_reg(reg) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", reg)
			gsub(/,.*$/, "", reg)
			return reg
		}

		/^[[:space:]]*l16ui[[:space:]]/ {
			split_inst($0, parts)
			load_reg = trim_reg(parts[2])
			seen_load = 1
			seen_range = 0
			masked_load = 0
		}
		seen_load && /^[[:space:]]*movi(\.n)?[[:space:]][^,]+,[[:space:]]*256$/ {
			seen_256_limit = 1
		}
		seen_load && /^[[:space:]]*bltu[[:space:]]/ && seen_256_limit {
			seen_range = 1
		}
		seen_range && /^[[:space:]]*and[[:space:]]/ {
			split_inst($0, parts)
			dst = trim_reg(parts[2])
			src0 = trim_reg(parts[3])
			src1 = trim_reg(parts[4])
			if (dst == load_reg && (src0 == load_reg || src1 == load_reg)) {
				masked_load = 1
			}
		}
		seen_range && /^[[:space:]]*b(eqz|nez)(\.n)?[[:space:]]/ {
			split_inst($0, parts)
			branch_reg = trim_reg(parts[2])
			if (branch_reg == load_reg && !masked_load) {
				print "optional enum decode branches on unmasked halfword load"
				exit 1
			}
		}
		END {
			if (!seen_load) {
				print "missing optional enum halfword load"
				exit 1
			}
		}
	' "$asm_file"
}

verify_optional_enum_lookup_asm() {
	local asm_file="$1"

	awk '
		function clear_state() {
			load_reg = ""
			window = 0
			delete zero_reg
			delete one_reg
		}

		function split_inst(line, parts) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			return split(line, parts, /[[:space:],]+/)
		}

		function trim_reg(reg) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", reg)
			gsub(/,.*$/, "", reg)
			return reg
		}

		function is_zero(reg) {
			return reg == "0" || zero_reg[reg]
		}

		function is_one(reg) {
			return reg == "1" || one_reg[reg]
		}

		/^[[:space:]]*l16ui[[:space:]]/ {
			split_inst($0, parts)
			load_reg = trim_reg(parts[2])
			seen_load = 1
			window = 24
			next
		}

		window > 0 {
			window -= 1
			if ($0 ~ /^[[:space:]]*movi(\.n)?[[:space:]]/) {
				split_inst($0, parts)
				dst = trim_reg(parts[2])
				imm = parts[3]
				if (imm == "0")
					zero_reg[dst] = 1
				else if (imm == "1")
					one_reg[dst] = 1
				else {
					delete zero_reg[dst]
					delete one_reg[dst]
				}
			}
			if ($0 ~ /^[[:space:]]*and[[:space:]]/) {
				split_inst($0, parts)
				dst = trim_reg(parts[2])
				src0 = trim_reg(parts[3])
				src1 = trim_reg(parts[4])
				if (dst == load_reg && ((src0 == load_reg && is_one(src1)) ||
				    (src1 == load_reg && is_one(src0))))
					load_reg = ""
			}
			if ($0 ~ /^[[:space:]]*b(eqz|nez)(\.n)?[[:space:]]/) {
				split_inst($0, parts)
				branch_reg = trim_reg(parts[2])
				if (branch_reg == load_reg) {
					print "optional enum lookup branches on unmasked halfword tag"
					exit 1
				}
			}
			if ($0 ~ /^[[:space:]]*b(eq|ne)[[:space:]]/) {
				split_inst($0, parts)
				lhs = trim_reg(parts[2])
				rhs = trim_reg(parts[3])
				if ((lhs == load_reg && is_zero(rhs)) ||
				    (rhs == load_reg && is_zero(lhs))) {
					print "optional enum lookup branches on unmasked halfword tag"
					exit 1
				}
			}
			if ($0 ~ /^[[:space:]]*[a-z]/) {
				split_inst($0, parts)
				dst = trim_reg(parts[2])
				if (dst == load_reg && $0 !~ /^[[:space:]]*srli[[:space:]]/)
					clear_state()
			}
		}

		END {
			if (!seen_load) {
				print "missing optional enum halfword load"
				exit 1
			}
		}
	' "$asm_file"
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
		verify_phi_spill_asm "$asm_file" >>"$log_file" 2>&1 || return 1
		;;
	xtensa-bool-load-hi-subvector:Debug)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_load_hi_subvector_asm "$asm_file" >>"$log_file" 2>&1 || return 1
		;;
	xtensa-bool-fixup-v4-high-group:Debug)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_fixup_v4_high_group_asm "$asm_file" >>"$log_file" 2>&1 || return 1
		;;
	xtensa-optional-enum-return:ReleaseSmall)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_optional_enum_return_asm "$asm_file" >>"$log_file" 2>&1 || return 1
		;;
	xtensa-optional-enum-lookup:ReleaseSafe)
		local asm_file="$work_dir/$case_id.$optimize.s"
		if ! emit_asm "$zig_exe" "$source_file" "$optimize" "$work_dir" "$asm_file" "$log_file"; then
			return 1
		fi
		verify_optional_enum_lookup_asm "$asm_file" >>"$log_file" 2>&1 || return 1
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
