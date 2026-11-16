# Rust release process

## Release scope

Releases from this repository contain the Rust command-line executable for
Linux x86_64, macOS x86_64, and Windows x86_64. They are separate from releases
of the original DockQ project. The Rust CLI runs without Python.

The Rust implementation preserves the core scoring workflows and passes the
included numerical reference checks. It is not a drop-in replacement for every
Biopython parser behavior or for the original Python API. Read README.md and
MIGRATION_STATUS.md before distributing it as a substitute for an existing
Python-based workflow.

## Validation gate

Before tagging a release, the Rust CI workflow must pass on all three operating
systems. Each platform job checks formatting, Clippy, all targets and features,
a locked release build, and a representative scoring invocation. The release
workflow repeats those checks against the tagged commit, creates and smoke-tests
each executable, and bundles the project and third-party license texts.

See TEST_REPORT.md for the result of the latest cross-platform run. Do not
describe a platform as supported until its job and release artifact job pass.

## Create a release

Use a tag with the prefix rust-v, for example rust-v2.1.3. Pushing the tag runs
the release workflow. It builds one archive per supported platform and publishes
the archives as assets on a GitHub Release in this repository.

Each archive contains:

- The platform's DockQ executable.
- The root MIT license and bundled third-party dependency license notices.
- This README, build commit and compiler metadata, and SHA-256 checksums.

Verify SHA256SUMS.txt before using an archive. The GitHub release is not a PyPI
or crates.io publication and does not change the original DockQ project.

## Reproduce release checks locally

From the repository root, with stable Rust and Python 3 available:

    cargo fmt --manifest-path rust/Cargo.toml --all -- --check
    cargo clippy --locked --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings
    cargo test --locked --manifest-path rust/Cargo.toml --all-targets --all-features
    cargo build --locked --release --manifest-path rust/Cargo.toml
    python scripts/generate_third_party_licenses.py --output THIRD_PARTY_LICENSES.txt
    rust/target/release/DockQ examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb --mapping AB:AB --short

Cross-platform behavior must be checked on the corresponding operating system;
a Linux build or cross-compiled binary is not a substitute for the hosted
Windows and macOS jobs.
