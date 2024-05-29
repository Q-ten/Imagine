function varargout = conditionPanel_MonthBased(varargin)
% CONDITIONPANEL_MONTHBASED MATLAB code for conditionPanel_MonthBased.fig
%      CONDITIONPANEL_MONTHBASED, by itself, creates a new CONDITIONPANEL_MONTHBASED or raises the existing
%      singleton*.
%
%      H = CONDITIONPANEL_MONTHBASED returns the handle to a new CONDITIONPANEL_MONTHBASED or the handle to
%      the existing singleton*.
%
%      CONDITIONPANEL_MONTHBASED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONDITIONPANEL_MONTHBASED.M with the given input arguments.
%
%      CONDITIONPANEL_MONTHBASED('Property','Value',...) creates a new CONDITIONPANEL_MONTHBASED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before conditionPanel_MonthBased_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to conditionPanel_MonthBased_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help conditionPanel_MonthBased

% Last Modified by GUIDE v2.5 26-Jul-2013 02:48:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @conditionPanel_MonthBased_OpeningFcn, ...
                   'gui_OutputFcn',  @conditionPanel_MonthBased_OutputFcn, ...
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


% --- Executes just before conditionPanel_MonthBased is made visible.
function conditionPanel_MonthBased_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to conditionPanel_MonthBased (see VARARGIN)

% Choose default command line output for conditionPanel_MonthBased
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes conditionPanel_MonthBased wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = conditionPanel_MonthBased_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenuMonthChoice.
function popupmenuMonthChoice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMonthChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMonthChoice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMonthChoice


% --- Executes during object creation, after setting all properties.
function popupmenuMonthChoice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMonthChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in editIndices.
function editIndices_Callback(hObject, eventdata, handles)
% hObject    handle to editIndices (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns editIndices contents as cell array
%        contents{get(hObject,'Value')} returns selected item from editIndices


% --- Executes during object creation, after setting all properties.
function editIndices_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIndices (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
