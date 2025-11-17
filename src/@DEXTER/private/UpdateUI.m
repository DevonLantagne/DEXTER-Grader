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

            % TODO Update FdBk button to bold or something to
            % indicate a comment exists for this item.
            ItemMask = ...
                (app.CurRubric.Problem == app.CurProb) & ...
                (app.CurRubric.CriteriaID == thisItem);
            if app.StTbl{app.CurSt, "Rubric"}{1}.Feedback(ItemMask) ~= ""
                set(app.ItemFBBtns(thisItem),...
                    "FontWeight", "bold",...
                    "FontAngle", "italic")
            else
                set(app.ItemFBBtns(thisItem),...
                    "FontWeight", "normal",...
                    "FontAngle", "normal")
            end
        end
    end

end