function metrics = evaluateEngineValidation(actual, predicted)
% Confusion matrix rows are actual labels, columns are predicted labels.
validateEngineLabels(actual);
validateEngineLabels(predicted);
if numel(actual) ~= numel(predicted)
    error('EngineModels:PredictionSize', 'Expected one predicted label per validation record.');
end
counts = accumarray([double(actual)+1, double(predicted)+1], 1, [2 2]);
correct = diag(counts);
actualTotals = sum(counts, 2);
predictedTotals = sum(counts, 1)';
precision = correct ./ max(predictedTotals, 1);
recall = correct ./ max(actualTotals, 1);
f1 = 2*correct ./ max(actualTotals + predictedTotals, 1);
metrics = struct('classOrder', [0 1], 'confusionMatrix', counts, ...
    'accuracy', sum(correct)/numel(actual), 'precision', precision, ...
    'recall', recall, 'f1', f1, 'macroF1', mean(f1), 'balancedAccuracy', mean(recall));
end
