function [checks, data] = step7_v1_retrained(data)
% STEP 7  The version 1 baselines trained again from scratch with the settings of the official code
% (version 1 Listing 2, MASTER_identification_linear.m).
%
% Uses the forward model that step 7a trained again (ssest, about 2.3 h, saved in
% results/models), and estimates the inverse matrix again (fmincon from random start points,
% about 1 min).
checks = [];
fw = data.forward;
iv = data.inverse;
saved = data.saved_models;
P = paper_values();
file = fullfile(data.results, 'models', 'v1_ssest_retrained.mat');

% ---- forward: the ssest model trained again by step 7a
if ~exist(file, 'file')
    error('step7:model', 'No retrained v1 model in %s: run run_all(''full'') once.', file);
end
S = load(file);
model = S.forward_ss_model_sim;
fprintf('retrained ssest model: results/models/v1_ssest_retrained.mat\n');
fprintf('  trained by %s, started %s, wall time %.1f s, MATLAB CPU time %.1f s\n', S.trained_by, S.trained_on, S.tFwd, S.cpuFwd);
stops = model.Report.Termination;                % one entry for each search stage of ssest
fprintf('ssest(nx=12, Focus=simulation): Ts=%g | stable=%d | iterations=%s | stop: %s\n', ...
    model.Ts, isstable(model), mat2str([stops.Iterations]), strjoin({stops.WhyStop}, ' / '));
u_train = fw.u_train - fw.u_train(:,1);          % zero-initialized input, as in the official code
u_test = fw.u_test - fw.u_test(:,1);
w = warning('off', 'all');
y_saved_train = lsim(saved.forward_ss_model_sim, u_train', fw.time_train)';
y_new_train = lsim(model, u_train', fw.time_train)';
y_saved_test = lsim(saved.forward_ss_model_sim, u_test', fw.time_test)';
y_new_test = lsim(model, u_test', fw.time_test)';
warning(w);
poles_saved = sort(pole(saved.forward_ss_model_sim));
poles_new = sort(pole(model));
fprintf('saved poles    : %s\nretrained poles: %s\n', mat2str(round(poles_saved.', 4)), mat2str(round(poles_new.', 4)));
[status, found, T4] = compare_table(P.T4v1, fw.y_train, y_new_train, fw.y_test, y_new_test, 1);
data.md = [data.md write_table(T4, fullfile(data.results, 'tables', 'Table4_v1_forward_ssest_retrained.csv'), ...
    'Table 4 (v1): forward model, ssest retrained from scratch, v1 R² formula')];
output_diff = max(abs([y_new_train(:) - y_saved_train(:); y_new_test(:) - y_saved_test(:)]));
found = sprintf('%s; retrained vs saved model: max output difference %.2g deg, max pole difference %.2g, stop after %s iterations', ...
    found, output_diff, max(abs(poles_new - poles_saved)), mat2str([stops.Iterations]));
checks = add_check(checks, 'L7', 'v1 Tab. 4, Listing 2', 'v1 forward baseline retrained from scratch (ssest, nx = 12, Focus = simulation)', ...
    'v1 Tab. 4', found, status);

% ---- inverse: fmincon as in the official code (start point randn without a seed, 1e4 evaluations)
U = iv.u_train;
Y = iv.y_train;
A_ls = Y / U;
cost = @(x) sum((Y - reshape(x, 6, 18) * U).^2, 'all');
opt = optimoptions('fmincon', 'Display', 'off', 'MaxFunctionEvaluations', 1e4, 'MaxIterations', 1e3);
A_fmincon = cell(1, 3);
distance_to_ls = zeros(1, 3);
for seed = 1:3                                   % the official start point cannot be reproduced
    rng(seed);
    x0 = randn(108, 1);
    [x, fval, exitflag, info] = fmincon(cost, x0, [], [], [], [], [], [], [], opt);
    A_fmincon{seed} = reshape(x, 6, 18);
    distance_to_ls(seed) = max(abs(x - A_ls(:)));
    fprintf('fmincon seed %d: exitflag %d, funcCount %d, cost %.6g (LS %.6g), max|A-A_ls| = %.4g\n', ...
        seed, exitflag, info.funcCount, fval, cost(A_ls(:)), distance_to_ls(seed));
end
fprintf('saved v1 matrix: max|A_saved - A_ls| = %.4g\n', max(abs(saved.inverse_lin_model(:) - A_ls(:))));
[status, found, T5] = compare_table(P.T5v1, iv.y_train, A_fmincon{1} * iv.u_train, iv.y_test, A_fmincon{1} * iv.u_test, 1);
data.md = [data.md write_table(T5, fullfile(data.results, 'tables', 'Table5_v1_inverse_fmincon_retrained.csv'), ...
    'Table 5 (v1): inverse model, fmincon retrained from scratch (seed 1), v1 R² formula')];
nrmse_diff = max(abs(T5{:, [2 6]} - T5{:, [3 7]}), [], 'all');    % NRMSE columns: paper vs ours
found = sprintf(['%s; the official code starts fmincon from an unseeded randn and stops at 1e4 evaluations, so the saved ' ...
    'matrix cannot be regenerated exactly; seeds 1-3 end within %.3g of the least-squares optimum; max NRMSE difference ' ...
    'to the paper %.3g; LS optimum test NRMSE mean %.4f'], found, max(distance_to_ls), nrmse_diff, ...
    mean(round(nrmse(iv.y_test, A_ls * iv.u_test), 3)));
% the saved matrix cannot be made again exactly, so a small NRMSE difference counts as CONSISTENT
if ~strcmp(status, 'MATCH')
    if nrmse_diff <= 0.002
        status = 'CONSISTENT';
    else
        status = 'DEVIATION';
    end
end
checks = add_check(checks, 'L8', 'v1 Tab. 5', 'v1 inverse baseline retrained from scratch (fmincon)', 'v1 Tab. 5', found, status);
inverse_lin_model = A_fmincon{1};
inverse_lin_model_LS = A_ls;
save(fullfile(data.results, 'models', 'v1_inverse_retrained.mat'), 'inverse_lin_model', 'inverse_lin_model_LS');
end
