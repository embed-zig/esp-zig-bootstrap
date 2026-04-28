# esp-zig-bootstrap

This repository maintains version-scoped Zig bootstrap assets and scripts.
Currently tracked versions:

- `0.15.2/llvm-project`
- `0.15.2/zig-bootstrap`
- `0.15.2/patches/`
- `0.16.0/llvm-project`
- `0.16.0/zig-bootstrap`
- `0.16.0/patches/`

## Build

```bash
./bootstrap.sh <version> <target> <mcpu>
```

Example:

```bash
./bootstrap.sh 0.16.0 aarch64-macos-none baseline
```

Build output is written to the repository root: `.out/zig-<target>-<mcpu>/`

During bootstrap, patches are applied from `<version>/patches/*.patch` in lexical
order.

## Clean

```bash
./bootstrap.sh clean 0.16.0 aarch64-linux-gnu baseline
./bootstrap.sh clean 0.16.0 x86_64-macos-none baseline
```

- `clean` only removes artifacts for the specified target:
  - `<version>/.build-<target>-<mcpu>/`
  - `<version>/.out/zig-<target>-<mcpu>/`
  - `.out/zig-<target>-<mcpu>/`
- It does not delete build results for other targets.

## smoke test

Run the smoke test script:

```bash
./smoke_test.sh
```

## Regression Tests

Committed Xtensa regression cases live under each version's `regression/`
directory when that version has focused downstream coverage.

Run them with the current environment Zig:

```bash
./0.16.0/regression/run.sh
```

Or pick an explicit Zig:

```bash
ZIG=/path/to/zig ./0.16.0/regression/run.sh
```

See the version-specific regression README for the case list and usage details.

## Release

`release.sh` requires a build number so all releases use `v<version>-rN` tags.
Passing `--build-number 1` produces release assets under `release/<version>-r1/`
and uses artifact names such as `zig-<version>-r1-<target>-<mcpu>.tar.xz`.

See [`RELEASE.md`](./RELEASE.md).
