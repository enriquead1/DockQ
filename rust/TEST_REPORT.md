# Rust validation — 2026-11-04

Tested the current working tree on Linux using Rust 1.99.1. The Rust and
compatibility implementation files were already untracked when testing began;
this report refers to those local files, not a committed Rust revision.
No implementation files were changed during this validation.

| Check | Result |
|---|---|
| Locked, offline tests, all targets/features | 56 passed: 48 unit, 3 reference, 5 search |
| Formatting | Passed |
| Clippy, all targets/features, warnings denied | Passed |
| Locked, offline release build | Passed |
| Python/Rust CLI differential harness | 12/15 full cases passed; 3 text-rounding failures |
| Additional nucleic-acid CLI differential | Passed, including JSON and text |
| Additional CLI smoke/error cases | 14 passed |
| Minimal-environment release executable | Passed; fixed AB:AB example scored 0.943 |
| Linux dynamic dependencies | libc and libgcc runtime; no Python library |

The CLI comparison used Python 3.12.2, NumPy 1.26.4, Biopython 1.85, and
the compiled DockQ operations extension in `/tmp/dockq-reference`.

## Compatibility findings

The differential harness exited 1 because `1exb-short`, `1exb-partial`, and
`1exb-complete` failed exact normalized text comparison. All three displayed
LRMSD as `0.000` in Python and `0.001` in Rust for native interface EG:

- Python: 0.000497884823376 Å
- Rust: 0.000502755378778 Å
- Absolute difference: approximately 0.0000048705554 Å

All numeric JSON comparisons passed the existing absolute tolerances: `1e-4` Å
for RMSDs and `1e-5` for other floating metrics. Integer counts and selected
top-level mappings agreed. The largest reported LRMSD delta across the main
CLI corpus was approximately `4.44393463e-5` Å, on 1A2K.

The harness excluded nested `chain_map` fields when they differed despite matching
top-level best mappings, as documented in `compat/compare_cli.py`: 14 interface
diagnostics in `1exb-partial`, two in `1exb-native-subset`, and two in
`small-molecule`. Thus this result does not claim full JSON identity.

The additional nucleic-acid case used `rust/tests/data/nucleic.model.pdb` and
`rust/tests/data/nucleic.native.pdb` with `--mapping AB:AB`. Its largest LRMSD
difference was approximately `4.77503067e-7` Å.

Additional CLI checks verified help/version success and nonzero, informative
errors without panics for: no arguments, an unknown flag, a missing mapping value,
zero workers, zero chunk size, negative allowed mismatches, duplicate mapping,
an unknown chain, missing input, empty input, corrupt gzip, and a JSON destination
whose parent directory does not exist.

## Reproduction

The installed toolchain is outside PATH. From the repository root:

```sh
export CARGO_HOME=/tmp/dockq-rust/cargo
export RUSTUP_HOME=/tmp/dockq-rust/rustup
export PATH="$CARGO_HOME/bin:$PATH"
cargo test --locked --offline --manifest-path rust/Cargo.toml --all-targets --all-features
cargo fmt --manifest-path rust/Cargo.toml --all -- --check
cargo clippy --locked --offline --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings
cargo build --locked --offline --release --manifest-path rust/Cargo.toml
/tmp/dockq-reference/bin/python -u compat/compare_cli.py --memory
env -i PATH=/usr/bin:/bin rust/target/release/DockQ examples/1A2K_r_l_b.model.pdb examples/1A2K_r_l_b.pdb --mapping AB:AB --short
ldd rust/target/release/DockQ
```

These checks validate the supplied corpus and local Linux runtime. They do not
establish macOS/Windows behavior or compatibility across an external structure
corpus. The three text differences reproduce previously documented findings;
no new failure was observed in the checks above.
