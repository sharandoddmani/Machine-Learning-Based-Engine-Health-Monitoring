function app = run_stage6(visibility)
% Launch the native MATLAB dashboard with the saved Stage 4 model.
arguments
    visibility (1,1) string {mustBeMember(visibility, ["on","off"])} = "on"
end
root = fileparts(mfilename('fullpath'));
src = fullfile(root, 'src');
addpath(fullfile(src, 'dashboard'), fullfile(src, 'inference'), fullfile(src, 'preprocessing'));
modelPath = fullfile(root, 'data', 'processed', 'final_engine_model.mat');
app = createEngineDashboard(modelPath, visibility);
end
