function [fig, h] = fdr_multiaxis_plot(T, spec, varargin)
%FDR_MULTIAXIS_PLOT  Time-history plot with any number of y-axes.
%
%   [FIG, H] = fdr_multiaxis_plot(T, SPEC, Name, Value, ...)
%
%   T    - table with a 'Time' column (seconds)
%   SPEC - struct array, one element per y-axis, with fields
%            Label  - y-axis title
%            Params - cellstr / string array of column names on this axis
%            Side   - 'left' or 'right'
%            Color  - axis colour, '#RRGGBB' or [r g b]
%          The first element is the main axis (next to the plot, left).
%          Further axes on the same side are stacked outwards in the
%          order they appear, like the free axes in the Plotly scripts.
%
%   Options
%     'Title'        - figure title                         ('')
%     'XLabel'       - x-axis label                         ('Time (s)')
%     'OutFile'      - path without extension; writes <OutFile>.fig
%                      (interactive) and <OutFile>.png       ('')
%     'Size'         - figure size [width height] in pixels ([1500 750])
%     'AxisSpacing'  - pixels between stacked y-axes         (80)
%     'LineWidth'    -                                       (1)
%     'TraceColors'  - 'axis'     : traces take their axis colour and
%                                   differ by line style (easy to see
%                                   which axis a trace belongs to)
%                      'distinct' : every trace its own colour (Plotly look)
%     'Visible'      - 'on' / 'off' (off = batch export)     ('on')
%
%   Interaction: zoom / pan act on the time axis of all traces together,
%   data tips work on every trace, and clicking a legend entry hides or
%   shows that trace (like clicking a Plotly legend item).
%
%   After reopening a saved .fig, call fdr_link_axes(gcf) to restore the
%   shared time axis.

p = inputParser;
p.addParameter('Title', '');
p.addParameter('XLabel', 'Time (s)');
p.addParameter('OutFile', '');
p.addParameter('Size', [1500 750]);
p.addParameter('AxisSpacing', 80);
p.addParameter('LineWidth', 1);
p.addParameter('TraceColors', 'axis');
p.addParameter('Visible', 'on');
p.parse(varargin{:});
o = p.Results;

defaultColors = {'#0000FF', '#FF0000', '#006400', '#8F00FF', '#FF8C00', '#008B8B', '#8B4513'};
lineStyles    = {'-', '--', ':', '-.'};

% ---- Validate the requested parameters ----------------------------------
available = string(T.Properties.VariableNames);
keep = true(numel(spec), 1);
for i = 1:numel(spec)
    params = reshape(string(spec(i).Params), 1, []);
    ok = ismember(params, available);
    for m = params(~ok)
        hint = available(contains(lower(available), lower(extractBefore(m + "   ", 4))));
        warning('fdr:paramMissing', 'Parameter "%s" not found - skipped.%s', m, ...
            similarText(hint));
    end
    params = params(ok);
    isNum = arrayfun(@(q) isnumeric(T.(char(q))), params);
    for m = params(~isNum)
        warning('fdr:paramText', 'Parameter "%s" is not numeric - skipped.', m);
    end
    spec(i).Params = params(isNum);
    keep(i) = ~isempty(spec(i).Params);
end
spec = spec(keep);
if isempty(spec)
    error('fdr:nothingToPlot', 'None of the requested parameters exist in the table.');
end
nAx = numel(spec);

% ---- Figure and layout ---------------------------------------------------
fig = figure('Name', char(o.Title), 'NumberTitle', 'off', 'Color', 'w', ...
    'Position', [40 40 o.Size], 'Visible', o.Visible);

sides  = lower(strtrim(string({spec.Side})));
if any(~ismember(sides, ["left" "right"]))
    error('fdr:side', 'Side must be ''left'' or ''right''.');
end
nLeft  = sum(sides == "left");
nRight = sum(sides == "right");
gap    = o.AxisSpacing / o.Size(1);
plotLeft  = 0.01 + max(nLeft, 1) * gap;
plotRight = 1 - 0.01 - max(nRight, 0.5) * gap;
plotPos   = [plotLeft 0.15 plotRight - plotLeft 0.77];   % bottom fixed later

xl = [min(T.Time) max(T.Time)];
if xl(1) == xl(2), xl = xl + [-1 1]; end

dataAx  = gobjects(nAx, 1);
spineAx = gobjects(nAx, 1);
traces  = gobjects(0);
legendNames = strings(0);
leftCount = 0; rightCount = 0;
traceNo = 0;

for i = 1:nAx
    axColor = toRGB(spec(i), defaultColors{mod(i - 1, numel(defaultColors)) + 1});

    % -- data axes: all stacked on the same rectangle --
    ax = axes(fig, 'Units', 'normalized', 'Position', plotPos, ...
        'Tag', sprintf('fdr_data_%d', i), 'XLim', xl, 'TickDir', 'out');
    hold(ax, 'on');
    if i == 1
        ax.GridColor = [0.15 0.15 0.15];
        ax.GridAlpha = 0.15;
        grid(ax, 'on');
        ax.Box = 'off';
        xlabel(ax, o.XLabel, 'Interpreter', 'none');
        title(ax, o.Title, 'Interpreter', 'none', 'FontSize', 14);
    else
        ax.Color = 'none';          % transparent; clicks fall through
        ax.XColor = 'none';
        try ax.Toolbar.Visible = 'off'; catch, end
    end
    ax.YColor = 'none';             % its y-ruler is drawn by the spine
    try
        ax.Interactions = [panInteraction('Dimensions', 'x'), ...
                           zoomInteraction('Dimensions', 'x'), dataTipInteraction];
    catch
    end

    params = spec(i).Params;
    for j = 1:numel(params)
        traceNo = traceNo + 1;
        if strcmpi(o.TraceColors, 'distinct')
            c  = traceColor(traceNo);
            ls = '-';
        else
            c  = axColor;
            ls = lineStyles{mod(j - 1, numel(lineStyles)) + 1};
        end
        hl = plot(ax, T.Time, T.(char(params(j))), 'Color', c, 'LineStyle', ls, ...
            'LineWidth', o.LineWidth, 'DisplayName', params(j));
        try
            hl.DataTipTemplate.DataTipRows(1).Label = 'Time';
            hl.DataTipTemplate.DataTipRows(2).Label = char(params(j));
        catch
        end
        traces(end + 1) = hl; %#ok<AGROW>
        legendNames(end + 1) = params(j); %#ok<AGROW>
    end
    ax.YLim = paddedLimits(T, params);

    % -- spine: a zero-width axes that only shows the y-ruler --
    if sides(i) == "left"
        xPos = plotLeft - leftCount * gap;  leftCount = leftCount + 1;
        spPos = [xPos, plotPos(2), 1e-4, plotPos(4)];
    else
        xPos = plotRight + rightCount * gap;  rightCount = rightCount + 1;
        spPos = [xPos - 1e-4, plotPos(2), 1e-4, plotPos(4)];
    end
    sp = axes(fig, 'Units', 'normalized', 'Position', spPos, 'Color', 'none', ...
        'Tag', sprintf('fdr_spine_%d', i), 'YAxisLocation', char(sides(i)), ...
        'YColor', axColor, 'TickDir', 'out', 'YLim', ax.YLim, 'Box', 'off');
    sp.XAxis.Visible = 'off';
    ylabel(sp, spec(i).Label, 'Color', axColor, 'Interpreter', 'none', 'FontWeight', 'bold');
    try sp.Toolbar.Visible = 'off'; catch, end
    try disableDefaultInteractivity(sp); catch, end

    dataAx(i)  = ax;
    spineAx(i) = sp;
end

% ---- Legend below the plot (clickable, hides/shows a trace) -------------
legAx = axes(fig, 'Units', 'normalized', 'Position', [0 0 1 1e-3], ...
    'Visible', 'off', 'Tag', 'fdr_legend_axes', 'HitTest', 'off');
hold(legAx, 'on');
dummies = gobjects(numel(traces), 1);
for k = 1:numel(traces)
    dummies(k) = plot(legAx, NaN, NaN, 'Color', traces(k).Color, ...
        'LineStyle', traces(k).LineStyle, 'LineWidth', 1.5, 'UserData', traces(k));
end
lg = legend(legAx, dummies, cellstr(legendNames), 'Interpreter', 'none', ...
    'Orientation', 'horizontal', 'NumColumns', min(numel(traces), 6), ...
    'ItemHitFcn', @toggleTrace, 'Box', 'off');
lg.Units = 'normalized';
drawnow;
lp = lg.Position;
lg.Position = [0.5 - lp(3) / 2, 0.01, lp(3), lp(4)];

% now that the legend height is known, fix the plot bottom
bottom = 0.01 + lp(4) + 0.075;
top    = 0.92;
for i = 1:nAx
    dataAx(i).Position([2 4])  = [bottom, top - bottom];
    spineAx(i).Position([2 4]) = [bottom, top - bottom];
end

fdr_link_axes(fig);
fig.CurrentAxes = dataAx(1);
try
    z = zoom(fig);  z.Motion = 'horizontal';
    pn = pan(fig);  pn.Motion = 'horizontal';
catch
end

h = struct('Figure', fig, 'DataAxes', dataAx, 'SpineAxes', spineAx, ...
    'Lines', traces, 'Legend', lg);

% ---- Export -------------------------------------------------------------
if strlength(string(o.OutFile)) > 0
    out = char(o.OutFile);
    folder = fileparts(out);
    if ~isempty(folder) && ~isfolder(folder), mkdir(folder); end
    savefig(fig, [out '.fig']);
    try
        exportgraphics(fig, [out '.png'], 'Resolution', 200);
    catch
        print(fig, [out '.png'], '-dpng', '-r200');
    end
    fprintf('Saved %s.fig and %s.png\n', out, out);
end
end

% =========================================================================
function toggleTrace(~, evt)
% Legend click: hide/show the real trace; the legend entry greys out.
d = evt.Peer;
r = d.UserData;
if strcmp(r.Visible, 'on')
    r.Visible = 'off';  d.Visible = 'off';
else
    r.Visible = 'on';   d.Visible = 'on';
end
end

function lim = paddedLimits(T, params)
vals = [];
for q = params
    v = double(T.(char(q)));
    vals = [vals; min(v, [], 'omitnan'); max(v, [], 'omitnan')]; %#ok<AGROW>
end
lo = min(vals); hi = max(vals);
if isempty(lo) || isnan(lo)
    lim = [0 1];
elseif lo == hi
    lim = lo + [-1 1] * max(1, abs(lo) * 0.05);
else
    pad = 0.05 * (hi - lo);
    lim = [lo - pad, hi + pad];
end
end

function c = toRGB(s, fallback)
c = fallback;
if isfield(s, 'Color') && ~isempty(s.Color) && ...
        ~((ischar(s.Color) || isstring(s.Color)) && strlength(string(s.Color)) == 0)
    c = s.Color;
end
if ischar(c) || isstring(c)
    c = char(c);
    if c(1) == '#'
        c = sscanf(c(2:end), '%2x%2x%2x', [1 3]) / 255;
    end
end
end

function c = traceColor(k)
cmap = lines(7);
c = cmap(mod(k - 1, 7) + 1, :);
end

function txt = similarText(hint)
if isempty(hint)
    txt = '';
else
    txt = sprintf(' Similar names: %s', strjoin(hint(1:min(end, 8)), ', '));
end
end
