function tests = testEnginePreprocessingUnits
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
addpath(fullfile(root, 'src', 'preprocessing'));
testCase.addTeardown(@() path(originalPath));
end

function testConstantAndNewReading(testCase)
training = [1 2 3 4 5 0.1; 3 4 5 6 7 0.1];
p = fitEnginePreprocessing(training);
verifyEqual(testCase, p.std(6), 0);
verifyEqual(testCase, p.scale(6), 1);
verifyEqual(testCase, applyEnginePreprocessing(training, p), ...
    [-ones(1,5)/sqrt(2), 0; ones(1,5)/sqrt(2), 0], 'AbsTol', 1e-12);
verifyEqual(testCase, applyEnginePreprocessing([4 5 6 7 8 1.1], p), ...
    [sqrt(2)*ones(1,5), 1], 'AbsTol', 1e-12);
end

function testInvalidInputs(testCase)
p = fitEnginePreprocessing(ones(2,6));
verifyError(testCase, @() applyEnginePreprocessing(zeros(1,7),p), 'EngineData:Features');
verifyError(testCase, @() fitEnginePreprocessing(["bad","2","3","4","5","6"]), 'EngineData:Features');
verifyError(testCase, @() fitEnginePreprocessing([NaN, zeros(1,5)]), 'EngineData:Nonfinite');
verifyError(testCase, @() applyEnginePreprocessing([zeros(1,5), Inf],p), 'EngineData:Nonfinite');
verifyError(testCase, @() splitEngineTraining([0; 1; 2]), 'EngineData:Labels');
end

function testMalformedCsv(testCase)
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
file = fullfile(folder.Folder, 'malformed.csv');
[names, target] = engineSchema;
writelines([string(strjoin([names, {target}], ',')); ...
    "1,2,3,4,5,6,0"; "bad,2,3,4,5,6,1"], file);
verifyError(testCase, @() loadEngineSplit(file,2), 'EngineData:Import');
writelines(["unknown,engine_condition"; "1,0"; "2,1"], file);
verifyError(testCase, @() loadEngineSplit(file,2), 'EngineData:Schema');
end
