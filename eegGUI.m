function varargout = eegGUI(varargin)
% EEGGUI MATLAB code for eegGUI.fig
%      EEGGUI, by itself, creates a new EEGGUI or raises the existing
%      singleton*.
%
%      H = EEGGUI returns the handle to a new EEGGUI or the handle to
%      the existing singleton*.
%
%      EEGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EEGGUI.M with the given input arguments.
%
%      EEGGUI('Property','Value',...) creates a new EEGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before eegGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to eegGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help eegGUI

% Last Modified by GUIDE v2.5 15-Mar-2017 09:35:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @eegGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @eegGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before eegGUI is made visible.
function eegGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eegGUI (see VARARGIN)

% Choose default command line output for eegGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes eegGUI wait for user response (see UIRESUME)
% uiwait(handles.eegGUI);


% --- Outputs from this function are returned to the command line.
function varargout = eegGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in datasetup.
function datasetup_Callback(hObject, eventdata, handles)
% hObject    handle to datasetup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
datasetup
uiwait(datasetup);
[handles.runtype, handles.select_dir, handles.plottype, handles.winlength, handles.dispchans, handles.spacing, ...
    handles.fileloc, handles.ref_chanind, handles.ref_ref, handles.filtertype, handles.filtercutoff, ...
    handles.notchtype, handles.notchcutoff, handles.epochrange, handles.rmchan_type, ...
    handles.autochanrej, handles.autochanrej_ref, handles.epchrej_type, handles.twindow, handles.threshold, handles.winsize, handles.winstep, handles.channel, handles.ICA_type, handles.ncomps, handles.plotcomps, handles.run_type] = deal('');
guidata(hObject, handles);
chkactive(handles, hObject)


% --- Executes on button press in reexporttxt.
function reexporttxt_Callback(hObject, eventdata, handles)
% hObject    handle to reexporttxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'reexportlog2text';
handles.select_dir = 'data';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in exportEEGevents.
function exportEEGevents_Callback(hObject, eventdata, handles)
% hObject    handle to exportEEGevents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'exportEEGevents';
handles.select_dir = 'data';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in syncEEGtiming.
function syncEEGtiming_Callback(hObject, eventdata, handles)
% hObject    handle to syncEEGtiming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'syncEEGtiming';
handles.select_dir = 'data';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes when selected object is changed in plotpanel.
function plotpanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotpanel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'plot';
switch get(eventdata.NewValue, 'Tag')
    case 'plotraw'
        handles.plottype = 'raw';
        set([handles.plotfiltered, handles.plotbins, handles.plotepochs, handles.plotepchrej],'Value', 0)
    case 'plotfiltered'
        handles.plottype = 'filt';
        set([handles.plotraw, handles.plotbins, handles.plotepochs, handles.plotepchrej],'Value', 0)
    case 'plotbins'
        handles.plottype = 'bins';
        set([handles.plotraw, handles.plotfiltered, handles.plotepochs, handles.plotepchrej],'Value', 0)
    case 'plotepochs'
        handles.plottype = 'epochs';
        set([handles.plotraw, handles.plotfiltered, handles.plotbins, handles.plotepchrej],'Value', 0)
    case 'plotepchrej'
        handles.plottype = 'epchrej';
        set([handles.plotraw, handles.plotfiltered, handles.plotbins, handles.plotepochs],'Value', 0)
end
guidata(hObject, handles);


% --- Executes on button press in plot.
function plot_Callback(hObject, eventdata, handles)
% hObject    handle to plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.plottype, '')
    msgbox('Please select a type of data to plot.');
    return
end

prompt = {'Window length', 'Display channels', 'Spacing'};
title = 'Input';
defaultanswers = {'10', '50', '30'};
answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
if ~strcmp(answer(1),'') && ~strcmp(answer(2),'') && ~strcmp(answer(3), '')
    handles.winlength = str2num(answer{1});
    handles.dispchans = str2num(answer{2});
    handles.spacing = str2num(answer{3});
else
    msgbox('Please input a number for all options.');
    return
end
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in chaninfo_rflag.
function chaninfo_rflag_Callback(hObject, eventdata, handles)
% hObject    handle to chaninfo_rflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chaninfo_rflag
chaninfo_rflag = get(hObject, 'Value');
if chaninfo_rflag == 1
    chanoptions_Callback(hObject, eventdata, handles)
    handles = guidata(hObject); % necessary to pull handles back from chanoptions
    handles.run_type = 'process';
end
guidata(hObject, handles);


% --- Executes on button press in chanoptions.
function chanoptions_Callback(hObject, eventdata, handles)
% hObject    handle to chanoptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[GUIpath ~] = fileparts(which('eegGUI'));
fileloc = fullfile(GUIpath, 'GSN-HydroCel-257.sfp');

if exist(fileloc, 'file')
    handles.fileloc = fileloc;
else
    [filename, path] = uigetfile('*.sfp','Select Scalp Coordinates File (e.g., GSN-HydroCel-257.sfp)');
    if filename ~= 0
        handles.fileloc = fullfile(path, filename);
    else
        msgbox('Please select a valid file')
        set(handles.chaninfo_rflag, 'Value', 0);
        return
    end
end

H = questdlg('Would you like to add an empty channel (required for automatic channel rejection)?');

prompt = {'Channel indices', 'Reference'};
title = 'Input';
defaultanswers = {'1:256', 'Cz'};
answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
if  ~strcmp(answer(1),'') && ~strcmp(answer(2),'')
    handles.ref_chanind = answer{1};
    handles.ref_ref = answer{2};
    set(handles.chaninfo_rflag, 'Value', 1);
else
    msgbox('Please fill out both options.')
    set(handles.chaninfo_rflag, 'Value', 0);
end

if strcmp(H,'Yes') == 1
    handles.autochanrej = 1;
    handles.autochanrej_ref = answer{2};
end

guidata(hObject, handles);


% --- Executes on button press in filter_rflag.
function filter_rflag_Callback(hObject, eventdata, handles)
% hObject    handle to filter_rflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filter_rflag
filt_rflag = get(hObject, 'Value');
if filt_rflag == 1
    set(handles.filter_rflag, 'Value', 1)
    handles.run_type = 'process';
    % BAND-PASS FILTER OPTIONS
    prompt = {'Type', 'High-Pass', 'Low-Pass'};
    title = 'Band-Pass Filter';
    defaultanswers = {'butter', '0.05', '100'};
    answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
    if isempty(answer)
        handles.filtertype = '';
        handles.filtercutoff = '';
    elseif ~strcmp(answer(1),'') && ~strcmp(answer(2),'') && ~strcmp(answer(3),'')
        handles.filtertype = answer{1};
        handles.filtercutoff = [str2num(answer{2}), str2num(answer{3})];
    end
    % NOTCH FILTER OPTIONS
    prompt = {'Type', 'Cutoff'};
    title = 'Notch Filter';
    defaultanswers = {'PMnotch', '60'};
    answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
    if isempty(answer)
        handles.notchtype = '';
        handles.notchcutoff = '';
    elseif ~strcmp(answer(1), '') && ~strcmp(answer(2), '')
        handles.notchtype = answer{1};
        handles.notchcutoff = str2num(answer{2});
    end
else
    set(handles.filter_rflag, 'Value', 0)
end
guidata(hObject, handles);


% --- Executes on button press in reref_rflag.
function reref_rflag_Callback(hObject, eventdata, handles)
% hObject    handle to reref_rflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reref_rflag
reref_rflag = get(hObject,'Value');
set(handles.reref_rflag, 'Value', reref_rflag);
handles.run_type = 'process';
guidata(hObject, handles);


% --- Executes on button press in bins_rflag.
function bins_rflag_Callback(hObject, eventdata, handles)
% hObject    handle to bins_rflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bins_rflag
bins_rflag = get(hObject,'Value');
set(handles.bins_rflag, 'Value', bins_rflag);
handles.run_type = 'process';
guidata(hObject, handles);


% --- Executes on button press in epochs_rflag.
function epochs_rflag_Callback(hObject, eventdata, handles)
% hObject    handle to epochs_rflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of epochs_rflag
epochs_rflag = get(hObject,'Value');
if epochs_rflag == 1
    epochsoptions_Callback(hObject, eventdata, handles)
    handles = guidata(hObject); % necessary to pull handles back from epochsoptions
    handles.run_type = 'process';
end
guidata(hObject, handles);


% --- Executes on button press in epochsoptions.
function epochsoptions_Callback(hObject, eventdata, handles)
% hObject    handle to epochsoptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
prompt = 'Epoch Range';
title = 'Input';
defaultanswers = {'-500 10000'};
answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
if isempty(answer)
    set(handles.epochs_rflag, 'Value', 0);
elseif ~strcmp(answer(1),'')
    handles.epochrange = str2num(answer{1});
    set(handles.epochs_rflag, 'Value', 1);
else
    set(handles.epochs_rflag, 'Value', 0);
end
guidata(hObject, handles);


% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA) 
InterfaceObj=findobj(eegGUI,'Enable','on');
datasetup_vals = getappdata(0,'datasetup_vals');

if strcmp(handles.run_type, '') == 1
    return
end

run_struct = struct('datasetup', struct(datasetup_vals), ... % creates (mostly empty) structure
    'run_type', handles.run_type, ...
    'selectdir', handles.select_dir, ...
    'plot', struct('plottype', '', ...
        'winlength', '', ...
        'dispchans', '', ...
        'spacing', ''), ...
    'processing', struct('chaninfo_rflag', '', ...
        'filter_rflag', '', ...
        'reref_rflag', '', ...
        'bins_rflag', '', ...
        'epochs_rflag', '', ...
        'fileloc', '', ...
        'autochanrej', '', ...
        'autochanrej_ref', '', ...
        'ref_chanind', '', ...
        'ref_ref', '', ...
        'filtertype', '', ...
        'filtercutoff', '', ...
        'notchtype', '', ...
        'notchcutoff', '', ...
        'epochrange', ''), ...
    'artifact_handling', struct('rmchan', struct('type', '', ...
        'rmchanauto', '', ...
        'rmchanauto_ref', ''), ...
        'epchrej', struct('type', '', ...
        'twindow', '', ...
        'threshold', '', ...
        'winsize', '', ...
        'winstep', '', ...
        'channel', ''), ...
        'ICA', struct('type', '', ...
        'limitcomps', '', ...
        'numcomps', '', ...
        'plotcomps', '')));

switch run_struct.run_type
    case 'plot'
        run_struct.datasetup.subjs = dir([run_struct.datasetup.savedir,'/ProcessedData/',run_struct.datasetup.subject, '*']);
        run_struct.datasetup.subjs = run_struct.datasetup.subjs(~strncmpi('.',{run_struct.datasetup.subjs.name},1)); % Remove hidden folders (folders starting with '.')
        run_struct.selectdir = 'save';
        run_struct.plot = struct('plottype', handles.plottype, ...
            'winlength', handles.winlength, ...
            'dispchans', handles.dispchans, ...
            'spacing', handles.spacing);
        if strcmp(handles.plottype, 'marked')
            run_struct.artifact_handling.epchrej.type = handles.epchrej_type;
        end            
    case 'process'
        run_struct.datasetup.subjs = dir([run_struct.datasetup.savedir,'/ProcessedData/',run_struct.datasetup.subject, '*']);
        run_struct.datasetup.subjs=run_struct.datasetup.subjs(~strncmpi('.',{run_struct.datasetup.subjs.name},1)); % Remove hidden folders (folders starting with '.')
        run_struct.selectdir = 'save';
        run_struct.processing = struct('chaninfo_rflag', get(handles.chaninfo_rflag, 'Value'), ...
            'filter_rflag', get(handles.filter_rflag, 'Value'), ...
            'reref_rflag', get(handles.reref_rflag, 'Value'), ...
            'bins_rflag', get(handles.bins_rflag, 'Value'), ...
            'epochs_rflag', get(handles.epochs_rflag, 'Value'), ...
            'fileloc', handles.fileloc, ...
            'autochanrej', handles.autochanrej, ...
            'autochanrej_ref', handles.autochanrej_ref, ...
            'ref_chanind', handles.ref_chanind, ...
            'ref_ref', handles.ref_ref, ...
            'filtertype', handles.filtertype, ...
            'filtercutoff', handles.filtercutoff, ...
            'notchtype', handles.notchtype, ...
            'notchcutoff', handles.notchcutoff, ...
            'epochrange', handles.epochrange);
    case {'rmchan', 'chan_interp', 'epchrej', 'ICA', 'plotICA'}
        run_struct.datasetup.subjs = dir([run_struct.datasetup.savedir,'/ProcessedData/',run_struct.datasetup.subject, '*']);
        run_struct.datasetup.subjs=run_struct.datasetup.subjs(~strncmpi('.',{run_struct.datasetup.subjs.name},1)); % Remove hidden folders (folders starting with '.')
        run_struct.selectdir = 'save';
        run_struct.artifact_handling = struct('rmchan', struct('type', handles.rmchan_type, ...
            'autochanrej', handles.autochanrej, ...
            'autochanrej_ref', handles.autochanrej_ref), ...
            'epchrej', struct('type', handles.epchrej_type, ...
            'twindow', handles.twindow, ...
            'threshold', handles.threshold, ...
            'winsize', handles.winsize, ...
            'winstep', handles.winstep, ...
            'channel', handles.channel), ...
            'ICA', struct('type', handles.ICA_type, ...
            'limitcomps', get(handles.limitcomps, 'Value'), ...
            'numcomps', handles.ncomps, ...
            'plotcomps', handles.plotcomps));
end

% set(InterfaceObj,'Enable','off');
runprocess(run_struct)
set([handles.chaninfo_rflag, handles.filter_rflag, handles.reref_rflag, handles.bins_rflag, handles.epochs_rflag, handles.limitcomps],'Value', 0);
guidata(hObject, handles);
% set(InterfaceObj,'Enable','on');
chkactive(handles, hObject)


% --- Executes on button press in rmchan_man.
function rmchan_man_Callback(hObject, eventdata, handles)
% hObject    handle to rmchan_man (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'rmchan';
handles.rmchan_type = 'manual';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in rmchan_auto.
function rmchan_auto_Callback(hObject, eventdata, handles)
% hObject    handle to rmchan_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'rmchan';
handles.rmchan_type = 'auto';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in chan_interp.
function chan_interp_Callback(hObject, eventdata, handles)
% hObject    handle to chan_interp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'chan_interp';
guidata(hObject, handles);
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in epchrej_man.
function epchrej_man_Callback(hObject, eventdata, handles)
% hObject    handle to epchrej_man (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'plot';
handles.epchrej_type = 'manual';
handles.plottype = 'marked';
guidata(hObject, handles)
plot_Callback(hObject, eventdata, handles)


% --- Executes on button press in epchrej_auto.
function epchrej_auto_Callback(hObject, eventdata, handles)
% hObject    handle to epchrej_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'epchrej';
handles.epchrej_type = 'auto';

prompt = {'Twindow', 'Threshold', 'Window size', 'Window step', 'Channel'};
title = 'Input';
defaultanswers = {'-500 1600', '300', '400', '200', '1:256'};
answer = inputdlg(prompt,title, [1, length(title)+30], defaultanswers);
if isempty(answer)
    return
elseif ~strcmp(answer(1),'') && ~strcmp(answer(2),'') && ~strcmp(answer(3),'') && ~strcmp(answer(4), '') && ~strcmp(answer(5), '')
    handles.artifacthandling.twindow = str2num(answer{1});
    handles.artifacthandling.threshold = str2num(answer{2});
    handles.artifacthandling.winsize = str2num(answer{3});
    handles.artifacthandling.winstep = str2num(answer{4});
    handles.artifacthandling.channel = str2num(answer{5});
end
guidata(hObject, handles)
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in rejepchs.
function rejepchs_Callback(hObject, eventdata, handles)
% hObject    handle to rejepchs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'epchrej';
handles.epchrej_type = 'reject';

guidata(hObject, handles)
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in runica.
function runica_Callback(hObject, eventdata, handles)
% hObject    handle to runica (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'ICA';
guidata(hObject, handles)
run_Callback(hObject, eventdata, handles)


% --- Executes on button press in limitcomps.
function limitcomps_Callback(hObject, eventdata, handles)
% hObject    handle to limitcomps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of limitcomps
limitcomps = get(hObject,'Value');
if limitcomps == 0
    set(handles.numcomps, 'enable', 'off');
elseif limitcomps == 1
    set(handles.numcomps, 'enable', 'on');
    handles.ncomps = 64;
    handles.ICA_type = 'pca';
end
guidata(hObject, handles);


function numcomps_Callback(hObject, eventdata, handles)
% hObject    handle to numcomps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numcomps as text
%        str2double(get(hObject,'String')) returns contents of numcomps as a double
numcomps = get(hObject,'String');
handles.ncomps = str2num(numcomps);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function numcomps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numcomps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in plotICAcomps.
function plotICAcomps_Callback(hObject, eventdata, handles)
% hObject    handle to plotICAcomps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.run_type = 'plotICA';
promptstr = { 'Components to plot:' };
initstr   = { [ '1:64' ] };
result = inputdlg2(promptstr, 'Reject comp. by map -- pop_selectcomps',1, initstr);
if ~strcmp(result,'')
    handles.plotcomps = eval( [ '[' result{1} ']' ]);
else
    return
end
run_Callback(hObject, eventdata, handles)

% --- Executes on button press in quit.
function quit_Callback(hObject, eventdata, handles)
% hObject    handle to quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear all application data
appdata = get(0,'ApplicationData');
fns = fieldnames(appdata);
for ii = 1:numel(fns)
    rmappdata(0,fns{ii});
end
close(gcf);
% set(0,'DefaultUicontrolBackgroundColor', [.94 .94 .94])


% --- Executes when user attempts to close eegGUI.
function eegGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to eegGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% clear all application data
appdata = get(0,'ApplicationData');
fns = fieldnames(appdata);
for ii = 1:numel(fns)
    rmappdata(0,fns{ii});
end
delete(hObject);
