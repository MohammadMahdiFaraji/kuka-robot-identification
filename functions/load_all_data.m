function data = load_all_data(folder, results)
% LOAD_ALL_DATA  Load the official benchmark files and all 12 raw recordings once, and find the
% single runs inside the recordings. Every step gets this struct.
%
%   folder  : the official archive (with raw_data/, *_without_raw_data.mat, saved_linear_model/)
%   results : the results folder of this project

data.folder = folder;
data.results = results;
data.forward = load(fullfile(folder, 'forward_identification_without_raw_data.mat'));
data.inverse = load(fullfile(folder, 'inverse_identification_without_raw_data.mat'));
data.saved_models = load(fullfile(folder, 'saved_linear_model', 'trained_model.mat'));

% the official script takes the files in dir() order and uses the last one as test data
data.files = dir(fullfile(folder, 'raw_data', '*.mat'));
data.n_files = numel(data.files);
data.train_files = 1:data.n_files-1;
data.test_file = data.n_files;
fprintf('raw files in dir() order (last = test):\n');
for k = 1:data.n_files
    fprintf('  %s\n', data.files(k).name);
end

data.fs = 250;        % sample rate of the raw data (Hz)
data.n_step = 25;     % the benchmark keeps every 25th sample (0.1 s)
data.K = 15147;       % samples of one trajectory (60.6 s)
data.tol = 1e-3;      % |reference velocity| below this = robot at rest (deg/s)

% the raw recordings; position of the benchmark = link-side encoder for joints 1-3 and
% motor resolver for joints 4-6 (paper, App. A.1)
channels = {'time', 'q_ref', 'qd_ref', 'q_se_meas', 'q_mot_meas', 'qd_se_meas', 'qd_mot_meas', ...
            'tau_meas', 'tau_ref_ff', 'tau_fb_meas'};
data.raw = cell(data.n_files, 1);
data.n_samples = zeros(data.n_files, 1);
for k = 1:data.n_files
    d = load(fullfile(data.files(k).folder, data.files(k).name), channels{:});
    for c = 1:numel(channels)
        d.(channels{c}) = double(d.(channels{c}));
    end
    d.q = [d.q_se_meas(1:3,:); d.q_mot_meas(4:6,:)];
    d.qd = [d.qd_se_meas(1:3,:); d.qd_mot_meas(4:6,:)];
    data.raw{k} = d;
    data.n_samples(k) = size(d.q, 2);
end

% the low pass filter of the official script (Listing 1 of the paper)
data.filter = designfilt('lowpassiir', 'FilterOrder', 4, 'PassbandFrequency', 2, ...
                         'PassbandRipple', 0.2, 'SampleRate', data.fs);

% ---- the single runs: the robot rests (all reference velocities about 0) between two runs
data.rest_centres = cell(data.n_files, 1);   % sample in the middle of every rest phase
data.runs = {};                              % one run = [file, last rest sample, first rest sample after it]
data.run_file = [];
data.motion_time = [];
data.rest_time = [];
data.boundaries_at_rest = true;
for k = 1:data.n_files
    at_rest = all(abs(data.raw{k}.qd_ref) < data.tol, 1);
    change = diff([false at_rest false]);
    rest_start = find(change == 1);
    rest_end = find(change == -1) - 1;
    data.rest_centres{k} = round((rest_start + rest_end) / 2);
    for m = 1:numel(rest_start)-1
        data.runs{end+1} = [k rest_end(m) rest_start(m+1)];
        data.run_file(end+1) = k;
        data.motion_time(end+1) = (rest_start(m+1) - rest_end(m)) / data.fs;
    end
    inner = 2:numel(rest_start)-1;           % rest phases between two runs
    data.rest_time = [data.rest_time (rest_end(inner) - rest_start(inner) + 1) / data.fs];
    % the paper says every trajectory has K = 15147 samples: are all these boundaries at rest?
    boundaries = min(1 + (0:6) * data.K, data.n_samples(k));
    data.boundaries_at_rest = data.boundaries_at_rest && all(at_rest(boundaries));
end
data.n_runs = numel(data.runs);

% ---- which runs use the same reference trajectory (the "twins")?
% references are compared from the start of the motion, with every 10th sample
shortest = inf;
for i = 1:data.n_runs
    shortest = min(shortest, data.runs{i}(3) - data.runs{i}(2));
end
X = zeros(data.n_runs, 6 * ceil(shortest / 10));
for i = 1:data.n_runs
    r = data.runs{i};
    q = data.raw{r(1)}.q_ref(:, r(2):r(2) + shortest - 1);
    q = q(:, 1:10:end);
    X(i,:) = q(:)';
end
distance = zeros(data.n_runs);                % largest difference between two references (deg)
for i = 1:data.n_runs
    distance(i,:) = max(abs(X - X(i,:)), [], 2)';
end
twins = distance < 1e-3;
label = zeros(data.n_runs, 1);                % runs with the same label have the same reference
n_unique = 0;
for i = 1:data.n_runs
    if label(i) == 0
        n_unique = n_unique + 1;
        label(twins(:,i) | (1:data.n_runs)' == i) = n_unique;
    end
end
data.run_distance = distance;
data.twins = twins;
data.run_label = label;
data.n_unique = n_unique;
data.md = '';                                 % Markdown of the reproduced result tables
end
