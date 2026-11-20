function tests = testFinalEngineEvaluation
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root, 'src');
originalPath = path;
addpath(fullfile(src, 'preprocessing'), fullfile(src, 'models'), fullfile(src, 'evaluation'));
testCase.addTeardown(@() path(originalPath));
raw = fullfile(root, 'data', 'raw');
testCase.TestData.trainPath = fullfile(raw, 'train.csv');
testCase.TestData.testPath = fullfile(raw, 'test.csv');
bundle = trainFinalEngineModel(testCase.TestData.trainPath);
[bundle.finalEvaluation, predictions] = evaluateFinalEngineModel(bundle, testCase.TestData.testPath);
testCase.TestData.bundle = bundle;
testCase.TestData.predictions = predictions;
end

function testOriginalDimensionsAndTrainingFit(testCase)
d = testCase.TestData;
[X, y] = loadEngineSplit(d.trainPath, 15628);
[test, actual] = loadEngineSplit(d.testPath, 3907);
verifySize(testCase, X, [15628 6]);
verifySize(testCase, y, [15628 1]);
verifySize(testCase, test, [3907 6]);
verifySize(testCase, actual, [3907 1]);
names = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
verifyEqual(testCase, d.bundle.featureNames, names);
verifyEqual(testCase, d.bundle.model.PredictorNames, names);
verifyEqual(testCase, d.bundle.model.ClassNames(:)', [0 1]);
verifyEqual(testCase, d.bundle.trainingRows, 15628);
p = d.bundle.preprocessing;
verifyEqual(testCase, p.rowCount, 15628);
verifyEqual(testCase, p.mean, mean(X, 1));
verifyEqual(testCase, p.std, std(X, 0, 1));
verifyEqual(testCase, p.scale, p.std);
verifyEqual(testCase, d.bundle.hyperparameters, struct('MaxNumSplits', 30, ...
    'SplitCriterion', 'gdi', 'MinLeafSize', 1, 'Prior', 'empirical'));
verifyLessThanOrEqual(testCase, nnz(d.bundle.model.IsBranchNode), 30);
verifyEqual(testCase, d.bundle.model.Prior(:)', [nnz(y == 0), nnz(y == 1)]/numel(y), 'AbsTol', 1e-12);
end

function testHoldoutPredictionsAndMetrics(testCase)
d = testCase.TestData;
[~, actual] = loadEngineSplit(d.testPath, 3907);
m = d.bundle.finalEvaluation.tree;
p = d.predictions;
verifySize(testCase, p, [3907 1]);
verifyTrue(testCase, all(ismember(p, [0 1])));
verifyEqual(testCase, m.classOrder, [0 1]);
expected = [nnz(actual == 0 & p == 0), nnz(actual == 0 & p == 1); ...
    nnz(actual == 1 & p == 0), nnz(actual == 1 & p == 1)];
verifyEqual(testCase, m.confusionMatrix, expected);
verifyEqual(testCase, m.correctCount, nnz(actual == p));
verifyEqual(testCase, m.incorrectCount, nnz(actual ~= p));
verifyEqual(testCase, m.accuracy, mean(actual == p));
verifyEqual(testCase, m.macroPrecision, mean(m.precision));
verifyEqual(testCase, m.macroRecall, mean(m.recall));
verifyEqual(testCase, m.balancedAccuracy, m.macroRecall);
verifyEqual(testCase, m.macroF1, mean(m.f1));

baseline = d.bundle.finalEvaluation.baseline;
verifyEqual(testCase, d.bundle.trainingClassCounts, [5774 9854]);
verifyEqual(testCase, d.bundle.majorityClass, 1);
verifyEqual(testCase, baseline.confusionMatrix, [0 1444; 0 2463]);
accuracy = 2463/3907;
verifyEqual(testCase, baseline.accuracy, accuracy);
verifyEqual(testCase, baseline.precision, [0; accuracy]);
verifyEqual(testCase, baseline.recall, [0; 1]);
verifyEqual(testCase, baseline.f1, [0; 2*2463/(3907+2463)], 'AbsTol', 1e-12);
verifyEqual(testCase, baseline.balancedAccuracy, 0.5);
for candidate = [m baseline]
    verifyTrue(testCase, all(isfinite([candidate.accuracy, candidate.macroPrecision, ...
        candidate.macroRecall, candidate.macroF1, candidate.balancedAccuracy, ...
        candidate.precision', candidate.recall', candidate.f1'])));
end
end

function testFitWithoutTestAndReproducibleEvaluation(testCase)
d = testCase.TestData;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
train = fullfile(folder.Folder, 'train.csv');
copyfile(d.trainPath, train);
before = rng;
repeat = trainFinalEngineModel(train);
verifyEqual(testCase, rng, before);
verifyEqual(testCase, repeat.hyperparameters, d.bundle.hyperparameters);
verifyEqual(testCase, repeat.preprocessing, d.bundle.preprocessing);
[e, p] = evaluateFinalEngineModel(repeat, d.testPath);
verifyEqual(testCase, e, d.bundle.finalEvaluation);
verifyEqual(testCase, p, d.predictions);
changedTest = readtable(d.testPath);
changedTest.engine_condition = 1 - changedTest.engine_condition;
changedPath = fullfile(folder.Folder, 'test.csv');
writetable(changedTest, changedPath);
[changed, changedPredictions] = evaluateFinalEngineModel(repeat, changedPath);
verifyEqual(testCase, changedPredictions, p);
verifyEqual(testCase, changed.tree.confusionMatrix, flipud(e.tree.confusionMatrix));
verifyEqual(testCase, changed.baseline.confusionMatrix, flipud(e.baseline.confusionMatrix));
end

function testBundleRoundTripAndReport(testCase)
d = testCase.TestData;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
artifact = fullfile(folder.Folder, 'final_engine_model.mat');
bundle = d.bundle;
save(artifact, 'bundle');
restored = load(artifact, 'bundle');
verifyEqual(testCase, restored.bundle.featureNames, engineSchema);
verifyEqual(testCase, restored.bundle.preprocessing, bundle.preprocessing);
verifyEqual(testCase, restored.bundle.finalEvaluation, bundle.finalEvaluation);
[e, p] = evaluateFinalEngineModel(restored.bundle, d.testPath);
verifyEqual(testCase, p, d.predictions);
verifyEqual(testCase, e, bundle.finalEvaluation);
report = fullfile(folder.Folder, 'final_model_evaluation.txt');
writeFinalEngineEvaluation(restored.bundle, report, folder.Folder);
verifyTrue(testCase, contains(fileread(report), sprintf('Accuracy: %.6f', e.tree.accuracy)));
files = {'stage4_test_confusion_matrix.png','stage4_test_class_metrics.png', ...
    'stage4_validation_vs_test.png','stage4_tree_vs_baseline.png'};
verifyTrue(testCase, all(isfile(fullfile(folder.Folder, files))));
end
