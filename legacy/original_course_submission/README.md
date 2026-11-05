# My original final project (February 2026)

These are the MATLAB scripts I handed in for the final project of the System Identification course
(fall 2025, 1404). The only change is the path to the data: the scripts had the full path of the data
folder on my computer, now they use `..\..\data\Robot_Identification_Benchmark_With_Raw_Data`.
The report, the slides and the video are not in this repository.

The idea of the project was: first reproduce the linear baseline of the paper, then try nonlinear
models (NLARX and Hammerstein-Wiener) and see if they are better.

| File | What it does |
|---|---|
| `STEP0A_CheckDatasetStructure.m` | lists the files of the data archive |
| `STEP1_InspectForwardDataset.m` | shows the variables of the forward data file |
| `STEP2_BuildIddata_ForwardMIMO.m` | makes `iddata` objects for training and test, saves `step3_iddata.mat` |
| `Baseline_linear_MIMO.m` | n4sid models with 8 to 16 states, test fit for each (`TAB_STEP3_FitVsNx.csv`) |
| `Evaluate_baseline_with_NRMSE.m` | NRMSE and R2 per joint for 12 states and for the best order |
| `STEP4B_PaperBaseline_LinearForward_n4sid.m` | the baseline of the paper (normalized data, n4sid, 12 states) |
| `STEP6_0_DataSplit_Forward.m` | splits the training data: first 85 % for estimation, last 15 % for validation |
| `STEP6_1_Normalize_LikePaper.m` | normalizes with the mean and std of the estimation part |
| `STEP6_2_NLARX_ReducedSweep.m` | NLARX with a sigmoid network, one model per joint, small grid of orders |
| `STEP8_NLHW_ALLJOINTS_pwlinear.m` | Hammerstein-Wiener with a piecewise linear input nonlinearity, one model per joint |
| `STEP8_NLHW_MISO.m` | first try of Hammerstein-Wiener on joints 1 and 3 with three nonlinearities |
| `STEP9_ModelComparison_UniformMetrics.m` | the final table: baseline, NLARX and NLHW with the same NRMSE and R2 |

## Problems I found later

- **R2 formula in STEP4B.** The line `SST = sum((y_true - mean(y_hat)).^2)` takes the mean of the
  model output instead of the measured signal. It is the same formula as in the official code of
  version 1 of the paper (the script says "same style as paper code"), where it was corrected
  in version 2 of the paper. Because of this the
  R2 values on page 11 of my report are wrong: the mean is 32.35 % in the report, the right value
  is 31.14 %, the same as Table 4 of the paper. The NRMSE values were right (mean 0.8252), and the
  final table on page 24 (from STEP9) uses the correct formula.
- **File names between the steps do not match.** STEP6_1 saves `STEP6_1_norm.mat`, but STEP6_2
  loads `STEP6_1_norm_like_paper.mat` and STEP8_NLHW_MISO loads `step6_norm.mat`. These were saved
  by earlier versions of STEP6_1. I checked the three saved files: they hold exactly the same data,
  so the results are not affected, but the scripts do not run one after the other as they are.
- **A missing script.** The results file `STEP7_FAST_AUG_results.mat` exists, but its script is not
  in the submission.

The nonlinear part (NLARX and NLHW) is checked again in the second part of this project.
