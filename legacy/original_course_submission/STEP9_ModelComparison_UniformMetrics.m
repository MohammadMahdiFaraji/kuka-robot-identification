%% STEP9_ModelComparison_UniformMetrics.m
% هدف: مقایسه یکنواخت مدل‌ها با معیارهای یکسان (NRMSE و R^2) روی TEST
clc; clear; close all;

disp("=== STEP9: Uniform Model Comparison (R2 & NRMSE) ===");

%% ---------- Load TEST (un-normalized) ----------
load("step3_iddata.mat","z_te","Ts");      % z_te: real units (deg, Nm)

ny = size(z_te.y,2);
Nte = size(z_te.y,1);

%% ---------- Load normalized TEST + normalization stats ----------
normFileCandidates = ["STEP6_1_norm.mat","step6_norm.mat","STEP6_1_norm_like_paper.mat"];
loadedNorm = false;

for f = normFileCandidates
    if exist(f,"file")==2
        load(f,"z_te_n","muY","sigY");   % z_te_n in normalized space + stats
        loadedNorm = true;
        fprintf("Loaded normalization file: %s\n", f);
        break
    end
end

if ~loadedNorm
    error("Could not find normalization file (STEP6_1_norm.mat or step6_norm.mat).");
end

% sanity
if size(z_te_n.y,1) ~= Nte
    warning("z_te and z_te_n length mismatch! (z_te=%d, z_te_n=%d)", Nte, size(z_te_n.y,1));
end

%% ---------- Load BASELINE results (paper-style) ----------
% baseline file from your STEP2/STEP4B paper-style script
baselineFile = "STEP4B_PaperBaseline_LinearForward_n4sid_results.mat";
if exist(baselineFile,"file")~=2
    error("Baseline result file not found: %s", baselineFile);
end
B = load(baselineFile,"Ysim","Ymeas");  % Nte x 6 (real units)
Yhat_baseline = B.Ysim;
Ytrue_baseline = B.Ymeas;

disp("Loaded BASELINE metrics");

%% ---------- Load NLARX models (best per joint) ----------
nlarxFile = "STEP6_2_NLARX_best_reduced.mat";
hasNLARX = exist(nlarxFile,"file")==2;
if hasNLARX
    A = load(nlarxFile,"best");
    bestNLARX = A.best;   % best.model{j} is idnlarx (SISO)
    disp("Loaded NLARX results");
else
    warning("NLARX file not found -> NLARX columns will be NaN: %s", nlarxFile);
end

%% ---------- Load NLHW models (best per joint) ----------
nlhwFile = "STEP8_NLHW_ALLJOINTS_pwlinear.mat";
hasNLHW = exist(nlhwFile,"file")==2;
if hasNLHW
    H = load(nlhwFile,"bestSys","bestDesc");
    bestNLHW = H.bestSys; % cell(6,1) nlhw (SISO)
    bestNLHW_desc = H.bestDesc;
    disp("Loaded NLHW results");
else
    warning("NLHW file not found -> NLHW columns will be NaN: %s", nlhwFile);
end

%% ---------- helper: compute metrics ----------
metricNRMSE = @(y, yhat) sqrt(mean((y-yhat).^2)) / (std(y)+eps);
metricR2pct = @(y, yhat) 100*(1 - (sum((y-yhat).^2) / (sum((y-mean(y)).^2)+eps)));

%% ---------- Prepare outputs ----------
Joint      = (1:ny).';
OutputName = string(z_te.OutputName(:));

NRMSE_baseline = nan(ny,1);  R2_baseline = nan(ny,1);
NRMSE_nlarx    = nan(ny,1);  R2_nlarx    = nan(ny,1);
NRMSE_nlhw     = nan(ny,1);  R2_nlhw     = nan(ny,1);

cmpSim = compareOptions('InitialCondition','z');  % simulation-style

%% ---------- BASELINE metrics (already denormalized) ----------
for j = 1:ny
    y  = Ytrue_baseline(:,j);
    yh = Yhat_baseline(:,j);

    NRMSE_baseline(j) = metricNRMSE(y,yh);
    R2_baseline(j)    = metricR2pct(y,yh);
end

%% ---------- NLARX metrics (simulate on normalized test -> de-normalize) ----------
if hasNLARX
    for j = 1:ny
        sys = bestNLARX.model{j};
        if isempty(sys); continue; end

        % Make TEST dataset SISO (normalized)
        zTj = z_te_n(:,j);

        % IMPORTANT: unify channel names so compare won't fail
        % (your error: "u1 not available")
        try
            sys2 = sys;
            sys2.InputName  = zTj.InputName;     % force match
            sys2.OutputName = zTj.OutputName;    % force match

            yhatN_id = compare(zTj, sys2, cmpSim);   % normalized output
            yhatN = yhatN_id.y;                      % Nte x 1

            % de-normalize output
            yhat = yhatN * sigY(j) + muY(j);

            % true output in real units
            ytrue = z_te.y(:,j);

            NRMSE_nlarx(j) = metricNRMSE(ytrue,yhat);
            R2_nlarx(j)    = metricR2pct(ytrue,yhat);

        catch ME
            warning("NLARX compare failed for joint %d (%s): %s", j, z_te.OutputName{j}, ME.message);
        end
    end
end

%% ---------- NLHW metrics (simulate on normalized test -> de-normalize) ----------
if hasNLHW
    for j = 1:ny
        sys = bestNLHW{j};
        if isempty(sys); continue; end

        zTj = z_te_n(:,j);

        try
            sys2 = sys;
            sys2.InputName  = zTj.InputName;
            sys2.OutputName = zTj.OutputName;

            yhatN_id = compare(zTj, sys2, cmpSim);
            yhatN = yhatN_id.y;

            yhat  = yhatN * sigY(j) + muY(j);
            ytrue = z_te.y(:,j);

            NRMSE_nlhw(j) = metricNRMSE(ytrue,yhat);
            R2_nlhw(j)    = metricR2pct(ytrue,yhat);

        catch ME
            warning("NLHW compare failed for joint %d (%s): %s", j, z_te.OutputName{j}, ME.message);
        end
    end
end

%% ---------- Summary table ----------
Tsum = table(Joint, OutputName, ...
    NRMSE_baseline, R2_baseline, ...
    NRMSE_nlarx,    R2_nlarx, ...
    NRMSE_nlhw,     R2_nlhw);

disp("========== UNIFORM MODEL COMPARISON (TEST) ==========");
disp(Tsum);

fprintf("\n=== MEAN across joints ===\n");
fprintf("Baseline: mean NRMSE=%.4f | mean R2=%.2f%%\n", mean(NRMSE_baseline,'omitnan'), mean(R2_baseline,'omitnan'));
fprintf("NLARX   : mean NRMSE=%.4f | mean R2=%.2f%%\n", mean(NRMSE_nlarx,'omitnan'),    mean(R2_nlarx,'omitnan'));
fprintf("NLHW    : mean NRMSE=%.4f | mean R2=%.2f%%\n", mean(NRMSE_nlhw,'omitnan'),     mean(R2_nlhw,'omitnan'));

%% ---------- Save ----------
save("STEP9_UniformComparison_R2_NRMSE.mat","Tsum", ...
     "NRMSE_baseline","R2_baseline","NRMSE_nlarx","R2_nlarx","NRMSE_nlhw","R2_nlhw");

disp("Saved: STEP9_UniformComparison_R2_NRMSE.mat");
