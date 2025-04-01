classdef Rubric
    %RUBRIC Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Name
        tbl
        NextItemID = 1
        NumDataColumns

        grade_scale = cell2table({
            "A",    93;
            "AB",   89;
            "B",    85;
            "BC",   81;
            "C",    77;
            "CD",   74;
            "D",    70;
            "F",     0}, "VariableNames", ["Letter","LowerScore"]);
    end

    properties (Dependent = true)
        NumStudents
        StudentNames
        ProblemNames
        NumProbs
    end

    %% Constructor
    methods
        function obj = Rubric()
            if nargin == 0
                return
            end
        end
    end

    %% GET Methods
    methods
        function out = get.NumStudents(obj)
            if isempty(obj.tbl); out = 0; return; end
            out = length(obj.StudentNames);
        end
        function out = get.StudentNames(obj)
            if isempty(obj.tbl); out = ""; return; end
            out = string(obj.tbl.Properties.VariableNames);
            out = out((obj.NumDataColumns+1):end);
        end
        function out = get.ProblemNames(obj)
            if isempty(obj.tbl); out = ""; return; end
            out = unique(obj.tbl.Problem, 'stable');
        end
        function out = get.NumProbs(obj)
            if isempty(obj.tbl); out = 0; return; end
            out = length(obj.ProblemNames);
        end
    end

    %% Public Methods
    methods (Access=public)
        % Loading Rubrics and Students
        function [obj, msg] = LoadRubricTable(obj, FileName)
            % Read rubric sheet
            % Expects (6) columns: Problem, ProblemWeight, CriteriaPoints,
            % Part, CriteriaName, and CriteriaDescription.

            warning('off','MATLAB:table:ModifiedAndSavedVarnames')
            opts = detectImportOptions(FileName);
            RubTbl = readtable(FileName, opts);
            warning('on','MATLAB:table:ModifiedAndSavedVarnames')

            % Clean and expand table
            [pass, data] = Rubric.ConditionNewRubricTable(RubTbl);

            if pass
                obj.tbl = data;
                obj.NextItemID = max(data.ItemID) + 1;
                obj.NumDataColumns = width(data);
                msg = "";
            else
                % If we get here, we didn't pass. Throw error. data contains
                % error string.
                msg = data;
            end
        end
        function obj = LoadStudentList(obj, FileName)
            % Loads a .csv file from Canvas or an .xls file from myMSOE
            studentTbl = obj.ReadClassList(FileName);
            % Cycle through each student and add them to master table
            for st = 1:height(studentTbl)
                thisSt = studentTbl(st,:);
                obj = obj.AddStudent(thisSt.FirstName + " " + thisSt.LastName,...
                    "email", thisSt.Email,...
                    "id", thisSt.MSOEID,...
                    "level", thisSt.Level,...
                    "major", thisSt.Major,...
                    "section", thisSt.Section);
            end
        end
        function obj = AddStudent(obj, studentName, opts)
            arguments
                obj Rubric
                studentName string
                opts.section string = ""
                opts.id double = 0
                opts.major string = ""
                opts.level string = ""
                opts.email string = ""
            end
            if any(string(obj.tbl.Properties.VariableNames) == studentName)
                return
            end
            % For every student, add a column to the rubric with two
            % subcolumns: points earned and feedback
            subtbl = table(zeros(height(obj.tbl),1), strings(height(obj.tbl),1), ...
                'VariableNames', ["PointsEarned", "Feedback"]);
            % Add student metadata to table column
            subtbl.Properties.UserData = opts;
            % Append student's subtable to master table
            obj.tbl.(studentName) = subtbl;
        end
        function obj = RemoveStudent(obj, studentName)
            if any(obj.StudentNames == studentName)
                obj.tbl.(studentName) = [];
            end
        end
        
        % Information gathering
        function info = GetStudentInfo(obj, student)
            % Returns a structure of student info
            %   Problem info uses same index as order of problems
            if ~any(obj.StudentNames == student)
                info = [];
                return
            end
            % Start with metadata
            info = obj.tbl.(student).Properties.UserData;
            info.name = student;
            
            % Compile info for each problem:
            % Init across-problem stats:
            Total = 0;
            for prob = 1:obj.NumProbs
                ThisProbName = obj.ProblemNames(prob);
                probMask = ThisProbName == obj.tbl.Problem;
                % Get criteria points and student scores
                critPoints = obj.tbl(probMask, "CriteriaPoints");
                studentPoints = obj.tbl(probMask, student).PointsEarned;
                % Stats
                TotalPoints = sum(critPoints);
                TotalEarned = sum(studentPoints, 'omitmissing');
                TotalPerc = 100*TotalEarned/TotalPoints;
                LetterGrade = obj.GetLetterGrade(TotalPerc);
                % Package into structure
                info.probs(prob).Name = ThisProbName;
                info.probs(prob).Weight = obj.tbl.ProblemWeight( find(probMask, 1, 'first') );
                info.probs(prob).TotalPoints = TotalPoints;
                info.probs(prob).TotalEarned = TotalEarned;
                info.probs(prob).TotalPerc = TotalPerc;
                info.probs(prob).LetterGrade = LetterGrade;
                Total = Total + info.probs(prob).Weight * TotalPerc;
            end
            info.Total = Total;
            info.TotalLetterGrade = GetLetterGrade(Total);
            
        end
        function LG = GetLetterGrade(obj,score)
            % scale is a table with two columns: ["Letter","LowerScore"]
            LG = strings(size(score));
            for n = 1:length(score)
                idx = find(score(n) >= obj.grade_scale.LowerScore, 1, 'first');
                if isempty(idx)
                    LG(n) = "";
                else
                    LG(n) = obj.grade_scale.Letter(idx);
                end
            end
        end
        function points = GetCriteriaPoints(obj, itemID)
            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("GetCriteriaPoints: itemID (%d) does not exist.", itemID)
            end
            points = obj.tbl.CriteriaPoints(RowNum);
        end

        % Data Manipulation
        function score = GetScore(obj, student, itemID)
            arguments
                obj Rubric
                student string
                itemID double
            end
            % Error checks (student and ID)
            if ~any(obj.StudentNames == student)
                error("GetScore: student %s does not exist.", student)
            end
            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("GetScore: itemID (%d) does not exist.", itemID)
            end
            % get score from table
            score = obj.tbl.(student).PointsEarned(RowNum);
        end
        function feedback = GetFeedback(obj, student, itemID)
            arguments
                obj Rubric
                student string
                itemID double
            end
            % Error checks (student and ID)
            if ~any(obj.StudentNames == student)
                error("GetFeedback: student %s does not exist.", student)
            end
            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("GetFeedback: itemID (%d) does not exist.", itemID)
            end
            % get fb from table
            feedback = obj.tbl.(student).Feedback(RowNum);
        end
        function obj = ChangeScore(obj, student, itemID, score)
            % NO PROTECTIONS for scores below zero or above max points
            %   This allows for penalties and extra credit implementations.
            arguments
                obj Rubric
                student string
                itemID double
                score double
            end
            % Error checks (student and ID)
            if ~any(obj.StudentNames == student)
                error("ChangeScore: student %s does not exist.", student)
            end
            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("ChangeScore: itemID (%d) does not exist.", itemID)
            end
            % write score to table
            obj.tbl.(student).PointsEarned(RowNum) = score;
        end
        function obj = ChangeFB(obj, student, itemID, feedback)
            arguments
                obj Rubric
                student string
                itemID double
                feedback string
            end
            % Error checks (student and ID)
            if ~any(obj.StudentNames == student)
                error("ChangeFB: student %s does not exist.", student)
            end
            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("ChangeFB: itemID (%d) does not exist.", itemID)
            end
            % write feedback to table
            obj.tbl.(student).Feedback(RowNum) = feedback;
        end
    
        % Rubric-wide Manipulation
        function obj = ChangeRubricCriteriaPoints_GUI(obj, itemID)
            % A GUI frontend for the ChangeRubricCriteriaPoints method.

            TitleFontSize = 16;
            TextFontSize = 14; % includes button size
            WindowSize = [400 400];

            thisfig = uifigure(...
                'visible',      'off',...
                'windowstyle',  'modal',...
                'name',         "Change Criteria Points",...
                'position',     [0 0 WindowSize],...
                'resize',       'off',...
                'AutoResizeChildren', 'off',...
                'Icon',         fullfile('Graphics','iconLarge.png'));

            OldUnits = thisfig.Units;
            thisfig.Units = "pixels";
            %AppPos = app.Position;
            thisfig.Units = OldUnits;
            % Reposition this figure to be on top of app figure
            %movegui(thisfig, [AppPos(1)+(AppPos(3)-WindowSize(1))/2, AppPos(2)+(AppPos(4)-WindowSize(2))/2])
            movegui(thisfig, 'center')

            

            

        end
        function obj = ChangeRubricCriteriaPoints(obj, itemID, newScore, method)
            % Method used to change the CriteriaPoints field during
            % grading.
            arguments
                obj Rubric
                itemID double
                newScore double
                method string
            end

            RowNum = find(obj.tbl.ItemID == itemID);
            if isempty(RowNum)
                error("ChangeRubricCriteriaPoints: itemID (%d) does not exist.", itemID)
            end
            tempScores = NaN(1,obj.NumStudents);
            oldScores = tempScores;
            for st_ind = 1:obj.NumStudents
                st = obj.StudentNames(st_ind);
                oldScores(st_ind) = obj.tbl.(st).PointsEarned(RowNum);
            end

            switch method
                case "scale"
                    % Scales existing scores to the new criteria:
                    %   Full scores remain full scores.
                    %   Zeros remain zeros.
                    %   Partial credit is scaled proportionally.
                    tempScores = (oldScores / obj.tbl.CriteriaPoints(RowNum)) * newScore;

                case "scale_ceil"
                    % Same procedure as scale but rounds the score up to
                    % the nearest integer.
                    tempScores = (oldScores / obj.tbl.CriteriaPoints(RowNum)) * newScore;
                    tempScores = ceil(tempScores);

                case "scale_floor"
                    % Same procedure as scale but rounds the score down to
                    % the nearest interger.
                    tempScores = (oldScores / obj.tbl.CriteriaPoints(RowNum)) * newScore;
                    tempScores = floor(tempScores);

                case "ignore"
                    % Already graded scores will not be changed
                    %   If points increased, everyone will have missing
                    %   points.
                    %   If points decreased, full-credit scores will have
                    %   EXTRA credit.
                    return
                
                case "absolute"
                    % Gives/takes points equal to the difference between
                    % previous and new score.
                    %   Full scores remain full scores.
                    %   Zeros get the added points for free.
                    %   Partial credit gets free points.
                    tempScores = oldScores - obj.tbl.CriteriaPoints(RowNum) + newScore;
                    tempScores(tempScores<0) = 0; % limit to no less than zero

                case "reset"
                    % All grades are reset back to zero for a full regrade.
                    tempScores = oldScores * 0;

                otherwise
                    % Not an option
                    return
            end

            % Apply temp scores
            for st_ind = 1:obj.NumStudents
                st = obj.StudentNames(st_ind);
                obj.tbl.(st).PointsEarned(RowNum) = tempScores(st_ind);
            end
            % Update highest points
            obj.tbl.CriteriaPoints(RowNum) = newScore;

        end
        function [OutPerc, CriteriaPoints] = PercGrid(obj)
            % Provides a numeric array of criteria percentages with each
            % row being a criteria item and each column being a student.
            % These data can be used for a heat-map.
            
            data = NaN(height(obj.tbl), obj.NumStudents);
            % For all students, extract their scores and save to standard
            % numeric array.
            for ind = 1:obj.NumStudents
                st = obj.StudentNames(ind);
                data(:,ind) = obj.tbl.(st).PointsEarned ./ obj.tbl.CriteriaPoints;
            end

            if nargout == 1
                OutPerc = data;
            elseif nargout == 2
                OutPerc = data;
                CriteriaPoints = obj.tbl.CriteriaPoints;
            end
        end
    end

    %% Static Methods
    methods (Static)
        function [pass, data] = ConditionNewRubricTable(testTbl)
            ColumnNames = string(testTbl.Properties.VariableNames);

            % Clean and expand table

            % Remove empty rows
            data = rmmissing(testTbl,'DataVariables',"CriteriaName");

            % Enfore string data types for required columns
            data.CriteriaName = string(data.CriteriaName);

            % Condition Problem Weights (normalize them)
            % First, check to make sure we have one weight per problem:
            MismatchMask = xor( isnan(data.ProblemWeight),  data.Problem == "" );
            if any(MismatchMask)
                pass = false;
                data = "Problem names and Problem Weights must be defined on the same row.";
                return
            end
            data.ProblemWeight = data.ProblemWeight / sum(data.ProblemWeight, 'omitnan'); % Normalize to percentage of total grade
            data.ProblemWeight = fillmissing(data.ProblemWeight, "previous");

            % Augment Problem column to have redundant problem names
            data.Problem = fillmissing(data.Problem, "previous"); % empty char arrays '' are considered missing, but empty strings "" are not!
            data.Problem = string(data.Problem); % Convert to strings AFTER the fillmissing

            % Create Problem IDs based on unique problem names
            [ProbNames, ~, IDs] = unique(data.Problem, 'stable');
            data.ProblemID = IDs;

            % Condition Part
            % It it doesn't exist, add it. Otherwise fill empty cells with
            % blank strings ""
            if ismember("Part", ColumnNames)
                data.Part = string(data.Part);
                data.Part = fillmissing(data.Part, "constant", "");
            else
                data.Part = repmat("",height(data),1);
            end

            % Condition CriteriaDescription
            if ismember("CriteriaDescription", ColumnNames)
                data.CriteriaDescription = string(data.CriteriaDescription);
                data.CriteriaDescription = fillmissing(data.CriteriaDescription, "constant", "");
            else
                data.CriteriaDescription = repmat("", height(data), 1);
            end

            % Create Criteria IDs (within problem)
            NumProbs = length(ProbNames);
            data.CriteriaID(:) = NaN; % Creates new NaN column
            for p = 1:NumProbs
                NumCriteria = sum(data.ProblemID == p, 'omitnan');
                data{data.ProblemID == p, "CriteriaID"} = (1:NumCriteria)';
            end

            % Create item IDs
            data.ItemID = (1:height(data))';
            
            pass = true;
        end
        function tbl = ReadClassList(filename)
            [~, ~, extension] = fileparts(filename);
            extension = string(extension);

            % Default Class List Format:
            %   First Name, Last Name, MSOE ID, Section, Email, Major, Level, Notes
            Def_tbl = table('Size', [1,7], 'VariableTypes', ...
                ["string", "string", "uint32", "string", "string", "string", "string"],...
                'VariableNames', ["FirstName", "LastName", "MSOEID", "Section", "Email", "Major", "Level"]);

            switch extension
                case ".csv"
                    % From Canvas
                    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
                    % Read base table
                    RawTbl = readtable(filename, ...
                        "NumHeaderLines", 0, ...
                        "TextType", "string", ...
                        "VariableNamingRule", "modify");
                    warning('on','MATLAB:table:ModifiedAndSavedVarnames')
                    % Clone default for number of students
                    tbl = repmat(Def_tbl, height(RawTbl), 1);
                    % Parse whole columns:
                    tbl.MSOEID =    RawTbl.StudentSISID;
                    tbl.Section =   RawTbl.SectionName;
                    tbl.Email =     RawTbl.Email;
                    [tbl.Major, tbl.Level] = deal(strings(height(RawTbl), 1));
                    % Parse special info
                    for n = 1:height(RawTbl)
                        NameParts = split(RawTbl.StudentName(n), " ");
                        tbl.FirstName(n) = NameParts(1);
                        tbl.LastName(n) = join(NameParts(2:end), " ");
                    end
                    tbl.Properties.RowNames = tbl.FirstName + " " + tbl.LastName;

                case [".xls", ".xlsx"]
                    % From MyMSOE
                    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
                    RawTbl = readtable(filename, ...
                        "NumHeaderLines", 1, ...
                        "TextType", "string", ...
                        "VariableNamingRule", "modify");
                    Header = readcell(filename, "texttype", "string","range", "A1:A1");
                    Header = Header{:};
                    HeaderInfo = split(Header, " | ");
                    SectionName = HeaderInfo(3);
                    warning('on','MATLAB:table:ModifiedAndSavedVarnames')
                    % Clone default for number of students
                    tbl = repmat(Def_tbl, height(RawTbl), 1);
                    % Parse whole columns:
                    tbl.MSOEID =    RawTbl.StudentID;
                    tbl.Section =   repmat(SectionName, height(RawTbl), 1);
                    tbl.Email =     RawTbl.Email;
                    tbl.Major =     RawTbl.Major;
                    tbl.Level =     RawTbl.Class;
                    tbl.Level = fillmissing(tbl.Level, "constant", "");
                    % Parse special info
                    for n = 1:height(RawTbl)
                        NameParts = split(RawTbl.Student(n), ", ");
                        tbl.FirstName(n) = NameParts(2);
                        tbl.LastName(n) = NameParts(1);
                    end
                    tbl.Properties.RowNames = tbl.FirstName + " " + tbl.LastName;
            end
        end
        
    end
end

