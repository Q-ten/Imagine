function varargout = RainfallBasedGMDialogue(varargin)
% RAINFALLBASEDGMDIALOGUE M-file for RainfallBasedGMDialogue.fig
%      RAINFALLBASEDGMDIALOGUE, by itself, creates a new RAINFALLBASEDGMDIALOGUE or raises the existing
%      singleton*.
%
%      H = RAINFALLBASEDGMDIALOGUE returns the handle to a new RAINFALLBASEDGMDIALOGUE or the handle to
%      the existing singleton*.
%
%      RAINFALLBASEDGMDIALOGUE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RAINFALLBASEDGMDIALOGUE.M with the given input arguments.
%
%      RAINFALLBASEDGMDIALOGUE('Property','Value',...) creates a new RAINFALLBASEDGMDIALOGUE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RainfallBasedGMDialogue_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RainfallBasedGMDialogue_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RainfallBasedGMDialogue

% Last Modified by GUIDE v2.5 02-May-2012 06:34:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RainfallBasedGMDialogue_OpeningFcn, ...
                   'gui_OutputFcn',  @RainfallBasedGMDialogue_OutputFcn, ...
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

    % Default top-level parameters include spatial parameters
    default.propagationParameters.p = [3e-6, 0.02, 0];
    default.propagationParameters.temporalModifiers = {};
    default.propagationParameters.spatialModifiers = SpatialInteractions.empty(1,0);
    default.propagationParameters.firstRelevantMonth = 3;
    default.propagationParameters.lastRelevantMonth = 11;

    default.plantingParameters = [];
    default.harvestingParameters = [];
    gm = default;
    
    gm.propagationParameters = absorbFields(default.propagationParameters, propagationParameters);


% --- Executes just before RainfallBasedGMDialogue is made visible.
function RainfallBasedGMDialogue_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RainfallBasedGMDialogue (see VARARGIN)

% Argument List:
% 1. cropInfo - so we can give yield curve units like, per Tree or per Ha.
%    cropInfo.cropType
%    cropInfo.cropName
%    cropInfo.cropYieldUnits (actually should be defined by the
%    growthmodel).
% 2. propagationParameters structure, or empty array.
% 3. current list of crop names
% 4. current list of possible categories.

% Set up the unitType
if nargin <= 3
    msgbox('For some reason, the cropType has not been given. Assuming yield is in tonnes / Ha.');
    set(handles.unitTypeLabel, 'String', 'per Hectare');
    handles.cropYieldUnits = 't / Ha';
    handles.cropName = 'Test Crop';
else
    % Then we have at least 4.
    % Assume cropType is given in first argument.
    cropInfo = varargin{1};
    handles.cropName = cropInfo.cropName;
    if(strcmp(cropInfo.cropType, {'Tree', 'Coppice', 'Plantation'}))
        set(handles.unitTypeLabel, 'String', 'per Tree');
        handles.cropYieldUnits = 't / tree';
    else
        set(handles.unitTypeLabel, 'String', 'per Hectare');
        handles.cropYieldUnits = 't / Ha';
    end
end

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

handles.xpoints = [];
handles.ypoints = [];

axes(handles.axes1);
hold on
handles.sc = scatter([351],[1], 25, 'b');
handles.plo = plot([0], [0]);

p = propPar.p;
set(handles.RBA, 'String', num2str(-p(1)));
set(handles.RBB, 'String', num2str(p(2)));
set(handles.RBC, 'String', num2str(p(3)));

set(handles.firstRelevantMonthDDL, 'Value', propPar.firstRelevantMonth);

set(handles.lastRelevantMonthDDL, 'Value', propPar.lastRelevantMonth);

if ~isempty(propPar.temporalModifiers)
    propPar.temporalModifiers = sortrows(propPar.temporalModifiers, 1);
end

set(handles.modifiersListbox, 'String', makeModifiersString(propPar.temporalModifiers));
set(handles.modifierLabelDDL, 'String', ['User defined', handles.cropNamesList]);
set(handles.modifiersListbox, 'Value', 1);

handles.propagationParameters = propPar;
guidata(handles.axes1, handles);
updateYieldCurve(handles);

if isempty(propPar.temporalModifiers)
   set(handles.modifierAddOrUpdateButton, 'String', 'Add');
else
   set(handles.modifierAddOrUpdateButton, 'String', 'Update');    
   loadModifierFromListBox(handles);
end

refreshSpatialInteractionLabels(handles)

% --- Outputs from this function are returned to the command line.
function varargout = RainfallBasedGMDialogue_OutputFcn(hObject, eventdata, handles) 
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

% Grab the polynomial parameters
A = str2double(get(handles.RBA, 'String'));
B = str2double(get(handles.RBB, 'String'));
C = str2double(get(handles.RBC, 'String'));

% Check them
if(isnan(A))
    A = 0;
end
if(isnan(B))
    B = 0;
end
if(isnan(C))
    C = 0;
end

%Set the polynomial parameters and add them to GM.

handles.propagationParameters.p = [-A, B, C];
handles.propagationParameters.firstRelevantMonth = get(handles.firstRelevantMonthDDL, 'Value');
handles.propagationParameters.lastRelevantMonth = get(handles.lastRelevantMonthDDL, 'Value');

handles.output.propagationParameters = handles.propagationParameters;
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(gcf);


function RBA_Callback(hObject, eventdata, handles)
% hObject    handle to RBA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RBA as text
%        str2double(get(hObject,'String')) returns contents of RBA as a double

handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function RBA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RBA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function RBB_Callback(hObject, eventdata, handles)
% hObject    handle to RBB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RBB as text
%        str2double(get(hObject,'String')) returns contents of RBB as a double

handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function RBB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RBB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function RBC_Callback(hObject, eventdata, handles)
% hObject    handle to RBC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RBC as text
%        str2double(get(hObject,'String')) returns contents of RBC as a double

handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function RBC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RBC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% This function updates the plot with rainfall based data
function updateYieldCurve(handles)

if(isempty(handles.xpoints) || isempty(handles.ypoints))

    % Get the numbers A,B,C
    A = str2double(get(handles.RBA, 'String'));
    B = str2double(get(handles.RBB, 'String'));
    C = str2double(get(handles.RBC, 'String'));

    if(isnan(A))
        A = 0;
    end
    if(isnan(B))
        B = 0;
    end
    if(isnan(C))
        C = 0;
    end

    p = [-A, B, C];

else
    p = polyfit(handles.xpoints, handles.ypoints, 2);
    set(handles.RBA, 'String', -p(1));
    set(handles.RBB, 'String',  p(2));
    set(handles.RBC, 'String',  p(3));
end
    
t = [0:700];
y = polyval(p, t);

hold on
axes(handles.axes1);
set(handles.plo, 'XData', t);
set(handles.plo, 'YData', y);

set(handles.sc, 'XData', handles.xpoints);
set(handles.sc, 'YData', handles.ypoints);
axis([0 700 0 max(y) * 1.2])
xlabel('Rainfall (mm)');
ylabel('Yield (t/Ha)');

% --- Executes on button press in fineTuneCurve.
function fineTuneCurve_Callback(hObject, eventdata, handles)
% hObject    handle to fineTuneCurve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

but = 1;

xpoints = [0 350 700];

% Get the numbers A,B,C
A = str2double(get(handles.RBA, 'String'));
B = str2double(get(handles.RBB, 'String'));
C = str2double(get(handles.RBC, 'String'));

if(isnan(A))
    A = 0;
end
if(isnan(B))
    B = 0;
end
if(isnan(C))
    C = 0;
end

p = [-A, B, C];

ypoints = polyval(p, xpoints);

set(handles.sc, 'XData', xpoints);
set(handles.sc, 'YData', ypoints);

while (but == 1)
    [x,y,but] = ginput(1); 
    xlim = get(handles.axes1, 'XLim');
    ylim = get(handles.axes1, 'YLim');
    if(x < xlim(1) || x > xlim(2) || y < ylim(1) || y > ylim(2) || but ~= 1)
        break;
    end
    xpoints(end+1) = x;
    ypoints(end+1) = y;

    handles.xpoints = xpoints;
    handles.ypoints = ypoints;
    
    guidata(hObject, handles);
    updateYieldCurve(handles);
end

set(handles.sc, 'XData', []);
set(handles.sc, 'YData', []);


% --- Executes on selection change in firstRelevantMonthDDL.
function firstRelevantMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to firstRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns firstRelevantMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from firstRelevantMonthDDL


% --- Executes during object creation, after setting all properties.
function firstRelevantMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to firstRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lastRelevantMonthDDL.
function lastRelevantMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to lastRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lastRelevantMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lastRelevantMonthDDL


% --- Executes during object creation, after setting all properties.
function lastRelevantMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lastRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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


% --- Executes on slider movement.
function AGBMSlider_Callback(hObject, eventdata, handles)
% hObject    handle to AGBMSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

sliderNum = get(hObject, 'Value');
handles.propagationParameters.spatialModifiers.sliderAGBM = sliderNum;
guidata(hObject, handles);
setSliderLabels(handles);
updateSpatialModifierPlot(handles)

% --- Executes during object creation, after setting all properties.
function AGBMSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AGBMSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function BGBMSlider_Callback(hObject, eventdata, handles)
% hObject    handle to BGBMSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderNum = get(hObject, 'Value');
handles.propagationParameters.spatialModifiers.sliderBGBM = sliderNum;
guidata(hObject, handles);
setSliderLabels(handles);
updateSpatialModifierPlot(handles)

% --- Executes during object creation, after setting all properties.
function BGBMSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BGBMSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function maxAGBMEdit_Callback(hObject, eventdata, handles)
% hObject    handle to maxAGBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxAGBMEdit as text
%        str2double(get(hObject,'String')) returns contents of maxAGBMEdit as a double

% We need to maintain a valid number in this field.
entry = get(hObject, 'String');
newNum = str2double(entry);

if ~isnan(newNum)
    if newNum > 0
        handles.propagationParameters.spatialModifiers.maxAGBM = newNum;
        guidata(hObject, handles);
        setSliderLabels(handles);
    end
end

set(hObject, 'String', num2str(handles.propagationParameters.spatialModifiers.maxAGBM, 3));
updateSpatialModifierPlot(handles)

% --- Executes during object creation, after setting all properties.
function maxAGBMEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxAGBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxBGBMEdit_Callback(hObject, eventdata, handles)
% hObject    handle to maxBGBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxBGBMEdit as text
%        str2double(get(hObject,'String')) returns contents of maxBGBMEdit as a double
% We need to maintain a valid number in this field.
entry = get(hObject, 'String');
newNum = str2double(entry);

if ~isnan(newNum)
    if newNum > 0
        handles.propagationParameters.spatialModifiers.maxBGBM = newNum;
        guidata(hObject, handles);
        setSliderLabels(handles);
    end
end

set(hObject, 'String', num2str(handles.propagationParameters.spatialModifiers.maxBGBM, 3));
updateSpatialModifierPlot(handles)

function setSliderLabels(handles)
sMs = handles.propagationParameters.spatialModifiers;
set(handles.AGBMLabel, 'String', [num2str(sMs.maxAGBM * sMs.sliderAGBM, 3), ' kg']);
set(handles.BGBMLabel, 'String', [num2str(sMs.maxBGBM * sMs.sliderBGBM, 3), ' kg']);


% --- Executes during object creation, after setting all properties.
function maxBGBMEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxBGBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function reachFactorEdit_Callback(hObject, eventdata, handles)
% hObject    handle to reachFactorEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of reachFactorEdit as text
%        str2double(get(hObject,'String')) returns contents of reachFactorEdit as a double

% We need to maintain a valid number in this field.
entry = get(hObject, 'String');
newNum = str2double(entry);

if ~isnan(newNum)
    if newNum > 0 && newNum <=5
        handles.propagationParameters.spatialModifiers.reachFactor = newNum;
        guidata(hObject, handles);
    end
end

set(hObject, 'String', num2str(handles.propagationParameters.spatialModifiers.reachFactor, 3));
updateSpatialModifierPlot(handles)

% --- Executes during object creation, after setting all properties.
function reachFactorEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reachFactorEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function transpirationFactorEdit_Callback(hObject, eventdata, handles)
% hObject    handle to transpirationFactorEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transpirationFactorEdit as text
%        str2double(get(hObject,'String')) returns contents of transpirationFactorEdit as a double

% We need to maintain a valid number in this field.
entry = get(hObject, 'String');
newNum = str2double(entry);

if ~isnan(newNum)
    if newNum > 0 && newNum <=5
        handles.propagationParameters.spatialModifiers.transpirationFactor = newNum;
        guidata(hObject, handles);
    end
end

set(hObject, 'String', num2str(handles.propagationParameters.spatialModifiers.transpirationFactor, 3));
updateSpatialModifierPlot(handles)

% --- Executes during object creation, after setting all properties.
function transpirationFactorEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transpirationFactorEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
