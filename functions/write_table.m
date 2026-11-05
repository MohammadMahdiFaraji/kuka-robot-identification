function md = write_table(T, file, title)
% WRITE_TABLE  Save a "paper against reproduced" table (from compare_table) as a CSV file and
% return the same table as Markdown text.
writetable(T, file);
md = sprintf('### %s\n\n', title);
md = [md '| | train NRMSE paper | reproduced | train R² paper | reproduced | test NRMSE paper | reproduced | test R² paper | reproduced | same |' newline];
md = [md '|---|---:|---:|---:|---:|---:|---:|---:|---:|:---:|' newline];
for i = 1:height(T)
    line = sprintf('| %s |', T.row(i));
    for c = 2:9
        line = [line sprintf(' %s |', num2str(T{i, c}, 10))];
    end
    if T.match(i)
        line = [line ' yes |'];
    else
        line = [line ' no |'];
    end
    md = [md line newline];
end
md = [md newline];
end
