# What changed since the course project

I handed in the final project in February 2026: 12 MATLAB scripts, a report and slides. The scripts are in [`legacy/original_course_submission/`](../legacy/original_course_submission/), unchanged except for the path to the data.

## What the course version did

1. Looked at the data files and made `iddata` objects for training and test.
2. Trained `n4sid` models with 8 to 16 states on the forward data (torque in, position out) and compared their test fit (`TAB_STEP3_FitVsNx.csv`: 11.2 % with 8 states, 16.2 % with 12 states, 16.7 % with 16 states).
3. Reproduced the forward baseline of version 2 of the paper (`STEP4B`: normalized data, `n4sid` with 12 states, focus on simulation). The NRMSE values were the same as Table 4 of the paper (mean 0.8252).
4. Tried nonlinear models: NLARX with a sigmoid network and Hammerstein-Wiener models, one model per joint, and compared them with the baseline (`STEP9`).

## What is new in this repository (part 1)

- **The whole paper is checked, not only one table.** The course version reproduced Table 4 of version 2. Now the code starts from the raw recordings, builds the benchmark files again, trains both baselines (forward and inverse) again, reproduces the tables of both versions of the paper and checks 53 statements of the text, each with a status ([`findings.md`](findings.md)).
- **The R² formula is fixed.** The course script used the formula of the official version 1 code, which measures the variation around the mean of the model output. So the R² values on page 11 of my report were wrong (mean 32.35 % instead of 31.14 %). Now `functions/r2.m` has the correct formula. The version 1 formula is kept in `functions/r2_version1.m`, only to reproduce the tables of version 1.
- **One command.** The course scripts had to be run one by one, by hand, and some of them load files that other scripts save under a different name. Now `run_all` runs everything in order and writes a log for every step.
- **No personal paths.** The course scripts had the full path of the data folder on my computer. Now the data is found in `data/`.
- **Results are saved with the code.** The tables, figures, logs and the list of all checks are in `results/`, so they can be compared with the paper without running anything.

## Not in part 1

- The order sweep (8 to 16 states) and the nonlinear models (NLARX and Hammerstein-Wiener) of the course version. I want to check them again before I add them here: the split of the training data, the normalization and one missing script (`STEP7_FAST_AUG`, whose results file exists but its script is not in the submission). This will be the second part of the project.
- The report, the slides and the presentation video of the course.
