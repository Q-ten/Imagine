function varargout = testA(varargin)
% TESTA MATLAB code for testA.fig
%      TESTA, by itself, creates a new TESTA or raises the existing
%      singleton*.
%
%      H = TESTA returns the handle to a new TESTA or the handle to
%      the existing singleton*.
%
%      TESTA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TESTA.M with the given input arguments.
%
%      TESTA('Property','Value',...) creates a new TESTA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before testA_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to testA_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help testA

% Last Modified by GUIDE v2.5 08-May-2014 23:34:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @testA_OpeningFcn, ...
                   'gui_OutputFcn',  @testA_OutputFcn, ...
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


% --- Executes just before testA is made visible.
function testA_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to testA (see VARARGIN)

% Choose default command line output for testA
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes testA wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = testA_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

s = rand(1, 10);
plot(handles.axes1, s);



