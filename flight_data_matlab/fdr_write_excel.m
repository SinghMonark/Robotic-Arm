function fdr_write_excel(T, file)
%FDR_WRITE_EXCEL  Write a table to a fresh .xlsx file (no index column).
%
%   Any existing file is replaced, so no stale rows or sheets are left
%   behind. Checks Excel's size limits first.

maxRows = 1048576 - 1;     % one row is used by the header
maxCols = 16384;
if height(T) > maxRows || width(T) > maxCols
    error('fdr:excelLimit', ['%s: %d rows x %d columns exceeds the Excel limit ' ...
        '(%d x %d). Write a .csv or .mat instead.'], file, height(T), width(T), maxRows, maxCols);
end

folder = fileparts(file);
if folder ~= "" && ~isfolder(folder)
    mkdir(folder);
end
if isfile(file)
    delete(file);
end
writetable(T, file);
fprintf('Wrote %s (%d rows x %d columns)\n', file, height(T), width(T));
end
