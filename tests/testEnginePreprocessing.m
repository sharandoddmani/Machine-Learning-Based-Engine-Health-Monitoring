function tests = testEnginePreprocessing
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
addpath(fullfile(root, 'src', 'preprocessing'));
testCase.addTeardown(@() path(originalPath));
raw = fullfile(root, 'data', 'raw');
testCase.TestData.raw = raw;
testCase.TestData.data = prepareEngineData(raw);
end

function testSchemaAndExtraction(testCase)
d = testCase.TestData.data;
names = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
verifyEqual(testCase, engineSchema, names);
verifySize(testCase, d.train, [15628 6]);
verifySize(testCase, d.XTest, [3907 6]);
for split = {'train','test'}
    original = readtable(fullfile(testCase.TestData.raw, [split{1} '.csv']));
    [X, y] = loadEngineSplit(fullfile(testCase.TestData.raw, [split{1} '.csv']), height(original));
    verifyEqual(testCase, X, original{:, names});
    verifyEqual(testCase, y, original.engine_condition);
    verifyEqual(testCase, unique(y), [0; 1]);
end
end

function testStratification(testCase)
d = testCase.TestData.data;
before = rng;
[a, b] = splitEngineTraining(d.yTrain);
verifyEqual(testCase, rng, before);
verifyEqual(testCase, a, d.developmentIndices);
verifyEqual(testCase, b, d.validationIndices);
verifyEmpty(testCase, intersect(a,b));
verifyEqual(testCase, sort([a;b]), (1:15628)');
verifyEqual(testCase, [nnz(d.yDevelopment == 0), nnz(d.yDevelopment == 1)], [4619 7883]);
verifyEqual(testCase, [nnz(d.yValidation == 0), nnz(d.yValidation == 1)], [1155 1971]);
end

function testFittedStatisticsAndFiniteOutputs(testCase)
d = testCase.TestData.data;
rawDevelopment = d.train(d.developmentIndices, :);
verifyEqual(testCase, d.parameters.rowCount, 12502);
verifyEqual(testCase, d.parameters.mean, mean(rawDevelopment, 1));
verifyEqual(testCase, d.parameters.std, std(rawDevelopment, 0, 1));
verifyEqual(testCase, mean(d.XDevelopment, 1), zeros(1,6), 'AbsTol', 1e-10);
verifyEqual(testCase, std(d.XDevelopment, 0, 1), ones(1,6), 'AbsTol', 1e-10);
verifySize(testCase, d.XDevelopment, [12502 6]);
verifySize(testCase, d.XValidation, [3126 6]);
verifyTrue(testCase, all(isfinite([d.XDevelopment; d.XValidation; d.XTest]), 'all'));
verifyEqual(testCase, d.XValidation, ...
    (d.train(d.validationIndices, :) - d.parameters.mean) ./ d.parameters.scale);
end

function testTestDataCannotAffectFit(testCase)
d = testCase.TestData.data;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
copyfile(fullfile(testCase.TestData.raw, 'train.csv'), folder.Folder);
test = readtable(fullfile(testCase.TestData.raw, 'test.csv'));
test.engine_rpm = test.engine_rpm + 10000;
test.engine_condition = 1 - test.engine_condition;
writetable(test, fullfile(folder.Folder, 'test.csv'));
changed = prepareEngineData(folder.Folder);
verifyEqual(testCase, changed.parameters, d.parameters);
verifyEqual(testCase, changed.developmentIndices, d.developmentIndices);
verifyEqual(testCase, changed.XValidation, d.XValidation);
verifyNotEqual(testCase, changed.XTest(:,1), d.XTest(:,1));
end
