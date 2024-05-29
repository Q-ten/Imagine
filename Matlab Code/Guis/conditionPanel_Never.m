function varargout = conditionPanel_Never(varargin)
% CONDITIONPANEL_NEVER MATLAB code for conditionPanel_Never.fig
%      CONDITIONPANEL_NEVER, by itself, creates a new CONDITIONPANEL_NEVER or raises the existing
%      singleton*.
%
%      H = CONDITIONPANEL_NEVER returns the handle to a new CONDITIONPANEL_NEVER or the handle to
%      the existing singleton*.
%
%      CONDITIONPANEL_NEVER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONDITIONPANEL_NEVER.M with the given input arguments.
%
%      CONDITIONPANEL_NEVER('Property','Value',...) creates a new CONDITIONPANEL_NEVER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before conditionPanel_Never_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to conditionPanel_Never_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help conditionPanel_Never

% Last Modified by GUIDE v2.5 25-Jul-2013 13:51:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @conditionPanel_Never_OpeningFcn, ...
                   'gui_OutputFcn',  @conditionPanel_Never_OutputFcn, ...
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


% --- Executes just before conditionPanel_Never is made visible.
function conditionPanel_Never_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to conditionPanel_Never (see VARARGIN)

% Choose default command line output for conditionPanel_Never
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes conditionPanel_Never wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = conditionPanel_Never_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


