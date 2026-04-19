# 0.15.2 Assets

This directory contains the version-scoped inputs used by
`./bootstrap.sh 0.15.2 <target> <mcpu>`.

## Layout

- `llvm-project`
  Source definition for the LLVM/Clang/LLD input.
- `zig-bootstrap`
  Source definition for the Zig bootstrap input.
- `patches/`
  Downstream patch set applied in lexical order during bootstrap.

## Patch Notes

Patch files stay intentionally focused. The numeric prefixes preserve apply
order and should stay stable unless the patch set is reworked.

Unless otherwise noted, the entries below were split out from the repository's
previous monolithic `espressif.patch` and are maintained as local downstream
changes.

### 010-zig-lib-std-Target-xtensa.patch

- Purpose: add Xtensa CPU features and CPU models to Zig's std target tables.
- Notes: required for targets such as `esp32`, `esp32s2`, `esp32s3`, and other
  Xtensa CPU selections to resolve cleanly.
- Source: local downstream patch.

### 020-zig-src-codegen-llvm.patch

- Purpose: initialize the Xtensa LLVM asm printer in Zig's LLVM target setup.
- Notes: complements the Xtensa backend enablement work.
- Source: local downstream patch.

### 030-zig-src-codegen-llvm-bindings.patch

- Purpose: expose `LLVMInitializeXtensaAsmPrinter()` in Zig's LLVM bindings.
- Notes: paired with `020-zig-src-codegen-llvm.patch`.
- Source: local downstream patch.

### 040-zig-src-target.patch

- Purpose: mark Xtensa as an LLVM-backed target in Zig target support checks.
- Notes: allows object/assembly generation paths to treat Xtensa as supported.
- Source: local downstream patch.

### 050-llvm-CMakeLists.patch

- Purpose: avoid forcing `-static` in LLVM's host executable linker flags.
- Notes: helps host-side builds on environments where fully static host tools
  are not desirable or do not link cleanly.
- Source: local downstream patch.

### 060-build.patch

- Purpose: enable the experimental Xtensa target during bootstrap and pass the
  Zig-side Xtensa build flag.
- Notes: this is the bootstrap glue that turns on Xtensa in both LLVM and Zig.
- Source: local downstream patch.

### 065-build-zstd-static-lib.patch

- Purpose: copy Zig's Windows `zstd.lib` output to the `zstd_static.lib` name
  that LLVM's CMake probes for on Windows targets.
- Notes: keeps the downstream bootstrap compatible with the current
  `Findzstd.cmake` static-library naming expectation without changing non-Windows
  builds.
- Source: local downstream patch.

### 066-llvm-cmake-Findzstd.patch

- Purpose: synthesize `zstd::libzstd_static` whenever LLVM's zstd probe already
  resolved a usable static-library path.
- Notes: fixes the `x86_64-windows-gnu` bootstrap path where Zig emits
  `zstd_static.lib`, but LLVM's MinGW-side suffix heuristic otherwise skips
  creating the imported static target.
- Source: local downstream patch.

### 070-zig-src-link-MachO-Dylib.patch

- Purpose: allow Zig's Mach-O dylib logic to match `arm64e-*` target strings in
  newer macOS SDK `.tbd` files.
- Notes: added for Xcode 26.4 / macOS 26 SDK behavior where many TBD entries
  moved from `arm64-*` to `arm64e-*`. This patch preserves the original
  `arm64-*` strings and adds `arm64e-*` variants.
- Source: local workaround; may be replaceable by an external patched-sysroot
  workflow if that becomes the project's preferred solution.

### 080-llvm-XtensaSubtarget.patch

- Purpose: enable Xtensa text-section literals by default.
- Notes: keeps the LLVM subtarget default aligned with the downstream Xtensa
  toolchain expectations used here.
- Source: local downstream patch.

### 090-llvm-XtensaISelLowering.patch

- Purpose: provide the consolidated `XtensaISelLowering.cpp` downstream fix for
  small Xtensa boolean vectors and the `MOVBA4_P` custom inserter path.
- Notes: keeps `v1i1`/`v2i1`/`v4i1` lowering on one shared `i32` mask pipeline,
  covering build/insert/extract/concat/shuffle, `OR`/`AND`/`XOR`/`VSELECT`, and
  the extend-after-extract combines that previously required follow-up patches.
  It also avoids over-matching non-small bool-vector bitcasts in Debug builds.
- Source: local downstream fix developed from local investigation and repros.

### 100-llvm-XtensaInstrInfo.patch

- Purpose: add Xtensa instruction-selection patterns for boolean truncation and
  boolean vector element extraction.
- Notes: complements the consolidated `090-llvm-XtensaISelLowering.patch` for
  `v1i1`/`v2i1`/`v4i1` lowering, including the `v1i1` bitconvert shape that
  appears on helper call and return paths.
- Source: local downstream fix developed from local investigation and repros.

### 110-llvm-XtensaBRegFixupPass.patch

- Purpose: teach the Xtensa boolean-register fixup pass about `MOVBA4_P2`.
- Notes: required so the post-isel fixup stage handles the 4-lane boolean
  pseudo-instruction used by the new lowering path.
- Source: local downstream fix developed from local investigation and repros.

### 115-llvm-XtensaFrameLowering.patch

- Purpose: reserve an emergency spill slot whenever Xtensa frame-index
  scavenging is required.
- Notes: fixes the `Cannot scavenge register without an emergency spill slot`
  crash that showed up in optimized Xtensa builds.
- Source: local downstream fix developed from local investigation and repros.

### 116-llvm-XtensaBoolStackSlots.patch

- Purpose: teach Xtensa bool stack-slot selection and spill/reload expansion
  about packed `BR2`/`BR4` values.
- Notes: fixes the `-O0` verifier failure where multi-lane bool-vector spills
  were misrouted through `AE_[SL]ALIGN64_I`, and adds focused LLVM regressions.
- Source: local downstream fix developed from local investigation and repros.

### 117-llvm-XtensaBRegFixupHighGroup.patch

- Purpose: mark the high-group `MOVBA*_P2` shift writeback as an actual `SLLI`
  definition.
- Notes: fixes the verifier failure on high-group bool-vector writeback and
  adds a focused LLVM regression for the `v2i1` shuffle-plus-phi case.
- Source: local downstream fix developed from local investigation and repros.

### 120-llvm-XtensaRegisterInfo.patch

- Purpose: keep Xtensa emergency spill-slot indexing based on SP instead of FP.
- Notes: improves large `-O0` frame scavenging behavior for Xtensa.
- Source: local downstream patch.

### 125-llvm-XtensaConstantIsland.patch

- Purpose: tighten Xtensa `l32r` constant-island placement to the real positive
  encoding limit and reuse entries based on the caller's actual offset.
- Notes: fixes large Debug functions that previously reached assembly with
  `l32r fixup value out of range`.
- Source: local downstream fix developed from local investigation and repros.

### 130-clang-tools-CMakeLists.patch

- Purpose: stop building `clang-shlib` as part of this bootstrap.
- Notes: keeps the host tool build smaller and avoids an unnecessary shared
  library path for this repository's bootstrap use case.
- Source: local downstream patch.

## Maintenance Notes

- Keep patch files focused and in lexical order; `bootstrap.sh` applies them in
  that order.
- Some fixes intentionally span multiple related upstream files or pair code
  changes with focused LLVM regressions. Keep those groupings small and
  purpose-built.
- If you add or remove a patch, update this README so the patch purpose and
  provenance stay discoverable.

## Regression Tests

Committed Xtensa regression cases live under `regression/`.

Run them with the current environment Zig:

```bash
./0.15.2/regression/run.sh
```

Or pick an explicit Zig:

```bash
ZIG=/path/to/zig ./0.15.2/regression/run.sh
```

See [`regression/README.md`](./regression/README.md) for case coverage and the
usage details.
