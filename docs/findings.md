# Findings, one by one

This file explains the checks that are more than a plain "yes", in simple words and with their numbers. The ids (D13, B2, ...) are the ids of [`results/all_checks.csv`](../results/all_checks.csv), where every check has the statement of the paper, the value in the paper, what I found and a status. All numbers come from `run_all` with MATLAB R2024b. "Version 1" is the paper of January 2022, "version 2" the paper of April 2023.

## 1. From the raw recordings to the benchmark files

**D11, MATCH: the processing of Listing 1 is exactly right.** I wrote the processing again from the text (Chebyshev type I filter of order 4, 2 Hz, 0.2 dB ripple, `filtfilt`, then keep every 25th sample) and got exactly the published files (difference 0). One detail is not in the text: the 11 training recordings are joined first and filtered as one long signal. Filtering every recording on its own would change the positions by up to 0.0066 deg.

**D13, UNDOCUMENTED: the filter makes every signal 4.5 % smaller.** A "low pass filter" sounds like it keeps slow signals as they are. But a Chebyshev type I filter of even order has its gain at the bottom of the ripple at 0 Hz, here -0.2 dB, so 0.977. `filtfilt` runs the filter forward and backward, so the gain is squared: 0.955. In the data, the benchmark positions are 0.956 times the raw positions for every joint. This does not change the NRMSE of a model trained on these files, but anyone who compares the benchmark data with the raw data, or with a physical model, has to know it.

**D10, DEVIATION: the sample time is not exactly 0.1 s.** The official script makes the time vector with `linspace(0, N*dt, N)`. The correct form is `(0:N-1)*dt`. So the steps are 0.1000025 s in the training file and 0.1000275 s in the test file.

**O3, OBSERVATION: the recordings are joined in alphabetical order, not in time order.** The files are named by the time of recording, for example `recording_2021_12_15_21H_3M`. The official script takes them in `dir()` order, so `21H_3M` comes after `21H_32M`. The last file in this order (`22H_58M`) is the test data. This does not break anything, but it is good to know when you look for a file in the training data.

## 2. The planned paths (Section 2.1)

**D2b, MATCH: every path is a sum of 10 sines and cosines.** A least-squares fit with 10 harmonics of 1/60 Hz fits all 72 runs of all 6 joints with an error below 7e-6 deg. With 9 harmonics the error is 2.7 deg, so all 10 are really used.

**D2c, DEVIATION: eq. (1) as printed is not complete.** The real paths need a constant term (the start position, which comes from integrating the velocity series). Without it the fit error is 14.9 deg. The printed formula also leaves out 2π and the sample time inside the sine and cosine.

**D7b, DEVIATION: "a maximum frequency of 1 Hz".** The text says the frequency grid of the paths goes up to 1 Hz. With 10 harmonics of 1/60 Hz the highest frequency is 0.167 Hz, and in the data there is nothing stronger than -60 dB above 0.198 Hz. (D7: the other statement, "position spectrum less than 0.3 Hz", is right.)

**D8b, UNCLEAR: acceleration and jerk limits.** Eq. (2b) says that acceleration and jerk stay within limits, but the paper gives only position and velocity limits (Table 7). The largest values in the data are 18.5 to 52.2 deg/s² and 17 to 46 deg/s³, depending on the joint. Without the limits this can't be checked.

## 3. Sensors and controller (Table 3, Appendix A)

**R2, UNDOCUMENTED: the velocity channels are not separate measurements.** Table 3 says the joint velocity is "measured by" the resolver and the secondary encoder. In the data, every velocity channel is the numerical derivative of the matching position channel, one sample (4 ms) later: correlation 0.99997 or higher, gain 0.9997 to 1. So the velocity channels add no new information.

**A2, UNCLEAR: sensor resolution.** Table 10 gives the resolution of the sensors (about 5e-6 deg for the encoders, 82e-6 to 240e-6 deg for the resolvers). The recorded positions are not rounded to steps (the smallest difference between two values is 6e-11 deg), so the resolution can't be read from the data. The noise while the robot stands still is about 1e-5 to 2e-4 deg.

**A1, CONSISTENT: gearbox deformation.** The difference between the motor side and the link side of joints 1 to 3 has a standard deviation of 0.008 to 0.052 deg. This fits "about 0.01 to 0.05 deg" in Appendix C.3.

**D16, DEVIATION: the torque is not the sum of the two other torque channels.** Table 3 says the motor torque τ is the sum of the feed-forward torque τ_FF and the feedback torque τ_FB. In the data, the sum explains almost nothing of τ: R² is between -0.78 and 0.21. For example, the mean of τ on joints 2 and 3 is -6.75 and -9.83 Nm, while the mean of τ_FF + τ_FB is 0 for every joint. Even the best weighted combination of the two channels reaches only R² 0.5 to 0.75.

**D17, UNCLEAR: the control law of eq. (13).** I fitted τ_FB to the PD terms P (q_R - q) + D (q̇_R - q̇). This explains τ_FB well on joints 2, 3 and 6 (R² 0.95 to 0.99), but not on joints 1, 4 and 5 (R² 0.12 to 0.44). Maybe the controller has parts that the paper does not describe, but with the published channels I can't decide it.

## 4. The inputs of the inverse dataset (Table 2, Section 3)

**D14, UNDOCUMENTED: the inputs are filtered and late.** The paper says the position, velocity and acceleration inputs are shifted by 4 ms. What I found in the data:
- The position is shifted by one raw sample (4 ms), as written, but it went through the filter once more, so it is 0.956 times the forward position.
- The velocity and acceleration are not the measured signals. The official script computes them from the position with the filters s/(1 + 0.5 s) and s²/(1 + 0.5 s)², simulated forward in time with `lsim`. These filters delay the signals: compared with the measured velocity, the velocity input is about 0.5 s late and 10 % smaller, and the acceleration input is about 0.9 s late and 18 % smaller.

Half a second is not small here: the fastest component of the paths (0.167 Hz) has a period of 6 s. After the derivative filters, all three inputs go through the 2 Hz filter once more.

**D15, CONSISTENT:** at the start of the data the velocity and acceleration inputs are exactly 0, because `lsim` starts the filters from a zero state while the robot stands still.

**D14b, CONSISTENT:** the measured position follows the reference with a delay of about one sample of 4 ms ([1 2 -1 1 1 1] samples for joints 1 to 6), which fits the 4 ms of controller computation time in the text.

## 5. The baselines and the metrics (Sections 4 and 5)

**B1 and B4, MATCH:** both baselines of version 2 are reproduced exactly from scratch, all 28 numbers of Table 4 and of Table 5. The `n4sid` model is stable. The `fminunc` matrix is the least-squares solution (largest difference 4.8e-6), so the optimizer is not important here.

**B2, DEVIATION: Listing 2 does not run as printed.** `lsim(robot_model, u_test, time_test)` stops with the error "the time step must match the sample time of discrete-time models", because of D10. The listing also uses `time_true`, which is not a variable of the data file. With an exact 0.1 s time vector everything works and gives Table 4.

**M1, CONSISTENT: which standard deviation is in the NRMSE?** Eq. (5) divides by "the standard deviation regarding position" but doesn't say of which data. Table 4 comes out only with the standard deviation of the test data (with N - 1). With the one of the training data, the test NRMSE values would be different (for example 0.543 instead of 0.638 for joint 1).

**M2, CONSISTENT: NRMSE and R² say the same thing.** When both use the same data, R² = 100 (1 - NRMSE²). All printed pairs of version 2 follow this to 0.085 (the rounding of NRMSE to 3 decimals). So the second number adds no information.

**B3, OBSERVATION: the zero initial state.** The paper starts the simulation of the forward model from a zero state. If the start state is estimated instead, the test values become a bit better: NRMSE 0.8200 instead of 0.8252, R² 32.04 % instead of 31.14 %.

## 6. Version 1 and what version 2 changed

**L1 and L2, MATCH:** with the models that the authors saved with version 1, both tables of version 1 are reproduced exactly, but only with the R² formula of the version 1 code (L3).

**L3, MATCH: the R² correction of version 2.** The official version 1 code computes the total variation as `sum((y - mean(y_sim)).^2)`, around the mean of the model output instead of the measured signal. That is why the version 1 pairs don't follow R² = 100 (1 - NRMSE²): they miss it by up to 293 points. With the correct formula, the mean test R² of version 1 is -40.4 % for the forward model and -40.4 % for the inverse model (the two values happen to be almost equal), instead of the printed 22.3 % and 18.3 %. Version 2 says it "corrected the calculation of the coefficient of determination", and this is that correction.

**L4, MATCH:** the saved version 1 inverse matrix is the least-squares solution (its training cost is the least-squares optimum).

**L6, OBSERVATION: where the better inverse result of version 2 comes from.** The test NRMSE of the inverse model went from 1.05 (version 1) to 0.61 (version 2). Version 1 fits τ = A [q; q̇; q̈], a model without a constant term. Version 2 normalizes the data (subtract the mean, divide by the standard deviation), and this adds a constant term without saying so. Plain least squares on the original data with an extra constant input gives exactly the test values of Table 5 of version 2. The constant is mostly the gravity torque on joints 2 and 3. So the improvement comes from the constant term, not from the change of the optimizer.

**L5, CONSISTENT:** the two forward models are really different: test NRMSE 1.117 (version 1, `ssest`) against 0.825 (version 2, `n4sid`), correct R² -40.4 % against 31.1 %.

**L7, MATCH: the version 1 `ssest` model trained again.** I trained it again from scratch with the settings of the official code (12 states, focus on simulation). It took 8265 s (about 2.3 hours) on my computer. Its output differs from the saved model of the authors by at most 5.1e-6 deg, and all numbers of the table are the same.

**L8, CONSISTENT: the version 1 inverse matrix trained again.** The official code starts `fmincon` from random numbers without a fixed seed (`randn`) and stops it after 10000 evaluations, before it reaches the optimum. So the exact matrix can't be made again. With seeds 1, 2 and 3 the result ends within 0.0155 of the least-squares optimum, and the NRMSE values differ from the paper by at most 0.001.

## 7. Section 5, the figures and the text

**O1, OBSERVATION: the robot runs in closed loop.** The measured positions follow the reference with an RMS error of 0.035 to 0.26 deg. If I use 0.955 times the reference position as a "model" (0.955 is the filter gain of D13), the test NRMSE is 0.002 to 0.025. This is not a fair model, because the reference is not an input of the benchmark. But it explains why the forward task (torque in, position out) is hard: the controller decides where the joints go, and the torque is only what it needs to get there.

**D22, CONSISTENT:** the paper says that different torques lead to the same, almost constant position. At the 84 rest points in the home pose the position is the same within 0.018 deg, but the filtered torque differs by up to 23 % to 71 % of the full torque range of the joint.

**O2, OBSERVATION: how well the robot repeats a path.** Every path was driven twice. Between the two runs the position is almost identical (NRMSE about 1e-5). The torque repeats less well: median NRMSE 0.014 to 0.035, and in the worst pair up to 0.64 on joint 2. So the same motion does not always need the same torque, which also limits how good any torque model can be.

**F1, DEVIATION: Figures 2 and 4 don't show the benchmark data.** The text says the torques "as presented in Fig. 2 and 4" are applied "without modification". But the figures show every torque minus its first value (the input that the version 1 code gives to the model). For example τ2 of the training data is between -15.3 and 7.2 Nm in the data file, between -2.3 and 20.2 Nm after subtracting the first value, and between about -2 and 20 Nm in the figure. The repository has both versions of these figures (`fig2_...` and `fig2_..._minus_initial_value_as_in_pdf`).

**F2, CONSISTENT:** the other figures (3, 5, 7, 8, 9) look like the ones in the PDF in shape and axis range, also small details like the start of q3 in Fig. 7 and the offset of q3 in Fig. 9 of the version 1 model. This is a visual comparison.

**X1, DEVIATION:** Section 2.2 says "position control 1250 Hz, velocity control 2500 Hz and current control 20 kHz". Table 8 gives cycle times of 0.8, 0.2 and 0.05 ms, which are 1250, 5000 and 20000 Hz. One of the two is wrong for the velocity loop.

**X2, CONSISTENT:** "the motor power supply ranges from 5.5 kW to 16 kW" fits Table 9 (5.5 kW for joints 4 to 6, 16 kW for joints 1 to 3).

**X3, DEVIATION:** eq. (4) writes gravity and the hydraulic counterbalance as g(q̇_R) and τ_H(q̇_R), as functions of the velocity. In Appendix A both depend on the position (eq. (12) and eq. (14) to (18)), so eq. (4) should have q_R.

**X4, DEVIATION:** the caption of Fig. 6 says "Black: Joint 1. Red: Joint 2. Purple: Joint 3. Green: Joint 4. Blue: Joint 5. Brown: Joint 6." The figure uses the default MATLAB colors (blue, orange, yellow, purple, green, light blue), and there is no black or brown line. My `fig6_spectrum.png` uses the colors of the caption.

The other checks (the amount of data, the 36 paths driven twice, the home pose, the joint limits, the test paths not being in the training data, the sizes of the signals in Section 5.2, and more) are confirmed. Their numbers are in [`results/all_checks.csv`](../results/all_checks.csv) and in the logs of [`results/logs/`](../results/logs/).
