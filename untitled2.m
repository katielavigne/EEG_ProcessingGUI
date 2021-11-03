% TIME FREQUENCY ANALYSIS
subj = EEG.subject;
nchans = EEG.nbchan;
numtrials = EEG.trials;
samplerate = EEG.srate;
numconds = 4;


% 1. DEFINE TRIALS
cfg = [];
cfg.dataset = fullfile(EEG.filepath, EEG.filename);
cfg.trialfun = 'bade_trialfun';
cfg.trialdef.pre = 0.5;
cfg.trialdef.post = 10;

cfg.cond = 'YY1';
                
cfg = ft_definetrial(cfg);

% 2. PREPROCESSING
cfg.continuous = 'no';
cfg.demean = 'yes';
data = ft_preprocessing(cfg);

% 3. FREQUENCY ANALYSIS
cfg=[];
cfg.method      = 'mtmconvol';
cfg.output      = 'pow';
cfg.channel = 'eeg';
cfg.trials     = 'all'; %or a selection given as a 1xN vector (default = 'all')
cfg.keeptrials  = 'no';    
cfg.keeptapers  = 'no'; 
cfg.foi      = 2:0.5:60;

%hanning
cfg.taper       = 'hanning';

%dpss
% cfg.taper       = 'dpss';
cfg.tapsmofrq = 2;

cfg.t_ftimwin = ones(length(cfg.foi)).*0.5; % 500 ms windows 
cfg.toi = -0.35:0.01:9.5;


TFRdata = ft_freqanalysis(cfg, data);

% VISUALIZATION


%% Multiplot

cfg = [];
cfg.baseline     = [-0.35 0.0]; 
cfg.baselinetype = 'absolute';          % if i used a relative baseline, the results looked terrible
%cfg.xlim         = [-0.35 9.5];         % this specifies which time points get plotted, if it is blank the whole trial is displayed
% cfg.zlim         = [-3e-27 3e-27];	% % min and max power values A.K.A. thresholds for display (changed from -27 to -29 in the examples I sent)       
%cfg.zlim         = 'maxmin';
%cfg.zlim         = [-5000 5000]        
cfg.ylim         = [0 60];	        % frequency range to display  
% cfg.ylim         = [30 100];
cfg.showlabels   = 'yes';	
cfg.layout       = TFRdata.elec;        % this will need to be changed as this is MEG specific
% cfg.renderer     = 'painters';          % i was getting weird plotting errors (nothing would show up or it would just be a glitchy image so I read that I should specify this)
cfg.interactive  = 'yes';               %this means you can click on stuff on the graph to get a closer view, or draw a box around multiple sensors to get an averaged view
fig1=figure;
ft_multiplotTFR(cfg, TFRdata);
set(fig1, 'Position', [ 53 7 1789 967]); % positions graph on one screen adn not in the middle of both screens... maybe unnecessary for you 


%% Singleplot

cfg = [];
cfg.baseline     = [-0.35 0.0];
cfg.baselinetype = 'absolute';  
cfg.maskstyle    = 'saturation';
cfg.renderer     = 'painters';
cfg.xlim         = [-0.35 9.5];
% cfg.zlim         = [-5 5];	% changed from -27 to -29
cfg.ylim         = [0 60];	        
cfg.channel      = 'all';
fig2=figure; 
ft_singleplotTFR(cfg, TFRdata);
set(fig2,'Position',[710   431   687   509]);


%% Topoplot  %% I almost always just ran it to here. The stuff below makes topoplots and movies and whatnot but I never messed around with it too much. 

cfg = [];
cfg.baseline     = [0.5 0.0];	
cfg.baselinetype = 'absolute';
cfg.xlim         = [0.1 .20];   
cfg.zlim         = [-3e-28 3e-28];
%cfg.ylim         = [8 12];
cfg.showlabels   = 'markers';
fig3=figure; 
ft_topoplotTFR(cfg, TFRdata);
set(fig3,'Position',[398   262   965   673]);

% %OLD EEGGUI.M TF code
% % --- Executes on button press in tfanalysis.
% function tfanalysis_Callback(hObject, eventdata, handles)
% % hObject    handle to tfanalysis (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% handles.run_type = 'timefrequency';
% 
% type = questdlg('Select Time-Frequency Method:', 'TF Type', 'Wavelet', 'Hanning', 'Wavelet');
% 
% handles.timefreq.type = lower(type);
% 
% switch type
%     case 'Wavelet'
%         prompt = {'Width', 'Length', 'FOI', 'TOI'};
%         title = 'Input Options';
%         defaultanswers = {'7', '2', '2:0.5:50', '-0.35:0.01:9.5'};
%         answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
%         if isempty(answer)
%             return
%         elseif ~strcmp(answer(1),'') && ~strcmp(answer(2),'') && ~strcmp(answer(3),'') && ~strcmp(answer(4),'')
%             handles.wavelet.width = str2num(answer{1});
%             handles.wavelet.length = str2num(answer{2});
%             handles.wavelet.foi = str2num(answer{3});
%             handles.wavelet.foitext = answer{3};
%             handles.wavelet.toi = str2num(answer{4});
%             handles.wavelet.toitext = answer{4};
%         end
%     case 'Hanning'
%         prompt = {'Windows (ms)'};
%         title = 'Input Options';
%         defaultanswers = {'400'};
%         answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
%         if isempty(answer)
%             return
%         elseif ~strcmp(answer(1),'')
%             handles.hanning.windows = str2num(answer{1})/1000;
%         end
% end
% guidata(hObject, handles)
% run_Callback(hObject, eventdata, handles)
% 
% 
% % --- Executes on button press in TFplot.
% function TFplot_Callback(hObject, eventdata, handles)
% % hObject    handle to TFplot (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% handles.run_type = 'timefrequencyplot';
% guidata(hObject, handles)
% run_Callback(hObject, eventdata, handles)