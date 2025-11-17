function ShowReport(app)
    % Creates a figure of the whole screen reporting classwise
    % data.
    if isvalid(app.CRfig)
        figure(app.CRfig) % bring in focus
        return
    end
    app.CRfig = uifigure("WindowState","maximized",...
        'name', app.WindowBaseName + " > Class Report",...
        "Visible",'off',...
        'Icon', fullfile(app.GetGraphicsPath,'iconLarge.png'));

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
