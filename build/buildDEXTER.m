% This script builds the standalone executable.
% You will need the MATLAB Compiler package

% Ensure the repo root directory is the current working directory or add
% the repo and its subfolders to your MATLAB path.

%% Build Process
% Generates the DEXTER executable and places it in the appOuput directory
% in build.

disp("Building DEXTER Grader...")

cd("src")

% Get version
dexter_version = DEXTER.version;

opts = compiler.build.StandaloneApplicationOptions(fullfile("@DEXTER","DEXTER.m"));

opts.ExecutableVersion = dexter_version;
opts.Verbose = "on";
opts.OutputDir = fullfile("..","build","appOutput");
opts.ExecutableSplashScreen = fullfile("..","build","graphics","splash.png");
opts.ExecutableIcon = fullfile("..","build","graphics","icon_dg_64x64.png");

opts.AdditionalFiles = { char(fullfile("..","build","graphics","icon_dg_48x48.png")) };

results = compiler.build.standaloneApplication(opts); % 'results' will be used below

fprintf("\nBuild Complete!\n\n")

%% Package Process
% Packages the DEXTER.exe executable into an installer. The installer is
% saved to executables in the build folder.

disp("Starting Packaging...")

pack_opts = compiler.package.InstallerOptions(results); % takes build results

pack_opts.ApplicationName = "DEXTER Grader";
pack_opts.AuthorName = "Devon Lantagne";
pack_opts.AuthorEmail = "lantagned@msoe.edu";
pack_opts.AuthorCompany = "Milwaukee School of Engineering";
pack_opts.Summary = "DEXTER Grader is a grading tool that gives the user more control over problems and point criteria compared to the Canvas SpeedGrader.";
pack_opts.Description = "DEXTER Grader (DEXTER) is a grading calculator and gradebook manager. DEXTER’s main goal is to improve the efficiency and consistency of grading. The secondary goal of DEXTER is to provide insights into student performance. This is not a unified gradebook. DEXTER acts on individual assignments/exams; you will need a new DEXTER project per assignment. Projects are initialized using a class list and rubric file. See the DEXTER Wiki on how to find, create, or format these files. DEXTER is a ""standalone"" MATLAB App. To use a standalone MATLAB app, you need the MATLAB Runtime. When you install DEXTER, the runtime will also be installed if it is not already on your computer. DEXTER is currently only supported on Windows OS.";
pack_opts.Version = dexter_version;
pack_opts.InstallerLogo = fullfile("..","build","graphics","InstallTall.png"); % 112x290 px
pack_opts.InstallerSplash = fullfile("..","build","graphics","splash.png");
pack_opts.InstallerIcon = fullfile("..","build","graphics","icon_dg_48x48.png"); % 48x48
pack_opts.InstallerName = "DEXTER_installer_" + strrep(dexter_version,".","_");
pack_opts.OutputDir = fullfile("..","build","executables");
pack_opts.Verbose = "on";

compiler.package.installer(results, 'Options', pack_opts)

fprintf("\nPackaging Complete!\n\n")

cd("..")
