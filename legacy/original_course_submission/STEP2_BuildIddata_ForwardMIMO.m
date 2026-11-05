%% STEP2_BuildIddata_ForwardMIMO.m
clc; clear; close all;

dataFile = "..\..\data\Robot_Identification_Benchmark_With_Raw_Data\forward_identification_without_raw_data.mat";
S = load(dataFile);

t_tr = S.time_train(:);   % N×1
t_te = S.time_test(:);

u_tr = S.u_train.';       % now N×6  (iddata expects N×nu)
y_tr = S.y_train.';       % now N×6  (N×ny)

u_te = S.u_test.';        % N×6
y_te = S.y_test.';        % N×6

% ---- Compute Ts (robustly) ----
dt = diff(t_tr);
Ts = median(dt);
fprintf("Estimated Ts = %.8f s\n", Ts);
fprintf("dt range: [%.8f, %.8f] s\n", min(dt), max(dt));

% ---- Build iddata ----
z_tr = iddata(y_tr, u_tr, Ts);
z_te = iddata(y_te, u_te, Ts);

% (اختیاری) نام‌گذاری سیگنال‌ها
z_tr.InputName  = arrayfun(@(i) sprintf("tau%d",i), 1:6, "UniformOutput", false);
z_tr.OutputName = arrayfun(@(i) sprintf("q%d",i),   1:6, "UniformOutput", false);
z_te.InputName  = z_tr.InputName;
z_te.OutputName = z_tr.OutputName;

disp("Train iddata:");
disp(z_tr);
disp("Test iddata:");
disp(z_te);

% ---- Quick plots: one joint example ----
j = 1; % joint index to visualize
figure;
subplot(2,1,1);
plot(t_tr, y_tr(:,j), 'LineWidth', 1.1); grid on;
xlabel('time (s)'); ylabel(z_tr.OutputName{j});
title('Train output (position)');

subplot(2,1,2);
plot(t_tr, u_tr(:,j), 'LineWidth', 1.1); grid on;
xlabel('time (s)'); ylabel(z_tr.InputName{j});
title('Train input (torque)');

% Save for next steps
save("step3_iddata.mat","z_tr","z_te","Ts");
