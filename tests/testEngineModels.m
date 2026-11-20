function tests = testEngineModels
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root, 'src');
originalPath = path;
addpath(fullfile(src, 'preprocessing'), fullfile(src, 'models'), fullfile(src, 'evaluation'));
testCase.addTeardown(@() path(originalPath));
testCase.TestData.trainPath = fullfile(root, 'data', 'raw', 'train.csv');
end

function testFrozenSplitAndDevelopmentFit(testCase)
data = prepareEngineDevelopment(testCase.TestData.trainPath);
verifySize(testCase, data.XDevelopment, [12502 6]);
verifySize(testCase, data.XValidation, [3126 6]);
verifyEmpty(testCase, intersect(data.developmentIndices, data.validationIndices));
verifyEqual(testCase, sort([data.developmentIndices; data.validationIndices]), (1:15628)');
verifyEqual(testCase, data.parameters, fitEnginePreprocessing(data.train(data.developmentIndices,:)));
verifyEqual(testCase, data.XValidation, ...
    applyEnginePreprocessing(data.train(data.validationIndices,:), data.parameters));
verifyEqual(testCase, data.seed, 42);
end

function testTrainingWithoutTestCsvAndReproducibility(testCase)
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
source = fullfile(folder.Folder, 'train.csv');
copyfile(testCase.TestData.trainPath, source);
data = prepareEngineDevelopment(source);
% Exercise every candidate on a bounded subset for a fast repeatable test.
idx = [find(data.yDevelopment == 0, 120); find(data.yDevelopment == 1, 120)];
raw = data.train(data.developmentIndices(idx), :);
data.developmentIndices = data.developmentIndices(idx);
data.parameters = fitEnginePreprocessing(raw);
data.XDevelopment = applyEnginePreprocessing(raw, data.parameters);
data.yDevelopment = data.yDevelopment(idx);
idx = [find(data.yValidation == 0, 60); find(data.yValidation == 1, 60)];
data.validationIndices = data.validationIndices(idx);
data.XValidation = applyEnginePreprocessing(data.train(data.validationIndices,:), data.parameters);
data.yValidation = data.yValidation(idx);

before = rng;
benchmark = trainEngineCandidates(data);
verifyEqual(testCase, rng, before);
repeated = trainEngineCandidates(data);
verifyEqual(testCase, {benchmark.candidates.algorithm}, ...
    [repmat({'KNN'}, 1, 4), repmat({'Decision Tree'}, 1, 3), {'SVM','SVM'}]);
verifyEqual(testCase, benchmark.bestOverall, repeated.bestOverall);
verifyEqual(testCase, benchmark.bestPerAlgorithm, repeated.bestPerAlgorithm);
verifyEqual(testCase, [benchmark.candidates(1:4).hyperparameters].', ...
    [repeated.candidates(1:4).hyperparameters].');
for k = 1:4
    verifyEqual(testCase, benchmark.candidates(k).model.NumNeighbors, ...
        benchmark.candidates(k).hyperparameters.numNeighbors);
end
for k = 1:numel(benchmark.candidates)
    a = benchmark.candidates(k);
    b = repeated.candidates(k);
    verifySize(testCase, a.validationPredictions, [120 1]);
    verifyTrue(testCase, all(ismember(a.validationPredictions, [0 1])));
    verifyEqual(testCase, a.validationPredictions, b.validationPredictions);
    verifyEqual(testCase, a.validationMetrics.macroF1, b.validationMetrics.macroF1, 'AbsTol', 1e-12);
end

artifact = fullfile(folder.Folder, 'models.mat');
save(artifact, 'benchmark');
saved = load(artifact, 'benchmark');
saved = saved.benchmark;
verifyEqual(testCase, saved.featureNames, engineSchema);
verifyEqual(testCase, saved.preprocessing, data.parameters);
for c = saved.candidates
    verifyEqual(testCase, c.model.PredictorNames, engineSchema);
    verifyEqual(testCase, predict(c.model, data.XValidation), c.validationPredictions);
end
end
