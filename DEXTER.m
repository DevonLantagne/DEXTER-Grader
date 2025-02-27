classdef DEXTER < matlab.apps.AppBase
    %%DEXTER is an app for grading custom assignment rubrics.


    %% Record of Revisions
    % 1.1.0:
    %   - Redesigned the New  select multiple sections when creating a new project.
    %   - The "Export" menu is now "Grade Printouts" and allows
    %   experimental PDF printouts.
    %   - Added keybinds for changing students and problems
    %
    % 1.2.0:
    %   - Import class list via myMSOE and Canvas
    %       - Importing a class list now separates first and last names.
    %       - Canvas does not separate first/last names, so DEXTER guesses.
    %       - Can view and edit the class list from the menubar.
    %   - New Settings Panel
    %       - The new home for any user preferences
    %       - Change font sizes
    %       - Change keyboard shortcuts (primitive)
    %   - Sorting
    %       - You can now sort students by first/last name.
    %   - Added a Help menu item to bring you to the Teams User Guide.
    %   - This update will wipe your previous user settings.
    %   - This update is backwards compatible with previous saved projects.
    %  
    % 1.2.1:
    %   - Minor wording changes for clarity when loading class lists.
    %   - Fixed a bug when using MyMSOE for class list imports.
    %
    % 1.3.0:
    %   
    %   
    %   


    %% Properties
    % App components visible to other code (and Command Window)
    properties (Access = public)
        % Main Grader Figure
        fig				    matlab.ui.Figure

        WelcomeContainer    matlab.ui.container.GridLayout
        WelcomeText		    matlab.ui.control.Label

        m_file			    matlab.ui.container.Menu
        m_file_new		    matlab.ui.container.Menu
        m_file_open		    matlab.ui.container.Menu
        m_file_save		    matlab.ui.container.Menu
        m_file_saveas	    matlab.ui.container.Menu
        m_file_enableAutoSave matlab.ui.container.Menu
        m_file_settings	    matlab.ui.container.Menu

        m_edit              matlab.ui.container.Menu
        m_edit_classlist    matlab.ui.container.Menu
        m_edit_usersettings matlab.ui.container.Menu

        m_view			    matlab.ui.container.Menu
        m_view_sort
        m_view_sort_firstascend
        m_view_sort_firstdescend
        m_view_sort_lastascend
        m_view_sort_lastdescend
        m_view_increaseItem matlab.ui.container.Menu
        m_view_decreaseItem matlab.ui.container.Menu

        m_reports	        matlab.ui.container.Menu
        m_reports_class     matlab.ui.container.Menu

        m_export_stu	    matlab.ui.container.Menu
        m_export_all_txt	matlab.ui.container.Menu
        m_export_all_pdf	matlab.ui.container.Menu

        m_about             matlab.ui.container.Menu
        m_about_version     matlab.ui.container.Menu
        m_about_help        matlab.ui.container.Menu

        MainGrid		    matlab.ui.container.GridLayout
        TopSubGrid		    matlab.ui.container.GridLayout
        TopGridRight	    matlab.ui.container.GridLayout
        RubricText		    matlab.ui.control.Label
        SectionText		    matlab.ui.control.Label
        TopGridLeft		    matlab.ui.container.GridLayout
        StudentDropdown
        StudentTotal	    matlab.ui.control.Label

        ItemMainGrid	    matlab.ui.container.GridLayout
        ItemHeaderGrid	    matlab.ui.container.GridLayout
        ItemProblemText     matlab.ui.control.Label
        ProblemList

        ItemGrid		    matlab.ui.container.GridLayout
        ItemSpins		    matlab.ui.control.Spinner
        ItemBtns		    matlab.ui.control.StateButton
        ItemParts		    matlab.ui.control.Label
        ItemTexts		    matlab.ui.control.Label

        % Aux Figures
        CRfig               matlab.ui.Figure

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
    end
    properties (Constant)

        version = "1.3.0"

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
            "m_exportAlltxt",   ["Select a folder to receive generated grade printouts for all students";"Generates .txt files."],...
            "m_exportAllpdf",   ["Select a folder to receive generated grade printouts for all students";"Generates .pdf files.";"";"EXPERIMENTAL: Formatting issues may occur.";"Connecting an external monitor may help."])

        window_name = "DEXTER Grader"

        webHelpLink = "https://msoe365.sharepoint.com/:b:/r/sites/DEXTERGraderDevelopment-Community/Shared%20Documents/General/Docs%20and%20Tutorials/User%20Guide.pdf?csf=1&web=1&e=5t3pdU"

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
        function cb_reportClass(app,~)
            ShowReport(app)
        end

        function cb_ExportStudent(app, ~)
            filter = {'*.txt';'*.pdf'};
            ValidExtensions = extractAfter(string(filter), "*");
            %filter = {'*.txt'};
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
            app.m_file_enableAutoSave.Enable = "on";
            app.m_view.Enable = "on";
            app.m_edit_classlist.Enable = "on";

        end
        function UpdateUI(app)
            % Must update the entire UI:
            UpdateText(app)
            UpdateTotalScore(app)
            UpdateProblemScore(app)
            UpdateAllItems(app)
            drawnow

            function UpdateText(app)
                % Text Data
                app.StudentDropdown.Items = app.StudentNames;
                % Text Fonts and sizes
                set(findobj(app.fig, 'tag', 'Header'), ...
                    "fontsize", app.user.FontSizeHeader, "fontname", app.user.Font)
                set(findobj(app.fig, "tag", "Body"), ...
                    "fontsize", app.user.FontSizeBody, "fontname", app.user.Font)
            end
            function UpdateTotalScore(app)
                StudentsRubric = app.CurRubric;
                % Get problem weight from each criteriaID (first entry)
                ProblemWeights = StudentsRubric.ProblemWeight(StudentsRubric.CriteriaID==1);
                % Form the weighted sum of probems
                total = 0;
                for p = 1:app.NumProbs
                    TotalPoints = sum(StudentsRubric{StudentsRubric.ProblemID==p, "CriteriaPoints"});
                    EarnedPoints = sum(StudentsRubric{StudentsRubric.ProblemID==p, "PointsEarned"}, 'omitnan');
                    PercPoints = 100*EarnedPoints/TotalPoints;
                    total = total + PercPoints * ProblemWeights(p);
                end
                LG = app.GetLetterGrade(total);
                % Update Gradebook
                app.StTbl{app.CurSt, "ScorePerc"} = total;
                app.StTbl{app.CurSt, "GradeLetter"} = LG;
                % Update GUI
                app.StudentTotal.Text = sprintf("%.1f%%  %s", total, LG);
                app.SectionText.Text = app.StTbl{app.CurSt,"Section"};
            end
            function UpdateProblemScore(app)
                StudentsRubric = app.CurRubric;
                TotalPoints = sum(StudentsRubric{StudentsRubric.Problem==app.CurProb, "CriteriaPoints"});
                EarnedPoints = sum(StudentsRubric{StudentsRubric.Problem==app.CurProb, "PointsEarned"}, 'omitnan');
                PercPoints = 100*EarnedPoints/TotalPoints;
                LG = app.GetLetterGrade(PercPoints);
                app.ItemProblemText.Text = sprintf("%4.1f / %4.1f = %5.1f%%  %s",...
                    EarnedPoints, TotalPoints, PercPoints, LG);
            end
            function UpdateAllItems(app)
                partStrings = app.CurRubric.Part(app.CurRubric.Problem == app.CurProb);
                if all(app.CurRubric.Part(app.CurRubric.Problem == app.CurProb) == "")
                    app.ItemGrid.ColumnWidth{3} = 0;
                else
                    app.ItemGrid.ColumnWidth{3} = 'fit';
                end
                for thisItem = 1:app.cfg.NumMaxItems
                    % Show/Hide item rows
                    if thisItem > app.NumCriteria
                        % We can hide this criteria row
                        app.ItemGrid.RowHeight{thisItem} = 0;
                        continue
                    else
                        % Show this row
                        app.ItemGrid.RowHeight{thisItem} = 'fit';
                    end

                    % Update parts
                    app.ItemParts(thisItem).Text = partStrings(thisItem);

                    % Update Values
                    ItemTbl = app.ReadScore(thisItem);
                    app.ItemTexts(thisItem).Text = ItemTbl.CriteriaName;
                    if isnan(ItemTbl.PointsEarned)
                        ItemTbl.PointsEarned = 0;
                    end

                    % Update Coloring
                    if ItemTbl.PointsEarned == ItemTbl.CriteriaPoints
                        backColor = [0.4660 0.6740 0.1880]; % green
                    elseif ItemTbl.PointsEarned == 0
                        backColor = [0.8500 0.3250 0.0980]; % orange
                    elseif ItemTbl.PointsEarned > ItemTbl.CriteriaPoints
                        backColor = [0.3010 0.7450 0.9330]; % teal
                    else
                        backColor = [0.9290 0.6940 0.1250]; % yellow
                    end

                    set(app.ItemSpins(thisItem), ...
                        "Limits", [0 ItemTbl.CriteriaPoints],...
                        "Value", ItemTbl.PointsEarned,...
                        "BackgroundColor", backColor);

                    app.ItemBtns(thisItem).Text = sprintf("+%.0f", ItemTbl.CriteriaPoints);
                    % Load Button State if points earned is the same as citeria
                    % points
                    if ItemTbl.PointsEarned == ItemTbl.CriteriaPoints
                        app.ItemBtns(thisItem).Value = 1; % button on state
                    else
                        app.ItemBtns(thisItem).Value = 0; % button off state
                    end
                end
            end

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

        function ValidateAppData(app, oldVer)
            switch oldVer
                case app.version
                    % up to date! Only way to break out of function.
                    return

                case {"1.1.0", "1.0.1", "1.0.2", "1.0.3"}

                    % Repair Config

                    % Repair ItemFontSize
                    %if app.cfg.ItemFontSize < 1; app.cfg.ItemFontSize = 18; end

                    % Modify StTbl to universal format

                    % Upgrade Canvas classlist to universal
                    TableHeaders = string(app.StTbl.Properties.VariableNames);
                    if ismember("StudentName", TableHeaders)
                        StTbl = app.StTbl;
                        % Add First/LastNames
                        FullNames = app.StTbl.StudentName;
                        for n = 1:length(FullNames)
                            NameParts = split(FullNames(n), " ");
                            StTbl.FirstName(n) = NameParts(1);
                            StTbl.LastName(n) = join(NameParts(2:end), " ");
                        end
                        StTbl = movevars(StTbl, ["FirstName", "LastName"], "Before", "StudentName");
                        StTbl.StudentName = [];
                        StTbl.Properties.RowNames = StTbl.FirstName + " " + StTbl.LastName;

                        % Rename other fields
                        StTbl.MSOEID = StTbl.StudentSISID;
                        StTbl.Section = StTbl.SectionName;
                        StTbl.Major = repmat("", app.NumStudents, 1);
                        StTbl.Level = repmat("", app.NumStudents, 1);
                        StTbl.Notes = repmat("", app.NumStudents, 1);
                        % Remove old fields
                        StTbl.StudentSISID = [];
                        StTbl.SectionName = [];

                        app.StTbl = StTbl;
                    end

                    stepVer = "1.2.0"; % This now supports what 1.2.0 runs on

                otherwise
                    return
            end
            app.ValidateAppData(stepVer)
        end

        function createBaseComponents(app)
            % Main Figure
            app.fig = uifigure(...
                'visible', "off",...
                'name', app.window_name,...
                'units', 'normalized',...
                'position', [0 0 app.cfg.window_size],...
                'AutoResizeChildren', 'off',...
                'WindowKeyPressFcn', createCallbackFcn(app, @cb_keypress, true),...
                "CloseRequestFcn", createCallbackFcn(app, @cb_dexFigClose));
            app.fig.Icon = 'iconLarge.png';
            if app.Debug; app.fig.Visible = "on"; end
            
            % Welome Text
            app.WelcomeContainer = uigridlayout(app.fig, [1,1]);
            app.WelcomeText = uilabel(app.WelcomeContainer, "HorizontalAlignment", "center", ...
                "fontsize", 30, "fontweight", "bold", ...
                "Text", sprintf("Welcome\n\nBegin a new session with: File > New...\nLoad a previous session with File > Open..."));
            if app.Debug; app.WelcomeContainer.Visible = "off"; end

            % UI Elements
            app.MainGrid = uigridlayout(app.fig, [2,1], ...
                "RowHeight", {'fit', '1x'}, 'visible','off');
            if app.Debug; app.MainGrid.Visible = "on"; end
            app.TopSubGrid = uigridlayout(app.MainGrid, [1,2], ...
                "Padding", [0 0 0 0], 'ColumnWidth', {'1x','fit'});
            TopPanelLeft = uipanel(app.TopSubGrid, "title", "Student Summary");
            TopPanelRight = uipanel(app.TopSubGrid, "title", "Assignment Summary");
            ItemPanel = uipanel(app.MainGrid, "title", "Problem");

            set([TopPanelLeft, TopPanelRight, ItemPanel], ...
                'fontsize', app.user.FontSizeHeader, "tag", "Header", ...
                "fontweight", "bold")

            NumHeaderRows = 3;

            % Top Grid Left (Student)
            app.TopGridLeft = uigridlayout(TopPanelLeft, [NumHeaderRows,2],...
                "ColumnWidth",{'fit','1x'},...
                "RowHeight",{'1x','1x','1x'});
            app.StudentDropdown = uidropdown(app.TopGridLeft, "Items", ["AAA", "BBB"], "ValueChangedFcn",createCallbackFcn(app, @cb_change_student));
            app.StudentDropdown.Layout.Column = [1, 2];
            uilabel(app.TopGridLeft, "Text", "Section: ", "HorizontalAlignment","right");
            app.SectionText = uilabel(app.TopGridLeft, "Text", "XXX XXX XXX");
            uilabel(app.TopGridLeft, "Text", "Total: ", "HorizontalAlignment","right");
            app.StudentTotal = uilabel(app.TopGridLeft, "text", "XXX.X%  (AA)");
            set(allchild(app.TopGridLeft),'fontsize', app.user.FontSizeHeader, "tag", "Header")

            % Top Grid Right (Assignment)
            app.TopGridRight = uigridlayout(TopPanelRight, [NumHeaderRows,2], "ColumnWidth", {'fit','1x'});
            uilabel(app.TopGridRight, "Text", "Rubric:");
            app.RubricText = uilabel(app.TopGridRight, "Text", "xxx");
            set(allchild(app.TopGridRight),'fontsize', app.user.FontSizeHeader, "tag", "Header")

            % Item Grid
            app.ItemMainGrid = uigridlayout(ItemPanel, [3,1], "RowHeight", {'fit','fit','1x'});
            % Third row will be populated later
            app.ItemHeaderGrid = uigridlayout(app.ItemMainGrid, [1,3], ...
                "ColumnWidth", {'fit','fit','fit'},"Padding",[0 10 0 10]);
            app.ItemProblemText = uilabel(app.ItemMainGrid, "Text", "Problem Text", ...
                "FontSize",app.user.FontSizeBody, "tag", "Body",'fontweight','bold');
            app.ProblemList = uidropdown(app.ItemHeaderGrid, "Items", ["aaa", "bbb"], ...
                "ValueChangedFcn", createCallbackFcn(app, @cb_change_problem));
            uibutton(app.ItemHeaderGrid,"push","Text","Full Credit", ...
                "ButtonPushedFcn", createCallbackFcn(app, @cb_FullNoCredit, true), "UserData", 1);
            uibutton(app.ItemHeaderGrid,"push","Text","No Credit", ...
                "ButtonPushedFcn", createCallbackFcn(app, @cb_FullNoCredit, true), "UserData", 0);
            set(allchild(app.ItemHeaderGrid), 'fontsize', app.user.FontSizeBody, "tag", "Body")

            movegui(app.fig, 'east')
            app.fig.Visible = "on";
        end
        function createCriteriaList(app)

            app.ItemGrid = uigridlayout(app.ItemMainGrid, [app.cfg.NumMaxItems,4], ...
                "ColumnWidth", {'fit', 'fit', 'fit', '1x'},"Padding",[0 10 0 10], ...
                "Scrollable", "on", "RowHeight", repmat({'fit'}, app.cfg.NumMaxItems,1));

            for row = 1:app.cfg.NumMaxItems
                % Col 1 (spinner)
                app.ItemSpins(row) = uispinner(app.ItemGrid, ...
                    "value", 0,...
                    "ValueChangedFcn", createCallbackFcn(app, @cb_change_score, true),...
                    "UserData", row,...
                    "FontWeight", "bold");
                app.ItemSpins(row).Layout.Row = row;
                app.ItemSpins(row).Layout.Column = 1;

                % Col 2 (full pt btn)
                app.ItemBtns(row) = uibutton(app.ItemGrid, "state", "Text", "+X.X",'value',false,...
                    "ValueChangedFcn",createCallbackFcn(app, @cb_change_score, true),...
                    "UserData",row);
                app.ItemBtns(row).Layout.Row = row;
                app.ItemBtns(row).Layout.Column = 2;

                app.ItemParts(row) = uilabel(app.ItemGrid, "WordWrap", "off", ...
                    "text", "a) ");
                app.ItemParts(row).Layout.Row = row;
                app.ItemParts(row).Layout.Column = 3;

                % Col 4 (criteria description)
                app.ItemTexts(row) = uilabel(app.ItemGrid, "WordWrap", "on", ...
                    "text", "test");
                app.ItemTexts(row).Layout.Row = row;
                app.ItemTexts(row).Layout.Column = 4;
            end
            set(allchild(app.ItemGrid),'fontsize',app.user.FontSizeBody)
        end
        function createMenubar(app)
            % Creates the menubar

            app.m_file = uimenu(app.fig, "Text", "File");
            app.m_file_new = uimenu(app.m_file, "Text", "New Project...", "Accelerator", "N", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_New), ...
                "Tooltip", app.tooltips.m_new);
            app.m_file_open = uimenu(app.m_file, "Text", "Open Project...", "Accelerator", "O", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_Open), ...
                "Tooltip", app.tooltips.m_open);
            app.m_file_save = uimenu(app.m_file, "Text", "Save", "Accelerator", "S", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_save), "Enable", "off", ...
                "Tooltip", app.tooltips.m_save);
            app.m_file_saveas = uimenu(app.m_file, "Text", "Save as...", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_saveas), "Enable", "off", ...
                "Tooltip", app.tooltips.m_saveas);
            app.m_file_enableAutoSave = uimenu(app.m_file, "Text", "Enable Autosave", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_AutosaveEnable), "Checked","on", "Enable", "off", ...
                "Tooltip", app.tooltips.m_enableAutosave,...
                "Separator", "on");

            app.m_edit = uimenu(app.fig, "Text", "Edit");
            app.m_edit_classlist = uimenu(app.m_edit, "Text", "Class List...", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_New), ...
                "Tooltip", app.tooltips.m_edit_classlist, "enable", "off");
            app.m_edit_usersettings = uimenu(app.m_edit, "Text", "User Settings...",...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_changeSettings));

            app.m_view = uimenu(app.fig, "Text", "View", "Enable","off");
            app.m_view_sort = uimenu(app.m_view, "Text", "Sort Students");
            app.m_view_sort_firstascend = uimenu(app.m_view_sort, "Text", "First Name A to Z", ...
                "UserData", ["FirstName","ascend"], "MenuSelectedFcn", createCallbackFcn(app, @cb_sortStudents, true), ...
                "Tooltip", "");
            app.m_view_sort_firstdescend = uimenu(app.m_view_sort, "Text", "First Name Z to A", ...
                "UserData", ["FirstName","descend"], "MenuSelectedFcn", createCallbackFcn(app, @cb_sortStudents, true), ...
                "Tooltip", "");
            app.m_view_sort_lastascend = uimenu(app.m_view_sort, "Text", "Last Name A to Z", ...
                "UserData", ["LastName","ascend"], "MenuSelectedFcn", createCallbackFcn(app, @cb_sortStudents, true), ...
                "Tooltip", "");
            app.m_view_sort_lastdescend = uimenu(app.m_view_sort, "Text", "Last Name Z to A", ...
                "UserData", ["LastName","descend"], "MenuSelectedFcn", createCallbackFcn(app, @cb_sortStudents, true), ...
                "Tooltip", "");
            app.m_view_increaseItem = uimenu(app.m_view, "Text", "Increase Criteria Fontsize", "Accelerator", "X", ...
                "UserData", 1, "MenuSelectedFcn", createCallbackFcn(app, @cb_changeItemSize, true), ...
                "Tooltip", app.tooltips.m_IncreaseItem);
            app.m_view_decreaseItem = uimenu(app.m_view, "Text", "Decrease Criteria Fontsize", "Accelerator", "Z", ...
                "UserData", -1, "MenuSelectedFcn", createCallbackFcn(app, @cb_changeItemSize, true), ...
                "Tooltip", app.tooltips.m_DecreaseItem);

            app.m_reports = uimenu(app.fig, "Text", "Reports", "Enable", "off");
            app.m_reports_class = uimenu(app.m_reports, "Text", "Classwide", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_reportClass), ...
                "Tooltip", app.tooltips.m_classwide);
            app.m_export_stu = uimenu(app.m_reports, "Text", "This student...", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_ExportStudent), ...
                "Tooltip", app.tooltips.m_exportStudent,"Separator", "on");
            app.m_export_all_txt = uimenu(app.m_reports, "Text", "All students (.txt)...", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_ExportAll, true), ...
                "Tooltip", app.tooltips.m_exportAlltxt, "UserData", ".txt",...
                "Separator", "on");
            app.m_export_all_pdf = uimenu(app.m_reports, "Text", "All students (.pdf)... [Experimental]", ...
                "MenuSelectedFcn", createCallbackFcn(app, @cb_ExportAll, true), ...
                "Tooltip", app.tooltips.m_exportAllpdf, "UserData", ".pdf");

            app.m_about = uimenu(app.fig, "Text", "About");
            app.m_about_version = uimenu(app.m_about, "Text", "Version " + app.version, "Enable", "off");
            app.m_about_help = uimenu(app.m_about, "Text", "Help", "MenuSelectedFcn", createCallbackFcn(app, @cb_gethelp));

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

        function ExportStudent(app, ScoreTbl, DestFolder, method)
            if nargin < 4
                method = ".txt";
            end
            % If ScoreTbl only has one student AND DestFolder has an
            % extension, then we are saving one student with a particular
            % filename. Otherwise use defaults and save to a directory.
            [path, filename, ext] = fileparts(DestFolder);
            if (height(ScoreTbl) == 1) && (ext~="")
                % Save individual student
                DestFolder = path;
                StdNames = string(filename);
            else
                StdNames = ScoreTbl.FirstName + " " + ScoreTbl.LastName;
            end
            DestFolder = string(DestFolder);
            d = uiprogressdlg(app.fig,'Title','Exporting...',...
                'Message','',"Cancelable","on");
            % ScoreTbl can be a subset of the StTbl
            for s_idx = 1:height(ScoreTbl)
                if d.CancelRequested
                    break
                end
                ThisTbl = ScoreTbl(s_idx, :); % Get this student's data
                d.Value = (s_idx-1)/height(ScoreTbl);
                d.Message = StdNames(s_idx) + method;

                switch method
                    case ".txt"
                        ReportString = app.GenerateReportString(ThisTbl); % Generate the txt page data
                        fileID = fopen(DestFolder + filesep + StdNames(s_idx) + ".txt", 'w');
                        fprintf(fileID, "%s", ReportString);
                        fclose(fileID);

                    case ".pdf"
                        h_page = app.GeneratePage(ThisTbl); % Generate the PDF page data
                        warning('off')
                        saveas(h_page, DestFolder + filesep + StdNames(s_idx), 'pdf')
                        warning('on')
                        close(h_page)
                end
            end
            close(d)
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
            user = app.user;
            save(app.getUserSettingsFile, "user")
        end

        function h_page = GeneratePage(app, StTbl)

            pageHeight = 11.6929;
            pageWidth = 8.2677;
            SideMargin = 0.05;

            HeaderFontSize = 12;
            RubricFontSize = 11;

            BreakLineWidth = 80;
            PtFormatSpec = "%.1f";

            qp = @(ptr, height) [SideMargin ptr 1-SideMargin*2 height];

            h_page = figure(...
                'units','inches',...
                'Position',[0 0 pageWidth pageHeight], ...
                'color', 'w', ....
                'MenuBar','none', ...
                'PaperOrientation','portrait',....
                'PaperType','A4',...
                'visible','off');

            StudentHeader = sprintf("MSOE ID: %d\n%s - %s",...
                StTbl.MSOEID, StTbl.Section, app.RubricName);

            % Student Header
            Ypointer = 0.98;
            ElHeight = 0.05;
            Ypointer = Ypointer - ElHeight;
            uicontrol(h_page,'Style','text','Units','normalized','Position', qp(Ypointer, ElHeight),...
                'string', StTbl.Properties.RowNames, 'HorizontalAlignment','left', 'FontSize', HeaderFontSize*2)
            ElHeight = 0.04;
            Ypointer = Ypointer - ElHeight;
            uicontrol(h_page,'Style','text','Units','normalized','Position', qp(Ypointer, ElHeight),...
                'string', StudentHeader, 'HorizontalAlignment','left', 'FontSize', HeaderFontSize)

            % Final Score
            ElHeight = 0.03;
            Ypointer = Ypointer - ElHeight;
            if isnan(StTbl.ScorePerc)
                ScorePerc = 0;
                GradeLetter = "F";
            else
                ScorePerc = StTbl.ScorePerc;
                GradeLetter = StTbl.GradeLetter;
            end
            uicontrol(h_page,'Style','text','Units','normalized','Position', qp(Ypointer, ElHeight),...
                'string', sprintf('Total Score: %.1f%% %s', ScorePerc, GradeLetter), ...
                'HorizontalAlignment','left', 'FontSize', HeaderFontSize)

            % Rubric and Scores
            str = GenerateScoreSheet();
            uicontrol(h_page,'Style','text','Units','normalized','Position', qp(0.02, Ypointer-0.02),...
                'string', str, 'HorizontalAlignment','left', 'FontSize', RubricFontSize)

            set(h_page.Children, 'backgroundcolor', 'w')

            drawnow

            function str = GenerateScoreSheet()
                rub = StTbl.Rubric{1};
                rub.PointsEarned(isnan(rub.PointsEarned)) = 0; % all NaNs are zeros
                LastProblem = "";
                TextRubric = [];
                for ln = 1:height(rub)
                    if rub.Problem(ln) ~= LastProblem
                        LastProblem = rub.Problem(ln);
                        Earned = sum(rub.PointsEarned(rub.Problem == LastProblem), 'omitnan');
                        OutOf = sum(rub.CriteriaPoints(rub.Problem == LastProblem));
                        LG = app.GetLetterGrade(100*Earned/OutOf);
                        % Print problem header
                        TextRubric = sprintf("%s%s\n%s: %.1f / %.1f = %.1f%% (%s)\n", ...
                            TextRubric, repmat('-',1,BreakLineWidth), LastProblem, Earned, OutOf, 100*Earned/OutOf, LG);
                    end
                    % Print scores
                    TextRubric = sprintf("%s" + PtFormatSpec + " / " + PtFormatSpec + "  %s\n", ...
                        TextRubric, rub.PointsEarned(ln), rub.CriteriaPoints(ln), rub.CriteriaName(ln));
                end
                str = TextRubric;
                return

                rub = StTbl.Rubric{1};
                rub.PointsEarned(isnan(rub.PointsEarned)) = 0; % all NaNs are zeros
                LastProblem = "";
                str = [];
                for ln = 1:height(rub)
                    if rub.Problem(ln) ~= LastProblem
                        LastProblem = rub.Problem(ln);
                        Earned = sum(rub.PointsEarned(rub.Problem == LastProblem), 'omitnan');
                        OutOf = sum(rub.CriteriaPoints(rub.Problem == LastProblem));
                        LG = app.GetLetterGrade(100*Earned/OutOf);
                        % Print problem header
                        ap(sprintf("%s\n%s: %.1f / %.1f = %.1f%% (%s)\n", ...
                            repmat('-',1,BreakLineWidth), LastProblem, Earned, OutOf, 100*Earned/OutOf, LG))
                    end
                    % Print scores
                    ap(sprintf("%4.1f / %4.0f  %s\n", ...
                        rub.PointsEarned(ln), rub.CriteriaPoints(ln), rub.CriteriaName(ln)))
                end

                function ap(NewStr)
                    str = sprintf("%s%s", str, NewStr);
                end

            end

        end
        function ReportText = GenerateReportString(app,StTbl)
            PtFormatSpec = "%.1f";
            BreakLineWidth = 80;
            % Name
            TextName = sprintf("%s", string(StTbl.Properties.RowNames));
            % General Info
            TextInfo = sprintf("MSOE ID: %d\n%s - %s\nDate: %s",...
                StTbl.MSOEID, StTbl.Section, app.RubricName, char(datetime()));
            % Total Score
            TextScore = sprintf('Total Score: %.1f%% %s', StTbl.ScorePerc, StTbl.GradeLetter);

            % Rubric and Scores
            rub = StTbl.Rubric{1};
            rub.PointsEarned(isnan(rub.PointsEarned)) = 0; % all NaNs are zeros
            LastProblem = "";
            TextRubric = [];
            for ln = 1:height(rub)
                if rub.Problem(ln) ~= LastProblem
                    LastProblem = rub.Problem(ln);
                    Weight = rub.ProblemWeight(rub.Problem == LastProblem);
                    Weight = Weight(1);
                    Earned = sum(rub.PointsEarned(rub.Problem == LastProblem), 'omitnan');
                    OutOf = sum(rub.CriteriaPoints(rub.Problem == LastProblem));
                    LG = app.GetLetterGrade(100*Earned/OutOf);
                    % Print problem header
                    TextRubric = sprintf("%s%s\n%s [%.f%% of grade]: %.1f / %.1f = %.1f%% (%s)\n", ...
                        TextRubric, repmat('-',1,BreakLineWidth), LastProblem, Weight*100, Earned, OutOf, 100*Earned/OutOf, LG);
                end
                % Print scores
                TextRubric = sprintf("%s" + PtFormatSpec + " / " + PtFormatSpec + "  %s\n", ...
                    TextRubric, rub.PointsEarned(ln), rub.CriteriaPoints(ln), rub.CriteriaName(ln));
            end
            % Assemble Text
            ReportText = sprintf("%s\n%s\n\n%s\n\n%s", TextName, TextInfo, TextScore, TextRubric);
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
                out = "~/Library/Preferences/DEXTER";
            elseif isunix()
                warning("Untested on Linux!!!")
                out = "";
            else

            end
        end
        function out = getUserHomePath()
            if ispc()
                out = fullfile(getenv("HOMEPATH"), "DEXTER");
                %LOCALAPPDATA
            elseif ismac()
                out = fullfile(getenv("HOME"), "DEXTER");
            elseif isunix()
                warning("Untested on Linux!!!")
                out = "";
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

    %% Secondary Figures
    methods (Access = public)
        function NewSession(app)
            % Prompt user for classlist, section, and rubric
            TitleFontSize = 16;
            TextFontSize = 14; % includes button size
            WindowSize = [600 400];

            thisfig = uifigure(...
                'visible',      'off',...
                'windowstyle',  'modal',...
                'name',         "New DEXTER Project",...
                'position',     [0 0 WindowSize],...
                'resize',       'off',...
                'AutoResizeChildren', 'off',...
                'Icon',         'iconLarge.png');

            OldUnits = app.fig.Units;
            app.fig.Units = "pixels";
            AppPos = app.fig.Position;
            app.fig.Units = OldUnits;
            % Reposition this figure to be on top of app figure
            movegui(thisfig, [AppPos(1)+(AppPos(3)-WindowSize(1))/2, AppPos(2)+(AppPos(4)-WindowSize(2))/2])
            %movegui(thisfig, 'center')

            ActiveClassList = [];
            ActiveRubric = [];

            thisGrid = uigridlayout(thisfig, [3,2], ...
                "ColumnWidth", {'1x','1x'},...
                "RowHeight", {'1x','1x','fit'});

            RubPanel = uipanel(thisGrid, "Title", "1) Select Rubric");
            SectionPanel = uipanel(thisGrid, "Title", "3) Select Sections");
            SectionPanel.Layout.Row = [1 2];
            ClassPanel = uipanel(thisGrid, "Title", "2) Select Class List");
            ClassPanel.Layout.Column = 1;
            ClassPanel.Layout.Row = 2;
            set(allchild(thisGrid),'fontsize', TitleFontSize,'fontweight','bold')

            % Rubric Panel
            RubGrid = uigridlayout(RubPanel, [3,1], ...
                "ColumnWidth", {'1x'},...
                "RowHeight", {'fit','fit','fit'});
            thistext = uilabel(RubGrid, "Text", "Browse for a rubric .xlsx file.", "wordwrap", "on");
            %thistext.Layout.Column = [1,2];
            uibutton(RubGrid, "push", "text", "Browse...", "ButtonPushedFcn", @cb_rubric);
            edit_rubric = uilabel(RubGrid, "text", ". . .", 'FontAngle','italic','WordWrap','on');
            set(allchild(RubGrid),'fontsize',TextFontSize)

            % Class List Panel
            ClassGrid = uigridlayout(ClassPanel, [3,1], ...
                "ColumnWidth", {'1x'},...
                "RowHeight", {'fit','fit','fit'});
            thistext = uilabel(ClassGrid, "Text", "Browse for a class list file from Canvas [.csv] or MyMSOE [.xls or .xlsx].", ...
                "wordwrap", "on");
            %thistext.Layout.Column = [1,2];
            uibutton(ClassGrid, "push", "text", "Browse...", "ButtonPushedFcn", @cb_classlist);
            edit_classlist = uilabel(ClassGrid, "text", ". . .", 'FontAngle','italic','WordWrap','on');
            set(allchild(ClassGrid),'fontsize',TextFontSize)

            % Sections panel
            SectionGrid = uigridlayout(SectionPanel, [2,1], ...
                "ColumnWidth", {'1x'}, "RowHeight", {'fit','1x'});
            uilabel(SectionGrid, "Text", "Shift+Click or CTRL+Click to select multiple sections.",...
                "WordWrap","on","FontSize",TextFontSize);
            drop_section = uilistbox(SectionGrid, ...
                "Items", ["Section 1", "Section 2"],...
                "Multiselect", "on",...
                "Enable", "off","FontSize",TextFontSize);

            % Create Project Button
            btn_create = uibutton(thisGrid,"push","Text",...
                "4) Create New Project", "ButtonPushedFcn", @cb_create, ...
                'fontsize', 14, "Enable", "off", 'fontweight', 'bold');
            btn_create.Layout.Column = [1,2];

            thisfig.Visible = 'on';

            function cb_classlist(obj,~)
                [file,path] = uigetfile({...
                    '*.csv','Canvas (*.csv)';...
                    '*.xls;*.xlsx', 'MyMSOE (*.xls,*.xlsx)'},...
                    "Select class list downloaded from Canvas or MyMSOE", app.cfg.PathLastClasslist);
                figure(app.fig)
                figure(thisfig) % bring back in focus
                if isequal(file, 0) || isequal(path,0)
                    return
                end
                % Try to load the classlist
                try
                    ActiveClassList = app.ReadClassList(fullfile(path,file));
                    % Update other UI
                    sections = unique([ActiveClassList.Section]);
                    drop_section.Items = sections;
                    edit_classlist.Text = file;
                catch
                    uialert(thisfig,{'Unable to read class list file.','Check formatting and try again.'},'Invalid File');
                    ActiveClassList = [];
                    drop_section.Items = ["Section 1", "Section 2"];
                    drop_section.Enable = "off";
                    return
                end

                drop_section.Enable = "on";
                % Save config with last path
                path = string(path);
                app.ChangeConfig(["PathLastSelected", "PathLastClasslist"], {path, path})
                if ~isempty(ActiveClassList) && ~isempty(ActiveRubric)
                    btn_create.Enable = "on";
                end
            end
            function cb_rubric(obj,~)
                [file,path] = uigetfile('*.xlsx',"Select rubric .xlsx", app.cfg.PathLastRubric);
                figure(app.fig)
                figure(thisfig) % bring back in focus
                if isequal(file, 0) || isequal(path,0); return; end
                % Try to load the rubric
                try
                    [ActiveRubric, msg] = app.GetRubricTable(fullfile(path,file));
                catch
                    % If otherwise would have been a fatal error, catch and
                    % abort:
                    uialert(thisfig, {'Unable to read rubric Excel file.', 'Check spreadsheet formatting and try again.'},'Invalid File');
                    ActiveRubric = [];
                    return
                end
                % Otherwise no 'fatal' error, but we should check for app
                % error (bad table formatting)
                if msg ~= ""
                    % Something bad happened internally (bad table
                    % formatting?)
                    uialert(thisfig, {'Unable to read rubric Excel file.', msg},'Invalid File');
                    return
                end
                % Good Read, Update UI and config history
                edit_rubric.Text = file;
                path = string(path);
                app.ChangeConfig(["PathLastSelected", "PathLastRubric"], {path, path})

                if ~isempty(ActiveClassList) && ~isempty(ActiveRubric)
                    btn_create.Enable = "on";
                end
            end
            function cb_create(obj,~)
                % User wants to create a new session, finally, ask for
                % filename and path of grading session.
                RubricfName = extractBefore(edit_rubric.Text,".xlsx");

                if length(drop_section.Value) > 1
                    DefaultName = "MultiSection";
                else
                    DefaultName = string(drop_section.Value);
                end

                [file, path] = uiputfile("*.dex", "Save session", ...
                    fullfile(app.cfg.PathLastSaves, DefaultName + " " + RubricfName + ".dex"));
                if isequal(file, 0) || isequal(path,0); return; end
                figure(app.fig)
                figure(thisfig) % bring back in focus

                % Pass Active Classlist and Active Rubric as well as get
                % the selected Section from dropdown.
                ActiveClassList = ActiveClassList(any(ActiveClassList.Section == string(drop_section.Value), 2),:);
                ActiveClassList.ScorePerc = NaN(height(ActiveClassList), 1);
                ActiveClassList.GradeLetter = strings(height(ActiveClassList), 1);
                ActiveClassList.Rubric = repmat({ActiveRubric}, height(ActiveClassList), 1);

                if isempty(app.StTbl)
                    % We can use the current DEXTER to host this session
                    app.section = drop_section.Value;
                    app.RubricFileName = edit_rubric.Text;
                    app.StTbl = ActiveClassList;
                    app.SaveFile = fullfile(path,file);
                    app.LoadBaseData();
                    app.UpdateUI();
                    SaveState(app, fullfile(path,file)) % Initial save
                    close(thisfig)
                else
                    % We should start a new instance of the app with these
                    % data. Save a 'state' and load it
                    AppState.cfg = app.cfg; % Inherit config from current window
                    AppState.StTbl = ActiveClassList;
                    AppState.RubricFileName = edit_rubric.Text;
                    AppState.section = drop_section.Value;
                    AppState.SaveFile = fullfile(path,file);
                    AppState.CurSt = string(app.StTbl.Properties.RowNames{1});
                    AllProbs = unique(ActiveClassList{1,"Rubric"}{1}.Problem, 'stable');
                    AppState.CurProb = AllProbs(1);
                    save(fullfile(path,file), "AppState", "-mat")
                    DEXTER(fullfile(path,file)); % Make new instance
                end
            end
        end
        function OpenSettings(app)
            TextFontSize = 14;
            WindowSize = [400 600];

            thisfig = uifigure(...
                'visible',      'off',...
                'windowstyle',  'modal',...
                'name',         "DEXTER > User Settings",...
                'position',     [0 0 WindowSize],...
                'AutoResizeChildren', 'off',...
                'Icon',         'iconLarge.png');

            OldUnits = app.fig.Units;
            app.fig.Units = "pixels";
            AppPos = app.fig.Position;
            app.fig.Units = OldUnits;
            % Reposition this figure to be on top of app figure
            movegui(thisfig, [AppPos(1)+(AppPos(3)-WindowSize(1))/2, AppPos(2)+(AppPos(4)-WindowSize(2))/2])

            thisGrid = uigridlayout(thisfig, [2,2], ...
                "ColumnWidth", {'1x','1x'},...
                "RowHeight", {'1x','fit'});

            h = app.user.FillGuiGrid(thisGrid);
            h.MainGrid.Layout.Row = 1;
            h.MainGrid.Layout.Column = [1 2];

            % Cancel
            uibutton(thisGrid, "Text","Cancel",'FontSize',TextFontSize,...
                'ButtonPushedFcn',@cb_cancel);

            % Accept
            uibutton(thisGrid, "Text","Accept",'FontSize',TextFontSize,...
                'ButtonPushedFcn',@cb_accept);

            drawnow

            thisfig.Visible = "on";

            function cb_cancel(~, ~)
                close(thisfig)
            end
            function cb_accept(~, ~)
                % Read all data from the UI
                [NewUserSettings, delta] = app.user.ExtractPropsFromHandles(h);
                if ~isempty(delta)
                    vars = [delta.var];
                    values = {delta.value};
                    app.ChangeUserSetting(vars, values);
                    app.user = NewUserSettings;
                    UpdateUI(app)
                end
                close(thisfig)
            end
        end
        function ShowReport(app)
            % Creates a figure of the whole screen reporting classwise
            % data.
            if isvalid(app.CRfig)
                figure(app.CRfig) % bring in focus
                return
            end
            app.CRfig = uifigure("WindowState","maximized",...
                'name', app.WindowBaseName + " > Class Report",...
                "Visible",'off');

            HistHeightPix = 300;

            LongTable = DEXTER.ExpandTable(app.StTbl);
            LongTable.Rubric = app.StTbl.Rubric;

            MainGrid = uigridlayout(app.CRfig, [1,3], "ColumnWidth", {'1x', '1x', '1x'}); %#ok<*ADPROPLC>
            TextPnl = uipanel(MainGrid, "Title", "Summary", "fontsize", 20);
            LeftPanel = uipanel(MainGrid, "Title", "Assignment", "fontsize", 20);
            RightPanel = uipanel(MainGrid, "Title", "Problems", "fontsize", 20);
            LeftGrid = uigridlayout(LeftPanel, [1,1], "Scrollable","on",...
                "RowHeight", HistHeightPix);
            RightGrid = uigridlayout(RightPanel, [app.NumProbs,1], "Scrollable","on",...
                "RowHeight",repmat({HistHeightPix}, app.NumProbs, 1));

            % Populate Summary Section
            % ItemName, average score % (letter grade), lowest %, highest %
            SmryGrid = uigridlayout(TextPnl, [3+app.NumProbs, 4], ...
                "RowHeight", repmat({'fit'}, 3+app.NumProbs, 1),...
                "ColumnWidth", repmat({'fit'},1,4));
            uilabel(SmryGrid, "Text", "");
            uilabel(SmryGrid, "Text", "Avg", "FontWeight", "bold");
            uilabel(SmryGrid, "Text", "Min", "FontWeight", "bold");
            uilabel(SmryGrid, "Text", "Max", "FontWeight", "bold");
            AddSmryScoreRow("Total:", LongTable.ScorePerc)
            % Return to fill in each problem summary when building
            % historgrams

            % main score historgram
            ax1 = uiaxes(LeftGrid, "PickableParts", "none");
            title(ax1, "Total Score Distribution")
            h = histogram(ax1, categorical(LongTable.GradeLetter), app.cfg.grade_scale.Letter);
            %AppendStudentListTT(h, app.cfg.grade_scale.Letter' == LongTable.GradeLetter)
            %h.DataTipTemplate.DataTipRows(1).Label = "Occurences";
            %h.DataTipTemplate.DataTipRows(2).Label = "Grade";
            HistFormat(ax1)

            % Histrogram for each problem
            ProbColumnNames = "Q" + (1:app.NumProbs)' + "%: " + app.ProblemNames;
            for n = 1:app.NumProbs
                ThisAx = uiaxes(RightGrid, "PickableParts","none");
                title(ThisAx, app.ProblemNames(n))
                TheseGrades = app.GetLetterGrade(LongTable.(ProbColumnNames(n)));
                histogram(ThisAx, categorical(TheseGrades), app.cfg.grade_scale.Letter)
                HistFormat(ThisAx)

                % Also add summary text
                AddSmryScoreRow(app.ProblemNames(n), LongTable.(ProbColumnNames(n)))
            end

            drawnow
            app.CRfig.Visible = 'on';

            function HistFormat(ThisAxes)
                ylabel(ThisAxes, "Occurences")
                set(ThisAxes, "TickDir", "none", 'YLim', [0, max(ThisAxes.Children.Values)+1])
            end
            function AppendStudentListTT(h_hist, TruthMatrix)
                % if h_hist has B bins representing S totall students,
                % then TruthMtrix is a SxB logical matrix which 1 inidcates
                % the student (row) matches that bin (column)
                NumBins = size(TruthMatrix,2);
                sts = cell(1, NumBins);
                StudentNames = LongTable.StudentName;
                for ThisBin = 1:NumBins
                    FoundStudents = sort(StudentNames(TruthMatrix(:,ThisBin)));
                    sts{ThisBin} = char(sprintf("\n%s", FoundStudents));
                end
                h_hist.UserData = sts;
                h_hist.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Students', 'UserData');
            end
            function AddSmryScoreRow(name, scores)
                uilabel(SmryGrid, "Text", name, "FontWeight","bold");
                MeanScore = mean(scores, 'omitnan');
                uilabel(SmryGrid, "Text", sprintf("%.1f %% (%s)", MeanScore, app.GetLetterGrade(MeanScore)));
                uilabel(SmryGrid, "Text", sprintf("%.1f", min(scores, [], 'omitnan')));
                uilabel(SmryGrid, "Text", sprintf("%.1f", max(scores, [], 'omitnan')));
            end
        end
        function EditClassList(app)
            TextFontSize = app.user.FontSizeBody;
            WindowSize = [550 600];

            thisfig = uifigure(...
                'visible',      'off',...
                'windowstyle',  'modal',...
                'name',         "DEXTER > Edit Class List",...
                'position',     [0 0 WindowSize],...
                'AutoResizeChildren', 'off',...
                'Icon',         'iconLarge.png');

            OldUnits = app.fig.Units;
            app.fig.Units = "pixels";
            AppPos = app.fig.Position;
            app.fig.Units = OldUnits;
            % Reposition this figure to be on top of app figure
            movegui(thisfig, [AppPos(1)+(AppPos(3)-WindowSize(1))/2, AppPos(2)+(AppPos(4)-WindowSize(2))/2])

            thisGrid = uigridlayout(thisfig, [3,1], ...
                "ColumnWidth", {'1x'},...
                "RowHeight", {'fit','1x','fit'});

            uilabel(thisGrid, "Text", "Edit class list then press Continue.", "WordWrap","on",...
                "FontSize",TextFontSize);

            ThisTbl = uitable(thisGrid, "Data", app.StTbl(:, ["FirstName", "LastName"]),...
                "ColumnEditable",[true true],'rowname','numbered','FontSize',TextFontSize);

            uibutton(thisGrid, "Text","Continue",'FontSize',TextFontSize,...
                'ButtonPushedFcn',@cb_continue);

            thisfig.Visible = "on";

            function cb_continue(obj, event)
                app.StTbl(:, ["FirstName", "LastName"]) = ThisTbl.Data;
                app.StTbl.Properties.RowNames = app.StTbl.FirstName + " " + app.StTbl.LastName;
                UpdateUI(app)
                close(thisfig)
            end
        end
    end

    %% Public Tools
    methods (Access = public, Static)

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

