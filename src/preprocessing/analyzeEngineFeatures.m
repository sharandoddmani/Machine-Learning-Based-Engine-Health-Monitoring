function analyzeEngineFeatures(X, y, figureDir, reportPath)
% Use only the original publisher training data for exploratory analysis.
names = engineSchema;
R = corrcoef([X y]);
[file, message] = fopen(reportPath, 'w', 'n', 'UTF-8');
if file < 0, error('EngineData:Report', '%s', message); end
cleanup = onCleanup(@() fclose(file));
fprintf(file, 'Stage 2 feature analysis, original publisher training (%d rows)\n', size(X, 1));
writeSummary(file, 'All training records', X, names);
for label = 0:1
    writeSummary(file, sprintf('Class %d', label), X(y == label, :), names);
end
fprintf(file, '\nPairwise Pearson sensor correlations in input order\n');
fprintf(file, 'Input order: %s\n', strjoin(names, ', '));
for k = 1:numel(names)
    fprintf(file, '%-22s', names{k});
    fprintf(file, ' %8.4f', R(k, 1:numel(names)));
    fprintf(file, '\n');
end
fprintf(file, '\nPearson association with the 0/1 target (point-biserial correlation)\n');
for k = 1:numel(names)
    fprintf(file, '%-22s %8.4f\n', names{k}, R(k, end));
end
pairs = abs(R(1:end-1, 1:end-1));
pairs(~triu(true(size(pairs)), 1)) = NaN;
[strongest, linearIndex] = max(pairs(:), [], 'omitnan');
if isfinite(strongest)
    [a, b] = ind2sub(size(pairs), linearIndex);
    fprintf(file, '\nLargest absolute sensor pair correlation: %s and %s (r = %.4f).\n', ...
        names{a}, names{b}, R(a,b));
end
[strongest, index] = max(abs(R(1:end-1, end)), [], 'omitnan');
if isfinite(strongest)
    fprintf(file, 'Largest absolute linear target association: %s (r = %.4f).\n', names{index}, R(index,end));
end
constant = names(all(X == X(1,:), 1));
fprintf(file, 'Constant features: %d. %s\n', numel(constant), strjoin(constant, ', '));
fprintf(file, 'Sensor pairs with absolute Pearson r >= 0.95: %d.\n', nnz(pairs >= 0.95));
fprintf(file, ['This threshold screens for strong linear redundancy only. All six sensors are retained.\n' ...
    'Compare within-sensor class summaries using the same scale. Units are unverified.\n' ...
    'Potential outliers are observations beyond the 1.5 IQR fences. Flags are descriptive.\n' ...
    'Correlations do not establish causation or physical fault types.\n' ...
    'See preprocessing_report.txt for split, provenance and dataset limitations.\n']);
writePlots(X, y, names, R(1:end-1,1:end-1), figureDir);
end

function writeSummary(file, label, X, names)
q = quantile(X, [0.25 0.75], 1);
spread = q(2,:) - q(1,:);
low = q(1,:) - 1.5*spread;
high = q(2,:) + 1.5*spread;
stats = [min(X); max(X); mean(X); median(X); std(X, 0, 1); sum(X < low | X > high, 1)];
fprintf(file, '\n%s (n = %d)\n', label, size(X,1));
fprintf(file, '%-22s %12s %12s %12s %12s %12s %12s\n', ...
    'Sensor', 'Min', 'Max', 'Mean', 'Median', 'Sample SD', 'IQR flags');
for k = 1:numel(names)
    fprintf(file, '%-22s %12.6g %12.6g %12.6g %12.6g %12.6g %12d\n', names{k}, stats(:,k));
end
end

function writePlots(X, y, names, R, folder)
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 1100 720]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact');
title(layout, 'Publisher training sensor distributions');
for k = 1:numel(names)
    ax = nexttile(layout);
    histogram(ax, X(:,k));
    xlabel(ax, names{k}, 'Interpreter', 'none');
    ylabel(ax, 'Records');
end
exportgraphics(fig, fullfile(folder, 'stage2_sensor_histograms.png'), 'Resolution', 160);

clf(fig);
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact');
title(layout, 'Publisher training sensors by engine condition class');
for k = 1:numel(names)
    ax = nexttile(layout);
    boxchart(ax, y, X(:,k));
    xticks(ax, [0 1]);
    xticklabels(ax, {'Class 0','Class 1'});
    ylabel(ax, names{k}, 'Interpreter', 'none');
end
exportgraphics(fig, fullfile(folder, 'stage2_sensor_boxplots.png'), 'Resolution', 160);

clf(fig);
chart = heatmap(fig, names, names, R, 'ColorLimits', [-1 1], 'CellLabelFormat', '%.2f');
chart.Title = 'Pearson correlations of publisher training sensors';
chart.Interpreter = 'none';
exportgraphics(fig, fullfile(folder, 'stage2_sensor_correlation.png'), 'Resolution', 160);

clf(fig);
ax = axes(fig);
counts = [nnz(y == 0), nnz(y == 1)];
bar(ax, 0:1, counts);
text(ax, 0:1, counts, compose('%.2f%%', 100*counts/numel(y)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
ylim(ax, [0 1.12*max(counts)]);
xticks(ax, [0 1]);
xticklabels(ax, {'Class 0','Class 1'});
ylabel(ax, 'Records');
title(ax, 'Publisher training class distribution');
exportgraphics(fig, fullfile(folder, 'stage2_class_distribution.png'), 'Resolution', 160);
end
