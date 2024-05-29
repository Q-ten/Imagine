function varargout = nma_change_figure_units(varargin)
%GUI main for changing figure unit program

% NMA_CHANGE_FIGURE_UNITS M-file for nma_change_figure_units.fig
%      NMA_CHANGE_FIGURE_UNITS, by itself, creates a new NMA_CHANGE_FIGURE_UNITS or raises the existing
%      singleton*.
%
%      H = NMA_CHANGE_FIGURE_UNITS returns the handle to a new NMA_CHANGE_FIGURE_UNITS or the handle to
%      the existing singleton*.
%
%      NMA_CHANGE_FIGURE_UNITS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NMA_CHANGE_FIGURE_UNITS.M with the given input arguments.
%
%      NMA_CHANGE_FIGURE_UNITS('Property','Value',...) creates a new NMA_CHANGE_FIGURE_UNITS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nma_change_figure_units_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nma_change_figure_units_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% by Nasser M. Abbasi, updated May 18, 2011.
% Free to use at your own risk.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nma_change_figure_units

% Last Modified by GUIDE v2.5 18-Jul-2012 18:05:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @nma_change_figure_units_OpeningFcn, ...
    'gui_OutputFcn',  @nma_change_figure_units_OutputFcn, ...
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


% --- Executes just before nma_change_figure_units is made visible.
function nma_change_figure_units_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nma_change_figure_units (see VARARGIN)

% Choose default command line output for nma_change_figure_units
handles.output = hObject;
userData.fileName = '*.fig';
set(handles.figure1, 'UserData',userData);
set(handles.figure1,'Name','change_figure_units. March 20, 2011 version');
% Update handles structure

nma_set_figure_position(handles.figure1,0.25,0.3,0.46,0.2);

guidata(hObject, handles);

% UIWAIT makes nma_change_figure_units wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = nma_change_figure_units_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in open_tag.
function open_tag_Callback(hObject, eventdata, handles)
% hObject    handle to open_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1, 'UserData');
[fileName,pathName,filterIndex] = uigetfile('*.fig','Select the figure file to change');
if isequal(fileName,0)
    userData.fileName='*.fig';
    userData.pathName=pathName;
else
    userData.fileName=fullfile(pathName, fileName);
    userData.pathName=pathName;
end

set(handles.fig_file_name_tag,'String',userData.fileName);
set(handles.figure1, 'UserData',userData);

function fig_file_name_tag_Callback(hObject, eventdata, handles)
% hObject    handle to fig_file_name_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fig_file_name_tag as text
%        str2double(get(hObject,'String')) returns contents of fig_file_name_tag as a double


% --- Executes during object creation, after setting all properties.
function fig_file_name_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fig_file_name_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in make_changes_btn.
function make_changes_btn_Callback(hObject, eventdata, handles)
% hObject    handle to make_changes_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(handles.menu_tag,'String'));
to = contents{get(handles.menu_tag,'Value')};

[fileName, pathName, status] = getFileName(handles);
editFileName = get(handles.fig_file_name_tag, 'String');
userData.pathName=pathName;

k = findstr(pathName, editFileName);
if ~isempty(k)
    if (k == 1)
        fileName = editFileName(numel(pathName)+1:end);
        if any(strcmp(fileName, {'\*.fig', '*.fig'}))
            batch(to, handles);
            return
        end
    end
end
    
process(to,handles);

% --- Executes on selection change in menu_tag.
function menu_tag_Callback(hObject, eventdata, handles)
% hObject    handle to menu_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menu_tag contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menu_tag


% --- Executes during object creation, after setting all properties.
function menu_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menu_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%------------------
function  [fileName, pathName, status] = getFileName(handles)

status = false;
fileName = '';

userData = get(handles.figure1, 'UserData');
if strcmp(userData.fileName,'*.fig')
    uiwait(errordlg('Please open a valid fig file first','Bad Input', 'modal'));
    uicontrol(handles.fig_file_name_tag);
else
    fileName =  userData.fileName;
    pathName = userData.pathName;
    status = true;
end

%-------------
function [H,status] = getFigureHandle(fileName,handles)

H = 0;
status = false;

try
    H = hgload(fileName);
    if not(ishandle(H))
        uiwait(errordlg('Invalid handle. Looks like not a valid figure file?','Bad Input', 'modal'));
        uicontrol(handles.fig_file_name_tag);
    else
        status = true;
    end
catch ME
    uiwait(errordlg('Error calling hgload() on this file. Is this a valid fig file?','Bad Input', 'modal'));
    uicontrol(handles.fig_file_name_tag);
end

%--------------
function  changeUnits(H,to,fileName)

set(findall(H, '-property', 'Units'), 'Units', to);
%set(findall(H, '-property', 'FontUnits'),'FontName', 'FixedWidth', 'FontUnits', 'points','FontSize', 8);
set(findall(H, '-property', 'FontUnits'),'FontName', 'default');
set(findall(H, '-property', 'FontUnits'), 'FontSize', 8,'FontUnits', 'points');


hgsave(H, fileName,'all');
close(H);
%uiwait(msgbox('figure file update success','message','modal'));

%-----------------
function process(to,handles)

[fileName, pathName, status] = getFileName(handles);
if not(status)
    return;
end

here = pwd;

cd(pathName); %must be in the same folder

[H,status] = getFigureHandle(fileName,handles);
if not(status)
    return;
end

changeUnits(H,to,fileName);

cd(here);


function batch(to, handles)

[fileName, pathName, status] = getFileName(handles);

here = pwd;

cd(pathName); %must be in the same folder

contents = dir('*.fig'); % or whatever the filename extension is
for i = 1:numel(contents)
  filename = contents(i).name;

    [H,status] = getFigureHandle(filename,handles);
    if not(status)
        disp(['Did not change units in ', filename, '. Skipping...']);
        continue
    end

    try
            
    changeUnits(H,to,filename);
    disp(['Changed units in ', filename]);
    catch ME
        disp(ME.message);
    end
end

cd(here);

