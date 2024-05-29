function varargout = conditionPanel_QuantityBased(varargin)
% CONDITIONPANEL_QUANTITYBASED MATLAB code for conditionPanel_QuantityBased.fig
%      CONDITIONPANEL_QUANTITYBASED, by itself, creates a new CONDITIONPANEL_QUANTITYBASED or raises the existing
%      singleton*.
%
%      H = CONDITIONPANEL_QUANTITYBASED returns the handle to a new CONDITIONPANEL_QUANTITYBASED or the handle to
%      the existing singleton*.
%
%      CONDITIONPANEL_QUANTITYBASED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONDITIONPANEL_QUANTITYBASED.M with the given input arguments.
%
%      CONDITIONPANEL_QUANTITYBASED('Property','Value',...) creates a new CONDITIONPANEL_QUANTITYBASED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before conditionPanel_QuantityBased_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to conditionPanel_QuantityBased_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help conditionPanel_QuantityBased

% Last Modified by GUIDE v2.5 29-Jul-2013 10:59:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @conditionPanel_QuantityBased_OpeningFcn, ...
                   'gui_OutputFcn',  @conditionPanel_QuantityBased_OutputFcn, ...
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


% --- Executes just before conditionPanel_QuantityBased is made visible.
function conditionPanel_QuantityBased_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to conditionPanel_QuantityBased (see VARARGIN)

% Choose default command line output for conditionPanel_QuantityBased
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes conditionPanel_QuantityBased wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = conditionPanel_QuantityBased_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenuEventChoice.
function popupmenuEventChoice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuEventChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuEventChoice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuEventChoice
populateQuantityChoices(handles);
ehcb = QuantityBasedCondition('');
quantityIndex = get(handles.(ehcb.handlesField).popupmenuQuantityChoice, 'Value');
quantityNames = get(handles.(ehcb.handlesField).popupmenuQuantityChoice, 'String');
if (quantityIndex > length(quantityNames))
    set(handles.(ehcb.handlesField).popupmenuQuantityChoice, 'Value', length(quantityNames));
end
popupmenuQuantityChoice_Callback(handles.(ehcb.handlesField).popupmenuQuantityChoice, [], handles);


% --- Executes during object creation, after setting all properties.
function popupmenuEventChoice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuEventChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuComparator.
function popupmenuComparator_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuComparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuComparator contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuComparator


% --- Executes during object creation, after setting all properties.
function popupmenuComparator_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuComparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmount_Callback(hObject, eventdata, handles)
% hObject    handle to editAmount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmount as text
%        str2double(get(hObject,'String')) returns contents of editAmount as a double
user_entry = str2double(get(hObject,'String'));
ehpc = QuantityBasedCondition('');
if any(isnan(user_entry))
    set(hObject, 'String', num2str(handles.(ehpc.handlesField).data.amount));
	return
end
handles.(ehpc.handlesField).data.amount = user_entry;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editAmount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuQuantityTypeOptions.
function popupmenuQuantityTypeOptions_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuQuantityTypeOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuQuantityTypeOptions contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuQuantityTypeOptions

populateEventNames(handles);
ehcb = QuantityBasedCondition('');
eventIndex = get(handles.(ehcb.handlesField).popupmenuEventChoice, 'Value');
eventNames = get(handles.(ehcb.handlesField).popupmenuEventChoice, 'String');
if (eventIndex > length(eventNames))
    set(handles.(ehcb.handlesField).popupmenuEventChoice, 'Value', length(eventNames));
end
popupmenuEventChoice_Callback(handles.(ehcb.handlesField).popupmenuEventChoice, [], handles);

% --- Executes during object creation, after setting all properties.
function popupmenuQuantityTypeOptions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuQuantityTypeOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuQuantityChoice.
function popupmenuQuantityChoice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuQuantityChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuQuantityChoice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuQuantityChoice
populateUnitOptions(handles);
ehcb = QuantityBasedCondition('');
unitIndex = get(handles.(ehcb.handlesField).popupmenuDenominatorUnits, 'Value');
unitNames = get(handles.(ehcb.handlesField).popupmenuDenominatorUnits, 'String');
if (unitIndex > length(unitNames))
    set(handles.(ehcb.handlesField).popupmenuDenominatorUnits, 'Value', length(unitNames));
end
popupmenuDenominatorUnits_Callback(handles.(ehcb.handlesField).popupmenuDenominatorUnits, [], handles);


% --- Executes during object creation, after setting all properties.
function popupmenuQuantityChoice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuQuantityChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDenominatorUnits.
function popupmenuDenominatorUnits_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDenominatorUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDenominatorUnits contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDenominatorUnits


% --- Executes during object creation, after setting all properties.
function popupmenuDenominatorUnits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDenominatorUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function populateQuantityTypeOptions(handles)

ehpc = QuantityBasedCondition('');
conditionHandles = handles.(ehpc.handlesField);

% There will always be one product. (Or something is very wrong.)
% But if there may not be any outputs - either from propagation or events.
% In this case, we shouldn't include outputs as an option in the list.
eventRates = conditionHandles.data.eventRates;
quantityTypes = {'Product'};
for i = 1:length(eventRates)
   if ~isempty(eventRates(i).outputRates)
       quantityTypes{2} = 'Output';
       break;
   end
end

set(conditionHandles.popupmenuQuantityTypeOptions, 'String', quantityTypes);


function populateEventNames(handles)

ehpc = QuantityBasedCondition('');
conditionHandles = handles.(ehpc.handlesField);

quantityTypeIndex = get(conditionHandles.popupmenuQuantityTypeOptions, 'Value');
quantityTypeChoice = ehpc.quantityTypeOptions{quantityTypeIndex};
rateField = [lower(quantityTypeChoice), 'Rates'];

eventRates = conditionHandles.data.eventRates;

currentEventNames = get(conditionHandles.popupmenuEventChoice, 'String');
% Save the currently selected event name so we can get it back.
if isempty(currentEventNames)
    currentEventName = '';
else
    currentEventName = currentEventNames{get(conditionHandles.popupmenuEventChoice, 'Value')};
end
eventNames = {};
ix = 1;
for i = 1:length(eventRates)
    if ~isempty(eventRates(i).(rateField))
        eventNames{end+1} = eventRates(i).eventName;
        % If the event name matches the current event name, that's the
        % index we want.
        if strcmp(eventRates(i).eventName, currentEventName)
            ix = length(eventNames);
        end
    end
end
set(conditionHandles.popupmenuEventChoice, 'String', eventNames)
set(conditionHandles.popupmenuEventChoice, 'Value', ix)

function populateQuantityChoices(handles)
% For the chosen event name and quantity type, get the list of rates.
% Fill in the list with numerator units of those rates.

% Get the quanityType, and event name.
ehpc = QuantityBasedCondition('');
conditionHandles = handles.(ehpc.handlesField);

quantityTypeIndex = get(conditionHandles.popupmenuQuantityTypeOptions, 'Value');
quantityTypeChoice = ehpc.quantityTypeOptions{quantityTypeIndex};
currentEventNames = get(conditionHandles.popupmenuEventChoice, 'String');
% Get the rates
eventRates = conditionHandles.data.eventRates;

if isempty(currentEventNames)
    error('There should always be a non-empty list of event names. At least one of them should have a product. And outputs shouldn''t be listed if there are no events with outputs.');
else    
    currentEventName = currentEventNames{get(conditionHandles.popupmenuEventChoice, 'Value')};
    ix = find(strcmp({eventRates.eventName}, currentEventName), 1, 'first');
end

rateField = [lower(quantityTypeChoice), 'Rates'];
if ~isempty(ix)
    rates = eventRates(ix).(rateField);
    units = [rates.unit];
    set(conditionHandles.popupmenuQuantityChoice, 'String', {units.speciesName});
else
    error('We''ve tried to make it impossible to reach this point. If we do, there''s a logic fail somewhere, or you''re trying to do something that wasn''t intended.')
end


function populateUnitOptions(handles)
% For the chosen quantity, work out what the available denominator units
% are and populate the denominator unit popupmenu. Also set the text for
% the numerator units.

% Need to populate the denominator units with the regime units, or no
% units.

% If it's the regime units then select the right one.


% Get the rate in question.
ehpc = QuantityBasedCondition('');
conditionHandles = handles.(ehpc.handlesField);

quantityTypeIndex = get(conditionHandles.popupmenuQuantityTypeOptions, 'Value');
quantityTypeChoice = ehpc.quantityTypeOptions{quantityTypeIndex};
currentEventNames = get(conditionHandles.popupmenuEventChoice, 'String');
currentEventName = currentEventNames{get(conditionHandles.popupmenuEventChoice, 'Value')};

% Get the rates
eventRates = conditionHandles.data.eventRates;
ix = find(strcmp({eventRates.eventName}, currentEventName), 1, 'first');
rateField = [lower(quantityTypeChoice), 'Rates'];
if ~isempty(ix)
    rates = eventRates(ix).(rateField);
    rateIndex = get(conditionHandles.popupmenuQuantityChoice, 'Value');
    rate = rates(rateIndex);
else
    error('We''ve tried to make it impossible to reach this point. If we do, there''s a logic fail somewhere, or you''re trying to do something that wasn''t intended.')
end

% Get the numerator unit and set the label to be it's readable unit.
set(conditionHandles.textUnitName, 'String', rate.unit.readableUnit);
    
% Get the denominator unit of the chosen quantity. If it's one of the
% regimeUnits, popuplate it with Regime units, or clear it and set it
% invisible.
regimeUnits = conditionHandles.data.regimeUnits;
ix = find(regimeUnits == rate.denominatorUnit, 1, 'first');
if ~isempty(ix)
    set(conditionHandles.popupmenuDenominatorUnits, 'Visible', 'on');
    set(conditionHandles.popupmenuDenominatorUnits, 'String', {regimeUnits.readableDenominatorUnit});
    set(conditionHandles.popupmenuDenominatorUnits, 'Value', ix);
else
    set(conditionHandles.popupmenuDenominatorUnits, 'Visible', 'off');
    set(conditionHandles.popupmenuDenominatorUnits, 'String', {});
end
