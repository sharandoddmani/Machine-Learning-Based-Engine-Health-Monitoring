function tests = testEngineInference
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
addpath(fullfile(root, 'src', 'inference'), fullfile(root, 'src', 'preprocessing'));
testCase.addTeardown(@() path(originalPath));
testCase.TestData.modelPath = fullfile(root, 'data', 'processed', 'final_engine_model.mat');
testCase.TestData.bundle = loadFinalEngineModel(testCase.TestData.modelPath);
testCase.TestData.reading = [800, 3.3, 6.6, 2.3, 77.6, 78.4];
end

function testSavedModelAndNumericPrediction(testCase)
d = testCase.TestData;
names = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
verifyEqual(testCase, d.bundle.featureNames, names);
result = predictEngineCondition(d.bundle, d.reading);
standardized = (d.reading - d.bundle.preprocessing.mean) ./ d.bundle.preprocessing.scale;
[expected, scores] = predict(d.bundle.model, standardized);
verifyEqual(testCase, result.rawReadings, d.reading);
verifyEqual(testCase, result.featureNames, names);
verifyEqual(testCase, result.standardizedReadings, standardized);
verifyEqual(testCase, result.classLabels, [0 1]);
verifyTrue(testCase, ismember(result.predictedClass, [0 1]));
verifyEqual(testCase, result.predictedClass, expected);
verifyEqual(testCase, result.scores, scores);
verifySize(testCase, result.scores, [1 2]);
verifyEqual(testCase, result.algorithm, 'Decision Tree');
verifyEqual(testCase, result.hyperparameters.MaxNumSplits, 30);
verifyEqual(testCase, result.trainingRows, 15628);
end

function testEquivalentNamedFormats(testCase)
d = testCase.TestData;
names = d.bundle.featureNames;
order = [6 2 4 1 5 3];
named = array2table(d.reading(order), 'VariableNames', names(order));
expected = predictEngineCondition(d.bundle, d.reading);
verifyEqual(testCase, predictEngineCondition(d.bundle, named), expected);
verifyEqual(testCase, predictEngineCondition(d.bundle, table2struct(named)), expected);
end

function testMissingExtraAndMalformedNamedFeatures(testCase)
d = testCase.TestData;
named = array2table(d.reading, 'VariableNames', d.bundle.featureNames);
verifyError(testCase, @() predictEngineCondition(d.bundle, named(:,1:5)), 'EngineInference:SensorNames');
verifyError(testCase, @() predictEngineCondition(d.bundle, rmfield(table2struct(named), 'engine_rpm')), ...
    'EngineInference:SensorNames');
extra = table2struct(named);
extra.unknown = 1;
verifyError(testCase, @() predictEngineCondition(d.bundle, extra), 'EngineInference:SensorNames');
verifyError(testCase, @() predictEngineCondition(d.bundle, named([1 1],:)), 'EngineInference:ReadingShape');
named.engine_rpm = "800";
verifyError(testCase, @() predictEngineCondition(d.bundle, named), 'EngineInference:SensorValue');
extra = table2struct(named);
extra.engine_rpm = [800 801];
verifyError(testCase, @() predictEngineCondition(d.bundle, extra), 'EngineInference:SensorValue');
end

function testMalformedNumericReadings(testCase)
d = testCase.TestData;
for bad = [NaN, Inf, 800+1i]
    x = d.reading;
    x(1) = bad;
    verifyError(testCase, @() predictEngineCondition(d.bundle, x), 'EngineInference:SensorValue');
end
for bad = {d.reading(1:5), d.reading', [], "800", num2cell(d.reading), [d.reading; d.reading]}
    verifyError(testCase, @() predictEngineCondition(d.bundle, bad{1}), 'EngineInference:ReadingShape');
end
end

function testMissingCorruptAndIncompatibleBundles(testCase)
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
artifact = fullfile(folder.Folder, 'model.mat');
verifyError(testCase, @() loadFinalEngineModel(artifact), 'EngineInference:MissingModel');
writelines("Invalid MAT contents", artifact);
verifyError(testCase, @() loadFinalEngineModel(artifact), 'EngineInference:UnreadableModel');
bundle = testCase.TestData.bundle;
badBundles = {rmfield(bundle, 'model'), bundle, bundle, bundle};
badBundles{2}.model = [];
badBundles{3}.featureNames = fliplr(bundle.featureNames);
badBundles{4}.classLabels = [1 0];
ids = {'InvalidBundle','InvalidTree','FeatureOrder','ClassOrder'};
for k = 1:numel(ids)
    bundle = badBundles{k};
    save(artifact, 'bundle');
    verifyError(testCase, @() loadFinalEngineModel(artifact), ['EngineInference:' ids{k}]);
end
for badScale = {0, -1, NaN, Inf}
    bundle = testCase.TestData.bundle;
    bundle.preprocessing.scale(1) = badScale{1};
    save(artifact, 'bundle');
    verifyError(testCase, @() loadFinalEngineModel(artifact), 'EngineInference:InvalidPreprocessing');
end
bundle = testCase.TestData.bundle;
bundle.preprocessing.mean = bundle.preprocessing.mean';
save(artifact, 'bundle');
verifyError(testCase, @() loadFinalEngineModel(artifact), 'EngineInference:InvalidPreprocessing');
end

function testArtifactOnlyInferenceIsRepeatableAndReadOnly(testCase)
d = testCase.TestData;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
artifact = fullfile(folder.Folder, 'final_engine_model.mat');
copyfile(d.modelPath, artifact);
before = artifactBytes(artifact);
originalFolder = pwd;
testCase.addTeardown(@() cd(originalFolder));
cd(folder.Folder);
verifyFalse(testCase, any(isfile({'train.csv','test.csv'})));
bundle = loadFinalEngineModel('final_engine_model.mat');
result = predictEngineCondition(bundle, d.reading);
verifyEqual(testCase, predictEngineCondition(bundle, d.reading), result);
verifyEqual(testCase, artifactBytes(artifact), before);
verifyEqual(testCase, artifactBytes(d.modelPath), before);
end

function bytes = artifactBytes(path)
file = fopen(path, 'rb');
assert(file ~= -1, 'Could not open fixture artifact.');
cleanup = onCleanup(@() fclose(file));
bytes = fread(file, Inf, '*uint8');
end
