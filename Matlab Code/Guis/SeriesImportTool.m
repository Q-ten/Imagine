function varargout = SeriesImportTool(varargin)
% SERIESIMPORTTOOL M-file for SeriesImportTool.fig
%      SERIESIMPORTTOOL, by itself, creates a new SERIESIMPORTTOOL or raises the existing
%      singleton*.
%
%      H = SERIESIMPORTTOOL returns the handle to a new SERIESIMPORTTOOL or the handle to
%      the existing singleton*.
%
%      SERIESIMPORTTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SERIESIMPORTTOOL.M with the given input arguments.
%
%      SERIESIMPORTTOOL('Property','Value',...) creates a new SERIESIMPORTTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SeriesImportTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SeriesImportTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SeriesImportTool

% Last Modified by GUIDE v2.5 22-Apr-2012 17:44:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SeriesImportTool_OpeningFcn, ...
                   'gui_OutputFcn',  @SeriesImportTool_OutputFcn, ...
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


% --- Executes just before SeriesImportTool is made visible.
function SeriesImportTool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SeriesImportTool (see VARARGIN)

% Choose default command line output for SeriesImportTool
handles.output = hObject;

% Need to be passed in a title, and a size for the array.
defaultTitle = '';
defaultData = zeros([50, 1]);

if(nargin < 5)
   % Then we need to set the default settings
   handles.title = defaultTitle;
   handles.data = defaultData;
else
    % Try and use the first argument as a title.
   if isempty(varargin{2})
        handles.title = defaultTitle;   
   else
       if ischar(varargin{2})
           handles.title = varargin{2};
       else
           handles.title = defaultTitle;              
       end       
   end
   % Try to use the second argument as a size. 
   if isempty(varargin{1})
        handles.data = defaultData;   
   else
       if isnumeric(varargin{1}) && length(size(varargin{1})) == 2
           handles.data = varargin{1};
       else
           handles.data = defaultData;              
       end       
   end
end

if (nargin >= 6)
   colHeaders = varargin{3};
   if length(colHeaders) == size(handles.data, 2)
      set(handles.uitableData, 'ColumnName', colHeaders);
   end    
end

handles.size = size(handles.data);
handles.selectedIndices = [];

% Update handles structure
guidata(hObject, handles);

populateDialog(handles);

% UIWAIT makes SeriesImportTool wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SeriesImportTool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);

function populateDialog(handles)

% Set the title.
set(handles.textTitle, 'String', handles.title);

% Set the sizes.
set(handles.textSize, 'String', [num2str(handles.size(1)), ' x ', num2str(handles.size(2))]);
set(handles.uitableData, 'ColumnFormat', repmat({'numeric'}, 1, size(handles.data, 2)) );
set(handles.uitableData, 'ColumnEditable', true(1, size(handles.data, 2)) );

% Set the column widths to be 60.
set(handles.uitableData, 'ColumnWidth', num2cell(60 * ones(1, size(handles.data, 2))));

% Set the size such that 12 columns appear ok. More get truncated. 
tableWidth = 60 + 60 * size(handles.data, 2);
tablePos = get(handles.uitableData, 'Position');
if (tablePos(1) + tableWidth + 10 > 1000)
    tableWidth = 1000 - tablePos(1) - 10;
end
tablePos(3) = tableWidth;
set(handles.uitableData, 'Position', tablePos);
figPos = get(handles.figure1, 'Position');
figPos(3) = tablePos(1) + tableWidth + 10;
set(handles.figure1, 'Position', figPos);

refreshTable(handles);

function saveTable(handles)

handles.data = get(handles.uitableData, 'Data');
guidata(handles.figure1, handles);

function refreshTable(handles)
set(handles.uitableData, 'Data', handles.data);


% --- Executes on button press in pushbuttonPasteClipboard.
function pushbuttonPasteClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPasteClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Grab the data from the clipboard.
data = getTableFromClipboard;

if(isempty(data))
    return    
end

% If there is data there, work out how to add it to the table data.
% Paste it into the columns from the selected cell across the visible cells
% as if we were pasting into Excel.
tableData = get(handles.uitableData, 'Data');
[length, width] = size(tableData);

selectedIndices = handles.selectedIndices;

newSelectedIndices = [];

% If there's more data on the clipboard than we can fit, we truncate it.
for i = 1:size(selectedIndices, 1)
    % If the coordinates are outside the table, lose them.
    if(selectedIndices(i, 1) <= length && selectedIndices(i, 2) <= width)
        newSelectedIndices(end+1, :) = selectedIndices(i, :);
    end
end
selectedIndices = newSelectedIndices;

if(isempty(selectedIndices))
    Msgbox('Please select top left cell to paste from.', 'No cell selected.');
    return
end
if(size(selectedIndices, 1) > 1)
    Msgbox('Please select only one cell to paste from.', 'Multiple Paste Cells')
    return
end

insertRow = selectedIndices(1, 1);
insertCol = selectedIndices(1, 2);
rowEnd = insertRow + size(data, 1) - 1;
colEnd = insertCol + size(data, 2) - 1;
if(rowEnd > length)
    rowEnd = length;
end
if(colEnd > width)
    colEnd = width;
end

rows = insertRow:rowEnd;
cols = insertCol:colEnd;

%tableData(rows, cols) = data(1:length(rows), 1:length(cols));
% Bizarrely length(rows) says index exceeded...
tableData(rows, cols) = data(1:size(rows, 2), 1:size(cols, 2));
set(handles.uitableData, 'Data', tableData);

saveTable(handles);

% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = handles.data;
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


% --- Executes when entered data in editable cell(s) in uitableData.
function uitableData_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableData (see GCBO)
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



% --- Executes when selected cell(s) is changed in uitableData.
function uitableData_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableData (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
handles.selectedIndices = eventdata.Indices;
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);
