function [evaluation, predicted, rawTest] = evaluateFinalEngineModel(bundle, testPath)
% Score a previously fitted bundle. Test data enter only this evaluation.
[rawTest, actual] = loadEngineSplit(testPath, 3907);
standardized = applyEnginePreprocessing(rawTest, bundle.preprocessing);
predicted = predict(bundle.model, standardized);
baseline = repmat(bundle.majorityClass, size(actual));
evaluation = struct('testRows', numel(actual), ...
    'testClassCounts', [nnz(actual == 0), nnz(actual == 1)], ...
    'tree', completeMetrics(actual, predicted), ...
    'baseline', completeMetrics(actual, baseline));
end

function metrics = completeMetrics(actual, predicted)
metrics = evaluateEngineValidation(actual, predicted);
metrics.macroPrecision = mean(metrics.precision);
metrics.macroRecall = mean(metrics.recall);
metrics.correctCount = trace(metrics.confusionMatrix);
metrics.incorrectCount = numel(actual) - metrics.correctCount;
end
