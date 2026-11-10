%% RUN_MERGE_16HZ
% MATLAB version of Merged_Data_Final.py
%
% Puts three FDR exports on a common 16 Hz time grid, joins them on Time
% and writes one Excel file with all parameters side by side.
%
% Difference from the Python script: the Time column holds the 16 Hz grid
% time (k/16 s) instead of the original time stamp of the first file.

clear; clc; close all;
here = fileparts(mfilename('fullpath'));
if ~isempty(here), addpath(here); end

%% ---------------------------- SETTINGS ----------------------------------
dataFolder = pwd;
outFolder  = fullfile(pwd, 'output');

% {file name, short label, header row}
files = {
    'Kvik_06.xlsx',          'Kvik06',  1
    'kvik_07.xlsx',          'Kvik07',  1
    'kvik_panel c 08.xlsx',  'Panel08', 1
    };
sheet      = 1;
timeColumn = 'Time';
fs         = 16;          % Hz (Python: sr = 1/16)
method     = 'first';     % 'first' (same as Python) | 'mean' | 'linear'

outFile = fullfile(outFolder, 'Merged_Data.xlsx');

%% Read, check, resample, merge, write ------------------------------------
n = size(files, 1);
resampled = cell(n, 1);
for i = 1:n
    T = fdr_read_excel(fullfile(dataFolder, files{i, 1}), 'Sheet', sheet, ...
        'HeaderRow', files{i, 3}, 'TimeColumn', timeColumn);
    fdr_sample_rate_check(T, files{i, 2});
    resampled{i} = fdr_resample(T, fs, method);
end

M = fdr_merge(resampled, string(files(:, 2)));
fdr_write_excel(M, outFile);
