function varargout = GrassGroGrowthModelDialog(varargin)
% GRASSGROGROWTHMODELDIALOG M-file for GrassGroGrowthModelDialog.fig
%      GRASSGROGROWTHMODELDIALOG, by itself, creates a new GRASSGROGROWTHMODELDIALOG or raises the existing
%      singleton*.
%
%      H = GRASSGROGROWTHMODELDIALOG returns the handle to a new GRASSGROGROWTHMODELDIALOG or the handle to
%      the existing singleton*.
%
%      GRASSGROGROWTHMODELDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRASSGROGROWTHMODELDIALOG.M with the given input arguments.
%
%      GRASSGROGROWTHMODELDIALOG('Property','Value',...) creates a new GRASSGROGROWTHMODELDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GrassGroGrowthModelDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GrassGroGrowthModelDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GrassGroGrowthModelDialog

% Last Modified by GUIDE v2.5 14-Jan-2013 06:41:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GrassGroGrowthModelDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @GrassGroGrowthModelDialog_OutputFcn, ...
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

    default.woolSales.ewes = struct('woolPricePerKg', 8.47);
    default.woolSales.eweHoggets = struct('woolPricePerKg', 9.07);
    default.woolSales.eweLambs = struct('woolPricePerKg', 4.07);
%    default.woolSales.rams = struct('woolPricePerKg', 8.48);
    default.woolSales.wethers = struct('woolPricePerKg', 8.48);
    default.woolSales.wetherHoggets = struct('woolPricePerKg', 9.07);
    default.woolSales.wetherLambs = struct('woolPricePerKg', 4.07);

    default.sheepSales.CFAEwes = struct('pricePerHdCS2', 88.85, 'pricePerHdCS3', 88.85);
    default.sheepSales.eweHoggets = struct('pricePerHdCS2', 135, 'pricePerHdCS3', 135);
    default.sheepSales.eweLambs = struct('pricePerHdCS2', 102.52, 'pricePerHdCS3', 102.52);
%    default.sheepSales.CFARams = struct('pricePerHdCS2', 60.48, 'pricePerHdCS3', 60.48);
    default.sheepSales.CFAWethers = struct('pricePerHdCS2', 80.48, 'pricePerHdCS3', 80.48);
    default.sheepSales.wetherHoggets = struct('pricePerHdCS2', 135, 'pricePerHdCS3', 135);
    default.sheepSales.wetherLambs = struct('pricePerHdCS2', 102.52, 'pricePerHdCS3', 102.52);
    default.sheepSales.salesCommission = 5;
    
    default.costs.ewes = struct('maintenance', 1.1, 'shearing', 5.89);
    default.costs.eweHoggets = struct('maintenance', 1.1, 'shearing', 5.89);
    default.costs.eweLambs = struct('maintenance', 1.1, 'shearing', 1.5);
%    default.costs.rams = struct('maintenance', 8, 'shearing', 2.5);
    default.costs.wethers = struct('maintenance', 1.1, 'shearing', 5.89);
    default.costs.wetherHoggets = struct('maintenance', 1.1, 'shearing', 5.89);
    default.costs.wetherLambs = struct('maintenance', 1.1, 'shearing', 1.5);

    default.ggm = GrassGroModel;
    
    default.spatialInteractions = SpatialInteractions.empty(1, 0);
    
    fields = {'woolSales', 'sheepSales', 'costs', 'ggm', 'spatialInteractions'};

    gm = struct;
    for i = 1:length(fields)        
        if (nargin >= i)
           gm.(fields{i}) = varargin{i};
        end
    end

    gm = absorbFields(default, gm);


% --- Executes just before GrassGroGrowthModelDialog is made visible.
function GrassGroGrowthModelDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GrassGroGrowthModelDialog (see VARARGIN)

% Input cropName, model.
% model has fields woolSales, sheepSales, costs, and ggm which should be a
% GrassGroModel.

if nargin >= 4
   handles.cropName = varargin{1};
else
    handles.cropName = 'Pasture';
end

gm = struct();
if nargin >= 5
    model = varargin{2};
    if (isfield(model, 'spatialInteractions'))
        gm = setupParameters(model.woolSales, model.sheepSales, model.costs, model.ggm, model.spatialInteractions);
    else
        gm = setupParameters(model.woolSales, model.sheepSales, model.costs, model.ggm);
    end
else
    gm = setupParameters();
end
fns = fieldnames(gm);
for i = 1:length(fns)
    handles.(fns{i}) = gm.(fns{i});
end


guidata(hObject, handles);
populateDialog(handles);

% Choose default command line output for GrassGroGrowthModelDialog
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GrassGroGrowthModelDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GrassGroGrowthModelDialog_OutputFcn(hObject, eventdata, handles) 
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


function populateDialog(handles)

% Set the picture

picture = './Resources/PastureImage.bmp';            
try 
    im = imread(picture);
    im = im(end:-1:1,:,:);
end

axes(handles.axes1);
cla
image('CData', im);
%570 520
axis([50 525 100 420])
axis on

% Load the data into the tables.

% Wool Sales
data = [ ...
        struct2cell(handles.woolSales.ewes)'; ...
        struct2cell(handles.woolSales.eweHoggets)'; ...
        struct2cell(handles.woolSales.eweLambs)'; ...
%        struct2cell(handles.woolSales.rams)'; ...
        struct2cell(handles.woolSales.wethers)'; ...
        struct2cell(handles.woolSales.wetherHoggets)'; ...
        struct2cell(handles.woolSales.wetherLambs)'; ...
        ];

set(handles.uitableWoolSales, 'Data', data);

% Sheep Sales
data = [ ...
        struct2cell(handles.sheepSales.CFAEwes)'; ...
        struct2cell(handles.sheepSales.eweHoggets)'; ...
        struct2cell(handles.sheepSales.eweLambs)'; ...
  %      struct2cell(handles.sheepSales.CFARams)'; ...
        struct2cell(handles.sheepSales.CFAWethers)'; ...
        struct2cell(handles.sheepSales.wetherHoggets)'; ...
        struct2cell(handles.sheepSales.wetherLambs)'; ...
        ];

set(handles.uitableSheepSales, 'Data', data);
set(handles.editSalesCommission, 'String', num2str(handles.sheepSales.salesCommission));

% Costs
data = [ ...
        struct2cell(handles.costs.ewes)'; ...
        struct2cell(handles.costs.eweHoggets)'; ...
        struct2cell(handles.costs.eweLambs)'; ...
 %       struct2cell(handles.costs.rams)'; ...
        struct2cell(handles.costs.wethers)'; ...
        struct2cell(handles.costs.wetherHoggets)'; ...
        struct2cell(handles.costs.wetherLambs)'; ...
        ];

set(handles.uitableCosts, 'Data', data);
set(handles.editSalesCommission, 'String', num2str(handles.sheepSales.salesCommission));

set(handles.popupmenuPaddockNumber, 'Value', handles.ggm.paddockNumber);
set(handles.textPaddockNumber, 'String', num2str(handles.ggm.paddockNumber));

set(handles.editPaddockSize, 'String', num2str(handles.ggm.paddockSize));

% GrassGroModel
populateGrassGroModelValidity(handles);

% Sort out labels for spatial interactions
refreshSpatialInteractionLabels(handles)


% Populates the data section for the table that displays the validity.
function populateGrassGroModelValidity(handles)

    ggm = handles.ggm;

    dataHeadings = ggm.classBasedHeaders;
    nonClassSectionHeaders = {'Yearly Attributions', 'Monthly Supplement Cost'};

    validSections = cell(length(dataHeadings) + 2, 1);
    for i = 1:length(dataHeadings)
       if (ggm.checkSectionValidity(dataHeadings{i}))
           validSections{i, 1} = '<html><center><font color="green">Ok</font></center></html>'; 
       else
           validSections{i, 1} = '<html><center><font color="red"><center/>Not Ok</center></font></html>'; 
       end
    end
   if (ggm.checkSectionValidity(nonClassSectionHeaders{1}))           
       validSections{end - 1, 1} = '<html><center><font color="green">Ok</font></center></html>'; 
   else
       validSections{end - 1, 1} = '<html><center><font color="red">Not Ok</font></center></html>'; 
   end
   if (ggm.checkSectionValidity(nonClassSectionHeaders{2}))           
       validSections{end, 1} = '<html><center><font color="green">Ok</font></center></html>'; 
   else
       validSections{end, 1} = '<html><center><font color="red">Not Ok</font></center></html>'; 
   end
    set(handles.uitableValidity, 'Data', validSections);

% Pulls the data out of controls
function model = retrieveModel(handles)

    % Wool Sales
    data = get(handles.uitableWoolSales, 'Data');
    model.woolSales.ewes = cell2struct(data(1, :)', {'woolPricePerKg'});
    model.woolSales.eweHoggets = cell2struct(data(2, :)', {'woolPricePerKg'});
    model.woolSales.eweLambs = cell2struct(data(3, :)', {'woolPricePerKg'});
%    model.woolSales.rams = cell2struct(data(4, :)', {'woolPricePerKg'});
    model.woolSales.wethers = cell2struct(data(4, :)',{'woolPricePerKg'});
    model.woolSales.wetherHoggets = cell2struct(data(5, :)', {'woolPricePerKg'});
    model.woolSales.wetherLambs = cell2struct(data(6, :)', {'woolPricePerKg'});

    % Sheep Sales
    data = get(handles.uitableSheepSales, 'Data');

    model.sheepSales.CFAEwes = cell2struct(data(1, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
    model.sheepSales.eweHoggets = cell2struct(data(2, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
    model.sheepSales.eweLambs = cell2struct(data(3, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
 %   model.sheepSales.CFARams = cell2struct(data(4, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
    model.sheepSales.CFAWethers = cell2struct(data(4, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
    model.sheepSales.wetherHoggets = cell2struct(data(5, :)', {'pricePerHdCS2', 'pricePerHdCS3'});
    model.sheepSales.wetherLambs = cell2struct(data(6, :)', {'pricePerHdCS2', 'pricePerHdCS3'});

    model.sheepSales.salesCommission = str2double(get(handles.editSalesCommission, 'String'));

    % Costs
    data = get(handles.uitableCosts, 'Data');

    model.costs.ewes = cell2struct(data(1, :)', {'maintenance', 'shearing'});
    model.costs.eweHoggets = cell2struct(data(2, :)', {'maintenance', 'shearing'});
    model.costs.eweLambs = cell2struct(data(3, :)', {'maintenance', 'shearing'});
%    model.costs.CFARams = cell2struct(data(4, :)', {'maintenance', 'shearing'});
    model.costs.wethers = cell2struct(data(4, :)', {'maintenance', 'shearing'});
    model.costs.wetherHoggets = cell2struct(data(5, :)', {'maintenance', 'shearing'});
    model.costs.wetherLambs = cell2struct(data(6, :)', {'maintenance', 'shearing'});

    % GrassGroModel
    model.ggm = handles.ggm;
    
    % SpatialInteractions
    model.spatialInteractions = handles.spatialInteractions;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.output = [];
guidata(hObject, handles);
uiresume(gcf);


function editSalesCommission_Callback(hObject, eventdata, handles)
% hObject    handle to editSalesCommission (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSalesCommission as text
%        str2double(get(hObject,'String')) returns contents of editSalesCommission as a double
num = str2double(get(hObject,'String'));
if isnan(num)
    set(hObject, 'String', num2str(handles.sheepSales.salesCommission))
else
    handles.sheepSales.salesCommission = num;
end

% --- Executes during object creation, after setting all properties.
function editSalesCommission_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSalesCommission (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonEditGGM.
function pushbuttonEditGGM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEditGGM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Launch the GGM editor.
newGGM = GrassGroEditor(handles.ggm);

if ~isempty(newGGM)
    handles.ggm.copyFields(newGGM);
    guidata(hObject, handles);
    populateGrassGroModelValidity(handles);    
end


% --- Executes on button press in pushbuttonLoadFromSpreadsheet.
function pushbuttonLoadFromSpreadsheet_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadFromSpreadsheet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


 [file, path, filt] = uigetfile('.xls', 'Load GrassGro output spreadsheet', './Resources/');

    if(isequal(path, 0) || isequal(file, 0))
        % User cancelled load: do nothing.
        return
    end
    handles.ggm.importFile([path, file]);
    populateGrassGroModelValidity(handles);    

           


% --- Executes during object deletion, before destroying properties.
function uitableSheepSales_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to uitableSheepSales (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenuPaddockNumber.
function popupmenuPaddockNumber_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPaddockNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuPaddockNumber contents as cell array
%        contents{get(hObject,'Value')} returns selected item from
%        popupmenuPaddockNumber
handles.ggm.paddockNumber = get(hObject, 'Value');
set(handles.textPaddockNumber, 'String', num2str(handles.ggm.paddockNumber));
% guidata not needed since ggm is a handle class.



% --- Executes during object creation, after setting all properties.
function popupmenuPaddockNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPaddockNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPaddockSize_Callback(hObject, eventdata, handles)
% hObject    handle to editPaddockSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPaddockSize as text
%        str2double(get(hObject,'String')) returns contents of editPaddockSize as a double
paddockSize = str2double(get(hObject, 'String'));
if isnan(paddockSize)
    set(hObject, 'String', num2str(handles.ggm.paddockSize));
else
    handles.ggm.paddockSize = paddockSize;
    % saving guidata unnecessary since ggm is a handle object.
end

% --- Executes during object creation, after setting all properties.
function editPaddockSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPaddockSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonSetupSIS.
function pushbuttonSetupSIS_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupSIS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cropInfo.cropName = handles.cropName;
sis = SpatialInteractionsForPastureDialog(cropInfo, handles.spatialInteractions);
if ~isempty(sis)
    handles.spatialInteractions = sis;
    guidata(hObject, handles);
    refreshSpatialInteractionLabels(handles);
end

function refreshSpatialInteractionLabels(handles)
sis = handles.spatialInteractions;
if ~isempty(sis) && strcmp(class(sis), 'SpatialInteractions');
    if sis.useCompetition
        set(handles.textCompetitionEffect, 'String', 'ON');
    else
        set(handles.textCompetitionEffect, 'String', 'OFF');    
    end

    if sis.useWaterlogging
        set(handles.textWaterloggingEffect, 'String', 'ON');
    else
        set(handles.textWaterloggingEffect, 'String', 'OFF');    
    end
else
    set(handles.textCompetitionEffect, 'String', 'NOT SET');
    set(handles.textWaterloggingEffect, 'String', 'NOT SET');
end
