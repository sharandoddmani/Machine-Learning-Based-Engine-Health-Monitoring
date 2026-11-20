% Inspect the published train/test splits and write the Stage 1 outputs.
stage1(fileparts(mfilename('fullpath')));

function stage1(root)
reportDir = fullfile(root, 'results', 'reports');
figureDir = fullfile(root, 'results', 'figures');
if ~isfolder(reportDir), mkdir(reportDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
report = fullfile(reportDir, 'dataset_verification.txt');
[file, message] = fopen(report, 'w', 'n', 'UTF-8');
if file < 0, error('Stage1:Report', '%s', message); end
cleanup = onCleanup(@() fclose(file));

say(file, 'Stage 1 dataset verification\nMATLAB %s\n', version('-release'));
say(file, ['Source: https://huggingface.co/datasets/mukherjee78/' ...
    'predictive-maintenance-engine-data\n']);
sensors = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
splits = {'train','test'};
paths = fullfile(root, 'data', 'raw', strcat(splits, '.csv'));
missingFiles = ~isfile(paths);
if any(missingFiles)
    say(file, 'Missing input files: %s\n', strjoin(paths(missingFiles), ', '));
    error('Stage1:MissingInput', 'Place the published CSVs in data/raw and rerun.');
end
try
    train = loadSplit(paths{1});
    test = loadSplit(paths{2});
catch problem
    say(file, 'CSV import failed: %s\n', problem.message);
    rethrow(problem);
end

documentedTarget = 'engine_condition';
target = '';
if all(cellfun(@(names) ismember(documentedTarget, names), ...
        {train.Properties.VariableNames, test.Properties.VariableNames}))
    target = documentedTarget;
    say(file, 'Documented target: %s (Engine Condition in the source card).\n', target);
else
    say(file, 'Target ambiguous: documented header is absent from at least one split.\n');
end
say(file, 'Assumptions and limits: the source card does not define label meanings, units for all sensors, or split provenance.\n');
trainInfo = inspectSplit(file, 'Training', train, target, sensors);
testInfo = inspectSplit(file, 'Testing', test, target, sensors);
match = isempty(setxor(trainInfo.features, testInfo.features));
say(file, '\nMatching feature names (order independent): %d\n', match);
say(file, 'Training-only features: %s\n', list(setdiff(trainInfo.features, testInfo.features)));
say(file, 'Testing-only features: %s\n', list(setdiff(testInfo.features, trainInfo.features)));
for name = intersect(trainInfo.features, testInfo.features, 'stable')
    if ~strcmp(class(train.(name{1})), class(test.(name{1})))
        say(file, 'Feature type mismatch: %s\n', name{1});
        match = false;
    end
end
[shared, overlapOK] = overlap(file, trainInfo.keys, testInfo.keys, ...
    train.Properties.VariableNames, test.Properties.VariableNames, 'Full records');
[featureShared, featureOverlapOK] = overlap(file, trainInfo.keys, testInfo.keys, ...
    trainInfo.features, testInfo.features, 'Feature-only records');

usable = ~isempty(target) && match && all(ismember(sensors, trainInfo.numeric)) ...
    && all(ismember(sensors, testInfo.numeric)) && numel(trainInfo.labels) > 1 ...
    && isequal(trainInfo.labels, testInfo.labels);
if usable && trainInfo.clean && testInfo.clean && overlapOK && featureOverlapOK ...
        && shared == 0 && featureShared == 0
    say(file, '\nAssessment: suitable for a preliminary supervised classification benchmark.\n');
else
    say(file, '\nAssessment: resolve the schema, data quality, or overlap findings above before benchmarking.\n');
end
say(file, ['Stage 2: confirm label meanings and split provenance, check for engine or time ' ...
    'grouping, validate sensor ranges, and fit preprocessing on training data only. ' ...
    'Keep the test split held out and use per-class metrics alongside accuracy.\n']);
say(file, '\nVisualizations\n');
plotErrors = false;
for kind = ["target_class_distribution", "sensor_histograms", "feature_correlation"]
    try
        plotDataset(file, figureDir, kind, train, trainInfo, testInfo, sensors);
    catch problem
        say(file, 'Could not save %s: %s\n', kind, problem.message);
        plotErrors = true;
    end
end
if plotErrors
    error('Stage1:Figures', 'One or more figure exports failed. See the verification report.');
end
say(file, '\nInspection completed.\n');
end

function data = loadSplit(path)
opts = detectImportOptions(path, 'FileType', 'text', 'Delimiter', ',', ...
    'VariableNamingRule', 'preserve');
opts.ImportErrorRule = 'error';
opts.ExtraColumnsRule = 'error';
data = readtable(path, opts);
if height(data) == 0 || width(data) < 2
    error('Stage1:CSVShape', 'Expected data rows and multiple CSV columns in %s.', path);
end
end

function info = inspectSplit(file, split, data, target, sensors)
names = data.Properties.VariableNames;
info = struct('features', {setdiff(names, {target}, 'stable')}, ...
    'numeric', {{}}, 'categorical', {{}}, 'keys', table(), ...
    'labels', strings(0,1), 'counts', zeros(0,1), 'clean', true);
say(file, '\n%s dataset: %d rows x %d columns\n', split, height(data), width(data));
preview = evalc('disp(data(1:min(5,height(data)), :))');
preview = regexprep(preview, '</?strong>|[ \t]+(?=\r?$)', '', 'lineanchors');
say(file, '%s\n', strtrim(preview));
say(file, 'Input columns: %s\n', list(info.features));
for k = 1:numel(names)
    name = names{k};
    values = data.(name);
    numeric = isnumeric(values) && isreal(values);
    textual = isstring(values) || iscellstr(values) || iscategorical(values);
    if ~iscolumn(values) || ~(numeric || textual || islogical(values))
        say(file, '  %s (%s): unsupported type or shape for quality checks\n', name, class(values));
        info.clean = false;
        continue
    end
    missing = ismissing(values);
    if textual
        missing = missing | strcmp(strtrim(string(values)), "");
    end
    nonfinite = 0;
    if numeric, nonfinite = nnz(isinf(values)); end
    observed = values(~missing);
    say(file, '  %s (%s): %d missing, %d infinite\n', name, class(values), nnz(missing), nonfinite);
    keys = "value:" + string(values);
    if numeric
        % Hexadecimal representation preserves exact imported numeric values.
        exact = double(values);
        exact(exact == 0) = 0;
        keys = "number:" + string(cellstr(num2hex(exact)));
    end
    keys(missing) = "missing";
    info.keys.(name) = keys;
    info.clean = info.clean && ~any(missing) && nonfinite == 0;
    if strcmp(name, target)
        [labels, ~, groups] = unique(string(observed));
        info.labels = labels;
        info.counts = accumarray(groups, 1, [numel(labels), 1]);
        for j = 1:numel(labels)
            say(file, '    Label %s: %d (%.2f%% of nonmissing labels)\n', ...
                labels(j), info.counts(j), 100 * info.counts(j) / numel(observed));
        end
        continue
    end
    if numeric
        info.numeric{end+1} = name;
    else
        info.categorical{end+1} = name;
    end
    if ~isempty(observed) && numel(unique(observed)) == 1
        say(file, '    Constant among nonmissing values.\n');
        info.clean = false;
    end
    if ~isempty(regexpi(name, '(^|[ _])(id|index|timestamp|serial|vin)([ _]|$)', 'once'))
        say(file, '    Possible identifier based on header. Review before modeling.\n');
        info.clean = false;
    end
end
say(file, 'Numerical inputs: %s\nCategorical inputs: %s\n', list(info.numeric), list(info.categorical));
say(file, 'Expected sensors present: %d/%d. Missing sensors: %s\n', ...
    nnz(ismember(sensors, names)), numel(sensors), list(setdiff(sensors, names)));
if width(info.keys) == width(data)
    duplicates = height(data) - height(unique(info.keys));
    say(file, 'Duplicate rows beyond the first occurrence: %d\n', duplicates);
    info.clean = info.clean && duplicates == 0;
else
    say(file, 'Duplicate check skipped because some columns are unsupported.\n');
end
end

function [shared, checked] = overlap(file, train, test, names, testNames, description)
shared = NaN;
checked = ~isempty(names) && isempty(setxor(names, testNames)) ...
    && all(ismember(names, train.Properties.VariableNames)) ...
    && all(ismember(names, test.Properties.VariableNames));
if checked
    a = train(:, names);
    b = test(:, names);
    shared = height(intersect(a, b));
    say(file, '%s shared: %d distinct (%d training rows and %d testing rows).\n', ...
        description, shared, nnz(ismember(a, b)), nnz(ismember(b, a)));
else
    say(file, '%s overlap skipped because columns are missing, unsupported, or mismatched.\n', description);
end
end

function plotDataset(file, folder, kind, train, trainInfo, testInfo, sensors)
path = fullfile(folder, kind + ".png");
switch kind
    case "target_class_distribution"
        labels = union(trainInfo.labels, testInfo.labels);
        if isempty(labels)
            say(file, 'Class chart skipped: no confirmed, usable target labels.\n');
            return
        end
        counts = zeros(numel(labels), 2);
        [~, locations] = ismember(trainInfo.labels, labels);
        counts(locations, 1) = trainInfo.counts;
        [~, locations] = ismember(testInfo.labels, labels);
        counts(locations, 2) = testInfo.counts;
    case "sensor_histograms"
        names = intersect(sensors, trainInfo.numeric, 'stable');
        names = names(cellfun(@(name) any(isfinite(train.(name))), names));
        if isempty(names)
            say(file, 'Histograms skipped: no documented sensors with finite numerical training values.\n');
            return
        end
    case "feature_correlation"
        names = intersect(sensors, trainInfo.numeric, 'stable');
        if numel(names) < 2
            say(file, 'Correlation skipped: fewer than two numerical sensor inputs.\n');
            return
        end
        values = train{:, names};
        values = values(all(isfinite(values), 2), :);
        if size(values, 1) < 3
            say(file, 'Correlation skipped: fewer than three complete finite training rows.\n');
            return
        end
        varies = any(values ~= values(1,:), 1);
        names = names(varies);
        if numel(names) < 2
            say(file, 'Correlation skipped: fewer than two varying numerical sensor inputs.\n');
            return
        end
        coefficients = corrcoef(values(:, varies));
        say(file, 'Pearson correlation uses %d complete training rows.\n', size(values, 1));
end
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 1050 700]);
closeFigure = onCleanup(@() close(fig));
switch kind
    case "target_class_distribution"
        if isscalar(labels)
            bar(1:2, [counts; NaN NaN]);
            xlim([0.5 1.5]);
        else
            bar(1:numel(labels), counts);
        end
        xticks(1:numel(labels));
        xticklabels(labels);
        xlabel('Engine condition label');
        ylabel('Records');
        title('Engine condition by split');
        legend('Training', 'Testing', 'Location', 'best');
    case "sensor_histograms"
        layout = tiledlayout(fig, ceil(numel(names)/2), 2, 'TileSpacing', 'compact');
        title(layout, 'Training engine sensor distributions');
        for k = 1:numel(names)
            ax = nexttile(layout);
            values = train.(names{k});
            histogram(ax, values(isfinite(values)));
            xlabel(ax, names{k}, 'Interpreter', 'none');
            ylabel(ax, 'Records');
        end
    case "feature_correlation"
        chart = heatmap(fig, names, names, coefficients, ...
            'ColorLimits', [-1 1], 'CellLabelFormat', '%.2f');
        chart.Title = 'Pearson correlation of training sensors';
        chart.XLabel = 'Engine sensor';
        chart.YLabel = 'Engine sensor';
        chart.Interpreter = 'none';
end
exportgraphics(fig, path, 'Resolution', 160);
say(file, 'Saved %s.png\n', kind);
end

function result = list(names)
result = strjoin(names, ', ');
if isempty(result), result = '(none)'; end
end

function say(file, format, varargin)
fprintf(1, format, varargin{:});
fprintf(file, format, varargin{:});
end
