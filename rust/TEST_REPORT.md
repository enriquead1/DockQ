# Rust validation report

## Local Linux validation

The released SVD implementation at the previous public revision passed the
following checks locally on Linux x86_64 with the committed lockfile:

| Check | Result |
|---|---|
| Formatting | Passed |
| Clippy, all targets/features, warnings denied | Passed |
| Unit tests | 48 passed |
| Reference tests | 3 passed |
| Mapping/search tests | 5 passed |
| Locked release build | Passed |
| Clean-environment CLI scoring example | Passed; DockQ 0.943 |
| Dynamic dependencies | libc and libgcc only; no Python library |

These checks were rerun on 2026-11-16 from a fresh checkout of the public
Rust branch. Cargo needed one build job in this container after an initial
linker process returned an I/O error; the serial build completed successfully.

## Hosted cross-platform validation

The main branch now runs the same formatting, Clippy, test, release-build, and
scoring-smoke checks on GitHub-hosted Linux x86_64, macOS x86_64, and Windows
x86_64 runners. The release workflow repeats these checks while assembling the
platform archives.

Record the GitHub Actions run links and per-platform outcomes here once the
main-branch workflow has completed. A platform is supported only after its
build, tests, smoke check, and release archive job pass.

## Numerical compatibility

The Python/Rust CLI corpus has 12 of 15 strict text comparisons passing. All
numeric JSON comparisons pass the established tolerances: 1e-4 Å for RMSD
values and 1e-5 for other floating-point metrics. Three 1EXB outputs differ
only in LRMSD rounding: Python prints 0.000 while Rust prints 0.001 around the
0.0005 Å boundary. The underlying values differ by approximately 4.9e-6 Å.
These cases remain documented and are not normalized away. See
../compat/CLI_ACCEPTANCE.md for the full comparison report.
