classdef DEXTER < matlab.apps.AppBase
    %%DEXTER is an app for grading custom assignment rubrics.



    %% Properties
    % App components visible to other code (and Command Window)
    properties (Access = public)
        % Main Grader Figure
        fig				        matlab.ui.Figure

        WelcomeContainer        matlab.ui.container.GridLayout
        WelcomeText		        matlab.ui.control.Label

        m_file			        matlab.ui.container.Menu
        m_file_new		        matlab.ui.container.Menu
        m_file_open		        matlab.ui.container.Menu
        m_file_save		        matlab.ui.container.Menu
        m_file_saveas	        matlab.ui.container.Menu
        m_file_enableAutoSave   matlab.ui.container.Menu
        m_file_settings	        matlab.ui.container.Menu

        m_edit                  matlab.ui.container.Menu
        m_edit_classlist        matlab.ui.container.Menu
        m_edit_usersettings     matlab.ui.container.Menu

        m_view			        matlab.ui.container.Menu
        m_view_sort
        m_view_sort_firstascend
        m_view_sort_firstdescend
        m_view_sort_lastascend
        m_view_sort_lastdescend
        m_view_increaseItem     matlab.ui.container.Menu
        m_view_decreaseItem     matlab.ui.container.Menu

        m_reports	            matlab.ui.container.Menu
        m_reports_class         matlab.ui.container.Menu
        
        m_export	            matlab.ui.container.Menu
        m_export_stu	        matlab.ui.container.Menu
        m_export_clipboard      matlab.ui.container.Menu
        m_export_markdown_clipboard matlab.ui.container.Menu
        m_export_all_txt	    matlab.ui.container.Menu
        m_export_all_pdf	    matlab.ui.container.Menu

        m_about                 matlab.ui.container.Menu
        m_about_version         matlab.ui.container.Menu
        m_about_help            matlab.ui.container.Menu

        MainGrid		        matlab.ui.container.GridLayout
        TopSubGrid		        matlab.ui.container.GridLayout
        TopGridRight	        matlab.ui.container.GridLayout
        RubricText		        matlab.ui.control.Label
        SectionText		        matlab.ui.control.Label
        TopGridLeft		        matlab.ui.container.GridLayout
        StudentDropdown
        StudentTotal	        matlab.ui.control.Label

        ItemMainGrid	        matlab.ui.container.GridLayout
        ItemHeaderGrid	        matlab.ui.container.GridLayout
        ItemProblemText         matlab.ui.control.Label
        ProblemList

        ItemGrid		        matlab.ui.container.GridLayout
        ItemSpins		        matlab.ui.control.Spinner
        ItemBtns		        matlab.ui.control.StateButton
        ItemParts		        matlab.ui.control.Label
        ItemTexts		        matlab.ui.control.Label
        ItemFBBtns              matlab.ui.control.Button

        % Aux Figures
        CRfig                   matlab.ui.Figure

    end

    % App-related settings and variables
    properties (Access = public)
        Debug = false;

        % Cached Configuration structure
        cfg     DexConfig = DexConfig()
        user    DexConfig = DexConfig()

        % Main Data Vars
        StTbl = []
        RubricFileName = []
        section = []

        % SaveFile Contains the path to the saved .mat state
        SaveFile = []

        Styles

    end
    properties (Access = public, Dependent)
        % Functional Vars
        % name of the student
        CurSt
        % name of problem
        CurProb
        % Read-Only of current student's rubric
        CurRubric

        NumStudents
        StudentNames
        NumProbs
        ProblemNames
        NumCriteria
        RubricName
        SaveFileName
        WindowBaseName

        PastComments
    end
    properties (Constant)

        version = "1.3.2"

        tooltips = struct(...
            "m_new",            "Start a new DEXTER Grader project", ...
            "m_open",           "Open an existing DEXTER Grader project", ...
            "m_save",           "Saves the existing project", ...
            "m_saveas",         "Saves the existing project to a new file",...
            "m_enableAutosave", ["[Checked] Changing the student or problem autosaves the file."; "[Unchecked] The user must explicitly save data to the file."],...
            "m_IncreaseItem",   "Icreases the font size of the problem criteria text",...
            "m_DecreaseItem",   "Decreases the font size of the problem criteria text",...
            "m_edit_classlist", "Opens a window to change the names of students.",...
            "m_classwide",      "Opens a new window showing a summary of class performance on the assignment",...
            "m_exportStudent",  ["Generate a grade printout for the selected student."; "You can specify .txt or .pdf when prompted for the file name."],...
            "m_exportStudentMarkdown", "Copies a Markdown report of the student to your clipboard to be pasted into a .md file.",...
            "m_exportAlltxt",   ["Select a folder to receive generated grade printouts for all students";"Generates .txt files."],...
            "m_exportAllpdf",   ["Select a folder to receive generated grade printouts for all students";"Generates .pdf files."])

        window_name = "DEXTER Grader"
        app_icon = "icon_dg_48x48.png"

        webHelpLink = "https://github.com/DevonLantagne/DEXTER-Grader/wiki"

    end

    %% CONSTRUCTOR

    methods (Access = public)
        function app = DEXTER(SaveStateFile)
            %DEXTER Runs the Dexter Grader app

            % First, check if we have a config file
            if app.Debug || ~exist(DEXTER.getConfigFile, "file")
                % No config! Assume a new user.
                % Creates appdata folders for config and autosaves
                DEXTER.FirstTimeSetup();
            end

            % Check if we have user settings file
            if ~exist(DEXTER.getUserSettingsFile, "file")
                DEXTER.InitUserSettings();
            end

            % Load Configuration File
            S = load(fullfile(DEXTER.getAppDataPath, "config.mat"));
            cfg = S.cfg;
            if isa(cfg, "struct")
                % Must rebuild config
                DEXTER.InitConfig()
                S = load(fullfile(DEXTER.getAppDataPath, "config.mat"));
                cfg = S.cfg;
            end
            app.cfg = cfg; clear S

            % Load User Settings File
            S = load(fullfile(DEXTER.getAppDataPath, "user.mat"));
            app.user = S.user; clear S

            % INIT the app components
            createBaseComponents(app)
            createMenubar(app)

            if nargin > 0
                % We are given a filepath to a saved state
                LoadState(app, SaveStateFile);
            end

            registerApp(app, app.fig)

            if nargout == 0
                clear app
            end
        end
    end

    %% GET Properties

    methods
        function out = get.CurSt(app)
            out = app.StudentDropdown.Value;
        end
        function out = get.CurProb(app)
            out = app.ProblemList.Value;
        end
        function out = get.CurRubric(app)
            out = app.StTbl{app.CurSt, "Rubric"}{1};
        end
        function out = get.NumStudents(app)
            out = height(app.StTbl); % fastest method
        end
        function out = get.StudentNames(app)
            % Student names are used to index into a table row name. So we
            % should pull names from the RowNames property to avoid issues.
            % Otherwise it is just the StudentName column from the table.
            out = string(app.StTbl.Properties.RowNames);
        end
        function out = get.NumProbs(app)
            out = length(app.ProblemNames);
        end
        function out = get.NumCriteria(app)
            [ProbName, CriteriaPerProblem] = unique(app.StTbl{1,"Rubric"}{1}.Problem, 'stable');
            CriteriaPerProblem = diff([CriteriaPerProblem; height(app.StTbl{1,"Rubric"}{1})+1]);
            out = CriteriaPerProblem(ProbName==app.CurProb);
        end
        function out = get.RubricName(app)
            out = extractBefore(app.RubricFileName, '.');
        end
        function out = get.ProblemNames(app)
            out = unique(app.StTbl{1,"Rubric"}{1}.Problem, 'stable');
        end
        function out = get.SaveFileName(app)
            if isempty(app.SaveFile)
                out = "";
            else
                [~, name, ext] = fileparts(app.SaveFile);
                out = string(name) + string(ext);
            end
        end
        function out = get.WindowBaseName(app)
            [~,name,ext] = fileparts(app.SaveFile);
            out = app.window_name + ": """ + name + ext + """";
        end
        function out = get.PastComments(app)
            % return unique comments within ALL student's rubric entries
            
            AllComments = [];
            CommentHeaderName = "Feedback";

            % Get current problem name to filter results
            ProbMask = app.CurProb == app.CurRubric.Problem;
            
            for st = 1:app.NumStudents
                % Get all comments for a student
                StComments = app.StTbl{st,"Rubric"}{1}{ProbMask,CommentHeaderName};
                % Remove empty comments
                StComments(StComments=="") = [];
                % Add to master list
                AllComments = [AllComments; StComments];
            end

            % Prune duplicate comments (and sort)
            out = unique(AllComments);

        end

    end

    %% Main GUI Callbacks

    methods (Access = private)

        function cb_New(app,~)
            app.NewSession(); % Launches modal subwindow
        end
        function cb_Open(app,~)
            [file,path] = uigetfile('*.dex',"Select a saved session to load", app.cfg.PathLastSaves);
            if isequal(file, 0) || isequal(path,0); return; end
            % First, check if this session is already opened
            ExpectedFigName = app.window_name + ": " + file;
            Allfigs = findall(groot,'type','figure');
            MatchMask = string({Allfigs.Name}) == ExpectedFigName;
            if any(MatchMask)
                % already exists
                figure(Allfigs(MatchMask)) % bring that figure into focus
                return
            end

            % We have an ongoing session?
            if isempty(app.SaveFile)
                % We had a blank DEXTER, populate with loaded state
                app.SaveFile = fullfile(path,file);
                LoadState(app, fullfile(path,file))
                figure(app.fig)
            else
                % We have an ongoing session, retain it and start a new
                % instance.
                DEXTER(fullfile(path,file)); % Make new instance
            end
        end
        function cb_save(app,~)
            SaveState(app, app.SaveFile)
        end
        function cb_saveas(app,~)
            [file, path] = uiputfile("*.dex", "Save session", ...
                fullfile(app.cfg.PathLastSaves, app.section + " " + app.RubricName + ".dex"));
            if isequal(file, 0) || isequal(path,0); return; end
            figure(app.fig)
            % Update "new" session
            app.SaveFile = fullfile(path,file);
            app.fig.Name = app.window_name + ": " + file;
            % Perform the save
            SaveState(app, fullfile(path,file))
        end
        function cb_AutosaveEnable(app,~)
            if strcmp(app.m_file_enableAutoSave.Checked, 'on')
                app.m_file_enableAutoSave.Checked = 'off';
            else
                app.m_file_enableAutoSave.Checked = 'on';
            end
        end
        function cb_changeClassList(app,~)
            app.EditClassList();
        end
        function cb_changeSettings(app,~)
            OpenSettings(app);
        end
        function cb_changeItemSize(app,event)
            NewFontSize = app.user.FontSizeBody + event.Source.UserData;
            if NewFontSize <= 1
                app.m_view_decreaseItem.Enable = 'off';
                return
            end
            app.m_view_decreaseItem.Enable = 'on';
            ChangeUserSetting(app, "FontSizeBody", NewFontSize)
            set(allchild(app.ItemGrid), "FontSize", NewFontSize)
            UpdateUI(app);
        end

        function cb_sortStudents(app, event)
            app.StTbl = sortrows(app.StTbl,...
                event.Source.UserData{1}, event.Source.UserData{2});
            app.StudentDropdown.Items = app.StudentNames;
        end
        function cb_gethelp(app, ~)
            web(app.webHelpLink);
        end

        function cb_change_student(app,~)
            UpdateUI(app);
            if strcmp(app.m_file_enableAutoSave.Checked, 'on')
                SaveState(app, app.SaveFile)
            end
        end
        function cb_change_problem(app,~)
            UpdateUI(app);
            if strcmp(app.m_file_enableAutoSave.Checked, 'on')
                SaveState(app, app.SaveFile)
            end
        end

        function cb_keypress(app, event)
            switch string(event.Key)
                case app.user.key_NextProblem
                    NextIndex = app.ProblemList.ValueIndex + 1;
                    if NextIndex > app.NumProbs; NextIndex = app.NumProbs; end
                    app.ProblemList.ValueIndex = NextIndex;
                    cb_change_problem(app, [])

                case app.user.key_PreviousProblem
                    NextIndex = app.ProblemList.ValueIndex - 1;
                    if NextIndex < 1; NextIndex = 1; end
                    app.ProblemList.ValueIndex = NextIndex;
                    cb_change_problem(app, [])

                case app.user.key_NextStudent
                    NextIndex = app.StudentDropdown.ValueIndex + 1;
                    if NextIndex > app.NumStudents; NextIndex = app.NumStudents; end
                    app.StudentDropdown.ValueIndex = NextIndex;
                    cb_change_student(app, [])

                case app.user.key_PreviousStudent
                    NextIndex = app.StudentDropdown.ValueIndex - 1;
                    if NextIndex < 1; NextIndex = 1; end
                    app.StudentDropdown.ValueIndex = NextIndex;
                    cb_change_student(app, [])

            end
        end

        function cb_change_score(app,event)
            % The event contains the object that called the callback.
            % We hid the row index in the User Data of the spinner and
            % state button. We can now update the core data and then
            % refresh the display.
            CriteriaID = event.Source.UserData;
            % Operate differently based on source type:
            switch event.Source.Type
                case "uistatebutton"
                    state = event.Source.Value;
                    MaxPts = str2double(event.Source.Text(2:end)); % ignores + symbol
                    NewPts = state * MaxPts;
                case "uispinner"
                    NewPts = event.Source.Value;
            end
            % Write the new score
            app.WriteScore(NewPts, CriteriaID)
            % Update
            UpdateUI(app)
        end
        function cb_FullNoCredit(app,event)
            % Change scores for all criteria items
            CriteriaIdList = app.CurRubric.CriteriaID(app.CurRubric.Problem == app.CurProb);
            for CriteriaIndex = CriteriaIdList'
                switch event.Source.UserData
                    case 0
                        app.WriteScore(0, CriteriaIndex)
                    case 1
                        % Max
                        MaxPts = app.CurRubric.CriteriaPoints(...
                            (app.CurRubric.CriteriaID == CriteriaIndex) & ...
                            (app.CurRubric.Problem == app.CurProb));
                        app.WriteScore(MaxPts, CriteriaIndex)
                end
            end
            UpdateUI(app)
        end
        function cb_addFB(app, event)  
            CritNum = event.Source.UserData; % Clicked criteria row
            app.ModifyFeedback(CritNum);
        end
        function cb_reportClass(app,~)
            ShowReport(app)
        end

        function cb_ExportStudentClipboard(app)
            app.Clipboard_StudentFB();
        end
        function cb_ExportStudentMarkdownClipboard(app)
            app.ClipboardMarkdown_StudentFB();
        end
        function cb_ExportStudent(app, ~)
            filter = {'*.pdf'; '*.txt'};
            ValidExtensions = extractAfter(string(filter), "*");
            [file,path] = uiputfile(filter, "Export student report", fullfile(app.getUserHomePath,app.CurSt));
            if isequal(file, 0); return; end
            figure(app.fig)
            % Determine export type:
            [~, ~, ext] = fileparts(file);
            method = string(ext);
            if ~ismember(method, ValidExtensions)
                % Not a valid extension.
                uialert(app.fig, {...
                    "Unable to export reports with the " + method " extension.",...
                    "Available formats are: " + join(ValidExtensions, ", ")},...
                    'Invalid File Extension');
                return
            end
            app.ExportStudent(app.StTbl(app.CurSt,:), fullfile(path,file), method)
        end
        function cb_ExportAll(app, event)
            DestFolder = uigetdir(app.getUserHomePath, "Select destination folder for all export files");
            if isequal(DestFolder, 0); return; end
            figure(app.fig)
            app.ExportStudent(app.StTbl, DestFolder, event.Source.UserData)
        end

        function cb_dexFigClose(app, ~)
            if isempty(app.SaveFile) || app.Debug
                delete(app.fig)
                return
            end
            SaveState(app, app.SaveFile)
            delete(app.fig)
        end
    end

    %% Internal Private Functions
    methods (Access = public)
        function LoadBaseData(app)
            % Used when loading data such as rubric and section text,
            % student list, and problem list

            % Figure Name
            app.fig.Name = app.WindowBaseName;
            % Update Assignment Summary
            app.RubricText.Text = app.RubricName;
            % Allocate item grid
            app.cfg.NumMaxItems = max(groupcounts(app.StTbl.Rubric{1}.Problem)) + 1;
            app.createCriteriaList();
            % Update Student List
            app.StudentDropdown.Items = app.StudentNames;
            app.StudentDropdown.Value = app.StudentNames(1);
            app.SectionText.Text = app.StTbl.Section(1);
            % Update Problem List
            app.ProblemList.Items = app.ProblemNames;
            app.ProblemList.Value = app.ProblemNames(1);

            app.MainGrid.Visible = "on";
            app.WelcomeContainer.Visible = "off";
            app.m_file_save.Enable = "on";
            app.m_file_saveas.Enable = "on";
            app.m_reports.Enable = "on";
            app.m_export.Enable = "on";
            app.m_file_enableAutoSave.Enable = "on";
            app.m_view.Enable = "on";
            app.m_edit.Enable = "on";

        end
        function SaveState(app, PathAndFilename)
            AppState.cfg = app.cfg;
            AppState.StTbl = app.StTbl;
            AppState.RubricFileName = app.RubricFileName;
            AppState.section = app.section;
            AppState.CurSt = app.CurSt;
            AppState.CurProb = app.CurProb;
            AppState.Ver = app.version;

            save(PathAndFilename, "AppState", "-mat")
        end
        function LoadState(app, PathAndFilename)
            dat = load(PathAndFilename, "-mat");

            AS = dat.AppState;
            if isa(AS.cfg, "struct")
                % Must rebuild config
                DEXTER.InitConfig()
                S = load(fullfile(DEXTER.getAppDataPath, "config.mat"));
                AS.cfg = S.cfg;
            end
            app.cfg = AS.cfg;
            app.StTbl = AS.StTbl;
            app.RubricFileName = AS.RubricFileName;
            app.section = AS.section;

            if ~isfield(AS, "Ver"); LoadedVersion = "1.1.0";
            else; LoadedVersion = AS.Ver;
            end

            % Repair cfg
            app.ValidateAppData(LoadedVersion);

            app.SaveFile = PathAndFilename;

            % Update UI
            LoadBaseData(app)
            app.StudentDropdown.Value = AS.CurSt;
            app.SectionText.Text = app.StTbl{AS.CurSt,"Section"};
            app.ProblemList.Value = AS.CurProb;
            UpdateUI(app)
        end

        function WriteScore(app, points, criteriaID)
            ItemMask = ...
                (app.CurRubric.Problem == app.CurProb) & ...
                (app.CurRubric.CriteriaID == criteriaID);
            app.StTbl{app.CurSt, "Rubric"}{1}.PointsEarned(ItemMask) = points;
            UpdateUI(app)
        end
        function tblRow = ReadScore(app, criteriaID)
            ItemMask = ...
                (app.CurRubric.Problem == app.CurProb) & ...
                (app.CurRubric.CriteriaID == criteriaID);
            tblRow = app.CurRubric(ItemMask, :);
        end

        function Clipboard_StudentFB(app)
            ThisTbl = app.StTbl(app.CurSt, :);
            ReportString = app.GenerateReportString(ThisTbl);
            clipboard('copy',ReportString)
        end
        function ClipboardMarkdown_StudentFB(app)
            ThisTbl = app.StTbl(app.CurSt, :);
            ReportString = app.GenerateReportStringMarkdown(ThisTbl);
            clipboard('copy',ReportString)
        end

        function ChangeConfig(app, field, value)
            if ~iscell(value)
                value = {value};
            end
            % Update RAM config
            for n = 1:length(field)
                app.cfg.(field(n)) = value{n};
            end
            % save ROM config
            cfg = app.cfg; %#ok<ADPROPLC>
            save(app.getConfigFile, "cfg")
        end
        function ChangeUserSetting(app, field, value)
            if ~iscell(value)
                value = {value};
            end
            for n = 1:length(field)
                app.user = app.user.ChangeProp(field(n), value{n});
            end
            user = app.user; %#ok<ADPROPLC>
            save(app.getUserSettingsFile, "user")
        end

        function LG = GetLetterGrade(app,score)
            % scale is a table with two columns: ["Letter","LowerScore"]
            LG = strings(size(score));
            for n = 1:length(score)
                idx = find(score(n) >= app.cfg.grade_scale.LowerScore, 1, 'first');
                if isempty(idx)
                    LG(n) = "";
                else
                    LG(n) = app.cfg.grade_scale.Letter(idx);
                end
            end
        end

    end

    %% Static DEXTER
    methods (Access = public, Static)
        function FirstTimeSetup()
            % Init the DEXTER app data folder
            if ~isfolder(DEXTER.getAppDataPath); mkdir(DEXTER.getAppDataPath); end
            %if ~isfolder(DEXTER.getAutoSavePath); mkdir(DEXTER.getAutoSavePath); end

            % generates and saves a config file
            DEXTER.InitConfig();
            % Gen and save user settings
            DEXTER.InitUserSettings();
        end
        function InitConfig()
            cfg = DEXTER.getDefaultConfigSettings();
            save(DEXTER.getConfigFile, "cfg")
        end
        function InitUserSettings()
            user = DEXTER.getDefaultUserSettings();
            save(DEXTER.getUserSettingsFile, "user")
        end

        function tbl = ReadClassList(filename)
            [~, ~, extension] = fileparts(filename);
            extension = string(extension);

            % Default Class List Format:
            %   First Name, Last Name, MSOE ID, Section, Email, Major, Level, Notes
            Def_tbl = table('Size', [1,8], 'VariableTypes', ...
                ["string", "string", "uint32", "string", "string", "string", "string", "string"],...
                'VariableNames', ["FirstName", "LastName", "MSOEID", "Section", "Email", "Major", "Level", "Notes"]);

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
                    [tbl.Major, tbl.Level, tbl.Notes] = deal(strings(height(RawTbl), 1));
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
                    tbl.Notes =     strings(height(RawTbl), 1);
                    % Parse special info
                    for n = 1:height(RawTbl)
                        NameParts = split(RawTbl.Student(n), ", ");
                        tbl.FirstName(n) = NameParts(2);
                        tbl.LastName(n) = NameParts(1);
                    end
                    tbl.Properties.RowNames = tbl.FirstName + " " + tbl.LastName;

            end
        end
        function [RubTbl, msg] = GetRubricTable(FileName)
            % Read rubric sheet
            % Expects (6) columns: Problem, ProblemWeight, CriteriaPoints,
            % Part, CriteriaName, and CriteriaDescription.

            warning('off','MATLAB:table:ModifiedAndSavedVarnames')
            opts = detectImportOptions(FileName);
            % Check class type for SpreadsheetImportOptions class
            %opts = opts.setvartype({'Problem', 'Part', 'CriteriaName', 'CriteriaDescription'}, 'string');

            RubTbl = readtable(FileName, opts);
            warning('on','MATLAB:table:ModifiedAndSavedVarnames')

            % Clean and expand table
            [pass, data] = DEXTER.ConditionNewRubricTable(RubTbl);

            if pass
                RubTbl = data;
                msg = "";
            else
                % If we get here, we didn't pass. Throw error. data contains
                % error string.
                RubTbl = [];
                msg = data;
            end
        end
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

            % Create Criteria IDs
            NumProbs = length(ProbNames);
            data.CriteriaID(:) = NaN; % Creates new NaN column
            for p = 1:NumProbs
                NumCriteria = sum(data.ProblemID == p, 'omitnan');
                data{data.ProblemID == p, "CriteriaID"} = (1:NumCriteria)';
            end

            data.PointsEarned = zeros(height(data), 1);

            data.Feedback = strings(height(data), 1);
            
            pass = true;
        end
        function OutTbl = ExpandTable(StudentTbl)
            % Reformats (pivots) the rubric table into a giant row.
            % Column names are renamed into Q# and C#

            % Pull first rubric (they should all be the same) and create new output
            % table from old StudentTbl
            RepRub = StudentTbl{1, "Rubric"}{1};
            ProblemPercs = "Q" + (1:max(RepRub.ProblemID))' + "%: " + unique(RepRub.Problem, 'stable');
            ProblemCodes = compose("Q%dC%d", RepRub.ProblemID, RepRub.CriteriaID);

            OutTbl = StudentTbl;
            OutTbl.Rubric = [];

            EmptyProblemTbl = array2table(NaN(height(OutTbl), length(ProblemPercs)), ...
                'VariableNames', ProblemPercs);
            EmptyRubTbl = array2table(NaN(height(OutTbl), length(ProblemCodes)),...
                'variablenames', ProblemCodes);

            OutTbl = [OutTbl, EmptyProblemTbl, EmptyRubTbl];

            % For each student, pivot the table
            for st = 1:height(StudentTbl)
                RepRub = StudentTbl{st, "Rubric"}{1};
                ItemScores = RepRub.PointsEarned';
                PtsPerProb = NaN(1,length(ProblemPercs));
                for p = 1:length(ProblemPercs)
                    PtsPerProb(p) = 100 * sum(RepRub.PointsEarned(RepRub.ProblemID==p)) / ...
                        sum(RepRub.CriteriaPoints(RepRub.ProblemID==p));
                end
                OutTbl{st, ProblemPercs} = PtsPerProb;
                OutTbl{st, ProblemCodes} = ItemScores;
            end
        end

        function out = getAppDataPath()
            if ispc()
                out = fullfile(getenv("APPDATA"), "DEXTER"); % Roaming
            elseif ismac()
                out = fullfile(getenv("HOME"), "Library", "Application Support", "Dexter");
            elseif isunix() % linux
                home = getenv("HOME");

                xdg_data = getenv("XDG_DATA_HOME"); % Check if XDG is active
                if isempty(xdg_data)
                    % Fall back to default
                    xdg_data = fullfile(home, ".local", "share");
                end
                
                out = fullfile(xdg_data, "dexter");
            else
                warning("Unknown OS. Saving app data to current directory");
                out = pwd;
            end
        end
        function out = getUserHomePath()
            if ispc()
                out = fullfile(getenv("HOMEPATH"), "DEXTER");
                %LOCALAPPDATA
            elseif ismac()
                out = fullfile(getenv("HOME"), "DEXTER");
            elseif isunix()
                out = getenv("HOME");
            else
                out = pwd;
            end
        end
        function out = getConfigFile()
            out = fullfile(DEXTER.getAppDataPath, "config.mat");
        end
        function out = getUserSettingsFile()
            out = fullfile(DEXTER.getAppDataPath, "user.mat");
        end
        function out = getAutoSavePath()
            out = fullfile(DEXTER.getAppDataPath, "Autosaves");
        end
    end

    %% Public Tools
    methods (Access = public, Static)

        function out = GetGraphicsPath()
            % Returns the path to find graphics files depending on dev or prod environment
        % 
        % In development: returns relative path from src folder
        % In deployed mode: uses 'which' to locate files in ctfroot
        
        if isdeployed
            % Try to find a specific graphics file (e.g., icon.png) using which()
            % which() is more reliable for files in the deployable archive
            graphicsFile = which(DEXTER.app_icon);
            
            if ~isempty(graphicsFile)
                % Extract directory from the full path
                out = fileparts(graphicsFile);
            else
                % Fallback to ctfroot if which() doesn't work
                out = fullfile(ctfroot);
            end
        else
            % Development mode
            out = fullfile(pwd, 'build', 'graphics');
        end
        end

        function path = DexterPath()
            % Returns the file location of this file
            MyLoc = string(mfilename('fullpath'));  % Get path to this .m file
            [path,~,~] = fileparts(MyLoc);
        end

        function usrSet = getDefaultUserSettings(opts)
            arguments
                opts.Instructor = "";
                opts.Font = "Helvetica";
                opts.FontSize_Titles = 20;
                opts.FontSize_Body = 18;
            end

            usrSet = DexConfig();

            usrSet = usrSet.AddProp("Instructor", opts.Instructor, ...
                "type", "text", "label", "Instructor's Name", "family", "General");

            usrSet = usrSet.AddProp("Font", opts.Font, ...
                "type", "list", "label", "Font Name", "family", "Font",...
                "list", string(listfonts));
            usrSet = usrSet.AddProp("FontSizeHeader", opts.FontSize_Titles, ...
                "type", "num", "label", "Header Font Size", "family", "Font");
            usrSet = usrSet.AddProp("FontSizeBody", opts.FontSize_Body, ...
                "type", "num", "label", "Body Font Size", "family", "Font");

            usrSet = usrSet.AddProp("key_NextProblem", "rightarrow", ...
                "type", "text", "label", "Next Problem", "family", "Keyboard");
            usrSet = usrSet.AddProp("key_PreviousProblem", "leftarrow", ...
                "type", "text", "label", "Previous Problem", "family", "Keyboard");
            usrSet = usrSet.AddProp("key_NextStudent", "downarrow", ...
                "type", "text", "label", "Next Student", "family", "Keyboard");
            usrSet = usrSet.AddProp("key_PreviousStudent", "uparrow", ...
                "type", "text", "label", "Previous Student", "family", "Keyboard");

        end
        function cfg = getDefaultConfigSettings(opts)
            arguments
                % Filesystem history
                opts.PathLastSelected = "";
                opts.PathLastClasslist = "";
                opts.PathLastRubric = "";
                opts.PathLastSaves = "";

                % Window Size - percentage of screen space for width and height
                opts.window_size = [0.5 0.9];

                % Ui Components
                opts.NumMaxItems = 15;

                % The lower bounds of each letter grade
                opts.grade_scale = cell2table({
                    "A",    93;
                    "AB",   89;
                    "B",    85;
                    "BC",   81;
                    "C",    77;
                    "CD",   74;
                    "D",    70;
                    "F",     0}, "VariableNames", ["Letter","LowerScore"]);

            end

            cfg = DexConfig();

            cfg = cfg.AddProp("PathLastSelected", opts.PathLastSelected, "type", "text");
            cfg = cfg.AddProp("PathLastClasslist", opts.PathLastClasslist, "type", "text");
            cfg = cfg.AddProp("PathLastRubric", opts.PathLastRubric, "type", "text");
            cfg = cfg.AddProp("PathLastSaves", opts.PathLastSaves, "type", "text");

            cfg = cfg.AddProp("window_size", opts.window_size, "type", "num");

            cfg = cfg.AddProp("NumMaxItems", opts.NumMaxItems, "type", "num");

            cfg = cfg.AddProp("grade_scale", opts.grade_scale, "type", "table");

        end

    end
end

