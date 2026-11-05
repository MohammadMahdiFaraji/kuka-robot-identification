function [checks, data] = step6_v1_baselines(data)
% STEP 6  Version 1 of the paper (January 2022): Tables 4 and 5, Fig. 9, and the changelog of v2.
%
% Uses the models that the authors saved with version 1 (ssest forward model on the
% zero-initialized input, fmincon inverse matrix without offset) and the R2 formula of the
% version 1 code, computes both version 1 tables again, checks the R2 correction of version 2
% and finds where the better inverse result of version 2 comes from.
checks = [];
fw = data.forward;
iv = data.inverse;
saved = data.saved_models;
P = paper_values();

% ---- version 1 forward model; its input starts at zero (u minus its first value)
w = warning('off', 'all');
yhat_train = lsim(saved.forward_ss_model_sim, (fw.u_train - fw.u_train(:,1))', fw.time_train)';
yhat_test = lsim(saved.forward_ss_model_sim, (fw.u_test - fw.u_test(:,1))', fw.time_test)';
warning(w);
[status, found, T4] = compare_table(P.T4v1, fw.y_train, yhat_train, fw.y_test, yhat_test, 1);
data.md = [data.md write_table(T4, fullfile(data.results, 'tables', 'Table4_v1_forward_ssest_saved_model.csv'), ...
    'Table 4 (v1): forward model, ssest (authors'' saved model), v1 R² formula')];
checks = add_check(checks, 'L1', 'v1 Tab. 4', 'v1 forward baseline (ssest, zero-initialized input) with the authors'' saved model', ...
    'v1 Tab. 4', found, status);

% ---- version 1 inverse matrix
yinv_train = saved.inverse_lin_model * iv.u_train;
yinv_test = saved.inverse_lin_model * iv.u_test;
[status, found, T5] = compare_table(P.T5v1, iv.y_train, yinv_train, iv.y_test, yinv_test, 1);
data.md = [data.md write_table(T5, fullfile(data.results, 'tables', 'Table5_v1_inverse_fmincon_saved_model.csv'), ...
    'Table 5 (v1): inverse model, 6x18 matrix (authors'' saved matrix), v1 R² formula')];
checks = add_check(checks, 'L2', 'v1 Tab. 5', 'v1 inverse baseline with the authors'' saved matrix', 'v1 Tab. 5', found, status);

% ---- L3: the R2 correction of version 2
gap_v1 = max([largest_gap(P.T4v1.trN, P.T4v1.trR) largest_gap(P.T4v1.teN, P.T4v1.teR) ...
              largest_gap(P.T5v1.trN, P.T5v1.trR) largest_gap(P.T5v1.teN, P.T5v1.teR)]);
gap_v2 = max([largest_gap(P.T4v2.trN, P.T4v2.trR) largest_gap(P.T4v2.teN, P.T4v2.teR) ...
              largest_gap(P.T5v2.trN, P.T5v2.trR) largest_gap(P.T5v2.teN, P.T5v2.teR)]);
found = sprintf(['v1 numbers only reproduce with SST = sum((y - mean(y_sim))^2) (MASTER_identification_linear.m); with ' ...
    'the correct SST the v1 test R2 averages are %.1f%% (forward) and %.1f%% (inverse), not 22.3%% and 18.3%%. The printed ' ...
    'v1 pairs violate R2 = 100 (1 - NRMSE^2) by up to %.0f points (v2: %.3f)'], ...
    mean(r2(fw.y_test, yhat_test)), mean(r2(iv.y_test, yinv_test)), gap_v1, gap_v2);
checks = add_check(checks, 'L3', 'v2 changelog', '"Corrected the calculation of the coefficient of determination"', ...
    'v1 R2 was wrong', found, 'MATCH');

% ---- L4: is the saved version 1 matrix the least-squares solution?
A_ls = iv.y_train / iv.u_train;
cost_saved = sum((iv.y_train - yinv_train).^2, 'all');
cost_ls = sum((iv.y_train - A_ls * iv.u_train).^2, 'all');
found = sprintf('saved v1 matrix has %.2fx the LS optimum training cost; the LS matrix on the same raw data gives test NRMSE %.4f vs %.4f', ...
    cost_saved / cost_ls, mean(nrmse(iv.y_test, A_ls * iv.u_test)), mean(nrmse(iv.y_test, yinv_test)));
if cost_saved / cost_ls < 1.01
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'L4', 'v1 Listing / 5.2', 'v1 inverse matrix = least-squares fit (fmincon, 1e4 evaluations, random x0)', ...
    'LS optimum', found, status);

% ---- L6: where does the better inverse result of version 2 come from?
% least squares with an extra constant input (an offset), on the data without normalization
u_train_1 = [iv.u_train; ones(1, size(iv.u_train, 2))];
u_test_1 = [iv.u_test; ones(1, size(iv.u_test, 2))];
A_offset = iv.y_train / u_train_1;
y_offset = A_offset * u_test_1;
same_as_v2 = all(abs(round(nrmse(iv.y_test, y_offset), 3) - P.T5v2.teN) < 1e-9) && ...
             all(abs(round(r2(iv.y_test, y_offset), 3) - P.T5v2.teR) < 1e-9);
found = sprintf(['v1 fits tau = A*[q; qd; qdd] without an offset; the v2 normalization adds the offset implicitly. Plain ' ...
    'least squares with an offset on the raw data gives test NRMSE %s, i.e. Tab. 5 of v2 exactly: %d. The gain comes from ' ...
    'the offset (gravity torque on joints 2, 3), not from fminunc'], mat2str(round(nrmse(iv.y_test, y_offset), 3)), same_as_v2);
checks = add_check(checks, 'L6', '5.2 / v2 changelog', '"Changed the linear baseline model" (inverse: v1 test NRMSE 1.05 -> v2 0.61)', ...
    '-', found, 'OBSERVATION');

% ---- L5: version 1 (ssest) against version 2 (n4sid)
found = sprintf('test NRMSE %.3f (v1) vs %.3f (v2); correct R2 %.1f%% vs %.1f%%', mean(nrmse(fw.y_test, yhat_test)), ...
    mean(nrmse(fw.y_test, data.yhat_forward_v2)), mean(r2(fw.y_test, yhat_test)), mean(r2(fw.y_test, data.yhat_forward_v2)));
checks = add_check(checks, 'L5', '5.3', '"the results [ssest v1 vs n4sid v2] differ significantly"', 'differ', found, 'CONSISTENT');

plot_joints(fw.time_test, fw.y_test, yhat_test, 'q', 'deg', fullfile(data.results, 'figures', 'fig9_v1_forward_test.png'));
end
