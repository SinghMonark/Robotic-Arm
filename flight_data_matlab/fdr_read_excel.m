function T = fdr_read_excel(file, varargin)
%FDR_READ_EXCEL  Read one FDR / flight-test export from Excel into a table.
%
%   T = fdr_read_excel(FILE) reads the first sheet of FILE, taking the
%   parameter names from row 1.
%
%   T = fdr_read_excel(FILE, Name, Value, ...) options:
%     'Sheet'      - sheet name or index                     (default 1)
%     'HeaderRow'  - row number holding the parameter names  (default 1)
%                    e.g. 3 if the export has two title lines above the
%                    names (same as pandas skiprows=2).
%     'TimeColumn' - name of the time column. Empty = first column whose
%                    name starts with "time" (case-insensitive). (default "")
%     'Rename'     - N-by-2 cell {'oldName','newName'; ...} applied after
%                    the names have been trimmed.            (default {})
%     'Verbose'    - print a summary                         (default true)
%
%   What it does (the "standardisation" step of the Python scripts):
%     * keeps the original parameter names (e.g. '211_D_TGT', 'Vind#3')
%     * strips leading AND trailing spaces from the names
%     * renames the time column to 'Time' and converts it to seconds
%     * converts numeric-looking text columns to double
%     * removes rows without a time, sorts by time and drops duplicate
%       time stamps (keeps the first one, like drop_duplicates)

p = inputParser;
p.addRequired('file', @(x) ischar(x) || isstring(x));
p.addParameter('Sheet', 1);
p.addParameter('HeaderRow', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('TimeColumn', "", @(x) ischar(x) || isstring(x));
p.addParameter('Rename', {}, @iscell);
p.addParameter('Verbose', true, @islogical);
p.parse(file, varargin{:});
o = p.Results;

file = char(o.file);
if ~isfile(file)
    error('fdr:fileNotFound', 'File not found: %s', file);
end

% ---- Read ---------------------------------------------------------------
opts = detectImportOptions(file, 'Sheet', o.Sheet, ...
    'Range', sprintf('A%d', o.HeaderRow), 'VariableNamingRule', 'preserve');
opts.VariableNamesRange = sprintf('A%d', o.HeaderRow);
opts.DataRange          = sprintf('A%d', o.HeaderRow + 1);
T = readtable(file, opts);

% ---- Clean parameter names ---------------------------------------------
names = strtrim(string(T.Properties.VariableNames));
names(names == "") = "Var";
names = matlab.lang.makeUniqueStrings(names);
T.Properties.VariableNames = cellstr(names);

for k = 1:size(o.Rename, 1)
    oldName = strtrim(string(o.Rename{k, 1}));
    newName = string(o.Rename{k, 2});
    idx = find(names == oldName, 1);
    if isempty(idx)
        warning('fdr:renameMissing', '%s: column "%s" not found, not renamed.', ...
            file, oldName);
    else
        names(idx) = newName;
    end
end
T.Properties.VariableNames = cellstr(names);

% ---- Time column --------------------------------------------------------
timeName = strtrim(string(o.TimeColumn));
if timeName == ""
    idx = find(startsWith(lower(names), "time"), 1);
    if isempty(idx)
        error('fdr:noTime', ['%s: no column starting with "Time" found. ' ...
            'Pass ''TimeColumn'' explicitly. Columns are:\n  %s'], ...
            file, strjoin(names, ', '));
    end
else
    idx = find(names == timeName, 1);
    if isempty(idx)
        error('fdr:noTime', '%s: time column "%s" not found.', file, timeName);
    end
end
names(idx) = "Time";
T.Properties.VariableNames = cellstr(names);
T.Time = toSeconds(T.Time);

% ---- Numeric conversion of text columns ---------------------------------
for v = string(T.Properties.VariableNames)
    col = T.(v);
    if iscellstr(col) || isstring(col) || iscategorical(col)
        num = str2double(string(col));
        present = ~ismissing(string(col)) & strtrim(string(col)) ~= "";
        if any(present) && mean(~isnan(num(present))) > 0.9
            T.(v) = num;
        end
    end
end

% ---- Time clean-up ------------------------------------------------------
nRead = height(T);
T = T(~isnan(T.Time), :);
T = sortrows(T, 'Time');                       % stable sort
[~, first] = unique(T.Time, 'first');
T = T(first, :);

if o.Verbose
    [~, base, ext] = fileparts(file);
    fprintf('Read %-35s %7d rows (%d after removing duplicate/empty times), %d parameters, t = %.3f .. %.3f s\n', ...
        [base ext], nRead, height(T), width(T) - 1, T.Time(1), T.Time(end));
end
end

% -------------------------------------------------------------------------
function t = toSeconds(t)
% Convert a time column of any common type to double seconds.
if isnumeric(t)
    t = double(t);
elseif isduration(t)
    t = seconds(t);
elseif isdatetime(t)
    t = seconds(t - dateshift(t(1), 'start', 'day'));   % seconds of day
else                                                    % text
    s = string(t);
    num = str2double(s);
    if mean(isnan(num)) < 0.5
        t = num;
    else
        try
            t = seconds(duration(s));                   % 'hh:mm:ss.SSS'
        catch
            error('fdr:timeFormat', 'Could not convert the time column to seconds.');
        end
    end
end
t = t(:);
end
