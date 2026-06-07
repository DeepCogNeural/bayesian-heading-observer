# Bayesian Heading Observer

Code companion for Bayesian observer models of human heading perception from optic flow.

This project studies how humans infer self-motion direction from noisy visual motion, and why the final reported action can be biased even when the internal perceptual estimate is close to statistically efficient.

## Why It Matters

For VR/XR navigation, user bias is not just "behavioral noise." A useful system needs to know where the bias enters:

- sensory encoding of optic flow,
- Bayesian prior integration,
- memory and serial dependence,
- or the final perception-to-action mapping.

This repository packages the modeling idea in a readable form, with a synthetic demo and the original MATLAB research scripts kept separate from subject-level data.

<p align="center">
  <img src="docs/pipeline.svg" alt="Bayesian heading observer pipeline" width="100%">
</p>

## Publications

**Co-first author:** Sun, Q.*, **Xu, L.H.***, Stocker, A.A. (2025). A linear perception-action mapping accounts for response range-dependent biases in heading estimation from optic flow. *PLOS Computational Biology*, 21(6), e1013147.  
[Paper](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1013147)

**First author:** Xu, L.H., Sun, Q., Zhang, B., Li, X. (2022). Attractive serial dependence in heading perception from optic flow occurs at the perceptual and postperceptual stages. *Journal of Vision*, 22(12), 11.  
[Paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC9652722/)

## One-Command Demo

```bash
python3 -m pip install -r requirements.txt
python3 -m demo.run_demo
```

Expected outputs:

```text
outputs/model_prediction.png
outputs/posterior_heatmap.png
```

The demo uses synthetic data. It is designed for fast inspection of the model mechanics, not for reproducing paper figures from private participant files.

## What The Demo Shows

The runnable Python demo implements a compact version of the observer logic:

1. Build a center-biased prior over heading.
2. Transform the heading axis through efficient coding.
3. Generate noisy sensory measurements.
4. Infer the posterior over heading.
5. Apply a linear perception-to-action gain.
6. Plot predicted response bias and response distributions.

## Main Modules

| Path | Role |
| --- | --- |
| `src/bayesian_heading_observer/model.py` | Compact Python implementation for the synthetic demo |
| `demo/run_demo.py` | One-command entry point |
| `docs/pipeline.svg` | Project pipeline diagram |
| `matlab/original/` | Original MATLAB research scripts without subject-level data |

## Original MATLAB Code

The original research code is preserved under `matlab/original/`.

Key routines:

- `fun_BayesInference.m`: efficient-coding Bayesian observer inference.
- `main_GroupMLE.m`: group-level maximum-likelihood fit.
- `main_EachSubjFitParam.m`: subject-level parameter fitting.
- `main_FitPrior.m`: prior fitting.
- `plot_HeatMap.m`: response-distribution visualization.

Subject-level `.mat` files are not included here. This keeps the public repository clean and prevents participant-level files or file-name identifiers from being exposed.

## Research Contribution

The core contribution is not just fitting a curve. The model separates:

- statistical inference from noisy optic-flow input,
- efficient coding constraints,
- response-range effects,
- and the perception-to-action transformation that creates systematic report bias.

That decomposition is useful for perception science and for applied VR/XR systems where a human user must infer heading and act under uncertainty.

## Citation

```bibtex
@article{sun_xu_stocker_2025_heading_mapping,
  title = {A linear perception-action mapping accounts for response range-dependent biases in heading estimation from optic flow},
  author = {Sun, Qichao and Xu, Linghao and Stocker, Alan A.},
  journal = {PLOS Computational Biology},
  volume = {21},
  number = {6},
  pages = {e1013147},
  year = {2025},
  doi = {10.1371/journal.pcbi.1013147}
}

@article{xu_2022_serial_dependence_heading,
  title = {Attractive serial dependence in heading perception from optic flow occurs at the perceptual and postperceptual stages},
  author = {Xu, Linghao and Sun, Qichao and Zhang, Biao and Li, Xingshan},
  journal = {Journal of Vision},
  volume = {22},
  number = {12},
  pages = {11},
  year = {2022}
}
```

## Data Note

This public repository intentionally uses a synthetic demo. The research papers describe the experimental data and modeling results; subject-level data files should be shared only through the appropriate data-release channel.
