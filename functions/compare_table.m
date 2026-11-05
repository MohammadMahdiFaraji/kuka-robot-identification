function [status, found, T] = compare_table(P, y_train, yhat_train, y_test, yhat_test, version)
% COMPARE_TABLE  Compute one result table of the paper again and compare it with the printed one.
%
%   [status, found, T] = compare_table(P, y_train, yhat_train, y_test, yhat_test, version)
%
% P is one table of paper_values. version is 2 (correct R2, default) or 1 (R2 formula of the
% version 1 code). Like in the paper, the per-joint values are rounded to 3 decimals and the
% "all joints" value is the mean of the rounded values, rounded to P.dec decimals.
% T has the paper values and our values side by side (rows: joint 1 to 6 and "all joints").
if nargin < 6
    version = 2;
end
if version == 1
    r2_train = r2_version1(y_train, yhat_train);
    r2_test = r2_version1(y_test, yhat_test);
else
    r2_train = r2(y_train, yhat_train);
    r2_test = r2(y_test, yhat_test);
end

ours = {round(nrmse(y_train, yhat_train), 3), round(r2_train, 3), round(nrmse(y_test, yhat_test), 3), round(r2_test, 3)};
paper = {P.trN, P.trR, P.teN, P.teR};
names = {'train NRMSE', 'train R2', 'test NRMSE', 'test R2'};
columns = {'train_NRMSE', 'train_R2', 'test_NRMSE', 'test_R2'};

T = table(["joint " + (1:6)'; "all joints"], 'VariableNames', {'row'});
found = '';
all_same = true;
for i = 1:4
    average = round(mean(ours{i}), P.dec(i));
    same = all(abs(ours{i} - paper{i}) < 1e-9) && abs(average - P.avg(i)) < 1e-9;
    if ~same
        all_same = false;
    end
    if i > 1
        found = [found '; '];
    end
    found = [found sprintf('%s %s, mean %s', names{i}, mat2str(ours{i}), num2str(average, 10))];
    if ~same
        found = [found sprintf(' [paper %s, mean %s]', mat2str(paper{i}), num2str(P.avg(i), 10))];
    end
    T.([columns{i} '_paper']) = [paper{i}'; P.avg(i)];
    T.([columns{i} '_reproduced']) = [ours{i}'; average];
end

% a row is "the same" when all four pairs agree
T.match = all(abs(T{:, [2 4 6 8]} - T{:, [3 5 7 9]}) < 1e-9, 2);
if all_same
    status = 'MATCH';
else
    status = 'DEVIATION';
end
end
