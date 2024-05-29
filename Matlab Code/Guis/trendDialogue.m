function varargout = trendDialogue(varargin)
% TRENDDIALOGUE M-file for trendDialogue.fig
%      TRENDDIALOGUE, by itself, creates a new TRENDDIALOGUE or raises the existing
%      singleton*.
%
%      H = TRENDDIALOGUE returns the handle to a new TRENDDIALOGUE or the handle to
%      the existing singleton*.
%
%      TRENDDIALOGUE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRENDDIALOGUE.M with the given input arguments.
%
%      TRENDDIALOGUE('Property','Value',...) creates a new TRENDDIALOGUE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trendDialogue_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trendDialogue_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trendDialogue

% Last Modified by GUIDE v2.5 12-Jan-2013 14:57:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trendDialogue_OpeningFcn, ...
                   'gui_OutputFcn',  @trendDialogue_OutputFcn, ...
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


% --- Executes just before trendDialogue is made visible.
function trendDialogue_OpeningFcn(hObject, eventdata, subHandles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trendDialogue (see VARARGIN)

% We assume that handles.trendData has already got a trend in in. If not,
% put one in and save it.
handles = guidata(hObject);

if isfield(handles, 'trendData')
    if ~isa(handles.trendData.trend, 'Trend')
        handles.trendData.trend = Trend();
        guidata(hObject, handles);
    end
else
    handles.trendData.trend = Trend();
    guidata(hObject, handles);
end
    
loadTrendData(handles);


% --- Outputs from this function are returned to the command line.
function varargout = trendDialogue_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles;


% --- Executes on selection change in varTypeDDL.
function varTypeDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to varTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns varTypeDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from varTypeDDL
list = get(hObject,'String');
listItem = list{get(hObject,'Value')};

if strcmp(listItem, 'Yearly Data')
    set(subHandles.varImportButton, 'Enable', 'on');    
    set(subHandles.textVarInstructions, 'String', 'You must define the mean value for every year.');
else
    set(subHandles.varImportButton, 'Enable', 'off');
    set(subHandles.textVarInstructions, 'String', {'You must define the coefficients of the polynomial'; 'that describes the mean for every year.'});
end

handles = guidata(subHandles.trendAxes);
handles.trendData.trend.varType = listItem;
guidata(subHandles.trendAxes, handles);
loadTrendData(subHandles);

% --- Executes during object creation, after setting all properties.
function varTypeDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function varDataEdit_Callback(hObject, eventdata, subHandles)
% hObject    handle to varDataEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveTrendData(subHandles);
refreshTrendGraph(subHandles);

% --- Executes on key press with focus on varDataEdit and none of its controls.
function varDataEdit_KeyPressFcn(hObject, eventdata, subHandles)
% hObject    handle to varDataEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Key, 'enter')
   saveTrendData(subHandles);
   refreshTrendGraph(subHandles);
end


% --- Executes during object creation, after setting all properties.
function varDataEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varDataEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in varImportButton.
function varImportButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to varImportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);
handles.trendData.trend.importVarData;
guidata(hObject, handles);

loadTrendData(subHandles);

% --- Executes on selection change in trendTypeDDL.
function trendTypeDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to trendTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns trendTypeDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trendTypeDDL
list = get(hObject,'String');
listItem = list{get(hObject,'Value')};

if strcmp(listItem, 'Yearly Data')
    set(subHandles.trendImportButton, 'Enable', 'on');
    set(subHandles.textTrendInstructions, 'String', 'You must define the mean value for every year.');
else
    set(subHandles.trendImportButton, 'Enable', 'off');
    set(subHandles.textTrendInstructions, 'String', {'You must define the coefficients of the polynomial'; 'that describes the mean for every year.'});
end
handles = guidata(subHandles.trendAxes);
handles.trendData.trend.trendType = listItem;
guidata(subHandles.trendAxes, handles);
loadTrendData(subHandles);


% --- Executes during object creation, after setting all properties.
function trendTypeDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trendTypeDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function trendDataEdit_Callback(hObject, eventdata, subHandles)
% hObject    handle to trendDataEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Editting trend data');
saveTrendData(subHandles);
refreshTrendGraph(subHandles);
   
% --- Executes on key press with focus on trendDataEdit and none of its controls.
function trendDataEdit_KeyPressFcn(hObject, eventdata, subHandles)
% hObject    handle to trendDataEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Key, 'enter')
   saveTrendData(subHandles);
   refreshTrendGraph(subHandles);
end

% --- Executes during object creation, after setting all properties.
function trendDataEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trendDataEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in trendImportButton.
function trendImportButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to trendImportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);
handles.trendData.trend.importTrendData;
guidata(hObject, handles);

loadTrendData(subHandles);

    
% --- Executes on button press in refreshButton.
function refreshButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to refreshButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

refreshTrendGraph(subHandles);

    
% Populates the gui trend with whatever is in trend. Set the graph as well.
function loadTrendData(subHandles)
handles = guidata(subHandles.trendAxes);
trend = handles.trendData.trend;

% set(subHandles.trendDataEdit, 'String', '');
% set(subHandles.varDataEdit, 'String', '');

set(subHandles.trendDataEdit, 'String', num2str(trend.trendData));
set(subHandles.varDataEdit, 'String', num2str(trend.varData));

trendTypes = get(subHandles.trendTypeDDL, 'String');
index = find(strcmp(trendTypes, trend.trendType));
set(subHandles.trendTypeDDL, 'Value', index);

varTypes = get(subHandles.varTypeDDL, 'String');
index = find(strcmp(varTypes, trend.varType));
set(subHandles.varTypeDDL, 'Value', index);    

saveTrendData(subHandles);
refreshTrendGraph(subHandles);    


% Gets the trend from trendData and draws the graph if the trend is valid.
function refreshTrendGraph(subHandles)
handles = guidata(subHandles.trendAxes);
trend = handles.trendData.trend;

if Trend.isValid(trend)
    %Hack:
    simLength = 50;

    [m,v,s] = trend.createTrendSeries(simLength);

    axes(subHandles.trendAxes);
    cla
    hold on
    t = 1:simLength;
    bar(s, 'FaceColor', [0.5 0.5 1], 'EdgeColor', [0.4 0.4 0.6], 'BarWidth', 0.9);
    plot(t, m, 'r-', t, m + v, 'g--', t, m - v, 'g--', 'LineWidth', 2);
    set(subHandles.trendAxes, 'XLim', [0 simLength + 1]);
else
    axes(subHandles.trendAxes);
    cla
    %msgbox('Trend data not valid. Please enter data again', 'Bad Trend Data', 'warn'); 
end



% Save the trend data in the gui into the trendData field of handles.
% If the gui data is not valid, replace it with the old data.
function valid = saveTrendData(subHandles)

    handles = guidata(subHandles.trendAxes);
    trend = handles.trendData.trend;

    ddlList = get(subHandles.trendTypeDDL, 'String');
    trend.trendType = ddlList{get(subHandles.trendTypeDDL, 'Value')};

    try 
        trend.trendData = eval(['[', get(subHandles.trendDataEdit, 'String'), ']']);
    catch e
        %If is throws an exception, the edit cannot be evaulated as is. Undo
        %what was done.
        set(subHandles.trendDataEdit, 'String', num2str(trend.trendData));
    end

    ddlList = get(subHandles.varTypeDDL, 'String');
    trend.varType = ddlList{get(subHandles.varTypeDDL, 'Value')};
 
    try 
        trend.varData = eval(['[', get(subHandles.varDataEdit, 'String'), ']']);
    catch e
        %If is throws an exception, the edit cannot be evaulated as is. Undo
        %what was done.
        set(subHandles.varDataEdit, 'String', num2str(trend.varData));
    end
    
    handles.trendData.trend = trend;
    guidata(subHandles.trendAxes, handles);
    
    valid = Trend.isValid(trend);

    % The trendData that is passed in may have a 'saveNotifier' field of
    % type savenotifier.
    if isfield(handles.trendData, 'saveNotifier')
        if isa(handles.trendData.saveNotifier, 'saveNotifier')
            handles.trendData.saveNotifier.sendSaveNotification();
        end
    end
    
    
