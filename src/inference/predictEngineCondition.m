function result = predictEngineCondition(bundle, reading)
% Predict one reading with a bundle validated by loadFinalEngineModel.
% Scores are returned in result.classLabels order and are uncalibrated model outputs.
names = bundle.featureNames;
if isstruct(reading) || istable(reading)
    ordered = orderNamedReading(reading, names);
elseif isnumeric(reading) && isequal(size(reading), [1 numel(names)])
    ordered = full(double(reading));
else
    error('EngineInference:ReadingShape', 'Enter one numeric 1-by-6 row, scalar sensor struct, or one-row sensor table.');
end
if ~isreal(ordered) || any(~isfinite(ordered))
    error('EngineInference:SensorValue', 'All six sensor readings must be real and finite.');
end

standardized = applyEnginePreprocessing(ordered, bundle.preprocessing);
[label, scores] = predict(bundle.model, standardized);
result = struct('predictedClass', label, 'featureNames', {names}, 'rawReadings', ordered, ...
    'standardizedReadings', standardized, 'classLabels', bundle.classLabels, 'scores', scores, ...
    'algorithm', bundle.algorithm, 'hyperparameters', bundle.hyperparameters, ...
    'trainingRows', bundle.trainingRows, 'matlabVersion', bundle.matlabVersion, ...
    'trainingTimestampUtc', bundle.trainingTimestampUtc);
end

function ordered = orderNamedReading(reading, names)
if istable(reading)
    if height(reading) ~= 1
        error('EngineInference:ReadingShape', 'A sensor table must contain exactly one row.');
    end
    supplied = reading.Properties.VariableNames;
else
    if ~isscalar(reading)
        error('EngineInference:ReadingShape', 'A sensor struct must be scalar.');
    end
    supplied = fieldnames(reading);
end
missing = setdiff(names, supplied, 'stable');
unknown = setdiff(supplied, names, 'stable');
if ~isempty(missing) || ~isempty(unknown) || numel(supplied) ~= numel(names)
    error('EngineInference:SensorNames', ...
        'Expected exactly the six named sensors once each. Missing: [%s]. Unknown: [%s].', ...
        strjoin(missing, ', '), strjoin(unknown, ', '));
end
ordered = zeros(1, numel(names));
for k = 1:numel(names)
    value = reading.(names{k});
    if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ~isfinite(value)
        error('EngineInference:SensorValue', '%s must be one real, finite numeric value.', names{k});
    end
    ordered(k) = double(value);
end
end
