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
    app.fig.Icon = fullfile(app.GetGraphicsPath, app.app_icon);
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