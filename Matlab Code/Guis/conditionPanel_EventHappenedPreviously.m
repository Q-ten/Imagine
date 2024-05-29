function varargout = conditionPanel_EventHappenedPreviously(varargin)
% CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY MATLAB code for conditionPanel_EventHappenedPreviously.fig
%      CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY, by itself, creates a new CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY or raises the existing
%      singleton*.
%
%      H = CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY returns the handle to a new CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY or the handle to
%      the existing singleton*.
%
%      CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY.M with the given input arguments.
%
%      CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY('Property','Value',...) creates a new CONDITIONPANEL_EVENTHAPPENEDPREVIOUSLY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before conditionPanel_EventHappenedPreviously_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to conditionPanel_EventHappenedPreviously_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help conditionPanel_EventHappenedPreviously

% Last Modified by GUIDE v2.5 25-Jul-2013 13:28:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @conditionPanel_EventHappenedPreviously_OpeningFcn, ...
                   'gui_OutputFcn',  @conditionPanel_EventHappenedPreviously_OutputFcn, ...
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


% --- Executes just before conditionPanel_EventHappenedPreviously is made visible.
function conditionPanel_EventHappenedPreviously_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to conditionPanel_EventHappenedPreviously (see VARARGIN)

% Choose default command line output for conditionPanel_EventHappenedPreviously
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes conditionPanel_EventHappenedPreviously wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = conditionPanel_EventHappenedPreviously_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenuEventChoice.
function popupmenuEventChoice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuEventChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuEventChoice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuEventChoice


% --- Executes during object creation, after setting all properties.
function popupmenuEventChoice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuEventChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on selection change in popupmenuComparator.
function popupmenuComparator_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuComparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuComparator contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuComparator


% --- Executes during object creation, after setting all properties.
function popupmenuComparator_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuComparator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMonthsPrior_Callback(hObject, eventdata, handles)
% hObject    handle to editMonthsPrior (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMonthsPrior as text
%        str2double(get(hObject,'String')) returns contents of editMonthsPrior as a double
user_entry = str2num(get(hObject,'String'));
ehpc = EventHappenedPreviouslyCondition('');
if any(isnan(user_entry))
    set(hObject, 'String', num2str(handles.(ehpc.handlesField).data.monthsPrior));
	return
end
if any(user_entry < 0)
    user_entry = user_entry(user_entry >= 0);
    set(hObject, 'String', num2str(user_entry));
end
handles.(ehpc.handlesField).data.monthsPrior = user_entry;

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editMonthsPrior_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMonthsPrior (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
