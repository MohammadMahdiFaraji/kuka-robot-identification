function x = join_runs(raw, files, name)
% JOIN_RUNS  Put one channel of several raw recordings one after the other in time.
%
%   x = join_runs(raw, files, name)
%
% raw is the cell array of recordings from load_all_data, files the recording numbers and
% name the channel, for example 'tau_meas'. The result has one row per joint.
x = [];
for k = files
    x = [x raw{k}.(name)];
end
end
