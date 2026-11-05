%% STEP2_BuildIddata_ForwardMIMO.m
clc; clear; close all;
rng(1);

% مسیر فایل دیتای forward
dataFile = "..\..\data\Robot_Identification_Benchmark_With_Raw_Data\forward_identification_without_raw_data.mat";
S = load(dataFile);

% طبق فایل: u_train,y_train به شکل 6xN هستند
u_train = S.u_train;   % 6 x Ntr
y_train = S.y_train;   % 6 x Ntr
u_test  = S.u_test;    % 6 x Nte
y_test  = S.y_test;    % 6 x Nte
time_test = S.time_test(:);   % Nte x 1
time_train = S.time_train(:); % Ntr x 1

% dt
dt = median(diff(time_train));
fprintf("dt (estimated) = %.8f s\n", dt);

% ---------- 1) Normalization ----------
u_std  = std(u_train,0,2);  y_std  = std(y_train,0,2);
u_mean = mean(u_train,2);   y_mean = mean(y_train,2);

u_tr_n = u_train;
y_tr_n = y_train;
u_te_n = u_test;

for k_ax = 1:size(y_train,1)
    y_tr_n(k_ax,:) = (y_train(k_ax,:) - y_mean(k_ax)) / (y_std(k_ax) + eps);
    u_tr_n(k_ax,:) = (u_train(k_ax,:) - u_mean(k_ax)) / (u_std(k_ax) + eps);
    u_te_n(k_ax,:) = (u_test(k_ax,:)  - u_mean(k_ax)) / (u_std(k_ax) + eps);
end

% ---------- 2) Build iddata ----------
% iddata expects: Y is N x ny, U is N x nu
Ytr = y_tr_n.';   % Ntr x 6
Utr = u_tr_n.';   % Ntr x 6
z_tr = iddata(Ytr, Utr, dt);

% نام‌ها
z_tr.InputName  = arrayfun(@(i) sprintf("tau%d",i), 1:6, "UniformOutput", false);
z_tr.OutputName = arrayfun(@(i) sprintf("q%d",i),   1:6, "UniformOutput", false);

% ---------- 3) Identify baseline model (nx=12, Focus=simulation) ----------
nx = 12;
idOpt = n4sidOptions('Focus','simulation');
idOpt.Display = 'off';

fprintf("Training n4sid baseline with nx=%d ...\n", nx);
robot_model = n4sid(z_tr, nx, idOpt);

% ---------- 4) Simulate on test (normalized space) ----------
% نکته مهم: چون مدل گسسته است، بهتر است زمان را با dt دقیق بسازیم
Nte = size(u_te_n,2);
t_te = (0:Nte-1)' * dt;

Ute = u_te_n.';             % Nte x 6
Ysim_n = lsim(robot_model, Ute, t_te);   % Nte x 6

% ---------- 5) De-normalize simulated output ----------
Ysim = zeros(Nte,6);
for k_ax = 1:6
    Ysim(:,k_ax) = Ysim_n(:,k_ax) * y_std(k_ax) + y_mean(k_ax);
end

Ymeas = y_test.';  % Nte x 6

% ---------- 6) Metrics (same style as paper code) ----------
JointNames = arrayfun(@(i) "q"+string(i), 1:6).';
NRMSE = zeros(6,1);
R2p   = zeros(6,1);

for k_ax = 1:6
    y_true = Ymeas(:,k_ax);
    y_hat  = Ysim(:,k_ax);

    % NRMSE = RMSE / std(y_true)
    NRMSE(k_ax) = sqrt(mean((y_true - y_hat).^2)) / (std(y_true) + eps);

    % R2% = 100*(1 - SSE / SST)  (همان فرم مقاله)
    SSE = sum((y_true - y_hat).^2);
    SST = sum((y_true - mean(y_hat)).^2) + eps;
    R2p(k_ax) = 100 * (1 - SSE/SST);
end

T = table((1:6).', JointNames, NRMSE, R2p, 'VariableNames', ...
    {'Joint','OutputName','NRMSE','R2_percent'});

fprintf("===== PAPER-STYLE METRICS (Test, Simulation) =====\n");
disp(T);
fprintf("All joints: mean NRMSE = %.4f | mean R2 = %.2f %%\n", mean(NRMSE), mean(R2p));

% ---------- 7) Plot ALL joints (tiledlayout 3x2) ----------
figure('Name','Test: Measured vs Simulated (All joints)','Color','w');
tiledlayout(3,2,'Padding','compact','TileSpacing','compact');

for k_ax = 1:6
    nexttile;
    plot(t_te, Ymeas(:,k_ax), 'k', 'LineWidth', 1.1); hold on; grid on;
    plot(t_te, Ysim(:,k_ax),  'b--', 'LineWidth', 1.1);
    xlabel('Time (s)');
    ylabel(char(JointNames(k_ax)) + " (deg)");
    title(sprintf("%s | NRMSE=%.3f | R^2=%.1f%%", JointNames(k_ax), NRMSE(k_ax), R2p(k_ax)));
    legend('Measured','Simulated','Location','best');
end

% ---------- 8)  Plot each joint in a separate figure ----------
makeSeparateFigures = true;
if makeSeparateFigures
    for k_ax = 1:6
        figure('Name',"Test: "+JointNames(k_ax),'Color','w');
        plot(t_te, Ymeas(:,k_ax), 'k', 'LineWidth', 1.2); hold on; grid on;
        plot(t_te, Ysim(:,k_ax),  'b--', 'LineWidth', 1.2);
        xlabel('Time (s)'); ylabel(char(JointNames(k_ax)) + " (deg)");
        title(sprintf("Test: Measured vs Simulated (%s) | NRMSE=%.3f | R^2=%.1f%%", ...
            JointNames(k_ax), NRMSE(k_ax), R2p(k_ax)));
        legend('Measured','Simulated','Location','best');
    end
end

% ---------- 9) Save for report ----------
save("STEP4B_PaperBaseline_LinearForward_n4sid_results.mat", ...
     "robot_model","dt","T","Ysim","Ymeas","t_te");
