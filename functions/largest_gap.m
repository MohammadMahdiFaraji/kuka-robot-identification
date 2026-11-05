function g = largest_gap(nrmse_values, r2_values)
% LARGEST_GAP  How far printed (NRMSE, R2) pairs are from R2 = 100 (1 - NRMSE^2).
% If both numbers use the std of the same data set this relation holds exactly, so a small gap
% (only from rounding) shows that the two metrics carry the same information.
g = max(abs(r2_values - 100 * (1 - nrmse_values.^2)));
end
