function benchmark = trainEngineCandidates(data)
% Fit on development rows and score each setting once on validation rows.
requireEngineModelToolbox;
names = engineSchema;
if ~isequal(data.parameters.featureNames, names) || ...
        data.parameters.rowCount ~= size(data.XDevelopment, 1)
    error('EngineModels:Preprocessing', 'Expected development-only preprocessing in canonical sensor order.');
end
X = validateEngineFeatures(data.XDevelopment, 'Development predictors');
validation = validateEngineFeatures(data.XValidation, 'Validation predictors');
y = data.yDevelopment;
validateEngineLabels(y);
validateEngineLabels(data.yValidation);
if numel(y) ~= size(X, 1) || numel(data.yValidation) ~= size(validation, 1)
    error('EngineModels:RowCount', 'Each development and validation row requires one label.');
end
previousRng = rng;
restoreRng = onCleanup(@() rng(previousRng));
rng(data.seed, 'twister');
common = {'ClassNames', [0 1], 'PredictorNames', names, 'Prior', 'empirical'};
neighbors = [3 5 7 11];
splitLimits = [10 30 100];
kernels = {'linear','gaussian'};
knn = fitcknn(X, y, common{:}, 'NumNeighbors', neighbors(1), ...
    'Distance', 'euclidean', 'DistanceWeight', 'equal', 'NSMethod', 'kdtree', ...
    'Standardize', false, 'BreakTies', 'smallest', 'IncludeTies', false);
candidates = cell(1, numel(neighbors) + numel(splitLimits) + numel(kernels));
next = 1;
for k = neighbors
    knn.NumNeighbors = k;
    settings = struct('numNeighbors', k, 'distance', 'euclidean', 'distanceWeight', 'equal', ...
        'searchMethod', 'kdtree', 'standardize', false, 'breakTies', 'smallest', ...
        'includeTies', false, 'prior', 'empirical');
    candidates{next} = score('KNN', sprintf('k = %d', k), settings, knn, data.yValidation, validation);
    next = next + 1;
end
for splits = splitLimits
    model = fitctree(X, y, common{:}, 'MaxNumSplits', splits, ...
        'MinLeafSize', 1, 'SplitCriterion', 'gdi');
    settings = struct('maxNumSplits', splits, 'minLeafSize', 1, ...
        'splitCriterion', 'gdi', 'prior', 'empirical');
    candidates{next} = score('Decision Tree', sprintf('max splits = %d', splits), ...
        settings, compact(model), data.yValidation, validation);
    next = next + 1;
end
for kernel = kernels
    settings = struct('kernel', kernel{1}, 'boxConstraint', 1, ...
        'kernelScale', 1, 'standardize', false, 'solver', 'SMO', 'prior', 'empirical');
    model = fitcsvm(X, y, common{:}, 'KernelFunction', settings.kernel, ...
        'BoxConstraint', settings.boxConstraint, 'KernelScale', settings.kernelScale, ...
        'Standardize', settings.standardize, 'Solver', settings.solver);
    if ~model.ConvergenceInfo.Converged
        error('EngineModels:SVMConvergence', 'The %s SVM did not converge.', settings.kernel);
    end
    candidates{next} = score('SVM', settings.kernel, settings, ...
        compact(model), data.yValidation, validation);
    next = next + 1;
end
candidates = [candidates{:}];
families = {'KNN','Decision Tree','SVM'};
bestPerAlgorithm = zeros(1, numel(families));
for k = 1:numel(families)
    indices = find(strcmp({candidates.algorithm}, families{k}));
    bestPerAlgorithm(k) = indices(selectEngineCandidate([candidates(indices).validationMetrics]));
end
bestOverall = bestPerAlgorithm(selectEngineCandidate([candidates(bestPerAlgorithm).validationMetrics]));
benchmark = struct('candidates', candidates, 'bestPerAlgorithm', bestPerAlgorithm, ...
    'bestOverall', bestOverall, 'featureNames', {names}, 'preprocessing', data.parameters, ...
    'developmentIndices', data.developmentIndices, 'validationIndices', data.validationIndices, ...
    'seed', data.seed, 'matlabVersion', version, 'toolboxVersion', ver('stats'));
end

function candidate = score(algorithm, setting, hyperparameters, model, actual, validation)
predicted = predict(model, validation);
candidate = struct('algorithm', algorithm, 'setting', setting, ...
    'hyperparameters', hyperparameters, 'model', model, ...
    'validationMetrics', evaluateEngineValidation(actual, predicted), 'validationPredictions', predicted);
end
