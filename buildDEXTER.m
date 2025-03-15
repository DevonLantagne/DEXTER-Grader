% This script builds the standalone executable.
% You will need the MATLAB Compiler package

% Build Process
disp("Building DEXTER Grader...")
opts = compiler.build.StandaloneApplicationOptions("DEXTER.m");
opts.ExecutableVersion = DEXTER.version;
opts.Verbose = "on";
opts.OutputDir = fullfile(".","build","appOutput");
opts.ExecutableSplashScreen = fullfile(".","Graphics","splash.png");
opts.ExecutableIcon = fullfile(".","Graphics","icon.png");

results = compiler.build.standaloneApplication(opts);
fprintf("\nBuild Complete!\n\n")

% Package Process
disp("Starting Packaging...")
pack_opts = compiler.package.InstallerOptions(results); % takes build results
pack_opts.ApplicationName = "DEXTER Grader";
pack_opts.AuthorName = "Devon Lantagne";
pack_opts.AuthorEmail = "lantagned@msoe.edu";
pack_opts.AuthorCompany = "Milwaukee School of Engineering";
pack_opts.Summary = "DEXTER Grader is a grading tool that gives the user more control over problems and point criteria compared to the Canvas SpeedGrader.";
pack_opts.Description = "DEXTER Grader (DEXTER) is a grading calculator and gradebook manager. DEXTER’s main goal is to improve the efficiency and consistency of grading. The secondary goal of DEXTER is to provide insights into student performance.\n This is not a unified gradebook. DEXTER acts on individual assignments/exams; you will need a new DEXTER project per assignment. Projects are initialized using a class list and rubric file. See the User Guide on how to find, create, or format these files.\nDEXTER is a ""standalone"" MATLAB App. To use a standalone MATLAB app, you need the MATLAB Runtime. When you install DEXTER, the runtime will also be installed if it is not already on your computer. DEXTER is currently only supported on Windows OS.";
pack_opts.Version = DEXTER.version;
pack_opts.InstallerLogo = fullfile(".","Graphics","InstallTall.png"); % 112x290 px
pack_opts.InstallerSplash = fullfile(".","Graphics","splash.png");
pack_opts.InstallerIcon = fullfile(".","Graphics","icon.png"); % 48x48
pack_opts.InstallerName = "DEXTER_installer_" + strrep(DEXTER.version,".","_");
pack_opts.OutputDir = fullfile(".","build","installer");

compiler.package.installer(results,'Options',pack_opts)
fprintf("\nPackaging Complete!\n\n")


