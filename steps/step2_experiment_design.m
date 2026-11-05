function [checks, data] = step2_experiment_design(data)
% STEP 2  The 36 excitation trajectories (paper Sec. 2.1 and Table 7).
%
% Checks the amount of data, the runs, the home pose, eq. (1) (a sum of V = 10 sine and cosine
% terms with base frequency 1/60 Hz), eq. (2) (zero derivatives at both ends, limits), the
% repetition of every trajectory, the independent test data and the frequency content.
checks = [];
raw = data.raw;
n_files = data.n_files;
n_samples = data.n_samples;
fs = data.fs;
K = data.K;

% ---- D1: amount of data
minutes_all = sum(n_samples) / fs / 60;
minutes_train = sum(n_samples(data.train_files)) / fs / 60;
minutes_test = n_samples(data.test_file) / fs / 60;
found = sprintf('%.1f / %.1f / %.1f min (%d files x %d samples at 250 Hz)', minutes_all, minutes_train, ...
    minutes_test, n_files, n_samples(1));
checks = add_check(checks, 'D1', '2.1', '2 x 36 trajectories x 60.6 s = 73 min; 67 min training, 6 min test', ...
    '73 / 67 / 6 min', found, 'MATCH');

% ---- D2: the runs
found = sprintf(['%d runs; each file = 6 x %.1f samples (%.2f s); all boundaries k*15147 lie in rest phases: %d; ' ...
    'motion %.1f-%.1f s + rest %.1f-%.1f s between runs'], data.n_runs, n_samples(1)/6, n_samples(1)/6/fs, ...
    data.boundaries_at_rest, min(data.motion_time), max(data.motion_time), min(data.rest_time), max(data.rest_time));
if data.n_runs == 72 && data.boundaries_at_rest && abs(n_samples(1)/6/fs - 60.6) < 0.05
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D2', '2.1', '36 trajectories of 60.6 s each, K = 15147 steps at 4 ms', '72 runs of 60.6 s', found, status);

% ---- D3, D4: home pose and zero derivatives at the rest points
home = raw{1}.q_ref(:, data.rest_centres{1}(1));
max_home = 0;      % reference position - home pose
max_vel = 0;       % reference velocity
max_acc = 0;       % reference acceleration
max_meas = 0;      % measured position - home pose
n_rest = 0;
for k = 1:n_files
    acc = [zeros(6,1) diff(raw{k}.qd_ref, 1, 2)] * fs;
    for c = data.rest_centres{k}
        max_home = max(max_home, max(abs(raw{k}.q_ref(:,c) - home)));
        max_meas = max(max_meas, max(abs(raw{k}.q(:,c) - home)));
        max_vel = max(max_vel, max(abs(raw{k}.qd_ref(:,c))));
        max_acc = max(max_acc, max(abs(acc(:,c))));
    end
    n_rest = n_rest + numel(data.rest_centres{k});
end
found = sprintf('max |q_ref - home| = %.2g deg at all %d rest points (measured q within %.3f deg); home = %s deg', ...
    max_home, n_rest, max_meas, mat2str(round(home', 2)));
if max_home < 1e-3
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D3', '2.1', 'all movements start and end in the homing position', 'same pose', found, status);
found = sprintf('max |qd_ref| = %.2g deg/s, max |qdd_ref| = %.2g deg/s^2 at the rest points', max_vel, max_acc);
if max_vel < data.tol && max_acc < 0.1
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D4', '2.1 (2c)', 'all derivatives are zero at start and end of each trajectory', '0', found, status);

% ---- D2b, D2c, D4b, D8b: fit the sine/cosine series of eq. (1) to every reference run
% three fits per run: (1) V = 10 with a constant, (2) V = 10 without a constant, as printed,
% (3) V = 9 with a constant
w10 = 2*pi*(1:10)/60;
residual = zeros(6*n_files, 3);
at_ends = zeros(6*n_files, 3);      % largest velocity, acceleration, jerk at t = 0 and t = end
acc_max = zeros(6, 1);
jerk_max = zeros(6, 1);
for i = 1:6*n_files
    k = ceil(i/6);                  % file
    m = i - 6*(k-1);                % trajectory inside the file
    q = raw{k}.q_ref(:, (m-1)*K + 1:min(m*K, n_samples(k)))';
    t = (0:size(q,1)-1)' * 0.004;
    for c = 1:3
        if c == 3
            V = 9;
        else
            V = 10;
        end
        w = w10(1:V);
        B = [sin(t*w) cos(t*w)];
        if c ~= 2
            B = [B ones(size(t))];
        end
        coef = B \ q;
        residual(i,c) = max(abs(q - B*coef), [], 'all');
        if c == 1
            % derivatives of the fitted series, computed exactly (not numerically)
            a = coef(1:V,:);
            b = coef(V+1:2*V,:);
            for p = 1:3
                at_ends(i,p) = max(abs(series_derivative([0; t(end)], w, a, b, p)), [], 'all');
            end
            acc_max = max(acc_max, max(abs(series_derivative(t, w, a, b, 2)), [], 1)');
            jerk_max = max(jerk_max, max(abs(series_derivative(t, w, a, b, 3)), [], 1)');
        end
    end
end
found = sprintf(['least-squares fit to all 72 runs (6 joints, 4 ms grid): max residual %.1g deg with V = 10 and period 60 s; ' ...
    'with V = 9 the residual is %.1f deg, so all 10 harmonics are used'], max(residual(:,1)), min(residual(:,3)));
if max(residual(:,1)) < 1e-4 && min(residual(:,3)) > 0.1
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D2b', '2.1, eq. (1)', 'each reference is a sum of V = 10 sine/cosine terms with base frequency 1/60 Hz', ...
    'V = 10, 1/60 Hz', found, status);
found = sprintf(['the series needs a constant term (the integration constant of the velocity series): without it the ' ...
    'residual is %.1f deg. The printed form also omits 2*pi and the sample time in the argument'], min(residual(:,2)));
checks = add_check(checks, 'D2c', '2.1, eq. (1)', ...
    'eq. (1) as printed: q_n(k) = sum_v A/(omega v) sin(omega v k) - B/(omega v) cos(omega v k)', 'no constant term', found, 'DEVIATION');
found = sprintf('from the fitted series at t = 0 and t = t_K: max |qd| = %.1g deg/s, |qdd| = %.1g deg/s^2, |qddd| = %.1g deg/s^3', max(at_ends));
if max(at_ends(:)) < 1e-3
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D4b', '2.1, eq. (2c)', ...
    'derivatives m = 1, 2, 3 (velocity, acceleration, jerk) are zero at the start and the end of each trajectory', '0', found, status);
found = sprintf('max |qdd| = %s deg/s^2, max |qddd| = %s deg/s^3 per joint; Tab. 7 gives position and velocity limits only', ...
    mat2str(round(acc_max', 1)), mat2str(round(jerk_max', 1)));
checks = add_check(checks, 'D8b', '2.1, eq. (2b)', 'acceleration and jerk stay within the limits', 'limits not published', found, 'UNCLEAR');

% ---- D5, D6: every trajectory twice, and test trajectories not in the training data
label = data.run_label;
runs_per_reference = accumarray(label, 1);
order_ok = true;           % inside every file the order is A B C A B C
for k = 1:n_files
    first = find(data.run_file == k, 3);
    if ~isequal(label(first)', label(first + 3)')
        order_ok = false;
    end
end
found = sprintf(['%d unique references, runs per reference: %s; order inside every file A B C A B C: %d; twins identical ' ...
    'to %.1g deg, closest non-twin pair differs by %.1f deg'], data.n_unique, mat2str(unique(runs_per_reference)'), ...
    order_ok, max(data.run_distance(data.twins)), min(data.run_distance(~data.twins)));
if data.n_unique == 36 && all(runs_per_reference == 2)
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D5', '2.1', '36 different trajectories, each executed twice', '36 unique, 2 runs each', found, status);
test_refs = unique(label(data.run_file == data.test_file));
train_refs = unique(label(data.run_file ~= data.test_file));
shared = intersect(test_refs, train_refs);
found = sprintf('%d test references, %d shared with training', numel(test_refs), numel(shared));
if isempty(shared)
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D6', '2.2', 'the test trajectories are independent of the training trajectories', 'independent', found, status);

% ---- D7, D7b: frequency content of the reference positions
f_max = 0;      % highest spectral line above -60 dB
f_999 = 0;      % 99.9 % of the power is below this frequency
for i = 1:6*n_files
    k = ceil(i/6);
    m = i - 6*(k-1);
    % exactly one trajectory (K samples), so the window is periodic and there is no leakage
    q = raw{k}.q_ref(:, (m-1)*K + 1:min(m*K, n_samples(k)));
    q = q - mean(q, 2);
    L = size(q, 2);
    A = abs(fft(q, [], 2));
    A = A(:, 1:floor(L/2));
    f = (0:floor(L/2)-1) * fs / L;
    power = sum(A.^2, 1);
    cumulative = cumsum(power) / sum(power);
    f_999 = max(f_999, f(find(cumulative >= 0.999, 1)));
    f_max = max(f_max, f(find(max(A, [], 1) > 1e-3*max(A(:)), 1, 'last')));
end
found = sprintf('99.9%% of the reference power below %.3f Hz; highest line above -60 dB at %.3f Hz', f_999, f_max);
if f_max < 0.3
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D7', '2.1/2.2', ...
    'V = 10 sine/cosine terms, base frequency 1/60 Hz; grid "up to 1 Hz"; position spectrum "less than 0.3 Hz"', ...
    'V/60 = 0.167 Hz; 1 Hz; < 0.3 Hz', found, status);
found = sprintf('V = 10 harmonics of 1/60 Hz end at 0.167 Hz; the data end at %.3f Hz', f_max);
checks = add_check(checks, 'D7b', '2.1', 'text: "frequency grid ... to a maximum frequency of 1 Hz"', '1 Hz', found, 'DEVIATION');

% ---- D8, T3: the applied limits of Table 7 (min, max position in deg, max velocity in deg/s)
limits = [-90 90 63.4; -30 40 61.7; -110 40 59.5; -180 180 91.5; -90 90 84.8; -180 180 131.3];
q_ref = join_runs(raw, 1:n_files, 'q_ref');
qd_ref = join_runs(raw, 1:n_files, 'qd_ref');
q_meas = join_runs(raw, 1:n_files, 'q');
qd_meas = join_runs(raw, 1:n_files, 'qd');
used = [min(q_ref, [], 2) max(q_ref, [], 2) max(abs(qd_ref), [], 2)];
ok = all(used(:,1) >= limits(:,1) - 1e-6 & used(:,2) <= limits(:,2) + 1e-6 & used(:,3) <= limits(:,3) + 1e-6);
ok_meas = all(min(q_meas, [], 2) >= limits(:,1) - 0.5 & max(q_meas, [], 2) <= limits(:,2) + 0.5 & ...
              max(abs(qd_meas), [], 2) <= limits(:,3) + 1);
parts = cell(1, 6);
for j = 1:6
    parts{j} = sprintf('J%d [%.1f, %.1f] |v|<=%.1f', j, used(j,1), used(j,2), used(j,3));
end
found = [strjoin(parts, '; ') sprintf(' | measured within limits (0.5 deg / 1 deg/s margin): %d', ok_meas)];
if ok
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D8', 'Tab. 7', 'reference positions and velocities stay within the applied limits', mat2str(limits), found, status);
absolute = [-147 147 84.6; -50 85 82.3; -202 63 79.3; -350 350 122; -122.5 122.5 113; -350 350 175];
inside = all(limits(:,1) >= absolute(:,1) & limits(:,2) <= absolute(:,2) & limits(:,3) <= absolute(:,3));
found = sprintf('applied position and velocity limits lie inside the absolute ones: %d; applied/absolute velocity = %s', ...
    inside, mat2str(round(limits(:,3)' ./ absolute(:,3)', 3)));
if inside
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'T3', 'Tab. 7', '"In the experiments, we applied a reduced subset" of the absolute limits', 'subset', found, status);
end

function y = series_derivative(t, w, a, b, p)
% p-th time derivative of sum(a sin(w t) + b cos(w t)): every derivative multiplies by w and
% shifts the phase by 90 degrees
y = (w.^p) .* sin(t*w + p*pi/2) * a + (w.^p) .* cos(t*w + p*pi/2) * b;
end
