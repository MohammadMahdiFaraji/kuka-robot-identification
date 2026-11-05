function checks = add_check(checks, id, section, statement, paper, found, status)
% ADD_CHECK  Add one checked statement of the paper to the list and print it.
%
%   checks = add_check(checks, id, section, statement, paper_value, what_we_found, status)
%
% status is one of:
%   MATCH         reproduced exactly, at the precision printed in the paper
%   CONSISTENT    the data support the statement
%   DEVIATION     the data contradict the statement, or the text of the paper is not consistent
%   UNDOCUMENTED  true property of the official data or code that the paper does not mention
%   UNCLEAR       the published material neither confirms nor clearly contradicts it
%   OBSERVATION   not a statement of the paper, but useful for anyone who uses the data

k = numel(checks) + 1;
checks(k).id = id;
checks(k).section = section;
checks(k).claim = statement;
checks(k).paper = paper;
checks(k).reproduced = found;
checks(k).status = status;

fprintf('[%-12s] %-5s (%s) %s\n', status, id, section, statement);
fprintf('               paper: %s\n', paper);
fprintf('               found: %s\n', found);
end
