function result = run_stage5(reading)
% Prompt for manual readings, or pass a single reading to skip prompts.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src', 'inference'), fullfile(root, 'src', 'preprocessing'));
bundle = loadFinalEngineModel(fullfile(root, 'data', 'processed', 'final_engine_model.mat'));
fprintf('Stage 5 engine condition prediction using the saved Stage 4 %s.\n', bundle.algorithm);
fprintf('Class 0 and Class 1 are dataset labels with unverified physical meanings.\n');
if nargin == 1
    result = predictEngineCondition(bundle, reading);
    printPrediction(result);
    return
end

result = [];
fprintf('Enter the six readings below in model order. Type q at any sensor prompt to exit.\n');
fprintf('  %s\n', bundle.featureNames{:});
while true
    values = zeros(1, numel(bundle.featureNames));
    for k = 1:numel(values)
        while true
            entry = strtrim(input(sprintf('%s: ', bundle.featureNames{k}), 's'));
            if strcmpi(entry, 'q')
                return
            end
            value = str2double(entry);
            if ~isempty(regexp(entry, '^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$', 'once')) && ...
                    isreal(value) && isfinite(value)
                values(k) = value;
                break
            end
            fprintf('Enter one finite real number, for example 3.3 or 2e-3.\n');
        end
    end
    try
        result = predictEngineCondition(bundle, values);
        printPrediction(result);
    catch problem
        if ~strcmp(problem.identifier, 'EngineData:Nonfinite')
            rethrow(problem);
        end
        fprintf('The reading produced a nonfinite standardized value. Enter another reading.\n');
    end
    while true
        answer = lower(strtrim(input('Predict another reading? [y/N]: ', 's')));
        if any(strcmp(answer, {'','n','no','q'}))
            return
        end
        if any(strcmp(answer, {'y','yes'}))
            break
        end
        fprintf('Please answer y or n.\n');
    end
end
end

function printPrediction(result)
fprintf('\nInput readings in model order\n');
for k = 1:numel(result.featureNames)
    fprintf('  %-20s %.16g\n', result.featureNames{k}, result.rawReadings(k));
end
fprintf('Predicted class: Class %d\n', result.predictedClass);
if ~isempty(result.scores)
    fprintf('Classification scores (uncalibrated model outputs)\n');
    for k = 1:numel(result.classLabels)
        fprintf('  Class %d: %.8g\n', result.classLabels(k), result.scores(k));
    end
end
end
