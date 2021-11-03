%% DOCUMENTATION
%
% AUTHORS: Katie Lavigne 
% DATE: June 17th, 2015
% 
% FILE:     plot_ICA_comps.m
% PURPOSE:  Plots ICA components for inspection/rejection/acceptance
% USAGE:    Click Plot ICA Comps next to ICA in GUI
% 
% DESCRIPTION:  This script will plot the ICA components from
%               *ICA.set files and allow you to look through each,
%               accepting or rejecting them.
%
% REQUIREMENTS:
%   1) *ICA.set file must exist in processing folder (savedir)
%
% INSTRUCTIONS
%   -   IMPORTANT!!! Do not click away from figure window while components
%   are being plotted. This will abort plotting!
%   -   Script will go through all matching subjects/runs and plot the data one at a time
%   -   Once opened, go through each component to reject or accept it
%   -   When you close a figure, a popup will show and you can choose to show the next figure or quit.
% 
% OUTPUT: *ICApruned.set files
% 

function [errors, p] = plotICAcomps(run_struct, s, subjID, suffix, sessionID, taskID, p, errors)

    global EEG
    
    diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
    fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
    fprintf('***ICA CORRECTION: PLOT COMPONENTS***\n---------------\n')
    diary off

    file = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '*ICA.set']));
    if size(file,1) == 1
        filename = file.name;
    elseif size(file,1) > 1
        [Selection,OK] = listdlg('PromptString', [{'Multiple ICA.set files found!'} {['Select proper file for ' subjID suffix ' ' sessionID ' ' taskID ':']}], ...
            'SelectionMode','single', 'ListString', {files.name}, 'ListSize', [500,250]);
        if OK == 0 % If no selection made
            errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No .set file selected!'];
        else
            filename = files(Selection).name;
        end
    else
        fprintf([subjID suffix '_' sessionID '_' taskID ': No ICA.set files found'])
        return
    end
    
    try
        EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        fprintf(['\nLoading ' filename '...\n'])
        setname = filename(1:end-4);
    catch loadERR
        errors{size(errors,1)+1,1} = ['Error loading ' filename '. ' loadERR.message];
        if s == size(run_struct.datasetup.subjs,1) && p == 0
            msgbox(['No ICA.set files found in ' run_struct.datasetup.processdir '!']);
            return
        else
            return
        end
    end
    p = p + 1;

    EEG = pop_selectcomps(EEG, run_struct.artifact_handling.ICA.plotcomps); % view components
    uiwait(gcf)
    diary on
    fprintf(['Number of ICA Components Rejected: ' num2str(sum(EEG.reject.gcompreject)) '\n'])
    fprintf(['Components: ' num2str(find(EEG.reject.gcompreject)) '\n'])
    diary off
    EEG = pop_subcomp(EEG); % reject components
    saveName = [setname '_ICApruned.set'];
    EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
end