function tests = testEngineDashboard
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root, 'src');
originalPath = path;
addpath(root, fullfile(src, 'dashboard'), fullfile(src, 'inference'), fullfile(src, 'preprocessing'));
testCase.addTeardown(@() path(originalPath));
testCase.TestData.modelPath = fullfile(root, 'data', 'processed', 'final_engine_model.mat');
testCase.TestData.reading = [800, 3.3, 6.6, 2.3, 77.6, 78.4];
end

function testDashboardCreationAndClose(testCase)
app = run_stage6("off");
testCase.addTeardown(@() app.Close());
verifyTrue(testCase, isvalid(app.Figure));
verifyEqual(testCase, char(app.Figure.Visible), 'off');
verifyNumElements(testCase, app.Inputs, 6);
verifyEqual(testCase, app.FeatureNames, engineSchema);
verifyEqual(testCase, {app.Inputs.Tag}, engineSchema);
verifyEqual(testCase, app.PredictionLabel.Text, 'No prediction');
close(app.Figure);
verifyFalse(testCase, isvalid(app.Figure));
end

function testDisplayAndRepeatWithoutModelFile(testCase)
d = testCase.TestData;
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
source = fullfile(folder.Folder, 'model.mat');
copyfile(d.modelPath, source);
bundle = loadFinalEngineModel(source);
app = createEngineDashboard(source, "off");
testCase.addTeardown(@() app.Close());
% Removing access to the local copy also rules out reloading on Predict or Reset.
movefile(source, fullfile(folder.Folder, 'stored.mat'));
reading = d.reading;
setReading(app, reading);
app.Predict();
checkDisplay(testCase, app, predictEngineCondition(bundle, reading));
reset = findobj(app.Figure, 'Tag', 'EngineDashboardReset');
verifyNumElements(testCase, reset, 1);
verifyEqual(testCase, char(reset.Enable), 'on');
feval(reset.ButtonPushedFcn, reset, []);
verifyTrue(testCase, all(cellfun(@isempty, {app.Inputs.Value})));
verifyCleared(testCase, app);
verifyEmpty(testCase, app.ScoreBars.Parent.YTick);
reading(1) = 1200;
setReading(app, reading);
app.Predict();
checkDisplay(testCase, app, predictEngineCondition(bundle, reading));
verifyFalse(testCase, isfile(source));
verifyFalse(testCase, any(isfile(fullfile(folder.Folder, {'train.csv','test.csv'}))));
end

function testInvalidInputClearsResultAndReset(testCase)
app = run_stage6("off");
testCase.addTeardown(@() app.Close());
badValues = {'','NaN','Inf','1+2i','words','1,2','1e999'};
for k = 1:numel(badValues)
    setReading(app, testCase.TestData.reading);
    app.Predict();
    verifyTrue(testCase, startsWith(app.StatusLabel.Text, 'Prediction complete.'));
    app.Inputs(3).Value = badValues{k};
    app.Predict();
    verifyTrue(testCase, contains(app.StatusLabel.Text, 'Fuel pressure: enter one finite real number'));
    verifyCleared(testCase, app);
end
app.Reset();
verifyTrue(testCase, all(cellfun(@isempty, {app.Inputs.Value})));
verifyEqual(testCase, app.StatusLabel.Text, 'Enter the sensor readings, then select Predict.');
verifyCleared(testCase, app);
end

function testMissingModelReportsStage4(testCase)
folder = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(folder);
path = fullfile(folder.Folder, 'missing.mat');
verifyError(testCase, @() createEngineDashboard(path, "off"), 'EngineInference:MissingModel');
end

function setReading(app, reading)
for k = 1:numel(reading)
    app.Inputs(k).Value = sprintf('%.17g', reading(k));
end
end

function checkDisplay(testCase, app, expected)
verifyEqual(testCase, app.PredictionLabel.Text, sprintf('Class %d', expected.predictedClass));
verifyEqual(testCase, app.ScoreBars.YData(:), expected.scores(:));
verifyEqual(testCase, app.ScoreLabel.Text, ...
    sprintf('Class 0: %.17g    |    Class 1: %.17g', expected.scores));
verifyEqual(testCase, {app.ReadingLabels.Text}, ...
    arrayfun(@(x) sprintf('%.10g', x), expected.rawReadings, 'UniformOutput', false));
end

function verifyCleared(testCase, app)
verifyEqual(testCase, app.PredictionLabel.Text, 'No prediction');
verifyEqual(testCase, app.ScoreLabel.Text, 'Scores unavailable');
verifyTrue(testCase, all(isnan(app.ScoreBars.YData)));
verifyEqual(testCase, {app.ReadingLabels.Text}, repmat({'—'}, 1, 6));
end
