%% DOCUMENTATION
%
% AUTHORS: Katie Lavigne
% DATE: November 29th, 2016
% 
% FILE:     arthandling.m
% PURPOSE:  Runs artifact handling steps depending on button clicked
% USAGE:    Click desired step under "artifact handling" in GUI
% 
% 
% REQUIREMENTS:
%   1) Relevant *.set file must exist in processing folder
%       -   Will look for .set file depending on pipeline described in EEG
%       GUI manual (or will ask you to select a file - currently commented out)
% 
% OUTPUT: multiple .set files for each step in relevant processing 
%   sub-directories as well as processing_errors.txt in processing directory

function [errors, p] = arthandling(run_struct, s, subjID, suffix, sessionID, taskID, p, rmchan_info, errors)

    global EEG
    [set_filt, set_epochs, set_marked, set_rmchans, set_artrej, set_interp, set_ICApruned] = deal(0);
    row = [];
    
    % FIND ALL .SET FILES IN FOLDER
    files = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_*.set']));
    for i = 1:size(files,1)
        if ~isempty(strfind(files(i).name, 'filt.set'))
            set_filt = i;
        end
        if ~isempty(strfind(files(i).name, 'epochs.set'))
            set_epochs = i;
        end
        if ~isempty(strfind(files(i).name, 'marked.set'))
            set_marked= i;
        end
        if ~isempty(strfind(files(i).name, 'rmchans.set'))
            set_rmchans = i;
        end
        if ~isempty(strfind(files(i).name, 'artrej.set'))
            set_artrej = i;
        end
        if ~isempty(strfind(files(i).name, 'interp.set'))
            set_interp = i;
        end
        if ~isempty(strfind(files(i).name, 'ICApruned.set'))
            set_ICApruned = i;
        end
    end
    
    switch run_struct.run_type
        case 'rmchan'
            % 1. REMOVE BAD CHANNELS
            diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
            fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
            fprintf('***REMOVING BAD CHANNELS***\n---------------\n');
            
            if set_rmchans > 0 && strcmp(run_struct.artifact_handling.rmchan.type,'manual')
                filename = files(set_rmchans).name;
            elseif set_filt > 0
                filename = files(set_filt).name;
            else
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No rmchans or filt set files found!']; % comment these lines and uncomment block below to allow people to select files if none found
                return
%                 [Selection,OK] = listdlg('PromptString', [{'No rmchans or filt sets found!'} {['Select file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
%                     'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
%                 if OK == 0 % If no selection made
%                     errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
%                     return
%                 else
%                     filename = files(Selection).name;
%                 end
            end     
            
            try
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No relevant .set files found in ' run_struct.datasetup.processdir '!']);
                    return
                else
                    return
                end
            end
            
            switch run_struct.artifact_handling.rmchan.type
                case 'manual'
                    setfile = filename(1:end-4);
                    row = intersect(intersect(find(ismember(rmchan_info(:,1),subjID)),find(ismember(rmchan_info(:,2),sessionID))),find(ismember(rmchan_info(:,3),taskID))); % find channels to remove from selected text file
                    if isempty(row) ||isempty(rmchan_info{row,4})
                        chans = 'NONE';
                    else
                        chans = str2num(rmchan_info{row,4});
                    end
                    prevchans = EEG.reject.indelec; % hold channels that were removed previously
                    if isnumeric(chans)
                        fprintf('\nRemoving and Interpolating Bad Channels...\n');
                        EEG = pop_interp( EEG, chans, 'spherical');
                        EEG.reject.indelec = [prevchans chans]; % copy all channels removed to EEG structure for future reference
                        fprintf(['\n' num2str(length(chans)) ' BAD CHANNELS REMOVED: ' num2str(chans) '.\n']);
                    end
                    saveName = [setfile '_rmchans.set'];
                    EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                case 'auto'
                    % FASTER code for detecting bad channels
                    eeg_chans = 1:EEG.nbchan; % this will only work if the empty channel was added and chan info also added
                    ref_chan = EEG.nbchan;
                    c_properties = channel_properties(EEG,eeg_chans,ref_chan);
                    c_properties = c_properties(1:EEG.nbchan-1,1:3);
                    eeg_chans_new = 1:EEG.nbchan-1;

                    % z-score calculations
                    z_c_properties = c_properties;
                    z_cor = (c_properties(:,1)-mean(c_properties(:,1)))/std(c_properties(:,1));
                    z_var = (c_properties(:,2)-mean(c_properties(:,2)))/std(c_properties(:,2));
                    z_hur = (c_properties(:,3)-mean(c_properties(:,3)))/std(c_properties(:,3));

                    %create a matrix of z-scores
                    for i = 1:length(eeg_chans_new)
                        z_c_properties(i,1)= z_cor(i); %channel correlations
                        z_c_properties(i,2)= z_var(i); %channel variances
                        z_c_properties(i,3)= z_hur(i); %channel hurst exponents 
                    end;

                    %identify bad channels using z-score thresholds (+/- 3) and save them as
                    %'badChannels'
                    badChannels = [];
                    badchan_arr= {'Channel_Number', 'Z_Correlations', 'Z_Variances', 'Z_Hurst'};
                    c = 1;
                    for i = 1:length(eeg_chans_new)
                        if ((z_c_properties(i,1) >= 3) | (z_c_properties(i,1) <= -3)) | ((z_c_properties(i,2) >= 3) | (z_c_properties(i,2) <= -3)) | ((z_c_properties(i,3) >= 3) | (z_c_properties(i,3) <= -3))
                            badChannels(c) = i;
                            badchan_arr{c+1,1} = i;
                            badchan_arr{c+1,2} = z_c_properties(i,1);
                            badchan_arr{c+1,3} = z_c_properties(i,2);
                            badchan_arr{c+1,4} = z_c_properties(i,3);
                            c=c+1;
                        end;    
                    end;
                    
                    ds=cell2dataset(badchan_arr); % cell2dataset requires statistics toolbox!
                    export(ds,'file', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_BadChannels.txt']), 'delimiter', '\t');

                    %clear index variables from workspace
                    clear c;
                    clear i;
                    
                    setfile = filename(1:end-4);
                    fprintf('\nRemoving Reference channel...\n');
                    EEG = pop_select(EEG, 'nochannel', {'Cz'}); % Remove reference channel
                    if isnumeric(badChannels)
                        fprintf('\nRemoving and Interpolating Bad Channels...\n');
                        EEG = pop_interp( EEG, badChannels, 'spherical');
                        EEG.reject.indelec = badChannels; % copy channels removed to EEG structure for future reference
                        fprintf(['\n' num2str(length(badChannels)) ' BAD CHANNELS REMOVED: ' num2str(badChannels) '.\n']);
                    else
                        fprintf('\nNO BAD CHANNELS DETECTED!\n')
                    end
                    saveName = [setfile '_rmchans.set'];
                    EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
            end
        case 'chan_interp'
            % 2. INTERPOLATE BAD/REMOVED CHANNELS
            diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
            fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
            fprintf('***INTERPOLATING BAD/REMOVED CHANNELS***\n---------------\n');
            
            if set_ICApruned > 0 % look for ICA pruned data first
                filename = files(set_ICApruned).name;
            else
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No ICApruned set files found!']; % comment these lines and uncomment block below to allow people to select files if none found
                return
%                 [Selection,OK] = listdlg('PromptString', [{'No rmchans sets found!'} {['Select file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
%                     'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
%                 if OK == 0 % If no selection made
%                     errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
%                     return
%                 else
%                     filename = files(Selection).name;
%                 end
            end
            
            try
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No relevant .set files found in ' run_struct.datasetup.processdir '!']);
                    return
                else
                    return
                end
            end
                
            EEG = pop_interp( EEG, EEG.reject.indelec, 'spherical'); %Interpolates channels saved from rmchans
            
            
            setfile = filename(1:end-4);
            saveName = [setfile '_interp.set'];
            EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        case 'epchrej'
            % 3. EPOCH REJECTION
            diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
            fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
            
            
            %%%%%%%
            switch run_struct.artifact_handling.epchrej.type
                case 'auto'
                    fprintf('***PEAK-TO-PEAK ARTIFACT REJECTION***\n---------------\n');
                    if set_interp > 0 % looks for channel interpolated data first
                        filename = files(set_interp).name;
                    elseif set_epochs > 0
                        filename = files(set_epochs).name;
                    else
                        errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No interpolated or epoched set files found!']; % comment these lines and uncomment block below to allow people to select files if none found
                        return
%                         [Selection,OK] = listdlg('PromptString', [{'No marked or epoched sets found!'} {['Select file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
%                             'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
%                         if OK == 0 % If no selection made
%                             errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
%                             return
%                         else
%                             filename = files(Selection).name;
%                         end
                    end     

                    try
                        EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                        fprintf(['\nLoading ' filename '...\n'])
                    catch loadERR
                        errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
                        if s == size(run_struct.datasetup.subjs,1) && p == 0
                            msgbox(['No relevant .set files found in ' run_struct.datasetup.processdir '!']);
                            return
                        else
                            return
                        end
                    end
                    
                    fprintf(['\nTwindow: ' num2str(art.artrej_twindow(1)) ': ' num2str(art.artrej_twindow(2)) '\n'])
                    fprintf(['\nThreshold: ' num2str(art.artrej_threshold) '\n'])
                    fprintf(['\nTwindow: ' num2str(art.artrej_winsize) '\n'])
                    fprintf(['\nTwindow: ' num2str(art.artrej_winstep) '\n'])
                    fprintf(['\nTwindow: ' num2str(art.artrej_channel) '\n'])
                    
                    EEG = pop_artmwppth(EEG , ...
                    'Twindow', art.artrej_twindow, ...
                    'Threshold',  art.artrej_threshold, ...
                    'Windowsize',  art.artrej_winsize, ...
                    'Windowstep', art.artrej_winstep, ...
                    'Channel',  art.artrej_channel, ...
                    'Flag', [1 2]);
                    
                    setfile = filename(1:end-4);
                    saveName = [setfile '_artrej.set'];
                    EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                case 'reject'
                    if set_marked > 0
                        filename = files(set_marked).name;
                    else
                        errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No marked set files found!']; % comment these lines and uncomment block below to allow people to select files if none found
                        return
%                         [Selection,OK] = listdlg('PromptString', [{'No marked sets found!'} {['Select file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
%                             'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
%                         if OK == 0 % If no selection made
%                             errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
%                             return
%                         else
%                             filename = files(Selection).name;
%                         end
                    end     

                    try
                        EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                        fprintf(['\nLoading ' filename '...\n'])
                    catch loadERR
                        errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
                        if s == size(run_struct.datasetup.subjs,1) && p == 0
                            msgbox(['No relevant .set files found in ' run_struct.datasetup.processdir '!']);
                            return
                        else
                            return
                        end
                    end
            
                    fprintf('***REJECTING MARKED EPOCHS***\n---------------\n');
                    markedepochs = find(EEG.reject.rejmanual);
                    nummarked = sum(markedepochs);
                    fprintf(['\n' num2str(nummarked) ' MARKED EPOCH(S): ' num2str(markedepochs) '\n'])
                    setfile = filename(1:end-4);
                    EEG = pop_rejepoch( EEG, markedepochs ,0);
                    saveName = [setfile '_artrej.set'];
                    EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
            end
        case 'ICA'
            diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
            fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
            fprintf('***INDEPENDENT COMPONENT ANALYSIS***\n---------------\n');
            if set_artrej > 0 % looks for artifact rejected data (either manual or automatic)
                filename = files(set_artrej).name;
            else
                errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No marked or epoched set files found!']; % comment these lines and uncomment block below to allow people to select files if none found
                return
%                 [Selection,OK] = listdlg('PromptString', [{'No marked sets found!'} {['Select file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
%                     'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
%                 if OK == 0 % If no selection made
%                     errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
%                     return
%                 else
%                     filename = files(Selection).name;
%                 end
            end     

            try
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No relevant .set files found in ' run_struct.datasetup.processdir '!']);
                    return
                else
                    return
                end
            end
            
            if run_struct.artifact_handling.ICA.limitcomps == 1;
                EEG = pop_runica(EEG, 'pca', run_struct.artifact_handling.ICA.numcomps);
            else
                EEG = pop_runica(EEG);
            end
            
            setfile = filename(1:end-4);
            saveName = [setfile '_ICA.set'];
            EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
            
            diary off
    end
    p = p + 1;
end