function [checks, data] = step5_inverse_baseline_v2(data)
% STEP 5  Inverse baseline of version 2: (q, qd, qdd) -> torque, prediction mode
% (paper Sec. 5.2, Listing 3, Table 5, Fig. 8).
%
% Trains the 6 x 18 linear map from scratch as in Listing 3 (normalized data, fminunc,
% rng(1234)) and computes Table 5 again. Saves the matrix, the table and Fig. 8.
checks = [];
iv = data.inverse;
P = paper_values();

% ---- Listing 3
u_mean = mean(iv.u_train, 2);
u_std = std(iv.u_train, 0, 2);
y_mean = mean(iv.y_train, 2);
y_std = std(iv.y_train, 0, 2);
y_train_n = (iv.y_train - y_mean) ./ y_std;
u_train_n = (iv.u_train - u_mean) ./ u_std;
u_test_n = (iv.u_test - u_mean) ./ u_std;

opt = optimoptions('fminunc', 'Display', 'off');
opt.MaxFunctionEvaluations = 1e4;
opt.MaxIterations = 1e3;
rng(1234);
x0 = randn(6*18, 1);
cost = @(x) sum((y_train_n - reshape(x, 6, 18) * u_train_n).^2, 'all');   % sum of squared errors
[x, ~, exitflag] = fminunc(cost, x0, opt);
A = reshape(x, 6, 18);
A_ls = y_train_n / u_train_n;          % the same problem solved directly by least squares
yhat_test = (A * u_test_n) .* y_std + y_mean;
yhat_train = (A * u_train_n) .* y_std + y_mean;

% ---- Table 5
[status, found, T5] = compare_table(P.T5v2, iv.y_train, yhat_train, iv.y_test, yhat_test);
data.md = [data.md write_table(T5, fullfile(data.results, 'tables', 'Table5_v2_inverse_fminunc.csv'), ...
    'Table 5 (v2): inverse model, 6x18 matrix (fminunc), prediction mode')];
found = sprintf('%s (exitflag %d, max|A - A_LS| = %.2g)', found, exitflag, max(abs(A(:) - A_ls(:))));
checks = add_check(checks, 'B4', '5.2, Tab. 5', 'inverse baseline (Listing 3: normalized data, 6x18 matrix, fminunc, rng(1234))', ...
    'Tab. 5', found, status);

% ---- M2: with the std of the same data set, R2 = 100 (1 - NRMSE^2), so the two numbers of
% the tables carry the same information
gap = max([largest_gap(P.T4v2.trN, P.T4v2.trR) largest_gap(P.T4v2.teN, P.T4v2.teR) ...
           largest_gap(P.T5v2.trN, P.T5v2.trR) largest_gap(P.T5v2.teN, P.T5v2.teR)]);
found = sprintf(['every printed pair satisfies R2 = 100 (1 - NRMSE^2) to %.3f (rounding of NRMSE to 3 decimals), ' ...
    'so the two metrics carry the same information'], gap);
if gap < 0.1
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'M2', '4, eq. (5)-(6)', 'NRMSE and R2 of Tables 4 and 5 (v2)', 'two metrics', found, status);

% ---- outputs
plot_joints(iv.time_test, iv.y_test, yhat_test, 'tau', 'Nm', fullfile(data.results, 'figures', 'fig8_v2_inverse_test.png'));
normalization = struct('u_mean', u_mean, 'u_std', u_std, 'y_mean', y_mean, 'y_std', y_std);
save(fullfile(data.results, 'models', 'v2_inverse_fminunc.mat'), 'A', 'normalization', 'yhat_train', 'yhat_test');
end
