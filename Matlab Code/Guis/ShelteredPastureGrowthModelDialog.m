function varargout = ShelteredPastureGrowthModelDialog(varargin)
% SHELTEREDPASTUREGROWTHMODELDIALOG M-file for ShelteredPastureGrowthModelDialog.fig
%      SHELTEREDPASTUREGROWTHMODELDIALOG, by itself, creates a new SHELTEREDPASTUREGROWTHMODELDIALOG or raises the existing
%      singleton*.
%
%      H = SHELTEREDPASTUREGROWTHMODELDIALOG returns the handle to a new SHELTEREDPASTUREGROWTHMODELDIALOG or the handle to
%      the existing singleton*.
%
%      SHELTEREDPASTUREGROWTHMODELDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHELTEREDPASTUREGROWTHMODELDIALOG.M with the given input arguments.
%
%      SHELTEREDPASTUREGROWTHMODELDIALOG('Property','Value',...) creates a new SHELTEREDPASTUREGROWTHMODELDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ShelteredPastureGrowthModelDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ShelteredPastureGrowthModelDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ShelteredPastureGrowthModelDialog

% Last Modified by GUIDE v2.5 13-Apr-2018 16:25:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ShelteredPastureGrowthModelDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @ShelteredPastureGrowthModelDialog_OutputFcn, ...
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

function gm = setupParameters(varargin)

    default.FOO.peakFOOPerMMMonth = 11;
    default.FOO.minFOOPerMMMonth = 7;
    default.FOO.peakFOOPerMM = 24;
    default.FOO.minFOOPerMM = 16;
    default.FOO.startMonth = 3;
    default.FOO.availableAtStart = 500;
    default.FOO.requiredBeforeGrazing = 1100;
    default.FOO.for100PercentCS2 = 1500;
    default.FOO.for100PercentCS3 = 12000;
    default.FOO.shelterSettingsFile = '';

    default.fodderCosts.ewe = 2.1;
    default.fodderCosts.eweHogget = 2.1;
    default.fodderCosts.eweLamb = 1.4;
    default.fodderCosts.ram = 3;
    default.fodderCosts.wether = 2.1;
    default.fodderCosts.wetherHogget = 3;
    default.fodderCosts.wetherLamb = 3.5;
%    default.fodderCosts.pricePerTonne = 150;


    default.woolSales.ewes = struct('numberPer1000', 960, 'woolWeightPerHd', 5.4 , 'woolPricePerKg', 8.47);
    default.woolSales.eweHoggets = struct('numberPer1000', 208, 'woolWeightPerHd', 5.4 , 'woolPricePerKg', 9.07);
    default.woolSales.eweLambs = struct('numberPer1000', 425, 'woolWeightPerHd', 1.1 , 'woolPricePerKg', 4.07);
    default.woolSales.rams = struct('numberPer1000', 20, 'woolWeightPerHd', 8 , 'woolPricePerKg', 8.48);
    default.woolSales.wethers = struct('numberPer1000', 0, 'woolWeightPerHd', 5.4 , 'woolPricePerKg', 8.48);
    default.woolSales.wetherHoggets = struct('numberPer1000', 0, 'woolWeightPerHd', 5.4 , 'woolPricePerKg', 9.07);
    default.woolSales.wetherLambs = struct('numberPer1000', 425, 'woolWeightPerHd', 1.1 , 'woolPricePerKg', 4.07);
    default.woolSales.DSEPer1000 = 2500;
    default.woolSales.shearingMonth = 3;

    default.sheepSales.CFAEwes = struct('numberPer1000', 177, 'pricePerHdCS2', 88.85, 'pricePerHdCS3', 88.85);
    default.sheepSales.eweHoggets = struct('numberPer1000', 196, 'pricePerHdCS2', 135, 'pricePerHdCS3', 135);
    default.sheepSales.eweLambs = struct('numberPer1000', 0, 'pricePerHdCS2', 102.52, 'pricePerHdCS3', 102.52);
    default.sheepSales.CFARams = struct('numberPer1000', 4, 'pricePerHdCS2', 60.48, 'pricePerHdCS3', 60.48);
    default.sheepSales.CFAWethers = struct('numberPer1000', 0, 'pricePerHdCS2', 60.48, 'pricePerHdCS3', 60.48);
    default.sheepSales.wetherHoggets = struct('numberPer1000', 0, 'pricePerHdCS2', 135, 'pricePerHdCS3', 135);
    default.sheepSales.wetherLambs = struct('numberPer1000', 421, 'pricePerHdCS2', 102.52, 'pricePerHdCS3', 102.52);
    default.sheepSales.sheepSalesMonth = 9;

%    default.spatialInteractions = SpatialInteractions;
    
    fields = {'FOO', 'fodderCosts', 'woolSales', 'sheepSales'};%, 'spatialInteractions'};

    for i = 1:length(fields)        
        if (nargin >= i)
           gm.(fields{i}) = varargin{i};
        end
    end

    gm = absorbFields(default, gm);


% --- Executes just before ShelteredPastureGrowthModelDialog is made visible.
function ShelteredPastureGrowthModelDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ShelteredPastureGrowthModelDialog (see VARARGIN)

gm = struct();
if nargin >= 4
    in = varargin{1};
    gm = setupParameters(in.FOO, in.fodderCosts, in.woolSales, in.sheepSales);%, in.spatialInteractions);
else
    gm = setupParameters(gm);
end
fns = fieldnames(gm);
for i = 1:length(fns)
    handles.(fns{i}) = gm.(fns{i});
end

if nargin >= 5
   handles.cropName = varargin{2};
else
    handles.cropName = 'Pasture';
end

guidata(hObject, handles);
populateDialog(handles);

% Choose default command line output for ShelteredPastureGrowthModelDialog
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ShelteredPastureGrowthModelDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ShelteredPastureGrowthModelDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);


% --- Executes on button press in pushbuttonOk.
function pushbuttonOk_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = retrieveModel(handles);
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = [];
guidata(hObject, handles);
uiresume(gcf);

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

function populateDialog(handles)

% Set the picture

picture = './Resources/LongSheep.jpg';            
try 
    im = imread(picture);
    im = im(end:-1:1,:,:);

end

axes(handles.axes1);
cla
image('CData', im);
axis([1 380 1 600])
axis on

% Load the data into the tables.

months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

% FOO
data = { ...
        handles.FOO.availableAtStart; ...
        handles.FOO.requiredBeforeGrazing; ...
%        handles.FOO.peakFOOPerMM; ...
%        handles.FOO.minFOOPerMM; ...
        handles.FOO.for100PercentCS2; ...
        handles.FOO.for100PercentCS3; ...
        };

set(handles.uitableFOO, 'Data', data);
set(handles.popupmenuStartMonth, 'Value', handles.FOO.startMonth);
%set(handles.popupmenuPeakFOOGrowthMonth, 'Value', handles.FOO.peakFOOPerMMMonth);
%set(handles.popupmenuMinFOOGrowthMonth, 'Value', handles.FOO.minFOOPerMMMonth);

if isempty(handles.FOO.shelterSettingsFile)
    set(handles.textShelterSettingsFile, 'String', '[Not Selected]');
else
    set(handles.textShelterSettingsFile, 'String', handles.FOO.shelterSettingsFile);
end

% Fodder Costs
data = { ...
        handles.fodderCosts.ewe; ...
        handles.fodderCosts.eweHogget; ...
        handles.fodderCosts.eweLamb; ...
        handles.fodderCosts.ram; ...
        handles.fodderCosts.wether; ...
        handles.fodderCosts.wetherHogget; ...
        handles.fodderCosts.wetherLamb; ...
        };

set(handles.uitableFodderCosts, 'Data', data);
%set(handles.editFodderPrice, 'String', num2str(handles.fodderCosts.pricePerTonne));


% Wool Sales
data = [ ...
        struct2cell(handles.woolSales.ewes)'; ...
        struct2cell(handles.woolSales.eweHoggets)'; ...
        struct2cell(handles.woolSales.eweLambs)'; ...
        struct2cell(handles.woolSales.rams)'; ...
        struct2cell(handles.woolSales.wethers)'; ...
        struct2cell(handles.woolSales.wetherHoggets)'; ...
        struct2cell(handles.woolSales.wetherLambs)'; ...
        ];

set(handles.uitableWoolSales, 'Data', data);
set(handles.editDSEConversion, 'String', num2str(handles.woolSales.DSEPer1000));
set(handles.popupmenuWoolSalesMonth, 'Value', handles.woolSales.shearingMonth);

% Sheep Sales
data = [ ...
        struct2cell(handles.sheepSales.CFAEwes)'; ...
        struct2cell(handles.sheepSales.eweHoggets)'; ...
        struct2cell(handles.sheepSales.eweLambs)'; ...
        struct2cell(handles.sheepSales.CFARams)'; ...
        struct2cell(handles.sheepSales.CFAWethers)'; ...
        struct2cell(handles.sheepSales.wetherHoggets)'; ...
        struct2cell(handles.sheepSales.wetherLambs)'; ...
        ];

set(handles.uitableSheepSales, 'Data', data);
set(handles.popupmenuSheepSalesMonth, 'Value', handles.sheepSales.sheepSalesMonth);

%refreshSpatialInteractionLabels(handles);

% Pulls the data out of controls
function model = retrieveModel(handles)

months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

% FOO
data = get(handles.uitableFOO, 'Data');

model.FOO.availableAtStart = data{1};
model.FOO.requiredBeforeGrazing = data{2};
% model.FOO.peakFOOPerMM = data{3};
% model.FOO.minFOOPerMM = data{4};
% model.FOO.for100PercentCS2 = data{5};
% model.FOO.for100PercentCS3 = data{6};
model.FOO.for100PercentCS2 = data{3};
model.FOO.for100PercentCS3 = data{4};



model.FOO.startMonth = get(handles.popupmenuStartMonth, 'Value');
%model.FOO.peakFOOPerMMMonth = get(handles.popupmenuPeakFOOGrowthMonth, 'Value');
%model.FOO.minFOOPerMMMonth = get(handles.popupmenuMinFOOGrowthMonth, 'Value');
model.FOO.shelterSettingsFile = handles.FOO.shelterSettingsFile;

% Fodder Costs
data = get(handles.uitableFodderCosts, 'Data');

model.fodderCosts.ewe = data{1};
model.fodderCosts.eweHogget = data{2};
model.fodderCosts.eweLamb = data{3};
model.fodderCosts.ram = data{4};
model.fodderCosts.wether = data{5};
model.fodderCosts.wetherHogget = data{6};
model.fodderCosts.wetherLamb = data{7};
%model.fodderCosts.pricePerTonne = handles.fodderCosts.pricePerTonne;


% Wool Sales
data = get(handles.uitableWoolSales, 'Data');
model.woolSales.ewes = cell2struct(data(1, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.eweHoggets = cell2struct(data(2, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.eweLambs = cell2struct(data(3, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.rams = cell2struct(data(4, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.wethers = cell2struct(data(5, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.wetherHoggets = cell2struct(data(6, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.wetherLambs = cell2struct(data(7, :)', {'numberPer1000', 'woolWeightPerHd', 'woolPricePerKg'});
model.woolSales.DSEPer1000 = handles.woolSales.DSEPer1000;
model.woolSales.shearingMonth = get(handles.popupmenuWoolSalesMonth, 'Value');

% Sheep Sales
data = get(handles.uitableSheepSales, 'Data');

model.sheepSales.CFAEwes = cell2struct(data(1, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.eweHoggets = cell2struct(data(2, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.eweLambs = cell2struct(data(3, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.CFARams = cell2struct(data(4, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.CFAWethers = cell2struct(data(5, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.wetherHoggets = cell2struct(data(6, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});
model.sheepSales.wetherLambs = cell2struct(data(7, :)', {'numberPer1000', 'pricePerHdCS2', 'pricePerHdCS3'});

model.sheepSales.sheepSalesMonth = get(handles.popupmenuSheepSalesMonth, 'Value');

%model.spatialInteractions = handles.spatialInteractions;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.output = [];
guidata(hObject, handles);
uiresume(gcf);



function editDSEConversion_Callback(hObject, eventdata, handles)
% hObject    handle to editDSEConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDSEConversion as text
%        str2double(get(hObject,'String')) returns contents of editDSEConversion as a double
val = str2double(get(hObject, 'String'));

if isnan(val)
    set(hObject, 'String', num2str(handles.woolSales.DSEPer1000));
else
    handles.woolSales.DSEPer1000 = val;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function editDSEConversion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDSEConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit17 as text
%        str2double(get(hObject,'String')) returns contents of edit17 as a double


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit18 as text
%        str2double(get(hObject,'String')) returns contents of edit18 as a double


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuSheepSalesMonth.
function popupmenuSheepSalesMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSheepSalesMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSheepSalesMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSheepSalesMonth


% --- Executes during object creation, after setting all properties.
function popupmenuSheepSalesMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSheepSalesMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuWoolSalesMonth.
function popupmenuWoolSalesMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuWoolSalesMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuWoolSalesMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuWoolSalesMonth


% --- Executes during object creation, after setting all properties.
function popupmenuWoolSalesMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuWoolSalesMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuStartMonth.
function popupmenuStartMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuStartMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuStartMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuStartMonth


% --- Executes during object creation, after setting all properties.
function popupmenuStartMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuStartMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuPeakFOOGrowthMonth.
function popupmenuPeakFOOGrowthMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPeakFOOGrowthMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuPeakFOOGrowthMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuPeakFOOGrowthMonth


% --- Executes during object creation, after setting all properties.
function popupmenuPeakFOOGrowthMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPeakFOOGrowthMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuMinFOOGrowthMonth.
function popupmenuMinFOOGrowthMonth_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMinFOOGrowthMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMinFOOGrowthMonth contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMinFOOGrowthMonth


% --- Executes during object creation, after setting all properties.
function popupmenuMinFOOGrowthMonth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMinFOOGrowthMonth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in pushbuttonSettingsFileSelect.
function pushbuttonSettingsFileSelect_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSettingsFileSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, path, filt] = uigetfile('.m', 'Select Shelter Settings File', './Resources/ShelterSettingsFiles');

if(isequal(path, 0) || isequal(file, 0))
    % User cancelled load: do nothing.
    return
end

handles.FOO.shelterSettingsFile = file;
guidata(hObject, handles);

set(handles.textShelterSettingsFile, 'String', file);
