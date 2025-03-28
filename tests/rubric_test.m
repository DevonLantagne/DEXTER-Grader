% This script loads test data from directories into the base workspace.
% You will likely need to add this script to the MATLAB path temporarily.

dbstop if error

obj = Rubric();
obj.Name = "Rubric Test";

% Load Rubric
[obj, msg] = obj.LoadRubricTable(fullfile("examples", "ExampleRubric.xlsx"));

% Load Students
obj = obj.LoadStudentList(fullfile("examples", "ListFromCanvas.csv"));