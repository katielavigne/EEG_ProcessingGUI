function [trl, event] = bade_trialfun(cfg)

conds = {'YY1', 'NN1', 'NY1', 'YN1'};
allcodes = {};

% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

% search for events
for i = 1:size(event,2)
    allcodes{i,1} = event(i).codelabel;
    allcodes{i,2} = event(i).sample;
end

c = find(strcmp(cfg.cond, conds));
onsets = [];
for i = 1:size(allcodes,1)
    if find(strcmp(conds{c}, allcodes{i}))
        onsets = [onsets; allcodes{i,2}];
    end
end

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * hdr.Fs);
posttrig =  round(cfg.trialdef.post * hdr.Fs);

trl = [];
trl(:,1) = onsets + pretrig.*ones(size(onsets));
trl(:,2) = onsets + pretrig.*ones(size(onsets))+posttrig.*ones(size(onsets));
trl(:,3) = 1.*ones(size(onsets)).*pretrig;