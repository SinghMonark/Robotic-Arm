%% RUN_FBW_PLOT
% MATLAB version of FBW_Standard_Data.py
%
% Pitch-axis fly-by-wire check: pilot stick input -> stabiliser deflection
% -> aircraft response (AoA, pitch) -> flight path (height, speed),
% all on one time axis with 6 y-axes.
%
% Unlike the Python script, the "Stick_Pitch" and "Stab_L" axis titles are
% on the correct traces (they were swapped there).

clear; clc; close all;
here = fileparts(mfilename('fullpath'));
if ~isempty(here), addpath(here); end

%% ---------------------------- SETTINGS ----------------------------------
inputFile = fullfile(pwd, 'ANDY-RAI.xlsx');
outFolder = fullfile(pwd, 'output');
sheet     = 1;
headerRow = 3;            % Python: skiprows=2 -> names are in row 3

% Column names after trimming spaces ('  Habs#3' -> 'Habs#3')
renameCols = {'Habs#3', 'Height'};

%% 1. Read -----------------------------------------------------------------
T = fdr_read_excel(inputFile, 'Sheet', sheet, 'HeaderRow', headerRow, ...
    'Rename', renameCols);
fdr_sample_rate_check(T, 'ANDY-RAI');
columns = T.Properties.VariableNames';    % parameter list (Python: aa)

%% 2. Plot -----------------------------------------------------------------
ax = @(label, params, side, color) struct('Label', label, 'Params', {params}, ...
    'Side', side, 'Color', color);

spec = [
    ax('Height (m)',  {'Height'},       'left',  '#0000FF')
    ax('Speed',       {'Vind#3'},       'left',  '#FF0000')
    ax('Stick_Pitch', {'Xpt'},          'left',  '#FF8C00')
    ax('AOA',         {'ATTACKangl_1'}, 'right', '#006400')
    ax('Pitch',       {'PITCH_1'},      'right', '#8F00FF')
    ax('Stab_L',      {'STBl'},         'right', '#008B8B')
    ];

fdr_multiaxis_plot(T, spec, 'Title', 'FBW_Andy_Rai_Basic_1', ...
    'OutFile', fullfile(outFolder, 'FBW_Andy_Rai_Basic_1'));
