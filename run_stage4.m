% Refit the approved tree and evaluate once on the publisher's held-out split.
stage4(fileparts(mfilename('fullpath')));

function stage4(root)
src = fullfile(root, 'src');
addpath(fullfile(src, 'preprocessing'), fullfile(src, 'models'), fullfile(src, 'evaluation'));
raw = fullfile(root, 'data', 'raw');
bundle = trainFinalEngineModel(fullfile(raw, 'train.csv'));
[bundle.finalEvaluation, predicted, rawTest] = evaluateFinalEngineModel( ...
    bundle, fullfile(raw, 'test.csv'));
reportDir = fullfile(root, 'results', 'reports');
figureDir = fullfile(root, 'results', 'figures');
processedDir = fullfile(root, 'data', 'processed');
for folder = {reportDir, figureDir, processedDir}
    if ~isfolder(folder{1}), mkdir(folder{1}); end
end
path = fullfile(processedDir, 'final_engine_model.mat');
save(path, 'bundle');
reloaded = load(path, 'bundle');
reloadedTest = applyEnginePreprocessing(rawTest, reloaded.bundle.preprocessing);
assert(isequal(predict(reloaded.bundle.model, reloadedTest), predicted), ...
    'EngineModels:ReloadMismatch', 'Reloaded model predictions differ from the final test predictions.');
writeFinalEngineEvaluation(bundle, fullfile(reportDir, 'final_model_evaluation.txt'), figureDir);
metrics = bundle.finalEvaluation.tree;
fprintf('Stage 4 held-out test: accuracy %.6f, macro F1 %.6f, balanced accuracy %.6f.\n', ...
    metrics.accuracy, metrics.macroF1, metrics.balancedAccuracy);
fprintf('Saved model reloaded with identical predictions for all %d test rows.\n', numel(predicted));
end
