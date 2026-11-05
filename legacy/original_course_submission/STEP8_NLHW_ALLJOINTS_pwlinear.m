%% STEP8_NLHW_ALLJOINTS_pwlinear.m  (Plot ALL joints)
clc; clear; close all;

% اگر فایل نرمال‌سازی‌ات اسمش STEP6_1_norm.mat است:
load("STEP6_1_norm.mat","z_est_n","z_val_n","z_te_n","Ts");  % Ts اختیاری؛ z_*.Ts هم هست

jointsToTest = 1:6;

cmpSim  = compareOptions('InitialCondition','z');  % Simulation (IC=z)
cmpPred = compareOptions('InitialCondition','e');  % Prediction (IC=e)

% Use pwlinear (deprecated) or idPiecewiseLinear if available
if exist('idPiecewiseLinear','file') == 2
    inNL = idPiecewiseLinear;
    nlName = "idPiecewiseLinear";
else
    inNL = pwlinear;
    nlName = "pwlinear";
end
outNL = [];   % خروجی غیرخطی را فعلاً خالی گذاشتیم

nb_list = [2 3 4];
nf_list = [2 3 4];
nk_list = [0 1];

ny = 6;
bestDesc   = strings(ny,1);
ValSimFit  = -inf(ny,1);
TestSimFit = nan(ny,1);
TestPredFit= nan(ny,1);
bestSys    = cell(ny,1);

% برای رسم نمودارها
YhatSim_all = nan(length(z_te_n.y), ny);  % Nte x 6 (در فضای نرمال‌شده)
Ymeas_all   = z_te_n.y;                   % Nte x 6

for j = jointsToTest
    zE = z_est_n(:,j);   % SISO خروجی j با همه ورودی‌ها
    zV = z_val_n(:,j);
    zT = z_te_n(:,j);

    nu = size(zE.u,2);

    bestFit   = -Inf;
    bestModel = [];
    bestStr   = "";

    fprintf('\n==============================\n');
    fprintf('NLHW (%s) | Joint %d (%s)\n', nlName, j, zE.OutputName{1});
    fprintf('==============================\n');

    for nb0 = nb_list
        for nf0 = nf_list
            for nk0 = nk_list

                nb = nb0 * ones(1,nu);
                nf = nf0 * ones(1,nu);
                nk = nk0 * ones(1,nu);

                try
                    sys = nlhw(zE, [nb nf nk], inNL, outNL);

                    % معیار انتخاب: Validation در حالت Simulation
                    [~, fitV] = compare(zV, sys, cmpSim);
                    fitV = fitV(1);

                    fprintf('nb=%d nf=%d nk=%d | ValSimFit=%.2f%%\n', nb0, nf0, nk0, fitV);

                    if isfinite(fitV) && fitV > bestFit
                        bestFit   = fitV;
                        bestModel = sys;
                        bestStr   = sprintf('%s | nb=%d nf=%d nk=%d', nlName, nb0, nf0, nk0);
                    end
                catch ME
                    % اگر خواستی خطاها هم چاپ شوند، این را فعال کن:
                    % fprintf("FAILED nb=%d nf=%d nk=%d : %s\n", nb0, nf0, nk0, ME.message);
                end

            end
        end
    end

    ValSimFit(j) = bestFit;
    bestSys{j}   = bestModel;
    bestDesc(j)  = bestStr;

    fprintf('>> BEST for joint %d: %s | ValSimFit=%.2f%%\n', j, bestStr, bestFit);

    % Test evaluation
    [yhatSim, fitSim] = compare(zT, bestModel, cmpSim);
    [~,      fitPred] = compare(zT, bestModel, cmpPred);

    TestSimFit(j)  = fitSim(1);
    TestPredFit(j) = fitPred(1);

    % ذخیره خروجی شبیه‌سازی برای رسم نمودار کلی
    YhatSim_all(:,j) = yhatSim.y;
end

% Summary table
Joint = (1:6).';
OutputName = string(z_est_n.OutputName(:));
T = table(Joint, OutputName, bestDesc, ValSimFit, TestSimFit, TestPredFit);

disp('========== NLHW SUMMARY (piecewise linear) ==========');
disp(T);

save("STEP8_NLHW_ALLJOINTS_pwlinear.mat", ...
     "T","bestSys","bestDesc","ValSimFit","TestSimFit","TestPredFit");

%% ========== PLOTS: ALL JOINTS (tiledlayout 3x2) ==========
t = (0:length(z_te_n.y)-1)' * z_te_n.Ts;

figure('Name','NLHW Test: Measured vs Simulated (All joints)','Color','w');
tiledlayout(3,2,'Padding','compact','TileSpacing','compact');

for j = 1:6
    nexttile;
    plot(t, Ymeas_all(:,j), 'k', 'LineWidth', 1.1); hold on; grid on;
    plot(t, YhatSim_all(:,j), 'b--', 'LineWidth', 1.2);
    xlabel('Time (s)');
    ylabel(z_te_n.OutputName{j});
    title(sprintf('%s | TestSimFit=%.2f%%', z_te_n.OutputName{j}, TestSimFit(j)));
    legend('Measured','NLHW Simulated','Location','best');
end

%% ========== OPTIONAL: Separate figures for each joint ==========
makeSeparateFigures = true;
if makeSeparateFigures
    for j = 1:6
        figure('Name',sprintf('NLHW Test: %s', z_te_n.OutputName{j}),'Color','w');
        plot(t, Ymeas_all(:,j), 'k', 'LineWidth', 1.1); hold on; grid on;
        plot(t, YhatSim_all(:,j), 'b--', 'LineWidth', 1.2);
        xlabel('Time (s)');
        ylabel(z_te_n.OutputName{j});
        title(sprintf('NLHW | %s | %s | TestSimFit=%.2f%%', ...
            z_te_n.OutputName{j}, bestDesc(j), TestSimFit(j)));
        legend('Measured','NLHW Simulated','Location','best');
    end
end
