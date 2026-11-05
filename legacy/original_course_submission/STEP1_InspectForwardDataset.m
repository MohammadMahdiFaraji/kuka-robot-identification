%% STEP1_InspectForwardDataset.m
clc; clear; close all;

dataFile = "..\..\data\Robot_Identification_Benchmark_With_Raw_Data\forward_identification_without_raw_data.mat";

disp("Loading forward data ...");
S = load(dataFile);

disp("Variables inside forward MAT:");
disp(fieldnames(S));

whos('-file', dataFile);

% نمایش چند فیلد رایج اگر وجود داشتند (بدون خطا)
fn = fieldnames(S);
disp("---- Quick structure peek ----");
for k = 1:numel(fn)
    v = S.(fn{k});
    fprintf("%s: class=%s, size=%s\n", fn{k}, class(v), mat2str(size(v)));
end
