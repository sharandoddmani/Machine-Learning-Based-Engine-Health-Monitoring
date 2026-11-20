function writeFinalEngineEvaluation(bundle, reportPath, figureDir)
% Use the approved Stage 3 record rather than fitting or selecting again.
validation = struct('accuracy', 0.664427, 'macroF1', 0.616311, ...
    'balancedAccuracy', 0.613813, 'recall', [485/1155; 1592/1971]);
writeReport(bundle, validation, reportPath);
writePlots(bundle, validation, figureDir);
end

function writeReport(bundle, validation, reportPath)
[file, message] = fopen(reportPath, 'w', 'n', 'UTF-8');
if file < 0, error('EngineModels:Report', '%s', message); end
cleanup = onCleanup(@() fclose(file));
e = bundle.finalEvaluation;
fprintf(file, 'Stage 4 final held-out model evaluation\nMATLAB %s\n', bundle.matlabVersion);
fprintf(file, 'Statistics and Machine Learning Toolbox %s\n', bundle.toolboxVersion.Version);
fprintf(file, 'Training timestamp (UTC): %s\nTwister seed: %d\n', ...
    bundle.trainingTimestampUtc, bundle.seed);
fprintf(file, 'Approved Stage 3 revision: bda16ea0bed545c28e3235e3fa3a4b7215b70bf3\n');
fprintf(file, 'Publisher training: %d rows x %d sensors + one target (%d Class 0, %d Class 1)\n', ...
    bundle.trainingRows, numel(bundle.featureNames), bundle.trainingClassCounts);
fprintf(file, 'Publisher test: %d rows x %d sensors + one target (%d Class 0, %d Class 1)\n', ...
    e.testRows, numel(bundle.featureNames), e.testClassCounts);
fprintf(file, 'Predictor order: %s\nTarget: %s\n', strjoin(bundle.featureNames, ', '), bundle.targetName);
fprintf(file, '\nLocked model: %s\nSettings: %s\nBranch nodes fitted: %d\n', ...
    bundle.algorithm, jsonencode(bundle.hyperparameters), bundle.actualSplits);
fprintf(file, ['The tree and standardization were refitted on all publisher training rows.\n' ...
    'The test split was opened after fitting and used only for scoring.\n' ...
    'Both splits use the training means and sample standard deviations (N-1).\n' ...
    'Zero standard deviations use a divisor of 1. Undefined class metrics are zero.\n' ...
    'The saved model was reloaded and produced identical test predictions.\n']);
p = bundle.preprocessing;
fprintf(file, '\n%-22s %16s %16s %16s\n', 'Feature', 'Mean', 'Sample SD', 'Scale');
for k = 1:numel(bundle.featureNames)
    fprintf(file, '%-22s %16.10g %16.10g %16.10g\n', ...
        bundle.featureNames{k}, p.mean(k), p.std(k), p.scale(k));
end
printMetrics(file, 'Final Decision Tree (test)', e.tree);
fprintf(file, '\nThe training-set majority baseline predicts Class %d on every test row.\n', ...
    bundle.majorityClass);
printMetrics(file, 'Majority baseline (test)', e.baseline);

fprintf(file, '\nTest Decision Tree vs majority baseline\n');
minorityIndex = 3 - (bundle.majorityClass + 1);
metricNames = {'Accuracy','Macro F1','Balanced accuracy',sprintf('Class %d recall (training minority)', minorityIndex-1)};
treeScores = [summaryScores(e.tree), e.tree.recall(minorityIndex)];
baselineScores = [summaryScores(e.baseline), e.baseline.recall(minorityIndex)];
for k = 1:numel(metricNames)
    delta = treeScores(k) - baselineScores(k);
    directions = {'lower','equal','higher'};
    fprintf(file, '%-35s %+8.3f percentage points (%s)\n', ...
        metricNames{k}, 100*delta, directions{sign(delta)+2});
end

fprintf(file, '\nApproved Stage 3 validation vs Stage 4 held-out test\n');
fprintf(file, '%-21s %12s %12s\n', 'Metric', 'Validation', 'Test');
names = {'Accuracy','Macro F1','Balanced accuracy','Class 0 recall','Class 1 recall'};
v = [summaryScores(validation), validation.recall'];
t = [summaryScores(e.tree), e.tree.recall'];
for k = 1:numel(names)
    fprintf(file, '%-21s %12.6f %12.6f\n', names{k}, v(k), t(k));
end
fprintf(file, ['Validation scored the development-trained tree on 3126 validation rows.\n' ...
    'Stage 4 scored a separate refit on 3907 publisher test rows. Both fitted models\n' ...
    'and partitions differ, so score changes alone cannot isolate overfitting.\n']);
fprintf(file, ['\nValidation correctly classified 485 of 1155 Class 0 rows and\n' ...
    'predicted Class 1 for the other 670, giving Class 0 recall of %.2f%%.\n'], 100*validation.recall(1));
cm = e.tree.confusionMatrix;
fprintf(file, ['Test correctly classified %d of %d Class 0 rows and predicted Class 1 for %d.\n' ...
    'Test predicted Class 0 for %d actual Class 1 rows.\n'], cm(1,1), sum(cm(1,:)), cm(1,2), cm(2,1));
if e.tree.recall(1) < e.tree.recall(2)
    fprintf(file, 'The lower Class 0 recall seen on validation also appears on the test split.\n');
else
    fprintf(file, 'The test split does not reproduce the lower Class 0 recall seen on validation.\n');
end
fprintf(file, ['\nClass meanings, acquisition process, and publisher split method remain unverified.\n' ...
    'Engine IDs and timestamps are absent. Pressure and temperature units are unverified.\n' ...
    'These results describe this academic benchmark. See docs/dataset_provenance.txt.\n']);
end

function printMetrics(file, titleText, m)
fprintf(file, '\n%s\n', titleText);
fprintf(file, 'Accuracy: %.6f\nCorrect: %d\nIncorrect: %d\n', ...
    m.accuracy, m.correctCount, m.incorrectCount);
fprintf(file, 'Macro precision: %.6f\nMacro recall: %.6f\nMacro F1: %.6f\nBalanced accuracy: %.6f\n', ...
    m.macroPrecision, m.macroRecall, m.macroF1, m.balancedAccuracy);
fprintf(file, 'Class     Precision      Recall          F1\n');
for k = 1:2
    fprintf(file, '%5d     %9.6f   %9.6f   %9.6f\n', m.classOrder(k), m.precision(k), m.recall(k), m.f1(k));
end
fprintf(file, 'Confusion matrix (actual rows, predicted columns, order [0 1]):\n');
fprintf(file, '%5d %5d\n', m.confusionMatrix');
end

function scores = summaryScores(m)
scores = [m.accuracy, m.macroF1, m.balancedAccuracy];
end

function writePlots(bundle, validation, folder)
e = bundle.finalEvaluation;
m = e.tree;
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 980 580]);
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
cm = m.confusionMatrix;
imagesc(ax, cm, [0 max(cm, [], 'all')]);
axis(ax, 'image');
colormap(ax, flipud(gray(256)));
colorbar(ax);
xticks(ax, 1:2); xticklabels(ax, {'Class 0','Class 1'});
yticks(ax, 1:2); yticklabels(ax, {'Class 0','Class 1'});
xlabel(ax, 'Predicted class'); ylabel(ax, 'Actual class');
title(ax, 'Final Decision Tree confusion matrix | held-out test');
for row = 1:2
    for col = 1:2
        text(ax, col, row, sprintf('%d', cm(row,col)), 'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'center', 'FontSize', 13);
    end
end
exportgraphics(fig, fullfile(folder, 'stage4_test_confusion_matrix.png'), 'Resolution', 240);

clf(fig);
plotScores(axes(fig), [m.precision, m.recall, m.f1], {'Class 0','Class 1'}, ...
    {'Precision','Recall','F1'}, 'Final Decision Tree by class | held-out test');
exportgraphics(fig, fullfile(folder, 'stage4_test_class_metrics.png'), 'Resolution', 240);

clf(fig);
groups = {'Accuracy','Macro F1','Balanced accuracy','Class 0 recall','Class 1 recall'};
plotScores(axes(fig), [summaryScores(validation), validation.recall'; summaryScores(m), m.recall']', ...
    groups, {'Stage 3 validation','Stage 4 held-out test'}, 'Development tree vs final refit');
exportgraphics(fig, fullfile(folder, 'stage4_validation_vs_test.png'), 'Resolution', 240);

clf(fig);
plotScores(axes(fig), [summaryScores(m), m.recall'; summaryScores(e.baseline), e.baseline.recall']', ...
    groups, {'Final Decision Tree','Training majority baseline'}, 'Decision Tree vs majority baseline | held-out test');
exportgraphics(fig, fullfile(folder, 'stage4_tree_vs_baseline.png'), 'Resolution', 240);
end

function plotScores(ax, scores, groups, series, heading)
bars = bar(ax, 100*scores);
palette = [0.10 0.40 0.65; 0.73 0.32 0.11; 0.19 0.48 0.33];
for k = 1:numel(bars)
    bars(k).FaceColor = palette(k,:);
    for j = 1:size(scores,1)
        text(ax, bars(k).XEndPoints(j), bars(k).YEndPoints(j) + 1, ...
            sprintf('%.1f', 100*scores(j,k)), 'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end
xticks(ax, 1:numel(groups)); xticklabels(ax, groups);
ylim(ax, [0 108]);
yticks(ax, 0:20:100);
ylabel(ax, 'Score (%)');
title(ax, heading);
legend(ax, series, 'Location', 'southoutside', 'Orientation', 'horizontal');
grid(ax, 'on');
end
