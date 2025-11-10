% Automatically add all subfolders of the repo to the MATLAB path
disp("Adding the repo and its subdirectories to the MATLAB path.")
repo_root = fileparts(mfilename('fullpath'));
addpath(genpath(repo_root));
