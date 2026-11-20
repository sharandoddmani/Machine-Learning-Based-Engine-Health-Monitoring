function validateEngineLabels(y)
if ~isnumeric(y) || ~isreal(y) || ~iscolumn(y) || isempty(y) || any(~ismember(y, [0 1]))
    error('EngineData:Labels', 'Expected engine_condition to contain only numeric 0 and 1 labels.');
end
end
