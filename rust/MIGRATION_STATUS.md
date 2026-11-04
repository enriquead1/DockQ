# Migration implementation status

The Rust port lives in `rust/` alongside the unchanged Python implementation.
The required package implementation is present. This is an experimental release
candidate validated on the supplied examples and synthetic edge cases, not a claim
of compatibility with every structure Biopython can read.

Three GPT-6 Luna agents at high reasoning effort worked through successive
assignments. Routine packages rely on their owners' self-checks; the lead reviewed
the harder alignment, geometry, numerical compatibility, mapping, and scoring work
and performed cross-module scientific acceptance.

| Package | Primary implementation owner | Delivery |
|---|---|---|
| P01 Shared contracts | Lead | `CONTRACTS.md`, `src/types.rs`, `src/error.rs` |
| P02 Scaffold/CI | Luna scaffold | Manifest, lockfile, Rust CI workflow |
| P03 Python reference | Lead | `../compat/generate_reference.py`, recorded fixtures |
| P04 PDB normalization | Lead | `src/io/pdb.rs`, `normalize.rs` |
| P05 mmCIF | Lead | `src/io/mmcif.rs` |
| P06 Loading/gzip | Luna loader | `src/io/load.rs` |
| P07 Alignment | Luna scaffold | `src/alignment.rs`, 900 exhaustive small sequence fixtures |
| P08 Atom selection | Luna loader | `src/selection.rs` |
| P09 Geometry | Luna loader | `src/geometry.rs` |
| P10 Contacts | Luna scaffold; lead compatibility refinement | `src/contacts.rs` |
| P11 Polymer/peptide scoring | Lead | `src/scoring/polymer.rs` |
| P12 Ligand symmetry | Luna loader | `src/scoring/ligand.rs` |
| P13 Chain mappings | Lead; Luna scaffold acceptance | `src/mapping.rs`, search fixtures/tests |
| P14 Execution engine | Lead; Luna scaffold acceptance | `src/engine.rs`, deterministic parallel search tests |
| P15 CLI/output | Luna release | `src/cli.rs`, `src/output.rs`, `src/main.rs` |
| P16 Integration | Lead and Luna agents | Reference/search tests and `../compat/compare_cli.py` |
| P17 Release preparation | Luna release and Luna loader | Manual artifact workflow, README, RELEASE guide, local Linux smoke |

## Acceptance and reproduction

Local acceptance: **56 Rust tests pass**, including 900 alignment pairs, seven
mapping fixtures, nine explicit-mapping scoring cases, and deterministic search
across worker counts. Formatting, strict Clippy, and a locked release build pass.
The full CLI harness checks 15 scenarios: all numeric JSON comparisons pass;
12/15 full checks pass, with three text-rounding differences deliberately exposed.
See `../compat/CLI_ACCEPTANCE.md` and its captured output for exact results and
the separately identified Python diagnostic cache quirk.

From the repository root with Rust installed:

```sh
cargo fmt --manifest-path rust/Cargo.toml --all -- --check
cargo clippy --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings
cargo test --manifest-path rust/Cargo.toml --all-targets --all-features
cargo build --manifest-path rust/Cargo.toml --release --locked
./rust/target/release/DockQ examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb --short
```

The Rust tests consume checked-in Python fixtures and do not require Python at
runtime. Regenerating fixtures or running the differential CLI tool requires the
reference environment described in `../compat/README.md`. The Linux toolchain and
reference virtual environment used during this implementation are isolated under
`/tmp/dockq-rust/` and `/tmp/dockq-reference/`; no system installation is assumed.

## Compatibility boundaries

- Contact counts, residue/atom correspondence, and ordered mappings are checked
  exactly on the acceptance corpus. Rigid geometry uses float64; baseline input
  and contact arithmetic use float32. Absolute tolerances are 1e-4 Å for RMSDs
  and 1e-5 for scores and other floating metrics. This is numerical agreement,
  not bitwise identity. Rounded output near a rounding boundary can differ.
- The compiled kernel's early-exit behavior and initial distance sentinel are
  preserved, including non-minimum distances on controlled examples. Rust is
  targeting the compiled reference rather than silently adopting the exhaustive
  Python fallback.
- Candidate enumeration is lazy and execution uses bounded ordered batches plus
  a bounded interface cache. It does not reproduce the Python progress bar or
  its process-pool implementation. Equal scores retain the first ordered candidate.
  Exact `count_mappings` is available separately with checked u128 arithmetic;
  it enumerates candidates and can take factorial time, so the engine never
  requests it merely to show progress.
- The legacy CLI mapping syntax retains single-character chain IDs. Parsing and
  the Rust library preserve longer mmCIF IDs, but richer explicit CLI mapping
  syntax is not introduced in this port.
- Invalid inputs use typed errors. Detailed warning text and permissive recovery
  from all malformed records are not Biopython-compatible. Parsing preserves the
  selected model's data rather than reproducing accidental cross-model sequence
  accumulation. Full mmCIF dictionary validation, structure writing, and unrelated
  Biopython metadata are outside the migration scope.
- Empty required atom selections and non-isomorphic ligand graphs produce errors;
  Rust does not emit Python's infinity/NaN or incidental traceback outputs.
- Nested per-interface `chain_map` diagnostics describe the selected mapping,
  avoiding Python's cached-dictionary mutation. The CLI acceptance report records
  which baseline comparisons explicitly exclude that diagnostic quirk.
- The ligand path preserves the original full-native-interface index behavior.
  Its graph matching is unlabeled, as in the baseline. See the ligand module's
  compatibility notes for the missing-common-atom element-list behavior.
- The public Rust API uses native Rust structures. Existing Python callers passing
  Biopython objects are not preserved; Python bindings are optional package O01.

macOS and Windows release workflows are prepared but require execution on those
platforms. No release has been published. Optional packages O01–O03 (Python bindings,
further profile-driven optimization, and an extended external corpus) were not
selected for this implementation batch.
