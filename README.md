# DockQ Rust

A Rust command-line program and library for scoring protein, nucleic-acid,
peptide, and small-molecule docking models.

This repository's main branch is the Rust implementation. It is an independent
implementation of DockQ v2 for this repository, not an official release of the
original DockQ project. The original Python implementation and its documentation
are preserved in src/ and docs/PYTHON_README.md.

## Status

The Rust CLI works without Python at runtime. The compatibility suite checks the
included reference corpus; it does not establish identical behavior for every
file accepted by Biopython. Known compatibility limits and numeric tolerances
are listed in rust/README.md and rust/MIGRATION_STATUS.md.

CI checks formatting, lint, tests, release builds, and a scoring smoke example on
Linux, macOS, and Windows. See the Actions page for the status of each platform.

## Clone this fork

Clone the Rust implementation from this repository:

```sh
git clone --branch main https://github.com/enriquead1/DockQ.git
cd DockQ
```

## Build

Install a stable Rust toolchain, then run from the repository root:

    cargo build --locked --release --manifest-path rust/Cargo.toml

The executable is rust/target/release/DockQ on Linux and macOS or
rust/target/release/DockQ.exe on Windows.

## Quick start

    rust/target/release/DockQ \
      examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb \
      --mapping AB:AB --short

The mapping format is MODELCHAINS:NATIVECHAINS. Use --help for all command
options and --json results.json for structured output.

## Binary downloads

Download the current [DockQ Rust v2.1.3 release](https://github.com/enriquead1/DockQ/releases/tag/rust-v2.1.3). It includes Linux, macOS, and Windows x86_64 archives. Each archive contains the executable, README, MIT license, third-party dependency license texts, build metadata, and SHA-256 checksums. Verify the checksums before use. Future Rust releases are published from this repository and remain separate from releases of the original DockQ project.

## Project notes

- Rust build, CLI usage, and known compatibility limits: rust/README.md
- Migration and validation status: rust/MIGRATION_STATUS.md
- Release and platform support: rust/RELEASE.md
- Cross-platform acceptance report: rust/TEST_REPORT.md
- All-against-all benchmark method and results: benchmarks/all_vs_all/BENCHMARK_FINDINGS.md

If you use DockQ, cite the DockQ v2 paper: https://doi.org/10.1093/bioinformatics/btae586.
