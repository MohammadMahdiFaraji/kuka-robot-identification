function [checks, data] = step1_dataset_from_raw(data)
% STEP 1  From the raw recordings to the benchmark files (paper Sec. 2.2, Table 1, Table 3, Listing 1).
%
%  1. runs the official post-processing script on a copy of the raw data and compares its output
%     with the published benchmark files,
%  2. writes Listing 1 again from the text of the paper (filter + keep every 25th sample) and
%     compares again,
%  3. checks the archive, the raw channels, the number of samples and the gain of the filter.
checks = [];
raw = data.raw;
fw = data.forward;
iv = data.inverse;

% ---- 1. the official script, in a temporary folder (the archive itself is never changed)
tmp = tempname;
mkdir(tmp);
here = pwd;
cleanup = onCleanup(@() remove_folder(here, tmp));
copyfile(fullfile(data.folder, 'MASTER_filter_and_combine_datasets.m'), tmp);
copyfile(fullfile(data.folder, 'raw_data'), fullfile(tmp, 'raw_data'));
cd(tmp);
MASTER_filter_and_combine_datasets;
cd(here);
fprintf('official MASTER_filter_and_combine_datasets.m finished; regenerated vs published files:\n');
max_diff = 0;
sets = {'forward', 'inverse'};
variables = {'u_train', 'y_train', 'u_test', 'y_test', 'time_train', 'time_test'};
for s = 1:2
    A = load(fullfile(tmp, [sets{s} '_identification_without_raw_data.mat']));
    B = load(fullfile(data.folder, [sets{s} '_identification_without_raw_data.mat']));
    for v = 1:numel(variables)
        a = A.(variables{v});
        b = B.(variables{v});
        if ~isequal(size(a), size(b))
            max_diff = inf;
            fprintf('  %s.%s SIZE MISMATCH\n', sets{s}, variables{v});
            continue
        end
        d = max(abs(a - b), [], 'all');
        max_diff = max(max_diff, d);
        fprintf('  %-8s %-10s size %-12s max|diff| = %.3g  (max|value| %.3g)\n', sets{s}, variables{v}, ...
            mat2str(size(a)), d, max(abs(b), [], 'all'));
    end
end

% ---- T1, R1: contents of the archive (Table 1) and the raw channels (Table 3)
needed = {'forward_identification_without_raw_data.mat', 'inverse_identification_without_raw_data.mat', ...
          'MASTER_filter_and_combine_datasets.m', 'MASTER_identification_linear.m'};
present = false(1, numel(needed));
for i = 1:numel(needed)
    present(i) = exist(fullfile(data.folder, needed{i}), 'file') == 2;
end
contents = strjoin(setdiff(fieldnames(fw), {'READ_ME'})', ', ');
found = sprintf(['%d of %d files present, %d raw recordings; benchmark files hold %s; the official post-processing ' ...
    'script regenerates both benchmark files from the raw data with max diff %.2g'], ...
    sum(present), numel(present), data.n_files, contents, max_diff);
if all(present) && data.n_files == 12 && max_diff < 1e-9
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'T1', 'Tab. 1', ...
    'archives: two benchmark mat-files; raw mat-files of all experiments; scripts for post-processing and baseline', ...
    '2 mat + raw + scripts', found, status);

steps_raw = [];                                  % time steps of all raw recordings
se_hand = 0;                                     % largest value in the encoder rows 4-6
for k = 1:data.n_files
    steps_raw = [steps_raw diff(raw{k}.time)];
    se_hand = max(se_hand, max(abs(raw{k}.q_se_meas(4:6,:)), [], 'all'));
end
readme = load(fullfile(data.files(1).folder, data.files(1).name), 'READ_ME');
readme = readme.READ_ME;
fprintf('raw READ_ME:\n');
for i = 1:size(readme, 1)
    fprintf('  %-26s %s\n', readme{i,1}, readme{i,2});
end
found = sprintf(['all 9 channels present (6 x %d each); time step %.6f-%.6f s; secondary encoder channels ' ...
    'exist for joints 1-3 only (rows 4-6 = %g)'], data.n_samples(1), min(steps_raw), max(steps_raw), se_hand);
if abs(max(steps_raw) - 0.004) < 1e-9 && abs(min(steps_raw) - 0.004) < 1e-9
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'R1', 'Tab. 3, 2.2', ...
    'raw data: unfiltered, 250 Hz; reference position/velocity, position and velocity from resolver and secondary encoder, tau, tau_FF, tau_FB', ...
    '9 channels at 250 Hz', found, status);

% ---- D9, D10: number of samples and time vectors of the benchmark files
found = sprintf('%d / %d (forward), %d / %d (inverse)', size(fw.y_train, 2), size(fw.y_test, 2), ...
    size(iv.y_train, 2), size(iv.y_test, 2));
if size(fw.y_train, 2) == 39988 && size(fw.y_test, 2) == 3636
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D9', '2.2/4.1', 'K = 39988 training and K = 3636 test samples at 100 ms', '39988 / 3636', found, status);
dt_test = diff(fw.time_test);
dt_train = diff(fw.time_train);
found = sprintf('time_train / time_test spacing = %.7f / %.7f s (official code: linspace(0, N*dt, N) instead of (N-1)*dt)', ...
    dt_train(1), dt_test(1));
checks = add_check(checks, 'D10', '2.2', 'sample time 100 ms (Listing 2 uses dt = 0.1)', '0.1 s', found, 'DEVIATION');

% ---- D11, D12: Listing 1 written again from the text, compared with the forward files
f = data.filter;
q = join_runs(raw, data.train_files, 'q');
tau = join_runs(raw, data.train_files, 'tau_meas');
yq = filtfilt(f, q')';
yq = yq(:, 1:data.n_step:end);
yt = filtfilt(f, tau')';
yt = yt(:, 1:data.n_step:end);
diff_train = max([max(abs(yq - fw.y_train), [], 'all') max(abs(yt - fw.u_train), [], 'all')]);

q = join_runs(raw, data.test_file, 'q');
tau = join_runs(raw, data.test_file, 'tau_meas');
yq = filtfilt(f, q')';
yq = yq(:, 1:data.n_step:end);
yt = filtfilt(f, tau')';
yt = yt(:, 1:data.n_step:end);
diff_test = max([max(abs(yq - fw.y_test), [], 'all') max(abs(yt - fw.u_test), [], 'all')]);

% the other way to read Listing 1: filter every recording on its own, then join them
yr = [];
for k = data.train_files
    yr = [yr filtfilt(f, raw{k}.q')'];
end
yr = yr(:, 1:data.n_step:end);
diff_per_file = max(abs(yr - fw.y_train), [], 'all');

found = sprintf(['re-implementation from the text reproduces the forward files: max diff train %.2g, test %.2g ' ...
    '(runs concatenated before filtering; per-run filtering would differ by up to %.3g deg)'], diff_train, diff_test, diff_per_file);
if max(diff_train, diff_test) < 1e-9
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D11', '2.2, Listing 1', ...
    'filter (Chebyshev-I, order 4, 2 Hz, 0.2 dB, filtfilt) and keep every 25th sample', 'Listing 1', found, status);
if diff_train < 1e-9
    status = 'MATCH';
else
    status = 'DEVIATION';
end
checks = add_check(checks, 'D12', 'App. A.1', 'link-side encoders for joints 1-3, motor resolvers for joints 4-6', 'SE 1-3, RE 4-6', ...
    'confirmed by D11 (q_se_meas rows 1-3, q_mot_meas rows 4-6 reproduce y exactly)', status);

% ---- D13: gain of the filter in the pass band
% a Chebyshev type I filter of even order has the gain of the ripple floor (-0.2 dB) at 0 Hz,
% and filtfilt uses the filter twice, so the gain is squared
H = abs(freqz(f, [0 0.05 0.17], data.fs));
gain2 = H.^2;
y_raw = join_runs(raw, data.train_files, 'q');
y_raw = y_raw(:, 1:data.n_step:end);
slope = sum(fw.y_train .* y_raw, 2) ./ sum(y_raw.^2, 2);   % benchmark position / raw position
found = sprintf(['filtfilt gain %.4f at 0-0.17 Hz (Chebyshev-I even order starts at the ripple floor, -0.2 dB twice); ' ...
    'benchmark/raw position slope %s'], gain2(1), mat2str(round(slope', 4)));
checks = add_check(checks, 'D13', '2.2, Listing 1', '"low pass filtered with a cutoff of 2 Hz" (implies unit gain in the passband)', ...
    'gain 1 below 0.3 Hz', found, 'UNDOCUMENTED');
data.filter_gain = gain2(1);
end

function remove_folder(here, tmp)
cd(here);
if exist(tmp, 'dir')
    rmdir(tmp, 's');
end
end
