function requireEngineModelToolbox
if isempty(ver('stats')) || any(cellfun(@(name) isempty(which(name)), ...
        {'fitcknn','fitctree','fitcsvm'}))
    error('EngineModels:Toolbox', 'Stage 3 requires Statistics and Machine Learning Toolbox.');
end
[available, message] = license('checkout', 'Statistics_Toolbox');
if ~available
    error('EngineModels:Toolbox', 'Statistics and Machine Learning Toolbox license checkout failed: %s', message);
end
end
