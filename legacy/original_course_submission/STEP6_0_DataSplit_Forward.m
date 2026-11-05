%% STEP6_0_DataSplit.m  (Train/Val/Test Split)
clc; clear; close all;

load("step3_iddata.mat","z_tr","z_te","Ts");

Ntr = length(z_tr.y);
valRatio = 0.15;                 % 15% validation (last part)
Nva = round(valRatio * Ntr);
Ne  = Ntr - Nva;

z_est = z_tr(1:Ne);
z_val = z_tr(Ne+1:end);

fprintf("dt (estimated) = %.8f s\n", Ts);
fprintf("Estimation samples: %d\n", length(z_est.y));
fprintf("Validation samples: %d\n", length(z_val.y));
fprintf("Test samples: %d\n", length(z_te.y));

save("STEP6_0_data_ready.mat","z_est","z_val","z_te","Ts");
disp("Saved: STEP6_0_data_ready.mat");
