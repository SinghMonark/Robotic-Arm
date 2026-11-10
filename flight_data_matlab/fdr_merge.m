function M = fdr_merge(tables, labels)
%FDR_MERGE  Join several resampled tables on their common 'Time' values.
%
%   M = fdr_merge(TABLES, LABELS)
%     TABLES - cell array of tables, all resampled with the same rate
%     LABELS - string array, one short name per table. If a parameter name
%              already exists in the merged table it gets "_<label>"
%              appended, instead of pandas' anonymous _x / _y.
%
%   Inner join: only time points present in EVERY table are kept (same as
%   pd.merge(how="inner")). The function reports how many rows survive so
%   dropouts don't vanish silently.

labels = string(labels);
M = tables{1};
fprintf('\nMerging on Time:\n  %-25s %7d rows\n', labels(1), height(M));

for i = 2:numel(tables)
    Ti = tables{i};
    names = string(Ti.Properties.VariableNames);
    clash = intersect(names, string(M.Properties.VariableNames));
    clash(clash == "Time") = [];
    for c = clash
        names(names == c) = c + "_" + matlab.lang.makeValidName(labels(i));
    end
    if ~isempty(clash)
        fprintf('  renamed %d duplicate parameter(s) from %s with suffix _%s\n', ...
            numel(clash), labels(i), labels(i));
    end
    Ti.Properties.VariableNames = cellstr(names);

    fprintf('  %-25s %7d rows\n', labels(i), height(Ti));
    M = innerjoin(M, Ti, 'Keys', 'Time');
end

if isempty(M)
    warning('fdr:emptyMerge', ['The merged table is empty: the files have no ' ...
        'common time points. Check that they cover the same time span and use the same time base.']);
else
    fprintf('  => merged: %d rows, %d parameters, t = %.3f .. %.3f s\n', ...
        height(M), width(M) - 1, M.Time(1), M.Time(end));
end
end
