function step7a_retrain_v1_ssest(fw, file)
% STEP 7a  Train the version 1 forward model again from scratch, with the settings of the official
% code (MASTER_identification_linear.m with enable_new_identification = true): ssest with 12
% states and Focus = simulation on the zero-initialized input. Takes about 2.5 hours.
% Only run by run_all('full').
%
%   fw   : contents of forward_identification_without_raw_data.mat
%   file : where the model is saved; step 7 uses it
fprintf('MATLAB %s\n', version);
u_train = fw.u_train - fw.u_train(:,1);          % the official code starts the input at zero
dt = fw.time_train(2) - fw.time_train(1);
fprintf('dt used by the official code = %.7f s (Listing 2 of the PDF says 0.1)\n', dt);
opt = ssestOptions();
opt.Display = 'off';
opt.Focus = 'simulation';
trained_on = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
fprintf('ssest started %s\n', trained_on);
cpu_start = cputime;
tic;
forward_ss_model_sim = ssest(iddata(fw.y_train', u_train', dt), 12, opt);
tFwd = toc;
cpuFwd = cputime - cpu_start;
trained_by = 'steps/step7a_retrain_v1_ssest.m, run by run_all(''full'')';
save(file, 'forward_ss_model_sim', 'tFwd', 'cpuFwd', 'trained_by', 'trained_on');
fprintf('ssest finished %s: wall time %.1f s (includes any time the computer slept), MATLAB CPU time %.1f s\n', ...
    char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')), tFwd, cpuFwd);
end
