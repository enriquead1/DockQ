# Rust validation report

## Hosted cross-platform run

GitHub Actions run [#3](https://github.com/enriquead1/DockQ/actions/runs/43830338000)
validated commit e2e9ecb on 2026-11-16:

| Platform | Runner | Formatting | Clippy | Tests | Release build | Scoring smoke |
|---|---|---:|---:|---:|---:|---:|
| Linux x86_64 | ubuntu-22.04 | Pass | Pass | 56 passed | Pass | Pass |
| macOS x86_64 | macos-15-intel | Pass | Pass | 56 passed | Pass | Pass |
| Windows x86_64 | windows-2022 | Pass | Pass | 56 passed | Pass | Pass |

Each job ran formatting checks, Clippy for all targets and features with
warnings denied, all Rust tests, a locked release build, and the same 1A2K
scoring example. The example returned DockQ 0.943 on all three systems.

The release workflow repeats these checks and additionally assembles platform
archives with dependency license texts, build metadata, and checksums. Its
tagged release run is recorded on the repository's Releases page.

## Local Linux runtime check

A clean-environment run of the release executable scored 1A2K successfully.
The Linux binary links to libc and libgcc and does not load Python libraries.

## Numerical compatibility

The Python/Rust CLI corpus has 12 of 15 strict text comparisons passing. All
numeric JSON comparisons pass the established tolerances: 1e-4 Å for RMSD
values and 1e-5 for other floating-point metrics. Three 1EXB outputs differ
only in LRMSD rounding: Python prints 0.000 while Rust prints 0.001 around the
0.0005 Å boundary. The underlying values differ by approximately 4.9e-6 Å.
These cases remain documented and are not normalized away. See
../compat/CLI_ACCEPTANCE.md for the full comparison report.
