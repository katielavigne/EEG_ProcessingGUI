%% DOCUMENTATION
%
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com) & Christine Tipper (christine.tipper@gmail.com)
% DATE: February 28th, 2017
% 
% FILE:     timefrequency.m
% PURPOSE:  Runs the selected process in the GUI.
% USAGE:    Called by clicking on a button in the GUI.
% 
% DESCRIPTION:  This script will run the process that is selected in the
% GUI.
% 
% REQUIREMENTS: see 'help runEEG'
%
%%

function [errors, p, tf] = timefrequency(run_struct, s, subjID, suffix, sessionID, taskID, p, errors, tf)
    % Fix path
    spm_path = which('spm');
    if ~isempty(spm_path)
        rmpath(genpath(spm_path))
    end
    
    ft_path = which('ft_defaults.m');
    if isempty(ft_path)
       FTpath = uigetdir(pwd, 'Select FieldTrip Directory');
       addpath(FTpath)
       ft_defaults
    end

    global EEG
    
    if s == 1
        tf = struct();
        tf.dsname = fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_epochs_marked_artrej_ICA_ICApruned.set']);
        tf.bins = listConditions(tf.dsname);
        [Selection,~] = listdlg('PromptString', 'Select Condition(s) for Time Frequency Analysis', ...
                    'SelectionMode','multiple', 'ListString', tf.bins, 'ListSize', [500,250]);
        tf.numconds = size(Selection,2);
        
        if tf.numconds == 0
            errors{size(errors,1)+1,1} = [subjID suffix ' ' sessionID ' ' taskID ': No condition selected! Time frequency analysis skipped!'];
            return
        else
            for i = 1:size(Selection,2)
                temp = strsplit(tf.bins{Selection(i)}, '  ');
                tf.bin{i} = temp{1};
                tf.codeLabel{i} = temp{2};
                tf.codeLabel(ismember(tf.codeLabel, ' ')) = [];
                tf.binNumber{i} = str2double(regexp(tf.bin{i}, '\d*', 'Match'));
            end
        end
    else
        tf.dsname = fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, [subjID suffix '_' sessionID '_' taskID '_epochs_marked_artrej_ICA_ICApruned.set']);
    end
    
    for c = 1:tf.numconds
        switch run_struct.run_type
            case 'timefrequency'
                diary(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['processinglog_' date '.txt']));
                fprintf(['\n---------------\n' datestr(clock, 0) '\n'])
                fprintf('***TIME FREQUENCY ANALYSIS***\n---------------\n');
                fprintf(['Type = ' num2str(run_struct.analysis.timefrequency.type) '\n'])
                switch run_struct.analysis.timefrequency.type
                    case 'wavelet'
                        fprintf(['Width = ' num2str(run_struct.analysis.timefrequency.width) '\n'])
                        fprintf(['Length = ' num2str(run_struct.analysis.timefrequency.length) '\n'])
                        fprintf(['Frequencies of Interest (Start:Step:End): ' run_struct.analysis.timefrequency.foi_text '\n'])
                        fprintf(['Time of Interest (Start:Step:End): ' run_struct.analysis.timefrequency.toi_text '\n'])
                    case 'hanning'
                        fprintf(['Taper = ' num2str(run_struct.analysis.timefrequency.taper) '\n'])
                        fprintf(['T_ftiwin = ' num2str(run_struct.analysis.timefrequency.t_ftiwin) '\n'])
                end

                % 1. LOAD, PROCESS, SEGMENT DATA
                cfg = [];                                           % empty configuration
                cfg.dataset = tf.dsname;                            % name of EEG dataset  
                cfg.trialfun = [lower(taskID) '_trialfun'];         % function that segments data according to selected parameters
                cfg.codeLabel = tf.codeLabel{c};                       % can define conditions of interest either with a code label or with a bin number. Program will default to bin number if it is defined.
                cfg.binNumber = tf.binNumber{c};                       % enter desired bin number from bdf file. If you want to use code labels instead, set this to 0.
                cfg.epochBaseInt = EEG.xmin;                        % total baseline interval in data file
                cfg.epochInt = round(EEG.xmax*100)/100;             % total post-stim interval in data file
                disp(['Epoch range found: ' num2str(cfg.epochBaseInt) ' - ' num2str(cfg.epochInt) '.'])
                cfg.trialdef.prestim = abs(cfg.epochBaseInt) - 0.01;     % baseline to extract (need to leave 10 ms gap)
                cfg.trialdef.poststim = cfg.epochInt - 0.01 ;       % epoch to extract (need to leave 10 ms gap)

                cfg = ft_definetrial(cfg);         
                dataFIC = ft_preprocessing(cfg);
                disp('Saving dataset...')
                save(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['dataFIC_' tf.codeLabel{c}]), 'dataFIC', '-v7.3')                    % name the data file whatever you want. Here, it is dataFIC_condX

                % 2. TIME FREQUENCY ANALYSIS

                cfg = [];
                cfg.channel    = 'EEG';	                
                cfg.trials     = 'all'; %or a selection given as a 1xN vector (default = 'all')
                cfg.keeptrials = 'no'; % 'yes' or 'no', return individual trials or average (default = 'no')
                cfg.output     = 'pow';	
                cfg.foi        = run_struct.analysis.timefrequency.foi;% what frequencies are you interested in? This is a vector of whatever length you want.
                cfg.toi        = run_struct.analysis.timefrequency.toi; % what times are you interested in? Can not exceed total epoch length. For individual trials, include baseline "pre" interval (event is at 0). For erps, the epoch window includes the basel9ine, but starts at 0 (event time is at 0 + baseline interval). 	

                switch run_struct.analysis.timefrequency.type
                    case 'wavelet'
                        cfg.method     = run_struct.analysis.timefrequency.type;
                        cfg.width      = run_struct.analysis.timefrequency.width; % width of wavelet in number of cycles (decreasing this number increases temporal resolution at the cost of frequency resolution
                        cfg.length     = run_struct.analysis.timefrequency.length; % height of wavelet in the frequency domain (i.e., spread across frequencies) 
                    case 'hanning'
                        cfg.method = run_struct.analysis.timefrequency.method;
                        cfg.tapsmofrq = run_struct.analysis.timefrequency.type;
                        cfg.taper = run_struct.analysis.timefrequency.taper;
                        cfg.t_ftimwin = run_struct.analysis.timefrequency.t_ftiwin;
                end
    
                TFR = ft_freqanalysis(cfg, dataFIC);
                disp('Saving dataset...')
                save(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['TFRwave_' tf.codeLabel{c}]), 'TFR', '-v7.3')
                diary off
            case 'timefrequencyplot'
                % Load relevant files
                load(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['dataFIC_' tf.codeLabel{c}]));
                load(fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['TFRwave_' tf.codeLabel{c}]));

                [m,n] = find(TFR.time==max(TFR.time(TFR.time<0)));
                
                % Multiplot
                cfg                 = [];
                cfg.baseline        = [TFR.time(1) TFR.time(m,n)];
                cfg.baselinetype    = 'absolute'; 	        
                cfg.zlim            = [-3e-29 3e-29]; % power scaling (colour scaling) - % useful for creating multiple plots with the same scale.
                cfg.ylim            = [0 round(max(TFR.freq))];	        % frequency range to display 
                cfg.showlabels      = 'yes';	    
                cfg.channel         = 'all'; % select which channels you want to include for averaging or multiplot layout
                cfg.layout          = dataFIC.elec; % for topographic layout of electrodes
            %     cfg.layout          = 'ordered'; % for NxN layout of electrodes, or vertical for a single column.
                cfg.renderer        = 'painters';
                cfg.interactive     = 'yes';
                fig1                  = figure;
                ft_multiplotTFR(cfg, TFR);
                saveas(fig1, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['multiplot_' tf.codeLabel '.png']));

                % Singleplot
                cfg = [];
                cfg.baseline        = [TFR.time(1) TFR.time(m,n)];
                cfg.baselinetype    = 'absolute';  
                cfg.maskstyle       = 'saturation';
                cfg.renderer        = 'painters';
            %     cfg.xlim           = [-0.5 1.5];
                cfg.zlim            = [-3e-28 3e-28];	% changed from -27 to -29
                cfg.ylim            = [0 100];	        
                cfg.channel         = 'all';
                fig2                = figure; 
                ft_singleplotTFR(cfg, TFR);
                saveas(fig2, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['singleplot' tf.codeLabel '.png']));

                % Topoplot
                cfg                 = [];
                cfg.baseline        = [TFR.time(1) TFR.time(m,n)];	
                cfg.baselinetype    = 'absolute';
                cfg.xlim            = [0.1 .20];   
                cfg.zlim            = [-3e-27 3e-27];
            %     cfg.ylim            = [8 12];
                cfg.showlabels      = 'markers';
                fig3                = figure; 
                ft_topoplotTFR(cfg, TFR);
                saveas(fig3, fullfile(run_struct.datasetup.processdir, subjID, sessionID, taskID, ['topoplot_' tf.codeLabel '.png']));

            %     % Topoplot Movie
            % 
            %     start               = -0.5;
            %     finish              = 2;
            %     step                = 0.05;
            % 
            %     cfg                 = [];
            %     cfg.baseline        = [-0.5 -0.1];	
            %     cfg.baselinetype    = 'absolute';
            %     cfg.zlim            = [-3e-29 3e-29];
            %     cfg.ylim            = [2 30];
            % 
            %     fig4                = figure;
            %     set(fig4,'NextPlot','replaceChildren');
            %     set(fig4,'Position',[398   262   965   673]);
            % 
            %     ind=start:step:finish-step;
            %     clear F
            %     F(length(ind)).cdata=[];
            %     F(length(ind)).colormap=[];
            % 
            %     time=start;
            %     for i=1:length(ind)%-1
            % 
            %         cfg.xlim = [ind(i) ind(i)+step];   
            %         ft_topoplotTFR(cfg, TFR);
            %     %     if ~isempty(intersect(ind(i), [-.2:.1:2]))
            %     %         str=num2str(ind(i));
            %     %     end
            %     %     text(-0.05,.45,str,'FontSize', 20)
            %         F(i) = getframe;
            %     end
            % 
            % 
            %     movie(F,[5 1:length(F) 1 1 1 1 1 1 1 1 1],10)
        end
    end
end
    
    
