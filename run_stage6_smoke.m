function run_stage6_smoke
% Exercise the same callbacks as the dashboard buttons using an invisible window.
try
    app = run_stage6("off");
    cleanup = onCleanup(@() app.Close());
    reading = [800, 3.3, 6.6, 2.3, 77.6, 78.4];
    root = fileparts(mfilename('fullpath'));
    bundle = loadFinalEngineModel(fullfile(root, 'data', 'processed', 'final_engine_model.mat'));
    expected = predictEngineCondition(bundle, reading);
    for k = 1:numel(app.Inputs)
        app.Inputs(k).Value = sprintf('%.17g', reading(k));
    end
    app.Predict();
    assert(strcmp(app.PredictionLabel.Text, sprintf('Class %d', expected.predictedClass)));
    assert(isequal(app.ScoreBars.YData(:), expected.scores(:)));
    expectedText = sprintf('Class 0: %.17g    |    Class 1: %.17g', expected.scores);
    assert(strcmp(app.ScoreLabel.Text, expectedText));
    app.Reset();
    assert(all(cellfun(@isempty, {app.Inputs.Value})));
    assert(strcmp(app.PredictionLabel.Text, 'No prediction'));
    assert(strcmp(app.ScoreLabel.Text, 'Scores unavailable'));
    assert(all(isnan(app.ScoreBars.YData)));
    app.Close();
    assert(~isvalid(app.Figure));
catch problem
    fprintf(2, 'Stage 6 smoke FAIL: %s\n', problem.message);
    rethrow(problem);
end
fprintf('Stage 6 smoke PASS: displayed Class %d, scores [%.8g %.8g], reset and close verified.\n', ...
    expected.predictedClass, expected.scores);
end
