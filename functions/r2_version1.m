function r = r2_version1(y, yhat)
% R2_VERSION1  The R2 formula of the official code of version 1 (MASTER_identification_linear.m).
%
% Same as r2, but SST is taken around the mean of the MODEL output instead of the measured
% signal. This is wrong, but it is needed to reproduce the tables of version 1 of the paper.
sse = sum((y - yhat).^2, 2);
sst = sum((y - mean(yhat, 2)).^2, 2);
r = 100 * (1 - sse ./ sst);
r = r';
end
