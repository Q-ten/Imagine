function varargout = cropWizard_general(varargin)
% CROPWIZARD_GENERAL M-file for cropWizard_general.fig
%      CROPWIZARD_GENERAL, by itself, creates a new CROPWIZARD_GENERAL or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_GENERAL returns the handle to a new CROPWIZARD_GENERAL or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_GENERAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_GENERAL.M with the given input arguments.
%
%      CROPWIZARD_GENERAL('Property','Value',...) creates a new CROPWIZARD_GENERAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_general_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_general_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_general

% Last Modified by GUIDE v2.5 17-Jan-2011 11:51:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_general_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_general_OutputFcn, ...
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


% --- Executes just before cropWizard_general is made visible.
function cropWizard_general_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_general (see VARARGIN)

% Choose default command line output for cropWizard_general
%handles.output = hObject;

% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes cropWizard_general wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_general_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];



function cropNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cropNameEdit as text
%        str2double(get(hObject,'String')) returns contents of cropNameEdit as a double
updateTitle(handles);

% --- Executes during object creation, after setting all properties.
function cropNameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in categoryDDL.
function categoryDDL_Callback(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Indexing into setupCategories should work because the list came from
% setupCategories originally.
categoryIndex = get(handles.categoryDDL, 'Value');
categories = CropCategory.setupCategories();
set(handles.firstCoreEventLabel, 'String', categories(categoryIndex).coreEvents);

loadCategoryPicture(handles, categories(categoryIndex).name)


% --- Executes during object creation, after setting all properties.
function categoryDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeColourButton.
function changeColourButton_Callback(hObject, eventdata, handles)
% hObject    handle to changeColourButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
C = uisetcolor;
set(handles.colourPanel, 'BackgroundColor', C);

function updateTitle(handles)

% Get the passedCrop name and the crop name from the edit box.
% If they're different set the title to be PassedCrop (newCrop)
% else just PassedCrop.
superhandles = guidata(handles.cropNameEdit);
passedCrop = superhandles.passedCrop;
if isempty(passedCrop)
    passedCropName = '';
else
    passedCropName = passedCrop.name;
end
newName = get(handles.cropNameEdit, 'String');

if isempty(passedCropName)
    if isempty(newName)
        title = 'New Crop';
    else
        title = ['New Crop (', newName, ')'];            
    end    
elseif  strcmp(newName, passedCropName)
    title = newName;
else
    title = [passedCropName, ' (', newName, ')'];
end
set(superhandles.figure1, 'Name', title);

%
% This function takes a crop as input and populates the relevant controls
% as far as is possible.
%
% At this stage we only care about the names of possible categories.
% We'll populate the wizardCrop with the actual category at the end of this
% step.
% 
function populateStep(handles)

wizardCrop = handles.wizardCrop;

currentCategories = CropCategory.setupCategories();

% First set up the choices for the category
set(handles.categoryDDL, 'String', {currentCategories.name});
    
% wizardCrop should have a name. Get it and put it in the name edit box.
set(handles.cropNameEdit, 'String', wizardCrop.name) 

% wizardCrop should have a colour. Get it and set the crop colour box.
set(handles.colourPanel, 'BackgroundColor', wizardCrop.colour);

% If the crop has a category object, and it matches the list of categories
% in the ds, get it and put it in.
if ~isempty(wizardCrop.category)
    ix = find(strcmp({currentCategories.name}, wizardCrop.category.name));
    if isempty(ix)
        ix = 1;
    end
else
    ix = 1;
end
set(handles.categoryDDL, 'Value', ix)

% Populate the core events labels according to the category.
set(handles.firstCoreEventLabel, 'String', currentCategories(ix).coreEvents);

% Populate the axes according to the category.
loadCategoryPicture(handles, currentCategories(ix).name)

updateTitle(handles);


function [valid, msg] = validateStep(handles)
% Check name field is valid

msg = {};
name = get(handles.cropNameEdit, 'String');

if isempty(name)
   valid = 0;
   msg = [msg, {'Crop Name not defined.'}];
else
   valid = 1; 
end

%
% This function saves the data in the screen to the crop.
%
function wizardCrop = saveStep(handles)

[valid, msgs] = validateStep(handles);
    
if ~valid
   uiwait(errordlg([{'Step is not valid due to the following problems:', '', ''}, msgs], 'Step Not Valid'));
   wizardCrop = [];
   return
end

wizardCrop = handles.wizardCrop;

% Save the name
wizardCrop.name = get(handles.cropNameEdit, 'String');

% Save the crop colour
wizardCrop.colour = get(handles.colourPanel, 'BackgroundColor');

% Save the category
catNames = get(handles.categoryDDL, 'String');
wizardCrop.categoryChoice = catNames{get(handles.categoryDDL, 'Value')};


function loadCategoryPicture(handles, name)

if strcmp(name, 'Coppice Tree Crop')
    picture = 'PlantationImage.bmp';
title = 'Coppice Tree Crop Category';
expo = {'The coppice tree crop category is a category for', ....
        'woody plantations, with a coppice harvest as one of', ...
        'it''s core events.',...
        '',...
        'The coppice harvest removes the above ground biomass',...
        'leaving the below ground biomass. There is currently', ...
        'only one growth model that takes into account the ', ...
        'amount of below and above ground biomass when ',...
        'calculating the growth.'};
    
    
elseif strcmp(name, 'Annual')
    picture = 'WheatImage.bmp';
    title = 'Annual Category';
expo = {'The annual category is a simple category for growing ', ...
        'annuals such as Wheat, Barley, Canola, etc. The core ', ...
        'events are simply Planting and Harvesting, though', ...
        'you''ll be able to add your own for events such as', ...
        'fertilization soon', ...
        '', ...
        'There is only one growth model currently available ', ...
        'for the annnal category: a quadratic yield rainfall', ...
        'based growth model.'};
else
    picture = 'PastureImage.bmp';
    title = 'Pasture Category';
expo = {'The pasture category models a self-replacing flock ', ...
        'of sheep producing wool and meat. ' ...
        };    
end

try 
    im = imread(picture);
    im = im(end:-1:1,:,:);
catch ME
    im = 0.3* ones(558, 800, 3);
end

axes(handles.axes1);
cla
image('CData', im);
axis([0 570 0 520]);
axis on
hold on

    
intro =         {'Imagine is a tool designed to simulate the growth', ...
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
        'Imagine has been developed by Amir Abadi, Don Cooper ', ...
        'and Quenten Thomas.'};

    
    
    
patch([25 25 363 363], [25 495 495 25], 'k', 'FaceAlpha', 0.5);
view([0 90])

%set(gcf, 'Name', 'Welcome');
text(40, 480, title, 'Color', 1*[1,1,1], 'VerticalAlignment', 'top', 'FontSize', 16);
text(40, 410, expo, 'Color', 1*[1,1,1], 'VerticalAlignment', 'top');
