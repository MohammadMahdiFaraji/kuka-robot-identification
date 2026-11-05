function [checks, data] = step3_sensors_controller_inverse(data)
% STEP 3  Sensors, controller and the inputs of the inverse dataset
% (paper Table 2, Table 3, Sec. 3, App. A.1, App. C.3, Table 10).
%
% Checks the velocity channels, the gearbox deformation, the sensor resolution, the time shift
% and the derivative filters of the inverse inputs, and the torque sum tau = tau_FF + tau_FB.
checks = [];
raw = data.raw;
fw = data.forward;
iv = data.inverse;
n_files = data.n_files;
fs = data.fs;

% ---- R2, R3: the velocity channels of Table 3
% joints 1-3: link-side encoder (se), joints 4-6: motor resolver (mot); first two recordings
vel_lag = zeros(1, 6);
vel_corr = zeros(1, 6);
vel_gain = zeros(1, 6);
for j = 1:6
    if j <= 3
        sensor = 'se';
    else
        sensor = 'mot';
    end
    q = [raw{1}.(['q_' sensor '_meas'])(j,:) raw{2}.(['q_' sensor '_meas'])(j,:)];
    v = [raw{1}.(['qd_' sensor '_meas'])(j,:) raw{2}.(['qd_' sensor '_meas'])(j,:)];
    g = gradient(q, 1/fs);                      % numerical derivative of the position
    best = -inf;
    for L = 0:5
        r = corrcoef(v(1+L:end), g(1:end-L));
        if r(1,2) > best
            best = r(1,2);
            vel_lag(j) = L;
            vel_corr(j) = r(1,2);
            vel_gain(j) = std(v(1+L:end)) / std(g(1:end-L));
        end
    end
end
found = sprintf('the velocity channels equal the numerical derivative of the position channels, delayed by %s samples (4 ms): corr %s, gain %s', ...
    mat2str(unique(vel_lag)), mat2str(round(vel_corr, 5)), mat2str(round(vel_gain, 4)));
checks = add_check(checks, 'R2', 'Tab. 3', 'joint velocity "measured by" motor resolver and secondary encoder', 'measured', found, 'UNDOCUMENTED');
gq = 0;
for k = 1:n_files
    gq = max(gq, max(abs(gradient(raw{k}.q_ref, 1/fs) - raw{k}.qd_ref), [], 'all'));
end
found = sprintf('max |gradient(q_ref) - qd_ref| = %.2g deg/s (central differences at 4 ms)', gq);
if gq < 0.01
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'R3', 'Tab. 3', 'reference velocity qd_R belongs to the reference position q_R', 'qd_R = d/dt q_R', found, status);

% ---- A1, A2: gearbox deformation and sensor resolution (App. A.1, C.3, Table 10)
gear = join_runs(raw, 1:n_files, 'q_mot_meas') - join_runs(raw, 1:n_files, 'q_se_meas');
gear = gear(1:3,:);                              % motor side minus link side, joints 1-3
found = sprintf('q_mot - q_se, joints 1-3: std %s deg, 95th percentile of |dev - mean| %s deg, max %s deg', ...
    mat2str(round(std(gear, 0, 2)', 3)), mat2str(round(prctile(abs(gear - mean(gear, 2)), 95, 2)', 3)), ...
    mat2str(round(max(abs(gear), [], 2)', 3)));
if all(std(gear, 0, 2) > 0.005 & std(gear, 0, 2) < 0.06)
    status = 'CONSISTENT';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'A1', 'App. C.3', 'gearbox deformation and backlash (motor side vs link side) sum up to about 0.01-0.05 deg', ...
    '0.01-0.05 deg', found, status);

% smallest step between two different recorded values, for the 9 sensors
% (encoders of joints 1-3, then resolvers of joints 1-6)
smallest_step = zeros(1, 9);
for j = 1:9
    if j <= 3
        channel = 'q_se_meas';
        row = j;
    else
        channel = 'q_mot_meas';
        row = j - 3;
    end
    values = [];
    for k = 1:n_files
        values = [values raw{k}.(channel)(row,:)];
    end
    values = unique(values);
    steps = diff(values);
    smallest_step(j) = min(steps(steps > 0));
end
% noise of the 9 sensors while the robot rests in the home pose (rest phases longer than 2 s)
noise = [];
for k = 1:n_files
    at_rest = all(abs(raw{k}.qd_ref) < data.tol, 1);
    change = diff([false at_rest false]);
    s0 = find(change == 1);
    e0 = find(change == -1) - 1;
    for i = find(e0 - s0 > 2*fs)
        part = s0(i) + fs/2:e0(i) - fs/2;
        x = detrend([raw{k}.q_se_meas(1:3, part); raw{k}.q_mot_meas(:, part)]')';
        noise(:, end+1) = std(x, 0, 2);
    end
end
found = sprintf(['the recorded positions are not quantized (smallest step between values %.1g deg), so the resolution ' ...
    'cannot be read from the data; noise at rest (median std): SE %s, RE %s deg'], max(smallest_step), ...
    mat2str(round(median(noise(1:3,:), 2)', 7)), mat2str(round(median(noise(4:9,:), 2)', 6)));
checks = add_check(checks, 'A2', 'Tab. 10', 'software resolution: SE 4.3-6.5e-6 deg (joints 1-3), RE 82-240e-6 deg (joints 1-6)', ...
    'Tab. 10', found, 'UNCLEAR');

% ---- D14, D15, D14b: the inputs of the inverse dataset (Table 2, Sec. 3)
q_inv = iv.u_train(1:6,:);
v_inv = iv.u_train(7:12,:);
a_inv = iv.u_train(13:18,:);
pos_slope = sum(q_inv .* fw.y_train, 2) ./ sum(fw.y_train.^2, 2);   % inverse position / forward position
% measured velocity with the same filter and sampling as the benchmark, and its derivative
v_meas = join_runs(raw, data.train_files, 'qd');
v_meas = filtfilt(data.filter, v_meas')';
v_meas = v_meas(:, 1:data.n_step:end);
a_meas = [zeros(6,1) diff(v_meas, 1, 2)] / 0.1;
[lag_v, gain_v, corr_v] = best_lag(v_inv, v_meas, 0:20);
[lag_a, gain_a, corr_a] = best_lag(a_inv, a_meas, 0:30);
found = sprintf(['position: 1 raw sample (4 ms) advance, but filtered twice (gain %s vs forward y); velocity lags measured ' ...
    'velocity by %.1f s (gain %s, corr %.4f); acceleration lags by %.1f s (gain %s, corr %.3f) - derivatives come from ' ...
    's/(1+0.5 s) filters'], mat2str(round(pos_slope', 3)), lag_v*0.1, mat2str(round(gain_v', 2)), min(corr_v), ...
    lag_a*0.1, mat2str(round(gain_a', 2)), min(corr_a));
checks = add_check(checks, 'D14', 'Tab. 2, Sec. 3', 'inverse inputs: position, velocity, acceleration time-shifted by 4 ms', '+4 ms', ...
    found, 'UNDOCUMENTED');
v_start = max(abs(iv.u_train(7:12, 1:20)), [], 2);
a_start = max(abs(iv.u_train(13:18, 1:20)), [], 2);
found = sprintf('first 2 s: max |qd| = %s deg/s, max |qdd| = %s deg/s^2 (lsim of the derivative filters starts from a zero state)', ...
    mat2str(round(v_start', 1)), mat2str(round(a_start', 1)));
if max(v_start) > 1
    status = 'UNDOCUMENTED';
else
    status = 'CONSISTENT';
end
checks = add_check(checks, 'D15', 'Tab. 2', 'inverse velocity/acceleration at the start of the data (robot at rest in home pose)', '~0', found, status);

% delay of the measured position behind the reference (first recording), best RMS match
pos_lag = zeros(1, 6);
for j = 1:6
    best = inf;
    q = raw{1}.q(j,:);
    qr = raw{1}.q_ref(j,:);
    for L = -5:10
        e = sqrt(mean((q(1+max(L,0):end+min(L,0)) - qr(1-min(L,0):end-max(L,0))).^2));
        if e < best
            best = e;
            pos_lag(j) = L;
        end
    end
end
found = sprintf('the measured position lags the reference by %s samples of 4 ms (joints 1-6, best RMS match)', mat2str(pos_lag));
if median(pos_lag) == 1
    status = 'CONSISTENT';
else
    status = 'UNCLEAR';
end
checks = add_check(checks, 'D14b', 'Sec. 3', '"A time-shift of 4 ms is required to compensate for the feedback controller computation time"', ...
    '4 ms', found, status);

% ---- D16, D17: the torque channels of Table 3 and the control law of eq. (13)
tau = join_runs(raw, 1:n_files, 'tau_meas');
ff = join_runs(raw, 1:n_files, 'tau_ref_ff');
fb = join_runs(raw, 1:n_files, 'tau_fb_meas');
q_ref = join_runs(raw, 1:n_files, 'q_ref');
qd_ref = join_runs(raw, 1:n_files, 'qd_ref');
q = join_runs(raw, 1:n_files, 'q');
qd_mot = join_runs(raw, 1:n_files, 'qd_mot_meas');
r2_sum = zeros(1, 6);        % tau = ff + fb (+ offset)
r2_free = zeros(1, 6);       % tau = best linear combination of ff, fb and an offset
r2_pd = zeros(1, 6);         % fb = P (q_ref - q) + D (qd_ref - qd) + offset
r2_ff_pd = zeros(1, 6);      % tau = ff + PD terms + offset
for j = 1:6
    y = tau(j,:)';
    e = y - ff(j,:)' - fb(j,:)';
    r2_sum(j) = 1 - sum((e - mean(e)).^2) / sum((y - mean(y)).^2);
    X = [ff(j,:)' fb(j,:)' ones(numel(y), 1)];
    r2_free(j) = 1 - sum((y - X*(X\y)).^2) / sum((y - mean(y)).^2);
    Xpd = [q_ref(j,:)' - q(j,:)', qd_ref(j,:)' - qd_mot(j,:)', ones(numel(y), 1)];
    z = fb(j,:)';
    r2_pd(j) = 1 - sum((z - Xpd*(Xpd\z)).^2) / sum((z - mean(z)).^2);
    X = [ff(j,:)' Xpd];
    r2_ff_pd(j) = 1 - sum((y - X*(X\y)).^2) / sum((y - mean(y)).^2);
end
found = sprintf('R2 of tau = ff + fb (+offset): %s; best free linear combination: %s; mean tau %s, mean ff+fb %s Nm', ...
    mat2str(round(r2_sum, 2)), mat2str(round(r2_free, 2)), mat2str(round(mean(tau, 2)', 2)), mat2str(round(mean(ff + fb, 2)', 2)));
if min(r2_sum) > 0.95
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D16', 'Tab. 3', 'absolute motor torque tau = tau_FF + tau_FB', 'identity', found, status);
found = sprintf('R2 of tau_FB on PD terms: %s; R2 of tau on FF + PD: %s', mat2str(round(r2_pd, 2)), mat2str(round(r2_ff_pd, 2)));
if min(r2_ff_pd) > 0.95
    status = 'MATCH';
else
    status = 'UNCLEAR';
end
checks = add_check(checks, 'D17', 'App. A.1, eq. (13)', 'tau_M = tau_FF + P (qR - q) + D (qdR - qd)', 'PD + FF', found, status);
end
