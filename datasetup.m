function varargout = datasetup(varargin)
% DATASETUP MATLAB code for datasetup.fig
%      DATASETUP, by itself, creates a new DATASETUP or raises the existing
%      singleton*.
%
%      H = DATASETUP returns the handle to a new DATASETUP or the handle to
%      the existing singleton*.
%
%      DATASETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATASETUP.M with the given input arguments.
%
%      DATASETUP('Property','Value',...) creates a new DATASETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before datasetup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to datasetup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%% DOCUMENTATION
%
% AUTHOR: Katie Lavigne (lavigne.k@gmail.com)
% DATE: June 8th, 2016
% 
% FILE:     datasetup.m (paired with datasetup.fig)
% PURPOSE:  This is the GUIDE-created file for the Data Setup portion of the EEG GUI.
% USAGE:    Click Data Setup in the EEG GUI.
% 
% DESCRIPTION: This file, in addition to datasetup.fig, is the file created by MATLAB's
% Graphic User Interface Design Environment (GUIDE) for the Data Setup portion of the GUI.
% It defines what is done when each button/checkbox/etc is pressed/changed in the GUI.

% Edit the above text to modify the response to help datasetup

% Last Modified by GUIDE v2.5 26-Oct-2015 21:41:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @datasetup_OpeningFcn, ...
                   'gui_OutputFcn',  @datasetup_OutputFcn, ...
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


% --- Executes just before datasetup is made visible.
function datasetup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to datasetup (see VARARGIN)

if ~isempty(getappdata(0,'datasetup_vals'));
    tmp = getappdata(0,'datasetup_vals');
    set(handles.datadirtext, 'String', tmp.datadir);
    set(handles.savedirtext, 'String', tmp.savedir)
    set(handles.swildtext, 'String', tmp.subject);
    set(handles.sswildtext, 'String', tmp.session);
    set(handles.twildtext, 'String', tmp.task);
    set(handles.rwildtext, 'String', tmp.run);
    handles.datadir = tmp.datadir;
    handles.savedir = tmp.savedir;
    handles.subject = tmp.subject;
    handles.session = tmp.session;
    handles.task = tmp.task;
    handles.run = tmp.run;
    guidata(hObject, handles);
else
    handles.datadir = 'No Directory Selected!';
    handles.savedir = 'No Directory Selected!';
    handles.subject = '';
    handles.session = '';
    handles.task = '';
    handles.run = '';
end

% Choose default command line output for datasetup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes datasetup wait for user response (see UIRESUME)
% uiwait(handles.datasetup);

% --- Outputs from this function are returned to the command line.
function varargout = datasetup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in datadir.
function datadir_Callback(hObject, eventdata, handles)
% hObject    handle to datadir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.datadir = uigetdir(pwd,'Select Subject EEG Data Directory'); % location of subject eeg data directories
if handles.datadir == 0
    handles.datadir = 'No Directory Selected!';
end
set(handles.datadirtext, 'String', handles.datadir)
guidata(hObject, handles);


% --- Executes on button press in savedir.
function savedir_Callback(hObject, eventdata, handles)
% hObject    handle to savedir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.savedir = uigetdir(pwd,'Select Directory to Save Processed Data'); % location to save sets
if handles.savedir == 0
    handles.savedir = 'No Directory Selected!';
end
set(handles.savedirtext, 'String', handles.savedir)
guidata(hObject, handles);


function swildtext_Callback(hObject, eventdata, handles)
% hObject    handle to swildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of swildtext as text
%        str2double(get(hObject,'String')) returns contents of swildtext as a double
handles.subject = get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function swildtext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to swildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sswildtext_Callback(hObject, eventdata, handles)
% hObject    handle to sswildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sswildtext as text
%        str2double(get(hObject,'String')) returns contents of sswildtext as a double
handles.session = get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sswildtext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sswildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function twildtext_Callback(hObject, eventdata, handles)
% hObject    handle to twildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of twildtext as text
%        str2double(get(hObject,'String')) returns contents of twildtext as a double
handles.task = get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function twildtext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to twildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function rwildtext_Callback(hObject, eventdata, handles)
% hObject    handle to rwildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rwildtext as text
%        str2double(get(hObject,'String')) returns contents of rwildtext as a double
handles.run = get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function rwildtext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rwildtext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subjs = dir([handles.datadir,'/',handles.subject, '*']);
subjs=subjs(~strncmpi('.',{subjs.name},1)); % Remove hidden folders (folders starting with '.')
sflag = [subjs.isdir]; % directories only
subjs = subjs(sflag); % directories only
datasetup_vals = struct('datadir', handles.datadir, ...
    'savedir', handles.savedir, ...
    'subject', handles.subject, ...
    'subjs', subjs, ...
    'session', handles.session, ...
    'task', handles.task, ...
    'run', handles.run);
setappdata(0, 'datasetup_vals', datasetup_vals);
close(handles.datasetup);


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.datasetup);


% --- Executes when user attempts to close datasetup.
function datasetup_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to datasetup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
