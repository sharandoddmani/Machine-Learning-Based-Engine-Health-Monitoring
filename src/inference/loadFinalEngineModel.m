function bundle = loadFinalEngineModel(modelPath)
% Read and validate the Stage 4 model. A missing file requires a separate Stage 4 run.
if ~isfile(modelPath)
    error('EngineInference:MissingModel', ...
        'Final model file not found: %s. Run Stage 4 separately to create it.', char(modelPath));
end
if isempty(ver('stats'))
    error('EngineInference:Toolbox', 'Loading the final model requires Statistics and Machine Learning Toolbox.');
end
try
    artifact = load(modelPath, '-mat');
catch problem
    error('EngineInference:UnreadableModel', 'Cannot read final model file %s: %s', ...
        char(modelPath), problem.message);
end
if ~isfield(artifact, 'bundle')
    error('EngineInference:InvalidBundle', 'The Stage 4 MAT file must contain a variable named bundle.');
end
bundle = artifact.bundle;
required = {'model','algorithm','hyperparameters','preprocessing','featureNames', ...
    'classLabels','trainingRows','matlabVersion','trainingTimestampUtc'};
if ~isstruct(bundle) || ~isscalar(bundle) || ~all(isfield(bundle, required))
    error('EngineInference:InvalidBundle', 'The Stage 4 bundle must be a scalar struct with all inference fields.');
end
if ~isequal(bundle.algorithm, 'Decision Tree') || ...
        ~isstruct(bundle.hyperparameters) || ~isscalar(bundle.hyperparameters) || ...
        ~isfield(bundle.hyperparameters, 'MaxNumSplits') || ...
        ~isequal(bundle.hyperparameters.MaxNumSplits, 30) || ...
        ~isequal(bundle.trainingRows, 15628) || ...
        ~ischar(bundle.matlabVersion) || ~isrow(bundle.matlabVersion) || ...
        ~ischar(bundle.trainingTimestampUtc) || ~isrow(bundle.trainingTimestampUtc)
    error('EngineInference:InvalidMetadata', ...
        'Expected metadata for the final 30-split Decision Tree trained on 15,628 rows.');
end
tree = bundle.model;
if ~isa(tree, 'classreg.learning.classif.CompactClassificationTree') || ~isscalar(tree)
    error('EngineInference:InvalidTree', 'The Stage 4 bundle must contain a MATLAB classification tree.');
end

names = engineSchema;
if ~isequal(bundle.featureNames, names) || ~isequal(tree.PredictorNames, names)
    error('EngineInference:FeatureOrder', 'The bundle and tree must use the six Stage 4 predictors in order.');
end
if ~isequal(bundle.classLabels, [0 1]) || ~isequal(tree.ClassNames(:)', [0 1])
    error('EngineInference:ClassOrder', 'The bundle and tree must use numeric class order [0 1].');
end
p = bundle.preprocessing;
if ~isstruct(p) || ~isscalar(p) || ~all(isfield(p, {'featureNames','mean','scale'})) || ...
        ~isequal(p.featureNames, names)
    error('EngineInference:InvalidPreprocessing', 'Missing or inconsistent Stage 4 preprocessing fields.');
end
if ~validParameterRow(p.mean, numel(names)) || ~validParameterRow(p.scale, numel(names)) || any(p.scale <= 0)
    error('EngineInference:InvalidPreprocessing', ...
        'Stage 4 preprocessing requires six finite real means and six finite positive scales.');
end
end

function valid = validParameterRow(values, featureCount)
valid = isnumeric(values) && isreal(values) && isequal(size(values), [1 featureCount]) && all(isfinite(values));
end
