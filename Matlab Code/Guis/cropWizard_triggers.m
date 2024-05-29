function varargout = cropWizard_triggers(varargin)
% CROPWIZARD_TRIGGERS M-file for cropWizard_triggers.fig
%      CROPWIZARD_TRIGGERS, by itself, creates a new CROPWIZARD_TRIGGERS or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_TRIGGERS returns the handle to a new CROPWIZARD_TRIGGERS or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_TRIGGERS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_TRIGGERS.M with the given input arguments.
%
%      CROPWIZARD_TRIGGERS('Property','Value',...) creates a new CROPWIZARD_TRIGGERS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_triggers_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_triggers_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_triggers

% Last Modified by GUIDE v2.5 31-Jan-2011 12:23:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_triggers_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_triggers_OutputFcn, ...
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


% --- Executes just before cropWizard_triggers is made visible.
function cropWizard_triggers_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_triggers (see VARARGIN)

% Choose default command line output for cropWizard_triggers
%handles.output = hObject;

% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes cropWizard_triggers wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_triggers_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function cropNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cropNameEdit as text
%        str2double(get(hObject,'String')) returns contents of cropNameEdit as a double


% --- Executes during object creation, after setting all properties.
function cropNameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in categoryDDL.
function categoryDDL_Callback(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns categoryDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from categoryDDL


% --- Executes during object creation, after setting all properties.
function categoryDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeColourButton.
function changeColourButton_Callback(hObject, eventdata, handles)
% hObject    handle to changeColourButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% populateStep
% 
% Need to load triggerPanel and populate it based on whatever is in wc.

function populateStep(subHandles)

wizardCrop = subHandles.wizardCrop;
gmEvents = wizardCrop.growthModel.growthModelEvents;

% Also need the financialEvents.
financialEvents = wizardCrop.financialEvents;

% Ok, now load the trigger panel.
loadTriggerPanel(subHandles)
handles = guidata(subHandles.triggerPanel);
subHandles = handles.subHandles;


% clear stepData and reset it to wizardCrop
handles = guidata(subHandles.triggerPanel);
handles.stepData = [];
handles.stepData(1).wizardCrop = wizardCrop;

% Now merge the gmEvents and the financialEvents for inclusion in stepData.
% Add events next to wc in stepData. Later (on save) we need to seperate
% events and add them to wc.
handles.stepData.events = [gmEvents, financialEvents];

handles.stepData.location = 'CropWizard';

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
function loadTriggerPanel(subHandles)

handles = guidata(subHandles.triggerPanel);

% Load the first page fig.
td = load('triggerPanel.fig', '-MAT');
if(~isempty(td.hgS_070000.children))
    hs =  struct2handle(td.hgS_070000.children, repmat(subHandles.triggerPanel, length(td.hgS_070000.children), 1), 'convert');
    
    callbackToUseSubHandles(hs);
    
    trendHandles = grabHandles(hs);
end

% Use combine fields so that all the controls will be removed when we load
% another step.
subHandles = combineFields(subHandles, trendHandles);

handles.subHandles = subHandles;
guidata(subHandles.triggerPanel, handles);

disp('end of cropWizard_triggers. loadTriggerPanel, ie populateStep')



% saveStep
% 
% returns wc from stepData
function wc = saveStep(subHandles)

% Check that the step is valid. Ie all the priceModels are valid.
[valid, msgs] = validateStep(subHandles);

if ~valid
   uiwait(errordlg([{'Step is not valid due to the following problems:', '', ''}, msgs, {'', ''}], 'Step Not Valid'));
   wc = [];
   return
end


handles = guidata(subHandles.triggerPanel);
wc = handles.stepData.wizardCrop;
events = handles.stepData.events;

%coreEvents = [];
%financialEvents = [];
coreCounter = 0;
financialCounter = 0;
% Need to set it to empty so that if we remove all existing financial
% events, they are not left.
financialEvents = ImagineEvent.empty(1, 0); 

for i = 1:length(events)
   if strcmp(events(i).status.origin, 'core') 
        coreCounter = coreCounter + 1;
        coreEvents(coreCounter) = events(i);
   end
   if strcmp(events(i).status.origin, 'cropNew') 
        financialCounter = financialCounter + 1;
        financialEvents(financialCounter) = events(i);
   end
end

% What if we've changed the name of a financial event? Then the name of the
% event and the name in the priceModel won't match.
% Now, priceModels are saved in the category so that if we change the
% growthModel we keep price data (in the category) for events that are
% named the same in the new growthModel. Financial event cost price models
% are also stored in the category. So if we change the name of the
% financial event, we need to change the name in the priceModel so that
% it's up to date. The priceModel in the event will have the previous name
% so we can use that to find it in the category and change it there.
for i = 1:length(financialEvents)
    fev = financialEvents(i);
    if ~strcmp([fev.name, ' Cost'], fev.costPriceModel.name)
        % The names don't match. So find the index of the costPriceModel in
        % the category's list and update that name as well.
        
        [cats, TF] = wc.category.changePriceModelName(fev.costPriceModel.name, [fev.name, ' Cost']);
        wc.category = cats;
        if TF
           % If name change is a success, then update the price model name here.
           financialEvents(i).costPriceModel.name = [fev.name, ' Cost'];
        end
    end    
end

if coreCounter > 0
    wc.category.growthModel.growthModelEvents = coreEvents;
end

wc.financialEvents = financialEvents;


function [valid, msgs] = validateStep(subHandles)


msgs = {};
handles = guidata(subHandles.triggerPanel);

events = handles.stepData.events;


valid = 1;
for i = 1:length(events)
    
   % There should exist a valid trigger for each product.    
   if ~Trigger.isValid(events(i).trigger)
       valid = 0;
       condMsgs = {};
       for j = 1:length(events(i).trigger.conditions)
           if (~events(i).trigger.conditions{j}.isValid)
              condMsgs = [condMsgs, ['Invalid condition ', num2str(j), ': ',  events(i).trigger.conditions{j}.shorthand]]; 
           end
       end
       if ~isempty(condMsgs)
           msgs = [msgs, ['The trigger for event ''', events(i).name, ''' has invalid conditions:'], {''}, condMsgs];
       else
           msgs = [msgs, ['The trigger for event ''', events(i).name, ''' is invalid.']];           
       end
   end
    
end






