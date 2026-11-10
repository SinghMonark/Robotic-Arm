%% RUN_RADAR_ANALYSIS
% MATLAB version of Radar_Standard_Data.py + Graphing_Radar.py
%
%   1. read the radar FDR exports (Excel)
%   2. sample-rate check of every file
%   3. put the selected files on a common 4 Hz grid
%   4. merge them on Time and write the Excel files
%   5. plot the 211 and 226 radar parameters with 4 y-axes each
%
% Edit the SETTINGS block, then run the script (F5). To redo only the
% plots later, run the SETTINGS section and then section 5 or 6
% (Ctrl+Enter); they reload the merged Excel file if M is not in memory.

clear; clc; close all;
here = fileparts(mfilename('fullpath'));
if ~isempty(here), addpath(here); end

%% ---------------------------- SETTINGS ----------------------------------
dataFolder = pwd;                         % folder with the Excel inputs
outFolder  = fullfile(pwd, 'output');     % results go here

% One row per file: {file name, short label, header row}
%   header row = Excel row holding the parameter names
%   (1 if names are in the first row, 3 if there are two title lines).
files = {
    'kvik_sup_01.xlsx',      'Kvik211',  1
    'Kvik_Sup_02.xlsx',      'Sup02',    1
    'Kvik_Sup_03.xlsx',      'Kvik226',  1
    'Kvik_Sup_04.xlsx',      'Sup04',    1
    'Kvik_sup_05.xlsx',      'Sup05',    1
    'Kvik_sup_06.xlsx',      'Sup06',    1
    'Kvik_sup_doppler.xlsx', 'Doppler',  1
    };
sheet      = 1;          % sheet name or number
timeColumn = 'Time';     % '' = first column whose name starts with "Time"

filesToMerge = [1 3];    % rows of the table above (211 and 226 messages)
fs           = 4;        % common sample rate in Hz (Python: sr = 1/4)
method       = 'first';  % 'first' (same as Python) | 'mean' | 'linear'

mergedFile = fullfile(outFolder, 'Data Merge_Kvik_211_226_Parameters.xlsx');

%% 1. Read all files -------------------------------------------------------
nFiles = size(files, 1);
data = struct('File', {}, 'Label', {}, 'Table', {}, 'Columns', {}, 'SampleRate', {});
for i = 1:nFiles
    f = fullfile(dataFolder, files{i, 1});
    if ~isfile(f)
        warning('Missing input, skipped: %s', f);
        continue
    end
    T = fdr_read_excel(f, 'Sheet', sheet, 'HeaderRow', files{i, 3}, ...
        'TimeColumn', timeColumn);
    data(end + 1) = struct('File', files{i, 1}, 'Label', files{i, 2}, ...
        'Table', T, 'Columns', {T.Properties.VariableNames'}, 'SampleRate', []); %#ok<SAGROW>
end
% data(k).Columns lists the parameters of each file (Python: aa, bb, ... gg)

%% 2. Sample-rate check ----------------------------------------------------
for k = 1:numel(data)
    data(k).SampleRate = fdr_sample_rate_check(data(k).Table, data(k).Label);
end

%% 3. Resample the files to be merged -------------------------------------
labels    = string(files(filesToMerge, 2));
resampled = cell(numel(filesToMerge), 1);
for j = 1:numel(filesToMerge)
    k = find(string({data.Label}) == labels(j), 1);
    if isempty(k)
        error('File "%s" selected for merging was not read.', files{filesToMerge(j), 1});
    end
    resampled{j} = fdr_resample(data(k).Table, fs, method);
end

%% 4. Merge and write Excel ------------------------------------------------
M = fdr_merge(resampled, labels);
fdr_write_excel(M, mergedFile);
for j = 1:numel(resampled)
    fdr_write_excel(resampled{j}, fullfile(outFolder, ...
        sprintf('Data Merge_%s_Parameters.xlsx', labels(j))));
end

%% 5. Plot: message 211 (target tracking) ---------------------------------
if ~exist('M', 'var')
    M = fdr_read_excel(mergedFile);
end
ax = @(label, params, side, color) struct('Label', label, 'Params', {params}, ...
    'Side', side, 'Color', color);

spec211 = [
    ax('211_D_TGT',     {'211_D_TGT', '211_dDtgt'},          'left',  '#0000FF')
    ax('211_Az_Elev',   {'211_Az_abs', '211_Elev_abs'},      'left',  '#FF0000')
    ax('211_Fi_q',      {'211_Fi_h', '211_Fi_v', '211_q_h'}, 'right', '#006400')
    ax('211_X_Y_Z_tgt', {'211_Xtgt', '211_Ytgt', '211_Ztgt'},'right', '#8F00FF')
    ];
fdr_multiaxis_plot(M, spec211, 'Title', 'Qvik_Rai_Radar', ...
    'OutFile', fullfile(outFolder, 'Qvik_Rai_Radar'));

%% 6. Plot: message 226 (target state) ------------------------------------
if ~exist('M', 'var')
    M = fdr_read_excel(mergedFile);
end
ax = @(label, params, side, color) struct('Label', label, 'Params', {params}, ...
    'Side', side, 'Color', color);

spec226 = [
    ax('226_Aspect',          {'226_ASPECT_v', '226_ASPECT_h'},                 'left',  '#0000FF')
    ax('226_Rng_Height',      {'226_Rtgt', '226_H_TGT'},                        'left',  '#FF0000')
    ax('226_Az_Elev_Closing', {'226_Tgt_Closing', '226_Tgt_Az', '226_Tgt_Elev'},'right', '#006400')
    ax('226_Vx_Vy_Vz_tgt',    {'226_Vx', '226_Vy', '226_Vz'},                   'right', '#8F00FF')
    ];
fdr_multiaxis_plot(M, spec226, 'Title', 'Qvik_Rai_Radar_226', ...
    'OutFile', fullfile(outFolder, 'Qvik_Rai_Radar_226'));
