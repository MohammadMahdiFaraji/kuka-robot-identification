%%  Baseline linear MIMO state-space using n4sid (simulation on test)
clc; clear; close all;

load("step3_iddata.mat","z_tr","z_te","Ts");

orders = [8 10 12 14 16];
fitSim = zeros(numel(orders),1);

rng(1);

% Identification options: simulation focus
idOpt = n4sidOptions('Focus','simulation');
idOpt.Display = 'off';

% Compare options (no plotting assumptions)
cmpOpt = compareOptions('InitialCondition','z');

models = cell(numel(orders),1);

for i = 1:numel(orders)
    nx = orders(i);
    fprintf("Training n4sid with nx=%d ...\n", nx);

    sys = n4sid(z_tr, nx, idOpt);
    models{i} = sys;

    % compare in simulation sense
    [~, fit] = compare(z_te, sys, cmpOpt);

    % fit is 1×ny (per output); average over 6 joints
    fitSim(i) = mean(fit);

    fprintf("  Mean test fit (simulation) = %.2f %%\n", fitSim(i));
end

[bestFit, idxBest] = max(fitSim);
bestOrder = orders(idxBest);

fprintf("\n===== SUMMARY =====\n");
T = table(orders(:), fitSim, ...
    'VariableNames', {'nx','MeanTestFitSim_percent'});
disp(T);
fprintf("Best nx = %d with mean fit = %.2f %%\n", bestOrder, bestFit);

sys_best = models{idxBest};
idx12 = find(orders==12,1);
if ~isempty(idx12)
    sys_12 = models{idx12};
else
    sys_12 = [];
end

save("step4_n4sid_models.mat", ...
     "orders","fitSim","bestOrder","bestFit","sys_best","sys_12");


% ---- Plot fit vs nx ----
figure;
plot(orders, fitSim, '-o','LineWidth',1.5); grid on;
xlabel('State order nx'); ylabel('Mean Test Fit (%)');
title('Baseline linear MIMO (n4sid): Fit vs nx (simulation on test)');
exportgraphics(gcf, "FIG_STEP3_FitVsNx.png", "Resolution", 300);

% ---- Save table ----
writetable(T, "TAB_STEP3_FitVsNx.csv");
