function e = nrmse(y, yhat)
% NRMSE  Normalized root mean square error of every joint, eq. (5) of the paper.
%
% y and yhat have one row per joint. RMSE is divided by the standard deviation of the measured
% signal (with N-1). 0 means a perfect model, 1 means "as good as always guessing the mean".
% The result is a row vector with one value per joint.
e = sqrt(mean((y - yhat).^2, 2)) ./ std(y, 0, 2);
e = e';
end
