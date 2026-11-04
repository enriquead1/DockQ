# DockQ Rust (experimental)

The Rust crate now provides a working command-line scorer and library for the
main DockQ workflows. It remains experimental: the Python package is still the
established distribution, and the Rust migration has not completed the full
platform, compatibility, and release review gates. Do not treat this crate as a
drop-in replacement for every Python API or input accepted by Biopython.

The CLI reads PDB and mmCIF coordinate files, including gzip-compressed files;
scores protein and nucleic-acid interfaces, CAPRI peptide interfaces, and
small-molecule interfaces; searches chain mappings; and writes text or JSON
results. It runs without Python at runtime. Mapping search supports parallel
workers while retaining deterministic candidate ordering.

## Build and test

Use a stable Rust toolchain and the committed lockfile:

```sh
cargo build --locked --release --manifest-path rust/Cargo.toml
cargo test --locked --manifest-path rust/Cargo.toml
```

The binary is `rust/target/release/DockQ` (`DockQ.exe` on Windows). Check its
options with:

```sh
rust/target/release/DockQ --help
```

For a reproducible local build with dependencies already cached, add `--offline`
to the Cargo commands.

## Example

Score the included 1A2K model against its native structure and constrain the
mapping to model chains A and B against native chains A and B:

```sh
rust/target/release/DockQ \
  examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb \
  --mapping AB:AB --short
```

The mapping syntax is `MODELCHAINS:NATIVECHAINS` and currently accepts
single-character chain identifiers. Use `--small_molecule` to include
hetero-residue chains and run ligand scoring. Use `--json results.json` to write
structured output.

## Validation and known limits

`cargo test` includes focused tests and differential checks against the pinned
Python/Cython corpus in `compat/reference.json`. Counts are checked exactly;
RMSD fields are compared with an absolute tolerance of `1e-4` Å, and
other floating-point metrics with `1e-5`. These tolerances describe the current
test harness, not a guarantee for every structure or platform.

The full [CLI comparison](../compat/CLI_ACCEPTANCE.md) passes numeric JSON
comparisons but records three strict text failures caused by LRMSD rounding at
three decimals. It also identifies Python's overwritten nested mapping diagnostics.
See [MIGRATION_STATUS.md](MIGRATION_STATUS.md) for package delivery and acceptance.

The current validation does not establish full compatibility with all malformed
files, metadata, or parser behavior available through Biopython. The CLI's
legacy mapping syntax is limited to one-character chain IDs, even though the
library preserves string chain IDs from mmCIF. Linux has been validated locally;
macOS and Windows builds and runtime behavior require their own checks. Consult
[RELEASE.md](RELEASE.md) for release status and platform validation.

For ligand symmetry matching, atom mappings index the filtered common-atom
arrays. Element labels are filtered with coordinates; the Python reference
passes unfiltered element labels when atom-name sets differ, so Rust avoids that
legacy mismatch in this case.

The executable needs no Python interpreter or Python package at runtime. It is
linked against the platform's normal system runtime libraries. Rust dependencies
are listed in `Cargo.toml` and pinned by `Cargo.lock`.

## License and scientific citation

Redistribute the repository's MIT `LICENSE` with binaries. Third-party Rust
dependency licenses also apply. Cite the DockQ v2 paper as described by the
project's [citation guidance](../README.md#citing-dockq).
