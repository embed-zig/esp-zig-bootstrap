# 0.15.2 Local Packaging and Manual Release

## Prerequisites

- A completed build with output directory: `.out/zig-<target>-<mcpu>/`
- `tar` and `shasum` are available locally; for publishing, `gh` must be installed and authenticated (`gh auth status`)

## 1) Local build

```bash
./bootstrap.sh 0.15.2 aarch64-macos-none baseline
./.out/zig-aarch64-macos-none-baseline/bin/zig version
```

## 2) Package and checksum

```bash
./release.sh 0.15.2 aarch64-macos-none baseline
```

This generates:

- `release/0.15.2/zig-0.15.2-aarch64-macos-none-baseline.tar.xz`
- `release/0.15.2/SHA256SUMS`

## 3) Manual publish (optional)

```bash
./release.sh 0.15.2 aarch64-macos-none baseline --publish
```

This is equivalent to:

```bash
gh release create v0.15.2 \
  release/0.15.2/zig-0.15.2-aarch64-macos-none-baseline.tar.xz \
  release/0.15.2/SHA256SUMS \
  --title "v0.15.2" \
  --notes "Manual local build release for 0.15.2 (aarch64-macos-none/baseline)."
```
