function tests = testProjectIntegration
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.root = fileparts(fileparts(mfilename('fullpath')));
end

function testRequiredProjectFiles(testCase)
root = testCase.TestData.root;
entries = {'run_stage1.m','run_stage2.m','run_stage3.m','run_stage4.m', ...
    'run_stage5.m','run_stage5_demo.m','run_stage6.m','run_stage6_smoke.m','run_stage7.m'};
verifyTrue(testCase, all(isfile(fullfile(root, entries))));
sources = {'src/inference/loadFinalEngineModel.m', 'src/inference/predictEngineCondition.m', ...
    'src/preprocessing/applyEnginePreprocessing.m', 'src/dashboard/createEngineDashboard.m'};
verifyTrue(testCase, all(isfile(fullfile(root, sources))));
end

function testPublicInferenceAndDashboardWithOnlySavedArtifact(testCase)
root = testCase.TestData.root;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
isolated = folder.Folder;
files = {'run_stage5.m','run_stage5_demo.m','run_stage6.m', ...
    'src/dashboard/createEngineDashboard.m','src/inference/loadFinalEngineModel.m', ...
    'src/inference/predictEngineCondition.m','src/preprocessing/engineSchema.m', ...
    'src/preprocessing/validateEngineFeatures.m','src/preprocessing/applyEnginePreprocessing.m', ...
    'data/processed/final_engine_model.mat'};
for k = 1:numel(files)
    destination = fullfile(isolated, files{k});
    parent = fileparts(destination);
    if ~isfolder(parent)
        mkdir(parent);
    end
    copyfile(fullfile(root, files{k}), destination);
end
relativeArtifact = 'data/processed/final_engine_model.mat';
originalArtifact = fullfile(root, relativeArtifact);
artifact = fullfile(isolated, relativeArtifact);
before = readArtifact(originalArtifact);
oldFolder = pwd;
oldPath = path;
restoreFolder = onCleanup(@() cd(oldFolder));
restorePath = onCleanup(@() path(oldPath));
cd(isolated);
% Prevent the fixture from falling back to the original checkout's functions.
folders = strsplit(oldPath, pathsep);
projectPaths = strcmpi(folders, root) | startsWith(folders, [root filesep], 'IgnoreCase', true);
path(strjoin(folders(~projectPaths), pathsep));
assertEqual(testCase, which('run_stage5_demo'), fullfile(isolated, 'run_stage5_demo.m'));
assertEqual(testCase, which('run_stage6'), fullfile(isolated, 'run_stage6.m'));
verifyFalse(testCase, isfolder(fullfile(isolated, 'data', 'raw')));

first = run_stage5_demo();
names = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
reading = [800, 3.3, 6.6, 2.3, 77.6, 78.4];
bundle = loadFinalEngineModel(artifact);
verifyEqual(testCase, bundle.featureNames, names);
verifyEqual(testCase, first.featureNames, names);
verifyEqual(testCase, first.rawReadings, reading);
verifyEqual(testCase, first.classLabels, [0 1]);
verifyEqual(testCase, first.predictedClass, 1);
verifyEqual(testCase, first.scores, [0.39908638 0.60091362], 'AbsTol', 5e-8);
p = bundle.preprocessing;
verifyEqual(testCase, first.standardizedReadings, (reading - p.mean) ./ p.scale);
verifyEqual(testCase, run_stage5(reading), first);
bad = reading;
bad(1) = NaN;
verifyError(testCase, @() run_stage5(bad), 'EngineInference:SensorValue');

app = run_stage6("off");
closeApp = onCleanup(@() app.Close());
verifyEqual(testCase, app.FeatureNames, names);
% Run both prediction and reset through the dashboard's shared callbacks.
for k = 1:numel(reading)
    app.Inputs(k).Value = sprintf('%.17g', reading(k));
end
app.Predict();
verifyEqual(testCase, app.PredictionLabel.Text, sprintf('Class %d', first.predictedClass));
verifyEqual(testCase, app.ScoreBars.YData(:), first.scores(:));
app.Reset();
verifyTrue(testCase, all(cellfun(@isempty, {app.Inputs.Value})));
verifyEqual(testCase, app.PredictionLabel.Text, 'No prediction');
verifyTrue(testCase, all(isnan(app.ScoreBars.YData)));
app.Close();
verifyFalse(testCase, isvalid(app.Figure));
verifyEqual(testCase, readArtifact(artifact), before);
verifyEqual(testCase, readArtifact(originalArtifact), before);
end

function bytes = readArtifact(path)
file = fopen(path, 'rb');
assert(file ~= -1, 'Could not open model artifact: %s.', path);
cleanup = onCleanup(@() fclose(file));
bytes = fread(file, Inf, '*uint8');
end
