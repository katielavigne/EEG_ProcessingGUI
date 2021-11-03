%% DOCUMENTATION
%
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com)
% DATE: June 16th, 2016
% 
% FILE:     exportEEGevents.m
% PURPOSE:  Export EEG trigger events to text files.
% USAGE:    Click "Export EEG Events" in GUI after completing Data Setup.
% 
% DESCRIPTION:  This script will export EEG trigger events as under the Triggers folder 
%               in the user-defined processing directory as text files named as follows: 
%               [SubjectID]_[Task]_[Run#]_triggers.txt.
% 
% REQUIREMENTS: see 'help runEEG'
%
% INSTRUCTIONS
%   - If there are missing/multiple data files or logfiles, you will be asked to select the proper one.
%   - Make sure all files are properly named (see requirements) to avoid popups prompting for user input.
% 
% OUTPUT
%   -   Output files are 'subjinfo.csv' and 'EEGevent_errors.txt', both written to the user-defined processing directory.
%   -   You can examine the "EEGevent_errors.txt" file to see any errors with loading data or getting events, 
%       adjust these issues and re-run the script.
% 
% COMMENTS
%   -   Script will load subjinfo.csv (if exists) and only run subjects not
%       already complete (looks for [SubjectID]_[Task]_[Run#]_triggers.txt).
%   -   New subjects will be appended to subjinfo.csv

function [subjinfo, errors] = exportEEGevents(run_struct, subjID, suffix, sessionID, taskID, subjdir, subjinfo, errors)

    global EEG
    % CHECK IF RAW OR MAT
    if exist(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW'),'dir') == 7
        datatype = 1; % raw
    elseif exist(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT'),'dir') == 7
        datatype = 2; % mat
    end
    % GET RUN LISTS
    switch datatype
        case 1 % raw data
            runlist = dir(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW', run_struct.datasetup.run));
            runlist=runlist(~strncmpi('.',{runlist.name},1)); % Remove hidden files (files starting with '.')
            rflag = [runlist.isdir]; % directories only
            runlist = runlist(rflag); % directories only
            if size(runlist,1) == 0 % Check for run directories
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No run directories found!'];
                return
            end
        case 2 % mat data
            mat_datafile = dir(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT/*.mat'));
            mat_datafile = mat_datafile(~strncmpi('.',{mat_datafile.name},1)); % Remove hidden files (files starting with '.')
            if size(mat_datafile,1) == 1
                filename = mat_datafile.name;
            elseif size(mat_datafile,1) > 1 % Select data file if more than one match
                [Selection,OK] = listdlg('PromptString', [{'Multiple data files found!'} {['Select proper file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
                    'SelectionMode','single', 'ListString', {mat_datafile.name}, 'ListSize', [500,250]);
                if OK == 0 % If no selection made
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .mat data selected!'];
                else
                    filename = mat_datafile(Selection).name;
                end
            elseif size(mat_datafile,1) == 0
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .mat data file found!'];
                return
            end
            % LOAD MAT FILE
            try
                fprintf(['\n***Loading ' subjID suffix ' ' sessionID ' ' taskID ': ' filename '***\n'])
                tmpdata = load(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT', filename)); % load the current subject's data
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                return
            end
            % CREATE RUNLIST
            fieldValues = fieldnames(tmpdata);
            runlist = {};
            for a = 1 : size(fieldValues, 1)
                if regexp(fieldValues{a}, regexptranslate('wildcard', '*mff*')) == 1 % MATLAB run variables have 'mff' in name
                    runlist = [runlist; fieldValues(a)];
                end
            end
            allDINs = [];
            for j = 1:size(tmpdata.DINs,2)
                allDINs = [allDINs, tmpdata.DINs{3,j}];
            end
    end

    %START RUN LOOP
    for r = 1:size(runlist,1)
        % GET RUNID
        switch datatype
            case 1 % raw data
                runID=runlist(r).name;
            case 2 % mat data
                runID = ['Run' num2str(r)];
        end

        % SKIP RUN IF SUBJINFO & TRIGGER FILE EXISTS
        row = intersect(intersect(intersect(find(ismember(subjinfo(:,1),subjID)),find(ismember(subjinfo(:,2),sessionID))),find(ismember(subjinfo(:,3),taskID))),find(ismember(subjinfo(:,4),runID)));

        if ~isempty(row);
            if max(cellfun('isempty',subjinfo(row,:))) == 0
                if exist(fullfile(run_struct.datasetup.triggerdir, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_' runID '_triggers.txt']), 'file') == 2
                    continue % Skip run if relevant subjinfo row is filled in and trigger file exists
                end
            end
        else
            row = size(subjinfo,1)+1;
            subjinfo{row,1} = subjID;
            subjinfo{row,2} = sessionID;
            subjinfo{row,3} = taskID;
            subjinfo{row,4} = runID;
        end

        % FIND DATA FILENAME (OR VARIABLE IN CASE OF MAT)
        switch datatype
            case 1 % raw data
                subjinfo{row,5} = 'RAW';
                datafiles = dir(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW', runID, '*.raw'));
                datafiles = datafiles(~strncmpi('.',{datafiles.name},1)); % Remove hidden files (files starting with '.')

                % ERROR HANDLING
                if size(datafiles,1) == 1
                    runname = datafiles.name;
                elseif size(datafiles,1) > 1 % Select data file if more than one match
                    [Selection,OK] = listdlg('PromptString', [{'Multiple data files found!'} {['Select proper file for ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ':']}], ...
                        'SelectionMode','single', 'ListString', {datafiles.name}, 'ListSize', [500,250]);
                    if OK == 0 % If no selection made
                        errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': No .raw data selected!'];
                        continue
                    else
                        runname = datafiles(Selection).name;
                    end
                elseif size(datafiles,1) == 0
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': No .raw data file found!'];
                    continue
                end

                % LOAD DATA & EXPORT TRIGGER
                try 
                    fprintf(['\n***Importing ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ': ' runname '***\n'])
                    EEG = pop_readegi(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW', runID, runname), [], [], 'auto');
                    EEG.setname=[subjID suffix '_' sessionID '_' taskID '_' runID];
                    subjinfo{row,6} = EEG.srate;
                    subjinfo{row,7} = runname;
                    EEG = eeg_checkset( EEG );
                    pop_expevents(EEG, fullfile(run_struct.datasetup.triggerdir, sessionID, taskID, [EEG.setname '_triggers.txt']), 'samples');
                catch loadERR % Catch error if load fails
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': Error loading .raw data file! ', loadERR.message];
                    continue
                end
            case 2 % mat data
                runname = runlist{r};
                subjinfo{row,5} = 'MAT';
                subjinfo{row,6} = num2str(tmpdata.EEGSamplingRate);
                subjinfo{row,7} = runname;
                fid3 = fopen(fullfile(run_struct.datasetup.triggerdir, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_Run' num2str(r) '_triggers.txt']),'wt+');
                fprintf(fid3,'number\ttype\tlatency\turevent\n'); % create header line in trigger file
                DINsInd{r} = find(allDINs == r);
                for k = 1: length(DINsInd{r})
                    fprintf(fid3,'%d\t%s\t%d\t%d\n',k,tmpdata.DINs{1,DINsInd{r}(k)},tmpdata.DINs{4,DINsInd{r}(k)},k);
                end
                fclose(fid3);
        end

        % FIND LOGFILE NAME
        clear('logfiles')
        logfiles = dir(fullfile(subjdir, sessionID, 'logfiles', taskID, ['*_eventTiming_' lower(taskID) '_fixed.txt']));
        if ~isempty(logfiles);   
            if size(logfiles,1) ~= size(runlist,1)
                [Selection,OK] = listdlg('PromptString', [{'Inconsistent number of logfiles found!'} {['Data file is ' runname]} {['Select proper logfile for ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ':']}], ...
                                'SelectionMode','single', 'ListString', {logfiles.name}, 'ListSize', [500,250]);
                if OK == 0 % If no selection made
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': No logfile selected!'];
                    continue
                else
                    subjinfo{row,8} = logfiles(Selection).name;
                end
            elseif size(logfiles,1) == size(runlist,1)
                logfile=dir(fullfile(subjdir, sessionID, 'logfiles', taskID, [subjID suffix '_' lower(runID) '_eventTiming_' lower(taskID) '_fixed.txt'])); % try generic name
                if size(logfile,1) == 0 % Select logfile if no generic logfile found
                    [Selection,OK] = listdlg('PromptString', [{'Logfile not found!'} {['Data file is ' runname]} {['Select proper logfile for ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ':']}], ...
                    'SelectionMode','single', 'ListString', {logfiles.name}, 'ListSize', [500,250]);
                    if OK == 0
                        errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID  ': No logfile selected!'];
                        continue
                    else
                        subjinfo{row,8} = logfiles(Selection).name;
                    end
                else
                    subjinfo{row,8} = logfile.name;
                end
            end
        else
            logfiles = dir(fullfile(subjdir, sessionID, 'logfiles', taskID));
            logfiles=logfiles(~strncmpi('.',{logfiles.name},1)); % Remove hidden folders (folders starting with '.')
            [Selection,OK] = listdlg('PromptString', [{'No logfiles found!'} {['Select proper logfile for ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ':']}], ...
                            'SelectionMode','single', 'ListString', {logfiles.name}, 'ListSize', [500,250]);
            if OK == 0 % If no selection made
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': No logfile selected!'];
                continue
            else
                subjinfo{row,8} = logfiles(Selection).name;
            end       
        end
    end % END RUN LOOP
    clear('EEG', 'row')
end % END FUNCTION