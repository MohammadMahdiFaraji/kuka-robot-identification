function r = r2(y, yhat)
% R2  Coefficient of determination in percent for every joint, eq. (6) of the paper (version 2).
%
% r = 100 (1 - SSE/SST), with SST around the mean of the MEASURED signal. This is the correct
% formula. y and yhat have one row per joint; the result is a row vector.
sse = sum((y - yhat).^2, 2);
sst = sum((y - mean(y, 2)).^2, 2);
r = 100 * (1 - sse ./ sst);
r = r';
end
