%% DOCUMENTATION
%
% AUTHORS: Katie Lavigne 
% DATE: November 29th, 2016
% 
% FILE:     plot_saved_sets.m
% PURPOSE:  Plots saved datasets.
% USAGE:    Select type of data to plot and click Plot Channel Data in GUI
% 
% DESCRIPTION: This script will plot the [SubjID]_[SessionID]_[TaskID]_[Type].set
%   files. This should be used regularly after sync timing (to check synchronization)
%   and for manual artifact rejection, but can also be used to plot the .set files 
%   created after each processing step.
%
% REQUIREMENTS:
%   1) .set file must exist in processing folder (Processing directory/ProcessedData)
%   
%
% INSTRUCTIONS
%   -   Script will go through all matching subjects/runs and plot the data one at a time
%   -   Once the plot is opened and the window automatically maximized
%   -   You can change parameters in the figure window as desired
%   -   When you close a figure, a popup will show and you can choose to show the next figure or quit.
% 
% OUTPUT: plot_errors.txt in processing directory
%% 

function [errors, p] = plot_saved_sets(run_struct, s, subjID, suffix, sessionID, taskID, p, errors)

    global EEG

    plottype = 0;
    
    % FIND ALL .SET FILES IN FOLDER
    files = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_*.set']));
    for i = 1:size(files,1)
        if ~isempty(strfind(files(i).name, [run_struct.plot.plottype '.set']))
            plottype = i;
        elseif strcmp(run_struct.artifact_handling.epchrej.type, 'manual')
            if ~isempty(strfind(files(i).name, 'epochs.set'))    
                plottype = i;
            end
        end
    end
    
    if plottype > 0
        filename = files(plottype).name;
    else
        filename = '';
    end
            
    try
        fprintf(['\nLoading ' filename '...\n'])
        EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        setname = filename(1:end-4);
    catch loadERR
        errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
        if s == size(run_struct.datasetup.subjs,1) && p == 0
            msgbox(['No ' run_struct.plot.plottype '.set files found in ' run_struct.datasetup.processdir '!']);
            return
        else
            return
        end
    end
    p = p + 1;
    title = ['Scroll channel activities - ' filename];

    if strcmp(run_struct.artifact_handling.epchrej.type, 'manual') == 1
        %command string for marking trials to reject
        cmd = 'if ~isempty(TMPREJ),  icaprefix = '''';  [tmprej tmprejE] = eegplot2trial(TMPREJ,EEG.pnts, EEG.trials);  if ~isempty(tmprejE),     tmprejE2 = zeros(EEG.nbchan, length(tmprej));     tmprejE2([1:EEG.nbchan],:) = tmprejE;  else,     tmprejE2 = [];  end;EEG.reject.rejmanual= tmprej;EEG.reject.rejmanualE= tmprejE2;  tmpstr = [ ''EEG.reject.'' icaprefix ''rejmanual'' ];  if ~isempty(tmprej) eval([ ''if ~isempty('' tmpstr ''),'' tmpstr ''='' tmpstr ''| tmprej; else, '' tmpstr ''=tmprej; end;'' ]); end;  if ~isempty(tmprejE2) eval([ ''if ~isempty('' tmpstr ''E),'' tmpstr ''E='' tmpstr ''E| tmprejE2; else, '' tmpstr ''E=tmprejE2; end;'' ]); end;[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); eeglab(''redraw''); end;';

        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['---------------\n' datestr(clock, 0) '\n'])
        disp(['original file location: ' fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID)])
        fprintf(['\nSUBJECT: ' subjID suffix '_' sessionID '_' taskID '\n'])
        fprintf('\n***MANUAL ARTIFACT REJECTION***\n---------------\n')

        eegplot(EEG.data, ...
            'srate', EEG.srate, ...
            'spacing', run_struct.plot.spacing, ...
            'eloc_file', EEG.chanlocs, ...
            'winlength', run_struct.plot.winlength, ...
            'dispchans', run_struct.plot.dispchans, ...
            'title', title, ...
            'events', EEG.event, ...
            'command', cmd, ...
            'tag', title, ...
            'butlabel', 'UPDATE MARKS');
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1); % Maximize window
        uiwait(gcf);
        markedepochs = find(EEG.reject.rejmanual);
        fprintf(['\nMARKED EPOCH(S): ' num2str(markedepochs) '\n'])
        saveName = [setname '_marked.set'];
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        diary off
    else
        eegplot(EEG.data, ...
            'srate', EEG.srate, ...
            'spacing', run_struct.plot.spacing, ...
            'eloc_file', EEG.chanlocs, ...
            'winlength', run_struct.plot.winlength, ...
            'dispchans', run_struct.plot.dispchans, ...
            'title', title, ...
            'events', EEG.event, ...
            'tag', title);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1); % Maximize window
        uiwait(gcf);
    end
end