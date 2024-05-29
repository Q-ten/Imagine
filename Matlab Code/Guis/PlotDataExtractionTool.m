function varargout = PlotDataExtractionTool(varargin)
% PLOTDATAEXTRACTIONTOOL MATLAB code for PlotDataExtractionTool.fig
%      PLOTDATAEXTRACTIONTOOL, by itself, creates a new PLOTDATAEXTRACTIONTOOL or raises the existing
%      singleton*.
%
%      H = PLOTDATAEXTRACTIONTOOL returns the handle to a new PLOTDATAEXTRACTIONTOOL or the handle to
%      the existing singleton*.
%
%      PLOTDATAEXTRACTIONTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTDATAEXTRACTIONTOOL.M with the given input arguments.
%
%      PLOTDATAEXTRACTIONTOOL('Property','Value',...) creates a new PLOTDATAEXTRACTIONTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PlotDataExtractionTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PlotDataExtractionTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PlotDataExtractionTool

% Last Modified by GUIDE v2.5 18-Feb-2014 15:06:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PlotDataExtractionTool_OpeningFcn, ...
                   'gui_OutputFcn',  @PlotDataExtractionTool_OutputFcn, ...
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


% --- Executes just before PlotDataExtractionTool is made visible.
function PlotDataExtractionTool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PlotDataExtractionTool (see VARARGIN)

if nargin < 5
    close(handles.figure1);
    return
end

handles.axesList = varargin{1};
handles.otherFigure = varargin{2};

% Choose default command line output for PlotDataExtractionTool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

setupControls(handles);


% UIWAIT makes PlotDataExtractionTool wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PlotDataExtractionTool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function setupControls(handles)

% Work out how to size the main axes
% Get the default size in the window. We'll keep within the existing limits
% But use the shape of the otherFigure window.

defPos = get(handles.axes1, 'Position');
figPos = get(handles.otherFigure, 'Position');

% Are we going to max the width or the height on our axes?

% Is width/height greater in axes1 or fig1?
if (figPos(3)/figPos(4) > defPos(3)/defPos(4))
    % Then we'll max width on our axes.
    % Need to work out height.
    width = defPos(3);
    x = defPos(1);
    height = figPos(4) / figPos(3) * width;    
    % Original centre - helf the new height.
    y = defPos(2) + defPos(4) / 2 - height / 2;
else
    % Else we'll max height on our axes.
    % Need to work out width.
    height = defPos(4);
    y = defPos(2);
    width = figPos(3) / figPos(4) * height;
    % Original centre - helf the new height.
    x = defPos(1) + defPos(3) / 2 - width / 2;
end

set(handles.axes1, 'Position', [x, y, width, height]);

axes(handles.axes1)
axis([0, figPos(3), 0, figPos(4)]);
box('on');

handles.selectedColour = 0.8 * [1 1 1];
handles.unselectedColour = 'w';
handles.selectedPatch = [];
handles.selectedIndex = [];

for i = 1:length(handles.axesList)
   
    % Points are clockwise from bottom left.
    ax = handles.axesList(i);
    
    if strcmp(get(ax.handle, 'Visible'), 'on')    
        X = ax.pos(1) + [0, 0, ax.pos(3), ax.pos(3)];
        Y = ax.pos(2) + [0, ax.pos(4), ax.pos(4), 0];
        C = handles.unselectedColour;
        p = patch(X, Y, C);
        set(p, 'ButtonDownFcn', {@selectAxes, i, p});
        handles.patchs(i) = p;
    end
end

set(handles.pushbuttonCopy, 'Enable', 'off');    

guidata(handles.figure1, handles)

function selectAxes(hObject, eventdata, index, pat)

handles = guidata(hObject);
if ~isempty(handles.selectedPatch)
    set(handles.selectedPatch, 'FaceColor', handles.unselectedColour);
end    
set(pat, 'FaceColor', handles.selectedColour);
handles.selectedPatch = pat;
handles.selectedIndex = index;
guidata(hObject, handles);
updateSelectionInfo(handles, index);

function updateSelectionInfo(handles, index)

ax = handles.axesList(index);
set(handles.textNumberBarPlots, 'String', num2str(length(ax.bars)));
set(handles.textNumberScatterPlots, 'String', num2str(length(ax.scatters)));
set(handles.textNumberLinePlots, 'String', num2str(length(ax.lines)));
set(handles.textTotalPlots, 'String', num2str(ax.plotCount));

if (ax.plotCount > 0)
    set(handles.pushbuttonCopy, 'Enable', 'on');
else
    set(handles.pushbuttonCopy, 'Enable', 'off');    
end

% --- Executes on button press in pushbuttonCopy.
function pushbuttonCopy_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCopy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ax = handles.axesList(handles.selectedIndex);
publishAxesPlotsToClipboard(ax);

% --- Executes on button press in pushbuttonDone.
function pushbuttonDone_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.figure1);

function publishAxesPlotsToClipboard(ax)

arr = {};
arr{1, 1} = 'Plot';
arr{2, 1} = 'Type';

col = 0;
for i = 1:length(ax.lines)   
    
    col = col + 3;

    arr{1, col} = col/3;
    arr{2, col} = 'Line';
    arr{3, col} = 'X';
    arr{3, col + 1} = 'Y';
    
    X = get(ax.lines(i), 'XData');
    Y = get(ax.lines(i), 'YData');
    
    arr(4:(4+length(X)-1), col) = num2cell(X);
    arr(4:(4+length(X)-1), col+1) = num2cell(Y);    
    
end

for i = 1:length(ax.bars)   
    
    col = col + 3;

    arr{1, col} = col/3;
    arr{2, col} = 'Bar';
    arr{3, col} = 'X';
    arr{3, col + 1} = 'Y';
    
    X = get(ax.bars(i), 'XData');
    Y = get(ax.bars(i), 'YData');
    
    arr(4:(4+length(X)-1), col) = num2cell(X);
    arr(4:(4+length(X)-1), col+1) = num2cell(Y);    
    
end

for i = 1:length(ax.scatters)   
    
    col = col + 3;

    arr{1, col} = col/3;
    arr{2, col} = 'Scatter';
    arr{3, col} = 'X';
    arr{3, col + 1} = 'Y';
    
    X = get(ax.scatters(i), 'XData');
    Y = get(ax.scatters(i), 'YData');
    
    arr(4:(4+length(X)-1), col) = num2cell(X);
    arr(4:(4+length(X)-1), col+1) = num2cell(Y);    
    
end

mat2clip(arr);
