function parameters = fitEnginePreprocessing(training)
% Use development-training rows for validation or all training rows for final fitting.
training = validateEngineFeatures(training, 'Preprocessing fit');
constant = all(training == training(1, :), 1);
center = mean(training, 1);
deviation = std(training, 0, 1);
center(constant) = training(1, constant);
deviation(constant) = 0;
if any(~isfinite(center) | ~isfinite(deviation))
    error('EngineData:FitRange', 'Feature magnitudes produced nonfinite fitted statistics.');
end
scale = deviation;
scale(scale == 0) = 1;
parameters = struct('featureNames', {engineSchema}, 'mean', center, ...
    'std', deviation, 'scale', scale, 'rowCount', size(training, 1));
end
