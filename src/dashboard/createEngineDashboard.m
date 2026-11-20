function app = createEngineDashboard(modelPath, visibility)
% Create the dashboard. Pass "off" for programmatic verification.
% Set app.Inputs(k).Value, call app.Predict() or app.Reset(), and inspect
% the returned UI handles. app.Close() disposes of the dashboard.
arguments
    modelPath (1,1) string
    visibility (1,1) string {mustBeMember(visibility, ["on","off"])} = "on"
end

try
    bundle = loadFinalEngineModel(modelPath);
catch problem
    if startsWith(problem.identifier, 'EngineInference:') && ...
            ~any(strcmp(problem.identifier, {'EngineInference:MissingModel','EngineInference:Toolbox'}))
        error(problem.identifier, '%s Run Stage 4 separately to regenerate the final model.', problem.message);
    end
    rethrow(problem);
end
names = bundle.featureNames;
displayNames = {'Engine speed','Lub oil pressure','Fuel pressure', ...
    'Coolant pressure','Lub oil temperature','Coolant temperature'};
ink = [0.10 0.17 0.26];
muted = [0.31 0.38 0.47];
accent = [0.16 0.35 0.60];
surface = [0.95 0.97 0.99];
white = [1 1 1];
inputFill = [0.97 0.98 1.00];
secondaryFill = [0.88 0.92 0.97];
gridColor = [0.80 0.85 0.91];

fig = uifigure('Name', 'Engine Health Monitoring', 'Visible', 'off', ...
    'Position', [70 80 1050 635], 'Color', surface, 'AutoResizeChildren', 'off');
root = uigridlayout(fig, [4 2], 'RowHeight', {36, 27, '1x', 40}, ...
    'ColumnWidth', {320, '1x'}, 'Padding', [18 12 18 12], ...
    'RowSpacing', 7, 'ColumnSpacing', 14, 'BackgroundColor', surface);
fig.SizeChangedFcn = @enforceMinimumSize;
titleLabel = uilabel(root, 'Text', 'Engine Health Monitoring', 'FontSize', 27, ...
    'FontWeight', 'bold', 'FontColor', ink);
titleLabel.Layout.Row = 1;
titleLabel.Layout.Column = [1 2];
subtitle = uilabel(root, 'Text', 'Manual sensor input | Academic classification benchmark', ...
    'FontSize', 13, 'FontColor', muted);
subtitle.Layout.Row = 2;
subtitle.Layout.Column = [1 2];

controls = uipanel(root, 'Title', 'Sensor inputs', 'BackgroundColor', white, ...
    'ForegroundColor', ink, 'FontSize', 13, 'FontWeight', 'bold');
controls.Layout.Row = 3;
controls.Layout.Column = 1;
form = uigridlayout(controls, [8 2], 'RowHeight', {25, 35, 35, 35, 35, 35, 35, 38}, ...
    'ColumnWidth', {'1x', '1x'}, 'Padding', [12 10 12 10], 'RowSpacing', 10, ...
    'BackgroundColor', white);
hint = uilabel(form, 'Text', 'Enter six finite numbers.', 'FontColor', muted);
hint.Layout.Row = 1;
hint.Layout.Column = [1 2];
inputs = gobjects(1, numel(names));
for k = 1:numel(names)
    label = uilabel(form, 'Text', displayNames{k}, 'Tooltip', names{k}, 'FontColor', ink);
    label.Layout.Row = k + 1;
    label.Layout.Column = 1;
    inputs(k) = uieditfield(form, 'text', 'Tag', names{k}, 'Tooltip', names{k}, ...
        'FontSize', 13, 'FontColor', ink, 'BackgroundColor', inputFill);
    inputs(k).Layout.Row = k + 1;
    inputs(k).Layout.Column = 2;
end
predictButton = uibutton(form, 'Text', 'Predict', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', accent, 'FontColor', white, 'ButtonPushedFcn', @(~,~) onPredict());
predictButton.Layout.Row = 8;
predictButton.Layout.Column = 1;
resetButton = uibutton(form, 'Text', 'Reset', 'Tag', 'EngineDashboardReset', ...
    'FontSize', 13, 'FontWeight', 'bold', 'BackgroundColor', secondaryFill, ...
    'FontColor', ink, 'Enable', 'on', ...
    'ButtonPushedFcn', @(~,~) onReset());
resetButton.Layout.Row = 8;
resetButton.Layout.Column = 2;

outputs = uigridlayout(root, [3 1], 'RowHeight', {119, 145, '1x'}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 9, 'BackgroundColor', surface);
outputs.Layout.Row = 3;
outputs.Layout.Column = 2;
resultPanel = uipanel(outputs, 'Title', 'Prediction', 'BackgroundColor', white, ...
    'ForegroundColor', ink, 'FontSize', 13, 'FontWeight', 'bold');
resultPanel.Layout.Row = 1;
resultGrid = uigridlayout(resultPanel, [3 2], 'RowHeight', {32, 21, 29}, ...
    'ColumnWidth', {'1x', '1x'}, 'RowSpacing', 1, 'Padding', [12 3 12 2], ...
    'BackgroundColor', white);
prediction = uilabel(resultGrid, 'FontSize', 21, 'FontWeight', 'bold', 'FontColor', ink);
prediction.Layout.Row = 1;
prediction.Layout.Column = 1;
model = uilabel(resultGrid, 'Text', ['Model: ' bundle.algorithm], 'FontColor', muted, ...
    'HorizontalAlignment', 'right');
model.Layout.Row = 1;
model.Layout.Column = 2;
scoreText = uilabel(resultGrid, 'FontColor', ink);
scoreText.Layout.Row = 2;
scoreText.Layout.Column = [1 2];
limits = uilabel(resultGrid, 'Text', 'Class meanings are unverified. Scores are uncalibrated.', ...
    'FontColor', muted, 'WordWrap', 'on');
limits.Layout.Row = 3;
limits.Layout.Column = [1 2];

readingPanel = uipanel(outputs, 'Title', 'Sensor readings | raw values', 'BackgroundColor', white, ...
    'ForegroundColor', ink, 'FontSize', 13, 'FontWeight', 'bold');
readingPanel.Layout.Row = 2;
readingGrid = uigridlayout(readingPanel, [2 3], 'Padding', [8 6 8 6], ...
    'RowSpacing', 5, 'ColumnSpacing', 6, 'BackgroundColor', white);
values = gobjects(1, numel(names));
for k = 1:numel(names)
    tile = uigridlayout(readingGrid, [2 1], 'RowHeight', {18, '1x'}, ...
        'Padding', [7 3 7 3], 'RowSpacing', 0, 'BackgroundColor', surface);
    tile.Layout.Row = ceil(k/3);
    tile.Layout.Column = mod(k-1, 3) + 1;
    uilabel(tile, 'Text', displayNames{k}, 'FontColor', muted, 'FontSize', 11);
    values(k) = uilabel(tile, 'FontSize', 16, 'FontWeight', 'bold', 'FontColor', ink);
end

ax = uiaxes(outputs);
ax.Layout.Row = 3;
bars = bar(ax, 1:2, [NaN NaN], 0.52, 'FaceColor', accent, 'EdgeColor', 'none');
set(ax, 'Color', white, 'XColor', ink, 'YColor', ink, 'GridColor', gridColor, ...
    'GridAlpha', 0.7, 'FontSize', 13);
xticks(ax, 1:2);
xticklabels(ax, {'Class 0','Class 1'});
xlim(ax, [0.5 2.5]);
title(ax, 'Uncalibrated Classification Scores', 'Color', ink, 'FontSize', 15, 'FontWeight', 'bold');
ylabel(ax, 'Model score', 'Color', ink, 'FontSize', 13);
scorePlaceholder = text(ax, 0.5, 0.55, 'Scores appear after a successful prediction.', ...
    'Units', 'normalized', 'HorizontalAlignment', 'center', 'Color', muted, 'FontSize', 13);

status = uilabel(root, 'FontSize', 13, 'WordWrap', 'on', 'FontColor', muted);
status.Layout.Row = 4;
status.Layout.Column = [1 2];
fig.CloseRequestFcn = @(~,~) closeDashboard();
onReset();
fig.Visible = visibility;

app = struct('Figure', fig, 'FeatureNames', {names}, 'Inputs', inputs, ...
    'PredictionLabel', prediction, 'ScoreLabel', scoreText, 'ReadingLabels', values, ...
    'ScoreBars', bars, 'StatusLabel', status, 'Predict', @onPredict, ...
    'Reset', @onReset, 'Close', @closeDashboard);

    function onPredict()
        clearResults();
        try
            reading = readInputs(inputs, displayNames);
            result = predictEngineCondition(bundle, reading);
        catch problem
            if strcmp(problem.identifier, 'EngineDashboard:InvalidInput')
                status.Text = problem.message;
            elseif strcmp(problem.identifier, 'EngineData:Nonfinite')
                status.Text = 'The reading cannot be standardized to finite values. Review the inputs.';
            else
                status.Text = ['Prediction failed. ' problem.message];
            end
            status.FontColor = [0.63 0.22 0.14];
            return
        end
        prediction.Text = sprintf('Class %d', result.predictedClass);
        for j = 1:numel(values)
            values(j).Text = sprintf('%.10g', result.rawReadings(j));
            values(j).Tooltip = sprintf('%.17g', result.rawReadings(j));
        end
        if ~isempty(result.scores)
            bars.YData = result.scores;
            scorePlaceholder.Visible = 'off';
            ylim(ax, 'auto');
            yticks(ax, 'auto');
            ax.YGrid = 'on';
            ax.YLabel.Visible = 'on';
            scoreText.Text = sprintf('Class %d: %.17g    |    Class %d: %.17g', ...
                result.classLabels(1), result.scores(1), result.classLabels(2), result.scores(2));
        end
        status.Text = 'Prediction complete. Edit the inputs to evaluate another reading.';
        status.FontColor = muted;
    end

    function onReset()
        for j = 1:numel(inputs)
            inputs(j).Value = '';
        end
        clearResults();
        status.Text = 'Enter the sensor readings, then select Predict.';
        status.FontColor = muted;
    end

    function clearResults()
        prediction.Text = 'No prediction';
        scoreText.Text = 'Scores unavailable';
        bars.YData = [NaN NaN];
        ylim(ax, [0 1]);
        yticks(ax, []);
        ax.YGrid = 'off';
        ax.YLabel.Visible = 'off';
        scorePlaceholder.Visible = 'on';
        for j = 1:numel(values)
            values(j).Text = '—';
            values(j).Tooltip = '';
        end
    end

    function enforceMinimumSize(~, ~)
        position = fig.Position;
        minimum = [865 620];
        if any(position(3:4) < minimum)
            position(3:4) = max(position(3:4), minimum);
            fig.Position = position;
        end
    end

    function closeDashboard()
        if isvalid(fig)
            delete(fig);
        end
    end
end

function reading = readInputs(inputs, displayNames)
reading = zeros(1, numel(inputs));
for k = 1:numel(inputs)
    entry = strtrim(inputs(k).Value);
    value = str2double(entry);
    % Match Stage 5 command-window decimal and scientific notation.
    if isempty(regexp(entry, '^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$', 'once')) || ...
            ~isreal(value) || ~isfinite(value)
        error('EngineDashboard:InvalidInput', '%s: enter one finite real number, such as 3.3 or 2e-3.', ...
            displayNames{k});
    end
    reading(k) = value;
end
end
