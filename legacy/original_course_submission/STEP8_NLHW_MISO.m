%% STEP8_NLHW_MISO.m  (Robust)
clc; clear; close all;

load("step6_norm.mat","z_est_n","z_val_n","z_te_n");

% Test only q1 and q3 first (fast)
jointsToTest = [1 3];

% Compare options
cmpSim  = compareOptions('InitialCondition','z'); % simulation
cmpPred = compareOptions('InitialCondition','e'); % prediction (reference)

% ---- Build candidate input nonlinearities robustly ----
nlList  = {};
nlNames = strings(0);

% Prefer new class names if available
if exist('idSigmoidNetwork','file') == 2
    nlList{end+1} = idSigmoidNetwork(10); %#ok<*AGROW>
    nlNames(end+1) = "idSigmoid10";
elseif exist('sigmoidnet','file') == 2
    nlList{end+1} = sigmoidnet('NumberOfUnits',10);
    nlNames(end+1) = "sigmoid10";
end

if exist('idWaveletNetwork','file') == 2
    nlList{end+1} = idWaveletNetwork(10);
    nlNames(end+1) = "idWavelet10";
elseif exist('wavenet','file') == 2
    nlList{end+1} = wavenet('NumberOfUnits',10);
    nlNames(end+1) = "wavenet10";
end

% Piecewise linear if available
if exist('pwlinear','file') == 2
    nlList{end+1} = pwlinear;
    nlNames(end+1) = "pwlinear";
end

if isempty(nlList)
    error('No supported static nonlinearity found (sigmoid/wavelet/pwlinear).');
end

disp("Using nonlinearities: " + join(nlNames,", "));

% Small grid for linear dynamics
nb_list = [2 3];
nf_list = [2 3];
nk_list = [0 1];

results = struct();

for ii = 1:numel(jointsToTest)
    j = jointsToTest(ii);

    zE = z_est_n(:,j); % MISO -> SISO output j
    zV = z_val_n(:,j);
    zT = z_te_n(:,j);

    nu = size(zE.u,2);

    best.simFitV = -Inf;
    best.sys = [];
    best.desc = "";

    fprintf('\n==============================\n');
    fprintf('NLHW sweep | Joint %d (%s)\n', j, zE.OutputName{1});
    fprintf('==============================\n');

    for nli = 1:numel(nlList)
        inNL = nlList{nli};
        outNL = [];  % keep output nonlinearity empty for now

        for nb0 = nb_list
            for nf0 = nf_list
                for nk0 = nk_list

                    nb = nb0 * ones(1,nu);
                    nf = nf0 * ones(1,nu);
                    nk = nk0 * ones(1,nu);

                    try
                        sys = nlhw(zE, [nb nf nk], inNL, outNL);

                        [~, fitVsim] = compare(zV, sys, cmpSim);
                        fitVsim = fitVsim(1);

                        fprintf('%s | nb=%d nf=%d nk=%d | ValSimFit=%.2f%%\n', ...
                            nlNames(nli), nb0, nf0, nk0, fitVsim);

                        if isfinite(fitVsim) && fitVsim > best.simFitV
                            best.simFitV = fitVsim;
                            best.sys = sys;
                            best.desc = sprintf('%s | nb=%d nf=%d nk=%d', nlNames(nli), nb0, nf0, nk0);
                        end
                    catch
                        % ignore failed fits
                    end
                end
            end
        end
    end

    fprintf('>> BEST NLHW for joint %d: %s | ValSimFit=%.2f%%\n', ...
        j, best.desc, best.simFitV);

    % Test evaluation
    [yhatTsim, fitTsim]   = compare(zT, best.sys, cmpSim);
    [~,        fitTpred]  = compare(zT, best.sys, cmpPred);

    fitTsim  = fitTsim(1);
    fitTpred = fitTpred(1);

    fprintf('   TestSimFit = %.2f%%\n', fitTsim);
    fprintf('   TestPredFit= %.2f%% (ref)\n', fitTpred);

    % Plot test simulation
    t = (0:length(zT.y)-1)'*zT.Ts;
    figure('Color','w');
    plot(t, zT.y, 'k', 'LineWidth', 1.1); hold on;
    plot(t, yhatTsim.y, 'b--', 'LineWidth', 1.2);
    grid on;
    xlabel('Time (s)'); ylabel(zT.OutputName{1});
    title(sprintf('NLHW Joint %d | %s | TestSimFit=%.2f%%', j, best.desc, fitTsim));
    legend('Measured','NLHW Simulated','Location','best');

    results(ii).joint = j;
    results(ii).bestDesc = best.desc;
    results(ii).ValSimFit = best.simFitV;
    results(ii).TestSimFit = fitTsim;
    results(ii).TestPredFit = fitTpred;
    results(ii).sys = best.sys;
end

save("STEP8_NLHW_results_q1q3.mat","results");
disp('Saved: STEP8_NLHW_results_q1q3.mat');
