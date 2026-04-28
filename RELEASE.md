# Local Packaging and Manual Release

## Prerequisites

- A completed build with output directory: `.out/zig-<target>-<mcpu>/`
- `tar` and `shasum` are available locally; for publishing, `gh` must be installed and authenticated (`gh auth status`)
- A release build number. Releases intentionally use `v<version>-rN` tags; bare
  `v<version>` releases are not used.

## 1) Local build

```bash
./bootstrap.sh 0.16.0 aarch64-macos-none baseline
./.out/zig-aarch64-macos-none-baseline/zig version
```

## 2) Package and checksum

```bash
./release.sh 0.16.0 aarch64-macos-none baseline --build-number 1
```

This generates:

- `release/0.16.0-r1/zig-0.16.0-r1-aarch64-macos-none-baseline.tar.xz`
- `release/0.16.0-r1/SHA256SUMS`

For multi-target releases, package each target with the same build number, then
regenerate one combined checksum file:

```bash
(
  cd release/0.16.0-r1
  shasum -a 256 zig-0.16.0-r1-*.tar.xz > SHA256SUMS
)
```

## 3) Manual publish (optional)

```bash
./release.sh 0.16.0 aarch64-macos-none baseline --build-number 1 --publish
```

This is equivalent to:

```bash
gh release create v0.16.0-r1 \
  release/0.16.0-r1/zig-0.16.0-r1-aarch64-macos-none-baseline.tar.xz \
  release/0.16.0-r1/SHA256SUMS \
  --title "v0.16.0-r1" \
  --notes "Manual local build release for 0.16.0-r1 (aarch64-macos-none/baseline)."
```
