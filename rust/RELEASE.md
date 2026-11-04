# Rust release preparation

## Status

The Rust CLI and scoring library are implemented for the principal protein,
nucleic-acid, peptide, and small-molecule workflows. The crate remains
experimental while cross-platform validation and the remaining migration review
gates are incomplete. It is not yet a declared replacement for the Python
package. The GitHub Actions workflow is manual and builds artifacts; it does not
publish a GitHub Release, crates.io package, or other distribution.

Current local validation includes 56 Rust tests, including reference-corpus and
deterministic mapping-search checks. The
comparison tolerances are `1e-4` Å for RMSD metrics and `1e-5` for other floating
metrics; integer counts must match exactly. These checks cover the included
fixtures and do not prove parity for every input or platform.
The [CLI acceptance report](../compat/CLI_ACCEPTANCE.md) separately records
three strict text-rounding differences and known Python mapping-diagnostic quirks.

## Reproducible build and test

Use stable Rust and the committed lockfile:

```sh
cargo build --locked --release --manifest-path rust/Cargo.toml
cargo test --locked --manifest-path rust/Cargo.toml
rust/target/release/DockQ --help
```

If dependencies are already cached, `--offline` can be added to the Cargo
commands. The release executable is `rust/target/release/DockQ` on Unix-like
systems and `rust\\target\\release\\DockQ.exe` on Windows.

Run a scoring smoke check from the repository root:

```sh
rust/target/release/DockQ \
  examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb \
  --mapping AB:AB --short
```

On Linux, also run with a minimal environment and inspect dynamic dependencies:

```sh
env -i PATH=/usr/bin:/bin \
  rust/target/release/DockQ \
  examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb \
  --mapping AB:AB --short
ldd rust/target/release/DockQ
```

The Rust executable does not invoke Python or load Python libraries. `ldd`
should show the normal system runtime dependencies for the target toolchain; it
must not show Python libraries. Linux has been checked locally. The macOS and
Windows commands below are workflow targets, not platforms validated in this
environment.

## Platform artifact workflow

From GitHub Actions, run **Rust release artifacts** with `workflow_dispatch`.
The workflow builds x86_64 binaries on Ubuntu 22.04, macOS 15 Intel, and Windows Server
2022, checks non-empty successful `--help` output, then uploads one artifact per
OS. The workflow has not been run or validated on macOS or Windows as part of
the current local checks.

Each bundle contains the executable, this README, the root MIT `LICENSE`, build
metadata, and SHA-256 checksums. Verify a downloaded executable against
`SHA256SUMS.txt` before use. The workflow does not publish or attach files to a
tagged release.

For a local archive, include the executable, `LICENSE`, this README, source
revision and Rust compiler version, and checksums. Preserve the original
copyright notice and license terms.

## Before a production release

Complete cross-platform build and clean-runtime checks, broaden differential
validation, review known compatibility differences and dependency licenses, and
confirm documentation and scientific citation details. Keep publishing as a
separate explicit action after artifact review.
