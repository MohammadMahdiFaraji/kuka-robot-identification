function [lag, gain, corr_at_lag] = best_lag(x, ref, lags)
% BEST_LAG  Find the delay (in samples) for which x(t) looks most like ref(t - lag).
%
% x and ref have one row per channel. For every lag in lags the correlation of each channel is
% computed, and the lag with the highest mean correlation is chosen. gain is the ratio of the
% standard deviations at that lag and corr_at_lag the correlation of every channel.
nch = size(x, 1);
cc = zeros(nch, numel(lags));
for i = 1:numel(lags)
    L = lags(i);
    a = x(:, 1+L:end);
    b = ref(:, 1:end-L);
    for j = 1:nch
        r = corrcoef(a(j,:), b(j,:));
        cc(j, i) = r(1, 2);
    end
end
[~, best] = max(mean(cc, 1));
lag = lags(best);
corr_at_lag = cc(:, best);
a = x(:, 1+lag:end);
b = ref(:, 1:end-lag);
gain = std(a, 0, 2) ./ std(b, 0, 2);
end
