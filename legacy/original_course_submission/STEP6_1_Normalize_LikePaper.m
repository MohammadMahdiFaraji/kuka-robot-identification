%% STEP6_1_NormalizeLikePaper.m  (Channel-wise mean/std on Estimation only)
clc; clear; close all;

load("STEP6_0_data_ready.mat","z_est","z_val","z_te","Ts");

Ue = z_est.u;  Ye = z_est.y;
Uv = z_val.u;  Yv = z_val.y;
Ut = z_te.u;   Yt = z_te.y;

muU  = mean(Ue,1);   sigU = std(Ue,0,1);  sigU(sigU<eps)=1;
muY  = mean(Ye,1);   sigY = std(Ye,0,1);  sigY(sigY<eps)=1;

UeN = (Ue - muU)./sigU;   YeN = (Ye - muY)./sigY;
UvN = (Uv - muU)./sigU;   YvN = (Yv - muY)./sigY;
UtN = (Ut - muU)./sigU;   YtN = (Yt - muY)./sigY;

z_est_n = iddata(YeN, UeN, Ts);
z_val_n = iddata(YvN, UvN, Ts);
z_te_n  = iddata(YtN, UtN, Ts);

z_est_n.InputName  = z_est.InputName;  z_est_n.OutputName = z_est.OutputName;
z_val_n.InputName  = z_est.InputName;  z_val_n.OutputName = z_est.OutputName;
z_te_n.InputName   = z_est.InputName;  z_te_n.OutputName  = z_est.OutputName;

save("STEP6_1_norm.mat","z_est_n","z_val_n","z_te_n","Ts","muU","sigU","muY","sigY");

fprintf("Done. z_est_n: N=%d, nu=%d, ny=%d\n", length(z_est_n.y), size(z_est_n.u,2), size(z_est_n.y,2));
fprintf("      z_val_n: N=%d\n", length(z_val_n.y));
fprintf("      z_te_n : N=%d\n", length(z_te_n.y));
disp("Saved: STEP6_1_norm.mat");
