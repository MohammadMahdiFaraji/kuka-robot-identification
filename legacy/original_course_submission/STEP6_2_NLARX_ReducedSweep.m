%% STEP6_2_NLARX_ReducedSweep.m
clc; clear; close all;

load("STEP6_1_norm_like_paper.mat","z_est_n","z_val_n","z_te_n","Ts");

ny = size(z_est_n.y,2);
nu = size(z_est_n.u,2);

% گرید کوچک (سریع)
na = 2;
nbList = [2 3 4];
nkList = [0 1];

% یک نان‌لاینریتی پایدار
NL = idSigmoidNetwork('NumberOfUnits',10);
cmpOpt = compareOptions('InitialCondition','z');

best = struct();
best.model  = cell(1,ny);
best.desc   = strings(1,ny);
best.valFit = -inf(1,ny);

for j = 1:ny
    fprintf("\n==============================\n");
    fprintf("Output joint %d (%s)\n", j, z_est_n.OutputName{j});
    fprintf("==============================\n");

    zE = iddata(z_est_n.y(:,j), z_est_n.u, Ts);
    zV = iddata(z_val_n.y(:,j), z_val_n.u, Ts);

    bestFitJ = -inf;
    bestSysJ = [];
    bestStrJ = "";

    for nb0 = nbList
        nb = nb0*ones(1,nu);
        for nk0 = nkList
            nk = nk0*ones(1,nu);

            try
                sys = nlarx(zE, [na nb nk], NL);

                [~, fitV] = compare(zV, sys, cmpOpt);
                fitV = fitV(1);

                fprintf("nb=%d nk=%d | ValFit=%.2f%%\n", nb0, nk0, fitV);

                if isfinite(fitV) && fitV > bestFitJ
                    bestFitJ = fitV;
                    bestSysJ = sys;
                    bestStrJ = sprintf("na=%d nb=%d nk=%d | idSigmoid10", na, nb0, nk0);
                end
            catch ME
                fprintf("FAILED nb=%d nk=%d : %s\n", nb0, nk0, ME.message);
            end
        end
    end

    best.model{j}  = bestSysJ;
    best.desc(j)   = string(bestStrJ);
    best.valFit(j) = bestFitJ;

    fprintf(">> BEST joint %s: %s | ValFit=%.2f%%\n", ...
        z_est_n.OutputName{j}, best.desc(j), best.valFit(j));
end

save("STEP6_2_NLARX_best_reduced.mat","best","na","nbList","nkList");
fprintf("\nSaved: STEP6_2_NLARX_best_reduced.mat\n");
