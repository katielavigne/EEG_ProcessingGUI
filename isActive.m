function isActive(args, files)
handles = args{2};
hObject = args{3};
    for i = 1:size(files)
        if strfind(files(i).name, 'raw.set')
            set([handles.plot,  ...
                handles.plotraw, ...
                handles.chaninfo_rflag, ...
                handles.filter_rflag, ...
                handles.reref_rflag, ...
                handles.bins_rflag, ...
                handles.epochs_rflag, ...
                handles.run], 'enable', 'on');
        end
        if strfind(files(i).name, 'filt.set')
            set([handles.plotfiltered, ...
                handles.rmchan_man, ...
                handles.rmchan_auto], 'enable', 'on');
        end
        if strfind(files(i).name, 'rmchans')
            set([handles.rmchan_man, ...
                handles.rmchan_auto], 'enable', 'on');
        end
        if strfind(files(i).name, 'bins.set')
            set(handles.plotbins,  'enable', 'on');
        end
        if strfind(files(i).name, 'epochs.set')
            set([handles.plotepochs, ...
                handles.epchrej_man, ...
                handles.epchrej_auto, ...
                handles.runica, ...
                handles.limitcomps], 'enable', 'on');
        end
        if strfind(files(i).name, 'marked')
            set(handles.rejepchs, 'enable', 'on');
        end
        
        if strfind(files(i).name, 'artrej')
            set(handles.plotepchrej, 'enable', 'on');
        end
        if strfind(files(i).name, 'ICA')
            set([handles.plotICAcomps, ...
                handles.chan_interp], 'Enable', 'on');
        end
%         if strfind(files(i).name, 'TFRwave')
%             set([handles.TFplot, ...
%                 handles.beamer, ...
%                 handles.PCA], 'Enable', 'on');
%         end
    end
    guidata(hObject, handles);
end
