%% DOCUMENTATION
%
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com)
% DATE: June 16th, 2016
% 
% FILE:     reexport_log2text.m
% PURPOSE:  To recreate EEG-suitable text files from presentation logfiles
%           (will also identify any port conflicts).
% USAGE:    Click "Re-Export Text Files" in GUI after completing Data Setup.
% 
% DESCRIPTION: The original text files created during testing (OTT/MCT study) 
%   do not include all relevant events (e.g., all responses, beginning of trial,
%   etc), which causes the EEG and Presentation events to not match up when 
%   syncing the timing later on. This script recreates those text files (in the 
%   relevant logfile directories) to include all relevant events. It also reads
%   the logfiles to determine if there were any conflicts on the port which
%   prevented the Presentation events from being sent to the EEG computer
%   (these will be added back in during syncEEGtiming.m)
% 
% REQUIREMENTS
%   1)  Directory structure (see 'help runEEG')
%   2)  Woodward Lab MCT/OTT BADE, FISH, or WM data only.
%
% INSTRUCTIONS
%   -   Once you have run Data Setup, click on Re-Export Text Files
%   -   It will check if there are any missing codes listed at the bottom 
%       of each logfile. For runs with missing codes (i.e., presentation codes 
%       that were not sent to the EEG computer), a new file will be created 
%       which is used later on.
%   -   Script will go through all subjects/sessions/tasks/runs, open the
%       logfile and recreate the text file with all events.
% 
% OUTPUT
%   -   Will output [SubjID][suffix]_[RunID]_eventTiming_[task]_fixed.txt & *_missingcodes.txt files in the relevant logfile directories
%   -   Errors will output to the command window.
%%
function reexport_log2text(run_struct, subjID, suffix, sessionID, taskID)
    % MCT/OTT STUDY ONLY!
    if strcmp(taskID, 'BADE')
        task = 1;
    elseif strcmp(taskID, 'FISH')
        task = 2;
    elseif strcmp(taskID, 'WM')
        task = 3;
    else
        fprintf(['\n' subjID ' ' sessionID ' ' taskID ': Not a valid task ID!'])
        return
    end
    
    logfiles=dir(fullfile(run_struct.datasetup.datadir, subjID, sessionID, 'logfiles', taskID, '*.log'));
    logfiles=logfiles(~strncmpi('.',{logfiles.name},1)); % Remove hidden files (files starting with '.')
    if size(logfiles,1) == 0
        fprintf(['\n' subjID suffix ' ' sessionID ': No logfiles found!']);
        return
    end
    for r = 1: size(logfiles,1)
        fid=fopen(fullfile(run_struct.datasetup.datadir, subjID, sessionID, 'logfiles', taskID, logfiles(r).name));
        [logfile] = textscan(fid, repmat('%q',1,16),'delimiter','\t','headerlines', 3,'CollectOutput',1);
        logfile=logfile{1};
        fclose(fid);

        eventcode=logfile(2:end,4);
        time_cell=logfile(2:end,5);
        uncertainty_cell=logfile(2:end,7);
        time=cellfun(@(time_cell)str2double(time_cell), time_cell);
        uncertainty=cellfun(@(uncertainty_cell)str2double(uncertainty_cell), uncertainty_cell);
        time=round(time/10);                % conversion of time & uncertainty to ms and rounding to
        uncertainty=round(uncertainty/10);  % nearest integer (required to find proper missed codes!)
        time=time+uncertainty; % adding uncertainty to time improves precision

        % IDENTIFY MISSING PORT CODES
        missed_codes = logfile(strmatch('The following output port codes were not sent because of a conflict on the port', logfile):end,1:3);
        if ~isempty(missed_codes)
            fprintf(['\n' subjID suffix ' ' taskID ' Run' num2str(r) '...\tPort conflict found!'])
            missing = 1;
            % FIND MISSING CODES
            idx=cell([1,size(missed_codes,1)-2]);
            for i = 1:size(missed_codes,1)-2
                code=round(str2num(missed_codes{i+2,3}));
                if size(find(time==code),1)>1
                    fprintf(['\n\t' num2str(size(find(time==code),1)) ' instances of code ' num2str(code) ' found! Last entry used.'])
                    a = find(time==code);
                    idx(1,i) = {a(size(a,1))};
                else
                    idx(1,i) = {find(time==code)};
                end
                if isempty(idx{1,i})
                    fprintf(['\n\tWARNING: Event ' num2str(code) ' not found in logfile!'])
                end
            end
            if max(cellfun('isempty', idx)) == 0
                fprintf('\n\tOK!');
            end
        else
            missing = 0;
        end

        newtxt=[num2cell(time), eventcode];

        switch task
            case 1 % BADE
                % CREATE CONDITION COLUMN
                condition={};
                pic=0;
                for j = 1:size(newtxt,1)
                    if strcmp(logfile(j+1,3), 'Quit') == 1
                        condition{j,1} = 'Quit';
                    elseif strcmp(newtxt{j,2}, 'thanks') == 1
                        condition{j,1} = 'EndTrial';
                        newtxt(j+1:end,:) = [];
                        break
                    elseif strcmp(newtxt{j,2},'9')
                        condition{j,1} = 'StartTrial';
                    elseif strcmp(newtxt{j,2}, 'fixation')
                        condition{j,1} = 'fixation';                                
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'sync_eeg*')) == 1
                        condition{j,1} = 'sync_eeg';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', '*_*')) == 1
                        condition{j,1} = newtxt{j,2}(length(newtxt{j,2})-2:end);
                        pic = str2num(condition{j,1}(3));
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'ITI*')) == 1
                        condition{j,1} = 'ITI';
                    elseif strcmp(newtxt{j,2},'1') || strcmp(newtxt{j,2},'2')
                        condition{j,1} = 'Response';
                        if newtxt{j,2} == '1'
                            resp = 'Y';
                        elseif newtxt{j,2} == '2'
                            resp = 'N';
                        end
                        if strcmp(newtxt{j+1,2},'1') == 0 && strcmp(newtxt{j+1,2},'2') == 0
                            if pic == 3 || pic == 0
                                continue
                            elseif pic == 1
                                if strcmp(condition{j-1}(pic), resp) == 1
                                    condition{j,1} = 'correct';
                                elseif strcmp(condition{j-1}(pic), resp) == 0
                                    condition{j,1} = 'incorrect';
                                end
                            elseif pic == 2
                                if strcmp(condition{j-2,1}, 'incorrect') == 1
                                    condition{j,1} = 'incorrect';
                                elseif strcmp(condition{j-2,1}, 'correct') == 1
                                    if strcmp(condition{j-1}(pic), resp) == 1
                                        condition{j,1} = 'correct';
                                    elseif strcmp(condition{j-1}(pic), resp) == 0
                                        condition{j,1} = 'incorrect';
                                        condition{j-2,1} = 'incorrect';
                                    end
                                end
                            end
                        end
                    end
                end
            case 2 % FISH
                condition={};
                corresp = 0;
                for j = 1:size(newtxt,1)
                    if strcmp(logfile(j+1,3), 'Quit') == 1
                        condition{j,1} = 'Quit';
                    elseif strcmp(newtxt{j,2}, 'thanks') == 1
                        condition{j,1} = 'EndTrial';
                        newtxt(j+1:end,:) = [];
                        break
                    elseif strcmp(newtxt{j,2},'9')
                        condition{j,1} = 'StartTrial';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'sync_eeg*'))
                        condition{j,1} = 'sync_eeg';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', '*focal*'))
                        if strcmp(newtxt{j,2}(1), '0')
                            condlr = 'L';
                        elseif strcmp(newtxt{j,2}(1), '1')
                            condlr = 'R';
                        end
                        uscores=strfind(newtxt{j,2},'_');
                        if strcmp(newtxt{j,2}(uscores(1)+1:uscores(1)+2),'80')
                            condflk = '80pc';
                            percfoc = 80;
                        elseif strcmp(newtxt{j,2}(uscores(1)+1:uscores(1)+2),'20')
                            condflk = '20pc';
                            percfoc = 20;
                        end
                        if strcmp(newtxt{j,2}(uscores(2)+1:uscores(2)+2),'10')
                            condalk = '10altPc';
                            percalt = 10;
                        elseif strcmp(newtxt{j,2}(uscores(2)+1:uscores(2)+2),'90')
                            condalk = '90altPc';
                            percalt = 90;
                        end
                        condition{j,1}=[condlr '_' condflk '_' condalk];
                        if percfoc > percalt
                            corresp = '1';
                        elseif percalt > percfoc
                            corresp = '2';
                        end
                    elseif strcmp(newtxt{j,2}, '100') || strcmp(newtxt{j,2}, '101')
                        condition{j,1} = 'ITI';
                    elseif strcmp(newtxt{j,2},'1') || strcmp(newtxt{j,2},'2')
                        if corresp == 0
                            condition{j,1} = 'Response';
                        elseif newtxt{j,2} == corresp
                            condition{j,1} = 'correct';
                        else
                            condition{j,1} = 'incorrect';
                        end
                    end 
                end
            case 3 % WM
                condition={};
                corresp = 0;
                for j = 1:size(newtxt,1)
                    if strcmp(logfile(j+1,3), 'Quit')
                        condition{j,1} = 'Quit';
                    elseif strcmp(newtxt{j,2}, 'thanks')
                        condition{j,1} = 'EndTrial';
                        newtxt(j+1:end,:) = [];
                        break
                    elseif strcmp(newtxt{j,2},'9')
                        condition{j,1} = 'StartTrial';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'sync_eeg*'))
                        condition{j,1} = 'sync_eeg';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', '#*#'))
                        condition{j,1} = 'encode4';
                        encodestr = newtxt{j,2};
                        encodenum = '4';
                    elseif min(isletter(newtxt{j,2})) == 1 && sum(isletter(newtxt{j,2})) == 6
                        condition{j,1} = 'encode6';
                        encodestr = newtxt{j,2};
                        encodenum = '6';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'iti*'))
                        condition{j,1} = 'ITI';
                    elseif regexp(newtxt{j,2}, regexptranslate('wildcard', 'delay*'))
                        condition{j,1} = 'delay';
                    elseif min(isletter(newtxt{j,2})) && sum(isletter(newtxt{j,2}))
                        if isnumeric(strfind(encodestr,newtxt{j,2}))
                            condition{j,1} = ['probe' encodenum 'yes'];
                            corresp = '1';
                        else
                            condition{j,1} = ['probe' encodenum 'no'];
                            corresp = '2';
                        end
                    elseif strcmp(newtxt{j,2},'1') || strcmp(newtxt{j,2},'2')
                        if corresp == 0
                            condition{j,1} = 'Response';
                        elseif newtxt{j,2} == corresp
                            condition{j,1} = 'correct';
                        else
                            condition{j,1} = 'incorrect';
                        end
                    end 
                end
        end

        try
            newtxt=[newtxt(:,1), condition, newtxt(:,2)];
        catch
            fprintf(['\n' subjID suffix ' ' taskID ' Run' num2str(r) '...\tERROR: Please check logfile for missing data!'])
            break
        end

        if missing == 1
            skipped = 0;
            code_txt=cell(size(idx,2),3);
            for k = 1: size(idx,1)
                try
                    code_txt(k,:) = newtxt(idx{k},:);
                catch
                    skipped = skipped + 1;
                    fprintf(['\n\tEvent ' missed_codes{k+2,3} ' skipped!'])
                end
            end
        end

        del=0;
        switch task
            case 1 % BADE
                % DELETE IRRELEVANT LINES
                for x = 1:size(eventcode,1)
                    if regexp(eventcode{x,1}, regexptranslate('wildcard', 'ITI*'))
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(eventcode{x,1}, 'fixation')
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(logfile{x+1,3}, 'Quit')
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(eventcode{x,1}, 'thanks')
                        newtxt(x-del:end,:) = [];
                        del = del+1;
                        break
                    end
                    if missing == 1
                        for y = 1:size(idx,2)
                            if x == idx{y}
                                newtxt(x-del,:) = [];
                                del = del+1;
                            end                            
                        end
                    end
                end
            case 2 % FISH
                for x = 1:size(eventcode,1)
                    if strcmp(eventcode{x,1}, '100') || strcmp(eventcode{x,1}, '101')
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(logfile{x+1,3}, 'Quit')
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(eventcode{x,1}, 'thanks')
                        newtxt(x-del:end,:) = [];
                        del = del+1;
                        break
                    end
                    if missing == 1
                        for y = 1:size(idx,2)
                            if x == idx{y}
                                newtxt(x-del,:) = [];
                                del = del+1;
                            end                            
                        end
                    end
                end
            case 3 % WM
                % DELETE IRRELEVANT LINES
                for x = 1:size(eventcode,1)
                    if regexp(eventcode{x,1}, regexptranslate('wildcard', 'iti*')) == 1
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif regexp(eventcode{x,1}, regexptranslate('wildcard', 'delay*')) == 1
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(logfile{x+1,3}, 'Quit') == 1
                        newtxt(x-del,:) = [];
                        del = del+1;
                    elseif strcmp(eventcode{x,1}, 'thanks') == 1
                        newtxt(x-del:end,:) = [];
                        del = del+1;
                        break
                    end
                    if missing == 1
                        for y = 1:size(idx,2)
                            if x == idx{y}
                                newtxt(x-del,:) = [];
                                del = del+1;
                            end                            
                        end
                    end
                end
        end

        fid4 = fopen(fullfile(run_struct.datasetup.datadir, subjID, sessionID, 'logfiles', taskID, [subjID suffix '_run' num2str(r) '_eventTiming_' lower(taskID) '_fixed.txt']), 'wt+'); % Will overwrite previous text files!
        fprintf(fid4,'Time(ms)\tCondition\tEvent Code\n');
        for a = 1:size(newtxt,1)
            fprintf(fid4,'%d\t%s\t%s\n', newtxt{a,1}, newtxt{a,2}, newtxt{a,3});
        end
        if missing == 1
            if skipped < size(idx,2)
                fid5 = fopen(fullfile(run_struct.datasetup.datadir, subjID, sessionID, 'logfiles', taskID, [subjID suffix '_run' num2str(r) '_eventTiming_' lower(taskID) '_missingcodes.txt']), 'wt+');
                fprintf(fid5,'Time(ms)\tCondition\tEvent Code\r\n');
                for b = 1:size(code_txt,1)
                    fprintf(fid5,'%d\t%s\t%s\r\n', code_txt{b,1}, code_txt{b,2}, code_txt{b,3});
                end
            end
        end            
        fclose('all');                
    end % END RUN LOOP
end