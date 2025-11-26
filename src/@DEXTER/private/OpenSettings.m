function OpenSettings(app)
    TextFontSize = 14;
    WindowSize = [400 600];

    thisfig = uifigure(...
        'visible',      'off',...
        'windowstyle',  'modal',...
        'name',         "DEXTER > User Settings",...
        'position',     [0 0 WindowSize],...
        'AutoResizeChildren', 'off',...
        'Icon',         fullfile(app.GetGraphicsPath, app.app_icon));

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
