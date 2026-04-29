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

`release.sh` requires a build number so all releases use `<version>-rN` tags.
Passing `--build-number 1` produces release assets under `release/<version>-r1/`
and uses artifact names such as `zig-<version>-r1-<target>-<mcpu>.tar.xz`.

CI releases are tag-driven. Pushing a tag such as `0.16.0-r1` builds the
matching version directory and publishes a GitHub Release with the same tag.

The workflow runs on `ubuntu-24.04` and uses a target matrix, so one tag can
produce multiple cross-compiled distributions. Individual target failures do not
block the release; the final GitHub Release includes only successfully built
artifacts.

Release notes are generated with `github/copilot-release-notes`. The repository
must have a `COPILOT_GITHUB_TOKEN` secret with `Copilot Requests: Read`
permission, and the tag must have a previous `<version>-rN` tag to use as the
release notes base ref.

To refresh an existing release, delete and recreate the tag:

```bash
git tag -d 0.16.0-r1
git push origin :refs/tags/0.16.0-r1
git tag 0.16.0-r1
git push --force origin 0.16.0-r1
```
