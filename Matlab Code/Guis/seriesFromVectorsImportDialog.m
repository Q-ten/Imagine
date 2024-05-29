function varargout = seriesFromVectorsImportDialog(varargin)
% SERIESFROMVECTORSIMPORTDIALOG M-file for seriesFromVectorsImportDialog.fig
%      SERIESFROMVECTORSIMPORTDIALOG, by itself, creates a new SERIESFROMVECTORSIMPORTDIALOG or raises the existing
%      singleton*.
%
%      H = SERIESFROMVECTORSIMPORTDIALOG returns the handle to a new SERIESFROMVECTORSIMPORTDIALOG or the handle to
%      the existing singleton*.
%
%      SERIESFROMVECTORSIMPORTDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SERIESFROMVECTORSIMPORTDIALOG.M with the given input arguments.
%
%      SERIESFROMVECTORSIMPORTDIALOG('Property','Value',...) creates a new SERIESFROMVECTORSIMPORTDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before seriesFromVectorsImportDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to seriesFromVectorsImportDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help seriesFromVectorsImportDialog

% Last Modified by GUIDE v2.5 02-Feb-2012 13:39:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @seriesFromVectorsImportDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @seriesFromVectorsImportDialog_OutputFcn, ...
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


% --- Executes just before seriesFromVectorsImportDialog is made visible.
function seriesFromVectorsImportDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to seriesFromVectorsImportDialog (see VARARGIN)

% Choose default command line output for seriesFromVectorsImportDialog
handles.output = hObject;


if nargin < 4
    error('Must provide a structure from which to extract the series.');
    close(gcf);
else
    S = varargin{1};
    handles.S = S;
    if ~isstruct(S)
        error('Must provide a structure from which to extract the series.');
        close(gcf);
    end
end

fns = fieldnames(S);
handles.fns = fns;
set(handles.listboxVariables, 'String', fns);
set(handles.listboxVariables, 'Value', 1);

% Update handles structure
guidata(hObject, handles);

listboxVariables_Callback(handles.listboxVariables, [], handles);

% UIWAIT makes seriesFromVectorsImportDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = seriesFromVectorsImportDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varIndex = get(handles.listboxVariables, 'Value');
series = [];

for i = 1:length(varIndex)
    varName = handles.fns{varIndex(i)};
    var = handles.S.(varName);
    series.(varName) = var;
end
    
varargout{1} = series;

delete(handles.figure1);

% --- Executes on selection change in listboxVariables.
function listboxVariables_Callback(hObject, eventdata, handles)
% hObject    handle to listboxVariables (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxVariables contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxVariables

% load the column and transposed data into those controls.
varIndex = get(handles.listboxVariables, 'Value');
data = [];

for i = 1:length(varIndex)
    varName = handles.fns{varIndex(i)};
    cnames{i} = varName;
    var = handles.S.(varName);
    data(1:length(var), i) = var;
end
    
set(handles.uitable1, 'Data', data, 'ColumnName', cnames);

% --- Executes during object creation, after setting all properties.
function listboxVariables_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxVariables (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listboxVariables, 'Value', []);
guiata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);
