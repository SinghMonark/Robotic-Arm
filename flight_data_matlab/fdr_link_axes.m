function fdr_link_axes(fig)
%FDR_LINK_AXES  Link the stacked axes of a figure made by fdr_multiaxis_plot.
%
%   fdr_link_axes(FIG) shares the time axis between all traces and keeps
%   each y-ruler (spine) in step with its data. It is called automatically
%   when the plot is created. Call it yourself after reopening a saved
%   .fig file:   fig = openfig('Qvik_Rai_Radar.fig'); fdr_link_axes(fig);

if nargin < 1, fig = gcf; end
dataAx = findobj(fig, 'Type', 'axes', '-regexp', 'Tag', '^fdr_data_\d+$');
if isempty(dataAx)
    warning('fdr:noAxes', 'This figure was not made by fdr_multiaxis_plot.');
    return
end
n = numel(dataAx);
links = cell(n, 1);
for i = 1:n
    ax = findobj(dataAx, 'Tag', sprintf('fdr_data_%d', i));
    sp = findobj(fig, 'Type', 'axes', 'Tag', sprintf('fdr_spine_%d', i));
    if ~isempty(ax) && ~isempty(sp)
        links{i} = linkprop([ax(1) sp(1)], 'YLim');
    end
end
xl = dataAx(1).XLim;
set(dataAx, 'XLim', xl);
linkaxes(dataAx, 'x');
setappdata(fig, 'fdr_links', links);    % linkprop objects must stay alive
end
