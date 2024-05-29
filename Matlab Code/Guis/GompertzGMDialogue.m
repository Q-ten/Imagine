function varargout = GompertzGMDialogue(varargin)
% GOMPERTZGMDIALOGUE M-file for GompertzGMDialogue.fig
%      GOMPERTZGMDIALOGUE, by itself, creates a new GOMPERTZGMDIALOGUE or raises the existing
%      singleton*.
%
%      H = GOMPERTZGMDIALOGUE returns the handle to a new GOMPERTZGMDIALOGUE or the handle to
%      the existing singleton*.
%
%      GOMPERTZGMDIALOGUE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GOMPERTZGMDIALOGUE.M with the given input arguments.
%
%      GOMPERTZGMDIALOGUE('Property','Value',...) creates a new GOMPERTZGMDIALOGUE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GompertzGMDialogue_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GompertzGMDialogue_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GompertzGMDialogue

% Last Modified by GUIDE v2.5 18-Feb-2014 17:25:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GompertzGMDialogue_OpeningFcn, ...
                   'gui_OutputFcn',  @GompertzGMDialogue_OutputFcn, ...
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

function gm = setupParameters(varargin)

    % This function should accept 4 arguments in varargin:
    % 1. propagationParameters
    % 2. plantingParameters
    % 3. coppiceParameters
    % 4. desructiveHarvestingParameters
    % 5. setupParameters
    % 6. yieldUnit
    
    % If these 4 arguments aren't supplied, or are empty, then we need to
    % create the default ones.

   % Seedling biomass (in tonnes)
   A0 = 0.00005;
   B0 = 0.000025;

   % Max size of above and below ground biomass.
   KA = 2;
   KB = 1;

   % Estimated time to 80% of max size, if left alone at nom rainfall.
   A_T280 = 20;
   B_T280 = 20;

   default.plantingParameters.A0 = A0;
   default.plantingParameters.B0 = B0;

   default.propagationParameters.KA = KA;
   default.propagationParameters.KB = KB;

   default.propagationParameters.alpha_nom = -log(log(0.8)/(log(A0/KA))) / A_T280;
   default.propagationParameters.beta_nom = -log(log(0.8)/(log(B0/KB))) / B_T280;
   default.propagationParameters.alpha_coppice = 1.5;
   default.propagationParameters.beta_coppice = -0.5;
   default.propagationParameters.alpha_slope = 1;
   default.propagationParameters.beta_slope = 1;
   default.propagationParameters.nom_rain = 400;
   default.propagationParameters.A_optimal_rainfall = 750;
   default.propagationParameters.B_optimal_rainfall = 750;
   default.propagationParameters.A_sustaining_rainfall = 150;
   default.propagationParameters.B_sustaining_rainfall = 100;

   default.propagationParameters.initialBoost = 1;
   default.propagationParameters.boostHalfLife = 1;

   default.propagationParameters.useCFI = 1;
   default.propagationParameters.ratioDryToGreenBM = 0.55;
   default.propagationParameters.fractionCarbonInDryBM = 0.50;
   default.propagationParameters.CFIBuffer = 5;
   default.propagationParameters.useBGBM = 1;

   default.coppiceParameters.postCoppiceA = 0.01;
   default.coppiceParameters.B_coppice_loss = 20;

   default.propagationParameters.costParameters.useDensityBasedHarvestCost = false;
   default.propagationParameters.costParameters.speedTableFactor = [];
   default.propagationParameters.costParameters.speedTablePower = [];
   default.propagationParameters.costParameters.costFactor = 0;
   default.propagationParameters.costParameters.costPower = 1;

   default.destructiveHarvestParameters = [];

   default.setupParameters.coppiceYears = 6:4:30;
   default.setupParameters.coppiceMonth = 9;
   default.setupParameters.plantMonth = 4;
   default.setupParameters.plantYear = 1;
   default.setupParameters.showPlotDetail = false;
   default.setupParameters.usingStochasticRainModel = false;

   default.yieldUnit = Unit('', 'Tree', 'Unit');

   fields = {'propagationParameters', 'plantingParameters', 'coppiceParameters', 'destructiveHarvestParameters', 'setupParameters', 'yieldUnit'};

   for i = 1:length(fields)        
       if (nargin >= i)
           gm.(fields{i}) = varargin{i};
       end
   end

   gm = absorbFields(default, gm);
   % Overwrite the toggle detail so that it's false when we start up.
   gm.setupParameters.showPlotDetail = false;
   
   
% --- Executes just before GompertzGMDialogue is made visible.
function GompertzGMDialogue_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GompertzGMDialogue (see VARARGIN)

% This is the GUI to populate the parameters for the
% ABGompertzGrowthModelDelegate object
if nargin >= 9
    handles.gm = setupParameters(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6});
else
    handles.gm = setupParameters();    
end

% Set output to empty to indicate cancelling setup.
handles.output = [];

guidata(hObject, handles);
populateDialog(handles);

% UIWAIT makes GompertzGMDialogue wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GompertzGMDialogue_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(gcf);

% --- Executes on button press in acceptButton.
function acceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.propagationParameters = handles.gm.propagationParameters;
handles.output.plantingParameters = handles.gm.plantingParameters;
handles.output.coppiceParameters = handles.gm.coppiceParameters;
handles.output.destructiveHarvestParameters = handles.gm.destructiveHarvestParameters;
handles.output.setupParameters = handles.gm.setupParameters;
handles.output.yieldUnit = handles.gm.yieldUnit;

if ~isempty(handles.plotDetailFig)
    if ishandle(handles.plotDetailFig)
        delete(handles.plotDetailFig);
    end
end
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.plotDetailFig)
    if ishandle(handles.plotDetailFig)
        delete(handles.plotDetailFig);
    end
end

uiresume(gcf);

function KB_edit_Callback(hObject, eventdata, handles)
% hObject    handle to KB_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KB_edit as text
%        str2double(get(hObject,'String')) returns contents of KB_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainB_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function KB_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KB_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function B_T280_edit_Callback(hObject, eventdata, handles)
% hObject    handle to B_T280_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of B_T280_edit as text
%        str2double(get(hObject,'String')) returns contents of B_T280_edit as a double


n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainB_section(hObject, eventdata, handles);
    handles = guidata(hObject);
    propPar = handles.gm.propagationParameters;
    % Then use growth rate to redo beta section. alpha_nom is set in the
    % process function
    set(handles.beta_nom_edit, 'String', num2str(propPar.beta_nom));
    process_beta_section(hObject, eventdata, handles);
    process_beta_rain_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function B_T280_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to B_T280_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function B0_edit_Callback(hObject, eventdata, handles)
% hObject    handle to B0_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of B0_edit as text
%        str2double(get(hObject,'String')) returns contents of B0_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainB_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function B0_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to B0_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function KA_edit_Callback(hObject, eventdata, handles)
% hObject    handle to KA_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KA_edit as text
%        str2double(get(hObject,'String')) returns contents of KA_edit as a double

n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainA_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function KA_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KA_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_T280_edit_Callback(hObject, eventdata, handles)
% hObject    handle to A_T280_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of A_T280_edit as text
%        str2double(get(hObject,'String')) returns contents of A_T280_edit as a double

n = str2double(get(hObject, 'String'));

if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainA_section(hObject, eventdata, handles);
    handles = guidata(hObject);
    propPar = handles.gm.propagationParameters;
    % Then use growth rate to redo alpha section. alpha_nom is set in the
    % process function
    set(handles.alpha_nom_edit, 'String', num2str(propPar.alpha_nom));
    process_alpha_section(hObject, eventdata, handles);
    process_alpha_rain_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function A_T280_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to A_T280_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A0_edit_Callback(hObject, eventdata, handles)
% hObject    handle to A0_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of A0_edit as text
%        str2double(get(hObject,'String')) returns contents of A0_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_mainA_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function A0_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to A0_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_optimal_rain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to A_optimal_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of A_optimal_rain_edit as text
%        str2double(get(hObject,'String')) returns contents of A_optimal_rain_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_alpha_rain_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function A_optimal_rain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to A_optimal_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function A_sustaining_rain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to A_sustaining_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of A_sustaining_rain_edit as text
%        str2double(get(hObject,'String')) returns contents of A_sustaining_rain_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_alpha_rain_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function A_sustaining_rain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to A_sustaining_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function B_optimal_rain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to B_optimal_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of B_optimal_rain_edit as text
%        str2double(get(hObject,'String')) returns contents of B_optimal_rain_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_beta_rain_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function B_optimal_rain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to B_optimal_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function B_sustaining_rain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to B_sustaining_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of B_sustaining_rain_edit as text
%        str2double(get(hObject,'String')) returns contents of B_sustaining_rain_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_beta_rain_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function B_sustaining_rain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to B_sustaining_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function beta_nom_edit_Callback(hObject, eventdata, handles)
% hObject    handle to beta_nom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beta_nom_edit as text
%        str2double(get(hObject,'String')) returns contents of beta_nom_edit as a double


n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_beta_section(hObject, eventdata, handles);
    handles = guidata(hObject);
    planPar = handles.gm.plantingParameters;
    propPar = handles.gm.propagationParameters;
    % Then use growth rate to redo time to 80% section. 
    % Need to calculate the time explicity.
    B_T280 = -log(log(0.8)/(log(planPar.B0/propPar.KB))) / propPar.beta_nom;
    set(handles.B_T280_edit, 'String', num2str(B_T280));
    process_mainB_section(hObject, eventdata, handles);
    process_beta_rain_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function beta_nom_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta_nom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function beta_coppice_edit_Callback(hObject, eventdata, handles)
% hObject    handle to beta_coppice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beta_coppice_edit as text
%        str2double(get(hObject,'String')) returns contents of beta_coppice_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_beta_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function beta_coppice_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta_coppice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function beta_slope_edit_Callback(hObject, eventdata, handles)
% hObject    handle to beta_slope_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beta_slope_edit as text
%        str2double(get(hObject,'String')) returns contents of beta_slope_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_beta_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function beta_slope_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta_slope_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function alpha_nom_edit_Callback(hObject, eventdata, handles)
% hObject    handle to alpha_nom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alpha_nom_edit as text
%        str2double(get(hObject,'String')) returns contents of alpha_nom_edit as a double


n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_alpha_section(hObject, eventdata, handles);
    handles = guidata(hObject);
    planPar = handles.gm.plantingParameters;    
    propPar = handles.gm.propagationParameters;
    % Then use growth rate to redo time to 80% section. 
    % Need to calculate the time explicity.
    A_T280 = -log(log(0.8)/(log(planPar.A0/propPar.KA))) / propPar.alpha_nom;
    set(handles.A_T280_edit, 'String', num2str(A_T280));
    process_mainA_section(hObject, eventdata, handles);
    process_alpha_rain_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function alpha_nom_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpha_nom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function alpha_coppice_edit_Callback(hObject, eventdata, handles)
% hObject    handle to alpha_coppice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alpha_coppice_edit as text
%        str2double(get(hObject,'String')) returns contents of alpha_coppice_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_alpha_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function alpha_coppice_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpha_coppice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function alpha_slope_edit_Callback(hObject, eventdata, handles)
% hObject    handle to alpha_slope_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alpha_slope_edit as text
%        str2double(get(hObject,'String')) returns contents of alpha_slope_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_alpha_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function alpha_slope_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpha_slope_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Checks the inputs in first column and completes graph if they are ok
function process_mainA_section(hObject, eventdata, handles)

planPar = handles.gm.plantingParameters;
propPar = handles.gm.propagationParameters;

KA = str2double(get(handles.KA_edit, 'String'));
A_T280 = str2double(get(handles.A_T280_edit, 'String'));
A0 = str2double(get(handles.A0_edit, 'String'));

if(all( [~isnan(KA), ~isnan(A_T280), ~isnan(A0)]))
    
    propPar.KA = KA;
    planPar.A0 = A0;
    propPar.alpha_nom = -log(log(0.8)/(log(planPar.A0/propPar.KA))) / A_T280;
    
    handles.gm.plantingParameters = planPar;
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    plotCoppicedData(handles);     
end


% Checks the inputs in second column and completes graph if they are ok
function process_mainB_section(hObject, eventdata, handles)

planPar = handles.gm.plantingParameters;
propPar = handles.gm.propagationParameters;

KB = str2double(get(handles.KB_edit, 'String'));
B_T280 = str2double(get(handles.B_T280_edit, 'String'));
B0 = str2double(get(handles.B0_edit, 'String'));

if(all( [~isnan(KB), ~isnan(B_T280), ~isnan(B0)]))
    
    propPar.KB = KB;
    planPar.B0 = B0;
    propPar.beta_nom = -log(log(0.8)/(log(planPar.B0/propPar.KB))) / B_T280;

    handles.gm.plantingParameters = planPar;
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    plotCoppicedData(handles);  
end

% Checks the inputs in second column and completes graph if they are ok
function process_alpha_section(hObject, eventdata, handles)

propPar = handles.gm.propagationParameters;

alpha_nom = str2double(get(handles.alpha_nom_edit, 'String'));
alpha_coppice = str2double(get(handles.alpha_coppice_edit, 'String'));
alpha_slope = str2double(get(handles.alpha_slope_edit, 'String'));

if(all( [~isnan(alpha_nom), ~isnan(alpha_coppice), ~isnan(alpha_slope)]))
    
    propPar.alpha_nom = alpha_nom;
    propPar.alpha_coppice = alpha_coppice;
    propPar.alpha_slope = alpha_slope;
    
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    
    plotAlphaCurve(handles) 
    plotCoppicedData(handles);      
end

% Checks the inputs in second column and completes graph if they are ok
function process_beta_section(hObject, eventdata, handles)

gm = handles.gm;
propPar = gm.propagationParameters;

beta_nom = str2double(get(handles.beta_nom_edit, 'String'));
beta_coppice = str2double(get(handles.beta_coppice_edit, 'String'));
beta_slope = str2double(get(handles.beta_slope_edit, 'String'));

if(all( [~isnan(beta_nom), ~isnan(beta_coppice), ~isnan(beta_slope)]))
    
    propPar.beta_nom = beta_nom;
    propPar.beta_coppice = beta_coppice;
    propPar.beta_slope = beta_slope;
    
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    
    plotBetaCurve(handles) 
    plotCoppicedData(handles);      
end

% Checks the inputs in second column and completes graph if they are ok
function process_alpha_rain_section(hObject, eventdata, handles)

gm = handles.gm;
propPar = gm.propagationParameters;

A_optimal_rainfall = str2double(get(handles.A_optimal_rain_edit, 'String'));
A_sustaining_rainfall = str2double(get(handles.A_sustaining_rain_edit, 'String'));

if(all( [~isnan(A_optimal_rainfall), ~isnan(A_sustaining_rainfall)]))
    
    propPar.A_optimal_rainfall = A_optimal_rainfall;
    propPar.A_sustaining_rainfall = A_sustaining_rainfall;
     
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    
    plotAlphaRainCurve(handles) 
end

% Checks the inputs in second column and completes graph if they are ok
function process_beta_rain_section(hObject, eventdata, handles)

gm = handles.gm;
propPar = gm.propagationParameters;

B_optimal_rainfall = str2double(get(handles.B_optimal_rain_edit, 'String'));
B_sustaining_rainfall = str2double(get(handles.B_sustaining_rain_edit, 'String'));

if(all( [~isnan(B_optimal_rainfall), ~isnan(B_sustaining_rainfall)]))
    
    propPar.B_optimal_rainfall = B_optimal_rainfall;
    propPar.B_sustaining_rainfall = B_sustaining_rainfall;

    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);

    plotBetaRainCurve(handles) 
end



% Checks the inputs coppiced section
function process_coppiced_section(hObject, eventdata, handles)

gm = handles.gm;
coppPar = gm.coppiceParameters;

coppice_years = str2num(get(handles.coppice_years_edit, 'String'));
coppice_years = coppice_years(coppice_years <= 30 & coppice_years >= 1);
set(handles.coppice_years_edit, 'String', num2str(coppice_years));
postCoppiceA = str2double(get(handles.post_coppice_A_edit, 'String'));
B_coppice_loss = str2double(get(handles.B_coppice_loss_edit, 'String'));

if(B_coppice_loss > 99)
    B_coppice_loss = 99;
    set(handles.B_coppice_loss_edit, 'String', '99');
end
if(B_coppice_loss < 0)
    B_coppice_loss = 0;
    set(handles.B_coppice_loss_edit, 'String', '0');
end

if(all( [~isnan(coppice_years), ~isnan(postCoppiceA), ~isnan(B_coppice_loss)]))
    coppPar.postCoppiceA = postCoppiceA;
    coppPar.B_coppice_loss = B_coppice_loss;
    
    handles.gm.coppiceParameters = coppPar;
    guidata(hObject, handles);

    plotCoppicedData(handles)
end




function plotAGCurve(handles) 
gm = handles.gm;
propPar = gm.propagationParameters;
planPar = gm.plantingParameters;

axes(handles.mainAxes)
agData = propPar.KA * exp(log(planPar.A0/propPar.KA) * exp(-propPar.alpha_nom * handles.t));
set(handles.agCurve, 'Ydata', agData);
set(handles.p8LineA, 'Ydata', ones(1, length(handles.t)) * 0.8 * propPar.KA);
set(handles.startPointA, 'Ydata', planPar.A0);

A_T280 = str2double(get(handles.A_T280_edit, 'String'));
set(handles.A_T280_line, 'Xdata', A_T280 * [1 1]);


function plotBGCurve(handles)
gm = handles.gm;
propPar = gm.propagationParameters;
planPar = gm.plantingParameters;

axes(handles.mainAxes)
bgData = propPar.KB * exp(log(planPar.B0/propPar.KB) * exp(-propPar.beta_nom * handles.t));
set(handles.bgCurve, 'Ydata', bgData);
set(handles.p8LineB, 'Ydata', ones(1, length(handles.t)) * 0.8 * propPar.KB);
set(handles.startPointB, 'Ydata', planPar.B0);

B_T280 = str2double(get(handles.B_T280_edit, 'String'));
set(handles.B_T280_line, 'Xdata', B_T280 * [1 1]);


function plotAlphaCurve(handles)

gm = handles.gm;
propPar = gm.propagationParameters;

axes(handles.alphaAxes);

alphaData = (propPar.alpha_coppice - propPar.alpha_nom) * exp(-propPar.alpha_slope * handles.AB) + propPar.alpha_nom;
set(handles.alphaCurve, 'YData', alphaData);
set(handles.alphaAsymp, 'YData', propPar.alpha_nom * [1 1]);
axis([0 max(handles.AB) 0 1.2*propPar.alpha_coppice]);


function plotBetaCurve(handles)
gm = handles.gm;
propPar = gm.propagationParameters;

axes(handles.betaAxes)

betaData = (propPar.beta_coppice - propPar.beta_nom) * exp(-propPar.beta_slope * handles.AB) + propPar.beta_nom;
set(handles.betaCurve, 'YData', betaData);
set(handles.betaAsymp, 'YData', propPar.beta_nom * [1 1]);
axis([0 max(handles.AB) 1.2*propPar.beta_coppice 1.2*propPar.beta_nom]);


function plotAlphaRainCurve(handles)
gm = handles.gm;
propPar = gm.propagationParameters;

axes(handles.rainGrowthAxes)

A_rain_multiplier = propPar.alpha_nom / (propPar.nom_rain - propPar.A_sustaining_rainfall) ...
            / (propPar.nom_rain - 2*propPar.A_optimal_rainfall + propPar.A_sustaining_rainfall);
        
alphaRainData = A_rain_multiplier * (handles.rain - propPar.A_sustaining_rainfall) .* ...
                    (handles.rain - 2 * propPar.A_optimal_rainfall + propPar.A_sustaining_rainfall);
                
set(handles.alphaRainCurve, 'YData', alphaRainData);
set(handles.alphaNominalMarker, 'XData', propPar.nom_rain);
set(handles.alphaNominalMarker, 'YData', propPar.alpha_nom);


function plotBetaRainCurve(handles)
gm = handles.gm;
propPar = gm.propagationParameters;

axes(handles.rainGrowthAxes)

B_rain_multiplier = propPar.beta_nom / (propPar.nom_rain - propPar.B_sustaining_rainfall) ...
            / (propPar.nom_rain - 2*propPar.B_optimal_rainfall + propPar.B_sustaining_rainfall);    
 
betaRainData = B_rain_multiplier * (handles.rain - propPar.B_sustaining_rainfall) .* ...
                    (handles.rain - 2 * propPar.B_optimal_rainfall + propPar.B_sustaining_rainfall);
                
set(handles.betaRainCurve, 'YData', betaRainData);
set(handles.betaNominalMarker, 'XData', propPar.nom_rain);
set(handles.betaNominalMarker, 'YData', propPar.beta_nom);



function nom_rain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to nom_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nom_rain_edit as text
%        str2double(get(hObject,'String')) returns contents of nom_rain_edit as a double
gm = handles.gm;
propPar = gm.propagationParameters;

n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', propPar.nom_rain); 
else
    handles.gm.propagationParameters.nom_rain = n;
    guidata(hObject, handles)
    process_alpha_rain_section(hObject, eventdata, handles);
    process_beta_rain_section(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function nom_rain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nom_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function coppice_years_edit_Callback(hObject, eventdata, handles)
% hObject    handle to coppice_years_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coppice_years_edit as text
%        str2double(get(hObject,'String')) returns contents of coppice_years_edit as a double
n = str2num(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    set(hObject, 'String', num2str(sort(n)));
    handles.gm.setupParameters.coppiceYears = str2num(get(handles.coppice_years_edit, 'String'));
    
    global gompertzPlotData
    gompertzPlotData.AGBM = [];

    process_coppiced_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function coppice_years_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coppice_years_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function post_coppice_A_edit_Callback(hObject, eventdata, handles)
% hObject    handle to post_coppice_A_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of post_coppice_A_edit as text
%        str2double(get(hObject,'String')) returns contents of post_coppice_A_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_coppiced_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function post_coppice_A_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to post_coppice_A_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Function that gets the state based on planting.
% Function that propagates from start to end
% Function that coppices.
function newState = fakePlant(plantingParameters)

newState.AGBM = plantingParameters.A0;
newState.BGBM = plantingParameters.B0;

function newState = fakePropagate(propagationParameters, currentState, month, monthsRain, plantMonth)

if month < plantMonth
    newState.AGBM = 0;
    newState.BGBM = 0;
else
    year = floor((month - 1) / 12) + 1;
    monthInYear = mod(month - 1, 12) + 1;
    newState = ABGompertzPropagateState(currentState, propagationParameters, year, monthInYear, monthsRain, plantMonth);
end

function newState = fakeCoppice(coppiceParameters, currentState)

newState.AGBM = coppiceParameters.postCoppiceA;
newState.BGBM = currentState.BGBM * (100 - coppiceParameters.B_coppice_loss) / 100;


% Plots the coppiced data. Uses all the elements except the rainfall one.
function plotCoppicedData(handles, focusPlotDetail)

if (nargin == 1)
    focusPlotDetail = false;
end

global gompertzPlotData

gm = handles.gm;
propPar = gm.propagationParameters;
coppPar = gm.coppiceParameters;
planPar = gm.plantingParameters;
setupPar = gm.setupParameters;

% Get previous state, rainfall
if (setupPar.usingStochasticRainModel)
    climateMgr = ClimateManager.getInstance();
    monthlyRain = climateMgr.generateMonthlyRainfall;
    monthlyRain = monthlyRain(1:30*12);    
else
    monthlyRain = ones(1, 30*12) * propPar.nom_rain / 12;
end

yearlyRain = monthlyRain;

for i = 1:length(monthlyRain)    
    % Get 'annual rainfall' from average of previous 3 months rainfall so as to work out
    % growth rates.
    if(i == 1)
        rain = monthlyRain(1);
    elseif(i == 2)
        rain = (monthlyRain(1) + monthlyRain(2))/2;
    else
        rain = mean(monthlyRain(i-2:i));
    end
    yearlyRain(i) = rain * 12;
end

plantMonth = setupPar.plantMonth;
plantYear = setupPar.plantYear;
coppiceMonth = setupPar.coppiceMonth;
coppiceYears = setupPar.coppiceYears;

% coppiceT is a time scale we can use with the extra bits of time we need
% to have two points for each coppice month (for before and after).
% the agCoppiceData and bgCoppiceData match the time.
% cy is just an index to keep track of which coppice we're up to so we can
% offset the data accordingly.
coppiceT = zeros(1, 1 + 30*12 + length(coppiceYears));
agCoppicedData = coppiceT;
bgCoppicedData = coppiceT;

cy = 1; % coppice year
planted = false;
newState.AGBM = 0;
newState.BGBM = 0;

% For each step, use the standard ABGompertz function to propagate.
% Coppice if appropriate.
for i = 1:length(1:12*30)
   
   year = floor((i - 1)/12) + 1;
   month = mod(i-1, 12) + 1;
   coppiceT(i + cy) = i / 12;
   
   if (year == plantYear && month == plantMonth)
       newState = fakePlant(planPar);
       planted = true;
       agCoppicedData(i + cy - 1) = newState.AGBM;
       bgCoppicedData(i + cy - 1) = newState.BGBM;
       currentState = newState;
   end
   
   if (planted)
       
       newState = fakePropagate(propPar, currentState, i, yearlyRain(i), plantMonth + (plantYear - 1) * 12);
    
       agCoppicedData(i + cy) = newState.AGBM;
       bgCoppicedData(i + cy) = newState.BGBM;
       currentState = newState;
       
       if(cy <= length(coppiceYears)) 
           if(year == coppiceYears(cy) && month == coppiceMonth)
              coppiceT(i + cy + 1) = coppiceT(i + cy);
              newState = fakeCoppice(coppPar, currentState);
              agCoppicedData(i + cy + 1) = newState.AGBM;
              bgCoppicedData(i + cy + 1) = newState.BGBM;
              currentState = newState;
              cy = cy + 1;       
           end
       end    
              
   end
       
end

gompertzPlotData.coppiceT = coppiceT;
if isempty(gompertzPlotData.AGBM)
    gompertzPlotData.AGBM = agCoppicedData;
    gompertzPlotData.BGBM = bgCoppicedData;
else
    gompertzPlotData.AGBM(end + 1, :) = agCoppicedData;
    gompertzPlotData.BGBM(end + 1, :) = bgCoppicedData;
end

axes(handles.mainAxes);
if isfield(handles, 'agCoppiceCurve')    
    set(handles.agCoppiceCurve, 'XData', coppiceT);
    set(handles.agCoppiceCurve, 'YData', agCoppicedData);
    set(handles.bgCoppiceCurve, 'XData', coppiceT);
    set(handles.bgCoppiceCurve, 'YData', bgCoppicedData);
    ylabel(['Biomass ', gm.yieldUnit.readableDenominatorUnit, ' (tonnes)']);
else
    
    xlabel('Time (years)');
    ylabel(['Biomass ', gm.yieldUnit.readableDenominatorUnit, ' (tonnes)']);

    hold on
    
    handles.bgCoppiceCurve = plot(coppiceT, bgCoppicedData, 'Color', [0.8 0 0]);
    handles.agCoppiceCurve = plot(coppiceT, agCoppicedData, 'Color', [0 0.8 0]);

    guidata(handles.mainAxes, handles);
end

if gm.setupParameters.showPlotDetail
    if isempty(handles.plotDetailFig)
        handles.plotDetailFig = GompertzPlotDetail(handles.figure1);
        guidata(handles.mainAxes, handles);
    else
        if ~ishandle(handles.plotDetailFig)
            handles.plotDetailFig = GompertzPlotDetail(handles.figure1);
            guidata(handles.mainAxes, handles);            
        else            
            GompertzPlotDetail('update', handles.plotDetailFig, guidata(handles.plotDetailFig));
        end
    end
    if (focusPlotDetail)
        figure(handles.plotDetailFig);
    end   
end

if (~focusPlotDetail)
    % Put the main Gompertz window on top.
    figure(handles.figure1);
end

function B_coppice_loss_edit_Callback(hObject, eventdata, handles)
% hObject    handle to B_coppice_loss_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of B_coppice_loss_edit as text
%        str2double(get(hObject,'String')) returns contents of B_coppice_loss_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    process_coppiced_section(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function B_coppice_loss_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to B_coppice_loss_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ratioDryToGreenBMEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ratioDryToGreenBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ratioDryToGreenBMEdit as text
%        str2double(get(hObject,'String')) returns contents of ratioDryToGreenBMEdit as a double

% Make sure the input is ok
x = str2double(get(hObject, 'String'));
if(x > .999)
    set(hObject, 'String', '.999')
    return
end
if(x < 0.001)
    set(hObject, 'String', '0.001')
    return
end  

if(isnan(x))
   set(hObject, 'String', num2str(handles.gm.propagationParameters.ratioDryToGreenBM)); 
else
    handles.gm.propagationParameters.ratioDryToGreenBM = x;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function ratioDryToGreenBMEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ratioDryToGreenBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fractionCarbonInDryBMEdit_Callback(hObject, eventdata, handles)
% hObject    handle to fractionCarbonInDryBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fractionCarbonInDryBMEdit as text
%        str2double(get(hObject,'String')) returns contents of fractionCarbonInDryBMEdit as a double

% Make sure the input is ok
x = str2double(get(hObject, 'String'));
if(x > .999)
    set(hObject, 'String', '.999')
    return
end
if(x < 0.001)
    set(hObject, 'String', '0.001')
    return
end 

if(isnan(x))
   set(hObject, 'String', num2str(handles.gm.propagationParameters.fractionCarbonInDryBM)); 
else
    handles.gm.propagationParameters.fractionCarbonInDryBM = x;
    guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function fractionCarbonInDryBMEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fractionCarbonInDryBMEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%
% This function populates the fields of the dialog based on the growth
% model in handles.
%
function populateDialog(handles)

global gompertzPlotData
gompertzPlotData.AGBM = [];
gompertzPlotData.BGBM = [];
gompertzPlotData.coppiceT = [];

gm = handles.gm;

propPar = gm.propagationParameters;
planPar = gm.plantingParameters;
coppPar = gm.coppiceParameters;
destpar = gm.destructiveHarvestParameters;
setupPar = gm.setupParameters;

set(handles.KA_edit, 'String', num2str(propPar.KA));
set(handles.A0_edit, 'String', num2str(planPar.A0));
A_T280 = fix(1000 * -log(log(0.8)/(log(planPar.A0/propPar.KA))) / propPar.alpha_nom) / 1000;
set(handles.A_T280_edit, 'String', num2str(A_T280));

set(handles.KB_edit, 'String', num2str(propPar.KB));
set(handles.B0_edit, 'String', num2str(planPar.B0));
B_T280 = fix(1000 * -log(log(0.8)/(log(planPar.B0/propPar.KB))) / propPar.beta_nom) / 1000;
set(handles.B_T280_edit, 'String', num2str(B_T280));

set(handles.alpha_nom_edit, 'String', num2str(propPar.alpha_nom));
set(handles.beta_nom_edit, 'String', num2str(propPar.beta_nom));

set(handles.alpha_coppice_edit, 'String', num2str(propPar.alpha_coppice));
set(handles.alpha_slope_edit, 'String', num2str(propPar.alpha_slope));
set(handles.beta_coppice_edit, 'String', num2str(propPar.beta_coppice));
set(handles.beta_slope_edit, 'String', num2str(propPar.beta_slope));

set(handles.nom_rain_edit, 'String', num2str(propPar.nom_rain));

set(handles.A_optimal_rain_edit, 'String', num2str(propPar.A_optimal_rainfall));
set(handles.A_sustaining_rain_edit, 'String', num2str(propPar.A_sustaining_rainfall));
set(handles.B_optimal_rain_edit, 'String', num2str(propPar.B_optimal_rainfall));
set(handles.B_sustaining_rain_edit, 'String', num2str(propPar.B_sustaining_rainfall));
set(handles.initial_boost_edit, 'String', num2str(propPar.initialBoost));
set(handles.boost_half_life_edit, 'String', num2str(propPar.boostHalfLife));

set(handles.checkboxUseCFI, 'Value', propPar.useCFI);
set(handles.checkboxUseBGBM, 'Value', propPar.useBGBM);
set(handles.ratioDryToGreenBMEdit, 'String', num2str(propPar.ratioDryToGreenBM));
set(handles.fractionCarbonInDryBMEdit, 'String', num2str(propPar.fractionCarbonInDryBM));
set(handles.editCFIBuffer, 'String', num2str(propPar.CFIBuffer));

set(handles.post_coppice_A_edit, 'String', num2str(coppPar.postCoppiceA));
set(handles.B_coppice_loss_edit, 'String', num2str(coppPar.B_coppice_loss));

set(handles.checkboxUseCustomCost, 'Value', propPar.costParameters.useDensityBasedHarvestCost);

units = get(handles.popupmenuYieldUnit, 'String');
ix = find(strcmp(units, gm.yieldUnit.readableDenominatorUnit), 1, 'first');
if ~isempty(ix)
   set(handles.popupmenuYieldUnit, 'Value', ix); 
end


% Start setting up the axes

   % set up legend axes
    axes(handles.axesAGBMLegend);
    axis([ 0, 1, 0 1]);
    line([0.1,0.9], [0.5 ,0.5], [0, 0], 'Color', 'g', 'LineWidth', 2);

    axes(handles.axesBGBMLegend);
    axis([ 0, 1, 0 1]);
    line([0.1,0.9], [0.5 ,0.5], [0, 0], 'Color', 'r', 'LineWidth', 2);

% Set up coppicing growth rate curves

% AB is ratio of A to B - the x-axis of the alpha and beta curves.
handles.AB = 0:0.1:5;

axes(handles.alphaAxes)
hold on
grid on
xlabel('Above Ground Biomass / Below Ground Biomass');
ylabel('\alpha');
alphaData = (propPar.alpha_coppice - propPar.alpha_nom) * exp(-propPar.alpha_slope * handles.AB) + propPar.alpha_nom;
handles.alphaCurve = plot(handles.AB, alphaData, 'b');
handles.alphaAsymp = plot([0 5], propPar.alpha_nom * [1 1], 'b--');
axis([0 5 0 1.2*propPar.alpha_coppice]);


axes(handles.betaAxes)
hold on
grid on
xlabel('Above Ground Biomass / Below Ground Biomass');
ylabel('\beta');
betaData = (propPar.beta_coppice - propPar.beta_nom) * exp(-propPar.beta_slope * handles.AB) + propPar.beta_nom;
handles.betaCurve = plot(handles.AB, betaData, 'b');
handles.betaAsymp = plot([0,5], propPar.beta_nom * [1 1], 'b--');
axis([0 5 1.2*propPar.beta_coppice (propPar.beta_nom+0.1)]);


% Set up rainfall growth curves.
axes(handles.rainGrowthAxes)
hold on
grid on
handles.rain = 0:10:1000;
xlabel('Yearly rainfall');
ylabel('Nominal \alpha and \beta');


A_rain_multiplier = propPar.alpha_nom / (propPar.nom_rain - propPar.A_sustaining_rainfall) ...
            / (propPar.nom_rain - 2*propPar.A_optimal_rainfall + propPar.A_sustaining_rainfall);    

alphaRainData = A_rain_multiplier * (handles.rain - propPar.A_sustaining_rainfall) .* ...
                    (handles.rain - 2 * propPar.A_optimal_rainfall + propPar.A_sustaining_rainfall);
handles.alphaRainCurve = plot(handles.rain, alphaRainData, 'Color', [0 0.8 0]);
handles.alphaNominalMarker = scatter(propPar.nom_rain, propPar.alpha_nom, 20, 'MarkerEdgeColor', [0 0.8 0], 'MarkerFaceColor',[0 0.8 0]);


B_rain_multiplier = propPar.beta_nom / (propPar.nom_rain - propPar.B_sustaining_rainfall) ...
            / (propPar.nom_rain - 2*propPar.B_optimal_rainfall + propPar.B_sustaining_rainfall);   
        
betaRainData = B_rain_multiplier * (handles.rain - propPar.B_sustaining_rainfall) .* ...
                    (handles.rain - 2 * propPar.B_optimal_rainfall + propPar.B_sustaining_rainfall);
handles.betaRainCurve = plot(handles.rain, betaRainData, 'Color', [0.8 0 0]);
handles.betaNominalMarker = scatter(propPar.nom_rain, propPar.beta_nom, 20, 'MarkerEdgeColor', [0.8 0 0], 'MarkerFaceColor',[0.8 0 0]);

guidata(handles.mainAxes, handles);

% Fill in the test area
set(handles.popupmenuTestPlantYear, 'Value', setupPar.plantYear);
set(handles.popupmenuTestCoppiceMonth, 'Value', setupPar.coppiceMonth);
set(handles.popupmenuTestPlantMonth, 'Value', setupPar.plantMonth);
set(handles.coppice_years_edit, 'Value', setupPar.coppiceYears);

handles.plotDetailFig = [];

% Set up coppicing sawtooth curves
plotCoppicedData(handles)


function initial_boost_edit_Callback(hObject, eventdata, handles)
% hObject    handle to initial_boost_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initial_boost_edit as text
%        str2double(get(hObject,'String')) returns contents of initial_boost_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    processBoostSection(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function initial_boost_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initial_boost_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function boost_half_life_edit_Callback(hObject, eventdata, handles)
% hObject    handle to boost_half_life_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of boost_half_life_edit as text
%        str2double(get(hObject,'String')) returns contents of boost_half_life_edit as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', ''); 
else
    processBoostSection(hObject, handles)
end


% --- Executes during object creation, after setting all properties.
function boost_half_life_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to boost_half_life_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%
% Adds the boost parameters to the prop params and redraws the coppice
% curve.
function processBoostSection(hObject, handles)
propPar = handles.gm.propagationParameters;

initialBoost = str2double(get(handles.initial_boost_edit, 'String'));
boostHalfLife = str2double(get(handles.boost_half_life_edit, 'String'));

if(all( [~isnan(initialBoost), ~isnan(initialBoost)]))
    
    propPar.initialBoost = initialBoost;
    propPar.boostHalfLife = boostHalfLife;
  
    handles.gm.propagationParameters = propPar;
    guidata(hObject, handles);
    
    plotCoppicedData(handles);      
end



function editCFIBuffer_Callback(hObject, eventdata, handles)
% hObject    handle to editCFIBuffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCFIBuffer as text
%        str2double(get(hObject,'String')) returns contents of editCFIBuffer as a double
n = str2double(get(hObject, 'String'));
if(isnan(n))
   set(hObject, 'String', num2str(handles.gm.propagationParameters.CFIBuffer)); 
else
    handles.gm.propagationParameters.CFIBuffer = n;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function editCFIBuffer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCFIBuffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxUseCFI.
function checkboxUseCFI_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseCFI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseCFI
handles.gm.propagationParameters.useCFI = get(hObject, 'Value');
guidata(hObject, handles);

% --- Executes on button press in checkboxUseBGBM.
function checkboxUseBGBM_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseBGBM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseBGBM
handles.gm.propagationParameters.useBGBM = get(hObject, 'Value');
guidata(hObject, handles);


% --- Executes on button press in checkboxUseCustomCost.
function checkboxUseCustomCost_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseCustomCost (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseCustomCost
handles.gm.propagationParameters.costParameters.useDensityBasedHarvestCost = get(hObject, 'Value');
guidata(hObject, handles);

% --- Executes on button press in pushbuttonSetupCustomCost.
function pushbuttonSetupCustomCost_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupCustomCost (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
useCustomCost = handles.gm.propagationParameters.costParameters.useDensityBasedHarvestCost;
cps = BeltCoppiceDensityCostGUI(handles.gm.propagationParameters.costParameters);
if(~isempty(cps))
    cps.useDensityBasedHarvestCost = useCustomCost;
    handles.gm.propagationParameters.costParameters = cps;
    guidata(hObject, handles);
end


% --- Executes on selection change in edit63.
function edit63_Callback(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit63 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit63


% --- Executes during object creation, after setting all properties.
function edit63_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton7.
function helpButton_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg = {'The Gompertz model requires specification of a growth rate, which is', ...
'basically how fast the plant reaches its maximum. In the AB-Gompertz ', ...
'model, we model the above and below ground parts seperately, but ', ...
'with the two parts affecting the growth of each other. The main aim of ', ...
'this approach is to simulate coppicing crops while keeping track of ', ...
'both parts of the biomass.', ...
'', ...
'To do this, we model the growth rate of each parts as a function of the', ...
'ratio of the biomass of each part. Ie, alpha, beta are functions of A/B. ', ...
'Rainfall also plays a part. This model treats rainfall as affecting the ', ...
'growth rate as a quadratic function of rainfall.'};

msgbox(msg, 'AB - Gompertz Growth Model Setup Help')


% --- Executes during object creation, after setting all properties.
function edit65_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coppice_years_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit66_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nom_rain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupmenuYieldUnit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuYieldUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTestPlantMonth.
function popupmenuTestPlantMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTestPlantMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTestPlantMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTestPlantMonth
handles.gm.setupParameters.plantMonth = get(hObject, 'Value');
global gompertzPlotData
gompertzPlotData.AGBM = [];
guidata(hObject, handles);

process_coppiced_section(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTestPlantMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTestPlantMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTestCoppiceMonth.
function popupmenuTestCoppiceMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTestCoppiceMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTestCoppiceMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTestCoppiceMonth
handles.gm.setupParameters.coppiceMonth = get(hObject, 'Value');

global gompertzPlotData
gompertzPlotData.AGBM = [];
guidata(hObject, handles);
process_coppiced_section(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTestCoppiceMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTestCoppiceMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTestPlantYear.
function popupmenuTestPlantYear_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTestPlantYear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTestPlantYear contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTestPlantYear
handles.gm.setupParameters.plantYear = get(hObject, 'Value');
guidata(hObject, handles);
global gompertzPlotData
gompertzPlotData.AGBM = [];

process_coppiced_section(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTestPlantYear_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTestPlantYear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in togglebuttonShowPlotDetail.
function togglebuttonShowPlotDetail_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonShowPlotDetail (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonShowPlotDetail
handles.gm.setupParameters.showPlotDetail = get(hObject, 'Value');
showPlotDetail = get(hObject, 'Value');

if (~showPlotDetail)
    if ~isempty(handles.plotDetailFig)
        close(handles.plotDetailFig);
        handles.plotDetailFig = [];
    end
end

guidata(hObject, handles);
plotCoppicedData(handles, true);
%process_coppiced_section(hObject, eventdata, handles);




% --- Executes on button press in pushbuttonRefreshPlotNominal.
function pushbuttonRefreshPlotNominal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefreshPlotNominal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.gm.setupParameters.usingStochasticRainModel = false;
guidata(hObject, handles);
process_coppiced_section(hObject, eventdata, handles);


% --- Executes on button press in pushbuttonRefreshPlotStochastic.
function pushbuttonRefreshPlotStochastic_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefreshPlotStochastic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.gm.setupParameters.usingStochasticRainModel = true;
guidata(hObject, handles);
process_coppiced_section(hObject, eventdata, handles);


% --- Executes on selection change in popupmenuYieldUnit.
function popupmenuYieldUnit_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuYieldUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuYieldUnit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuYieldUnit
units = get(hObject, 'String');
unitText = units(get(hObject, 'Value'));
if (strcmp(unitText, 'per Tree'))
    yu = Unit('', 'Tree', 'Unit');
elseif (strcmp(unitText, 'per Hectare of Effective Area'))
    yu = Unit('', 'Effective Area', 'Hectare');    
elseif (strcmp(unitText, 'per Hectare of Area'))
    yu = Unit('', 'Area', 'Hectare');    
elseif (strcmp(unitText, 'per Km of Belts'))
    yu = Unit('', 'Belts', 'Km');    
elseif (strcmp(unitText, 'per Km of Rows'))
    yu = Unit('', 'Rows', 'Km');    
else
    return;
end

handles.gm.yieldUnit = yu;
guidata(hObject, handles);
plotCoppicedData(handles);


% --- Executes on button press in pushbuttonEditRainfall.
function pushbuttonEditRainfall_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEditRainfall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

climateMgr = ClimateManager.getInstance();
climateMgr.editMonthlyRainfallParameters;
plotCoppicedData(handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ishandle(handles.plotDetailFig)
    close(handles.plotDetailFig);
end

% Hint: delete(hObject) closes the figure
delete(hObject);

function hidePlotDetail(hObject)
handles = guidata(hObject);
close(handles.plotDetailFig);
handles.plotDetailFig = [];
set(handles.togglebuttonShowPlotDetail, 'Value', 0);
handles.gm.setupParameters.showPlotDetail = false;
guidata(hObject, handles);


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extractPlotData(handles.figure1, true);
