# AGENTS.md
Guide for coding agents in `esp-zig-bootstrap`.
Current product scope is Zig bootstrap assets/scripts for `0.15.2` only.
## 1) Repository scope
- Scripts: `bootstrap.sh`, `release.sh`, `smoke_test.sh`
- Docs: `README.md`, `RELEASE.md`
- Assets: `0.15.2/llvm-project`, `0.15.2/zig-bootstrap`, `0.15.2/espressif.patch`
- Gitignored local outputs: `.out/`, `release/`, `0.15.2/.build-*`, `0.15.2/.downloads/`, `0.15.2/.cache/`
- Do not introduce other version folders unless explicitly requested.
## 2) Tooling baseline
- Required: `bash`, `git`, `patch`, `tar`, `shasum`
- Download transport: `wget` or `curl`
- Optional publish tool: `gh` (authenticated)
## 3) Build/lint/test commands
### Build
General form:
```bash
./bootstrap.sh 0.15.2 <target> <mcpu>
```
Example:
```bash
./bootstrap.sh 0.15.2 aarch64-macos-none baseline
```
Output contract:
```bash
.out/zig-<target>-<mcpu>/
```
### Clean (target-scoped)
General form:
```bash
./bootstrap.sh clean 0.15.2 <target> <mcpu>
```
Examples:
```bash
./bootstrap.sh clean 0.15.2 aarch64-linux-gnu baseline
./bootstrap.sh clean 0.15.2 x86_64-macos-none baseline
```
Expectation: only the requested target artifacts are removed.
### Lint/static checks
This repo has no dedicated lint framework.
Minimum check:
```bash
bash -n bootstrap.sh release.sh smoke_test.sh
```
If available locally:
```bash
shellcheck bootstrap.sh release.sh smoke_test.sh
```
### Test suite
Primary test command:
```bash
./smoke_test.sh
```
`smoke_test.sh` validates:
- missing-arg usage failure path
- invalid-version failure path
- target-scoped clean logic
- preservation of other target outputs
- preservation of `.downloads`
### Running a single test/scenario (important)
There is no test runner with single-case selectors.
Run one scenario by invoking one command path directly.
Single-scenario commands:
```bash
# usage should fail
./bootstrap.sh

# invalid version should fail
./bootstrap.sh 0.15.3 aarch64-macos-none baseline

# clean one target
./bootstrap.sh clean 0.15.2 aarch64-linux-gnu baseline

# package one target
./release.sh 0.15.2 aarch64-macos-none baseline
```
## 4) Release commands
### Package + checksum (single target)
```bash
./release.sh 0.15.2 aarch64-macos-none baseline
```
Expected files:
- `release/0.15.2/zig-0.15.2-aarch64-macos-none-baseline.tar.xz`
- `release/0.15.2/SHA256SUMS`
### Manual publish path
```bash
./release.sh 0.15.2 aarch64-macos-none baseline --publish
```
### Multi-target release workflow
1. Run `release.sh` once per target.
2. Regenerate one combined `release/0.15.2/SHA256SUMS` over all `zig-0.15.2-*.tar.xz`.
3. Upload all archives + checksum to one GitHub release.
## 5) Code style guidelines
### Shell standards
- Use `#!/usr/bin/env bash`.
- Keep `set -euo pipefail`.
- Preserve existing indentation style (tabs in current scripts).
- Prefer small, single-purpose functions.
- Keep output messages concise and stable.
### Dependencies/imports (shell context)
- Avoid new dependencies unless necessary.
- Guard optional commands with `command -v` checks.
- Preserve fallback behavior (`wget`/`curl`, `nproc`/`sysctl`).
### Variables, naming, and “types”
- Script-level constants/path vars: `UPPER_SNAKE_CASE`.
- Function-local variables: `local lower_snake_case`.
- Function names: `lower_snake_case`.
- Quote expansions unless intentional word splitting is needed.
- Anchor paths from `SCRIPT_DIR` instead of caller CWD assumptions.
### Formatting
- Prefer `printf` over `echo` for deterministic output.
- Keep Markdown command examples copy-pastable.
- Keep artifact naming contracts unchanged:
  - output dir: `zig-<target>-<mcpu>`
  - archive: `zig-<version>-<target>-<mcpu>.tar.xz`
### Error handling
- Fail fast on invalid args and missing prerequisites.
- Use explicit fatal helpers (`die`, `fail`).
- Print failures to stderr.
- Do not silently ignore command failures.
### Safety and side effects
- Keep clean operations target-scoped.
- Restrict destructive actions to known build/output directories.
- Use trap-based cleanup for temp resources when needed.
- Keep scripts re-runnable/idempotent where practical.
### Validation checklist before handoff
1. `bash -n bootstrap.sh release.sh smoke_test.sh`
2. `./smoke_test.sh`
3. one focused scenario command related to your change
4. `./release.sh ...` if packaging/release behavior changed
### Documentation consistency
- Update `README.md` when CLI behavior/path contracts change.
- Update `RELEASE.md` when release flow or prerequisites change.
- Ensure docs match actual script behavior.
## 6) Cursor/Copilot rule files
Checked paths:
- `.cursor/rules/`
- `.cursorrules`
- `.github/copilot-instructions.md`
Status at writing time: none found.
If added later, treat them as higher-priority constraints than this file.
## 7) Agent notes
- Keep diffs small and focused.
- Never commit generated artifacts from `.out/` or `release/`.
- Stay in `0.15.2` scope unless user requests otherwise.
