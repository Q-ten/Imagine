function varargout = RainfallBasedAnnualGMDialog(varargin)
% RAINFALLBASEDANNUALGMDIALOG M-file for RainfallBasedAnnualGMDialog.fig
%      RAINFALLBASEDANNUALGMDIALOG, by itself, creates a new RAINFALLBASEDANNUALGMDIALOG or raises the existing
%      singleton*.
%
%      H = RAINFALLBASEDANNUALGMDIALOG returns the handle to a new RAINFALLBASEDANNUALGMDIALOG or the handle to
%      the existing singleton*.
%
%      RAINFALLBASEDANNUALGMDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RAINFALLBASEDANNUALGMDIALOG.M with the given input arguments.
%
%      RAINFALLBASEDANNUALGMDIALOG('Property','Value',...) creates a new RAINFALLBASEDANNUALGMDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RainfallBasedAnnualGMDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RainfallBasedAnnualGMDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RainfallBasedAnnualGMDialog

% Last Modified by GUIDE v2.5 10-Jan-2013 13:37:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RainfallBasedAnnualGMDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @RainfallBasedAnnualGMDialog_OutputFcn, ...
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


% --- Executes just before RainfallBasedAnnualGMDialog is made visible.
function RainfallBasedAnnualGMDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RainfallBasedAnnualGMDialog (see VARARGIN)

handles.gm = setupParameters(varargin{:});

% Don't use the gm version HIData. Only save to it if we accept. If we
% cancel it should remain untouched.
handles.units = handles.gm.HIData.units;
handles.HI = handles.gm.HIData.HI;

handles.output = [];

guidata(hObject, handles);
populateDialog(handles);

% UIWAIT makes RainfallBasedAnnualGMDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RainfallBasedAnnualGMDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
close(gcf);

function gm = setupParameters(varargin)

default.A = 3e-6;
default.B = 0.02;
default.C = 0;
default.firstRelevantMonth = 1;
default.lastRelevantMonth = 12;

default.HIData = HarvestIndexData;
default.HIData.units = 'Yield';
default.HIData.HI = 1;    

fields = {'A', 'B', 'C', 'firstRelevantMonth', 'lastRelevantMonth', 'HIData'};

gm = default;

for i = 1:length(fields)        
    if (nargin >= i)
       gm.(fields{i}) = varargin{i};
    end
end

gm = absorbFields(default, gm);


function populateDialog(handles)

handles.xpoints = [];
handles.ypoints = [];

axes(handles.axes1);
hold on
handles.sc = scatter([351],[1], 25, 'b');
handles.plo = plot([0], [0]);

p = [handles.gm.A, handles.gm.B, handles.gm.C];
set(handles.editA, 'String', num2str(p(1)));
set(handles.editB, 'String', num2str(p(2)));
set(handles.editC, 'String', num2str(p(3)));

set(handles.firstRelevantMonthDDL, 'Value', handles.gm.firstRelevantMonth);
set(handles.lastRelevantMonthDDL, 'Value', handles.gm.lastRelevantMonth);

unitOptions = get(handles.popupmenuHarvestUnits, 'String');
ix = find(strcmp(unitOptions, handles.units), '1', 'first');
if (isempty(ix))
   error('The HIData units should match one of the entries in the popupmenu.'); 
end
set(handles.popupmenuHarvestUnits, 'Value', ix);
set(handles.editHI, 'String', num2str(handles.HI));

if (strcmp(handles.units, 'Yield'))
    set(handles.editHI, 'Enable', 'off');
end

guidata(handles.axes1, handles);
updateYieldCurve(handles);
    
% This function updates the plot with rainfall based data
function updateYieldCurve(handles)

if(isempty(handles.xpoints) || isempty(handles.ypoints))

    % Get the numbers A,B,C
    A = str2double(get(handles.editA, 'String'));
    B = str2double(get(handles.editB, 'String'));
    C = str2double(get(handles.editC, 'String'));

    if(isnan(A))
        A = 0;
    end
    if(isnan(B))
        B = 0;
    end
    if(isnan(C))
        C = 0;
    end

    p = [-A, B, C];

else
    p = polyfit(handles.xpoints, handles.ypoints, 2);
    set(handles.editA, 'String', -p(1));
    set(handles.editB, 'String',  p(2));
    set(handles.editC, 'String',  p(3));
end
    
t = [0:700];
y = polyval(p, t);

hold on
axes(handles.axes1);
set(handles.plo, 'XData', t);
set(handles.plo, 'YData', y);

set(handles.sc, 'XData', handles.xpoints);
set(handles.sc, 'YData', handles.ypoints);
axis([0 700 0 max(y) * 1.2])
xlabel('Rainfall (mm)');
ylabel([handles.units, ' (t/Ha)']);


function editA_Callback(hObject, eventdata, handles)
% hObject    handle to editA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editA as text
%        str2double(get(hObject,'String')) returns contents of editA as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)


% --- Executes during object creation, after setting all properties.
function editA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editB_Callback(hObject, eventdata, handles)
% hObject    handle to editB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editB as text
%        str2double(get(hObject,'String')) returns contents of editB as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)


% --- Executes during object creation, after setting all properties.
function editB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editC_Callback(hObject, eventdata, handles)
% hObject    handle to editC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editC as text
%        str2double(get(hObject,'String')) returns contents of editC as a double
handles.xpoints = [];
handles.ypoints = [];
guidata(hObject, handles);
updateYieldCurve(handles)


% --- Executes during object creation, after setting all properties.
function editC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in firstRelevantMonthDDL.
function firstRelevantMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to firstRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns firstRelevantMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from firstRelevantMonthDDL


% --- Executes during object creation, after setting all properties.
function firstRelevantMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to firstRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lastRelevantMonthDDL.
function lastRelevantMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to lastRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lastRelevantMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lastRelevantMonthDDL


% --- Executes during object creation, after setting all properties.
function lastRelevantMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lastRelevantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonLeft.
function pushbuttonLeft_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonRight.
function pushbuttonRight_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonDown.
function pushbuttonDown_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonUp.
function pushbuttonUp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonWider.
function pushbuttonWider_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonWider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonNarrower.
function pushbuttonNarrower_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNarrower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonFineTuneCurve.
function pushbuttonFineTuneCurve_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFineTuneCurve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

but = 1;

xpoints = [0 350 700];

% Get the numbers A,B,C
A = str2double(get(handles.editA, 'String'));
B = str2double(get(handles.editB, 'String'));
C = str2double(get(handles.editC, 'String'));

if(isnan(A))
    A = 0;
end
if(isnan(B))
    B = 0;
end
if(isnan(C))
    C = 0;
end

p = [-A, B, C];

ypoints = polyval(p, xpoints);

set(handles.sc, 'XData', xpoints);
set(handles.sc, 'YData', ypoints);

while (but == 1)
    [x,y,but] = ginput(1); 
    xlim = get(handles.axes1, 'XLim');
    ylim = get(handles.axes1, 'YLim');
    if(x < xlim(1) || x > xlim(2) || y < ylim(1) || y > ylim(2) || but ~= 1)
        break;
    end
    xpoints(end+1) = x;
    ypoints(end+1) = y;

    handles.xpoints = xpoints;
    handles.ypoints = ypoints;
    
    guidata(hObject, handles);
    updateYieldCurve(handles);
end

set(handles.sc, 'XData', []);
set(handles.sc, 'YData', []);

% --- Executes on selection change in popupmenuHarvestUnits.
function popupmenuHarvestUnits_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuHarvestUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuHarvestUnits contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuHarvestUnits

contents = cellstr(get(hObject,'String'));
str = contents{get(hObject,'Value')};
currStr = handles.units;
if strcmp(currStr, str)
    return
end

handles.units = str;

% Get the numbers A,B,C
A = str2double(get(handles.editA, 'String'));
B = str2double(get(handles.editB, 'String'));
C = str2double(get(handles.editC, 'String'));
p = [A, B, C];
HI = handles.HI;

if (strcmp(str, 'Yield'))
    % Changed from biomass to yield.
    % Disable the HI entry.
    % Mulitiply coefficients by the HI.
    set(handles.editHI, 'Enable', 'off');
    p = p * HI;
elseif (strcmp(str, 'Biomass'))
    % Changed from yield to biomass.
    % enable the HI entry.
    % Divide the coefficients by the HI.
    set(handles.editHI, 'Enable', 'on');
    p = p / HI;
else
   error('Reached a supposedly unreachable spot.');
end

set(handles.editA, 'String', num2str(p(1)));
set(handles.editB, 'String', num2str(p(2)));
set(handles.editC, 'String', num2str(p(3)));
guidata(hObject, handles);
updateYieldCurve(handles);

   


% --- Executes during object creation, after setting all properties.
function popupmenuHarvestUnits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuHarvestUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHI_Callback(hObject, eventdata, handles)
% hObject    handle to editHI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHI as text
%        str2double(get(hObject,'String')) returns contents of editHI as a double
num = str2double(get(hObject, 'String'));
if isnan(num)
   set(hObject, 'String', num2str(handles.HI)); 
else
    if num > 1
        num = 1;
        set(hObject, 'String', num2str(num)); 
    end
    if num < 0.0000001;
        num = 0.0000001;
        set(hObject, 'String', num2str(num)); 
    end
    handles.HI = num;
    guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function editHI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonOk.
function pushbuttonOk_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.gm.A = str2double(get(handles.editA, 'String'));
handles.gm.B = str2double(get(handles.editB, 'String'));
handles.gm.C = str2double(get(handles.editC, 'String'));
handles.gm.firstRelevantMonth = get(handles.firstRelevantMonthDDL, 'Value');
handles.gm.lastRelevantMonth = get(handles.lastRelevantMonthDDL, 'Value');

handles.gm.HIData.units = handles.units;
handles.gm.HIData.HI = handles.HI;

handles.output = handles.gm;
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
