//! Protein/nucleic acid and CAPRI-peptide interface scoring.
use crate::alignment::align_chains;
use crate::contacts::{contact_stats, count_contacts, residue_distances};
use crate::error::Result;
use crate::geometry::{apply, fit, rmsd};
use crate::selection::{backbone_pairs, residue_coordinates};
use crate::types::*;

pub fn dockq_formula(fnat: f64, irms: f64, lrms: f64) -> f64 {
    (fnat + 1.0 / (1.0 + (irms / 1.5).powi(2)) + 1.0 / (1.0 + (lrms / 8.5).powi(2))) / 3.0
}

fn distances(
    a: &Chain,
    b: &Chain,
    ia: &[usize],
    ib: &[usize],
    cb: bool,
) -> Result<SquaredDistances> {
    let (ca, ga) = residue_coordinates(a, ia, cb)?;
    let (cc, gb) = residue_coordinates(b, ib, cb)?;
    residue_distances(&ca, &cc, &ga, &gb)
}

pub fn score_interface(
    model: [&Chain; 2],
    native: [&Chain; 2],
    options: &ScoringOptions,
) -> Result<Option<InterfaceScore>> {
    let threshold = if options.peptide { 4.0 } else { 5.0 };
    let interface_threshold: f32 = if options.peptide { 8.0 } else { 10.0 };
    let all_n: [Vec<usize>; 2] = std::array::from_fn(|i| (0..native[i].residues.len()).collect());
    let mut nd = distances(native[0], native[1], &all_n[0], &all_n[1], false)?;
    let nat_total = count_contacts(&nd, threshold);
    if nat_total == 0 {
        return Ok(None);
    }
    let mode = if options.no_align {
        AlignmentMode::Numbering
    } else {
        AlignmentMode::Sequence
    };
    let pairs = [
        align_chains(model[0], native[0], mode)?.matched_pairs(),
        align_chains(model[1], native[1], mode)?.matched_pairs(),
    ];
    let mi: [Vec<usize>; 2] = std::array::from_fn(|i| pairs[i].iter().map(|p| p.0).collect());
    let ni: [Vec<usize>; 2] = std::array::from_fn(|i| pairs[i].iter().map(|p| p.1).collect());
    let md = distances(model[0], model[1], &mi[0], &mi[1], false)?;
    if nd.rows != md.rows || nd.cols != md.cols {
        nd = distances(native[0], native[1], &ni[0], &ni[1], false)?;
    }
    let stats = contact_stats(&md, &nd, threshold)?;
    let fnat = stats.shared as f64 / nat_total as f64;
    let fnonnat = if stats.model == 0 {
        0.0
    } else {
        stats.non_native as f64 / stats.model as f64
    };
    if options.peptide {
        nd = distances(native[0], native[1], &ni[0], &ni[1], true)?;
    }
    let mut subsets = [Vec::new(), Vec::new()];
    for row in 0..nd.rows {
        for col in 0..nd.cols {
            if nd.values[row * nd.cols + col] < interface_threshold * interface_threshold {
                subsets[0].push(row);
                subsets[1].push(col);
            }
        }
    }
    let mut inter = AtomPairs::default();
    for i in 0..2 {
        // Python subset_atoms treats an empty collection like None (all pairs).
        let subset = if subsets[i].is_empty() {
            None
        } else {
            Some(subsets[i].as_slice())
        };
        let ap = backbone_pairs(model[i], native[i], &pairs[i], subset)?;
        inter.model.extend(ap.model);
        inter.native.extend(ap.native);
    }
    let irms = fit(&inter.model, &inter.native)?.rmsd;
    // Equal length uses group 2 as receptor. Never sort chain pairs here.
    let receptor = if native[0].residues.len() > native[1].residues.len() {
        0
    } else {
        1
    };
    let ligand = 1 - receptor;
    let rec = backbone_pairs(model[receptor], native[receptor], &pairs[receptor], None)?;
    let lig = backbone_pairs(model[ligand], native[ligand], &pairs[ligand], None)?;
    let transform = fit(&rec.model, &rec.native)?;
    let transformed: Vec<_> = lig.model.iter().map(|&p| apply(p, &transform)).collect();
    let lrms = rmsd(&transformed, &lig.native)?;
    let denominator = stats.shared + stats.non_native + nat_total;
    let f1 = 2.0 * stats.shared as f64 / denominator as f64;
    let metrics = PolymerMetrics {
        irmsd: irms,
        lrmsd: lrms,
        fnat,
        fnonnat,
        f1,
        clashes: count_contacts(&md, 2.0),
        nat_correct: stats.shared,
        nat_total,
        nonnat_count: stats.non_native,
        model_total: stats.model,
        len1: native[0].residues.len(),
        len2: native[1].residues.len(),
        class1: if receptor == 0 { "receptor" } else { "ligand" }.into(),
        class2: if receptor == 1 { "receptor" } else { "ligand" }.into(),
    };
    Ok(Some(InterfaceScore {
        dockq: dockq_formula(fnat, irms, lrms),
        metrics: Metrics::Polymer(metrics),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn formula_limits() {
        assert_eq!(dockq_formula(1.0, 0.0, 0.0), 1.0);
        assert!((dockq_formula(0.0, 1.5, 8.5) - 1.0 / 3.0).abs() < 1e-15);
    }
}
