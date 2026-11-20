% Rebuild Stage 2 outputs from the original publisher CSVs.
stage2(fileparts(mfilename('fullpath')));

function stage2(root)
addpath(fullfile(root, 'src', 'preprocessing'));
prepared = prepareEngineData(fullfile(root, 'data', 'raw'));
reportDir = fullfile(root, 'results', 'reports');
figureDir = fullfile(root, 'results', 'figures');
processedDir = fullfile(root, 'data', 'processed');
for folder = {reportDir, figureDir, processedDir}
    if ~isfolder(folder{1}), mkdir(folder{1}); end
end
analyzeEngineFeatures(prepared.train, prepared.yTrain, figureDir, ...
    fullfile(reportDir, 'feature_analysis.txt'));
writeEnginePreprocessingReport(prepared, fullfile(reportDir, 'preprocessing_report.txt'), ...
    fullfile(root, 'docs', 'dataset_provenance.txt'));
prepared = rmfield(prepared, {'train','yTrain','XTest','yTest'});
save(fullfile(processedDir, 'stage2_preprocessing.mat'), '-struct', 'prepared');
fprintf('Stage 2 completed with %d development-training and %d validation records.\n', ...
    numel(prepared.developmentIndices), numel(prepared.validationIndices));
end
