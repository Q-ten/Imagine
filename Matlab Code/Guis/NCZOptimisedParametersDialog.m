function varargout = NCZOptimisedParametersDialog(varargin)
% NCZOPTIMISEDPARAMETERSDIALOG M-file for NCZOptimisedParametersDialog.fig
%      NCZOPTIMISEDPARAMETERSDIALOG, by itself, creates a new NCZOPTIMISEDPARAMETERSDIALOG or raises the existing
%      singleton*.
%
%      H = NCZOPTIMISEDPARAMETERSDIALOG returns the handle to a new NCZOPTIMISEDPARAMETERSDIALOG or the handle to
%      the existing singleton*.
%
%      NCZOPTIMISEDPARAMETERSDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NCZOPTIMISEDPARAMETERSDIALOG.M with the given input arguments.
%
%      NCZOPTIMISEDPARAMETERSDIALOG('Property','Value',...) creates a new NCZOPTIMISEDPARAMETERSDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NCZOptimisedParametersDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NCZOptimisedParametersDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NCZOptimisedParametersDialog

% Last Modified by GUIDE v2.5 18-Feb-2014 17:51:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NCZOptimisedParametersDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @NCZOptimisedParametersDialog_OutputFcn, ...
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


% --- Executes just before NCZOptimisedParametersDialog is made visible.
function NCZOptimisedParametersDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NCZOptimisedParametersDialog (see VARARGIN)

% Choose default command line output for NCZOptimisedParametersDialog
handles.output = hObject;
handles.rainfallRange = setRainfallRange(false);

if nargin < 4
    handles.cropInfo.cropName = 'Test Crop';
    handles.cropInfo.cropYieldUnits = 't / Ha';
%   error('Must pass at least one argument to the NCZOptimisedParametersDialog. The first argument should have fields for cropName and cropYieldUnits.');
else
   handles.cropInfo = varargin{1};
end

handles.params = NCZOptimisedParameters();
handles.params.polyA = -2.5e-5;
handles.params.polyB = 0.02;
handles.params.polyC = -0.2;

if (nargin >= 5)
    params = varargin{2};
    if isempty(params)
        params = handles.params;
    end
else
    params = handles.params;
end
    
paramsList = {'preSeedingRainfallMonths', 'polyA', 'polyB', 'polyC', 'polynomialPredictiveCapacity', 'longTermAverageYield', 'longTermAverageCosts'};

fieldNamesIn = fieldnames(params);
for i = 1:length(paramsList)
   ix = find(strcmp(fieldNamesIn, paramsList{i}), 1, 'first');
   if ~isempty(ix)
       % Then overwrite the default parameters with what is provided in
       % the input argument.
       handles.(paramsList{i}) = params.(paramsList{i});
    end
end

% invert polyA so it works. polyA needs to be negative, but we only deal
% with the positive A in here. So we need the positive part to be saved.
handles.polyA = -handles.polyA;

% Update handles structure
guidata(hObject, handles);

% Setup the controls based on the NCZOptimised parameters that have come
% in.
setupControls(handles);

% UIWAIT makes NCZOptimisedParametersDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = NCZOptimisedParametersDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = populateParams(handles);
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);



function popupmenuPreSeedingRainfallMonths_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPreSeedingRainfallMonths (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenuPreSeedingRainfallMonths as text
%        str2double(get(hObject,'String')) returns contents of popupmenuPreSeedingRainfallMonths as a double
newNum = get(hObject, 'Value');
handles.preSeedingRainfallMonths = newNum;
guidata(hObject, handles);
updateYieldCurve(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuPreSeedingRainfallMonths_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPreSeedingRainfallMonths (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLongTermAverageYield_Callback(hObject, eventdata, handles)
% hObject    handle to editLongTermAverageYield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLongTermAverageYield as text
%        str2double(get(hObject,'String')) returns contents of editLongTermAverageYield as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.longTermAverageYield = newNum;
        guidata(hObject, handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.longTermAverageYield));
end

% --- Executes during object creation, after setting all properties.
function editLongTermAverageYield_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLongTermAverageYield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPredictiveCapacity_Callback(hObject, eventdata, handles)
% hObject    handle to editPredictiveCapacity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPredictiveCapacity as text
%        str2double(get(hObject,'String')) returns contents of editPredictiveCapacity as a double
newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum >= 0 && newNum <= 100
        handles.polynomialPredictiveCapacity = newNum / 100;
        guidata(hObject, handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.polynomialPredictiveCapacity * 100));
end

% --- Executes during object creation, after setting all properties.
function editPredictiveCapacity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPredictiveCapacity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPolyA_Callback(hObject, eventdata, handles)
% hObject    handle to editPolyA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPolyA as text
%        str2double(get(hObject,'String')) returns contents of editPolyA as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function editPolyA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPolyA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPolyB_Callback(hObject, eventdata, handles)
% hObject    handle to editPolyB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPolyB as text
%        str2double(get(hObject,'String')) returns contents of editPolyB as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function editPolyB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPolyB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPolyC_Callback(hObject, eventdata, handles)
% hObject    handle to editPolyC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPolyC as text
%        str2double(get(hObject,'String')) returns contents of editPolyC as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)

% --- Executes during object creation, after setting all properties.
function editPolyC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPolyC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonEditCurve.
function pushbuttonEditCurve_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEditCurve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
but = 1;

xpoints = [0 handles.rainfallRange / 2 handles.rainfallRange];

% Get the numbers A,B,C
A = str2double(get(handles.editPolyA, 'String'));
B = str2double(get(handles.editPolyB, 'String'));
C = str2double(get(handles.editPolyC, 'String'));

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

% This function updates the plot with rainfall based data
function updateYieldCurve(handles)

if(isempty(handles.xpoints) || isempty(handles.ypoints))

    % Get the numbers A,B,C
    A = str2double(get(handles.editPolyA, 'String'));
    B = str2double(get(handles.editPolyB, 'String'));
    C = str2double(get(handles.editPolyC, 'String'));

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
end

handles.polyA = -p(1);
handles.polyB = p(2);
handles.polyC = p(3);
guidata(handles.axes1, handles);

set(handles.editPolyA, 'String', -p(1));
set(handles.editPolyB, 'String',  p(2));
set(handles.editPolyC, 'String',  p(3));

t = [0:handles.rainfallRange];
y = polyval(p, t);

hold on
axes(handles.axes1);
set(handles.plo, 'XData', t);
set(handles.plo, 'YData', y);

set(handles.sc, 'XData', handles.xpoints);
set(handles.sc, 'YData', handles.ypoints);
%axis([0 500 0 max(y) * 1.2])
axis([0 handles.rainfallRange 0 max(y) * 1.2]);

xlabel({'Pre-Seeding Rainfall (mm)'; ['Over ', num2str(handles.preSeedingRainfallMonths), ' months']});
ylabel(['Expected Yield (',handles.cropInfo.cropYieldUnits,')']);


% Sets up the controls based on what is in handles.
function setupControls(handles)


% Set up plot data
handles.xpoints = [];
handles.ypoints = [];

axes(handles.axes1);
hold on
handles.sc = scatter([-1],[-1], 25, 'b');
handles.plo = plot([0], [0]);


set(handles.textCover, 'String', '');
set(handles.textCropName, 'String', handles.cropInfo.cropName);
set(handles.textLTAUnits, 'String', ['(', handles.cropInfo.cropYieldUnits, '):']);

% popupmenuPreSeedingRainfallMonths pre-populated with values 1:6. Value
% gives the month.
set(handles.popupmenuPreSeedingRainfallMonths, 'Value', handles.preSeedingRainfallMonths);
set(handles.editPredictiveCapacity, 'String', num2str(handles.polynomialPredictiveCapacity * 100));
set(handles.editLongTermAverageYield, 'String', num2str(handles.longTermAverageYield));
set(handles.editLongTermAverageCosts, 'String', num2str(handles.longTermAverageCosts));

set(handles.editPolyA, 'String', num2str(handles.polyA));
set(handles.editPolyB, 'String', num2str(handles.polyB));
set(handles.editPolyC, 'String', num2str(handles.polyC));

updateYieldCurve(handles);



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
pushbuttonCancel_Callback(hObject, eventdata, handles);

function params = populateParams(handles)

params = handles.params;

paramsList = {'preSeedingRainfallMonths', 'polyA', 'polyB', 'polyC', 'polynomialPredictiveCapacity', 'longTermAverageYield', 'longTermAverageCosts'};

fieldNamesIn = fieldnames(params);
for i = 1:length(paramsList)
   ix = find(strcmp(fieldNamesIn, paramsList{i}), 1, 'first');
   if ~isempty(ix)
       % Then overwrite the default parameters with what is provided in
       % the input argument.
       params.(paramsList{i}) = handles.(paramsList{i});
    end
end

params.polyA = -params.polyA;


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.rainfallRange = setRainfallRange(true);
axes(handles.axes1)
a = axis;
axis([0 handles.rainfallRange 0 a(4)]);
guidata(hObject, handles)
updateYieldCurve(handles);

function range = setRainfallRange(askForRange)

persistent rainfallRange
if isempty(rainfallRange)
    rainfallRange = 150;
end
range = rainfallRange;
    
if (askForRange)
    result = inputdlg('Enter max pre-seeding rainfall to show on graph:', 'Set Rainfall Range');
    if isempty(result)
        return
    else
        num = str2num(result{1});
        if ~isnan(num)
           if num > 0 && num < 1000
            rainfallRange = num;
           end
        end
    end
end

range = rainfallRange;



function editLongTermAverageCosts_Callback(hObject, eventdata, handles)
% hObject    handle to editLongTermAverageCosts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLongTermAverageCosts as text
%        str2double(get(hObject,'String')) returns contents of editLongTermAverageCosts as a double

newNum = str2double(get(hObject, 'String'));
reset = false;
if ~isnan(newNum)
    if newNum > 0
        handles.longTermAverageCosts = newNum;
        guidata(hObject, handles);
        reset = true;
    end    
end
if ~reset
   % Load the saved value again.
   set(hObject, 'String', num2str(handles.longTermAverageCosts));
end


% --- Executes during object creation, after setting all properties.
function editLongTermAverageCosts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLongTermAverageCosts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

extractPlotData(handles.figure1, true);
