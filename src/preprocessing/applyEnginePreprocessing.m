function standardized = applyEnginePreprocessing(X, parameters)
% Input matrices and single readings must use the canonical sensor order.
X = validateEngineFeatures(X, 'Preprocessing transform');
if ~isequal(parameters.featureNames, engineSchema)
    error('EngineData:ParameterOrder', 'Fitted feature names do not match the canonical order.');
end
center = validateEngineFeatures(parameters.mean, 'Fitted mean');
scale = validateEngineFeatures(parameters.scale, 'Fitted scale');
if ~isrow(center) || ~isrow(scale) || any(scale <= 0)
    error('EngineData:Parameters', 'Expected one fitted mean and positive scale per sensor.');
end
standardized = (X - center) ./ scale;
validateEngineFeatures(standardized, 'Standardized output');
end
