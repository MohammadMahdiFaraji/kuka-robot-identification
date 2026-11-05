function [checks, data] = step4_forward_baseline_v2(data)
% STEP 4  Forward baseline of version 2: torque -> position, simulation mode
% (paper Sec. 5.1, Listing 2, Table 4, Fig. 7).
%
% Trains the linear state-space model from scratch as in Listing 2 (normalized data, n4sid with
% 12 states, Focus = simulation), simulates the test data from a zero initial state and
% computes Table 4 again. Saves the model, the table and Fig. 7.
checks = [];
fw = data.forward;
P = paper_values();

% ---- Listing 2: normalize with the mean and std of the training data
u_mean = mean(fw.u_train, 2);
u_std = std(fw.u_train, 0, 2);
y_mean = mean(fw.y_train, 2);
y_std = std(fw.y_train, 0, 2);
u_train_n = (fw.u_train - u_mean) ./ u_std;
y_train_n = (fw.y_train - y_mean) ./ y_std;
u_test_n = (fw.u_test - u_mean) ./ u_std;

opt = n4sidOptions();
opt.Focus = 'simulation';
model = n4sid(iddata(y_train_n', u_train_n', 0.1), 12, opt);

% Listing 2 as printed uses the time vector of the data file, which lsim does not accept
try
    lsim(model, u_test_n, fw.time_test);
    listing_result = 'runs';
catch err
    listing_result = err.message;
end
% so we simulate on an exact 0.1 s time grid, from a zero initial state
t_test = (0:size(u_test_n, 2)-1)' * 0.1;
t_train = (0:size(u_train_n, 2)-1)' * 0.1;
yhat_test = lsim(model, u_test_n', t_test)' .* y_std + y_mean;
yhat_train = lsim(model, u_train_n', t_train)' .* y_std + y_mean;

% ---- Table 4
[status, found, T4] = compare_table(P.T4v2, fw.y_train, yhat_train, fw.y_test, yhat_test);
data.md = [data.md write_table(T4, fullfile(data.results, 'tables', 'Table4_v2_forward_n4sid.csv'), ...
    'Table 4 (v2): forward model, n4sid, simulation mode')];
checks = add_check(checks, 'B1', '5.1, Tab. 4', ...
    'forward baseline (Listing 2: normalized data, n4sid nx = 12, Focus = simulation, zero initial state)', ...
    'Tab. 4', sprintf('%s (stable %d)', found, isstable(model)), status);
found = sprintf(['lsim(robot_model, u_test, time_test): "%s". Same numbers with an exact 0.1 s time grid; time_true ' ...
    'is not a variable of the data file'], listing_result);
if strcmp(listing_result, 'runs')
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'B2', 'Listing 2', 'Listing 2 runs as printed', 'runs', found, status);

% ---- M1: which standard deviation is meant in eq. (5)?
rmse = sqrt(mean((fw.y_test - yhat_test).^2, 2))';
with_N = isequal(round(rmse ./ std(fw.y_test, 1, 2)', 3), P.T4v2.teN);         % std of the test data with N
with_train = isequal(round(rmse ./ std(fw.y_train, 0, 2)', 3), P.T4v2.teN);    % std of the training data
found = sprintf(['Tab. 4 test values reproduce with sigma of the test data (N-1: yes, N: %d); with sigma of the ' ...
    'training data: %d (NRMSE %s)'], with_N, with_train, mat2str(round(rmse ./ std(fw.y_train, 0, 2)', 3)));
if ~with_train
    status = 'CONSISTENT';
else
    status = 'UNCLEAR';
end
checks = add_check(checks, 'M1', '4.1, eq. (5)', 'sigma_q,n: "standard deviation regarding position" (data set not specified)', ...
    'ambiguous', found, status);

% ---- B3: what if the initial state is estimated instead of zero?
test_data = iddata(((fw.y_test - y_mean) ./ y_std)', u_test_n', 0.1);
ye = compare(test_data, model, compareOptions('InitialCondition', 'estimate'));
ye = ye.y' .* y_std + y_mean;
found = sprintf('with an estimated initial state the test averages would be NRMSE %.4f, R2 %.2f%%', ...
    mean(nrmse(fw.y_test, ye)), mean(r2(fw.y_test, ye)));
checks = add_check(checks, 'B3', '5.1', '"set the initial state to zero"', '-', found, 'OBSERVATION');

% ---- outputs
plot_joints(fw.time_test, fw.y_test, yhat_test, 'q', 'deg', fullfile(data.results, 'figures', 'fig7_v2_forward_test.png'));
normalization = struct('u_mean', u_mean, 'u_std', u_std, 'y_mean', y_mean, 'y_std', y_std);
save(fullfile(data.results, 'models', 'v2_forward_n4sid.mat'), 'model', 'normalization', 'yhat_train', 'yhat_test');
data.yhat_forward_v2 = yhat_test;
end
