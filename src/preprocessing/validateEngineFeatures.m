function X = validateEngineFeatures(X, description)
features = engineSchema;
if ~isnumeric(X) || ~isreal(X) || ~ismatrix(X) || isempty(X) || size(X, 2) ~= numel(features)
    error('EngineData:Features', '%s requires a nonempty real numeric matrix with six columns.', description);
end
[row, col] = find(~isfinite(X), 1);
if ~isempty(row)
    error('EngineData:Nonfinite', '%s has a missing or nonfinite %s at row %d.', ...
        description, features{col}, row);
end
X = double(X);
end
