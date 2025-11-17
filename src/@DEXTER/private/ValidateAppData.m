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

        case {"1.2.0", "1.2.1"}
            % Add criteria comments (Feedback) to rubrics
            for st = 1:app.NumStudents
                RubTable = app.StTbl{st,"Rubric"}{1};
                TableHeaders = string(RubTable.Properties.VariableNames);
                if ~ismember("Feedback", TableHeaders)
                    % Feedback column missing, add it
                    RubTable.Feedback = strings(height(RubTable), 1);
                    % Insert rubric back into StTbl
                    app.StTbl(st,"Rubric") = {RubTable};
                end
            end

            stepVer = "1.3.0";

        case {"1.3.0"}
            stepVer = "1.3.1";

        otherwise
            return
    end
    app.ValidateAppData(stepVer)
end