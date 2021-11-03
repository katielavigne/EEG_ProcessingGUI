%% DOCUMENTATION
%
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com)
% DATE: November 29th, 2016
% 
% FILE:     runprocess.m
% PURPOSE:  Runs the selected process in the GUI.
% USAGE:    Called by clicking on a button in the GUI.
% 
% DESCRIPTION:  This script will run the process that is selected in the
% GUI. It starts the subject/session/task loops and calls the relevant
% function for whichever process was selected.
% 
% REQUIREMENTS: see 'help runEEG'
%
%%

function runprocess(run_struct)

    fcn_name = run_struct.run_type;
    breakflag = 0;
    p = 0;
    errors = {};
    rmchan_info = {};
    tf = struct();
                                

    
    % CREATE TRIGGER DIRECTORY IF IT DOESN'T EXIST
    if ~exist(fullfile(run_struct.datasetup.savedir,'Triggers'), 'dir')
        mkdir(fullfile(run_struct.datasetup.savedir,'Triggers'))
    end
    run_struct.datasetup.triggerdir = fullfile(run_struct.datasetup.savedir, 'Triggers');
    
    % CREATE PROCESSING DIRECTORY IF IT DOESN'T EXIST
    if ~exist(fullfile(run_struct.datasetup.savedir,'ProcessedData'), 'dir')
        mkdir(fullfile(run_struct.datasetup.savedir,'ProcessedData'))
    end
    run_struct.datasetup.processdir = fullfile(run_struct.datasetup.savedir, 'ProcessedData');

    switch run_struct.selectdir
        case 'data'
            selectdir = run_struct.datasetup.datadir;
        case 'save'
            selectdir = fullfile(run_struct.datasetup.savedir, 'ProcessedData');
    end
    
    switch fcn_name
        case 'exportEEGevents'
            % LOAD SUBJINFO.CSV IF EXISTS, OTHERWISE CREATE IT
            try
                fid=fopen(fullfile(run_struct.datasetup.savedir,'subjinfo.csv'));
                firstline=fgetl(fid);
                numFields = length(strfind(firstline,',')) + 1;
                fclose(fid);

                fid=fopen(fullfile(run_struct.datasetup.savedir,'subjinfo.csv'));
                [subjinfo] = textscan(fid, repmat('%s',1,numFields),'delimiter',',','CollectOutput',1);
                subjinfo=subjinfo{1};
                fclose(fid);
            catch
                subjinfo = {};
                subjinfo(1,:) = {'SubjID' 'Session' 'Task' 'Run' 'DataType' 'SamplingRate' 'Filename' 'Logfile'};
            end
        case 'syncEEGtiming'
            event_latencies = {'Subject', 'AvgLatency'};
            % LOAD SYNCINFO.TXT OR PRODUCE ERROR MESSAGE AND END SCRIPT    
            try
                fid=fopen(fullfile(run_struct.datasetup.triggerdir, 'syncinfo.txt'));
                firstline=fgetl(fid);
                numFields = length(strfind(firstline,',')) + 1;
                fclose(fid);

                fid=fopen(fullfile(run_struct.datasetup.triggerdir, 'syncinfo.txt'));
                [syncinfo] = textscan(fid, repmat('%s',1,numFields),'delimiter',',','headerlines', 1,'CollectOutput',1);
                syncinfo=syncinfo{1};
                fclose(fid);
            catch
                msgbox([{fullfile(run_struct.datasetup.triggerdir, 'syncinfo.txt') 'does not exist!'} ,{'Please run EEGTriggersync.xlsm.'}]);
                return
            end
        case 'rmchan'
            if strcmp(run_struct.artifact_handling.rmchan.type, 'manual')
                % LOAD TEXT FILE WITH LIST OF CHANNELS TO REMOVE FOR ALL SUBJECTS
                [filename, path] = uigetfile('*.txt', 'Select File with Channels to Remove');
                try
                    fid=fopen(fullfile(path, filename));
                    [rmchan_info] = textscan(fid, '%s%s%s%s','delimiter','\t','headerlines', 1,'CollectOutput',1);
                    rmchan_info=rmchan_info{1};
                    fclose(fid);
                catch
                    msgbox('Error opening file.')
                    return
                end
            end
    end

    for s = 1:size(run_struct.datasetup.subjs,1)
        switch fcn_name
            case 'syncEEGtiming'
                clear subj_latencies
                subj_latencies = {'Events', 'Latency_ms', 'Time_sec'};
        end
            
        subjID = run_struct.datasetup.subjs(s).name;
        subjdir = fullfile(selectdir, subjID); % subject directory
        sessionlist = dir(fullfile(subjdir, [run_struct.datasetup.session '*']));
        sessionlist = sessionlist(~strncmpi('.',{sessionlist.name},1)); % Remove hidden files (files starting with '.')
        ssflag = [sessionlist.isdir]; % directories only
        sessionlist = sessionlist(ssflag); % directories only
        for ss = 1:size(sessionlist, 1)
            sessionID = sessionlist(ss).name;
            % MCT/OTT STUDY ONLY
            if strcmp(sessionID, 'T1') == 1
                suffix = 'a';
            elseif strcmp(sessionID, 'T3') == 1
                suffix = 'c';
            else
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ': Not a valid session ID!'];
                suffix = '';
            end
                  
            switch run_struct.selectdir
                case 'data'
                    tasklist = dir(fullfile(subjdir, sessionID, 'EEG_data', [run_struct.datasetup.task '*']));
                case 'save'
                    tasklist = dir(fullfile(subjdir, sessionID, [run_struct.datasetup.task '*']));
            end
            tasklist = tasklist(~strncmpi('.',{tasklist.name},1)); % Remove hidden files (files starting with '.')
            tflag = [tasklist.isdir]; % directories only
            tasklist = tasklist(tflag); % directories only
            for t = 1:size(tasklist,1)
                taskID = tasklist(t).name;
                switch fcn_name
                    case 'reexportlog2text'
                        reexport_log2text(run_struct, subjID, suffix, sessionID, taskID)
                    case 'exportEEGevents'
                        % CREATE PROCESSING DIRECTORIES IF ~ EXIST
                        if ~exist(fullfile(run_struct.datasetup.triggerdir, sessionID), 'dir')
                            mkdir(fullfile(run_struct.datasetup.triggerdir, sessionID));
                        end
                        if ~exist(fullfile(run_struct.datasetup.triggerdir, sessionID, taskID), 'dir')
                            mkdir(fullfile(run_struct.datasetup.triggerdir, sessionID, taskID));
                        end
                        [subjinfo, errors] = exportEEGevents(run_struct, subjID, suffix, sessionID, taskID, subjdir, subjinfo, errors);
                        ds=cell2dataset(subjinfo); % cell2dataset requires statistics toolbox!
                        export(ds,'file', fullfile(run_struct.datasetup.savedir, 'subjinfo.csv'), 'delimiter', ',');
                    case 'syncEEGtiming'
                        % CREATE PROCESSING DIRECTORIES IF ~ EXIST
                        if ~exist(fullfile(run_struct.datasetup.processdir, subjID), 'dir')
                            mkdir(fullfile(run_struct.datasetup.processdir, subjID));        
                        end
                        if ~exist(fullfile(run_struct.datasetup.processdir, subjID, sessionID), 'dir')
                            mkdir(fullfile(run_struct.datasetup.processdir, subjID, sessionID));
                        end
                        if ~exist(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID), 'dir')
                            mkdir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                        end
                        syncfile = [subjID suffix, '_', sessionID, '_', taskID '_sync_all.txt'];
                        [event_latencies, errors] = syncEEGtiming(run_struct, s, subjID, suffix, sessionID, taskID, subjdir, subj_latencies, syncfile, syncinfo, event_latencies, errors);
                        ds=cell2dataset(event_latencies); % cell2dataset requires statistics toolbox!
                        export(ds,'file', fullfile(run_struct.datasetup.savedir, 'event_latencies.txt'), 'delimiter', ',');
                    case 'plot'
                        [errors, p] = plot_saved_sets(run_struct, s, subjID, suffix, sessionID, taskID, p, errors);
                        if breakflag == 1
                            break
                        end
                        fighandle = questdlg('Go to:', 'Figure Options', 'Next Subject', 'Quit', 'Next Subject');
                        if strcmp(fighandle, 'Next Subject') == 1
                            continue
                        elseif strcmp(fighandle, 'Quit') == 1
                            breakflag = 1;
                            break
                        end
                    case 'process'
                        [errors, p] = processEEG(run_struct, s, subjID, suffix, sessionID, taskID, p, errors);
                    case {'rmchan', 'chan_interp', 'epchrej', 'ICA'}
                        [errors, p] = arthandling(run_struct, s, subjID, suffix, sessionID, taskID, p, rmchan_info, errors);
                    case 'plotICA'
                        [errors, p] = plotICAcomps(run_struct, s, subjID, suffix, sessionID, taskID, p, errors);
                        if breakflag == 1
                            break
                        end
                        fighandle = questdlg('Go to:', 'Figure Options', 'Next Subject', 'Quit', 'Next Subject');
                        if strcmp(fighandle, 'Next Subject') == 1
                            continue
                        elseif strcmp(fighandle, 'Quit') == 1
                            breakflag = 1;
                            break
                        end
                end
            end % END TASK LOOP
            if breakflag == 1
                break
            end
        end % END SESSION LOOP
        if breakflag == 1
            break
        end
    end
    error_chk(run_struct, fcn_name, errors)
    fprintf('\n\nDone!\n')
end