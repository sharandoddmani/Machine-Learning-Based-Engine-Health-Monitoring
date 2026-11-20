% Train and compare the Stage 3 classifiers on the frozen Stage 2 split.
stage3(fileparts(mfilename('fullpath')));

function stage3(root)
src = fullfile(root, 'src');
addpath(fullfile(src, 'preprocessing'), fullfile(src, 'models'), fullfile(src, 'evaluation'));
requireEngineModelToolbox;
data = prepareEngineDevelopment(fullfile(root, 'data', 'raw', 'train.csv'));
benchmark = trainEngineCandidates(data);
reportDir = fullfile(root, 'results', 'reports');
figureDir = fullfile(root, 'results', 'figures');
processedDir = fullfile(root, 'data', 'processed');
for folder = {reportDir, figureDir, processedDir}
    if ~isfolder(folder{1}), mkdir(folder{1}); end
end
save(fullfile(processedDir, 'stage3_models.mat'), 'benchmark');
writeEngineValidationOutputs(benchmark, fullfile(reportDir, 'model_training_report.txt'), figureDir);
winner = benchmark.candidates(benchmark.bestOverall);
fprintf('Stage 3 selected %s (%s), validation macro F1 %.6f.\n', ...
    winner.algorithm, winner.setting, winner.validationMetrics.macroF1);
end
