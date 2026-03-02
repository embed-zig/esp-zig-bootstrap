# esp-zig-bootstrap (0.15.2)

This repository currently maintains bootstrap assets and scripts for `0.15.2`:

- `0.15.2/llvm-project`
- `0.15.2/zig-bootstrap`
- `0.15.2/espressif.patch`

## Build

```bash
./bootstrap.sh 0.15.2 <target> <mcpu>
```

Example:

```bash
./bootstrap.sh 0.15.2 aarch64-macos-none baseline
```

Build output is written to the repository root: `.out/zig-<target>-<mcpu>/`

## Clean

```bash
./bootstrap.sh clean 0.15.2 aarch64-linux-gnu baseline
./bootstrap.sh clean 0.15.2 x86_64-macos-none baseline
```

- `clean` only removes artifacts for the specified target:
  - `0.15.2/.build-<target>-<mcpu>/`
  - `0.15.2/.out/zig-<target>-<mcpu>/`
  - `.out/zig-<target>-<mcpu>/`
- It does not delete build results for other targets.

## smoke test

Run the smoke test script:

```bash
./smoke_test.sh
```

## Release

See [`RELEASE.md`](./RELEASE.md).
