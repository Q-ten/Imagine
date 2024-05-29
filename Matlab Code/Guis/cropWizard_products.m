function varargout = cropWizard_products(varargin)
% CROPWIZARD_PRODUCTS M-file for cropWizard_products.fig
%      CROPWIZARD_PRODUCTS, by itself, creates a new CROPWIZARD_PRODUCTS or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_PRODUCTS returns the handle to a new CROPWIZARD_PRODUCTS or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_PRODUCTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_PRODUCTS.M with the given input arguments.
%
%      CROPWIZARD_PRODUCTS('Property','Value',...) creates a new CROPWIZARD_PRODUCTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_products_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_products_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_products

% Last Modified by GUIDE v2.5 30-Jan-2011 05:07:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_products_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_products_OutputFcn, ...
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


% --- Executes just before cropWizard_products is made visible.
function cropWizard_products_OpeningFcn(hObject, eventdata, subHandles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_products (see VARARGIN)

% Choose default command line output for cropWizard_products
%subHandles.output = hObject;

%handles = guidata(hObject);

% Import the trend dialogue into the trendPanel.



% Update handles structure
%guidata(hObject, subHandles);

% UIWAIT makes cropWizard_products wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_products_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];


function populateStep(subHandles)

% Get the Crop from handles.
wc = subHandles.wizardCrop;

% Get the crop's unique price model definitions. These are priceModels, but
% without the data. Just the name and units.
priceModelDefinitions = wc.getUniquePriceModelDefinitions('Income');

% Use the definitions to get the crop's saved priceModels. This will now
% include ones that haven't yet been saved, copied from the definition
% list.
savedPriceModels = wc.category.getSavedPriceModelsFromDefinitions(priceModelDefinitions);

% Set the names in the listbox.
set(subHandles.productsListBox, 'String', {savedPriceModels.markedUpName});

% Need to load the trend dialogue. 
loadTrendPanel(subHandles);

% loadTrendPanel will change the subHandles struct. Reload.
handles = guidata(subHandles.trendPanel);
subHandles = handles.subHandles;

% Save stepData and trendData
handles.stepData.priceModels = savedPriceModels;
handles.stepData.priceModelIndex = 1;

handles.trendData.trend = handles.stepData.priceModels(1).trend;
handles.trendData.saveNotifier = saveNotifier();
handles.stepData.saveListener = saveListener(handles.figure1, subHandles.productsListBox, handles.trendData.saveNotifier);

guidata(subHandles.trendPanel, handles);

% Load the trend for the first product.
% setTrend and saveTrend will both use the stepData struct, which will
% contain the priceModels from the previous step.
% setTrend will look up stepData, while saveTrend will save it.
% setTrend is called when we choose a product from the list.
% saveTrend is called when we change the trend at all.
setTrend(subHandles, 1);

% cb = 'cropWizard_products(''saveTrend'', getfield(guidata(gcbo), ''subHandles''))';
% set(subHandles.varDataEdit, 'Callback', cb);
% set(subHandles.trendDataEdit, 'Callback', cb);


% This function saves the details of the step. It should use stepData and
% save the info in stepData into wizardCrop, then return wizardCrop.
% The idea is that wizardCrop contains the last saved data, but stepData
% contains data within a step, and when the step gets saved, the info gets
% incorporated into the wizardCrop, which we need to be valid at all times.
% So this function should check that stepData is valid too.
%
function wc = saveStep(subHandles)

% Check that the step is valid. Ie all the priceModels are valid.
[valid, msgs] = validateStep(subHandles);

if ~valid
   uiwait(errordlg([{'Step is not valid due to the following problems:', '', ''}, msgs], 'Step Not Valid'));
   wc = [];
   return
end

handles = guidata(subHandles.trendPanel);

% Save the priceModels into the wizardCrop.
wc = subHandles.wizardCrop;
wc.category = wc.category.setSavedPriceModels(handles.stepData.priceModels);

% We can just save the productPriceModels directly to the growthModel as
% the list came from there and it will go back there.
wc.growthModel.productPriceModels = handles.stepData.priceModels;



% This function checks the step is valid. That is, the products all have valid
% trends.
function [valid, msgs] = validateStep(subHandles)

msgs = {};
handles = guidata(subHandles.trendPanel);
stepData = handles.stepData;

valid = 1;
for i = 1:length(stepData.priceModels)
   % There should exist a valid trend for each product. 
   
   if ~Trend.isValid(stepData.priceModels(i).trend)
       valid = 0;
       msgs = [msgs, stepData.priceModels(i).name]; 
   end
    
end

if ~valid 
    msgs = ['The following products do not have valid price trends assigned:', msgs];
end


% This function loads the trend dialog into the main window. Handles to the 
% subwindow's controls are provided in handles.subHandles
function loadTrendPanel(subHandles)

handles = guidata(subHandles.trendPanel);

% Load the first page fig.
td = load('trendDialogue.fig', '-MAT');
if(~isempty(td.hgS_070000.children))
    hs =  struct2handle(td.hgS_070000.children, repmat(subHandles.trendPanel, length(td.hgS_070000.children), 1), 'convert');
    
    callbackToUseSubHandles(hs);
    
    trendHandles = grabHandles(hs);
end

% Use combine fields so that all the controls will be removed when we load
% another step.
subHandles = combineFields(subHandles, trendHandles);

handles.subHandles = subHandles;
guidata(subHandles.trendPanel, handles);

disp('end of cropWizardProducts.loadTrend, ie populateStep')


% --- Executes on selection change in productsListBox.
function productsListBox_Callback(hObject, eventdata, subHandles)
% hObject    handle to productsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns productsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from productsListBox

% On change of product name in the list box, save the previous trend and load the trend for the
% selected product.
saveTrend(subHandles);
setTrend(subHandles, get(hObject, 'Value'));



% --- Executes during object creation, after setting all properties.
function productsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to productsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% setTrend looks up the priceModels in stepData and sets the trend to the
% one given by pmIndex. Sets the current priceModelIndex to the pmIndex.
function setTrend(subHandles, pmIndex)

% Set the product index
set(subHandles.productsListBox, 'Value', pmIndex);

handles = guidata(subHandles.trendPanel);
trend = handles.stepData.priceModels(pmIndex).trend;

if isempty(trend)
   trend = Trend(); 
end

handles.trendData.trend = trend;
handles.stepData.priceModelIndex = pmIndex;
guidata(subHandles.trendPanel, handles);

set(subHandles.trendDataEdit, 'String', '');
set(subHandles.varDataEdit, 'String', '');
    
trendDialogue('loadTrendData', subHandles);


% Save trend gets the data from handles.trendData and puts it into the
% current priceModel in stepData.
function saveTrend(subHandles)

handles = guidata(subHandles.trendPanel);
pmIndex = handles.stepData.priceModelIndex;
trend = handles.trendData.trend;

% Save the trend, update the marked up names, save the handles srtuct.
handles.stepData.priceModels(pmIndex).trend = trend;
set(subHandles.productsListBox, 'String', {handles.stepData.priceModels.markedUpName});
guidata(subHandles.trendPanel, handles);
