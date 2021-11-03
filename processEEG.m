%% DOCUMENTATION
%
% AUTHORS: Katie Lavigne
% DATE: November 29th, 2016
% 
% FILE:     processEEG.m
% PURPOSE:  Processes EEG data according to Woodward Lab manual
% USAGE:    Click on RUN in GUI after selecting processing steps
% 
% DESCRIPTION:  This script will run through each preprocessing step 
%               in a pipeline or one at a time as desired.
% 
% REQUIREMENTS:
%   1) Relevant *.set file must exist in processing folder
%       -   Will look for .set file from previous step (so if bins, will look
%   for *reref.set)
%
% INSTRUCTIONS
%   -   When you click on a checkbox, the relevant options will pop up.
%   -   Click the "RUN" button when you have selected all desired steps.
% 
% OUTPUT:   multiple .set files for each step in relevant processing 
%           sub-directories as well as processing_errors.txt in processing directory
%

function [errors, p] = processEEG(run_struct, s, subjID, suffix, sessionID, taskID, p, errors)

    global EEG
    
    pipe = 0;
                    
    if run_struct.processing.chaninfo_rflag == 1
        try 
            delete(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt'])); % will create a new processing file, deleting any with same date
        catch ERR
            disp(ERR.message)
        end
        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['---------------\n' datestr(clock, 0) '\n'])
        disp(['original file location: ' fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID)])
        fprintf(['\nSUBJECT: ' subjID suffix '_' sessionID '_' taskID '\n'])
        fprintf('***ADDING CHANNEL INFORMATION***\n---------------\n')
        disp(['SFP file = ' run_struct.processing.fileloc])
        fprintf(['Reference electrode options: \n  Channel Indices = ' run_struct.processing.ref_chanind '\n  Reference Channel = ' run_struct.processing.ref_ref '\n'])
        
        % 1. LOAD RAW DATASET
        filename = [subjID suffix '_' sessionID '_' taskID '_raw.set'];
        try
            EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
            fprintf(['\nLoading ' filename '...\n'])
        catch loadERR
            errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
            if s == size(run_struct.datasetup.subjs,1) && p == 0
                msgbox(['No *raw.set files found in ' run_struct.datasetup.processdir '! Please run Sync Timing.']);
            end
            return
        end                    

        % 2. ADD CHANNEL INFORMATION
        
            % Add reference channel (required for FASTER bad channel detection) if not already there
            if ~sum(EEG.data(end,:)) == 0
                EEG.data(end+1,:) = 0;
                EEG.nbchan = size(EEG.data,1);
                if ~isempty(EEG.chanlocs)
                    EEG.chanlocs(end+1).label = 'Cz';
                end;
                eeglab redraw
            end        
            % Read channel locations
        EEG = pop_chanedit(EEG, 'load', {run_struct.processing.fileloc, 'filetype', 'autodetect'}, 'setref', {run_struct.processing.ref_chanind, run_struct.processing.ref_ref});
        
        % 3. LOAD REFERENCE INFORMATION

        saveName = sprintf('%s_chaninfo.set',[subjID suffix '_' sessionID '_' taskID]);
        setname = saveName(1:end-4);
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        pipe = 1;
        diary off
     end

    % 4. FILTER DATA
    if run_struct.processing.filter_rflag == 1
        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
        fprintf('***FILTERING***\n---------------\n')

        if pipe == 0
            filename = [subjID suffix '_' sessionID '_' taskID '_chaninfo.set'];
            try
                % LOAD DATASET WITH CHANNEL INFO
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
                setname = filename(1:end-4);
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No *chaninfo.set files found in ' run_struct.datasetup.processdir '! Please add channel information.']);
                end
                return
            end
        end

        % Bandpass
        if ~strcmp(run_struct.processing.filtertype, '')
            fprintf(['Band-pass filter: ' run_struct.processing.filtertype '\nHigh-Pass: ' num2str(run_struct.processing.filtercutoff(1)) '\nLow-Pass: ' num2str(run_struct.processing.filtercutoff(2)) '\n'])
            EEG = pop_basicfilter(EEG, 1:EEG.nbchan, ...
                'Filter', 'bandpass', ...
                'Design', run_struct.processing.filtertype, ...
                'Cutoff', run_struct.processing.filtercutoff, ...
                'Order', 2, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary');
        else
            disp('Band-Pass Filter: none')
        end                    

        % 60Hz Notch 
        if ~strcmp(run_struct.processing.notchtype, '')
            fprintf(['\nNotch Filter: ' run_struct.processing.notchtype '\nCutoff: ' num2str(run_struct.processing.notchcutoff) '\n'])
            EEG = pop_basicfilter(EEG, 1:EEG.nbchan, ...
                'Filter', run_struct.processing.notchtype, ...
                'Design', 'notch', ...
                'Cutoff', run_struct.processing.notchcutoff, ...
                'Order', 180, ...
                'Boundary', 'boundary');
        else
            disp('Notch Filter: none')
        end
        
        % save
        saveName = [setname '_filt.set'];
        setname = saveName(1:end-4);
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        pipe = 1;
        diary off
    end
    
    % 5. RE-REFERENCE
    if run_struct.processing.reref_rflag == 1
        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
        fprintf('***RE-REFERENCING***\n---------------\n');

        if pipe == 0
            rmchans_file = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, '*rmchans.set'));
            if size(rmchans_file,1) > 1
                fprintf('\nWARNING: Multiple *_rmchans.set files found! Last file used.\n');
                filename = rmchans_file(size(rmchans_file,1)).name;
            elseif ~isempty(rmchans_file)
                filename = rmchans_file.name;
            else
                filename = [subjID suffix '_' sessionID '_' taskID '*filt.set'];
            end
            try
                % LOAD RMCHANS/FILTERED DATASET
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
                setname = filename(1:end-4);
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No *rmchans.set or *filt.set files found in ' run_struct.datasetup.processdir '! Please filter data and then remove bad channels.']);
                end
                return
            end
        end

        EEG = pop_reref(EEG, []);

        % save
        saveName = [setname '_reref.set'];
        setname = saveName(1:end-4);
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        pipe = 1;
        diary off
    end

    % 6. MAKE BINS
    if run_struct.processing.bins_rflag == 1
        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
        fprintf('***CREATING BINS***\n---------------\n');

        if pipe == 0;
            reref_file = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, '*reref.set'));
            if size(reref_file,1) > 1
                fprintf('\nWARNING: Multiple *_reref.set files found! Last file used.\n');
                filename = reref_file(size(reref_file,1)).name;
            elseif ~isempty(reref_file)
                filename = reref_file.name;
            else
                filename = [subjID suffix '_' sessionID '_' taskID '*reref.set'];
            end
            try
                % 1. LOAD RE-REFERENCED DATASET
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
                setname = filename(1:end-4);
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No *reref.set files found in ' run_struct.datasetup.processdir '! Please re-reference.']);
                end
                return
            end
        end

        scriptName = mfilename('fullpath');
        [currentpath, ~, ~]= fileparts(scriptName);
        eventList = fullfile(currentpath, 'binfiles', [taskID '_eventTypes.txt']);
        bdffile = fullfile(currentpath, 'binfiles', [taskID '_bdf.txt']);

        disp(['Event List = ' eventList])
        disp(['bdf file = ' bdffile])
        
        %DELETE DIN EVENTS
        del = 0;
        for j = 1: size(EEG.event,2)
            if strcmp(EEG.event(j-del).type, 'DIN4')
                EEG.event(j-del) = [];
                del = del + 1;
            end
        end

        EEG = pop_editeventlist_noGUI(EEG , ...
            'List', eventList, ...
            'BoundaryString', { 'boundary' }, ...
            'BoundaryNumeric', { -99}, ...
            'SendEL2', 'EEG', ...
            'UpdateEEG', 'on', ...
            'Warning', 'off' );

        % create bins
        EEG = pop_binlister(EEG , ...
            'BDF', bdffile, ...
            'UpdateEEG', 'on', ...
            'SendEL2', 'Workspace&EEG',...
            'IndexEL', 1, ...
            'Voutput', 'EEG' );
        % save
        saveName = [setname '_bins.set'];
        setname = saveName(1:end-4);
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        pipe = 1;
    end

    % 7. MAKE EPOCHS
    if run_struct.processing.epochs_rflag == 1
        diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
        fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
        fprintf('***CREATING EPOCHS***\n---------------\n');
        fprintf(['\nEpoch Range: ' num2str(run_struct.processing.epochrange(1)) ': ' num2str(run_struct.processing.epochrange(2)) '\n'])

        if pipe == 0;
            bin_file = dir(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, '*bins.set'));
            if size(bin_file,1) > 1
                fprintf('\nWARNING: Multiple *_reref.set files found! Last file used.\n');
                filename = bin_file(size(bin_file,1)).name;
            elseif ~isempty(bin_file)
                filename = bin_file.name;
            else
                filename = [subjID suffix '_' sessionID '_' taskID '*reref.set'];
            end
            try
                % 1. LOAD BINS DATASET
                EEG = pop_loadset(filename, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
                fprintf(['\nLoading ' filename '...\n'])
                setname = filename(1:end-4);
            catch loadERR
                errors{size(errors,1)+1,1} = ['Error loading ' filename '! ' loadERR.message];
                if s == size(run_struct.datasetup.subjs,1) && p == 0
                    msgbox(['No *bins.set files found in ' run_struct.datasetup.processdir '! Please make bins.']);
                end
                return
            end
        end

        % create epochs
        EEG = pop_epochbin(EEG , run_struct.processing.epochrange,  'pre');

        % save     
        saveName = sprintf('%s_epochs.set',[subjID suffix '_' sessionID '_' taskID]);
        EEG = pop_saveset(EEG, 'filename', saveName, 'filepath', fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID));
        diary off
    end
    p = p + 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEEDED CUSTOM EXTERNAL FUNCTIONS INCLUDED HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [EEG, com] = pop_editeventlist_noGUI(EEG, varargin)
com = '';
if nargin < 1
        help pop_editeventlist
        return
end
if isobject(EEG) % eegobj
        whenEEGisanObject % calls a script for showing an error window
        return
end
if length(EEG)>1
        msgboxText =  'Unfortunately, this function does not work with multiple datasets';
        title = 'ERPLAB: multiple inputs';
        errorfound(msgboxText, title);
        return
end
if isfield(EEG,'epoch')
        if ~isempty(EEG.epoch)
                msgboxText =  'pop_editeventlist only works with continuous datasets.';
                title = 'ERPLAB: pop_editeventlist ';
                errorfound(sprintf(msgboxText), title);
                return
        end
end
if nargin==1
        if isempty(EEG.data)
                msgboxText =  'pop_editeventlist() cannot work with an empty dataset!';
                title = 'ERPLAB: pop_editeventlist() error';
                errorfound(msgboxText, title);
                return
        end
        
        %
        % Call GUI
        %
        inputstrMat = assigncodesGUI;
        
        if ~isempty(inputstrMat)
                editlistname       = inputstrMat{1};
                newelname          = inputstrMat{2};
                updateEEG          = inputstrMat{3};
                boundarystrcode    = inputstrMat{4};
                newboundarynumcode = inputstrMat{5};
                option2do          = inputstrMat{6};
                iswarning          = inputstrMat{7};
                alphanum           = inputstrMat{8};
        else
                disp('User selected Cancel')
                return
        end
        
        % where to send the update/modified EVENTLIST
        switch option2do
                case 0
                        msgboxText = 'Where should I send the update EVENTLIST???\n Pick an option.';
                        title = 'ERPLAB: Error';
                        errorfound(sprintf(msgboxText), title);
                        return
                case 1
                        stroption2do = 'Text';
                case 2
                        stroption2do = 'EEG';
                case 3
                        stroption2do = 'EEG&Text';
                case 4
                        stroption2do = 'Workspace';
                case 5
                        stroption2do = 'Workspace&Text';
                case 6
                        stroption2do = 'Workspace&EEG';
                case 7
                        stroption2do = 'All';
        end
        
        % Update EEG.event field?
        if updateEEG==1
                strupdevent = 'on';
        else
                strupdevent = 'off';
        end
        
        % Warning message in case the exported file already exist
        if iswarning==1
                striswarning = 'on';
        else
                striswarning = 'off';
        end
        if alphanum==1
                stralphanum = 'on';
        else
                stralphanum = 'off';
        end
        
        EEG.setname = [EEG.setname '_elist']; %suggest a new name
        
        %
        % Somersault
        %
        [EEG, com] = pop_editeventlist(EEG, 'List', editlistname, 'SendEL2', stroption2do, 'ExportEL', newelname,...
                'BoundaryString', boundarystrcode,'BoundaryNumeric', newboundarynumcode, 'UpdateEEG', strupdevent,...
                'Warning', striswarning, 'AlphanumericCleaning', stralphanum, 'History', 'gui');
        return
end

%
% Parsing inputs
%
p = inputParser;
p.FunctionName  = mfilename;
p.CaseSensitive = false;
p.addRequired('EEG');
% option(s)
p.addParamValue('List', '', @ischar);
p.addParamValue('ExportEL', 'none', @ischar);
p.addParamValue('SendEL2', 'EEG', @ischar);
p.addParamValue('BoundaryString', 'boundary', @iscell);
p.addParamValue('BoundaryNumeric', -99, @iscell);
p.addParamValue('UpdateEEG', 'off', @ischar);
p.addParamValue('Warning', 'off', @ischar);
p.addParamValue('AlphanumericCleaning', 'off', @ischar);
p.addParamValue('History', 'script', @ischar); % history from scripting
%p.addParamValue('Saveas', 'off', @ischar); % 'on', 'off'

p.parse(EEG, varargin{:});

editlistname  = p.Results.List;     % list of edited events
newelname     = p.Results.ExportEL; % text file containing the updated EVENTLIST

if iseegstruct(EEG)
        if length(EEG)>1
                msgboxText =  'ERPLAB says: Unfortunately, this function does not work with multiple datasets';
                error(msgboxText);
        end
end

%
% What to do with the EVENTLIST?
if strcmpi(p.Results.SendEL2, 'All')
        option2do = 7;  % do all
elseif strcmpi(p.Results.SendEL2, 'Workspace&EEG')
        option2do = 6;  % workspace & current data
elseif strcmpi(p.Results.SendEL2, 'Workspace&Text')
        option2do = 5;  %  workspace & text
elseif strcmpi(p.Results.SendEL2, 'Workspace')
        option2do = 4;  %  workspace only
elseif strcmpi(p.Results.SendEL2, 'EEG&Text')
        option2do = 3;  %  current data & text
elseif strcmpi(p.Results.SendEL2, 'EEG')
        option2do = 2;  % current data only
elseif strcmpi(p.Results.SendEL2, 'Text')
        option2do = 1;  % text only
else
        error('invalid argument for "SendEL2"');
end
if strcmpi(p.Results.Warning, 'on')
        rwwarn = 1;
else
        rwwarn = 0;  % no warning about previous EVENTLIST struct
end
if strcmpi(p.Results.UpdateEEG, 'on')
        updateEEG = 1;
else
        updateEEG = 0;  % no warning about previous EVENTLIST struct
end
%if strcmpi(p.Results.Saveas, 'on') && ismember_bc2(option2do,[2 3 6 7]) % current data
%      issave = 1;
%else
%      issave = 0;  %
%end
if strcmpi(p.Results.AlphanumericCleaning, 'on')
        alphanum = 1;
else
        alphanum = 0;
end
if strcmpi(p.Results.History,'implicit')
        shist = 3; % implicit
elseif strcmpi(p.Results.History,'script')
        shist = 2; % script
elseif strcmpi(p.Results.History,'gui')
        shist = 1; % gui
else
        shist = 0; % off
end

boundarystrcode    = strtrim(p.Results.BoundaryString);
boundarystrcode    = regexprep(boundarystrcode, '''|"','');
newboundarynumcode = p.Results.BoundaryNumeric;

%
% Check empty EEG.event.type
%
indx_evnts = ~cellfun(@isempty, {EEG.event.type});
EEG.event  = EEG.event(indx_evnts);

if ~all(indx_evnts)
        msgboxText =  ['\n*** WARNING: ERPLAB found %g empty entries at EEG.event.type\n'...
                'All of them have been deleted from the list of events.\n'];
        
        try
                cprintf([0.6 0 0], msgboxText', nnz(~indx_evnts));
        catch
                fprintf(msgboxText, nnz(~indx_evnts));
        end  
        
        %fprintf(msgboxText, nnz(~indx_evnts))        
end
if isfield(EEG, 'EVENTLIST')
        if isfield(EEG.EVENTLIST, 'eventinfo')
                if ~isempty(EEG.EVENTLIST.eventinfo)
                        if rwwarn
                                % bug fixed here
                                question = ['dataset %s already has attached\n'...
                                        'an EVENTLIST structure.\n\n'...
                                        'So, pop_editeventlist()  will totally overwrite it.\n\n'...
                                        'Do you want to continue anyway?'];
                                
                                title   = 'ERPLAB: pop_editeventlist, Overwriting Confirmation';
                                button  = askquest(sprintf(question, EEG.setname), title);
                                
                                if ~strcmpi(button,'yes')
                                        disp('User selected Cancel')
                                        return
                                end
                        end
                        %if ischar(EEG.event(1).type)    % temporary...
                        %      [ EEG.event.type ]= EEG.EVENTLIST.eventinfo.code;
                        %end
                        EEG.EVENTLIST = [];
                end
        end
end
% if alphanum==1
%       %
%       % Delete alphabetic character(s) from alphanumeric event codes (if any)
%       %
%       EEG = letterkilla(EEG);
% end

%
% Event consistency
%
EEG = eeg_checkset(EEG, 'eventconsistency'); %  not working properly. EEGLAB 11.0.4.2b. Dec 10. 2012
field2del = {'bepoch','bini','binlabel', 'code', 'codelabel','enable','flag','item'};
tf  = ismember_bc2(field2del,fieldnames(EEG.event)');

if rwwarn && nnz(tf)>0
        question = ['The EEG.event field of %s contains subfield name(s) reserved for ERPLAB.\n\n'...
                'What would you like to do?\n\n'];
        
        BackERPLABcolor = [1 0.9 0.3];    % yellow
        title       = 'ERPLAB: pop_editeventlist, Overwriting Confirmation';
        oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
        set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
        button      = questdlg(sprintf(question,  EEG.setname), title,'Cancel','Overwrite them', 'Continue as it is', 'Overwrite them');
        set(0,'DefaultUicontrolBackgroundColor',oldcolor)
        
        if strcmpi(button,'Continue as it is')
                fprintf('|WARNING: Fields found in EEG.event that has ERPLAB''s reserved names will not be overwritten.\n\n');
        elseif strcmpi(button,'Cancel') || strcmpi(button,'')
                return
        elseif strcmpi(button,'Overwrite them')
                %bepoch bini binlabel codelabel duration enable flag item latency type urevent
                EEG.event = rmfield(EEG.event, field2del(tf));
                fprintf('|WARNING: Fields found in EEG.event that has ERPLAB''s reserved names were overwritten.\n\n')
        end
end

%
% Delete white spaces from alphanumeric event codes (if any)
%
%EEG = wspacekiller(EEG, 0);

%
% Get EVENTLIST
%
if isfield(EEG, 'EVENTLIST')    % from EEG.EVENTLIST
        EVENTLIST = EEG.EVENTLIST;
        
        %
        % Creates an EVENTLIST.eventinfo in case there was not one.
        %
        if ~isfield(EVENTLIST, 'eventinfo')
                fprintf('\nCreating an EVENTINFO by the first time...\n');
                
                %
                % subroutine
                %
                EVENTLIST = creaeventinfo(EEG, boundarystrcode, newboundarynumcode, alphanum);
        else
                if isempty(EVENTLIST.eventinfo)
                        fprintf('\nCreating an EVENTINFO by the first time...\n');
                        
                        %
                        % subroutine
                        %
                        EVENTLIST = creaeventinfo(EEG, boundarystrcode, newboundarynumcode, alphanum);
                end
        end
        if ~isfield(EVENTLIST, 'bdf')
                EVENTLIST.bdf = [];
        end
        if ~isfield(EVENTLIST, 'nbin')
                EVENTLIST.nbin = 0;
        end
        if ~isfield(EVENTLIST, 'trialsperbin')
                EVENTLIST.trialsperbin = [];
        end
else % from EEG.event
        EVENTLIST = [];
        fprintf('\nCreating an EVENTINFO by the first time...\n');
        
        %
        % subroutine
        %
        EVENTLIST      = creaeventinfo(EEG, boundarystrcode, newboundarynumcode, alphanum);
        EVENTLIST.bdf  = [];
        EVENTLIST.nbin = 0;
        EVENTLIST.trialsperbin = [];
end

EVENTLIST.setname = EEG.setname;

% % % if alphanum==1
% % %
% % %       %
% % %       % Delete alphabetic character(s) from alphanumeric event codes (if any)
% % %       %
% % %       [EEG, EVENTLIST]= letterkilla(EEG, EVENTLIST);
% % % end

%
% Get EVENTLIST editions (if any)
%
if ~strcmp(editlistname,'') && ~strcmp(editlistname,'no') && ~strcmp(editlistname,'none')
        if isempty(editlistname)
                error('ERPLAB says: Invalid editlist name')
        end
        
        inputLine = readeditedlist(editlistname);
        nline     = length(inputLine);
        
        if nline>=1
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%% a) detects by event code (number), assigns event label          %%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                xbin = []; % bin number accumulator
                disp('Assigning code labels to numeric codes. Looking for numeric codes...')
                
                for i=1:nline
                        codex = str2num(inputLine{i}{1});
                        if isnumeric([EVENTLIST.eventinfo.code])
                                indxm = find([EVENTLIST.eventinfo.code] == codex);
                                if ~isempty(indxm)
                                        codelabelx = inputLine{i}{2};
                                        if strcmpi(codelabelx,'')
                                                codelabelx = '""';
                                        end
                                        
                                        [EVENTLIST.eventinfo(indxm).codelabel] = deal(codelabelx);
                                        
                                        if ~strcmpi(codelabelx,'""')
                                                fprintf('\n #: Event codes %g were labeled %s . \n', codex, codelabelx);
                                        end
                                end
                                
                                %
                                % Bin assignment
                                %
                                numbin = str2num(inputLine{i}{3});
                                prebin = [EVENTLIST.eventinfo(indxm).bini]; % previous bin(s)
                                prebin(prebin<1)=[]; % only valid bin indexes
                                binlabelx = inputLine{i}{4};
                                
                                if strcmpi(binlabelx,'')
                                        binlabelx = '""';
                                end
                                if ~isempty(numbin) && ~isempty(indxm)   % bin was specified, code was found
                                        binII = unique_bc2([numbin prebin]);
                                        [EVENTLIST.eventinfo(indxm).bini] = deal(binII);
                                        fprintf('\n #: Event codes %g were bined %d . \n', codex, numbin);
                                        [EVENTLIST.eventinfo(indxm).binlabel]  = deal(binlabelx);
                                        
                                        if ~strcmpi(binlabelx,'""')
                                                fprintf('\n #: Event codes %g were bin-labeled %s . \n', codex, binlabelx);
                                        end
                                        
                                        EVENTLIST.bdf(numbin).description = binlabelx;
                                        EVENTLIST.bdf(numbin).namebin     = ['BIN' num2str(numbin)];
                                elseif ~isempty(numbin) && isempty(indxm) % bin was specified, code was not found
                                        EVENTLIST.bdf(numbin).description = binlabelx;
                                        EVENTLIST.bdf(numbin).namebin     = ['BIN' num2str(numbin)];
                                elseif isempty(numbin) && ~isempty(indxm)  % bin was not specified, code was found
                                        [EVENTLIST.eventinfo(indxm).bini] = deal(-1);
                                        [EVENTLIST.eventinfo(indxm).binlabel] = deal('""');
                                else
                                        fprintf('\n\nWARNING:  Event code %g was not found at %s .\n\n', codex, EEG.setname)
                                end
                        end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%% b) detects by event label, assigns event number       %%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                disp('Assigning numeric codes to alphanumeric codes. Moving alphanumeric codes to code labels. Looking for alphanumeric codes...')
                
                for i=1:nline
                        codelabelx = inputLine{i}{2};
                        if ~strcmpi(codelabelx,'""') && ~strcmpi(codelabelx,'')
                                indxm  = find(ismember_bc2({EVENTLIST.eventinfo.codelabel}', codelabelx));
                                if ~isempty(indxm)
                                        
                                        codex = str2num(inputLine{i}{1});
                                        [EVENTLIST.eventinfo(indxm).code] = deal(codex);
                                        fprintf('\n #: Event codelabels %s were encoded %d . \n', codelabelx, codex);
                                end
                                
                                numbin = str2num(inputLine{i}{3});
                                prebin = [EVENTLIST.eventinfo(indxm).bini]; % previous bin(s)
                                prebin(prebin<1)=[]; % only valid bin indexes
                                binlabelx = inputLine{i}{4};
                                
                                if strcmpi(binlabelx,'')
                                        binlabelx = '""';
                                end
                                if ~isempty(numbin) && ~isempty(indxm)
                                        binII = unique_bc2([numbin prebin]);
                                        [EVENTLIST.eventinfo(indxm).bini] = deal(binII);
                                        xbin = [xbin numbin];
                                        
                                        [EVENTLIST.eventinfo(indxm).binlabel]  = deal(binlabelx);
                                        
                                        if ~strcmpi(binlabelx,'""')
                                                fprintf('\n #: Event codes %g were bin-labeled %s . \n', codex, binlabelx);
                                        end
                                        
                                        EVENTLIST.bdf(numbin).description = binlabelx;
                                        EVENTLIST.bdf(numbin).namebin     = ['BIN' num2str(numbin)];
                                        
                                        if numbin>0
                                                fprintf('\n #: Event codelabels %s were bined %d . \n', codelabelx, numbin);
                                        end
                                elseif ~isempty(numbin) && isempty(indxm)
                                        EVENTLIST.bdf(numbin).description = binlabelx;
                                        EVENTLIST.bdf(numbin).namebin     = ['BIN' num2str(numbin)];
                                elseif isempty(numbin) && ~isempty(indxm)
                                        if isempty(prebin)
                                                [EVENTLIST.eventinfo(indxm).bini] = deal(-1);
                                                [EVENTLIST.eventinfo(indxm).binlabel] = deal('""');
                                        end
                                else
                                        fprintf('\n\nWARNING:  Event codelabel %s was not found at %s .\n\n', codelabelx, EEG.setname)
                                end
                        end
                end
                
                lbin = length(EVENTLIST.bdf);
                ubin = 1:lbin;
                countrb   = zeros(1, lbin); % trial per bin counter
                binaux    = [EVENTLIST.eventinfo.bini];
                binhunter = sort(binaux(binaux>0)); %8/19/2009
                
                if lbin>=1
                        [c, detbin] = ismember_bc2(ubin,binhunter);
                        detnonz    = nonzeros(detbin)';
                        if ~isempty(detnonz)
                                countra = [detnonz(1) diff(detnonz)];
                                countrb(c) = countra;
                        end
                        EVENTLIST.trialsperbin = countrb;
                        EVENTLIST.nbin  = length(EVENTLIST.trialsperbin);
                else
                        EVENTLIST.trialsperbin = 0;
                        EVENTLIST.nbin  = 0;
                end
                if EVENTLIST.nbin~=max(ubin)
                        error('ERPLAB says: Number of bin was wrongly assigned. Please, contact to javlopez@ucdavis.edu.')
                end
                
                lenbdf = length(EVENTLIST.bdf);
                
                if lenbdf<max(ubin)
                        EVENTLIST.bdf(max(ubin)).description = '""';
                        EVENTLIST.bdf(max(ubin)).namebin     = ['BIN' num2str(max(ubin))];
                end
                
                %
                % Complete EVENTLIST.bdf field
                %
                for h=1:max(ubin)
                        if isempty(EVENTLIST.bdf(max(ubin)).description)
                                EVENTLIST.bdf(h).description = '""';
                                EVENTLIST.bdf(h).namebin     = ['BIN' num2str(h)];
                        end
                end
        end
end

%
% What to do with the EVENTLIST
%
% option2do = 7;  % do all
% option2do = 6;  % workspace & current data
% option2do = 5;  % workspace & text
% option2do = 4;  % workspace only
% option2do = 3;  % current data & text
% option2do = 2;  % current data only
% option2do = 1;  % text only

if ismember_bc2(option2do,[1 3 5 7]) % text
        [EEG, EVENTLIST] = creaeventlist(EEG, EVENTLIST, newelname);
else
        [EEG, EVENTLIST] = creaeventlist(EEG, EVENTLIST);
end
if ismember_bc2(option2do,[2 3 6 7]) % current data
        EEG = pasteeventlist(EEG, EVENTLIST, 1); % joints both structs
        EEG = creabinlabel(EEG);
        if updateEEG
                EEG = pop_overwritevent(EEG,'code');
        end
        [EEG, serror] = sorteegeventfields(EEG);
        EEG = eeg_checkset(EEG, 'eventconsistency');
        fprintf('\n #: New EVENTLIST structure was attached to the EEG strucure.\n\n');
end
if ismember_bc2(option2do,[4 5 6 7]) % workspace
        assignin('base', 'EVENTLIST', EVENTLIST);
        fprintf('\n #: New EVENTLIST structure was sent to workspace.\n\n');
end

%
% Generate equivalent command (for history)  (most)
%
skipfields = {'EEG', 'History'};
fn  = fieldnames(p.Results);
com = sprintf( '%s  = pop_editeventlist( %s ', inputname(1), inputname(1));
for q=1:length(fn)
        fn2com = fn{q};
        if ~ismember_bc2(fn2com, skipfields)
                fn2res = p.Results.(fn2com);
                if ~isempty(fn2res)
                        if ischar(fn2res)
                                if ~strcmpi(fn2res,'off') && ~strcmpi(fn2res,'no') && ~strcmpi(fn2res,'none')
                                        com = sprintf( '%s, ''%s'', ''%s''', com, fn2com, fn2res);
                                end
                        elseif isnumeric(fn2res)
                                fn2resstr = vect2colon(fn2res, 'Sort','on');
                                fnformat = '%s';
                                com = sprintf( ['%s, ''%s'', ' fnformat], com, fn2com, fn2resstr);
                        elseif iscell(fn2res)
                                if isnumeric(fn2res{1})
                                        fn2resstr = vect2colon(cell2mat(fn2res), 'Sort','on');
                                else
                                        b = regexprep(fn2res, '(\S)*',' \''$1\'' ');
                                        fn2resstr = [b{:}];
                                end
                                fnformat = '{%s}';
                                com = sprintf( ['%s, ''%s'', ' fnformat], com, fn2com, fn2resstr);
                        else
                                if iscell(fn2res)
                                        fn2resstr = vect2colon(cell2mat(fn2res), 'Sort','on');
                                        fnformat = '{%s}';
                                else
                                        fn2resstr = vect2colon(fn2res, 'Sort','on');
                                        fnformat = '%s';
                                end
                                com = sprintf( ['%s, ''%s'', ' fnformat], com, fn2com, fn2resstr);
                        end
                end
        end
end
com = sprintf( '%s );', com);

% get history from script. EEG
switch shist
        case 1 % from GUI
                com = sprintf('%s %% GUI: %s', com, datestr(now));
                %fprintf('%%Equivalent command:\n%s\n\n', com);
                displayEquiComERP(com);
        case 2 % from script
                EEG = erphistory(EEG, [], com, 1);
        case 3
                % implicit
        otherwise %off or none
                com = '';
end

%
% Completion statement
%
prefunc = dbstack;
nf = length(unique_bc2({prefunc.name}));
if nf==1
        msg2end
end
return

%--------------------------------------------------------------------------
function inputLine2 = readeditedlist(editlistname)

disp(['For pre-edited list of changes, user selected  <a href="matlab: open(''' editlistname ''')">' editlistname '</a>'])

fid_edition = fopen( editlistname );
formcell    = textscan(fid_edition, '%[^\n]', 'whitespace', '');
fclose(fid_edition);
inputLine1    = cellstr(formcell{:});
strtok = regexp(inputLine1, '([-+]*\d+)\s*"(.*)"\s*(\d+|[[]]+)\s*"(.*)"', 'tokens');
strtok = strtok(~cellfun('isempty',strtok));
nline  = length(strtok);
inputLine2 = cell(1,nline);

for m=1:nline
        inputLine2{m} = strtok{m}{1};
end
end

end