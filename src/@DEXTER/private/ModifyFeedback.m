function ModifyFeedback(app, CritNum)
    % Shows small window to edit feedback for a criteria item

    TextFontSize = 14; % includes button size
    WindowSize = [650 400];

    thisfig = uifigure(...
        'visible',      'off',...
        'windowstyle',  'modal',...
        'name',         "Edit Feedback",...
        'position',     [0 0 WindowSize],...
        'resize',       'on',...
        'AutoResizeChildren', 'on',...
        'Icon',         fullfile(app.GetGraphicsPath, app.app_icon));

    OldUnits = app.fig.Units;
    app.fig.Units = "pixels";
    AppPos = app.fig.Position;
    app.fig.Units = OldUnits;
    % Reposition this figure to be on top of app figure
    movegui(thisfig, [AppPos(1)+(AppPos(3)-WindowSize(1))/2, AppPos(2)+(AppPos(4)-WindowSize(2))/2])

    % ItemMask contains the logical array for the location of the
    % selected criteria in the whole rubric.
    ItemMask = ...
        (app.CurRubric.Problem == app.CurProb) & ...
        (app.CurRubric.CriteriaID == CritNum);

    thisGrid = uigridlayout(thisfig, [3,2], ...
        "ColumnWidth", {'1x'},...
        "RowHeight", {'fit','1x','fit'});

    % Previous Feedback
    if isempty(app.PastComments)
        items = "";
    else
        items = [""; app.PastComments];
    end
    prevcomments = uidropdown(thisGrid, "Items", items,...
        "Value", "", "placeholder", "Previous Feedback",...
        "ValueChangedFcn",@cb_dropselected);
    prevcomments.Layout.Column = [1, 2];

    % Edit Box
    commentbox = uitextarea(thisGrid, ...
        "Placeholder", "Enter feedback",...
        "Fontsize", TextFontSize);
    commentbox.Layout.Column = [1, 2];
    if app.StTbl{app.CurSt, "Rubric"}{1}.Feedback(ItemMask) ~= ""
        commentbox.Value = app.StTbl{app.CurSt, "Rubric"}{1}.Feedback(ItemMask);
    end

    % Confirmation
    % Cancel
    uibutton(thisGrid, "Text","Cancel",'FontSize',TextFontSize,...
        'ButtonPushedFcn',@cb_cancel);
    % Accept
    uibutton(thisGrid, "Text","Accept",'FontSize',TextFontSize,...
        'ButtonPushedFcn',@cb_accept);

    drawnow
    thisfig.Visible = 'on';

    function cb_dropselected(obj, ~)
        % Overwrite text in editfield with dropdown content
        if obj.Value == ""
            return
        end
        commentbox.Value = string(obj.Value);
    end
    function cb_cancel(~, ~)
        close(thisfig)
    end
    function cb_accept(~, ~)
        % Save edit field text to user's criteria feedback
        app.StTbl{app.CurSt, "Rubric"}{1}.Feedback(ItemMask) = string(join(commentbox.Value," "));
        % Apply changes to main figure if feedback is present
        if app.StTbl{app.CurSt, "Rubric"}{1}.Feedback(ItemMask) ~= ""
            set(app.ItemFBBtns(CritNum),...
                "FontWeight", "bold",...
                "FontAngle", "italic")
        else
            set(app.ItemFBBtns(CritNum),...
                "FontWeight", "normal",...
                "FontAngle", "normal")
        end
        close(thisfig)
    end

end