%% DOCUMENTATION
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com)
% DATE: June 16th, 2016
% 
% FILE:     runEEG.m
% PURPOSE:  Performs EEG processing through GUI.
% USAGE:    Type runEEG in command window.
% 
% DESCRIPTION: This script will open EEGlab and the EEG Processing GUI (which is based on the Woodward
% Lab EEG manual (Located on /cfrifs02/WoodwardLab/EEG/analysisProtocol/Book1_preprocessing/EEG_AnalysisProtocol_oct13_2015). 
% The GUI will most likely only work for MCT/OTT, and BADE/FISH/WM tasks, because of the
% way it's been coded based on the particulars of these studies.
% 
% REQUIREMENTS:
%   1) Folders and filenames cannot contain spaces
%       - Useful linux command line scripts for removing spaces from filenames
%           1.  find [path to parent directory] -depth -name "* *" -execdir rename 's/ /_/g' "{}" \;
%               (Use rename -f to force rename and overwrite files if necessary)
%           2.  IFS="\n"
%               for file in s*/*; 
%               do 
%                   mv "$file" "${file//[[:space:]]}";
%               done
%
%   2) Subject IDs in folders and filenames must be consistent (including case)
%       - Useful linux command for renaming files
%           -   find [path to parent directory] -depth -iname "*wildcard*"
%           | while read filename; do mv ${filename} ${filename}(changes)
%               e.g., find /data4/EEG/MCT -depth -iname "*s76*" | while
%               read filename; do mv ${filename} ${filename//s76/S076}
%               (will replace all s76 and S76 with S076)
%
%   3) Folder structure MUST be as follows: 
%           Data directory  
%             - Subject
%               - Session (T1/T3)
%                 - EEG_data
%                   - Task (BADE/WM/FISH)
%                     - RAW/MAT
%                       - If RAW, Run folders (Run1/Run2/Run3/Run4)
%                         - .raw file for specific run
%                       - .mat file for all runs
%                 - logfiles
%                   - Task (BADE/WM/FISH)
%                     - Presentation .log files for all runs
%
%   4) Subject ID, Session, Task, and Run folders looked for are determined by user-defined, case-sensitive, wildcards, so make sure they are entered properly based on the folder names!
%       -   e.g., If folder name is 'Run1', run wildcard 'run*' will not work!; Same with 'BADE' vs 'bade' etc.
%
%   5) To avoid pop-ups and user input, only a single .raw or .mat file should be in the relevant folder, and only the relevant .log files (named in alphabetical/numerical order by run number) 
%       should be located in the logfiles directory. Data/Logfiles from extra/incomplete/aborted runs should be moved to a separate folder (e.g., a BAD_DATA folder).
%
%   6) If EEGlab isn't in your path, this script will ask you to add it.
%
%   7) Statistics Toolbox is required (for the creation of subjinfo.csv when exporting EEG events and some text files)
%
%
% INSTRUCTIONS: see EEG_GUI_Manual.docx and EEG_AnalysisProtocoll_oct13_2015.

function runEEG()

clear
clc

set(0,'DefaultUicontrolBackgroundColor', [.94 .94 .94])

% CHECK IF EEGLAB IS IN PATH
    try
        eeglab
    catch
        EEGLab_path = uigetdir(pwd, 'Select EEGLab Directory');
        addpath(EEGLab_path)
        eeglab
    end
    
    eegGUI
end