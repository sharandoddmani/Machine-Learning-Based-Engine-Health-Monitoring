function [X, y] = loadEngineSplit(path, expectedRows)
% Import one publisher split and extract sensors in canonical order.
if ~isfile(path)
    error('EngineData:MissingFile', 'Missing dataset file: %s.', path);
end
[features, target] = engineSchema;
expected = [features, {target}];
opts = detectImportOptions(path, 'FileType', 'text', 'Delimiter', ',', ...
    'VariableNamingRule', 'preserve');
if opts.VariableNamesLine ~= 1 || ~isempty(setxor(opts.VariableNames, expected)) || ...
        numel(opts.VariableNames) ~= numel(expected)
    error('EngineData:Schema', 'Expected exactly these columns in %s: %s.', ...
        path, strjoin(expected, ', '));
end
opts = setvartype(opts, expected, 'double');
opts.DataLines = [2 Inf];
opts.ImportErrorRule = 'error';
opts.MissingRule = 'error';
opts.ExtraColumnsRule = 'error';
opts.EmptyLineRule = 'error';
try
    data = readtable(path, opts);
catch problem
    error('EngineData:Import', 'Cannot read numeric records from %s: %s', path, problem.message);
end
if height(data) ~= expectedRows
    error('EngineData:Rows', 'Expected %d rows in %s, found %d.', expectedRows, path, height(data));
end
X = validateEngineFeatures(data{:, features}, char(path));
y = data.(target);
validateEngineLabels(y);
end
