function R = fdr_sample_rate_check(T, label)
%FDR_SAMPLE_RATE_CHECK  How many samples were recorded in each second.
%
%   R = fdr_sample_rate_check(T, LABEL) groups T.Time into whole seconds,
%   counts the samples in every second and then counts how many seconds had
%   each sample count. A clean 4 Hz recording gives (almost) only "4";
%   seconds with 1-3 samples point to dropouts. The first and last second
%   are usually partial.
%
%   Same check as the df_1 ... df_7 blocks in Radar_Standard_Data.py, plus
%   the nominal rate and the largest time gap.

if nargin < 2, label = ""; end
t = T.Time;

[~, ~, g]  = unique(floor(t));
perSecond  = accumarray(g, 1);
[cnt, ~, g2] = unique(perSecond);
nSec       = accumarray(g2, 1);
R = table(cnt, nSec, 'VariableNames', {'SamplesPerSecond', 'NumSeconds'});
R = sortrows(R, 'NumSeconds', 'descend');

dt = diff(t);
if isempty(dt)
    fprintf('%s: fewer than 2 samples.\n', label);
    return
end
medDt = median(dt);
nGaps = sum(dt > 1.5 * medDt);
[maxGap, iGap] = max(dt);

fprintf('\nSample-rate check: %s\n', label);
fprintf('  nominal rate %.2f Hz (median dt %.4f s), %d gaps > 1.5*dt, largest gap %.3f s at t = %.3f s\n', ...
    1 / medDt, medDt, nGaps, maxGap, t(iGap));
fprintf('  samples/second : number of seconds\n');
for k = 1:height(R)
    fprintf('  %14d : %d\n', R.SamplesPerSecond(k), R.NumSeconds(k));
end
end
