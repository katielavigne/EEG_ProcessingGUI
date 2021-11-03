% use this script to perform time-frequency analysis 
% edit accordingly to list your own data file(s) and conditions. Edit
% cfg.binLabel for single trial data, and cfg.codeLabel for erp data.
% define data file 
dsname = '/data/PROJECTS/MCT-OTT-PhD/Data/EEG/OTT/test/H001a_T1_BADE_epochs.set';
% set up preprocessing 
% find the interesting segments of data
cfg = [];                                           % empty configuration
cfg.dataset                 = dsname;       % name of EEG dataset  
cfg.trialfun                = 'bade_trialfun'; % function that segments data according to selected parameters
cfg.codeLabel               = 'YN1'; % can define conditions of interest either with a code label or with a bin number. Program will default to bin number if it is defined.
cfg.binNumber                = 0; % enter desired bin number from bdf file. If you want to use code labels instead, set this to 0.
cfg.epochBaseInt = -0.5; % total baseline interval in data file
cfg.epochInt = 4; % total post-stim interval in data file
cfg.trialdef.prestim        = cfg.epochBaseInt - 0.01; %baseline to extract (need to leave 10 ms gap)
cfg.trialdef.poststim       = cfg.epochInt - 0.01 ; % epoch to extract (need to leave 10 ms gap)
cfg = ft_definetrial(cfg);         
dataFIC = ft_preprocessing(cfg);
save dataFIC_disconfirm dataFIC; % name the data file whatever you want. Here, it is dataFIC_condX

% compute wavelet transform
% see ft_freqanalysis for information. All parameters are
% optional/changable.
cfg = [];
cfg.channel    = 'EEG';	                
cfg.trials     = 'all'; %or a selection given as a 1xN vector (default = 'all')
cfg.keeptrials = 'no'; % 'yes' or 'no', return individual trials or average (default = 'no')
cfg.output     = 'pow';	
cfg.foi        = 2:0.5:50;% what frequencies are you interested in? This is a vector of whatever length you want.
cfg.toi        = -0.35:0.01:3.5; % what times are you interested in? Can not exceed total epoch length. For individual trials, include baseline "pre" interval (event is at 0). For erps, the epoch window includes the basel9ine, but starts at 0 (event time is at 0 + baseline interval). 	
% for using a wavelet transform, use the following 3 parameters (and
% comment out the mtmconvol section)
cfg.method     = 'wavelet';
cfg.width      = 7; % width of wavelet in number of cycles (decreasing this number increases temporal resolution at the cost of frequency resolution
cfg.length     = 2; % height of wavelet in the frequency domain (i.e., spread across frequencies) 
% for using a mtmconvol transform, use the following 4 parameters (and
% comment out the wavelt section above)
% cfg.method = 'mtmconvol';
% cfg.tapsmofrq = 6;
% cfg.taper = 'hanning';
% cfg.t_ftimwin = ones(length(cfg.foi)).*0.4; % 400 ms windows
TFR = ft_freqanalysis(cfg, dataFIC);
save TFRwave_disconfirm TFR

% plot the results
cfg = [];
cfg.baseline     = [-0.35 0]; % must match baseline interval selected for cfg.toi (times of interest)
cfg.baselinetype = 'relative'; 	        
cfg.zlim         = [-3e-10 3e-10]; % power scaling (colour scaling) -
%useful for creating multiple plots with the same scale.
cfg.showlabels   = 'yes';	    
cfg.channel = [1:8:256]; % select which channels you want to include for
%averaging or multiplot layout
cfg.layout       = dataFIC.elec; % for topographic layout of electrodes
%cfg.layout = 'ordered'; % for NxN layout of electrodes, or vertical for a
%single column.
figure;
ft_multiplotTFR(cfg, TFR);
figure
ft_singleplotTFR(cfg,TFR);
figure
cfg.xlim = [30 40]; % selection of time window for topoplot (default is 'maxmin', i.e., averaged over all timepoints).
ft_topoplotTFR(cfg,TFR);
