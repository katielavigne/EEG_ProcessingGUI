% Load all EEG.set files in folder and check num chans and max value of
% each channel

clear
clc
datadir = uigetdir(pwd, 'Select Processed Data Directory');

[result files] = system(['find ' datadir  ' -name *raw.set']);
files=strsplit(files,'\n');
files = files(1:end-1);

for i=1:size(files,2)
    emptychans = [];
    EEG = pop_loadset(files{i});
    numchans = EEG.nbchan;
    disp([EEG.subject ': ' num2str(numchans) ' channels'])
    for j=1:numchans
        chanval = sum(EEG.data(j,:));
        if chanval == 0
            emptychans = [emptychans, j];
        end
    end
    
    disp(['Empty channels: ' num2str(emptychans)])
    clear EEG
end
        
    