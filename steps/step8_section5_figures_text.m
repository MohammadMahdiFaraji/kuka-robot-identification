function [checks, data] = step8_section5_figures_text(data)
% STEP 8  Statements of Sec. 5.2 and 5.3, Figs. 2-6, consistency of the text, and observations
% that matter for anyone who uses the benchmark (closed loop, repeatability, file order).
checks = [];
raw = data.raw;
fw = data.forward;
n_files = data.n_files;
fs = data.fs;
K = data.K;
figures = fullfile(data.results, 'figures');

% ---- D18: low-velocity phases near the start and the end of every trajectory (test recording)
test = raw{data.test_file};
speed = max(abs(test.qd), [], 1);
t = (0:data.n_samples(data.test_file)-1) / fs;
slow = speed < 1;                                % deg/s
boundaries = (0:6) * K / fs;                     % start and end times of the 6 trajectories
near_boundary = false(size(t));
for c = boundaries
    near_boundary = near_boundary | abs(t - c) <= 5;
end
found = sprintf(['test run: %.0f%% of samples with max|qd| < 1 deg/s lie within +-5 s of a trajectory boundary ' ...
    '(boundaries every %.1f s); those windows hold %.0f%% of the time'], 100*mean(near_boundary(slow)), ...
    median(diff(boundaries)), 100*mean(near_boundary));
if mean(near_boundary(slow)) > 0.8
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D18', '5.3', 'low-velocity phases occur in the first and last ~5 s of each trajectory', ...
    '0-5, 55-65, 115-125 s, ...', found, status);

% ---- D22: same pose (home) and zero velocity at every rest point, but different torques?
torque_at_rest = [];
pose_at_rest = [];
torque_all = [];
for k = 1:n_files
    tau_filtered = filtfilt(data.filter, raw{k}.tau_meas')';
    torque_all = [torque_all tau_filtered];
    for c = data.rest_centres{k}
        torque_at_rest(:, end+1) = tau_filtered(:, c);
        pose_at_rest(:, end+1) = raw{k}.q(:, c);
    end
end
pose_spread = max(pose_at_rest, [], 2) - min(pose_at_rest, [], 2);
torque_spread = max(torque_at_rest, [], 2) - min(torque_at_rest, [], 2);
torque_range = max(torque_all, [], 2) - min(torque_all, [], 2);
found = sprintf(['at the %d rest points in the home pose: position spread %s deg, filtered torque spread %s Nm = %s%% ' ...
    'of the full torque range'], size(torque_at_rest, 2), mat2str(round(pose_spread', 3)), ...
    mat2str(round(torque_spread', 1)), mat2str(round(100 * torque_spread' ./ torque_range', 0)));
if max(pose_spread) < 0.05 && min(torque_spread ./ torque_range) > 0.1
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D22', '5.3', '"different torque input signals lead to the same, almost constant position output"', ...
    'qualitative', found, status);

% ---- D19, D20, D21: sizes of the signals in Sec. 5.2 (test data, Figs. 2 and 3)
max_torque = max(abs(fw.u_test), [], 2);
pos_range = max(fw.y_test, [], 2) - min(fw.y_test, [], 2);
ratio = mean(max_torque(1:3)) / mean(max_torque(4:6));
found = sprintf('max|tau| = %s Nm; mean ratio %.1f', mat2str(round(max_torque', 1)), ratio);
if ratio > 2
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D19', '5.2', 'max torque of joints 1-3 is about triple that of joints 4-6 (Fig. 2)', '~3x', found, status);
ratio = mean(pos_range(4:6)) / mean(pos_range(1:3));
found = sprintf('ranges = %s deg; mean ratio %.1f', mat2str(round(pos_range', 1)), ratio);
if ratio > 1.5
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D20', '5.2', 'motion amplitude of joints 4-6 is a multiple of joints 1-3 (Fig. 3)', 'multiple', found, status);
mean_torque = mean([fw.u_train fw.u_test], 2);
[~, order] = sort(abs(mean_torque), 'descend');
found = sprintf('mean torque %s Nm (largest |mean|: joints %d and %d)', mat2str(round(mean_torque', 2)), order(1), order(2));
if isequal(sort(order(1:2)'), [2 3])
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D21', '5.2', 'gravitational loads act primarily on joints 2 and 3', 'joints 2, 3', found, status);

% ---- O1: closed loop. The measured position follows the reference very closely, so the
% reference alone (times the filter gain) already "predicts" the output
q_all = join_runs(raw, 1:n_files, 'q');
q_ref_all = join_runs(raw, 1:n_files, 'q_ref');
tracking = sqrt(mean((q_all - q_ref_all).^2, 2))';
guess = data.filter_gain * test.q_ref(:, 1:data.n_step:end);
found = sprintf('RMS(q - q_ref) = %s deg; a "model" y = %.3f*q_ref (filter gain) gives test NRMSE %s', ...
    mat2str(round(tracking, 3)), data.filter_gain, mat2str(round(nrmse(fw.y_test, guess), 3)));
checks = add_check(checks, 'O1', '-', 'closed loop: measured positions follow the reference closely', '-', found, 'OBSERVATION');

% ---- O2: repeatability. Compare the two runs of every reference ("twins")
pos_diff = zeros(data.n_unique, 6);
torque_diff = zeros(data.n_unique, 6);
n_pairs = 0;
for u = 1:data.n_unique
    pair = find(data.run_label == u);
    if numel(pair) < 2
        continue
    end
    a = data.runs{pair(1)};
    b = data.runs{pair(2)};
    L = min(a(3) - a(2), b(3) - b(2));          % both runs aligned at the start of the motion
    qa = raw{a(1)}.q(:, a(2):a(2)+L-1);
    qb = raw{b(1)}.q(:, b(2):b(2)+L-1);
    ta = filtfilt(data.filter, raw{a(1)}.tau_meas(:, a(2):a(2)+L-1)')';
    tb = filtfilt(data.filter, raw{b(1)}.tau_meas(:, b(2):b(2)+L-1)')';
    n_pairs = n_pairs + 1;
    pos_diff(n_pairs,:) = nrmse(qa, qb);
    torque_diff(n_pairs,:) = nrmse(ta, tb);
end
pos_diff = pos_diff(1:n_pairs,:);
torque_diff = torque_diff(1:n_pairs,:);
found = sprintf('NRMSE between twins (median over %d pairs): position %s, filtered torque %s; worst pair: position %s, torque %s', ...
    n_pairs, mat2str(round(median(pos_diff), 6)), mat2str(round(median(torque_diff), 3)), ...
    mat2str(round(max(pos_diff), 6)), mat2str(round(max(torque_diff), 3)));
checks = add_check(checks, 'O2', '2.1', 'repeatability: twin executions of the same reference', '-', found, 'OBSERVATION');

% ---- O3: order of the files
names = erase({data.files.name}, {'recording_2021_12_15_', '.mat'});
checks = add_check(checks, 'O3', '-', 'the files are combined in alphabetical dir() order', '-', ...
    sprintf('order: %s', strjoin(names, ', ')), 'OBSERVATION');

% ---- F1, F2: the figures. Figs. 2 and 4 show u - u(:,1), not the benchmark data
u_train_zero = fw.u_train - fw.u_train(:,1);
u_test_zero = fw.u_test - fw.u_test(:,1);
found = sprintf(['the plotted torques are u - u(:,1) (the v1 zero-initialized input), not the benchmark data: e.g. tau2 ' ...
    'train in the PDF spans about [-2, 20] Nm, the data %s, u - u(:,1) %s; tau3 test in the PDF about [-6, 12], the data %s, ' ...
    'u - u(:,1) %s'], value_range(fw.u_train(2,:)), value_range(u_train_zero(2,:)), ...
    value_range(fw.u_test(3,:)), value_range(u_test_zero(3,:)));
checks = add_check(checks, 'F1', 'Fig. 2, 4; Sec. 3', 'torques "as presented in Fig. 2 ... and 4", applied "without modification"', ...
    'benchmark data', found, 'DEVIATION');

% the following statements were checked by reading the PDF, not computed
checks = add_check(checks, 'F2', 'Fig. 3, 5, 7, 8, 9', 'positions and baseline results in the figures', 'figures', ...
    ['regenerated figures (results/figures) match the PDF in shape and axis range, including the start transient of q3 ' ...
    'in Fig. 7 and the q3 offset of the v1 model in Fig. 9 (visual comparison)'], 'CONSISTENT');
found = sprintf('Tab. 8 cycle times give %.0f Hz, %.0f Hz and %.0f Hz: the velocity loop runs at 5 kHz, not 2.5 kHz', ...
    1/0.8e-3, 1/0.2e-3, 1/0.05e-3);
checks = add_check(checks, 'X1', 'Sec. 2.2 vs Tab. 8', '"position control 1250 Hz, velocity control 2500 Hz and current control 20 kHz"', ...
    'Tab. 8: 0.8 / 0.2 / 0.05 ms', found, 'DEVIATION');
checks = add_check(checks, 'X2', 'Sec. 5.2 vs Tab. 9', '"The motor power supply ranges from 5.5 kW to 16 kW"', '5.5-16 kW', ...
    'Tab. 9: inverters of joints 4-6 5.5 kW, joints 1-3 16 kW continuous power', 'CONSISTENT');
checks = add_check(checks, 'X3', 'eq. (4) vs (12), (14)', 'inverse model contains g(qd_R) and tau_H(qd_R)', 'functions of q', ...
    ['gravity and the hydraulic counterbalance depend on the position (eq. (12): g(q), eq. (14)-(18): h(q2)); eq. (4) ' ...
    'should read g(q_R), tau_H(q_R)'], 'DEVIATION');
checks = add_check(checks, 'X4', 'Fig. 6 caption', ...
    '"Black: Joint 1. Red: Joint 2. Purple: Joint 3. Green: Joint 4. Blue: Joint 5. Brown: Joint 6."', 'colors', ...
    ['the plotted lines use the MATLAB default color order (blue, orange, yellow, purple, green, light blue); no black or ' ...
    'brown line appears (visual check of the PDF)'], 'DEVIATION');

% ---- Figs. 2-6 of the paper, drawn again from the benchmark files
plot_joints(fw.time_test, fw.u_test, [], 'tau', 'Nm', fullfile(figures, 'fig2_test_torque.png'));
plot_joints(fw.time_test, u_test_zero, [], 'tau', 'Nm', fullfile(figures, 'fig2_test_torque_minus_initial_value_as_in_pdf.png'));
plot_joints(fw.time_test, fw.y_test, [], 'q', 'deg', fullfile(figures, 'fig3_test_position.png'));
plot_joints(fw.time_train, fw.u_train, [], 'tau', 'Nm', fullfile(figures, 'fig4_train_torque.png'));
plot_joints(fw.time_train, u_train_zero, [], 'tau', 'Nm', fullfile(figures, 'fig4_train_torque_minus_initial_value_as_in_pdf.png'));
plot_joints(fw.time_train, fw.y_train, [], 'q', 'deg', fullfile(figures, 'fig5_train_position.png'));

% Fig. 6: power spectrum of the training torques and positions, with the colors of the caption
fig = figure('Visible', 'off', 'Position', [0 0 1100 420]);
colors = [0 0 0; 1 0 0; .5 0 .5; 0 .6 0; 0 0 1; .55 .27 .07];
signals = {fw.u_train, fw.y_train};
titles = {'torque (train)', 'position (train)'};
for p = 1:2
    subplot(1, 2, p);
    hold on;
    for j = 1:6
        [pxx, f] = pspectrum(signals{p}(j,:)', 10);
        plot(f, pow2db(pxx), 'Color', colors(j,:));
    end
    xlim([0 2]);
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Power Spectrum (dB)');
    title(titles{p});
end
exportgraphics(fig, fullfile(figures, 'fig6_spectrum.png'), 'Resolution', 150);
close(fig);
end

function s = value_range(x)
s = sprintf('[%.1f, %.1f]', min(x), max(x));
end
