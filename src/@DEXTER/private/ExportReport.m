function ExportReport(app, StTbl, FullFilePath)
    % Generates and saves a PDF of a student's report
    
    PtFormatSpec = "%.1f";

    % Make the DOM document compilable
    if isdeployed
        makeDOMCompilable();
    end

    import mlreportgen.dom.*;
    import mlreportgen.report.*;
    
    % Create file in APPDATA, then copy afterwards
    tempfilelocation = fullfile(DEXTER.getAppDataPath, "tempfile.pdf");
    rpt = Document(tempfilelocation, 'pdf');

    open(rpt);
    
    % margins
    pageLayout = rpt.CurrentPageLayout;
    pageLayout.PageMargins.Top = '0.25in';
    pageLayout.PageMargins.Bottom = '0.5in';
    pageLayout.PageMargins.Left = '0.75in';
    pageLayout.PageMargins.Right = '0.75in';
    pageLayout.PageMargins.Gutter = '0in';
    pageLayout.Hyphenation = false;
    
    % Student Title
    studentTitle = Paragraph(string(StTbl.Properties.RowNames));
    studentTitle.Style = {Bold(true), FontSize('18pt')}; 
    append(rpt, studentTitle);
    % Subtitle
    subtitleGroup = Group();
    append(subtitleGroup, Paragraph(sprintf('ID: %d', StTbl.MSOEID)));
    append(subtitleGroup, Paragraph(sprintf('Section: %s', StTbl.Section)));
    append(subtitleGroup, Paragraph(sprintf('Rubric: %s', app.RubricName)));
    append(subtitleGroup, Paragraph(sprintf('Generated: %s', char(datetime("now")))));
    append(rpt, subtitleGroup);

    % Total Grade
    if isnan(StTbl.ScorePerc)
        gradeinfo = Paragraph(sprintf("Total Grade: %.1f%%  (%s)", 0, "F"));
    else
        gradeinfo = Paragraph(sprintf("Total Grade: %.1f%%  (%s)", ...
            StTbl.ScorePerc, StTbl.GradeLetter));
    end
    gradeinfo.Style = {Bold(true)};
    append(rpt, gradeinfo);
    append(rpt, Paragraph(""));

    % Rubric Items
    rub = StTbl.Rubric{1};
    rub.PointsEarned(isnan(rub.PointsEarned)) = 0; % all NaNs are zeros

    % Get all problem names (in order)
    for p = 1:app.NumProbs
        probRub = rub(rub.Problem == app.ProblemNames(p), :);

        rubTbl = Table();
        rubTbl.Style = {Width('100%')};

        % Problem header
        Earned = sum(probRub.PointsEarned, 'omitnan');
        OutOf = sum(probRub.CriteriaPoints);
        LG = app.GetLetterGrade(100*Earned/OutOf);

        % Print problem header
        titleRow = TableRow();
        titlePara = Paragraph(sprintf("%s (%.1f %% of total): %.1f / %.1f = %.1f%% (%s)", ...
            app.ProblemNames(p), probRub.ProblemWeight(1)*100, Earned, OutOf, 100*Earned/OutOf, LG));
        titlePara.Style = {Bold(true), FontSize('12pt')};
        append(titleRow, TableEntry(titlePara));
        append(rubTbl, titleRow);

        % Print criteria rows
        for c = 1:height(probRub)
            % Criteria text
            row = TableRow();

            criteriaText = Paragraph(Text(sprintf(PtFormatSpec + " / " + PtFormatSpec + " - %s", ...
                probRub.PointsEarned(c), probRub.CriteriaPoints(c), probRub.CriteriaName(c))));
            criteriaText.Style = {FontSize('12pt')};
            thisTabEntry = TableEntry(criteriaText);

            append(row, thisTabEntry);
            append(rubTbl, row);

            % Add the FB as another line
            if probRub.Feedback(c) ~= ""
                row = TableRow();

                ThisText = Text(probRub.Feedback(c));
                FBpara = Paragraph(ThisText);
                FBpara.Style = {Italic(true), FontSize('11pt')};
                
                ThisEntry = TableEntry(FBpara);
                append(row, ThisEntry);
                append(rubTbl, row);
            end

        end
        rubTbl.TableEntriesStyle = {KeepWithNext(true), Hyphenation(true)};
        append(rpt, rubTbl);
        append(rpt, Paragraph(""));
    end

    close(rpt);

    % Copy from APPDATA to user location
    movefile(tempfilelocation, FullFilePath + ".pdf")

end