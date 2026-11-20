function results = run_stage7
% Verify the approved artifact, noninteractive inference, and full test suite.
root = fileparts(mfilename('fullpath'));
src = fullfile(root, 'src');
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(root, fullfile(src, 'inference'), fullfile(src, 'preprocessing'), fullfile(src, 'dashboard'));
modelPath = fullfile(root, 'data', 'processed', 'final_engine_model.mat');

fprintf('Stage 7 integration verification\n');
try
    assert(isfile(modelPath), 'EngineInference:MissingModel', ...
        'Final model file not found: %s. Run Stage 4 separately to create it.', modelPath);
    % The Stage 5 demo validates and loads the bundle before predicting.
    run_stage5_demo();
    run_stage6_smoke();
    results = runtests(fullfile(root, 'tests'));
    fprintf('MATLAB tests: %d passed, %d failed, %d incomplete (%d total).\n', ...
        nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results));
    assert(~isempty(results), 'EngineIntegration:NoTests', 'No MATLAB tests were discovered.');
    assertSuccess(results);
catch problem
    fprintf(2, 'Stage 7 verification FAIL: %s\n', problem.message);
    rethrow(problem);
end
fprintf('Stage 7 verification PASS.\n');
end
