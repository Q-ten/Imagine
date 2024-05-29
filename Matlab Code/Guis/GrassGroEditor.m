function varargout = GrassGroEditor(varargin)
% GRASSGROEDITOR M-file for GrassGroEditor.fig
%      GRASSGROEDITOR, by itself, creates a new GRASSGROEDITOR or raises the existing
%      singleton*.
%
%      H = GRASSGROEDITOR returns the handle to a new GRASSGROEDITOR or the handle to
%      the existing singleton*.
%
%      GRASSGROEDITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRASSGROEDITOR.M with the given input arguments.
%
%      GRASSGROEDITOR('Property','Value',...) creates a new GRASSGROEDITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GrassGroEditor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GrassGroEditor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GrassGroEditor

% Last Modified by GUIDE v2.5 08-Oct-2012 08:33:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GrassGroEditor_OpeningFcn, ...
                   'gui_OutputFcn',  @GrassGroEditor_OutputFcn, ...
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


% --- Executes just before GrassGroEditor is made visible.
function GrassGroEditor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GrassGroEditor (see VARARGIN)

% Need to guarantee that the first item is a GrassGroModel.
ggm = GrassGroModel;
if nargin > 3   
    ggm = ggm.copyFields(varargin{1});
end

set(handles.listboxSections, 'String', [ggm.classBasedHeaders, 'Yearly Attributions', 'Monthly Supplement Cost']);

handles.ggm = ggm;

% Choose default command line output for GrassGroEditor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

listboxSections_Callback(handles.listboxSections,[] , handles);


% UIWAIT makes GrassGroEditor wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GrassGroEditor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

% --- Executes on selection change in listboxSections.
function listboxSections_Callback(hObject, eventdata, handles)
% hObject    handle to listboxSections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxSections contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxSections

% Populate the table with the contents of the selected section.
ggm = handles.ggm;
index = get(hObject, 'Value');
data = [];
rowsAreMonths = true;
if index <= length(ggm.classBasedHeaders)
    data = ggm.dataByClass(:, index, :);
    data = reshape(data, size(data, 1), size(data, 3));
    set(handles.uitableData, 'ColumnName', ggm.sheepClassNames);
elseif index == length(ggm.classBasedHeaders) + 1
    data = ggm.yearlyAttributions;
    headers = {};
    for i = 1:size(ggm.yearlyAttributions, 2)
        headers{i} = ['Paddock ', num2str(i)];
    end
    rowsAreMonths = false;
    set(handles.uitableData, 'ColumnName', headers);    
elseif index == length(ggm.classBasedHeaders) + 2
    data = ggm.monthlySupplementCost;
    set(handles.uitableData, 'ColumnName', {'Month Index'});    
end
set(handles.uitableData, 'Data', data);

if rowsAreMonths
   set(handles.textRowExplanation, 'String', 'Rows indicate MONTH index'); 
else
   set(handles.textRowExplanation, 'String', 'Rows indicate YEAR index');     
end

% Could look at resizing the table or the columns...

% --- Executes during object creation, after setting all properties.
function listboxSections_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxSections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonImportTool.
function pushbuttonImportTool_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImportTool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ggm = handles.ggm;
index = get(handles.listboxSections, 'Value');
data = [];
headers = {};
title = '';
if index <= length(ggm.classBasedHeaders)
    data = ggm.dataByClass(:, index, :);
    data = reshape(data, size(data, 1), size(data, 3));
    headers = ggm.sheepClassNames;
    title = ggm.classBasedHeaders{index};
elseif index == length(ggm.classBasedHeaders) + 1
    title = 'Yearly Attributions';
    data = ggm.yearlyAttributions;
    headers = {};
    for i = 1:size(ggm.yearlyAttributions, 2)
        headers{i} = ['Paddock', num2str(i)];
    end
elseif index == length(ggm.classBasedHeaders) + 2
    title = 'Monthly Supplement Costs';
    data = ggm.monthlySupplementCost;
    headers = {'Month Index'};               
else
    return    
end
data = SeriesImportTool(data, title, headers);

if ~isempty(data)
    if index <= length(ggm.classBasedHeaders)
        ggm.dataByClass(:, index, :) = data;    
    elseif index == length(ggm.classBasedHeaders) + 1
        ggm.yearlyAttributions = data;    
    elseif index == length(ggm.classBasedHeaders) + 2
        ggm.monthlySupplementCost = data;    
    end
    handles.ggm = ggm;
    guidata(hObject, handles);
    set(handles.uitableData, 'Data', data);
end


% --- Executes on button press in pushbuttonOk.
function pushbuttonOk_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = handles.ggm;
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
