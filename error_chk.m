function error_chk(run_struct, fcn_name, errors)

    switch fcn_name
        case 'reexportlog2text'
            stage = 'Re-Export Log Files';
        case 'exportEEGevents'
            stage = 'Export EEG Events';
        case 'syncEEGtiming'
            stage = 'Sync Timing';
        case 'plot'
            stage = 'Plot Channel Data';
        case 'process'
            stage = 'Processing';
        case 'rmchan'
            stage = 'Channel Rejection';
        case 'chan_interp'
            stage = 'Channel Interpolation';
        case 'epchrej'
            stage = 'Epoch Rejection';
        case 'ICA'
            stage = 'ICA';
        case 'plotICA'
            stage = 'Plot ICA';
        case 'analysis'
            stage = 'Analysis';
        case 'timefrequency'
            stage = 'Time Frequency';
        case 'timefrequencyplot'
            stage = 'Time Frequency Plot';
    end
            
    if ~isempty(errors)
        fid=fopen(fullfile(run_struct.datasetup.savedir, [fcn_name '_errors.txt']), 'wt');
        for k = 1: size(errors,1)
            fprintf(fid,'%s\r\n',errors{k,:});
        end
        fclose(fid);
        h = msgbox({[ stage ' Complete!']; ''; ['Errors detected. Please see ' fcn_name '_errors.txt'  '.']});
    else
        h = msgbox( [stage ' Complete!'], 'DONE');
    end
    
    fclose('all');
    waitfor(h)    
end