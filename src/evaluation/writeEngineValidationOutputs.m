function writeEngineValidationOutputs(benchmark, reportPath, figureDir)
% Report every setting and plot the best validated setting per algorithm.
writeReport(benchmark, reportPath);
best = benchmark.candidates(benchmark.bestPerAlgorithm);
plotComparisons(best, figureDir);
end

function writeReport(benchmark, reportPath)
[file, message] = fopen(reportPath, 'w', 'n', 'UTF-8');
if file < 0, error('EngineModels:Report', '%s', message); end
cleanup = onCleanup(@() fclose(file));
fprintf(file, 'Stage 3 model training and validation\nMATLAB %s\n', benchmark.matlabVersion);
fprintf(file, 'Statistics and Machine Learning Toolbox %s\n', benchmark.toolboxVersion.Version);
fprintf(file, 'Predictor order: %s\n', strjoin(benchmark.featureNames, ', '));
fprintf(file, 'Development-training: %d rows. Validation: %d rows. Seed: %d.\n', ...
    numel(benchmark.developmentIndices), numel(benchmark.validationIndices), benchmark.seed);
fprintf(file, ['All candidate fits use the Stage 2 development rows and fitted standardization.\n' ...
    'Selection uses validation only. The publisher test split is held out.\n' ...
    'Ranking: macro F1, balanced accuracy, accuracy, then first listed candidate.\n' ...
    'Ranking uses unrounded scores. Undefined precision, recall and F1 are zero.\n' ...
    'Class 0 and Class 1 have unverified physical meanings.\n\n']);
fprintf(file, '%-14s %-17s %9s %9s %9s %9s %9s\n', ...
    'Algorithm', 'Setting', 'Accuracy', 'Macro F1', 'Bal. acc.', 'Recall 0', 'Recall 1');
for c = benchmark.candidates
    m = c.validationMetrics;
    fprintf(file, '%-14s %-17s %9.6f %9.6f %9.6f %9.6f %9.6f\n', ...
        c.algorithm, c.setting, m.accuracy, m.macroF1, m.balancedAccuracy, m.recall);
end
fprintf(file, '\nBest configuration by algorithm\n');
for c = benchmark.candidates(benchmark.bestPerAlgorithm)
    fprintf(file, '%s (%s)\n', c.algorithm, c.setting);
end
winner = benchmark.candidates(benchmark.bestOverall);
fprintf(file, '\nOverall validation selection: %s (%s)\n', winner.algorithm, winner.setting);
for c = benchmark.candidates
    m = c.validationMetrics;
    fprintf(file, '\n%s (%s)\nSettings: %s\n', c.algorithm, c.setting, jsonencode(c.hyperparameters));
    fprintf(file, 'Confusion matrix, actual rows and predicted columns, both ordered [0 1]\n');
    fprintf(file, '%5d %5d\n', m.confusionMatrix');
    fprintf(file, 'Class   Precision    Recall        F1\n');
    for k = 1:2
        fprintf(file, '%5d   %9.6f %9.6f %9.6f\n', ...
            m.classOrder(k), m.precision(k), m.recall(k), m.f1(k));
    end
end
fprintf(file, ['\nValidation is used for tuning and selection. These scores are development estimates.\n' ...
    'Engine IDs and timestamps are unavailable in the project data. Group and temporal\n' ...
    'independence are unverified. Final held-out evaluation awaits project-guide review.\n']);
end

function plotComparisons(best, folder)
metrics = [best.validationMetrics];
labels = string({best.algorithm}) + " (" + string({best.setting}) + ")";
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 1150 650]);
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
bar(ax, [[metrics.macroF1]', [metrics.balancedAccuracy]', [metrics.accuracy]']);
formatBars(ax, labels);
title(ax, 'Validation scores for the best setting per algorithm');
legend(ax, {'Macro F1','Balanced accuracy','Accuracy'}, 'Location', 'southoutside', ...
    'Orientation', 'horizontal');
exportgraphics(fig, fullfile(folder, 'stage3_algorithm_comparison.png'), 'Resolution', 160);

clf(fig);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
title(layout, 'Validation confusion matrices for the best setting per algorithm');
for k = 1:numel(best)
    ax = nexttile(layout);
    counts = metrics(k).confusionMatrix;
    imagesc(ax, counts, [0 max([metrics.confusionMatrix], [], 'all')]);
    axis(ax, 'square');
    colormap(ax, flipud(gray(256)));
    xticks(ax, 1:2); xticklabels(ax, {'Class 0','Class 1'});
    yticks(ax, 1:2); yticklabels(ax, {'Class 0','Class 1'});
    xlabel(ax, 'Predicted'); ylabel(ax, 'Actual');
    title(ax, labels(k));
    for row = 1:2
        for col = 1:2
            text(ax, col, row, sprintf('%d', counts(row,col)), ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        end
    end
end
exportgraphics(fig, fullfile(folder, 'stage3_confusion_matrices.png'), 'Resolution', 160);

clf(fig);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
title(layout, 'Validation performance by class for the best setting per algorithm');
precision = [metrics.precision];
recall = [metrics.recall];
f1 = [metrics.f1];
for k = 1:2
    ax = nexttile(layout);
    bar(ax, [precision(k,:)', recall(k,:)', f1(k,:)']);
    formatBars(ax, labels);
    title(ax, sprintf('Class %d', k-1));
    legend(ax, {'Precision','Recall','F1'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
end
exportgraphics(fig, fullfile(folder, 'stage3_class_performance.png'), 'Resolution', 160);
end

function formatBars(ax, labels)
ylim(ax, [0 1]);
xticks(ax, 1:numel(labels));
xticklabels(ax, labels);
xtickangle(ax, 15);
ylabel(ax, 'Score');
grid(ax, 'on');
end
