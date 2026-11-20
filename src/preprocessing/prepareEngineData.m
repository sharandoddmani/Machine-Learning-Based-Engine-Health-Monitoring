function prepared = prepareEngineData(rawDir)
% Fit before loading the publisher test split. Labels are returned separately.
prepared = prepareEngineDevelopment(fullfile(rawDir, 'train.csv'));
[test, prepared.yTest] = loadEngineSplit(fullfile(rawDir, 'test.csv'), 3907);
prepared.XTest = applyEnginePreprocessing(test, prepared.parameters);
end
