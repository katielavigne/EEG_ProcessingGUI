function bins = listConditions(dsname)

    global EEG
    % [dsfile dspath] = uigetfile('*.set', 'Select EEG .set file');
    % dsname = [dspath dsfile];

    EEG = pop_loadset(dsname);
    codes = [];

    for i = 1:size(EEG.event,2)
        if EEG.event(i).codelabel
            codes = [codes;{EEG.event(i).codelabel}];
        end
    end
    allCodes = unique(codes);

    bins = [];
    for i = 1:size(EEG.EVENTLIST.bdf,2)
        bins = [bins;{[EEG.EVENTLIST.bdf(i).namebin '  ' EEG.EVENTLIST.bdf(i).description]}];
    end
end