## Xtensa Regression Cases

This directory contains small committed Zig repros for the complex Xtensa patches
under `0.16.0/patches/`.

### Layout

- `cases/xtensa-bool-build-or.zig`: covers `090`
- `cases/xtensa-bool-bitwise.zig`: covers `090`
- `cases/xtensa-bool-insert.zig`: covers `090`
- `cases/xtensa-bool-return.zig`: covers `090`
- `cases/xtensa-bool-scalar-select.zig`: covers `090`
- `cases/xtensa-bool-phi-spill.zig`: covers `116`, including Debug-only BR2/BR4 byte spill/reload checks across a multi-block phi
- `cases/xtensa-bool-fp-select.zig`: covers `090`, including float-compare-driven bool-vector selects
- `cases/xtensa-bool-fp-vector-cmp.zig`: covers `090`, including vector float compares producing bool vectors
- `cases/xtensa-bool-v3-legalize.zig`: covers `090`, including irregular `@Vector(3, bool)` legalization
- `cases/xtensa-bool-reduce-odd.zig`: covers `090`, including odd-width bool-vector reductions
- `cases/xtensa-bool-load-hi-subvector.zig`: covers `090`, including non-zero subvector extraction from loaded packed bool vectors
- `cases/xtensa-bool-v1-call.zig`: covers `090`, `100`
- `cases/xtensa-bool-extract.zig`: covers `090`, `100`
- `cases/xtensa-bool-extend-extract.zig`: covers `090`
- `cases/xtensa-bool-fixup-v4.zig`: covers `110`
- `cases/xtensa-bool-fixup-v4-high-group.zig`: covers `110`, `117`, including Debug-only BR4 writes into the second physical bool-vector group
- `cases/xtensa-bool-negated-extract.zig`: defensive extract-plus-negation coverage for `090`
- `cases/xtensa-bool-v2-roundtrip.zig`: defensive `@Vector(2, bool)` coverage for `090`, `100`
- `cases/xtensa-bool-v2-vselect-shuffle.zig`: covers `100`, including Debug-only BR2 physreg copies after vector `@select`
- `cases/xtensa-bool-shuffle-select.zig`: covers `090`
- `cases/xtensa-bool-shuffle.zig`: covers `090`, including reverse self-shuffles
- `cases/xtensa-bool-v8-bitcast.zig`: covers `090`
- `cases/xtensa-bool-vselect.zig`: covers `090`
- `cases/xtensa-frame-scavenge.zig`: covers `115`, `120`
- `cases/xtensa-frame-narrow-offsets.zig`: defensive narrow-offset scavenging coverage
- `cases/xtensa-l32r-const-island.zig`: covers `125`, including Debug-only large mixed-width stack accesses that used to overflow Xtensa `l32r` constant-island reach
- `cases/manifest.sh`: case metadata used by the harness
- `run.sh`: executes the matrix across `Debug`, `ReleaseSafe`, `ReleaseFast`,
and `ReleaseSmall`

### Usage

Run with the Zig from your current environment:

```bash
./0.16.0/regression/run.sh
```

Run with an explicit Zig:

```bash
ZIG=/path/to/zig \
./0.16.0/regression/run.sh
```

Run one case only:

```bash
ZIG=/path/to/zig \
./0.16.0/regression/run.sh xtensa-bool-extend-extract
```

List all available cases without running compilation:

```bash
./0.16.0/regression/run.sh --list
```

### Notes

- The cases intentionally stay small and compile-only.
- `xtensa-bool-phi-spill` also performs a Debug-only assembly sanity check for the BR2/BR4 byte spill/reload path.
- `xtensa-bool-fixup-v4-high-group` also performs a Debug-only assembly sanity check for the high-group BR4 writeback shape.
- `xtensa-bool-load-hi-subvector` also performs a Debug-only assembly sanity check for the packed-byte high-half extract path.
- The harness runs `zig build-obj -target xtensa-freestanding-none -mcpu esp32s3`.
- The harness uses `ZIG` when provided, otherwise it falls back to
`$(command -v zig)`.
