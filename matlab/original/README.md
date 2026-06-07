# Original MATLAB Research Code

This folder contains the core MATLAB scripts from the Bayesian observer modeling project.

It intentionally does not include subject-level `.mat` datasets in this public repository. The public demo in `demo/` uses synthetic data so the model can be inspected without exposing participant files.

Key files:

- `fun_BayesInference.m`: Bayesian observer and efficient-coding inference routine.
- `main_GroupMLE.m`: group-level maximum-likelihood fit.
- `main_EachSubjFitParam.m`: subject-level parameter fit.
- `main_FitPrior.m`: prior fitting.
- `main_iddFit.m` and `main_Idd_continous.m`: individual-difference analyses.
- `plot_GroupContinous.m` and `plot_HeatMap.m`: plotting utilities.
