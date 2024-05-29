function varargout = cropWizard(varargin)
% CROPWIZARD M-file for cropWizard.fig
%      CROPWIZARD, by itself, creates a new CROPWIZARD or raises the existing
%      singleton*.
%
%      H = CROPWIZARD returns the handle to a new CROPWIZARD or the handle to
%      the existing singleton*.
%
%      CROPWIZARD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD.M with the given input arguments.
%
%      CROPWIZARD('Property','Value',...) creates a new CROPWIZARD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard

% Last Modified by GUIDE v2.5 18-Feb-2014 17:44:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_OutputFcn, ...
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


% --- Executes just before cropWizard is made visible.
function cropWizard_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard (see VARARGIN)

% Arguments are optional, but the first will be an existing crop to edit,
% or empty and the second will be a cell array of crop names, or empty.


% Choose default command line output for cropWizard
handles.output = hObject;

% Sort out whether this is a new crop, or if we were passed one.
% Use initialiseCropWizard to load the crop into the handles structure if
% appropriate.
%handles = initialiseCropWizard(handles, varargin);



opengl software

set(handles.subPanel, 'Title', '');

set(handles.titleEdit, 'String', 'Step 1: Name and category');

step1.title = 'Name and category';
step1.figFile = 'cropWizard_general.fig';
step1.mfile = @cropWizard_general;

steps(1) = step1;

steps(2).title = 'Growth Model';
steps(2).figFile = 'cropWizard_GrowthModel.fig';
steps(2).mfile = @cropWizard_GrowthModel;

steps(3).title = 'Events and Triggers';
steps(3).figFile = 'cropWizard_triggers.fig';
steps(3).mfile = @cropWizard_triggers;

steps(4).title = 'Products';
steps(4).figFile = 'cropWizard_products.fig';
steps(4).mfile = @cropWizard_products;

steps(5).title = 'Costs';
steps(5).figFile = 'cropWizard_costs.fig';
steps(5).mfile = @cropWizard_costs;

%steps(6).title = 'Competition Zone';
%steps(6).figFile = 'cropWizard_category.fig';
%steps(6).mfile = @cropWizard_category;

%steps(7).title = 'Temporal Effects';
%steps(7).figFile = 'cropWizard_category.fig';
%steps(7).mfile = @cropWizard_category;

handles.steps = steps;
handles.currentStep = 1;
handles.subHandles = [];
guidata(hObject, handles);

% Load the input crop or set to empty
if nargin > 3
    if isa(varargin{1}, 'Crop')
        handles.passedCrop = varargin{1};
    else
        handles.passedCrop = [];
    end
    
    if nargin > 4
       if iscell(varargin{2})
           handles.cropNamesList = varargin{2};                   
       else
           handles.cropNamesList = [];
       end
    end
else
    handles.passedCrop = [];
    handles.cropNamesList = [];
end

% We are going to do away with the idea of a different kind of wizardCrop, and just have a
% Crop. If the Crop is returned it becomes the new Crop, otherwise the
% original Crop remains.

if ~isempty(handles.passedCrop)
    handles.wizardCrop = cloneHandleObject(handles.passedCrop);
else
    handles.wizardCrop = Crop();
end

handles.currentCategories = CropCategory.setupCategories();

% save handles
guidata(hObject, handles);

% Load the controls for step 1.
loadStep(handles.currentStep, handles);
set(handles.backButton, 'Enable', 'off');
set(handles.finishButton', 'Enable', 'off');
set(handles.saveButton, 'Enable', 'off');

handles = guidata(hObject);

% Populate step 1.
steps(1).mfile('populateStep', handles.subHandles);



% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes cropWizard wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now.
delete(handles.figure1);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on button press in nextButton.
function nextButton_Callback(hObject, eventdata, handles)
% hObject    handle to nextButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Enable', 'off') 

cropData = handles.steps(handles.currentStep).mfile('saveStep', handles.subHandles); 
if isempty(cropData)
    set(hObject, 'Enable', 'on') 
    return
else
    handles.wizardCrop = cropData;
end


handles.currentStep = handles.currentStep + 1;
guidata(hObject, handles);

enableDisableFig(handles.figure1, 'off');

loadStep(handles.currentStep, handles);
if(handles.currentStep == length(handles.steps))
   set(hObject, 'Enable', 'off') 
   set(handles.finishButton, 'Enable', 'on');
   set(handles.saveButton, 'Enable', 'on');
else
   set(hObject, 'Enable', 'on')     
end
set(handles.backButton, 'Enable', 'on')  

handles = guidata(hObject);

handles.steps(handles.currentStep).mfile('populateStep', handles.subHandles);
enableDisableFig(handles.figure1, 'on');


% --- Executes on button press in backButton.
function backButton_Callback(hObject, eventdata, handles)
% hObject    handle to backButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Enable', 'off');

cropData = handles.steps(handles.currentStep).mfile('saveStep', handles.subHandles); 
if isempty(cropData)
    set(hObject, 'Enable', 'on');
    return
else
    handles.wizardCrop = cropData;
end


handles.currentStep = handles.currentStep - 1;
guidata(hObject, handles);

enableDisableFig(handles.figure1, 'off');

loadStep(handles.currentStep, handles);
if(handles.currentStep == 1)
   set(hObject, 'Enable', 'off')  
else
    set(hObject, 'Enable', 'on');    
end
set(handles.nextButton, 'Enable', 'on') 
set(handles.finishButton', 'Enable', 'off');
set(handles.saveButton, 'Enable', 'off');
   
handles = guidata(hObject);
handles.currentStep
handles.steps(handles.currentStep).mfile('populateStep', handles.subHandles);

enableDisableFig(handles.figure1, 'on');


% --- Executes on button press in finishButton.
function finishButton_Callback(hObject, eventdata, handles)
% hObject    handle to finishButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


wizardCrop = handles.steps(handles.currentStep).mfile('saveStep', handles.subHandles);

% Check the crop name doesn't conflict.
passedCrop = handles.passedCrop;
if isempty(passedCrop)
    passedCropName = '';
else
    passedCropName = passedCrop.name;
end

if strcmp(wizardCrop.name, passedCropName)
    % Then its ok.
else
   cropNamesList = handles.cropNamesList(not(strcmp(passedCropName, handles.cropNamesList)));
   if any(strcmp(wizardCrop.name, cropNamesList))      
        nl=sprintf('\n');
        cropNamesString = '';
        for i = 1:length(cropNamesList)
            cropNamesString = [cropNamesString, nl, cropNamesList{i}];
        end
        prompt = ['The name chosen for this crop conflicts with existing crops. You cannot use the following crop names: ', nl, cropNamesString, nl, nl, 'Enter a new crop name here to continue Accept command:', nl];
        title = 'Crop Name In Use';
        loopDone = false;

        while ~loopDone
            answer = inputdlg(prompt,title);
          
            if isempty(answer)
                % User cancelled.
                return;
            elseif isempty(answer{1})
                uiwait(msgbox('Crop name cannot be empty', 'No Crop Name Defined', 'error', 'modal'));
            elseif any(strcmp(answer{1}, cropNamesList))
                uiwait(msgbox('Crop name already in use. Please enter a crop name not in use.', 'Name Already In Use', 'error', 'modal'));
            else
                loopDone = true;
                wizardCrop.name = answer{1};
            end
        end
   end
end


if ~isempty(wizardCrop)
    
    handles.output = wizardCrop;
    guidata(hObject, handles);
    uiresume(handles.figure1);
end


    
    
% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wizardCrop = handles.steps(handles.currentStep).mfile('saveStep', handles.subHandles);


if~isempty(wizardCrop)
    % open the save dialogue.
    % Need to use uiputfile, as uisave does not compile.
    [file, path, filt] = uiputfile('.mat', 'Save Crop to .MAT File', [ImagineObject.imagineRoot, '/Resources/Crops/', wizardCrop.name, '.mat']);
    
    if(isequal(path, 0) || isequal(file, 0))
        % User cancelled save. Do nothing.
        
    else
        filename = [path, file];
        crop = wizardCrop;
        save(filename, 'crop')
    end
else
    msgbox('Crop is not well defined. Cannot save the crop yet.');
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Opens the uigetfile dialogue. Imports the resulting file. If the contents
% are a valid crop, it sets the dialogue to have those contents.

[file, path, filt] = uigetfile('.mat', 'Load Crop from File', [ImagineObject.imagineRoot, '/Resources/Crops']);

if(isequal(path, 0) || isequal(file, 0))
    % If path or file are zero, user cancelled the export. Do nothing.
    return
end
    
cropData = load([path, file]);

% Can customise the load process here. This can be used for backward
% compatability.

if isfield(cropData, 'crop')
    if strcmp(class(cropData.crop), 'Crop')
        crop = cropData.crop;
    end
end

if(Crop.isValid(crop) || true)
%     wizardCrop = convertCropToWizardCrop(crop);
    handles.wizardCrop = crop;
    handles.currentStep = 1;
    guidata(hObject, handles);
    loadStep(1, handles);
    handles = guidata(hObject);
    handles.steps(handles.currentStep).mfile('populateStep', handles.subHandles);

    % Temporary while debugging.
   % finishButton_Callback(handles.finishButton, eventdata, handles)
    
else
    msgbox('Failed to load crop file. Not a valid crop.');
end

% --- Executes on button press in step1Button.
function step1Button_Callback(hObject, eventdata, handles)
% hObject    handle to step1Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton16.
function pushbutton16_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% This function loads the step into the main window. Handles to the 
% subwindow's controls are provided in handles.subHandles
function loadStep(stepNum, handles)


stepNum = floor(stepNum); % Just in case

if(stepNum < 1 || stepNum > length(handles.steps))
    return
end

% delete any existing children of the subpanel
% But delete the cropWizard field first
if isfield(handles.subHandles, 'wizardCrop')
    handles.subHandles = rmfield(handles.subHandles, 'wizardCrop');
end
removeHandles(handles.subHandles);

% Load the first page fig.
td = load(handles.steps(stepNum).figFile, '-MAT');
if(~isempty(td.hgS_070000.children))
    hs =  struct2handle(td.hgS_070000.children, repmat(handles.subPanel, length(td.hgS_070000.children), 1), 'convert');
    
    callbackToUseSubHandles(hs);
    
    handles.subHandles = grabHandles(hs);
end

handles.subHandles.wizardCrop = handles.wizardCrop;

% Opening Fcn may change handles, so save.
guidata(handles.subPanel, handles);
handles.steps(stepNum).mfile([handles.steps(stepNum).figFile(1:end-4), '_OpeningFcn'], handles.subPanel, [], handles.subHandles, []);

% Opening Fcn may have changed handles. Get it again.
handles = guidata(handles.subPanel);
%disp('End of cropWizard.loadStep');
handles.currentStep = stepNum;
set(handles.titleEdit, 'String', ['Step ', num2str(stepNum), ': ', handles.steps(stepNum).title]);

guidata(handles.subPanel, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figure1);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figure1);
end


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extractPlotData(handles.figure1, true);