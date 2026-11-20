function index = selectEngineCandidate(metrics)
% Descending unrounded scores, then ascending input position.
ranking = [-[metrics.macroF1]', -[metrics.balancedAccuracy]', ...
    -[metrics.accuracy]', (1:numel(metrics))'];
[~, order] = sortrows(ranking);
index = order(1);
end
