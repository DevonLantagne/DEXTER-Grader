function EditClassList(app)
    TextFontSize = app.user.FontSizeBody;
    WindowSize = [550 600];

    thisfig = uifigure(...
        'visible',      'off',...
        'windowstyle',  'modal',...
        'name',         "DEXTER > Edit Class List",...
        'position',     [0 0 WindowSize],...
        'AutoResizeChildren', 'off',...
        'Icon',         fullfile('build','graphics','iconLarge.png'));

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
