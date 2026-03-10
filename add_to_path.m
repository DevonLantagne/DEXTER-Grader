% Automatically add all subfolders of the repo to the MATLAB path
disp("Adding the repo and its subdirectories to the MATLAB path.")
repo_root = fileparts(mfilename('fullpath'));

path_src = genpath(fullfile(repo_root, 'src'));
path_canvas = genpath(fullfile(repo_root, 'canvas-matlab'));
path_build = genpath(fullfile(repo_root, 'build'));

addpath(path_src, path_canvas, path_build);
