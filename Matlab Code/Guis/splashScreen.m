function varargout = splashScreen(varargin)
% SPLASHSCREEN M-file for splashScreen.fig
%      SPLASHSCREEN, by itself, creates a new SPLASHSCREEN or raises the existing
%      singleton*.
%
%      H = SPLASHSCREEN returns the handle to a new SPLASHSCREEN or the handle to
%      the existing singleton*.
%
%      SPLASHSCREEN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPLASHSCREEN.M with the given input arguments.
%
%      SPLASHSCREEN('Property','Value',...) creates a new SPLASHSCREEN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before splashScreen_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to splashScreen_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help splashScreen

% Last Modified by GUIDE v2.5 28-Aug-2009 01:27:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @splashScreen_OpeningFcn, ...
                   'gui_OutputFcn',  @splashScreen_OutputFcn, ...
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


% --- Executes just before splashScreen is made visible.
function splashScreen_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to splashScreen (see VARARGIN)

% Choose default command line output for splashScreen
handles.output = hObject;

opengl software

try 
    im = imread('MalleeSplash.jpg');
    im = im(end:-1:1,:,:);
catch ME
    im = 0.3* ones(558, 800, 3);
end

% try 
%     crc = imread('CRC.jpg');
%     crc = crc(end:-1:1,:,:);
%     im(26:25+125, 800-115-25:800-26,:) = crc;
% catch ME
% %    msgbox(ME.identifier);    
% end

% try 
%     dec = imread('DEC.jpg');
%     dec = dec(end:-1:1,:,:);
%     im(26:25+72, 26:25+340,:) = dec;
% catch ME
% %    msgbox(ME.identifier);
% end

    axes(handles.axes1);
%image(im);
axis([1 800 1 558]);
image('CData', im);
axis off

title = 'Welcome to Imagine!';
intro = {'Imagine is a tool designed to simulate the growth', ...
        'of crops on a paddock over time.', ...
        '', ...
        'Factors affecting the outcome of profitability can be ', ...
        'set up as probabilistic distributions and while there ', ...
        'may be complex interactions between the random ', ...
        'variables used, a monte carlo simulation ', ...
        'environment has been set up so that the distribution ', ...
        'of outcomes can be assessed.', ...
        '', ...
        'Crops grow according to a model set up by the user. ', ...
        'We have a rainfall based growth model that is ', ...
        'appropriate for annual crops, and a Gompertz based ', ...
        'growth model that grows above ground and below ', ...
        'ground biomass in tandem, which is suitable for trees.', ...
        '', ...
        'Developers:', ...
        'Amir Abadi, Quenten Thomas and John Bartle', ...
        '', ...
        '' };

    ip = {
            'IP and copyright for IMAGINE is vested in:', ...
            'Department of Parks and Wildlife, Western Australia (2007 to 2014), The Future Farm Industries Cooperative Research', ...
            'Centre (2007-2014) and the Department of Agriculture and Food -Western Australia (2014 onwards)', ...
        };
    
patch([25 25 363 363], [115 533 533 115], 'k', 'FaceAlpha', 0.5);
patch([25 25 (800-25) (800 - 25)], [25 90 90 25], 'k', 'FaceAlpha', 0.5);
view([0 90])

set(gcf, 'Name', 'Welcome');
text(35, 520, title, 'Color', 'w', 'VerticalAlignment', 'top', 'FontSize', 16);
text(35, 470, intro, 'Color', 'w', 'VerticalAlignment', 'top');
text(35, 80, ip, 'Color', 'w', 'VerticalAlignment', 'top');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes splashScreen wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = splashScreen_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in continueButton.
function continueButton_Callback(hObject, eventdata, handles)
% hObject    handle to continueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(gcf);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


