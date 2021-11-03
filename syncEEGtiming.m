%% DOCUMENTATION
%
% AUTHORS: Katie Lavigne (lavigne.k@gmail.com) & Christine Tipper
% DATE: June 16th, 2016
% 
% FILE:     syncEEGtiming.m
% PURPOSE:  Synchronizes EEG trigger events and presentation events, selects 
%           appropriate timing, imports events, and saves *_raw.set file.
% USAGE:    Click "Sync Timing" in GUI
% 
% DESCRIPTION: This script will:
%   (1) sync the presentation timing with the EEG timing based on the sync values created in EEGTriggerSync.xlsm
%   (2) merge the runs into one EEG structure
%   (3) add the relevant software and hardware offsets 
%   (4) select either the EEG or Presentation timing to write out to text file
%   (5) import the new timing events
%   (6) output text files for checking synchronization
%   (7) save the synced, merged, offsetted runs as a [SubjID]_[SessionID]_[TaskID]_raw.set file.
% 
% REQUIREMENTS
%   1) syncinfo.txt must exist in trigger directory and must include all info
%
% INSTRUCTIONS
%   -   If no syncinfo.txt file is found, the script will stop
%   -   If current subject/run info is missing (no row in syncinfo or empty values, missing files, etc), this will be listed in sync_errors.txt
%   -   If [SubjID]_[SessionID]_[TaskID]_sync_all.txt already exists, it will skip that subject (so delete the files if you want to redo everyone)
%       -   Linux command: find [path to data directory] -name *_sync_all.txt* -delete
% 
% OUTPUT
%   -   Will output [SubjID]_[SessionID]_[TaskID]_sync_all.txt files in the relevant logfile directories
%   -   sync_errors.txt in processing directory
%%

function [event_latencies, errors] = syncEEGtiming(run_struct, s, subjID, suffix, sessionID, taskID, subjdir, subj_latencies, syncfile, syncinfo, event_latencies, errors)

    global EEG
    origfilename = '';
    
    % CHECK IF RAW OR MAT
    if exist(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW'),'dir') == 7
        datatype = 1; % raw
    elseif exist(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT'),'dir') == 7
        datatype = 2; % mat
    end

    if isempty(dir(fullfile(subjdir, sessionID, 'logfiles', taskID, syncfile))) % skip completed subjects
        epochTimes = [];
        indices = [];
        ALLEEG = [];

        switch datatype
            case 1 % raw data
                runlist = dir(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW', run_struct.datasetup.run));
                runlist = runlist(~strncmpi('.',{runlist.name},1)); % Remove hidden files (files starting with '.')
                rflag = [runlist.isdir]; % directories only
                runlist = runlist(rflag); % directories only
                if size(runlist,1) == 0 % Check for run directories
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No run directories found!'];
                    return
                end
            case 2 % mat data
                mat_datafile = dir(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT', '*.mat'));
                mat_datafile = mat_datafile(~strncmpi('.',{mat_datafile.name},1)); % Remove hidden files (files starting with '.')
                % DEALING WITH MULTIPLE MAT FILES
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
                end
                % LOAD MAT FILE
                try
                    fprintf(['\n***Loading ' subjID suffix ' ' sessionID ' ' taskID ': ' filename '***\n'])
                    tmpdata = load(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'MAT', filename)); % load up the current subject's data
                catch loadERR
                    errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                    return
                end
                % CREATE RUNLIST
                fieldValues = fieldnames(tmpdata);
                runlist = [];
                runs = 0;
                for a = 1 : size(fieldValues, 1)
                    if regexp(fieldValues{a}, regexptranslate('wildcard', '*mff*')) == 1
                        runs = runs + 1;
                        runlist = [runlist; runs];
                    end
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

            row = intersect(intersect(intersect(find(ismember(syncinfo(:,2),subjID)),find(ismember(syncinfo(:,3),sessionID))),find(ismember(syncinfo(:,4),taskID))),find(ismember(syncinfo(:,5),runID)));
            if ~isempty(row)
                if size(row,1) > 1
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': Multiple sync info rows found! Used first entry.'];
                    row=row(1);                                
                end
                if max(cellfun('isempty',syncinfo(row,1:14))) == 0
                    % GET FILENAMES/VALUES
                    samplingrate = str2num(syncinfo{row, 7});
                    eegfile = syncinfo{row,8};
                    presfile = syncinfo{row,9};
                    site = syncinfo{row,10};
                    netstation_version = syncinfo{row,11};
                    syncvalue = str2num(syncinfo{row, 12});
                    s_offsetms = str2num(syncinfo{row, 13});
                    s_offset = floor(s_offsetms*samplingrate*1/1000);
                    h_offsetms = str2num(syncinfo{row, 14});
                    h_offset = floor(h_offsetms*samplingrate*1/1000);
                    
                    if r == 1
                        origfilename = eegfile;
                    end

                    if strcmp(site, 'CFRI') == 1
                        location = 1;
                    elseif strcmp(site, 'UBC') == 1
                        location = 2;
                    end

                    if str2num(netstation_version) == 4
                        version = 1;
                    elseif str2num(netstation_version) == 5
                        version = 2;
                    end

                    % GET EEG STRUCTURE
                    switch datatype
                        case 1 % raw
                            try
                                fprintf(['\n***Importing ' subjID suffix ' ' sessionID ' ' taskID ' ' runID ': ' eegfile '***\n'])
                                EEG = pop_readegi(fullfile(subjdir, sessionID, 'EEG_data', taskID, 'RAW', runID, eegfile));
                                [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
                            catch loadERR
                                errors{size(errors,1)+1,1} = ['Error loading ' eegfile '! ' loadERR.message];
                                continue
                            end
                        case 2 % mat
                            EEG = eeg_emptyset;
                            EEG.srate = tmpdata.EEGSamplingRate;
                            indData = strmatch(eegfile, fieldValues);
                            EEG.data = tmpdata.(fieldValues{indData(1)});
                            EEG = eeg_checkset(EEG);
                            %IMPORT DIN EVENTS
                            EEG = pop_importevent(EEG,'event',fullfile(run_struct.datasetup.triggerdir, sessionID, taskID, [subjID suffix, '_' sessionID, '_', taskID, '_', runID, '_triggers.txt']),'fields',{'number' 'type' 'latency' 'urevent'},'skipline',1,'append','yes','timeunit',NaN,'optimalign','off');
                            EEG = eeg_checkset(EEG);
                            [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
                    end

                    indices = [indices CURRENTSET];
                    [time, condition, eventCode]=textread(fullfile(subjdir, sessionID, 'logfiles', taskID, presfile),'%f %s %s','delimiter','\t', 'headerlines',1); % read presentation events, skip header line

                    % SYNC PRESENTATION TIMING AND ADD OFFSETS
                    if r == 1 || isempty(epochTimes)
                        epochTimes = [];
                        newPresTime = [];
                        newcondition = [];
                        neweventCode = [];
                        FinalTimes = [];
                        tmptime = floor(time*samplingrate*1/1000) + syncvalue + s_offset + h_offset;

                        %Remove events occurring before trial start
                        del=0;
                        for i = 1:size(tmptime,1)
                            if tmptime(i-del) < 0
                                tmptime(i-del) = [];
                                condition(i-del) = [];
                                eventCode(i-del) = [];
                                del = del+1;
                            end
                        end

                        epochTimes = EEG.pnts + s_offset + h_offset;
                        newPresTime = tmptime;
                        newcondition = condition;
                        neweventCode = eventCode;
                    elseif r > 1
                        tmptime = floor(time*samplingrate*1/1000) + syncvalue;
                        %Remove events occurring before trial start
                        del=0;
                        for i = 1:size(tmptime,1)
                            if tmptime(i-del) < 0
                                tmptime(i-del) = [];
                                condition(i-del) = [];
                                eventCode(i-del) = [];
                                del = del+1;
                            end
                        end
                        tmptime = tmptime + epochTimes(r-1); % add epoch time
                        newPresTime = [newPresTime; epochTimes(r-1) ; tmptime];
                        newcondition = [newcondition; {'boundary'}; condition];
                        neweventCode = [neweventCode; {'-99'}; eventCode];
                        epochTimes = [epochTimes (epochTimes(r-1) + EEG.pnts)];
                    end

                    if r == size(runlist,1)
                        if strcmp(origfilename, '')
                            origfilename = eegfile;
                        end
                        % REMOVE SPACES FROM EVENT CODES
                        for i = 1:size(neweventCode,1)
                            neweventCode{i,1} = strrep(neweventCode{i,1},' ','_');
                        end
                        % MERGE RUNS
                        if size(ALLEEG,2) > 1
                            mergedEEG=pop_mergeset(ALLEEG,indices,1);
                        else
                            mergedEEG=EEG;
                        end
                        mergedEEG.setname = [subjID suffix '_' sessionID '_' taskID];
                        mergedEEG.comments = [ 'Original files: ' origfilename ' to ' eegfile];
                        mergedEEG.subject = [subjID suffix];

                         % ADD OFFSET TO EEG EVENTS
                        for j = 1: size(mergedEEG.event,2)
                            mergedEEG.event(j).latency = mergedEEG.event(j).latency + s_offset + h_offset;
                        end

                        % SELECT SYNCED TIMING TO USE (EEG VS PRESENTATION)
                        switch version
                            case 1 % Netstation 4
                                FinalTimes = newPresTime;
                            case 2 % Netstation 5
                                clear allEEGevents
                                switch location
                                    case 1 % CFRI
                                        %REMOVE DIN7s, DIN6s AND NON-DINs
                                        del = 0;
                                        for j = 1: size(mergedEEG.event,2)
                                            if strcmp(mergedEEG.event(j-del).type, 'DIN7') || strcmp(mergedEEG.event(j-del).type, 'DIN6')
                                                mergedEEG.event(j-del) = [];
                                                del = del + 1;
                                            elseif isempty(regexp(mergedEEG.event(j-del).type, regexptranslate('wildcard','DIN*'))) && strcmp(mergedEEG.event(j-del).type, 'boundary') == 0
                                                mergedEEG.event(j-del) = [];
                                                del = del + 1;
                                            end
                                        end
                                    case 2 % UBC
                                        %REMOVE DIN4s AND NON-DINs
                                        del = 0;
                                        for j = 1: size(mergedEEG.event,2)
                                            if strcmp(mergedEEG.event(j-del).type, 'DIN4')
                                                mergedEEG.event(j-del) = [];
                                                del = del + 1;
                                            elseif isempty(regexp(mergedEEG.event(j-del).type, regexptranslate('wildcard','DIN*'))) && strcmp(mergedEEG.event(j-del).type, 'boundary') == 0
                                                mergedEEG.event(j-del) = [];
                                                del = del + 1;
                                            end
                                        end
                                end

                                xtra_events=size(newPresTime,1) - size(mergedEEG.event, 2);
                                if xtra_events == 0
                                    for i = 1:size(newPresTime,1)
                                        FinalTimes(i,1) = mergedEEG.event(i).latency;
                                    end
                                elseif xtra_events < 0
                                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': ' num2str(abs(xtra_events)) ' extra DINs found, presentation time used!'];
                                    FinalTimes = newPresTime;
                                elseif xtra_events > 0
                                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': ' num2str(abs(xtra_events)) ' extra Presentation events found, presentation time used!'];
                                    FinalTimes = newPresTime;
                                end
                        end

                        % ADD IN MISSING CODES
                        if exist(fullfile(subjdir, sessionID, 'logfiles', taskID, [subjID suffix '_run' num2str(r) '_eventTiming_' lower(taskID) '_missingcodes.txt']), 'file') == 2
                            fid3=fopen(fullfile(subjdir, sessionID, 'logfiles', taskID, [subjID suffix '_run' num2str(r) '_eventTiming_' lower(taskID) '_missingcodes.txt']));
                            [missingcodes] = textscan(fid3, '%d%s%s','delimiter','\t','headerlines', 1);
                            codetime = missingcodes{:,1};
                            codetime = floor(codetime*samplingrate*1/1000) + syncvalue + s_offset + h_offset;
                            if r > 1
                                codetime = codetime + epochTimes(r-1);
                            end
                            FinalTimes = [FinalTimes; codetime];
                            newcondition = [newcondition; missingcodes{:,2}];
                            neweventCode = [neweventCode; missingcodes{:,3}];
                        end
                        
                        % WRITE OUT FINAL TIMES
                        fid4 = fopen(fullfile(subjdir, sessionID, 'logfiles', taskID, syncfile), 'w+');
                        fprintf(fid4, 'Time\tCondition\tEvent Code\r\n');
                        for k = 1:length(FinalTimes)
                            fprintf(fid4,'%f\t%s\t%s\r\n', FinalTimes(k), newcondition{k}, neweventCode{k});
                        end                                    

                        %WRITE OUT FILE COMPARING EEG AND PRESENTATION TIME 
                        timecomp = {'EEGTime', 'EEGType', 'PresTime', 'PresCondition', 'PresEventCode'};
                        for i = 1:size(mergedEEG.event, 2)
                            timecomp(i+1,1) = num2cell(mergedEEG.event(i).latency);
                            timecomp(i+1,2) = cellstr(mergedEEG.event(i).type);
                        end
                        for i = 1:size(newPresTime,1)
                            timecomp(i+1,3) = num2cell(newPresTime(i));
                            timecomp(i+1,4) = newcondition(i);
                            timecomp(i+1,5) = neweventCode(i);
                        end

                         ds_timecomp=cell2dataset(timecomp); % cell2dataset requires statistics toolbox!
                         export(ds_timecomp,'file', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_timecomp.txt']), 'delimiter', '\t');

                        % IMPORT PRESENTATION TIMING TO EEG DATA
                        mergedEEG = pop_importevent(mergedEEG,'event',fullfile(subjdir, sessionID, 'logfiles', taskID, syncfile),'fields',{'latency' 'type' 'code'},'skipline',1,'append','yes','timeunit',NaN,'align',NaN,'optimalign','off');

                        % OUTPUT LATENCY BETWEEN EEG AND PRESENTATION EVENTS
                        n=1;
                        for m = 2: size(mergedEEG.event,2)
                            if m == size(mergedEEG.event,2)                                                                
                                ds=cell2dataset(subj_latencies); % cell2dataset requires statistics toolbox!
                                export(ds,'file', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_event_latencies.txt']), 'delimiter', '\t');

                                tmp=[subj_latencies{2:end,2}];
                                meantmp = mean(tmp);
                                event_latencies{s+1,1} = [subjID suffix '_' sessionID '_' taskID];
                                event_latencies{s+1,2} = meantmp;                                                                
                                break
                            elseif strcmp(mergedEEG.event(m).type, 'boundary') | regexp(mergedEEG.event(m).type, regexptranslate('wildcard','DIN*'))
                                if abs(mergedEEG.event(m).latency - mergedEEG.event(m-1).latency) < abs(mergedEEG.event(m).latency - mergedEEG.event(m+1).latency)
                                    n = n+1;
                                    subj_latencies{n,1} = [mergedEEG.event(m).type ' - ' mergedEEG.event(m-1).type];
                                    subj_latencies{n,2} = (mergedEEG.event(m).latency - mergedEEG.event(m-1).latency)*(1/samplingrate)*1000;
                                    subj_latencies{n,3} = mergedEEG.event(m).latency*(1/samplingrate);
                                elseif abs(mergedEEG.event(m).latency - mergedEEG.event(m-1).latency) > abs(mergedEEG.event(m).latency - mergedEEG.event(m+1).latency)
                                    n = n+1;
                                    subj_latencies{n,1} = [mergedEEG.event(m+1).type ' - ' mergedEEG.event(m).type];
                                    subj_latencies{n,2} = (mergedEEG.event(m+1).latency - mergedEEG.event(m).latency)*(1/samplingrate)*1000;
                                    subj_latencies{n,3} = mergedEEG.event(m+1).latency*(1/samplingrate);
                                end
                            end
                        end

                        % SAVE SYNCED EEG DATA AS .SET FILE
                        saveName = sprintf('%s_raw.set',[subjID suffix '_' sessionID '_' taskID]);
                        mergedEEG = pop_saveset(mergedEEG,'filename',saveName,'filepath',fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                        clear('EEG')
                    end
                else
                    errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': syncinfo.txt incomplete!'];
                    continue
                end
            else
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ' ' runID ': Sync Info not found in syncinfo.txt!'];
                continue
            end            
        end % END RUN LOOP   
    else
        return % skip subjects already completed        
    end
end