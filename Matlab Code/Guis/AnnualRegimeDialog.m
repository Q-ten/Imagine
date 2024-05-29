function varargout = AnnualRegimeDialog(varargin)
% ANNUALREGIMEDIALOG M-file for AnnualRegimeDialog.fig
%      ANNUALREGIMEDIALOG, by itself, creates a new ANNUALREGIMEDIALOG or raises the existing
%      singleton*.
%
%      H = ANNUALREGIMEDIALOG returns the handle to a new ANNUALREGIMEDIALOG or the handle to
%      the existing singleton*.
%
%      ANNUALREGIMEDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNUALREGIMEDIALOG.M with the given input arguments.
%
%      ANNUALREGIMEDIALOG('Property','Value',...) creates a new ANNUALREGIMEDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AnnualRegimeDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AnnualRegimeDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AnnualRegimeDialog

% Last Modified by GUIDE v2.5 03-Aug-2012 14:28:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnnualRegimeDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @AnnualRegimeDialog_OutputFcn, ...
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


% --- Executes just before AnnualRegimeDialog is made visible.
function AnnualRegimeDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnnualRegimeDialog (see VARARGIN)


% Arguments:
%
% Pass in a single struct containing arguments in the following fields.
%
% existingRegimeDefinitions
% existingCropDefinitions
% regimeParameters
%
% existingRegimeDefinitions - a struct array with fields regimeLabels,
% regimeStartYears, regimeFinalYears, regimeCategory, regimeType
%
% existingCropDefinitions - a struct array with a field cropName,
% cropCategory, and eventDefinitions
%
% regimeParameters will be a struct containing the parameters used to define this regime.
% Will be empty or absent if this is a new regime, but present if this is
% an editted regime.

if nargin < 4
    disp('No regime parameters struct passed.')
    return
end
    
regimeArguments = varargin{1};

argumentFields = {'regimeDefinitions', 'cropDefinitions'};

% For each argument field, add it to handles if it exists. Otherwise set it
% to empty.
% NOTE - Perhaps this should be done so that handles is defined with
% default values, and then the for loop overwrites fields if they exist in
% the regimeArguments struct.
for i = 1:length(argumentFields)
    if isfield(regimeArguments, argumentFields{i})
        handles.(argumentFields{i}) = regimeArguments.(argumentFields{i});
    else
        handles.(argumentFields{i}) = [];
    end
end

% The Annual Regime represents a rotation of crops in the Annual category.
% The regime defines a rotation list, which will be repeated until the end
% of the regime. An item in the rotation list contains the name of the crop
% to be planted, the planting and harvesting month, and also the name of a
% companion crop, which will be planted the month following the harvest,
% and exist until the planting of the next years crop. These are likely to
% be pastures.
%
% The regime dialog also defines the standard regime fields such as the
% regime label, the start and final year, the timeline colour, and also
% allows the user to define specific triggers for crop's events if desired.

% get the crop definitions that are annual crops.
annualCropDefinitions = handles.cropDefinitions(strcmp({handles.cropDefinitions.categoryName}, 'Annual') | strcmp({handles.cropDefinitions.categoryName}, 'Pasture'));
if isempty(annualCropDefinitions)   
    uiwait(warndlg('No annual crops are defined, or at least none were passed to the Annual Regime Dialog.'));
    delete(handles.figure1);
    return
end

% Set up default regime parameters
handles.regimeLabel = 'New Annual Regime';
handles.timelineColour = [0 0 1];
handles.startYear = 1;
handles.finalYear = 1;
handles.rotationList = [];
% has 
% primaryCrop
% companionCrop
% plantingMonth (int)
% harvestingMonth (int)

handles.cropEventTriggers = struct('cropName', {}, 'eventTriggers', {});
% has
% cropName
% eventsTriggers
    % has
    % eventName
    % trigger

handles.pastureControls = [handles.textDSE, handles.editDSE];
handles.annualControls = [handles.textPlant, handles.plantDDL, ...
                          handles.text4, handles.harvestDDL, ...
                          handles.text5, handles.companionCropDDL];

if isfield(regimeArguments, 'regimeParameters')
   
    regParList = {'regimeLabel', 'timelineColour', 'startYear', 'finalYear', 'rotationList', 'cropEventTriggers'};

    for i = 1:length(regParList)
       if isfield(regimeArguments.regimeParameters, regParList{i})
           % Then overwrite the default regPars with what is provided in
           % the regimeArguments.
           handles.(regParList{i}) = regimeArguments.regimeParameters.(regParList{i});
       end
    end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update CropEventTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% At this point we'll have loaded the cropEventTriggers that were last
% saved in the regime. However there could have been changes in the crops
% themselves. For instance we could have added or removed a financial
% event.
% We should make sure the current crop's events are present in the regime's
% cropEventTriggers struct. We want to keep what was there if it's still
% appropriate, but use the crop's ones if they are there.
% So we import ones that aren't already there. (Add newly defined financial
% events), we overwrite ones that are still there, unless the ones in the
% regime are regime redefined.
% That amounts to overwriting all the events, except ones that are regime
% redefined, or defferred to regime.
% This is something that should occur before we run a simulation as well.
% If we change something in the crop, don't we want that reflected in the
% regimes too? For example, if we say that an event is not regime
% redefinable in the crop, we should not use the regime one.
if ~isempty(handles.cropEventTriggers)
    handles.cropEventTriggers = updateCropEventTriggers({handles.cropEventTriggers.cropName}, handles.cropEventTriggers);
end



% Set the months list.
handles.months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

% Set output to empty
handles.output = [];

% Update handles structure
guidata(hObject, handles);

setupControls(handles);

% UIWAIT makes AnnualRegimeDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AnnualRegimeDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles)
    varargout{1} = [];
else
    % Get default command line output from handles structure
    varargout{1} = handles.output;
    close(handles.figure1);
end

% --- Executes on selection change in cropDDL.
function cropDDL_Callback(hObject, eventdata, handles)
% hObject    handle to cropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns cropDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cropDDL
setupRotationControls(handles);

% --- Executes during object creation, after setting all properties.
function cropDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in harvestDDL.
function harvestDDL_Callback(hObject, eventdata, handles)
% hObject    handle to harvestDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns harvestDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from harvestDDL


% --- Executes during object creation, after setting all properties.
function harvestDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harvestDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in plantDDL.
function plantDDL_Callback(hObject, eventdata, handles)
% hObject    handle to plantDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns plantDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plantDDL


% --- Executes during object creation, after setting all properties.
function plantDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plantDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in rotationListBox.
function rotationListBox_Callback(hObject, eventdata, handles)
% hObject    handle to rotationListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns rotationListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rotationListBox
listBoxSelection(handles);


% --- Executes during object creation, after setting all properties.
function rotationListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotationListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addToRotationButton.
function addToRotationButton_Callback(hObject, eventdata, handles)
% hObject    handle to addToRotationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addRotation(handles, 0);

% --- Executes on selection change in companionCropDDL.
function companionCropDDL_Callback(hObject, eventdata, handles)
% hObject    handle to companionCropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns companionCropDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from companionCropDDL


% --- Executes during object creation, after setting all properties.
function companionCropDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to companionCropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeColourButton.
function changeColourButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
C = uisetcolor;
set(handles.timelineColourPanel, 'BackgroundColor', C);

% --- Executes on button press in updateSelectedButton.
function updateSelectedButton_Callback(hObject, eventdata, handles)
% hObject    handle to updateSelectedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addRotation(handles, 1);

% --- Executes on button press in moveUpButton.
function moveUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
moveRotation(handles, -1);

% --- Executes on button press in moveDownButton.
function moveDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
moveRotation(handles, 1);

% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
removeRotation(handles);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(gcf);

% --- Executes on button press in acceptButton.
function acceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(isempty(handles.rotationList))
    msgbox('You need to define at least one crop in the rotation');
    return
end

returnRegime(handles);

% --- Executes on selection change in startYearDDL.
function startYearDDL_Callback(hObject, eventdata, handles)
% hObject    handle to startYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns startYearDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from startYearDDL


% --- Executes during object creation, after setting all properties.
function startYearDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finalYearDDL.
function finalYearDDL_Callback(hObject, eventdata, handles)
% hObject    handle to finalYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns finalYearDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finalYearDDL


% --- Executes during object creation, after setting all properties.
function finalYearDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finalYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function regimeLabelEdit_Callback(hObject, eventdata, handles)
% hObject    handle to regimeLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of regimeLabelEdit as text
%        str2double(get(hObject,'String')) returns contents of regimeLabelEdit as a double


% --- Executes during object creation, after setting all properties.
function regimeLabelEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to regimeLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Setup the controls on init.
function setupControls(handles)

% Need to use existingCropDefinitions to pull out the relevant cropnames
% and populate the list.
ecds = handles.cropDefinitions;

anIndex = find(strcmp({ecds.categoryName}, 'Annual') | strcmp({ecds.categoryName}, 'Pasture'));
if ~isempty(anIndex)
    primaryCrops = {ecds(anIndex).name};
    primaryCropsCategories = {ecds(anIndex).categoryName};
else
    primaryCrops = {};
    primaryCropsCategories = {};
end
compIndex = strcmp({ecds.categoryName}, 'Pasture');
if ~isempty(compIndex)
    companionCrops = {ecds(compIndex).name};
else
    companionCrops = {};
end

% Save list of primary and companion crop names
handles.primaryCrops = primaryCrops;
handles.primaryCropsCategories = primaryCropsCategories;
handles.companionCrops = companionCrops;
guidata(handles.cropDDL, handles);

set(handles.cropDDL, 'String', primaryCrops);
set(handles.companionCropDDL, 'String', ['None', companionCrops])
set(handles.regimeLabelEdit, 'String', handles.regimeLabel);
set(handles.timelineColourPanel, 'BackgroundColor', handles.timelineColour);

set(handles.startYearDDL, 'Value', handles.startYear);
set(handles.finalYearDDL, 'Value', handles.finalYear);

rotationStrings = {};

for i = 1:length(handles.rotationList)
   rotationStrings{i} = rotation2str(handles.rotationList(i));     
end
set(handles.rotationListBox, 'String', rotationStrings);

if isempty(handles.rotationList)
   set(handles.defineTriggersButton, 'Enable', 'off'); 
end

setupRotationControls(handles);
listBoxSelection(handles);


function setupRotationControls(handles)
% Get the selected crop.
% If it's pasture, hide the Annual controls and show the pasture controls
% Else vice versa.

category = handles.primaryCropsCategories(get(handles.cropDDL, 'Value'));

if strcmp(category, 'Pasture')
   set(handles.annualControls, 'Visible', 'off')
   set(handles.pastureControls, 'Visible', 'on')   
else
   set(handles.annualControls, 'Visible', 'on')
   set(handles.pastureControls, 'Visible', 'off')   
end
    
    
% Add (or update) a rotation.
% If inplace is true, then we replace the currently selected rotation.
% If inplace is false (or the selected line is not a rotation) we add to
% the end of the list of rotations.
function addRotation(handles, inplace)
handles.primaryCrops
r.crop = handles.primaryCrops{get(handles.cropDDL, 'Value')};
r.plant = handles.months{get(handles.plantDDL, 'Value')};
r.harvest = handles.months{get(handles.harvestDDL, 'Value')}; 

r.category = handles.primaryCropsCategories{get(handles.cropDDL, 'Value')};
if strcmp(r.category, 'Pasture')
    r.DSE = str2double(get(handles.editDSE, 'String'));
else
    r.DSE = 0;
end
compIndex = get(handles.companionCropDDL, 'Value') - 1;
if compIndex > 0
    r.companionCrop =  handles.companionCrops{compIndex};
else
    r.companionCrop = '';
end

rotationStrings = get(handles.rotationListBox, 'String');
rNum = length(handles.rotationList);

if(inplace)
   index = get(handles.rotationListBox, 'Value');
   if(index > rNum)
       index = rNum +1;
   end
else
   index = rNum + 1;  
end

if(rNum == 0)
    handles.rotationList = r;
else
    handles.rotationList(index) = r;
end
rotationStrings{index} = rotation2str(r);
set(handles.rotationListBox, 'String', rotationStrings);

if ~isempty(handles.rotationList)
   set(handles.defineTriggersButton, 'Enable', 'on'); 
end

guidata(handles.cropDDL, handles);

% removes the selected rotation
function removeRotation(handles)

rotationStrings = get(handles.rotationListBox, 'String');
rNum = length(handles.rotationList);

index = get(handles.rotationListBox, 'Value');
if(index > rNum)
   return
else
   handles.rotationList = [handles.rotationList(1:index - 1), handles.rotationList(index + 1:end)];
   rotationStrings = {rotationStrings{1:index - 1} ,rotationStrings{index + 1:end}};
   set(handles.rotationListBox, 'String', rotationStrings);
   if(index == rNum && rNum > 1)
       set(handles.rotationListBox, 'Value', rNum - 1);
   end
   guidata(handles.cropDDL, handles);
end

if isempty(handles.rotationList)
   set(handles.defineTriggersButton, 'Enable', 'off'); 
end


% Runs the code for listbox execution
% Loads the selected rotations' options into the DDLs
% If the selection is out of range, it selects the last item, and loads
% that.
function listBoxSelection(handles)

if(isempty(handles.rotationList))
    set(handles.rotationListBox, 'Value', 1);
    return
end

index = get(handles.rotationListBox, 'Value');

if(index > length(handles.rotationList))
    index = length(handles.rotationList);
    set(handles.rotationListBox, 'Value', index);
end

r = handles.rotationList(index);

set(handles.cropDDL, 'Value', find(strcmp(r.crop, handles.primaryCrops), 1, 'first'));

setupRotationControls(handles);

set(handles.plantDDL, 'Value', find(strcmp(r.plant, handles.months), 1, 'first'));
set(handles.harvestDDL, 'Value', find(strcmp(r.harvest, handles.months), 1, 'first'));
if ~isempty(handles.companionCrops)
    set(handles.companionCropDDL, 'Value', find(strcmp(r.companionCrop, handles.companionCrops), 1, 'first'));
end

set(handles.editDSE, 'String', num2str(r.DSE));


% moveRotation moves the currently selected rotation up or down the list.
% It remains selected. 
% Moves item up if theMove is negative, and down if theMove is positive.
function moveRotation(handles, theMove)

rotationStrings = get(handles.rotationListBox, 'String');
rNum = length(handles.rotationList);

index = get(handles.rotationListBox, 'Value');

if(isempty(index))
    return
elseif(index == 0 || rNum == 0)
    return
end

if(index > rNum)
    index = length(handles.rotationList);
    set(handles.rotationListBox, 'Value', index); 
end

if(theMove > 0)
% move down
    if(index == rNum)
        return
    end
    handles.rotationList(index:index+1) = handles.rotationList(index+1:-1:index);
    rotationStrings(index:index+1) = rotationStrings(index+1:-1:index);
elseif(theMove < 0)
    % move up
    if(index == 1)
        return
    end    
    handles.rotationList(index-1:index) = handles.rotationList(index:-1:index-1);    
    rotationStrings(index-1:index) = rotationStrings(index:-1:index-1); 
end

set(handles.rotationListBox, 'String', rotationStrings);
set(handles.rotationListBox, 'Value', min(rNum,max(1,index + sign(theMove))));

guidata(handles.cropDDL, handles);

% sets regimeData to be the regime defined by this dialog.
function returnRegime(handles)

rd.regimeLabel = get(handles.regimeLabelEdit, 'String');
rd.startYear = get(handles.startYearDDL, 'Value');
rd.finalYear = get(handles.finalYearDDL, 'Value');
rd.timelineColour = get(handles.timelineColourPanel, 'BackgroundColor');
rd.type = 'Annual';
rd.rotationList = handles.rotationList;
rd.listOfCropNames = [{rd.rotationList.crop}, {rd.rotationList.companionCrop}];
rd.listOfCropNames = rd.listOfCropNames(~strcmp(rd.listOfCropNames, 'None'));

problems = 0;
mstring = {};

thisRegimeIndex = find(strcmp(handles.regimeLabel, handles.regimeDefinitions), 1, 'first');
otherRegimeDefinitions = [handles.regimeDefinitions(1:thisRegimeIndex-1) handles.regimeDefinitions(thisRegimeIndex+1:end)];
handles.regimeYears = [[otherRegimeDefinitions.startYear]; [otherRegimeDefinitions.finalYear]];

if(rd.startYear > rd.finalYear)
    problems = problems + 1;
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''re trying to set the final year to be earlier than the start year.'}];
           
elseif(any(any(handles.regimeYears >= rd.startYear & handles.regimeYears <= rd.finalYear)))

    problems = problems + 1;
    
    % Then the years overlap.
    
    % Get strings for the existing years
    rangeStrings = {};
    for i = 1:size(handles.regimeYears, 2)
       rangeStrings{i} = [num2str(handles.regimeYears(1, i)), ' - ', num2str(handles.regimeYears(2, i))];
    end
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''ve selected a range of years that overlap existing regimes.', '', ...
               'Your range is ', '', [num2str(rd.startYear), ' - ', num2str(rd.finalYear), '.'], '', ...
               'The existing regimes range over the following years:', '', ...
               char(rangeStrings), ...
               '', 'Please select a range that doesn''t conflict with these years.'}];
end

handles.existingRegimeLabels = {handles.regimeDefinitions.regimeLabel};

if(any(strcmp(handles.existingRegimeLabels, rd.regimeLabel)) && ~strcmp(rd.regimeLabel, handles.regimeLabel))
    problems = problems + 1;
    
    if(problems > 1)
       mstring = [mstring, {'', ''}];
    end
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''ve chosen a regime label that already exists. Please choose a label that is different to all in the list below:', '', ...
               char(handles.existingRegimeLabels)}];
end

if(problems > 0)
    warndlg(mstring, 'Problems with Regime');
    return
end

% If no problems, save the data as events:
createAnnualRegimeEvents(handles);
handles = guidata(handles.acceptButton);

rd.cropEventTriggers = handles.cropEventTriggers;

handles = guidata(handles.acceptButton);
handles.output = rd;

guidata(handles.acceptButton, handles);

uiresume(gcf);


% --- Executes on button press in defineTriggersButton.
function defineTriggersButton_Callback(hObject, eventdata, handles)
% hObject    handle to defineTriggersButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Pass the trigger dialog the cropEventTriggers structure which should
% contain exactly the information that the trigger dialog needs and
% affects.
createAnnualRegimeEvents(handles);
handles = guidata(hObject);

cropEventTriggers = handles.cropEventTriggers;

% In order for the trigger dialog to work with the trigger panel, we'll
% convert the RegimeEventTriggers into Events and pass them across.
cropMgr = CropManager.getInstance;

disp(['Making cropEvents for regime trigger dialog... ']);

for i = 1:length(cropEventTriggers)
    cropEvents = cropMgr.getCropsEvents(cropEventTriggers(i).cropName);
    newCropEvents(i).cropName = handles.cropEventTriggers(i).cropName; %#ok<AGROW>
    
    disp(['Crop name: ', newCropEvents(i).cropName]);
    
    for j = 1:length(cropEvents)
        status = cropEvents(j).status;
        newCropEvents(i).events(j) = cropEventTriggers(i).eventTriggers(j).convertToEvent(status); %#ok<AGROW>
        disp(['   Event name: ', newCropEvents(i).events(j).name]);
        
                   
        for k = 1:length(cropEventTriggers(i).eventTriggers(j).trigger.conditions)
            disp(['      Condition: ', newCropEvents(i).events(j).trigger.conditions{k}.shorthand, ', type: ', newCropEvents(i).events(j).trigger.conditions{k}.conditionType]);
        end
    end
end

newCropEvents = triggerDialog(newCropEvents);

if isempty(newCropEvents)
    return
else
    disp('Saving regime cropEventTriggers');
    
    for i = 1:length(newCropEvents)
       % The crop names should match..
       if ~strcmp(newCropEvents(i).cropName, cropEventTriggers(i).cropName) 
           error('We got back a cropEvents struct that doesn''t match what we sent.');
       end
       
       disp(['Crop name: ', newCropEvents(i).cropName]);
       
       % Assuming the crops match, retrieve the regime trigger data.
       for j = 1:length(newCropEvents(i).events)
           newTrigger = cropEventTriggers(i).eventTriggers(j).convertFromEvent(newCropEvents(i).events(j));
           cropEventTriggers(i).eventTriggers(j) = newTrigger;
           disp(['   Event name: ', cropEventTriggers(i).eventTriggers(j).eventName]);
           
           for k = 1:length(cropEventTriggers(i).eventTriggers(j).trigger.conditions)
                disp(['      Condition: ', cropEventTriggers(i).eventTriggers(j).trigger.conditions{k}.shorthand, ', type: ', cropEventTriggers(i).eventTriggers(j).trigger.conditions{k}.conditionType]);
           end
           
       end
    end
    handles.cropEventTriggers = cropEventTriggers;
end

guidata(hObject, handles);



%createAnnualRegimeEvents
%
% makes the cropEventTriggers list contain entries for the core events in the
% crop. Sets planting and harvesting events for all crops used.
function createAnnualRegimeEvents(handles)

handles.startYear = get(handles.startYearDDL, 'Value');
handles.finalYear = get(handles.finalYearDDL, 'Value');

handles = AnnualRegimeDelegate.createAnnualRegimeEvents(handles);

% % Get list of crops used in regime.
% % Will need to set planting and harvesting events for them.
% 
% rotationCropNames = {handles.rotationList.crop};
% usedCropNames = unique(rotationCropNames);
% rotLength = length(handles.rotationList);
% startYear = get(handles.startYearDDL, 'Value');
% finalYear = get(handles.finalYearDDL, 'Value');
% regimeLength = finalYear - startYear + 1;
% 
% disp('creatingAnnualRegimeEvents');
% 
% if ~isempty(handles.cropEventTriggers)
%     % Removes the cropEventTriggers for crops we're not using in the regime
%     % any more.
%     handles.cropEventTriggers = handles.cropEventTriggers(ismember({handles.cropEventTriggers.cropName}, usedCropNames));
% end
% 
% for i = 1:length(usedCropNames)
% 
%     cropName = usedCropNames{i};
%     
%     % Make sure that cropEventTriggers has an element for our crop.
%     % Get it's index in the array and make it cropIndex.
%     % Hereafter we can assume handles.cropEventTriggers(cropIndex) will
%     % give us the struct with cropName and an array of eventTriggers in it.
%     
%     if isempty(handles.cropEventTriggers)
%         cropIndex = [];
%     else
%         cropIndex = find(strcmp({handles.cropEventTriggers.cropName}, cropName));
%     end
%     
%     if isempty(cropIndex)
%         % If we don't yet have events for the crop, we should load them
%         % from the crop.
%         % But what if the crop changes? Perhaps we should load the events from the crop here every time
%         % but overwrite the crop's event with the regimes event data if it exists, and then, only some fields. 
%         % It should definitely be the crop's growthmodel events and
%         % financial events that are used, not the category's events.
%          
%         % add the events for the crop by accessing the cropManager.
%         
%         cet.cropName = cropName;
%         cropMgr = CropManager.getInstance;
%         cropEvents = cropMgr.getCropsEvents(cropName);
%         
%         % create the eventTriggers, a struct array with eventName, trigger.
%         for k = 1:length(cropEvents)
%             ets(k) = RegimeEventTrigger(cropEvents(k).name, cropEvents(k).trigger, cropEvents(k).status.regimeRedefinable); %#ok<AGROW>
%             dET = ets(k);
%         end
%         cet.eventTriggers = ets;
%         cropIndex = length(handles.cropEventTriggers)+1;
%        
%         handles.cropEventTriggers(cropIndex) = cet;
%                 
%     end
% 
%     rotationAppearances = strcmp(rotationCropNames, cropName);
% 
%     % We'll need rotationAppearances x3 conditions + 1 to get it all done.
%     % (Unless theres only one appearance.)
%     plantConditions = {};
%     harvestConditions = {};
%            
%     for j = 1:sum(rotationAppearances)
% 
%         % Conditions
%         % 1. Month is
%         % 2. Year index
%         % 3. And 1, 2
% 
%         % Get planting month, harvest month, rotation index.
%         rotIndex = find(cumsum(rotationAppearances) .* rotationAppearances == j);
%         
%         rot = handles.rotationList(rotIndex);
%         if strcmp(rot.category, 'Pasture')
%             rot.plant = 'Jan';
%             rot.harvest = 'Dec';
%         end
%         
%         c1 = ImagineCondition.newCondition('Month Based', ['Month is ', rot.plant]);
%         ix = find(strcmp(c1.monthStrings, rot.plant));
%         c1.monthIndex = ix;
%         
% %         c1.string1 = '';
% %         c1.value1 = 1;
% %         c1.stringComp = 'Month is';
% %         c1.valueComp = 1;
% %         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
% %         c1.value2 = find(strcmp(c1.string2, rot.plant));
% %         c1.parameters1String = '';
% %         c1.parameters2String = '';
%         
%         c1B = ImagineCondition.newCondition('Month Based', ['Month is ', rot.harvest]);
%         ix = find(strcmp(c1B.monthStrings, rot.harvest));
%         c1B.monthIndex = ix;
%         
% %         c1B.string1 = '';
% %         c1B.value1 = 1;
% %         c1B.stringComp = 'Month is';
% %         c1B.valueComp = 1;
% %         c1B.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
% %         c1B.value2 = find(strcmp(c1B.string2, rot.harvest));
% %         c1B.parameters1String = '';
% %         c1B.parameters2String = '';
% 
%         c2 = ImagineCondition.newCondition('Time Index Based', [number2placing(rotIndex) , ' year then every ', number2placing(rotLength) , ' year.']);
%         c2.indexType = 'Year';
%         c2.indices = (rotIndex + startYear - 1):rotLength:finalYear;
%         
% %         c2.string1 = {'Year', 'Month'};
% %         c2.value1 = 1;
% %         c2.stringComp = {'=', '<', '>', '<=', '>='};
% %         c2.valueComp = 1;
% %         c2.string2 = [num2str(rotIndex + startYear - 1), ':', num2str(rotLength), ':', num2str(finalYear)];
% %         c2.value2 = 1;       
% %         c2.parameters1String = '';
% %         c2.parameters2String = '';
%         
%         c3 = ImagineCondition.newCondition('And / Or / Not', ['C', num2str(j*3 - 2), ' AND C', num2str(j*3 - 1)]);
%         c3.indices = [(j*3 - 2), (j*3 - 1)];
%         c3.logicType = 'And';
%         
% %         c3.string1 = {'AND', 'OR', 'NOT'};
% %         c3.value1 = 1;
% %         c3.stringComp = '';
% %         c3.valueComp = 1;
% %         c3.string2 = [num2str(j*3 - 2), ' ', num2str(j*3 - 1)];
% %         c3.value2 = 1;       
% %         c3.parameters1String = '';
% %         c3.parameters2String = '';
% 
%         if isempty(plantConditions)
%             plantConditions = {c1 c2 c3};
%             harvestConditions = {c1B, c2, c3};
%         else
%             plantConditions(j*3-2:j*3) = {c1, c2, c3};
%             harvestConditions(j*3-2:j*3) = {c1B, c2, c3};    
%         end
%     end
% 
%     if length(plantConditions) > 3
%         
%         cAll = ImagineCondition.newCondition('AND / OR / NOT', ['Any of these conditions: ', num2str(3*1:sum(rotationAppearances))]);
%         cAll.logicType = 'Or';
%         cAll.indices = cumsum(rotationAppearances) .* 3;
%         cAll.indices = cAll.indices(rotationAppearances);
%         
% %         cAll.string1 = {'AND', 'OR', 'NOT'};
% %         cAll.value1 = 2;
% %         cAll.stringComp = '';
% %         cAll.valueComp = 1;
% %         cAll.string2 = cumsum(rotationAppearances) .* 3;
% %         cAll.string2 = cAll.string2(rotationAppearances);
% %         cAll.string2 = num2str(cAll.string2);
% %         cAll.value2 = 1;       
% %         cAll.parameters1String = '';
% %         cAll.parameters2String = '';
%         
%         harvestConditions{j*3+1} = cAll;       
%         plantConditions{j*3+1} = cAll;
%     end
% 
%     % Set the triggers to the conditions.
%     
%     plantTrigger = Trigger;
%     plantTrigger.conditions = plantConditions;
%     if strcmp(rot.category, 'Pasture')
%         plantIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Establishment'));
%     else        
%         plantIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Planting'));
%     end
%     
%     ret = handles.cropEventTriggers(cropIndex).eventTriggers(plantIx);
%     ret = ret.setPrivateTrigger(plantTrigger);
%     handles.cropEventTriggers(cropIndex).eventTriggers(plantIx) = ret;
% 
%     harvestTrigger = Trigger;
%     harvestTrigger.conditions = harvestConditions;
%     
%     if strcmp(rot.category, 'Pasture')
%         harvestIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Destruction'));
%     else        
%         harvestIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Harvesting'));
%     end
%     ret = handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx);
%     ret = ret.setPrivateTrigger(harvestTrigger);
%     handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx) = ret; 
% 
%     for j = 1:length(handles.cropEventTriggers(cropIndex).eventTriggers)
%         for k = 1:length(handles.cropEventTriggers(cropIndex).eventTriggers(j).trigger.conditions)
%             cond = handles.cropEventTriggers(cropIndex).eventTriggers(j).trigger.conditions{k};
%             disp(['  Condition: ',  cond.shorthand, ', type: ', cond.conditionType]);
%         end
%     end
%     
% end
% 

% Save the cropEventTriggers
guidata(handles.defineTriggersButton, handles);



function editDSE_Callback(hObject, eventdata, handles)
% hObject    handle to editDSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDSE as text
%        str2double(get(hObject,'String')) returns contents of editDSE as a double




% --- Executes during object creation, after setting all properties.
function editDSE_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
