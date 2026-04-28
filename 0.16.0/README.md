# 0.16.0 Assets

This directory contains the version-scoped inputs used by
`./bootstrap.sh 0.16.0 <target> <mcpu>`.

## Layout

- `llvm-project`
  Source definition for the Espressif LLVM/Clang/LLD input.
- `zig-bootstrap`
  Source definition for the Zig bootstrap input.
- `patches/`
  Downstream patch set applied in lexical order during bootstrap.
- `regression/`
  Compile-only Xtensa regression cases for the downstream patch set.

## Patch Notes

Patch files stay intentionally focused. The numeric prefixes preserve apply
order and should stay stable unless the patch set is reworked.

### Zig-Side Patches

- `010-zig-lib-std-Target-xtensa.patch`
  Adds Espressif Xtensa CPU features and CPU models such as `esp32`, `esp32s2`,
  `esp32s3`, and `esp8266`.
- `020-zig-src-codegen-llvm.patch`
  Initializes the Xtensa LLVM asm printer.
- `030-zig-src-codegen-llvm-bindings.patch`
  Exposes `LLVMInitializeXtensaAsmPrinter()` in Zig's LLVM bindings.
- `035-zig-enable-xtensa-build-options.patch`
  Enables Zig's Xtensa LLVM feature flag while building the host compiler.
- `040-zig-src-target.patch`
  Marks Xtensa as an LLVM-backed target for Zig code generation checks.

### Bootstrap And LLVM Patches

- `050-llvm-CMakeLists.patch`
  Avoids forcing fully static host executable linker flags.
- `060-build.patch`
  Enables LLVM's experimental Xtensa target and passes Zig's Xtensa build flag.
- `065-build-zstd-static-lib.patch`
  Keeps Windows zstd static-library naming compatible with LLVM's CMake probes.
- `066-llvm-cmake-Findzstd.patch`
  Synthesizes `zstd::libzstd_static` from LLVM's resolved static-library path.
- `080-llvm-XtensaSubtarget.patch`
  Enables Xtensa text-section literals by default.
- `090-llvm-XtensaISelLowering.patch`
  Consolidates small bool-vector lowering for `v1i1`/`v2i1`/`v3i1`/`v4i1`,
  including select, shuffle, bitcast, extract, and odd-width legalization paths.
- `100-llvm-XtensaInstrInfo.patch`
  Adds boolean truncation and vector element extraction patterns.
- `110-llvm-XtensaBRegFixupPass.patch`
  Teaches the boolean-register fixup pass about `MOVBA4_P2`.
- `115-llvm-XtensaFrameLowering.patch`
  Reserves emergency spill slots when Xtensa frame-index scavenging is needed.
- `116-llvm-XtensaBoolStackSlots.patch`
  Handles packed `BR2`/`BR4` bool stack slots and spill/reload expansion.
- `117-llvm-XtensaBRegFixupHighGroup.patch`
  Fixes high-group `MOVBA*_P2` shift writeback definitions.
- `120-llvm-XtensaRegisterInfo.patch`
  Keeps emergency spill-slot indexing based on SP instead of FP.
- `125-llvm-XtensaConstantIsland.patch`
  Tightens `l32r` constant-island placement and reuse behavior.
- `130-clang-tools-CMakeLists.patch`
  Avoids building `clang-shlib` for this bootstrap.

## Regression Tests

Run the focused Xtensa regression suite with an explicit Zig:

```bash
ZIG=/path/to/zig ./0.16.0/regression/run.sh
```

See [`regression/README.md`](./regression/README.md) for case coverage and
usage details.
