function Tr = fdr_resample(T, fs, method)
%FDR_RESAMPLE  Put a table on a regular time grid of FS samples per second.
%
%   Tr = fdr_resample(T, FS)            uses method 'first'
%   Tr = fdr_resample(T, FS, METHOD)
%
%   METHOD
%     'first'  - round each time stamp to the nearest 1/FS s and keep the
%                first sample in each grid slot (exactly what the Python
%                scripts do: (Time/sr).round()*sr + drop_duplicates).
%                Other samples in the slot are discarded.
%     'mean'   - average all samples that fall into each grid slot
%                (non-numeric columns keep their first value).
%     'linear' - linear interpolation onto the grid between the first and
%                last sample (non-numeric columns take the nearest value).
%
%   The grid times are k/FS, so tables resampled with the same FS share
%   identical time values and can be joined on 'Time'.

if nargin < 3, method = 'first'; end
t = T.Time;
vars = string(T.Properties.VariableNames);
vars(vars == "Time") = [];

switch lower(method)
    case 'first'
        k = round(t * fs);
        [kk, idx] = unique(k, 'first');
        Tr = T(idx, :);
        Tr.Time = kk / fs;

    case 'mean'
        k = round(t * fs);
        [kk, ~, g] = unique(k);
        firstRow = accumarray(g, (1:height(T))', [], @min);
        Tr = T(firstRow, :);
        for v = vars
            col = T.(v);
            if isnumeric(col) && iscolumn(col)
                Tr.(v) = accumarray(g, double(col), [], @(x) mean(x, 'omitnan'));
            end
        end
        Tr.Time = kk / fs;

    case 'linear'
        kk = (ceil(t(1) * fs):floor(t(end) * fs))';
        tg = kk / fs;
        nearestRow = interp1(t, (1:height(T))', tg, 'nearest');
        Tr = T(nearestRow, :);
        for v = vars
            col = T.(v);
            if isnumeric(col) && iscolumn(col)
                Tr.(v) = interp1(t, double(col), tg, 'linear');
            end
        end
        Tr.Time = tg;

    otherwise
        error('fdr:method', 'Unknown method "%s" (use first, mean or linear).', method);
end
end
