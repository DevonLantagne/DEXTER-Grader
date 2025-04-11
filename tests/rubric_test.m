% This script loads test data from directories into the base workspace.
% You will likely need to add this script to the MATLAB path temporarily.

%% Loading

dbstop if error

obj = Rubric();
obj.Name = "Rubric Test";

% Load Rubric
[obj, msg] = obj.LoadRubricTable(fullfile("examples", "ExampleRubric.xlsx"));

% Load Students
obj = obj.LoadStudentList(fullfile("examples", "ListFromCanvas.csv"));

%% Fabricating User Scores
% For every student, randomly provide a score between 0 and the criteria
% points

% Get the default grid and assign random integers
totalPts = obj.tbl.CriteriaPoints;
grid = obj.AllScores();
for row = 1:size(grid,1)
    grid(row,:) = randi([0, totalPts(row)], 1, size(grid,2));
end
% Load back into gradebook
obj = obj.LoadGrid(grid);

%% Get Info

student = obj.StudentNames(1);
problem = obj.ProblemNames(1);

% Info about overall student performance and problem breakdown
obj.GetStudentInfo(student)

% Info about a specific problem
obj.GetProblem(student, problem)