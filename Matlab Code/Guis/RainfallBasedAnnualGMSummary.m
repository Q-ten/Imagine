function varargout = RainfallBasedAnnualGMSummary(varargin)
% RAINFALLBASEDANNUALGMSUMMARY M-file for RainfallBasedAnnualGMSummary.fig
%      RAINFALLBASEDANNUALGMSUMMARY, by itself, creates a new RAINFALLBASEDANNUALGMSUMMARY or raises the existing
%      singleton*.
%
%      H = RAINFALLBASEDANNUALGMSUMMARY returns the handle to a new RAINFALLBASEDANNUALGMSUMMARY or the handle to
%      the existing singleton*.
%
%      RAINFALLBASEDANNUALGMSUMMARY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RAINFALLBASEDANNUALGMSUMMARY.M with the given input arguments.
%
%      RAINFALLBASEDANNUALGMSUMMARY('Property','Value',...) creates a new RAINFALLBASEDANNUALGMSUMMARY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RainfallBasedAnnualGMSummary_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RainfallBasedAnnualGMSummary_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RainfallBasedAnnualGMSummary

% Last Modified by GUIDE v2.5 12-Jan-2013 16:51:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RainfallBasedAnnualGMSummary_OpeningFcn, ...
                   'gui_OutputFcn',  @RainfallBasedAnnualGMSummary_OutputFcn, ...
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


% --- Executes just before RainfallBasedAnnualGMSummary is made visible.
function RainfallBasedAnnualGMSummary_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RainfallBasedAnnualGMSummary (see VARARGIN)

% Choose default command line output for RainfallBasedAnnualGMSummary
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RainfallBasedAnnualGMSummary wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RainfallBasedAnnualGMSummary_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
