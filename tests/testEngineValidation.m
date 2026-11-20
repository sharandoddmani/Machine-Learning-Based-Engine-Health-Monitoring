function tests = testEngineValidation
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
addpath(fullfile(root, 'src', 'preprocessing'), fullfile(root, 'src', 'evaluation'));
testCase.addTeardown(@() path(originalPath));
end

function testMetricsAndOrder(testCase)
actual = [1; 0; 1; 1; 0; 1; 1; 0; 1; 0];
prediction = [0; 0; 1; 1; 1; 1; 1; 0; 1; 0];
m = evaluateEngineValidation(actual, prediction);
verifyEqual(testCase, m.classOrder, [0 1]);
verifyEqual(testCase, m.confusionMatrix, [3 1; 1 5]);
verifyEqual(testCase, m.accuracy, 0.8, 'AbsTol', 1e-12);
verifyEqual(testCase, m.precision, [3/4; 5/6], 'AbsTol', 1e-12);
verifyEqual(testCase, m.recall, [3/4; 5/6], 'AbsTol', 1e-12);
verifyEqual(testCase, m.f1, [3/4; 5/6], 'AbsTol', 1e-12);
verifyEqual(testCase, m.macroF1, 19/24, 'AbsTol', 1e-12);
verifyEqual(testCase, m.balancedAccuracy, 19/24, 'AbsTol', 1e-12);

m = evaluateEngineValidation([0; 0; 1; 1; 1], [0; 1; 1; 1; 1]);
verifyEqual(testCase, m.confusionMatrix, [1 1; 0 3]);
verifyEqual(testCase, m.precision, [1; 3/4], 'AbsTol', 1e-12);
verifyEqual(testCase, m.recall, [1/2; 1], 'AbsTol', 1e-12);
verifyEqual(testCase, m.f1, [2/3; 6/7], 'AbsTol', 1e-12);
end

function testZeroDenominators(testCase)
m = evaluateEngineValidation([0; 0], [0; 0]);
verifyEqual(testCase, m.confusionMatrix, [2 0; 0 0]);
verifyEqual(testCase, m.precision, [1; 0]);
verifyEqual(testCase, m.recall, [1; 0]);
verifyEqual(testCase, m.f1, [1; 0]);
verifyEqual(testCase, m.macroF1, 0.5);
verifyEqual(testCase, m.balancedAccuracy, 0.5);
end

function testSelectionPriority(testCase)
scores = [0.6 0.95 0.95; 0.7 0.7 0.95; 0.7 0.8 0.7; 0.7 0.8 0.8; 0.7 0.8 0.8];
metrics = repmat(struct('macroF1', 0, 'balancedAccuracy', 0, 'accuracy', 0), 1, size(scores, 1));
for k = 1:size(scores, 1)
    metrics(k) = struct('macroF1', scores(k,1), ...
        'balancedAccuracy', scores(k,2), 'accuracy', scores(k,3));
end
for k = 1:4
    verifyEqual(testCase, selectEngineCandidate(metrics(1:k)), k);
end
verifyEqual(testCase, selectEngineCandidate(metrics), 4);
end


function testModelComparisonPlotLabels(testCase)
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
candidates = struct('algorithm', {'KNN','Decision Tree','SVM'}, ...
    'setting', {'k = 5','max splits = 30','gaussian'});
for k = 1:numel(candidates)
    candidates(k).hyperparameters = struct();
    candidates(k).validationMetrics = evaluateEngineValidation([0; 1; 1], [0; 0; 1]);
end
benchmark = struct('candidates', candidates, 'bestPerAlgorithm', 1:3, 'bestOverall', 1, ...
    'featureNames', {engineSchema}, 'developmentIndices', (1:4)', ...
    'validationIndices', (5:7)', 'seed', 42, 'matlabVersion', version, ...
    'toolboxVersion', struct('Version', 'fixture'));
report = fullfile(folder.Folder, 'report.txt');
writeEngineValidationOutputs(benchmark, report, folder.Folder);
figures = {'stage3_algorithm_comparison.png','stage3_confusion_matrices.png', ...
    'stage3_class_performance.png'};
verifyTrue(testCase, all(isfile(fullfile(folder.Folder, figures))));
end
