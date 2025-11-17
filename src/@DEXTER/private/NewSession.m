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
        'Icon',         fullfile(app.GetGraphicsPath,'iconLarge.png'));

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
