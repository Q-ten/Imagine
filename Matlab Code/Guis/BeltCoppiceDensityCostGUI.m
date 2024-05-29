function varargout = BeltCoppiceDensityCostGUI(varargin)
% BELTCOPPICEDENSITYCOSTGUI M-file for BeltCoppiceDensityCostGUI.fig
%      BELTCOPPICEDENSITYCOSTGUI, by itself, creates a new BELTCOPPICEDENSITYCOSTGUI or raises the existing
%      singleton*.
%
%      H = BELTCOPPICEDENSITYCOSTGUI returns the handle to a new BELTCOPPICEDENSITYCOSTGUI or the handle to
%      the existing singleton*.
%
%      BELTCOPPICEDENSITYCOSTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BELTCOPPICEDENSITYCOSTGUI.M with the given input arguments.
%
%      BELTCOPPICEDENSITYCOSTGUI('Property','Value',...) creates a new BELTCOPPICEDENSITYCOSTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BeltCoppiceDensityCostGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BeltCoppiceDensityCostGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BeltCoppiceDensityCostGUI

% Last Modified by GUIDE v2.5 16-Apr-2012 08:05:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BeltCoppiceDensityCostGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @BeltCoppiceDensityCostGUI_OutputFcn, ...
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


% --- Executes just before BeltCoppiceDensityCostGUI is made visible.
function BeltCoppiceDensityCostGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BeltCoppiceDensityCostGUI (see VARARGIN)

% Choose default command line output for BeltCoppiceDensityCostGUI

   default.useDensityBasedHarvestCost = false;
   default.speedTableFactor = [0 0 0 0 0 0 ]';
   default.speedTablePower = [0 0 0 0 0 0 ]';
   default.costFactor = 0;
   default.costPower = 1;

if(nargin < 4)
   % Then we need to set the default settings
   handles.costParameters = default;
   
else
   % Use the given growth model parameters if there are provided.
   if isempty(varargin{1})
       handles.costParameters = default;
   else
       handles.costParameters = varargin{1};
       if isempty(handles.costParameters.speedTableFactor)
          handles.costParameters.speedTableFactor = default.speedTableFactor;
       end
       if isempty(handles.costParameters.speedTablePower)
          handles.costParameters.speedTablePower = default.speedTablePower;
       end
   end      
end

% Update handles structure
handles.output = [];
guidata(hObject, handles);
populateDialog(handles);
   

% UIWAIT makes BeltCoppiceDensityCostGUI wait for user response (see UIRESUME)
uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = BeltCoppiceDensityCostGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);

% Uses the parameters in handles to populate the dialog when it starts up.
function populateDialog(handles)

% Setup the tables
loadTable(handles);

% Setup the cost parameters.
set(handles.editCostMultiplier, 'String', num2str(handles.costParameters.costFactor));
set(handles.editCostPower, 'String', num2str(handles.costParameters.costPower));


function editCostMultiplier_Callback(hObject, eventdata, handles)
% hObject    handle to editCostMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCostMultiplier as text
%        str2double(get(hObject,'String')) returns contents of editCostMultiplier as a double
num = str2double(get(hObject, 'String'));
reset = false;
if(isnan(num))
    reset = true;
else
 if(num >= 0)
      handles.costParameters.costFactor = num; 
      guidata(hObject, handles);
 else
    reset = true;
 end
end
if reset
       set(hObject, 'String', num2str(handles.costParameters.costFactor)); 
end

% --- Executes during object creation, after setting all properties.
function editCostMultiplier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCostMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCostPower_Callback(hObject, eventdata, handles)
% hObject    handle to editCostPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCostPower as text
%        str2double(get(hObject,'String')) returns contents of editCostPower as a double
num = str2double(get(hObject, 'String'));
reset = false;
if(isnan(num))
    reset = true;
else
 if(num <= 0)
      handles.costParameters.costPower = num; 
      guidata(hObject, handles);
 else
    reset = true;
 end
end
if reset
       set(hObject, 'String', num2str(handles.costParameters.costPower)); 
end

% --- Executes during object creation, after setting all properties.
function editCostPower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCostPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(hObject);

% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = saveTable(handles);
handles.output = handles.costParameters;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%uiresume(hObject);
delete(hObject);


% --- Executes on button press in pushbuttonPasteSpeedFactor.
function pushbuttonPasteSpeedFactor_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPasteSpeedFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
col = getTableFromClipboard;
if(~isempty(col))
    data = get(handles.uitableHarvestSpeed, 'Data');
    rows = size(data, 1);
    if(size(col, 1) == rows && size(col, 2) == 1)
        data(:, 2) = col;
        set(handles.uitableHarvestSpeed, 'Data', data);
        handles = saveTable(handles);
    end
end

% --- Executes on button press in pushbuttonPasteSpeedPower.
function pushbuttonPasteSpeedPower_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPasteSpeedPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
col = getTableFromClipboard;
if(~isempty(col))
    data = get(handles.uitableHarvestSpeed, 'Data');
    rows = size(data, 1);
    if(size(col, 1) == rows && size(col, 2) == 1)
        data(:, 3) = col;
        set(handles.uitableHarvestSpeed, 'Data', data);
        handles = saveTable(handles);
    end
end

function loadTable(handles)
data = get(handles.uitableHarvestSpeed, 'Data');
data(:, 2) = handles.costParameters.speedTableFactor;
data(:, 3) = handles.costParameters.speedTablePower;
set(handles.uitableHarvestSpeed, 'Data', data);

function handles = saveTable(handles)
data = get(handles.uitableHarvestSpeed, 'Data');
handles.costParameters.speedTableFactor = data(:, 2);
handles.costParameters.speedTablePower = data(:, 3);
guidata(handles.figure1, handles);

% Converts a column pasted from Excel into an array to use in our table.
function data = getTableFromClipboard

data = clipboard('paste');
if(isempty(data))
    msgbox('Nothing on the clipboard. Paste Failed.','No Data to Paste.');
    data = [];
else
    data = str2num(data);
    if any(any(isnan(data)))
        msgbox('Unable to paste column. Possibly non-numerical data.', 'Bad Column Data');
        data = [];
    end
end

% --- Executes when entered data in editable cell(s) in uitableHarvestSpeed.
function uitableHarvestSpeed_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableHarvestSpeed (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

if isnan(eventdata.NewData)
    data = get(hObject, 'Data');
    data(eventdata.Indices(1), eventdata.Indices(2)) = eventdata.PreviousData;
    set(hObject, 'Data', data);
else
    saveTable(handles);
end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
