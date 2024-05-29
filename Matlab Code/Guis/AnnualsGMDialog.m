function varargout = AnnualsGMDialog(varargin)
% ANNUALSGMDIALOG M-file for AnnualsGMDialog.fig
%      ANNUALSGMDIALOG, by itself, creates a new ANNUALSGMDIALOG or raises the existing
%      singleton*.
%
%      H = ANNUALSGMDIALOG returns the handle to a new ANNUALSGMDIALOG or the handle to
%      the existing singleton*.
%
%      ANNUALSGMDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNUALSGMDIALOG.M with the given input arguments.
%
%      ANNUALSGMDIALOG('Property','Value',...) creates a new ANNUALSGMDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AnnualsGMDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AnnualsGMDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AnnualsGMDialog

% Last Modified by GUIDE v2.5 18-Feb-2014 17:48:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnnualsGMDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @AnnualsGMDialog_OutputFcn, ...
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

function gm = setupParameters(propagationParameters)

    % Next, set up the propagation parameters. Use the provided parameters
    % where possible to overwrite the defaults.
    default.propagationParameters.manualAnnualGM = ManualAnnualGM;
    default.propagationParameters.rainfallBasedAnnualGM = RainfallBasedAnnualGM;
    modifierAware = true;
    default.propagationParameters.fixedYieldGMDelegate = FixedYieldGrowthModelDelegate(modifierAware);
    default.propagationParameters.modelChoice = 'RainfallBasedAnnualGM';
    
    default.propagationParameters.HIData = HarvestIndexData;
    default.propagationParameters.HIData.units = 'Yield';
    default.propagationParameters.HIData.HI = 1;
    
    % Default top-level parameters include spatial parameters
 %   default.propagationParameters.p = [3e-6, 0.02, 0];
    default.propagationParameters.temporalModifiers = {};
    default.propagationParameters.spatialModifiers = SpatialInteractions.empty(1,0);
  %  default.propagationParameters.firstRelevantMonth = 3;
  %  default.propagationParameters.lastRelevantMonth = 11;

    default.plantingParameters = [];
    default.harvestingParameters = [];
    gm = default;
    
    gm.propagationParameters = absorbFields(default.propagationParameters, propagationParameters);

% --- Executes just before AnnualsGMDialog is made visible.
function AnnualsGMDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnnualsGMDialog (see VARARGIN)

% Argument List:
% 1. cropInfo - so we can give yield curve units like, per Tree or per Ha.
%    cropInfo.cropType
%    cropInfo.cropName
% 2. propagationParameters structure, or empty array.
% 3. current list of crop names
% 4. current list of possible categories.

% Set up the unitType
if nargin <= 3
    msgbox('For some reason, the cropType has not been given. Assuming yield is in tonnes / Ha.');
    handles.cropName = 'Test Crop';
else
    % Then we have at least 4.
    % Assume cropType is given in first argument.
    cropInfo = varargin{1};
    handles.cropName = cropInfo.cropName;
end
handles.cropYieldUnits = 't / Ha';

propagationParameters = struct();
if nargin >= 5
    propagationParameters = varargin{2};
end
gm = setupParameters(propagationParameters);
gmFields = fieldnames(gm);

for i = 1:length(gmFields)
   handles.(gmFields{i}) = gm.(gmFields{i}); 
end

% Save the provided crop names
if nargin >= 6
    handles.possibleCropNames = varargin{3};
else
    handles.possibleCropNames = {};
end

% Save the provided category names
if nargin >= 7
    handles.possibleCategoryNames = varargin{4};    
else
    handles.possibleCategoryNames = {};
end

handles.cropNamesList = [handles.possibleCategoryNames, handles.possibleCropNames];

% Choose empty output as default to signal cancellation.
handles.output = [];
handles.summaryHandles = [];
handles.recentChars = '';

% Update handles structure
guidata(hObject, handles);

populateDialog(handles);
   
uiwait(handles.figure1);


%
% This function uses the propagation parameters data in handles to setup the controls
% and axes in the dialog.
%
function populateDialog(handles)

propPar = handles.propagationParameters;

if strcmp(propPar.modelChoice, 'RainfallBasedAnnualGM')
    loadFrenchSchultzModel(handles);        
elseif strcmp(propPar.modelChoice, 'ManualAnnualGM')
    loadManualEntryModel(handles);
else
    error('Reached a supposedly unreachable position.');
end

setupHIData(handles);
    
handles = guidata(handles.figure1);

if ~isempty(propPar.temporalModifiers)
    propPar.temporalModifiers = sortrows(propPar.temporalModifiers, 1);
end

set(handles.modifiersListbox, 'String', makeModifiersString(propPar.temporalModifiers));
set(handles.modifierLabelDDL, 'String', ['User defined', handles.cropNamesList]);
set(handles.modifiersListbox, 'Value', 1);

handles.propagationParameters = propPar;
guidata(handles.axesModelGraph, handles);

if isempty(propPar.temporalModifiers)
   set(handles.modifierAddOrUpdateButton, 'String', 'Add');
else
   set(handles.modifierAddOrUpdateButton, 'String', 'Update');    
   loadModifierFromListBox(handles);
end

refreshSpatialInteractionLabels(handles)

function setupHIData(handles)

set(handles.editHI, 'String', num2str(handles.propagationParameters.HIData.HI));

units = handles.propagationParameters.HIData.units;

contents = cellstr(get(handles.popupmenuHarvestUnits,'String'));
ix = find(strcmp(units, contents), 1, 'first');
if isempty(ix)
    error('No harvest units in the drop down list match the HIData.units.');
end
set(handles.popupmenuHarvestUnits, 'Value', ix);

if (strcmp(units, 'Yield'))
    % Changed from biomass to yield.
    % Disable the HI entry.
    set(handles.editHI, 'Enable', 'off');
elseif (strcmp(units, 'Biomass'))
    % Changed from yield to biomass.
    % enable the HI entry.
    set(handles.editHI, 'Enable', 'on');
else
   error('Reached a supposedly unreachable spot.');
end


% --- Outputs from this function are returned to the command line.
function varargout = AnnualsGMDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
close(gcf);

function strings = makeModifiersString(modifiers)

if isempty(modifiers)
    strings = {};
    return
end

modifiers = sortrows(modifiers, 1);
rowCount = size(modifiers, 1);
strings = cell(rowCount, 1);
for i = 1:rowCount
    strings{i} = ['<html><table><tr><td textalign="left">', modifiers{i, 1}, '</td><td textalign="right">', num2str(modifiers{i, 2}), '</td></tr></table></html>'];
end

function loadModifierFromListBox(handles)

% use the value from the listbox to provide the index of the currently
% selected row.
propPar = handles.propagationParameters;
modIndex = get(handles.modifiersListbox, 'Value');
if isempty(propPar.temporalModifiers) || modIndex > size(propPar.temporalModifiers, 1)
    return
end

% Get name
modLabel = propPar.temporalModifiers{modIndex, 1};
modDDLIndex = find(strcmp(get(handles.modifierLabelDDL, 'String'), modLabel));
if isempty(modDDLIndex)
    % Use the edit, set DDL to custom
    set(handles.modifierLabelEdit, 'String', modLabel);
    set(handles.modifierLabelDDL, 'Value', 1);
    set(handles.modifierLabelEdit, 'Enable', 'on');
else
   % Use the DDL. Clear the edit
    set(handles.modifierLabelEdit, 'String', '');
    set(handles.modifierLabelDDL, 'Value', modDDLIndex);
    set(handles.modifierLabelEdit, 'Enable', 'off');
end
% Set the percentage
setValidPercentage(handles, propPar.temporalModifiers{modIndex, 2});

% Use selectedItemInList('yes') to setup the add and remove buttons.
selectedItemInListbox(handles, 'yes');

function selectedItemInListbox(handles, check)

switch check
    case 'yes'
       set(handles.modifierAddOrUpdateButton, 'String', 'Update');
       set(handles.modifierRemoveButton, 'Enable', 'on');
        
    case 'no'
       set(handles.modifiersListbox, 'Value', []);
       set(handles.modifierAddOrUpdateButton, 'String', 'Add');
       set(handles.modifierRemoveButton, 'Enable', 'off');         
end      

function setValidPercentage(handles, percentage)

persistent lastValidPercentage

if isempty(lastValidPercentage)
   lastValidPercentage = 100;
end


% If the percentage is valid, ok, otherwise set to something valid like
% lastValidPercentage
valid = 1;
if isnan(percentage) 
    valid = 0;
elseif percentage <= 0 || percentage >= 200
    valid = 0;
end

if ~valid
    percentage = lastValidPercentage;
end
    
set(handles.modifierPercentageEdit, 'String', num2str(percentage));

lastValidPercentage = percentage;

% --- Executes on button press in acceptButton.
function acceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.propagationParameters = handles.propagationParameters;
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(gcf);

% --- Executes on selection change in modifiersListbox.
function modifiersListbox_Callback(hObject, eventdata, handles)
% hObject    handle to modifiersListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns modifiersListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modifiersListbox

% If we've selected more than one item, select the last one.
ixs = get(hObject, 'Value');
if length(ixs) > 1
    set(hObject, 'Value', ixs(end))
end

loadModifierFromListBox(handles)

% --- Executes during object creation, after setting all properties.
function modifiersListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modifiersListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function modifierLabelEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modifierLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in modifierRemoveButton.
function modifierRemoveButton_Callback(hObject, eventdata, handles)
% hObject    handle to modifierRemoveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check that a valid item is selected in the listbox. Should be as this
% button should be disabled when not applicable.

% If the listbox has a single item selected, remove it after a prompt.

modIndex = get(handles.modifiersListbox, 'Value');
if length(modIndex) ~= 1
    return
end
mods = handles.propagationParameters.temporalModifiers;
rowCount = size(mods, 1);

mods = [mods(1:modIndex-1,:); mods(modIndex+1:end,:)];
handles.propagationParameters.temporalModifiers = mods;

set(handles.modifiersListbox, 'String', makeModifiersString(mods));

if modIndex == rowCount
    newIndex = modIndex - 1;
else
    newIndex = modIndex;
end

if newIndex <= 0   
    set(handles.modifiersListbox, 'Value', []);
    guidata(hObject, handles);  
    selectedItemInListbox(handles, 'no');
else
    set(handles.modifiersListbox, 'Value', newIndex);
    guidata(hObject, handles);    
    loadModifierFromListBox(handles);
end





% --- Executes on button press in modifierAddOrUpdateButton.
function modifierAddOrUpdateButton_Callback(hObject, eventdata, handles)
% hObject    handle to modifierAddOrUpdateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to see if the DDL has a name, or if the edit has a name.
% Should have them, as this button is disabled unless a valid name and
% percentage is listed.

% Get DDL string if value not 1.
ddlValue = get(handles.modifierLabelDDL, 'Value');
ddlStrings = get(handles.modifierLabelDDL, 'String');
editString = get(handles.modifierLabelEdit, 'String');

if ddlValue > 1
    modLabel = ddlStrings{ddlValue};
else
    modLabel = editString;
end

if isempty(modLabel)
      % There's a problem. We really should have a valid modLabel at this
    % point.
    msgbox('Whoops. For some reason we can add a modifier that has no valid label. Aborting add/update.');
    return  
end

modPercentage = str2double(get(handles.modifierPercentageEdit, 'String'));
if isnan(modPercentage) || modPercentage <= 0 || modPercentage >= 200
    %Then we have an invalid percentage.
    msgbox('Whoops. Somehow an invalid percentage has made it to the percentage box. Aborting add/update.');
    return
end

mods = handles.propagationParameters.temporalModifiers;
if isempty(mods)
    modIndex = [];
else
    modIndex = find(strcmp({mods{:,1}}, modLabel));
end

if isempty(modIndex)
    % then we're adding.
    % the button label should read Add.
    if ~strcmp(get(hObject, 'String'), 'Add')
        msgbox('Whoops. We have conditions for adding, but the button says something else');
    end

    newRow = {modLabel, modPercentage};
    mods = [mods; newRow];
    
else
   % then we're updating. the button label should read Update. 
    if ~strcmp(get(hObject, 'String'), 'Update')
        msgbox('Whoops. We have conditions for Updating, but the button says something else');
    end

    mods(modIndex, :) = {modLabel, modPercentage};
    
end

mods = sortrows(mods, 1);
handles.propagationParameters.temporalModifiers = mods;
guidata(hObject, handles);
set(handles.modifiersListbox, 'String', makeModifiersString(mods));

set(handles.modifiersListbox, 'Value', find(strcmp({mods{:, 1}}, modLabel)));
selectedItemInListbox(handles, 'yes');

% --- Executes on selection change in modifierLabelDDL.
function modifierLabelDDL_Callback(hObject, eventdata, handles)
% hObject    handle to modifierLabelDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns modifierLabelDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modifierLabelDDL


% Selects a name, or sets to custom. If name is selected, check to see if
% it already exists. If it does, set the listbox value to appropriate index
% and call loadModifierFromListBox(handles)
% If its not in the list, then clear edit and percentage.

ddlValue = get(hObject, 'Value');
if ddlValue <= 1
    % Then we selected custom.
    % Make sure the edit box is enabled.
    set(handles.modifierLabelEdit, 'Enable', 'on');
    selectedItemInListbox(handles, 'no');
    return;
else
    set(handles.modifierLabelEdit, 'Enable', 'off');    
end

ddlStrings = get(hObject, 'String');
selectedItem = ddlStrings{ddlValue};

mods = handles.propagationParameters.temporalModifiers;
if isempty(mods)
    modIndex = [];
else
    modIndex = find(strcmp({mods{:,1}}, selectedItem));
end

if ~isempty(modIndex)
    set(handles.modifiersListbox, 'Value', modIndex);
    loadModifierFromListBox(handles);
    return
else
    set(handles.modifierLabelEdit, 'String', '');
%    set(handles.modifierPercentageEdit, 'String', '');
    selectedItemInListbox(handles, 'no');
%    set(handles.modifierAddOrUpdateButton, 'String', 'Add');
end


% --- Executes during object creation, after setting all properties.
function modifierLabelDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modifierLabelDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function modifierPercentageEdit_Callback(hObject, eventdata, handles)
% hObject    handle to modifierPercentageEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of modifierPercentageEdit as text
%        str2double(get(hObject,'String')) returns contents of modifierPercentageEdit as a double

setValidPercentage(handles, str2double(get(hObject, 'String')));


% --- Executes during object creation, after setting all properties.
function modifierPercentageEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modifierPercentageEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on modifierLabelEdit and no controls selected.
function modifierLabelEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to modifierLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% We want this to be called on each key press, not just on the exit.
% Sets a name. If non-empty name, check to see if the name
% it already exists in list. If it does, set the listbox value to appropriate index
% and call loadModifierFromListBox(handles)
% If its not in the list, then clear edit and percentage.

if ~isfield(handles, 'jModifierLabelEdit')
   handles.jModifierLabelEdit = findjobj(hObject);
   guidata(hObject, handles);
end

newModifierLabel = handles.jModifierLabelEdit.text;
%newModifierLabel = get(hObject, 'String')
%handles.recentChars = [handles.recentChars, eventdata.Character];
%guidata(hObject, handles);
%newModifierLabel = [newModifierLabel, handles.recentChars]

if isempty(newModifierLabel)
  % disp('empty string')
    return
end

mods = handles.propagationParameters.temporalModifiers;
if isempty(mods)
    modIndex = [];
else
    modIndex = find(strcmp({mods{:,1}}, newModifierLabel));
end


if ~isempty(modIndex)
    set(handles.modifiersListbox, 'Value', modIndex);
    loadModifierFromListBox(handles);
    return
else
    set(handles.modifierLabelDDL, 'Value', 1);
%    set(handles.modifierPercentageEdit, 'String', '');
    selectedItemInListbox(handles, 'no');
    %set(handles.modifierAddOrUpdateButton, 'String', 'Add');
end



% --- Executes on button press in pushbuttonSetupSpatialInteractions.
function pushbuttonSetupSpatialInteractions_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupSpatialInteractions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cropInfo.cropName = handles.cropName;
cropInfo.cropYieldUnits = handles.cropYieldUnits;
assignin('base', 'ppsis', handles.propagationParameters.spatialModifiers);
sis = SpatialInteractionsDialog(cropInfo, handles.propagationParameters.spatialModifiers);
if ~isempty(sis)
    handles.propagationParameters.spatialModifiers = sis;
    guidata(hObject, handles);
    refreshSpatialInteractionLabels(handles);
end

function refreshSpatialInteractionLabels(handles)
sis = handles.propagationParameters.spatialModifiers;
if ~isempty(sis) && strcmp(class(sis), 'SpatialInteractions');
    if sis.useCompetition
        set(handles.textCompetitionModel, 'String', 'ON');
    else
        set(handles.textCompetitionModel, 'String', 'OFF');    
    end

    if sis.useWaterlogging
        set(handles.textWaterloggingModel, 'String', 'ON');
    else
        set(handles.textWaterloggingModel, 'String', 'OFF');    
    end

    if sis.useNCZ    
        set(handles.textNCZModel, 'String', sis.NCZChoice);
    else
        set(handles.textNCZModel, 'String', 'NONE');    
    end
else
    set(handles.textCompetitionModel, 'String', 'NOT SET');
    set(handles.textWaterloggingModel, 'String', 'NOT SET');
    set(handles.textNCZModel, 'String', 'NOT SET');
end



function modifierLabelEdit_Callback(hObject, eventdata, handles)
% hObject    handle to modifierLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of modifierLabelEdit as text
%        str2double(get(hObject,'String')) returns contents of modifierLabelEdit as a double


% --- Executes on button press in pushbuttonSwitchModel.
function pushbuttonSwitchModel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSwitchModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Enable', 'off');
if strcmp(handles.propagationParameters.modelChoice, 'RainfallBasedAnnualGM')
    handles.propagationParameters.modelChoice = 'ManualAnnualGM';
    guidata(hObject, handles);
    loadManualEntryModel(handles);
elseif strcmp(handles.propagationParameters.modelChoice, 'ManualAnnualGM')
    handles.propagationParameters.modelChoice = 'RainfallBasedAnnualGM';
    guidata(hObject, handles);
    loadFrenchSchultzModel(handles);        
else
    error('Reached a supposedly unreachable position.');
end
    
set(hObject, 'Enable', 'on');


% --- Executes on selection change in popupmenuHarvestUnits.
function popupmenuHarvestUnits_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuHarvestUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuHarvestUnits contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuHarvestUnits

contents = cellstr(get(hObject,'String'));
str = contents{get(hObject,'Value')};
currStr = handles.propagationParameters.HIData.units;
if strcmp(currStr, str)
    return
end

handles.propagationParameters.HIData.units = str;
guidata(hObject, handles);

if (strcmp(str, 'Yield'))
    % Changed from biomass to yield.
    % Disable the HI entry.
    set(handles.editHI, 'Enable', 'off');
elseif (strcmp(str, 'Biomass'))
    % Changed from yield to biomass.
    % enable the HI entry.
    set(handles.editHI, 'Enable', 'on');
else
   error('Reached a supposedly unreachable spot.');
end

% Refresh the summary and the graph.
if strcmp(handles.propagationParameters.modelChoice, 'RainfallBasedAnnualGM')
    handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData);
    handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData);
elseif strcmp(handles.propagationParameters.modelChoice, 'ManualAnnualGM')
    handles.propagationParameters.manualAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData)
    handles.propagationParameters.manualAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData)
end


% --- Executes during object creation, after setting all properties.
function popupmenuHarvestUnits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuHarvestUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHI_Callback(hObject, eventdata, handles)
% hObject    handle to editHI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHI as text
%        str2double(get(hObject,'String')) returns contents of editHI as a double
num = str2double(get(hObject, 'String'));
if isnan(num)
   set(hObject, 'String', num2str(handles.propagationParameters.HIData.HI)); 
else
    if num > 1
        num = 1;
        set(hObject, 'String', num2str(num)); 
    end
    if num < 0.0000001;
        num = 0.0000001;
        set(hObject, 'String', num2str(num)); 
    end
    handles.propagationParameters.HIData.HI = num;
    guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function editHI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonSetupModel.
function pushbuttonSetupModel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.propagationParameters.modelChoice, 'RainfallBasedAnnualGM')
    handles.propagationParameters.rainfallBasedAnnualGM.setup(handles.propagationParameters.HIData);
    handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData);
    handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData);
elseif strcmp(handles.propagationParameters.modelChoice, 'ManualAnnualGM')
    handles.propagationParameters.manualAnnualGM.setup(handles.propagationParameters.HIData);
    handles.propagationParameters.manualAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData)
    handles.propagationParameters.manualAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData)
else
    error('Reached a supposedly unreachable position.');
end
setupHIData(handles);
 

% Deletes all the elements of summaryControls field in handles and 
% saves the resulting handles struct without the controls.
function handles = deleteSummaryHandles(handles)
for i = 1:length(handles.summaryHandles)
    delete(handles.summaryHandles(i))
end
handles.summaryHandles = [];
guidata(handles.figure1, handles);


function loadManualEntryModel(handles)
handles = loadModelControls(handles, 'ManualAnnualGMSummary.fig');
handles.propagationParameters.manualAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData)
handles.propagationParameters.manualAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData)
set(handles.uipanelModelSummary, 'Title', 'Manual Trend Model');
set(handles.pushbuttonSwitchModel, 'String', 'Switch to French-Schultz Model');


function loadFrenchSchultzModel(handles)
handles = loadModelControls(handles, 'RainfallBasedAnnualGMSummary.fig');
handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryPanel(handles.summaryHandles, handles.propagationParameters.HIData)
handles.propagationParameters.rainfallBasedAnnualGM.populateSummaryGraph(handles.axesModelGraph, handles.propagationParameters.HIData)
set(handles.uipanelModelSummary, 'Title', 'French-Schultz Model');
set(handles.pushbuttonSwitchModel, 'String', 'Switch to Manual Trend Model');


function handles = loadModelControls(handles, figName)

% Clear the summary controls.
removeHandles(handles.summaryHandles);
handles.summaryHandles = [];

% Load the summary fig.
td = load(figName, '-MAT');
if(~isempty(td.hgS_070000.children))
    hs =  struct2handle(td.hgS_070000.children, repmat(handles.uipanelModelSummary, length(td.hgS_070000.children), 1), 'convert');  
    summaryHandles = grabHandles(hs);
else
    return
end

handles = combineFields(handles, summaryHandles);

handles.summaryHandles = summaryHandles;
guidata(handles.uipanelModelSummary, handles);


% --- Executes on button press in pushbuttonSetupFixedYieldGM.
function pushbuttonSetupFixedYieldGM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupFixedYieldGM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.propagationParameters.fixedYieldGMDelegate.setupGrowthModel(handles.cropName);

% Is this all we need to do??


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

extractPlotData(handles.figure1, true);

