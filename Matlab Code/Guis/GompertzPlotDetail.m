function varargout = GompertzPlotDetail(varargin)
% GOMPERTZPLOTDETAIL M-file for GompertzPlotDetail.fig
%      GOMPERTZPLOTDETAIL, by itself, creates a new GOMPERTZPLOTDETAIL or raises the existing
%      singleton*.
%
%      H = GOMPERTZPLOTDETAIL returns the handle to a new GOMPERTZPLOTDETAIL or the handle to
%      the existing singleton*.
%
%      GOMPERTZPLOTDETAIL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GOMPERTZPLOTDETAIL.M with the given input arguments.
%
%      GOMPERTZPLOTDETAIL('Property','Value',...) creates a new GOMPERTZPLOTDETAIL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GompertzPlotDetail_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GompertzPlotDetail_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GompertzPlotDetail

% Last Modified by GUIDE v2.5 18-Feb-2014 17:52:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GompertzPlotDetail_OpeningFcn, ...
                   'gui_OutputFcn',  @GompertzPlotDetail_OutputFcn, ...
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


% --- Executes just before GompertzPlotDetail is made visible.
function GompertzPlotDetail_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GompertzPlotDetail (see VARARGIN)

% Choose default command line output for GompertzPlotDetail
handles.output = hObject;

if nargin <= 3
    error('Need to pass in the window handle to the gompertz setup window.');
else
    handles.setupWindow = varargin{1};
end

   set(handles.pushbuttonClear, 'Visible', 'off');

% Update handles structure
guidata(hObject, handles);

update(hObject, handles);

% UIWAIT makes GompertzPlotDetail wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GompertzPlotDetail_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonRefresh.
function pushbuttonRefresh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global gompertzPlotData
if ~get(handles.checkboxAccumulateRuns, 'Value')
    gompertzPlotData.AGBM = [];    
end

GompertzGMDialogue('plotCoppicedData', guidata(handles.setupWindow), true);


% --- Executes on button press in checkboxGridLines.
function checkboxGridLines_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxGridLines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxGridLines
setGridLines(handles);

% --- Executes on button press in checkboxAccumulateRuns.
function checkboxAccumulateRuns_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAccumulateRuns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAccumulateRuns
if get(hObject, 'Value')
   set(handles.pushbuttonRefresh, 'String', 'Add Another Run'); 
   set(handles.pushbuttonClear, 'Visible', 'on');
else
   set(handles.pushbuttonRefresh, 'String', 'Refresh');     
   set(handles.pushbuttonClear, 'Visible', 'off');
end

% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in pushbuttonClear.
function pushbuttonClear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global gompertzPlotData
axes(handles.detailAxes);
cla;
gompertzPlotData.AGBM = [];

function update(hObject, handles)

global gompertzPlotData
axes(handles.detailAxes)
cla;
hold on

setGridLines(handles);

if get(handles.checkboxAccumulateRuns, 'Value')
    start = 1;
else
    start = size(gompertzPlotData.AGBM, 1);
end

for i = start:size(gompertzPlotData.AGBM, 1)
    plot(gompertzPlotData.coppiceT, gompertzPlotData.BGBM(i, :), 'Color', [0.8 0 0]);
    plot(gompertzPlotData.coppiceT, gompertzPlotData.AGBM(i, :), 'Color', [0 0.8 0]);
end

function setGridLines(handles)

axes(handles.detailAxes);
if get(handles.checkboxGridLines, 'Value')
    grid on;
else
    grid off;
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isfield(handles, 'setupWindow')
    if ishandle(handles.setupWindow)
        GompertzGMDialogue('hidePlotDetail', handles.setupWindow) 
    end
end
if ishandle(hObject)
    delete(hObject)
end

% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

extractPlotData(handles.figure1, true);
