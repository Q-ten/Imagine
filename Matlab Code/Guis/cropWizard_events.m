function varargout = cropWizard_events(varargin)
% CROPWIZARD_EVENTS M-file for cropWizard_events.fig
%      CROPWIZARD_EVENTS, by itself, creates a new CROPWIZARD_EVENTS or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_EVENTS returns the handle to a new CROPWIZARD_EVENTS or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_EVENTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_EVENTS.M with the given input arguments.
%
%      CROPWIZARD_EVENTS('Property','Value',...) creates a new CROPWIZARD_EVENTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_events_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_events_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_events

% Last Modified by GUIDE v2.5 16-Nov-2011 12:53:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_events_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_events_OutputFcn, ...
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


% --- Executes just before cropWizard_events is made visible.
function cropWizard_events_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_events (see VARARGIN)

% Choose default command line output for cropWizard_events
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes cropWizard_events wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_events_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function cropNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cropNameEdit as text
%        str2double(get(hObject,'String')) returns contents of cropNameEdit as a double


% --- Executes during object creation, after setting all properties.
function cropNameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in categoryDDL.
function categoryDDL_Callback(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns categoryDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from categoryDDL


% --- Executes during object creation, after setting all properties.
function categoryDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeColourButton.
function changeColourButton_Callback(hObject, eventdata, handles)
% hObject    handle to changeColourButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in eventListBox.
function eventListBox_Callback(hObject, eventdata, handles)
% hObject    handle to eventListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns eventListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventListBox


% --- Executes during object creation, after setting all properties.
function eventListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in transitionFunctionDDL.
function transitionFunctionDDL_Callback(hObject, eventdata, handles)
% hObject    handle to transitionFunctionDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns transitionFunctionDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from transitionFunctionDDL


% --- Executes during object creation, after setting all properties.
function transitionFunctionDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transitionFunctionDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in outputFunctionDDL.
function outputFunctionDDL_Callback(hObject, eventdata, handles)
% hObject    handle to outputFunctionDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns outputFunctionDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from outputFunctionDDL


% --- Executes during object creation, after setting all properties.
function outputFunctionDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputFunctionDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in eventProductListBox.
function eventProductListBox_Callback(hObject, eventdata, handles)
% hObject    handle to eventProductListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns eventProductListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventProductListBox


% --- Executes during object creation, after setting all properties.
function eventProductListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventProductListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function newProductNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to newProductNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of newProductNameEdit as text
%        str2double(get(hObject,'String')) returns contents of newProductNameEdit as a double


% --- Executes during object creation, after setting all properties.
function newProductNameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to newProductNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setCustomNameButton.
function setCustomNameButton_Callback(hObject, eventdata, handles)
% hObject    handle to setCustomNameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in cropProductListBox.
function cropProductListBox_Callback(hObject, eventdata, handles)
% hObject    handle to cropProductListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns cropProductListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cropProductListBox


% --- Executes during object creation, after setting all properties.
function cropProductListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropProductListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% Populates the event setup for the event mapped to the index argument.
% Populates with data from the datastructure if it exists.

function populateEventSetup(hObject, handles, index)
