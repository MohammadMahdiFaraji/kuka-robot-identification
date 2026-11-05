%% STEP 5 — Evaluate baseline with NRMSE and R^2 per joint (test set)
clc; clear; close all;

load("step3_iddata.mat","z_tr","z_te","Ts");
load("step4_n4sid_models.mat","sys_best","sys_12","bestOrder");

% Choose which model to evaluate as "best" and "paper baseline"
sysA = sys_12;      nameA = "Baseline nx=12 (paper)";
sysB = sys_best;    nameB = "Best nx=" + string(bestOrder);

% Get simulated outputs on test
cmpOpt = compareOptions('InitialCondition','z');

yhatA_id = compare(z_te, sysA, cmpOpt);   % iddata
yhatB_id = compare(z_te, sysB, cmpOpt);

y_true = z_te.y;          % N×6
yhatA  = yhatA_id.y;      % N×6
yhatB  = yhatB_id.y;

% --- Metrics per joint ---
ny = size(y_true,2);
NRMSE_A = zeros(1,ny); R2_A = zeros(1,ny);
NRMSE_B = zeros(1,ny); R2_B = zeros(1,ny);

for j = 1:ny
    yt = y_true(:,j);

    % ---- A: nx=12
    ya = yhatA(:,j);
    rmseA = sqrt(mean((yt-ya).^2));
    nrmseA = rmseA / (std(yt) + eps);
    ssResA = sum((yt-ya).^2);
    ssTot  = sum((yt-mean(yt)).^2) + eps;
    r2A = 1 - ssResA/ssTot;

    NRMSE_A(j) = nrmseA;
    R2_A(j)    = r2A;

    % ---- B: best
    yb = yhatB(:,j);
    rmseB = sqrt(mean((yt-yb).^2));
    nrmseB = rmseB / (std(yt) + eps);
    ssResB = sum((yt-yb).^2);
    r2B = 1 - ssResB/ssTot;

    NRMSE_B(j) = nrmseB;
    R2_B(j)    = r2B;
end

% Build result table
jointNames = z_te.OutputName(:);
T = table(jointNames, NRMSE_A(:), R2_A(:), NRMSE_B(:), R2_B(:), ...
    'VariableNames', {'Joint','NRMSE_nx12','R2_nx12','NRMSE_best','R2_best'});

disp("===== Test metrics per joint =====");
disp(T);

% Also print averages across joints
fprintf("\nAverages across 6 joints:\n");
fprintf("%s: mean NRMSE=%.4f | mean R2=%.4f\n", nameA, mean(NRMSE_A), mean(R2_A));
fprintf("%s: mean NRMSE=%.4f | mean R2=%.4f\n", nameB, mean(NRMSE_B), mean(R2_B));

% --- Plots (like paper): measured vs simulated (test) for a few joints ---
t = (0:size(y_true,1)-1)' * Ts;
plotJoints = [1 3 6];  % you can change
for jj = plotJoints
    figure;
    plot(t, y_true(:,jj), 'LineWidth', 1.3, 'DisplayName','Measured'); hold on;
    plot(t, yhatA(:,jj),  'LineWidth', 1.1, 'DisplayName', nameA);
    plot(t, yhatB(:,jj),  'LineWidth', 1.1, 'DisplayName', nameB);
    grid on;
    xlabel('Time (s)');
    ylabel(z_te.OutputName{jj});
    title(sprintf("Test: Measured vs Simulated (%s)", z_te.OutputName{jj}));
    legend('Location','best');
end

% Save metrics/results
save("step5_metrics.mat","T","NRMSE_A","R2_A","NRMSE_B","R2_B","yhatA","yhatB","y_true");



%% Optional: Smoothed visualization for clarity (NOT for metrics)
w_sec = 0.5;              % smoothing window in seconds
w = round(w_sec / Ts);    % window in samples

for jj = [1 3 6]
    yt = y_true(:,jj);
    ya = yhatA(:,jj);
    yb = yhatB(:,jj);

    yt_s = movmean(yt, w);
    ya_s = movmean(ya, w);
    yb_s = movmean(yb, w);

    figure;
    plot(t, yt_s, 'LineWidth', 1.4, 'DisplayName','Measured (smoothed)'); hold on;
    plot(t, ya_s, 'LineWidth', 1.2, 'DisplayName','Baseline nx=12 (smoothed)');
    plot(t, yb_s, 'LineWidth', 1.2, 'DisplayName','Best nx=16 (smoothed)');
    grid on;
    xlabel('Time (s)');
    ylabel(z_te.OutputName{jj});
    title(sprintf("Smoothed comparison (window = %.1f s) — %s", w_sec, z_te.OutputName{jj}));
    legend('Location','best');
end
