function varargout = triggerPanel(varargin)
% TRIGGERPANEL M-file for triggerPanel.fig
%      TRIGGERPANEL, by itself, creates a new TRIGGERPANEL or raises the existing
%      singleton*.
%
%      H = TRIGGERPANEL returns the handle to a new TRIGGERPANEL or the handle to
%      the existing singleton*.
%
%      TRIGGERPANEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRIGGERPANEL.M with the given input arguments.
%
%      TRIGGERPANEL('Property','Value',...) creates a new TRIGGERPANEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before triggerPanel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to triggerPanel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help triggerPanel

% Last Modified by GUIDE v2.5 06-Dec-2011 18:17:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @triggerPanel_OpeningFcn, ...
                   'gui_OutputFcn',  @triggerPanel_OutputFcn, ...
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


% --- Executes just before triggerPanel is made visible.
function triggerPanel_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to triggerPanel (see VARARGIN)


% UIWAIT makes triggerPanel wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = triggerPanel_OutputFcn(hObject, eventdata, subHandles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in conditionListBox.
function conditionListBox_Callback(hObject, eventdata, subHandles)
% hObject    handle to conditionListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns conditionListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from conditionListBox

loadCondition(subHandles);


% --- Executes during object creation, after setting all properties.
function conditionListBox_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to conditionListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in conditionTypeDDL.
function conditionTypeDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to conditionTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns conditionTypeDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from conditionTypeDDL
types = get(hObject, 'String');
type = types{get(hObject, 'Value')};

conditionTypeInfo = setupConditions();
for i = 1:length(conditionTypeInfo.samples)
    conditionTypeInfo.samples{i}.removeConditionControls(subHandles.condPanel);
end

changeConditionType(subHandles, '', type);

saveCondition(subHandles);
loadCondition(subHandles);
saveCondition(subHandles);
loadCondition(subHandles);


% --- Executes during object creation, after setting all properties.
function conditionTypeDDL_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to conditionTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in comparator.
function comparator_Callback(hObject, eventdata, subHandles)
% hObject    handle to comparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns comparator contents as cell array
%        contents{get(hObject,'Value')} returns selected item from comparator
valid = checkValidControlEntry(subHandles)
if (valid)
    c = saveCondition(subHandles);
    loadCondition(subHandles);
else
    % Put the saved value back in.
    loadCondition(subHandles);
end

% --- Executes during object creation, after setting all properties.
function comparator_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to comparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in control1.
function control1_Callback(hObject, eventdata, subHandles)
% hObject    handle to control1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns control1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from control1

valid = checkValidControlEntry(subHandles);
if (valid)
    conditionTypes = get(subHandles.conditionTypeDDL, 'String');
    conditionType = conditionTypes{get(subHandles.conditionTypeDDL, 'Value')};
    if (strcmp(conditionType, 'Quantity Based'))
       contents = get(hObject,'String');
       quantity = contents{get(hObject,'Value')};
       setupParametersForQuantityBased(subHandles, quantity); 
       
    end
    c = saveCondition(subHandles);
    loadCondition(subHandles);
else
    % Put the saved value back in.
    loadCondition(subHandles);
end


function [productRates, outputRates, eventRates, regimeUnits, thisEventName] = getQuantityBasedRequirements(subHandles)

handles = guidata(subHandles.condPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');        
thisEventName =  handles.stepData.events(eventIndex).name;

% To get the productUnits, the outputUnits we need to know where we are.
% If we're in the crop wizard, we get them from the wizard crop.
% If we're defining a regime, we know the crop is already defined, and we
% can get them from the CropManager.
if (strcmp(handles.stepData.location, 'CropWizard'))
    wizardCrop = handles.wizardCrop;
    % Regime units
    regimeUnits = wizardCrop.category.regimeOutputUnits;
    % For propagation
    outputRates = wizardCrop.growthModel.growthModelOutputRates;
    productRates = wizardCrop.growthModel.getPropagationProductRates;
    
    % For each event
    gmEvents = wizardCrop.growthModel.growthModelEvents;
    eventRates = EventRate.empty(1, 0);
    for i = 1:length(gmEvents)   
        [eventProductRates, eventOutputRates] = wizardCrop.growthModel.getProductAndOutputRatesForEvent(gmEvents(i).name);
        if ~isempty(eventProductRates) || ~isempty(eventOutputRates)
            eventRates(end+1) = EventRate(gmEvents(i).name, eventProductRates, eventOutputRates);
        end
    end
elseif (strcmp(handles.stepData.location, 'Regime'))
    cropMgr = CropManager.getInstance();
    cropName = handles.cropNames{handles.lastCropIndex};
    % Regime units
    regimeUnits = cropMgr.getCropsRegimeUnits(cropName);
    regimeUnits = regimeUnits{1}; 
    
    % For Propagation
    outputRates = cropMgr.getCropsOutputRates(cropName);
    outputRates = outputRates{1};
    propagationProductRates = cropMgr.getCropsPropagationProductRates(cropName);
    productRates = propagationProductRates{1};
    
    % For each event
    gmEvents = cropMgr.getCropsEvents(cropName);
    eventRates = EventRate.empty(1, 0);
    for i = 1:length(gmEvents)   
        [eventProductRates, eventOutputRates] = cropMgr.getCropsProductAndOutputRatesForEvent(cropName, gmEvents(i).name);
        if ~isempty(eventProductRates) || ~isempty(eventOutputRates)
            eventRates(end+1) = EventRate(gmEvents(i).name, eventProductRates, eventOutputRates);
        end
    end
    
else
    error('Using a trendPanel, not in a crop wizard or a regime. Where are we then?');
end


% --- Executes during object creation, after setting all properties.
function control1_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to control1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in control2.
function control2_Callback(hObject, eventdata, subHandles)
% hObject    handle to control2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns control2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from control2
valid = checkValidControlEntry(subHandles);
if (valid)
    c = saveCondition(subHandles);
    loadCondition(subHandles);
else
    % Put the saved value back in.
    loadCondition(subHandles);
end

% --- Executes during object creation, after setting all properties.
function control2_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to control2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in removeConditionButton.
function removeConditionButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to removeConditionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg('Are you sure you want to remove this condition?', 'Condition Removal', 'Yes', 'Cancel', 'Cancel');

if isempty(button)
    return
end
if strcmp(button, 'Cancel')
    return
end

% Get the eventIndex and the condition index
eventIndex = get(subHandles.eventsListBox, 'Value');
conditionIndex = get(subHandles.conditionListBox, 'Value');
handles = guidata(subHandles.triggerPanel);

% remove the condition
trigger = handles.stepData.events(eventIndex).trigger;
trigger.conditions = [trigger.conditions(1:conditionIndex-1), trigger.conditions(conditionIndex+1:end)];

% Check to see if any of the remaining conditions below are AND / OR / NOT conditions.
% If they are, we should subtract one from the indicies that are greater
% than the index of the event we removed.
for i = conditionIndex:length(trigger.conditions)
   cond = trigger.conditions(i);
   if strcmp(cond.conditionType, 'AND / OR / NOT')
      % Get the numbers from string2
      condIndices = str2num(cond.string2);
      
      % remove any that reference the removed index.
      condIndices = condIndices(condIndices ~= conditionIndex);
      
      % fix up the remaining indicies
      condIndices = condIndices - (condIndices > conditionIndex);
      
      % put the fixed indices back into the string.
      cond.string2 = num2str(condIndices);
      trigger.conditions(i) = cond;
   end    
end

% Save the fixed trigger conditions.
handles.stepData.events(eventIndex).trigger = trigger;
guidata(hObject, handles);

% If last condition, select previous condition.
if(conditionIndex == length(trigger.conditions) + 1)
   newConditionIndex = conditionIndex - 1; 
else
   newConditionIndex = conditionIndex;
end

if(length(trigger.conditions) == 1)
    set(subHandles.removeConditionButton, 'Enable', 'off');
end

set(subHandles.conditionListBox, 'Value', newConditionIndex);

loadEvent(subHandles, 0);



% --- Executes on button press in newConditionButton.
function newConditionButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to newConditionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Adds an empty condition and selects it.

% Get existing trigger
handles = guidata(subHandles.triggerPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');
trigger = handles.stepData.events(eventIndex).trigger;

condCount = length(trigger.conditions);

trigger.conditions{condCount+1} = NeverCondition(['Cond ', num2str(condCount+1)]);
shorthandList = {};
for i = 1:length(trigger.conditions)
    shorthandList = [shorthandList, trigger.conditions{i}.shorthand];
end
set(subHandles.conditionListBox, 'String', numberStringList(shorthandList));
set(subHandles.conditionListBox, 'Value', condCount+1);
handles.stepData.events(eventIndex).trigger = trigger;
guidata(hObject, handles);
loadCondition(subHandles);
set(subHandles.removeConditionButton, 'Enable', 'on');

function shorthandEdit_Callback(hObject, eventdata, subHandles)
% hObject    handle to shorthandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of shorthandEdit as text
%        str2double(get(hObject,'String')) returns contents of
%        shorthandEdit as a double
saveCondition(subHandles);
loadCondition(subHandles);
%set(subHandles.conditionListBox, 'String', {c.shorthand});



% --- Executes during object creation, after setting all properties.
function shorthandEdit_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to shorthandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function parameters1_Callback(hObject, eventdata, subHandles)
% hObject    handle to parameters1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of parameters1 as text
%        str2double(get(hObject,'String')) returns contents of parameters1 as a double
valid = checkValidControlEntry(subHandles);
if (valid)
    c = saveCondition(subHandles);
    loadCondition(subHandles);
else
    % Put the saved value back in.
    loadCondition(subHandles);
end

% --- Executes during object creation, after setting all properties.
function parameters1_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to parameters1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function parameters2_Callback(hObject, eventdata, subHandles)
% hObject    handle to parameters2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of parameters2 as text
%        str2double(get(hObject,'String')) returns contents of parameters2 as a double
valid = checkValidControlEntry(subHandles);
if (valid)
    c = saveCondition(subHandles);
    loadCondition(subHandles);
else
    % Put the saved value back in.
    loadCondition(subHandles);
end

% --- Executes during object creation, after setting all properties.
function parameters2_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to parameters2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% Load condition
% Set up the controls after setting the type, and populate controls with
% data. Condition must already be in stepData and we only load the
% condition that is selected in the listbox.
function loadCondition(subHandles)

% Get type info and trigger and condition.
conditionTypeInfo = setupConditions();

eventIndex = get(subHandles.eventsListBox, 'Value');
conditionIndex = get(subHandles.conditionListBox, 'Value');
handles = guidata(subHandles.triggerPanel);
trigger = handles.stepData.events(eventIndex).trigger;

if(conditionIndex > length(trigger.conditions))
    conditionIndex = length(trigger.conditions);
    set(subHandles.conditionListBox, 'Value', conditionIndex);
end

condition = trigger.conditions{conditionIndex};
conditionTypes = get(subHandles.conditionTypeDDL, 'String');
if isempty(conditionTypes)
    oldConditionType = '';
else
    oldConditionType = conditionTypes{get(subHandles.conditionTypeDDL, 'Value')};
end


% 1. Set shorthand
set(subHandles.shorthandEdit, 'String', condition.shorthand);

% 2. Populate type list and set the value.
set(subHandles.conditionTypeDDL, 'String', conditionTypeInfo.types);
cTypeIndex = find(strcmp(condition.conditionType, conditionTypeInfo.types));
set(subHandles.conditionTypeDDL, 'Value', cTypeIndex);

%3. use changeConditionType and populateConditionControls to set up the controls
changeConditionType(subHandles, oldConditionType, condition.conditionType);
populateConditionControls(subHandles, condition)

%4. Set longhand
longHand = condition2String(trigger.conditions, conditionIndex);
pos = get(subHandles.expressionLabel, 'Position');
[outString, newPos] = textwrap(subHandles.expressionLabel, {longHand});
if any(newPos > pos)
   % Change it to a list box that scrolls.
   outString = 'Expression does not all fit';
end
set(subHandles.expressionLabel, 'String', outString);


% Load Event
% Populate condition list, select last one, and load it.
%
% jumpToEnd is a boolean input. If set to true, it selects the last
% condition in the list. If false, it leaves the value unchanged.
function loadEvent(subHandles, jumpToEnd)

handles = guidata(subHandles.triggerPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');
event = handles.stepData.events(eventIndex);

% if ~Trigger.isValid(event.trigger) 
%     event.trigger = Trigger();
%     handles.stepData.events(eventIndex) = event;
%     guidata(subHandles.triggerPanel, handles);
%     disp(['Trigger not valid for event ', event.name]);
% end
% 
% Need to use subHandles.stepData.location to see if we are in 'Regime' or
% 'CropWizard'.
   
switch handles.stepData.location

        
    % In cropWizard, if derffered, disable things.
    % If not deferred, and regime redefinable is falselocked, disable things.
    
    case 'CropWizard'
        
        % Setup DUR Button.
        % If deferToRegimeLocked, disable the controls.
                
        % This setting only affects whether the Defer/Undefer button is
        % visible.
        if event.status.deferredToRegimeLocked
            set(subHandles.DURButton, 'Visible', 'off')
        else
            set(subHandles.DURButton, 'Visible', 'on')
        end

        % This setting goverens what the DURButton displays. (And how the
        % controls are enabled.)
        if event.status.deferredToRegime
            set(subHandles.DURButton, 'String', 'Undefer');
        else
            set(subHandles.DURButton, 'String', 'Defer')
        end

        % Set up the regime redefinable checkbox.
        if event.status.regimeRedefinableLocked
           % if it's locked on, should have it visible, but disabled.
           set(subHandles.regimeRedefinableCheckbox, 'Visible', 'off');
           if event.status.regimeRedefinable
              set(subHandles.regimeRedefinableLabel, 'Visible', 'on'); 
           else
              set(subHandles.regimeRedefinableLabel, 'Visible', 'off');
           end           
        else
           set(subHandles.regimeRedefinableLabel, 'Visible', 'off');
           set(subHandles.regimeRedefinableCheckbox, 'Value', event.status.regimeRedefinable);
           set(subHandles.regimeRedefinableCheckbox, 'Visible', 'on');         
        end
        
        % Set up the condition controls
        if event.status.deferredToRegime
           set(subHandles.condPanel, 'Visible', 'off'); 
           set(handles.stepData.controlsToBeDisabled, 'Visible', 'off');
           set(subHandles.triggerDeferredLabel, 'Visible', 'on')   
           set(subHandles.triggerDeferredLabel2, 'Visible', 'on') 
           
           set(subHandles.conditionListBox, 'Visible', 'off')
           set(subHandles.conditionListLabel, 'Visible', 'off')           
           set(subHandles.addConditionLabel, 'Visible', 'off')         
        
        elseif event.status.cropDefinitionLocked
           % It may be that the definition is locked, but we want to know
           % what it _is_. So simply disable the condition panel. But make
           % the add/remove condition buttons invisible.
           conditionControls = getConditionControls(subHandles);
           conditionControls = [];
           set([handles.stepData.controlsToBeDisabled, conditionControls], 'Enable', 'off');  
           set([handles.stepData.controlsToBeDisabled, conditionControls], 'Visible', 'on');
           set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'off');
           set(subHandles.condPanel, 'Visible', 'on');    
           set(subHandles.triggerDeferredLabel, 'Visible', 'off')   
           set(subHandles.triggerDeferredLabel2, 'Visible', 'off') 
                      
           set(subHandles.conditionListBox, 'Visible', 'on')
           set(subHandles.conditionListLabel, 'Visible', 'on')           
           set(subHandles.addConditionLabel, 'Visible', 'on')        
   
        else
           % We should have free access to edit the trigger. 
           conditionControls = getConditionControls(subHandles);
           conditionControls = [];

           set([handles.stepData.controlsToBeDisabled, conditionControls], 'Enable', 'on');
           set([handles.stepData.controlsToBeDisabled, conditionControls], 'Visible', 'on');
           set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'on');
           set(subHandles.condPanel, 'Visible', 'on');   
           set(subHandles.triggerDeferredLabel, 'Visible', 'off')   
           set(subHandles.triggerDeferredLabel2, 'Visible', 'off')  
           
           set(subHandles.conditionListBox, 'Visible', 'on')
           set(subHandles.conditionListLabel, 'Visible', 'on')           
           set(subHandles.addConditionLabel, 'Visible', 'on')           
   
        end

    case 'Regime'
        
        % In regime, controls will always be visible, even if we can't edit them.
        % That's because we either have a definition already - that we want
        % to view, or we need to make the definition.
        set(subHandles.condPanel, 'Visible', 'on');
  %      conditionControls = getConditionControls(subHandles);
        conditionControls = [];
        set([handles.stepData.controlsToBeDisabled, conditionControls], 'Visible', 'on');

        % We want the new and remove buttons to be invisible so we cant add events
        % in the regime. Thats because we have no way of defining costs for them.
        % And there's other controls we want gone, for similar reasons.
        set([subHandles.newEventButton, subHandles.removeEventButton], 'Visible', 'off');
        set(subHandles.triggerDeferredLabel, 'Visible', 'off')   
        set(subHandles.triggerDeferredLabel2, 'Visible', 'off') 
        set(subHandles.regimeRedefinableLabel, 'Visible', 'off');
        set(subHandles.changeEventNameButton, 'Visible', 'off');

        
        if event.status.regimeRedefinable
            % If it's redefinable, it's either been redefined, or it could be
            % redefined. Either way, the DURButton should be on, and show one
            % of 'Redefine' or 'Revert'.
            set(subHandles.DURButton, 'Visible', 'on');
            
            if event.status.regimeRedefined
                % Then allow for editting of trigger
                set([handles.stepData.controlsToBeDisabled, conditionControls], 'Enable', 'on');
                set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'on');
                set(subHandles.DURButton, 'String', 'Revert');
            else
                % Then allow only viewing of trigger
                set([handles.stepData.controlsToBeDisabled, conditionControls], 'Enable', 'off');
                set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'off');
                set(subHandles.DURButton, 'String', 'Redefine');
            end
            
        else
            % Then it's not to be redefined.
            % If it's in the regime and it's not to be redefined, then we
            % will have had the regime pass in it's trigger already.
            % So we can show that trigger, but not let the user change it.
            
 
            set(subHandles.DURButton, 'Visible', 'off');
            
%             if (event.status.deferredToRegime && strcmp(event.status.origin, 'cropNew')) || strcmp(event.status.origin, 'regimeNew')
%                 % Then we don't yet have a trigger and we need one. We must
%                 % set it here.
%                 set(handles.stepData.controlsToBeDisabled, 'Enable', 'on');
%                 set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'on');
%             else
                % Then it's not redefinable and its not 'first' definable. So it's already been defined.
                % Show that definition, but don't let it be changed.
 %               conditionControls = getConditionControls(subHandles);
                conditionControls = [];

                set([handles.stepData.controlsToBeDisabled, conditionControls], 'Enable', 'off');
                set([subHandles.removeConditionButton, subHandles.newConditionButton], 'Visible', 'off');
%            end
        end
        
end % end switch


% Populate the condition list from the trigger.
shorthandList = {};
for i = 1:length(handles.stepData.events(eventIndex).trigger.conditions)
    shorthandList = [shorthandList, handles.stepData.events(eventIndex).trigger.conditions{i}.shorthand];
end
set(subHandles.conditionListBox, 'String', numberStringList(shorthandList));

% Select last condition in trigger and populate the panel with it.
if(jumpToEnd || get(subHandles.conditionListBox, 'Value') > length(event.trigger.conditions))
    set(subHandles.conditionListBox, 'Value', length(event.trigger.conditions));
end

if(length(event.trigger.conditions) > 1)
    set(subHandles.removeConditionButton, 'Enable', 'on');
else
    set(subHandles.removeConditionButton, 'Enable', 'off');
end

% Also check if the event is a core event or not.
if strcmp(event.status.origin, 'core')
    set(subHandles.removeEventButton, 'Enable', 'off');
    set(subHandles.changeEventNameButton, 'Enable', 'off');
else
    set(subHandles.removeEventButton, 'Enable', 'on');
    set(subHandles.changeEventNameButton, 'Enable', 'on');
end

loadCondition(subHandles);







% Load Crop
% Loads the stepData's events list. jumpToTop is a boolean to decide
% whether we should select the top item, or leave as is.
function loadEventsList(subHandles, jumpToTop)

handles = guidata(subHandles.triggerPanel);
events = handles.stepData.events;

% Populate the event list from the crop.
set(subHandles.eventsListBox, 'String', eventStringsWithStatus(events));

% Select first event in trigger and populate the panel with it.
if(jumpToTop)
    set(subHandles.eventsListBox, 'Value', 1);
end

loadEvent(subHandles, jumpToTop);




% This function is called when we change the conditionTypeDDL.
% Sets the style, location and String for text and popupmenu based on a
% type and the conditionTypeInfo
% Uses conditionTypeInfo and the type to figure out lower control settings.
% Sets control style and location, and String for text and popupmenu.
function changeConditionType(subHandles, oldConditionType, type)

% Find controlInfo
% Get type info and trigger.
conditionTypeInfo = setupConditions();

oldIndex = find(strcmp(conditionTypeInfo.types, oldConditionType));
if strcmp(type, 'AND / OR')
    oldIndex = find(strcmp(conditionTypeInfo.types, 'AND / OR / NOT'));
end
if ~isempty(oldIndex)
    conditionTypeInfo.samples{oldIndex}.removeConditionControls(subHandles.condPanel);
end

index = find(strcmp(conditionTypeInfo.types, type));
if strcmp(type, 'AND / OR')
    index = find(strcmp(conditionTypeInfo.types, 'AND / OR / NOT'));
end
if ~isempty(index)
    conditionTypeInfo.samples{index}.loadConditionControls(subHandles.condPanel, [6, 135]);
else
    error('Could not find the passed type in the set of ImagineConditions provided by setupConditions().');
end

function conditionControls = getConditionControls(subHandles)
handles = guidata(subHandles.condPanel);
conditionTypes = get(subHandles.conditionTypeDDL, 'String');
conditionType = conditionTypes{get(subHandles.conditionTypeDDL, 'Value')};

switch conditionType   
    case 'Time Index Based'
        condition = TimeIndexedCondition('');
    case 'Month Based'
        condition = MonthBasedCondition('');
    case 'Event Happened Previously'
        condition = EventHappenedPreviouslyCondition('');
    case 'Quantity Based'        
        condition = QuantityBasedCondition('');
    case 'And / Or / Not'
        condition = AndOrNotCondition('');
    case 'Never'
        condition = NeverCondition('');
    otherwise
        error('Trying to populate the condition panel with an unrecognized condition.');
end
controlStruct = handles.(condition.handlesField);
if isstruct(controlStruct)    
    fns = fieldnames(controlStruct);
    % Remove the data part from the fns.
    ix = find(strcmp('data', fns), 1, 'first');
    if ~isempty(ix)
        fns = fns([1:(ix-1), (ix+1):end]);
    end
    for i = 1:length(fns)
        conditionControls(i) = controlStruct.(fns{i});
    end
else
   conditionControls = []; 
end

% Populate condition controls

function populateConditionControls(subHandles, condition)

switch condition.conditionType
   
    case 'Time Index Based'
        condition.loadCondition(subHandles.condPanel);
    case 'Month Based'
        condition.loadCondition(subHandles.condPanel);        
    case 'Event Happened Previously'
        handles = guidata(subHandles.condPanel);
        eventNames = {handles.stepData.events.name};
        condition.loadCondition(subHandles.condPanel, eventNames);        
    case 'Quantity Based'        
        [productRates, outputRates, eventRates, regimeUnits, thisEventName] = getQuantityBasedRequirements(subHandles);        
        condition.loadCondition(subHandles.condPanel, productRates, outputRates, eventRates, regimeUnits, thisEventName);        
    case 'And / Or / Not'
        conditionIndex = get(subHandles.conditionListBox, 'Value');
        condition.loadCondition(subHandles.condPanel, conditionIndex);        
    case 'And / Or'
        conditionIndex = get(subHandles.conditionListBox, 'Value');
        condition.loadCondition(subHandles.condPanel, conditionIndex);        
    case 'Never'
        condition.loadCondition(subHandles.condPanel);
    otherwise
        error('Trying to populate the condition panel with an unrecognized condition.');
end


% Control changed - save condition
% Goes through each control for the condition and saves its data to
% handles.stepData
function condition = saveCondition(subHandles)

handles = guidata(subHandles.conditionListBox);

conditionIndex = get(subHandles.conditionListBox, 'Value');
eventIndex = get(subHandles.eventsListBox, 'Value');

% Get the current saved trigger
trigger = handles.stepData.events(eventIndex).trigger;

trigger.conditions{conditionIndex}.shorthand = get(subHandles.shorthandEdit, 'String');
conditionTypes = get(subHandles.conditionTypeDDL, 'String');
if ~strcmp(trigger.conditions{conditionIndex}.conditionType, conditionTypes{get(subHandles.conditionTypeDDL, 'Value')})
    trigger.conditions{conditionIndex} = ImagineCondition.newCondition(conditionTypes{get(subHandles.conditionTypeDDL, 'Value')}, trigger.conditions{conditionIndex}.shorthand);
end

% Apparently, none of the ImagineConditions have special saveCondition
% arguments. So just call it directly!
trigger.conditions{conditionIndex}.saveCondition(subHandles.condPanel);

handles.stepData.events(eventIndex).trigger = trigger;
guidata(subHandles.conditionListBox, handles);

% Make sure the lists for the events and conditions are right.
set(subHandles.eventsListBox, 'String', eventStringsWithStatus(handles.stepData.events));
shorthandList = {};
for i = 1:length(handles.stepData.events(eventIndex).trigger.conditions)
    shorthandList = [shorthandList, handles.stepData.events(eventIndex).trigger.conditions{i}.shorthand];
end
set(subHandles.conditionListBox, 'String', numberStringList(shorthandList));
condition = trigger.conditions{conditionIndex};

% --- Executes on selection change in eventsListBox.
function eventsListBox_Callback(hObject, eventdata, subHandles)
% hObject    handle to eventsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns eventsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventsListBox

% Loads the selected event.
loadEvent(subHandles, 1);



% --- Executes on button press in removeEventButton.
function removeEventButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to removeEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button = questdlg('Are you sure you want to remove this event?', 'Event Removal', 'Yes', 'Cancel', 'Cancel');

if isempty(button)
    return
end
if strcmp(button, 'Cancel')
    return
end

handles = guidata(subHandles.triggerPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');
events = handles.stepData.events;
events = [events(1:eventIndex - 1), events(eventIndex+1:end)];
handles.stepData.events = events;
guidata(subHandles.triggerPanel, handles);

if(eventIndex > length(events))
    eventIndex = length(events);
end

set(subHandles.eventsListBox, 'String', eventStringsWithStatus(events));
set(subHandles.eventsListBox, 'Value', eventIndex);
loadEvent(subHandles, 1);



% --- Executes on button press in newEventButton.
function newEventButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to newEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Adds a new event with an empty trigger.
% New event in a financial event.

name = inputdlg('Please enter the name of the new event.', 'New Event');
if isempty(name)
    return
end
if isempty(name{1})
    return
end
handles = guidata(hObject);
switch handles.stepData.location
  case 'CropWizard'
    origin = 'cropNew';
  case 'Regime'
    origin = 'regimeNew';
end

handles = guidata(subHandles.triggerPanel);

% Set up the new event    

% Use $ / Paddock as the default unit
unit = Unit('', 'Money', 'Dollar'); 
denominatorUnit = Unit('', 'Paddock', 'Unit');

% Needs to be a financial event status. Means things are unlocked.
status = ImagineEventStatus('cropNew', false, false, false, false, false);

costPriceModel = PriceModel([name{1} ' Cost'], unit, denominatorUnit, true);

handles.stepData.events(end+1) = ImagineEvent(name{1}, status, costPriceModel);

set(subHandles.eventsListBox, 'String', eventStringsWithStatus(handles.stepData.events));
set(subHandles.eventsListBox, 'Value', length(handles.stepData.events));
guidata(subHandles.triggerPanel, handles);
loadEvent(subHandles, 1);




% numberStringList
%
% Given a cell array of strings, returns the strings with the index
% appended to front.
function strings = numberStringList(strings)

for i = 1:length(strings)
    strings{i} = [num2str(i), '. ', strings{i}];
end


% Gets the locked and deffered status of the event's trigger and adds it to
% name
function strings = eventStringsWithStatus(events)

% In cropWizard, we only care about deffered, and locked.
% In the regime, we care about if it's redefinable, and if it's redefined.
% In the crop wizard, we use the strings to indicate why we cant edit them.
% Also, if we can edit them do we also want to check the box (redefinable)

for i = 1:length(events)
    
    disp('In eventStringWithStatus')
    events(i)
    events(i).trigger
    if events(i).status.deferredToRegime
        deferredString = ' (Deferred)';
    else
        deferredString = '';
    end
    
    if events(i).status.regimeRedefinable
        if events(i).status.regimeRedefined
            redefinedString = ' (Redefined)';
        else
            redefinedString = ' (Redefinable)';
        end
    else
       redefinedString = '';
    end
    
    strings{i} = [events(i).name, deferredString, redefinedString];
end

% Sets the Enable parameter to en for all handles in controls
function setEnableOnControls(controls, enVis, en)
for i = 1:length(controls)
    set(controls(i), enVis, en);
end


% --- Executes on button press in DURButton.
% DUR means Defer Until Regime
function DURButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to DURButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(subHandles.triggerPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');

% If text is defer, set to defer, if text is undefer, set to undefer.
% Ditto for Redefine and Revert.
% Reload the event after this. It will probably change how the event should
% be presented.
text = get(hObject, 'String');
if strcmp(text, 'Defer')
    handles.stepData.events(eventIndex).status.deferredToRegime = true;
end
if strcmp(text, 'Undefer')
    handles.stepData.events(eventIndex).status.deferredToRegime = false;
end
if strcmp(text, 'Redefine')
    handles.stepData.events(eventIndex).status.regimeRedefined = true;    
end
if strcmp(text, 'Revert')
    handles.stepData.events(eventIndex).status.regimeRedefined = false;
end

guidata(hObject, handles);

loadEventsList(subHandles, 0);






% checkValidControlEntry
% 
% Checks whether the values of the controls are ok
function valid = checkValidControlEntry(subHandles)

conditionTypes = get(subHandles.conditionTypeDDL, 'String')
conditionType = conditionTypes{get(subHandles.conditionTypeDDL, 'Value')}

value1 = get(subHandles.control1, 'Value');
string1 = get(subHandles.control1, 'String');
value2 = get(subHandles.control2, 'Value');
string2 = get(subHandles.control2, 'String');
valueComp = get(subHandles.comparator, 'Value');
stringComp = get(subHandles.comparator, 'String');

switch conditionType

    case 'Time Index Based'
        % Controls 2 string should be numeric and integral
        valid = 1;
    case 'Month Based'
        % Cant really go wrong
        valid = 1;
    case 'Event Happened Previously'
        % Need to event to be one of the events higher in the list
        % Should be ok if the list of choices only covers the allowable
        % range.
        valid = 1;
    case 'Quantity Based'
        % Some work. Depends on the quantity.
        valid = 1;
    case 'AND / OR / NOT'
        % Need control 2 to be integral and only numbers lower than the
        % current condition list value.
        conditionIndex = get(subHandles.conditionListBox, 'Value');
        v = 0;
        try
           controlIndicies = str2num(string2)
           if all(controlIndicies == floor(controlIndicies))
               ok = 1;
           else
               ok = 0;
           end
           controlIndicies = sort(unique(controlIndicies))
          
           for i = 1:length(controlIndicies)
                if(~ok  || controlIndicies(i) >= conditionIndex || controlIndicies(i) <= 0)
                    ok = 0;
                end
           end
           if ok
               % Valid. but tidy up the numbers. Unique and increasing.
               set(subHandles.control2, 'String', num2str(controlIndicies));
               
           end
           v = ok;
        catch
        end
        valid = v;
    otherwise
        valid = 1;
end



%
%
% from a list of valid conditions, returns the longhand expression for the one in
% the indexing position.
function longHand = condition2String(conditionList, index)

index = floor(index);
if index > length(conditionList) || index <= 0
    longHand = 'Bad index.';
    return
end

% Can rely on the conditions to render their own strings.
% The only curly one is the AndOrNotCondition, which needs to be passed all
% the previous longhand expressions too.

condition = conditionList{index};
if strcmp(condition.conditionType, 'And / Or / Not')
    if index == 1
        longHand = 'Cannot use the And / Or / Not condition as the first condition.'; 
        return
    end

   for i = 1:index
       if strcmp(conditionList{i}.conditionType, 'And / Or / Not')
            lhs{i} = conditionList{i}.getLonghand(lhs);
       else
            lhs{i} = conditionList{i}.getLonghand;
       end
   end
   longHand = lhs{end};
else
    longHand = conditionList{index}.getLonghand;
end



% --- Executes on button press in changeEventNameButton.
function changeEventNameButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to changeEventNameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Use the same input dlg to get the new name and update it.
handles = guidata(subHandles.triggerPanel);
eventIndex = get(subHandles.eventsListBox, 'Value');

name = inputdlg('Please enter the name of the new event.', 'New Event', 1, {handles.stepData.events(eventIndex).name});
if isempty(name)
    return
end
if isempty(name{1})
    return
end

handles.stepData.events(eventIndex).name = name{1};
% Don't change the name of the priceModel just yet.
% We use the difference in the event name and the costPriceModel name
% to work out the events that have had name changes. This is dealt with in the saveStep.
% handles.stepData.events(eventIndex).costPriceModel.name = [name{1} ' Cost'];

guidata(subHandles.triggerPanel, handles);
set(subHandles.eventsListBox, 'String',  eventStringsWithStatus(handles.stepData.events));


% --- Executes on button press in regimeRedefinableCheckbox.
function regimeRedefinableCheckbox_Callback(hObject, eventdata, subHandles)
% hObject    handle to regimeRedefinableCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of regimeRedefinableCheckbox

% Need to update the event's status when this is changed.
handles = guidata(hObject);
eventIndex = get(subHandles.eventsListBox, 'Value');

handles.stepData.events(eventIndex).status.regimeRedefinable = get(hObject,'Value');
guidata(hObject, handles);

% Want the list to reflect the change in redefinability.
loadEventsList(subHandles, 0);
