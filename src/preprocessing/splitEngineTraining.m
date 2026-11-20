function [development, validation] = splitEngineTraining(y)
% Sample within each class without changing the caller's random stream.
validateEngineLabels(y);
stream = RandStream('mt19937ar', 'Seed', 42);
heldOut = false(size(y));
for label = 0:1
    rows = find(y == label);
    if numel(rows) < 2
        error('EngineData:ClassSize', 'Class %d requires at least two training records.', label);
    end
    count = max(1, round(0.20 * numel(rows)));
    shuffled = randperm(stream, numel(rows));
    heldOut(rows(shuffled(1:count))) = true;
end
development = find(~heldOut);
validation = find(heldOut);
end
