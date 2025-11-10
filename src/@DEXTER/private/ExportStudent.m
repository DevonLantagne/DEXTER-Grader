function ExportStudent(app, ScoreTbl, DestFolder, method)
    if nargin < 4
        method = ".pdf";
    end
    % If ScoreTbl only has one student AND DestFolder has an
    % extension, then we are saving one student with a particular
    % filename. Otherwise use defaults and save to a directory.
    [path, filename, ext] = fileparts(DestFolder);
    if (height(ScoreTbl) == 1) && (ext~="")
        % Save individual student
        DestFolder = path;
        StdNames = string(filename);
    else
        StdNames = ScoreTbl.FirstName + " " + ScoreTbl.LastName;
    end
    DestFolder = string(DestFolder);
    d = uiprogressdlg(app.fig,'Title','Exporting...',...
        'Message','',"Cancelable","on");
    % ScoreTbl can be a subset of the StTbl
    for s_idx = 1:height(ScoreTbl)
        if d.CancelRequested
            break
        end
        ThisTbl = ScoreTbl(s_idx, :); % Get this student's data
        d.Value = (s_idx-1)/height(ScoreTbl);
        d.Message = StdNames(s_idx) + method;

        switch method
            case ".txt"
                ReportString = app.GenerateReportString(ThisTbl); % Generate the txt page data
                fileID = fopen(DestFolder + filesep + StdNames(s_idx) + ".txt", 'w');
                fprintf(fileID, "%s", ReportString);
                fclose(fileID);

            case ".pdf"
                app.ExportReport(ThisTbl, DestFolder + filesep + StdNames(s_idx));
        end
    end
    close(d)
end