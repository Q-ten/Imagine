function varargout = SpatialInteractionsForPastureDialog(varargin)
% SPATIALINTERACTIONSFORPASTUREDIALOG M-file for SpatialInteractionsForPastureDialog.fig
%      SPATIALINTERACTIONSFORPASTUREDIALOG, by itself, creates a new SPATIALINTERACTIONSFORPASTUREDIALOG or raises the existing
%      singleton*.
%
%      H = SPATIALINTERACTIONSFORPASTUREDIALOG returns the handle to a new SPATIALINTERACTIONSFORPASTUREDIALOG or the handle to
%      the existing singleton*.
%
%      SPATIALINTERACTIONSFORPASTUREDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPATIALINTERACTIONSFORPASTUREDIALOG.M with the given input arguments.
%
%      SPATIALINTERACTIONSFORPASTUREDIALOG('Property','Value',...) creates a new SPATIALINTERACTIONSFORPASTUREDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpatialInteractionsForPastureDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpatialInteractionsForPastureDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpatialInteractionsForPastureDialog

% Last Modified by GUIDE v2.5 13-Jun-2014 15:01:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpatialInteractionsForPastureDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @SpatialInteractionsForPastureDialog_OutputFcn, ...
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


% --- Executes just before SpatialInteractionsForPastureDialog is made visible.
function SpatialInteractionsForPastureDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpatialInteractionsForPastureDialog (see VARARGIN)

% Set up default values.
handles.useCompetition = true;

handles.rootDensity = 0.2;
handles.relativeRadii = 0.4;

%handles.compReachFactor = 2;
handles.compYieldFactor = 2;
handles.compZeroImpactRainfall = 700;
handles.compMaxRainfallForFullImpact = 500;

handles.useWaterlogging = false;
%handles.waterReachFactor = 2;
handles.waterYieldFactor = 2;
handles.waterZeroImpactRainfall = 400;
handles.waterMinRainfallForFullImpact = 700;

handles.useNCZ = false;
handles.NCZChoice = 'Fixed Width';
handles.NCZFixedWidth = 0;
handles.NCZOptimisedParameters = NCZOptimisedParameters.empty(1, 0);

handles.notes = {};

handles.sisIn = SpatialInteractions.empty(1, 0);

% Need to pass in cropInfo so we can use the crop name and may also need to
% pass on cropInfo to the NCZOptimisedParametersDialog.
if nargin < 4
    handles.cropInfo.cropName = 'Test Crop';
    handles.cropInfo.cropYieldUnits = 't / Ha';
%   error('Must pass at least one argument to the NCZOptimisedParametersDialog. The first argument should have fields for cropName and cropYieldUnits.');
else
   handles.cropInfo = varargin{1};
end

if (nargin >= 5)
    sis = varargin{2};
    if ~isempty(sis)
        sisParList = {'useCompetition', 'compYieldFactor', 'compZeroImpactRainfall', 'compMaxRainfallForFullImpact', ...
                      'useWaterlogging', 'waterYieldFactor', 'waterZeroImpactRainfall', 'waterMinRainfallForFullImpact', ...
                      'useNCZ', 'NCZChoice', 'NCZFixedWidth', 'NCZOptimisedParameters', 'notes', 'rootDensity', 'relativeRadii'};

        fieldNamesIn = fieldnames(sis);
        for i = 1:length(sisParList)
           ix = find(strcmp(fieldNamesIn, sisParList{i}), 1, 'first');
           if ~isempty(ix)
               if ~isempty(sis.(sisParList{i}))
                   % Then overwrite the default parameters with what is provided in
                   % the input argument.
                   handles.(sisParList{i}) = sis.(sisParList{i});
               end
            end
        end
    end
    handles.sisIn = sis;
end

% Set up the AGBM, BGBM, rainfall and NCZ GUI parameters.
handles.AGBM = 60;
handles.BGBM = 30;
handles.rainfall = 450;
handles.plantSpacing = 2;

handles.AGBMMin = 0;
handles.AGBMMax = 200;
handles.BGBMMin = 0;
handles.BGBMMax = 100;
handles.rainfallMin = 0;
handles.rainfallMax = 1000;
handles.NCZFixedWidthMin = 0;
handles.NCZFixedWidthMax = 20;

% Setup test area now to establish the axes handles like lines etc, before
% other callbacks are called that may inadvertantly duplicate these
% handles.
handles.compColour = [255, 170, 0]/255;
handles.waterColour = [0, 0, 255]/255;
guidata(hObject, handles);

updateTestArea(handles);
handles = guidata(hObject);

% Choose default command line output for SpatialInteractionsForPastureDialog
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

setupControls(handles);

% UIWAIT makes SpatialInteractionsForPastureDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SpatialInteractionsForPastureDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%assignin('base', 'h', handles);
if isfield(handles, 'cancelled')
    sisOut = SpatialInteractions.empty(1, 0);
else
    sisOut = getSIS(handles);    
end

varargout{1} = sisOut;

delete(handles.figure1);


function sisOut = getSIS(handles)

if isempty(handles.sisIn) || ~strcmp(class(handles.sisIn), 'SpatialInteractions')
    sisOut = SpatialInteractions();
else
    sisOut = handles.sisIn;
end

sisParList = {'useCompetition', 'compYieldFactor', 'compZeroImpactRainfall', 'compMaxRainfallForFullImpact', ...
              'useWaterlogging', 'waterYieldFactor', 'waterZeroImpactRainfall', 'waterMinRainfallForFullImpact', ...
              'useNCZ', 'NCZChoice', 'NCZFixedWidth', 'NCZOptimisedParameters', 'notes', 'rootDensity', 'relativeRadii'};

fieldNamesIn = fieldnames(sisOut);
for i = 1:length(sisParList)
    ix = find(strcmp(fieldNamesIn, sisParList{i}), 1, 'first');
    if ~isempty(ix)
       % Then overwrite the default parameters with what is provided in
       % the handles struct.
       sisOut.(sisParList{i}) = handles.(sisParList{i});
    end
end


function handles = useSIS(handles, sis)

if ~isempty(sis) && ~isempty(handles)
sisParList = {'useCompetition', 'compYieldFactor', 'compZeroImpactRainfall', 'compMaxRainfallForFullImpact', ...
              'useWaterlogging', 'waterYieldFactor', 'waterZeroImpactRainfall', 'waterMinRainfallForFullImpact', ...
              'useNCZ', 'NCZChoice', 'NCZFixedWidth', 'NCZOptimisedParameters', 'notes', 'rootDensity', 'relativeRadii'};

    fieldNamesIn = fieldnames(sis);
    for i = 1:length(sisParList)
       ix = find(strcmp(fieldNamesIn, sisParList{i}), 1, 'first');
       if ~isempty(ix)
           if ~isempty(sis.(sisParList{i}))
               % Then overwrite the default parameters with what is provided in
               % the input argument.
               handles.(sisParList{i}) = sis.(sisParList{i});
           end
        end
    end
    handles.sisIn = sis;
else
    error('Must pass the handles struct and a struct containing the fields of a SIS.');
end



function editAGBM_Callback(hObject, eventdata, handles)
% hObject    handle to editAGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAGBM as text
%        str2double(get(hObject,'String')) returns contents of editAGBM as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > handles.AGBMMax
        handles.AGBM = handles.AGBMMax;
    elseif newNum < handles.AGBMMin
        handles.AGBM = handles.AGBMMin;
    else
        handles.AGBM = newNum;   
    end
    guidata(hObject, handles);
    setAGBMControls(handles); 
    reset = true;
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.AGBM));
end



% --- Executes during object creation, after setting all properties.
function editAGBM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editBGBM_Callback(hObject, eventdata, handles)
% hObject    handle to editBGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editBGBM as text
%        str2double(get(hObject,'String')) returns contents of editBGBM as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > handles.BGBMMax
        handles.BGBM = handles.BGBMMax;
    elseif newNum < handles.BGBMMin
        handles.BGBM = handles.BGBMMin;
    else
        handles.BGBM = newNum;
    end
    guidata(hObject, handles);
    setBGBMControls(handles);
    reset = true;
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.BGBM));
end

% --- Executes during object creation, after setting all properties.
function editBGBM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRainfall_Callback(hObject, eventdata, handles)
% hObject    handle to editRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRainfall as text
%        str2double(get(hObject,'String')) returns contents of editRainfall as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)        
    if newNum > handles.rainfallMax
        handles.rainfall = handles.rainfallMax;
    elseif newNum < handles.rainfallMin
        handles.rainfall = handles.rainfallMin;
    else
        handles.rainfall = newNum;
    end
    guidata(hObject, handles);
    setRainfallControls(handles);
    reset = true;  
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.rainfall));
end

% --- Executes during object creation, after setting all properties.
function editRainfall_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderAGBM_Callback(hObject, eventdata, handles)
% hObject    handle to sliderAGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.AGBM = floor(get(hObject, 'Value'));
guidata(hObject, handles);
setAGBMControls(handles);

% --- Executes during object creation, after setting all properties.
function sliderAGBM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderAGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderBGBM_Callback(hObject, eventdata, handles)
% hObject    handle to sliderBGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.BGBM = floor(get(hObject, 'Value'));
guidata(hObject, handles);
setBGBMControls(handles);


% --- Executes during object creation, after setting all properties.
function sliderBGBM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderBGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderRainfall_Callback(hObject, eventdata, handles)
% hObject    handle to sliderRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.rainfall = floor(get(hObject, 'Value'));
guidata(hObject, handles);
setRainfallControls(handles);


% --- Executes during object creation, after setting all properties.
function sliderRainfall_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in checkboxUseWaterlogging.
function checkboxUseWaterlogging_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseWaterlogging (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseWaterlogging
handles.useWaterlogging = get(hObject, 'Value');
guidata(hObject, handles);
if handles.useWaterlogging
    enabledString = 'on';
else
    enabledString = 'off';    
end

% Enable or disable controls based on the value.
set([handles.editWaterYieldFactor, ...
     handles.editWaterZeroImpactRainfall, handles.editWaterMinRainfallForFullImpact], 'Enable', enabledString);

% May need to update the test area based on whether the competition is on or not. 
updateTestArea(handles);

function editWaterYieldFactor_Callback(hObject, eventdata, handles)
% hObject    handle to editWaterYieldFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWaterYieldFactor as text
%        str2double(get(hObject,'String')) returns contents of editWaterYieldFactor as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.waterYieldFactor = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.waterYieldFactor));
end

% --- Executes during object creation, after setting all properties.
function editWaterYieldFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWaterYieldFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWaterZeroImpactRainfall_Callback(hObject, eventdata, handles)
% hObject    handle to editWaterZeroImpactRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWaterZeroImpactRainfall as text
%        str2double(get(hObject,'String')) returns contents of editWaterZeroImpactRainfall as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.waterZeroImpactRainfall = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.waterZeroImpactRainfall));
end

% --- Executes during object creation, after setting all properties.
function editWaterZeroImpactRainfall_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWaterZeroImpactRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWaterMinRainfallForFullImpact_Callback(hObject, eventdata, handles)
% hObject    handle to editWaterMinRainfallForFullImpact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWaterMinRainfallForFullImpact as text
%        str2double(get(hObject,'String')) returns contents of editWaterMinRainfallForFullImpact as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.waterMinRainfallForFullImpact = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.waterMinRainfallForFullImpact));
end

% --- Executes during object creation, after setting all properties.
function editWaterMinRainfallForFullImpact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWaterMinRainfallForFullImpact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxUseCompetition.
function checkboxUseCompetition_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseCompetition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseCompetition
handles.useCompetition = get(hObject, 'Value');
guidata(hObject, handles);
if handles.useCompetition
    enabledString = 'on';
else
    enabledString = 'off';    
end

% Enable or disable controls based on the value.
set([handles.editCompYieldFactor, ...
     handles.editCompZeroImpactRainfall, handles.editCompMaxRainfallForFullImpact], 'Enable', enabledString);

% May need to update the test area based on whether the competition is on or not. 
updateTestArea(handles);
 

function editCompYieldFactor_Callback(hObject, eventdata, handles)
% hObject    handle to editCompYieldFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCompYieldFactor as text
%        str2double(get(hObject,'String')) returns contents of editCompYieldFactor as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.compYieldFactor = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.compYieldFactor));
end

% --- Executes during object creation, after setting all properties.
function editCompYieldFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCompYieldFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCompZeroImpactRainfall_Callback(hObject, eventdata, handles)
% hObject    handle to editCompZeroImpactRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCompZeroImpactRainfall as text
%        str2double(get(hObject,'String')) returns contents of editCompZeroImpactRainfall as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.compZeroImpactRainfall = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.compZeroImpactRainfall));
end

% --- Executes during object creation, after setting all properties.
function editCompZeroImpactRainfall_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCompZeroImpactRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCompMaxRainfallForFullImpact_Callback(hObject, eventdata, handles)
% hObject    handle to editCompMaxRainfallForFullImpact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCompMaxRainfallForFullImpact as text
%        str2double(get(hObject,'String')) returns contents of editCompMaxRainfallForFullImpact as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.compMaxRainfallForFullImpact = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.compMaxRainfallForFullImpact));
end

% --- Executes during object creation, after setting all properties.
function editCompMaxRainfallForFullImpact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCompMaxRainfallForFullImpact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Sets up the controls on start. handles should contain fully defined and
% valid controls.
function setupControls(handles)

enableDisableFig(handles.figure1, 'off');

% set up legend axes
axes(handles.axesCompLegend);
axis([ 0, 1, 0 1]);
line([0.1,0.9], [0.5 ,0.5], [0, 0], 'Color', handles.compColour, 'LineWidth', 2);

axes(handles.axesWaterLegend);
axis([ 0, 1, 0 1]);
line([0.1,0.9], [0.5 ,0.5], [0, 0], 'Color', handles.waterColour, 'LineWidth', 2);


set(handles.textCropName, 'String', handles.cropInfo.cropName);

set(handles.editRootDensity, 'String', num2str(handles.rootDensity));
set(handles.editRelativeRadii, 'String', num2str(handles.relativeRadii));

set(handles.checkboxUseCompetition, 'Value', handles.useCompetition);
%set(handles.editCompReachFactor, 'String', num2str(handles.compReachFactor));
set(handles.editCompYieldFactor, 'String', num2str(handles.compYieldFactor));
set(handles.editCompMaxRainfallForFullImpact, 'String', num2str(handles.compMaxRainfallForFullImpact));
set(handles.editCompZeroImpactRainfall, 'String', num2str(handles.compZeroImpactRainfall));

set(handles.checkboxUseWaterlogging, 'Value', handles.useWaterlogging);
%set(handles.editWaterReachFactor, 'String', num2str(handles.waterReachFactor));
set(handles.editWaterYieldFactor, 'String', num2str(handles.waterYieldFactor));
set(handles.editWaterMinRainfallForFullImpact, 'String', num2str(handles.waterMinRainfallForFullImpact));
set(handles.editWaterZeroImpactRainfall, 'String', num2str(handles.waterZeroImpactRainfall));


checkboxUseCompetition_Callback(handles.checkboxUseCompetition, [], handles);
handles = guidata(handles.checkboxUseCompetition);
checkboxUseWaterlogging_Callback(handles.checkboxUseWaterlogging, [], handles);
handles = guidata(handles.checkboxUseCompetition);


set(handles.(['radiobuttonSpacing', num2str(handles.plantSpacing)]), 'Value', 1);
set(handles.textAGBMPerM, 'String', [num2str(handles.AGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);
set(handles.textBGBMPerM, 'String', [num2str(handles.BGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);

set(handles.sliderAGBM, 'Min', handles.AGBMMin);
set(handles.sliderAGBM, 'Max', handles.AGBMMax);
set(handles.sliderBGBM, 'Min', handles.BGBMMin);
set(handles.sliderBGBM, 'Max', handles.BGBMMax);
set(handles.sliderRainfall, 'Min', handles.rainfallMin);
set(handles.sliderRainfall, 'Max', handles.rainfallMax);

% Create tooltips to indicate the set ranges.
handles.AGBMTooltip = ['Above-ground biomass range: [', num2str(handles.AGBMMin), ', ', num2str(handles.AGBMMax), ']'];
handles.BGBMTooltip = ['Below-ground biomass range: [', num2str(handles.BGBMMin), ', ', num2str(handles.BGBMMax), ']'];
handles.rainfallTooltip = ['Rainfall range: [', num2str(handles.rainfallMin), ', ', num2str(handles.rainfallMax), ']'];

set([handles.textAGBM, handles.editAGBM, handles.sliderAGBM], 'TooltipString', handles.AGBMTooltip);
set([handles.textBGBM, handles.editBGBM, handles.sliderBGBM], 'TooltipString', handles.BGBMTooltip);
set([handles.textRainfall, handles.editRainfall, handles.sliderRainfall], 'TooltipString', handles.rainfallTooltip);

setAGBMControls(handles);
setBGBMControls(handles);
setRainfallControls(handles);

% Set up the rainfall impact axes
set(handles.axesRainfallImpact, 'XTick', [0:200:1000]);
set(handles.axesRainfallImpact, 'XTickLabel', {'0', '200', '400', '600', '800', '1000'});
set(handles.axesRainfallImpact, 'YTick', [0:50:100]);
set(handles.axesRainfallImpact, 'YTickLabel', {'0%', '50%', '100%'});
axes(handles.axesRainfallImpact);
xlabel('Growing Season Rainfall (mm)');
ylabel('');
title('Degree of Impact of Competition and Waterlogging Based on GSR');

axes(handles.axesYieldRepresentation);
xlabel('Distance into Alley from Stem (m)');
ylabel('Yield Change (%)');
title(['Effect of competition and waterlogging for ', num2str(handles.rainfall), ' mm GSR']);

updateTestArea(handles);


enableDisableFig(handles.figure1, 'on');


function setAGBMControls(handles)
% sets both the edit and the slider.
set(handles.editAGBM, 'String', num2str(handles.AGBM));
set(handles.sliderAGBM, 'Value', handles.AGBM);
set(handles.textAGBMPerM, 'String', [num2str(handles.AGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);
updateTestArea(handles);

function setBGBMControls(handles)
% sets both the edit and the slider.
set(handles.editBGBM, 'String', num2str(handles.BGBM));
set(handles.sliderBGBM, 'Value', handles.BGBM);
set(handles.textBGBMPerM, 'String', [num2str(handles.BGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);
updateTestArea(handles);

function setRainfallControls(handles)
% sets both the edit and the slider.
set(handles.editRainfall, 'String', num2str(handles.rainfall));
set(handles.sliderRainfall, 'Value', handles.rainfall);
updateTestArea(handles);


% Refreshes the test area display.
function updateTestArea(handles)
hold on

handles.AGBMPerM = handles.AGBM / handles.plantSpacing;
handles.BGBMPerM = handles.BGBM / handles.plantSpacing;

% setup rainfall impact first.
if isfield(handles, 'compRainImpactLines')
    compRainImpactLines = handles.compRainImpactLines;
else
    axes(handles.axesRainfallImpact);
    compRainImpactLines = line([0,0, 0], [0,0, 0], [0, 0, 0], 'Color',  handles.compColour, 'LineWidth', 2);
end

if isfield(handles, 'waterRainImpactLines')
    waterRainImpactLines = handles.waterRainImpactLines;
else
    axes(handles.axesRainfallImpact);
    waterRainImpactLines = line([0,0, 0], [0,0, 0], [0, 0, 0], 'Color', handles.waterColour, 'LineWidth', 2);
end

if isfield(handles, 'rainMeterImpactLines')
    rainMeterImpactLines = handles.rainMeterImpactLines;
else
    axes(handles.axesRainfallImpact);
    rainMeterImpactLines = line([0,0], [0,150], [0, 0], 'Color', [255, 0, 0]/255, 'LineWidth', 2);
end

axes(handles.axesRainfallImpact);
assignin('base', 'handles', handles);
if(handles.useWaterlogging)
   set(waterRainImpactLines, 'XData', [handles.waterZeroImpactRainfall, handles.waterMinRainfallForFullImpact, 1000]);
   set(waterRainImpactLines, 'YData', [0, 100, 100]);
   set(waterRainImpactLines, 'Visible', 'on');
 else
   set(waterRainImpactLines, 'XData', [0,0,0]);     
   set(waterRainImpactLines, 'YData', [0, 0, 0]);
   set(waterRainImpactLines, 'Visible', 'off');
end

if(handles.useCompetition)
   set(compRainImpactLines, 'XData', [0, handles.compMaxRainfallForFullImpact, handles.compZeroImpactRainfall]);
   set(compRainImpactLines, 'YData', [100, 100, 0]);
   set(compRainImpactLines, 'Visible', 'on');
else
   set(compRainImpactLines, 'XData', [0,0,0]);     
   set(compRainImpactLines, 'YData', [0, 0, 0]);
   set(compRainImpactLines, 'Visible', 'off');
end

% Draw the rainfall meter.
set(rainMeterImpactLines, 'XData', handles.rainfall*[1, 1]);

axis([0 1000, 0, 120]);


% Now set up for yield 
axes(handles.axesYieldRepresentation);
hold on
if isfield(handles, 'compYieldImpactLines')
    compYieldImpactLines = handles.compYieldImpactLines; 
else
    compYieldImpactLines = line([0, 0, 0], [0, 0, 0], [0, 0, 0], 'Color',  handles.compColour, 'LineWidth', 1, 'LineStyle', '--');
end
if isfield(handles, 'compYieldImpactLinesDashed')
    compYieldImpactLinesDashed = handles.compYieldImpactLinesDashed; 
else
    compYieldImpactLinesDashed = line([0, 0, 0], [0, 0, 0], [0, 0, 0], 'Color',  handles.compColour, 'LineWidth', 2);
end
if isfield(handles, 'compYieldImpactScatter')
    compYieldImpactScatter = handles.compYieldImpactScatter;    
else
    compYieldImpactScatter = scatter([0, 0], [0, 0], [1, 1], 'MarkerEdgeColor',  handles.compColour, 'MarkerFaceColor', 'none'); 
    set(compYieldImpactScatter, 'Visible', 'off');
end

if isfield(handles, 'waterYieldImpactLines')
    waterYieldImpactLines = handles.waterYieldImpactLines;
else
    axes(handles.axesYieldRepresentation);
    waterYieldImpactLines = line([0, 0, 0], [0, 0, 0], [0, 0, 0], 'Color', handles.waterColour, 'LineWidth', 1, 'LineStyle', '--');
end
if isfield(handles, 'waterYieldImpactLinesDashed')
    waterYieldImpactLinesDashed = handles.waterYieldImpactLinesDashed;
else
    axes(handles.axesYieldRepresentation);
    waterYieldImpactLinesDashed = line([0, 0, 0], [0, 0, 0], [0, 0, 0], 'Color', handles.waterColour, 'LineWidth', 2);
end
if isfield(handles, 'waterYieldImpactScatter')
    waterYieldImpactScatter = handles.waterYieldImpactScatter;    
else
    axes(handles.axesYieldRepresentation);
    waterYieldImpactScatter = scatter([0, 0], [0, 0], [1, 1], 'MarkerEdgeColor', handles.waterColour, 'MarkerFaceColor', 'none'); 
end

axes(handles.axesYieldRepresentation);
title(['Effect of competition and waterlogging for ', num2str(handles.rainfall), ' mm GSR']);

currentSIS = getSIS(handles);
[compExtent, compYieldLoss, waterExtent, waterYieldGain] = currentSIS.getRawSIBounds(handles.AGBM, handles.BGBM, handles.plantSpacing);

if(handles.useWaterlogging)

   % Figure out y int
   % Yield increse at y = AGBM / extent * A
   % extent = sqrt(BGBM) * B
%   ext = sqrt(handles.BGBMPerM) * handles.waterReachFactor;
%   yint = handles.AGBMPerM / ext * handles.waterYieldFactor;
   
   ext = waterExtent;
   yint = waterYieldGain;
   
   % Calculate waterlogging multiplier from rainfall.
   rain = handles.rainfall;
   
   if rain >= handles.waterMinRainfallForFullImpact
       mult = 1;
   elseif rain <= handles.waterZeroImpactRainfall
       mult = 0;
   else
       mult = (rain - handles.waterZeroImpactRainfall) / ...
            (handles.waterMinRainfallForFullImpact - handles.waterZeroImpactRainfall);
   end
   
   set(waterYieldImpactLines, 'XData', [0,0, ext]);
   set(waterYieldImpactLines, 'YData', [yint,yint, 0]);
   set(waterYieldImpactLines, 'Visible', 'on');   
   
   set(waterYieldImpactLinesDashed, 'XData', [0,0, ext]);
   set(waterYieldImpactLinesDashed, 'YData', mult*[yint,yint, 0]);
   set(waterYieldImpactLinesDashed, 'Visible', 'on');
   
   set(waterYieldImpactScatter, 'XData', [0, ext]);
   set(waterYieldImpactScatter, 'YData', [yint*mult, 0]);
   set(waterYieldImpactScatter, 'SizeData', [100, 100]);
   set(waterYieldImpactScatter, 'Visible', 'on');

   waterReach = ext;
else
   set(waterYieldImpactLines, 'XData', [0, 0, 0]);     
   set(waterYieldImpactLines, 'YData', [0, 0, 0]);
   set(waterYieldImpactLines, 'Visible', 'off');
   set(waterYieldImpactLinesDashed, 'Visible', 'off');

   set(waterYieldImpactScatter, 'XData', [0, 0]);
   set(waterYieldImpactScatter, 'YData', [0, 0]);
   set(waterYieldImpactScatter, 'SizeData', [1, 1]*.1);
   set(waterYieldImpactScatter, 'Visible', 'on');
   
   waterReach = 0;
end

if(handles.useCompetition)
   % Figure out y int
   % Yield increse at y = AGBM / extent * A
   % extent = sqrt(BGBM) * B
%   ext = sqrt(handles.BGBMPerM) * handles.compReachFactor;
%   yint = -handles.AGBMPerM / ext * handles.compYieldFactor;

   ext = compExtent;
   yint = -compYieldLoss;
   
   % Calculate waterlogging multiplier from rainfall.
   rain = handles.rainfall;
   
   if rain <= handles.compMaxRainfallForFullImpact
       mult = 1;
   elseif rain >= handles.compZeroImpactRainfall
       mult = 0;
   else
       mult = 1 - ((rain - handles.compMaxRainfallForFullImpact) / ...
            (handles.compZeroImpactRainfall - handles.compMaxRainfallForFullImpact));
   end
   
   yint1 = -yint;
   if yint1 > 100
      extra = yint1 - 100;
      ext1 = ext / yint1 * extra; 
      yint1 = -100;
   else
       yint1 = - yint1;
       ext1 = 0;
   end
   
   yint2 = -yint * mult;
   if yint2 > 100
      extra = yint2 - 100;
      ext2 = ext / yint2 * extra;             
      yint2 = -100;
   else
     yint2 = -yint2;
      ext2 = 0;
   end
   
   set(compYieldImpactLines, 'XData', [0, ext1, ext]);
   set(compYieldImpactLines, 'YData', [yint1, yint1, 0]);
   set(compYieldImpactLines, 'Visible', 'on');

   set(compYieldImpactLinesDashed, 'XData', [0, ext2, ext]);
   set(compYieldImpactLinesDashed, 'YData', [yint2, yint2, 0]);
   set(compYieldImpactLinesDashed, 'Visible', 'on');
   
   set(compYieldImpactScatter, 'XData', [0, ext]);
   set(compYieldImpactScatter, 'YData', [yint2, 0]);
   set(compYieldImpactScatter, 'SizeData', [100, 100]);
   set(compYieldImpactScatter, 'Visible', 'on');
   
   compReach = ext;
else
   set(compYieldImpactLines, 'XData', [0, 0, 0]);     
   set(compYieldImpactLines, 'YData', [0, 0, 0]);
   set(compYieldImpactLines, 'Visible', 'off');
   set(compYieldImpactLinesDashed, 'Visible', 'off');

   set(compYieldImpactScatter, 'XData', [0, 0]);
   set(compYieldImpactScatter, 'YData', [0, 0]);
   set(compYieldImpactScatter, 'SizeData', [1, 1]*.1);
   set(compYieldImpactScatter, 'Visible', 'off');

   compReach = 0;
end

maxReach = max([compReach, waterReach, 30]) - 0.01;
reach = (floor(maxReach / 15) + 1) * 15;
reach = max([reach, 30]);    
axis([0 reach, -120, 120]);
set(handles.axesYieldRepresentation, 'XTick', 0:10:reach)
k = 0;
ss = {};
for p = 0:10:reach
    k = k + 1;
    ss{k} = num2str(p);
end
set(handles.axesYieldRepresentation, 'XTickLabel', ss)

handles.compRainImpactLines = compRainImpactLines;
handles.waterRainImpactLines = waterRainImpactLines;
handles.rainMeterImpactLines = rainMeterImpactLines;

handles.compYieldImpactLines = compYieldImpactLines;
handles.compYieldImpactLinesDashed = compYieldImpactLinesDashed;
handles.compYieldImpactScatter = compYieldImpactScatter;
handles.waterYieldImpactLines = waterYieldImpactLines;
handles.waterYieldImpactLinesDashed = waterYieldImpactLinesDashed;
handles.waterYieldImpactScatter = waterYieldImpactScatter;

guidata(handles.axesRainfallImpact, handles);

% Update the ellipse shape.
% Plot from theta = 0..pi/2 whrre theta is from the vertial ccw into the
% horizontal.
% use x = a sin(theta)
% use y = b sin(theta)
thetaRange = [0:0.1:pi/2, pi/2];
xs = zeros(1, length(thetaRange));
ys = xs;
i = 0;
b = 1;
a = b / handles.relativeRadii;

for theta = thetaRange
    i = i + 1;
    xs(i) = a * sin(theta);
    ys(i) = -b * cos(theta);
end

axes(handles.axesRootShape);
cla(handles.axesRootShape);
plot(handles.axesRootShape, xs, ys);
% assign 8 pixels for above ground.
% Then work out the rest such that the y axis is 1.
pos = get(handles.axesRootShape, 'Position');
yHeight = pos(4) - 12;
yMax = 12/yHeight;
xMax = pos(3) / yHeight;
plot([0, xMax], [0, 0], 'Color', [.8 .4 0]);
text(a / 2, yMax/2, 'a');
axis([0, xMax, -1, yMax]);


% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cancelled = true;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
 pushbuttonCancel_Callback(hObject, eventdata, handles)


% --- Executes on button press in radiobuttonSpacing1.
function radiobuttonSpacing1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing1


% --- Executes on button press in radiobuttonSpacing2.
function radiobuttonSpacing2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing2


% --- Executes on button press in radiobuttonSpacing3.
function radiobuttonSpacing3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing3


% --- Executes on button press in radiobuttonSpacing4.
function radiobuttonSpacing4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing4


% --- Executes on button press in radiobuttonSpacing5.
function radiobuttonSpacing5_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing5


% --- Executes on button press in radiobuttonSpacing6.
function radiobuttonSpacing6_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSpacing6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSpacing6


% --- Executes when selected object is changed in uipanel8.
function uipanel8_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel8 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

str = get(eventdata.NewValue, 'String');
plantSpacing = str2double(str(1));
if ~isnan(plantSpacing)
    handles.plantSpacing = plantSpacing;
    guidata(hObject, handles);
    set(handles.textAGBMPerM, 'String', [num2str(handles.AGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);
    set(handles.textBGBMPerM, 'String', [num2str(handles.BGBM / handles.plantSpacing, '%3.0f'), 'kg/m']);
    
    updateTestArea(handles);
end



function editRootDensity_Callback(hObject, eventdata, handles)
% hObject    handle to editRootDensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRootDensity as text
%        str2double(get(hObject,'String')) returns contents of editRootDensity as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.rootDensity = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.rootDensity));
end
updateTestArea(handles);

% --- Executes during object creation, after setting all properties.
function editRootDensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRootDensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRelativeRadii_Callback(hObject, eventdata, handles)
% hObject    handle to editRelativeRadii (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRelativeRadii as text
%        str2double(get(hObject,'String')) returns contents of editRelativeRadii as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.relativeRadii = newNum;
        guidata(hObject, handles);
        updateTestArea(handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.relativeRadii));
end
updateTestArea(handles);

% --- Executes during object creation, after setting all properties.
function editRelativeRadii_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRelativeRadii (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonEditNotes.
function pushbuttonEditNotes_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEditNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
title = 'Spatial Interactions Notes...';
prompt = ['These notes relate to the spatial interactions setup for ', handles.cropInfo.cropName, '.'];
notes = handles.notes;
response = NotesEditor(title, prompt, notes);
if ~isempty(response)
   if (response.saved)
       handles.notes = response.notes;
       guidata(hObject, handles);
   end
end


% --- Executes on button press in pushbuttonSaveParams.
function pushbuttonSaveParams_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSaveParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the output function to create the Sis.
% Save the sis to a file.

    % open the save dialogue.
    % Need to use uiputfile, as uisave does not compile.
    [file, path, filt] = uiputfile('.mat', 'Save Spatial Interactions Setup to .MAT File', [ImagineObject.imagineRoot, '/Resources/SIS/', handles.cropInfo.cropName, '_sis.mat']);
    
    if(isequal(path, 0) || isequal(file, 0))
        % User cancelled save. Do nothing.
        
    else
        filename = [path, file];
        sis = getSIS(handles);
        save(filename, 'sis')
    end


% --- Executes on button press in pushbuttonLoadParams.
function pushbuttonLoadParams_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load the sis. Merge default and saved data. Setup controls.

[file, path, filt] = uigetfile('.mat', 'Load Spatial Interaction Setup from File', [ImagineObject.imagineRoot, '/Resources/SIS']);

if(isequal(path, 0) || isequal(file, 0))
    % If path or file are zero, user cancelled the export. Do nothing.
    return
end
    
loadedStruct = load([path, file]);

% Can customise the load process here. This can be used for backward
% compatability.

if isfield(loadedStruct, 'sis')
    if strcmp(class(loadedStruct.sis), 'SpatialInteractions')
        handles = useSIS(handles, loadedStruct.sis);
        guidata(hObject, handles);
        setupControls(handles);
        return
    end
end

error(['There was an error loading Spatial Interactions data from the file provided. ', ...
       'You may be able to extract some data from it by loading it into the Matlab workspace and inspecting it.']);


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extractPlotData(handles.figure1, true);
