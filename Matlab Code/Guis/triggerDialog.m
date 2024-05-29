function varargout = triggerDialog(varargin)
% TRIGGERDIALOG M-file for triggerDialog.fig
%      TRIGGERDIALOG, by itself, creates a new TRIGGERDIALOG or raises the existing
%      singleton*.
%
%      H = TRIGGERDIALOG returns the handle to a new TRIGGERDIALOG or the handle to
%      the existing singleton*.
%
%      TRIGGERDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRIGGERDIALOG.M with the given input arguments.
%
%      TRIGGERDIALOG('Property','Value',...) creates a new TRIGGERDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before triggerDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to triggerDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help triggerDialog

% Last Modified by GUIDE v2.5 19-Aug-2011 20:10:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @triggerDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @triggerDialog_OutputFcn, ...
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


% --- Executes just before triggerDialog is made visible.
function triggerDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to triggerDialog (see VARARGIN)

% Choose default command line output for triggerDialog
handles.output = hObject;

% Maintain handles.stepData for the events data. stepData holds event data
% for the current crop. Changing the crop will require us to save it.

% Also have handles.subHandles for the handles of items in the
% triggerPanel. We'll load the trigger panel, pretty much the same as its
% done in the cropWizard.

% handles.cropEvents will be the authoratative list.
% We need first argument to be the list of crops used in the regime.

% Second argument is the cropEvents struct that already exists. If there is
% no second argument, it starts as empty.

% varargin{1} is cropsToPass from regime dialog. Should be a list of the
% crops that are used in the regime. You get the whole crop struct here.
% varargin{2} is optional. If it exists, it is the regime's cropEvents
% struct. If it doesn't, the regime probably does not yet have a cropEvents
% struct.

if nargin < 4
    msgbox('triggerDialog called without passing crop events struct.');
    return  
else
    handles.cropEvents = varargin{1};
    handles.stepData.cropEvents = handles.cropEvents;
    handles.cropNames = {handles.cropEvents.cropName};
end


% For each crop in cropList, see if there is a match in cropEvents.
% if there is, use cropEvents' events. If there are any events in the
% crops' list that are absent in the cropEvents list, add them.
% Any crop that is not in cropEvents is added in full.
%handles.stepData.cropEvents = mergeCropEvents(cropList, cropEvents);

%handles.cropNames = {handles.stepData.cropEvents.cropName}

% Update handles structure
guidata(hObject, handles);

populateStep(handles);

% UIWAIT makes triggerDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = triggerDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
close(gcf);

% --- Executes on button press in acceptButton.
function acceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Before closing the window, save the current events in the trigger panel.
handles.stepData.cropEvents(handles.lastCropIndex).events = handles.stepData.events;
handles.output = handles.stepData.cropEvents;
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on selection change in cropSelectionListBox.
function cropSelectionListBox_Callback(hObject, eventdata, handles)
% hObject    handle to cropSelectionListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns cropSelectionListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cropSelectionListBox

% save current events into cropEvents.
handles.stepData.cropEvents(handles.lastCropIndex).events = handles.stepData.events;

% figure out which crop's events now get loaded.
cropIndex = get(hObject, 'Value');
handles.stepData.events = handles.stepData.cropEvents(cropIndex).events;
hsde = handles.stepData.events
handles.lastCropIndex = cropIndex;
guidata(hObject, handles);
triggerPanel('loadEventsList', handles.subHandles, 1);

% --- Executes during object creation, after setting all properties.
function cropSelectionListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropSelectionListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end











% populateStep
% 
% Need to load triggerPanel and populate it based on whatever is in wc.
%
% We assume that handles.stepData.cropEvents is defined and has all the
% events in it merged.
function populateStep(handles)

handles.subHandles = [];
guidata(handles.triggerPanel, handles);

% Ok, now load the trigger panel.
loadTriggerPanel(handles)

handles = guidata(handles.triggerPanel);
subHandles = handles.subHandles;


% set stepData.events
handles = guidata(subHandles.triggerPanel);
set(handles.cropSelectionListBox, 'String', handles.cropNames);

handles.lastCropIndex = 1;
set(handles.cropSelectionListBox, 'Value', handles.lastCropIndex);

handles.stepData.events = handles.stepData.cropEvents(handles.lastCropIndex).events;

handles.stepData.location = 'Regime';

% Set the controls that we might want to enable or disable at once:
handles.stepData.controlsToBeDisabled = [subHandles.shorthandEdit, ...
                                           subHandles.conditionTypeDDL, ...
                                           subHandles.removeConditionButton, ...
                                           subHandles.newConditionButton];
                                       
% save stepdata
guidata(subHandles.triggerPanel, handles);

% Load the events list from stepData.
triggerPanel('loadEventsList', subHandles, 1);



% This function loads the step into the main window. Handles to the 
% subwindow's controls are provided in handles.subHandles
function loadTriggerPanel(handles)

% Load the first page fig.
td = load('triggerPanel.fig', '-MAT');
if(~isempty(td.hgS_070000.children))
    
    td.hgS_070000.children
    hs =  struct2handle(td.hgS_070000.children, repmat(handles.triggerPanel, length(td.hgS_070000.children), 1), 'convert');
    
    callbackToUseSubHandles(hs);
    
    trendHandles = grabHandles(hs);
end

handles.subHandles = trendHandles;
handles.subHandles.triggerPanel = handles.triggerPanel;
guidata(handles.triggerPanel, handles);



% saveStep
% 
% Saves the stepData.events into stepData.cropEvents
function saveStep(subHandles)

% Really need to validate the events first

handles = guidata(subHandles.triggerPanel);
selectedCropName = handles.cropNames(get(handles.cropSelectionListBox, 'Value'));
ix = find(strcmp(selectedCropName, {handles.stepData.cropEvents.cropName}));
handles.stepData.cropEvents(ix) = handles.stepData.events;

guidata(subHandles.triggerPanel, handles);
