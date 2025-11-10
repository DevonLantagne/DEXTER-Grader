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