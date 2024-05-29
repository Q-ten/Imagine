function varargout = cropWizard_GrowthModel(varargin)
% CROPWIZARD_GROWTHMODEL M-file for cropWizard_GrowthModel.fig
%      CROPWIZARD_GROWTHMODEL, by itself, creates a new CROPWIZARD_GROWTHMODEL or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_GROWTHMODEL returns the handle to a new CROPWIZARD_GROWTHMODEL or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_GROWTHMODEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_GROWTHMODEL.M with the given input arguments.
%
%      CROPWIZARD_GROWTHMODEL('Property','Value',...) creates a new CROPWIZARD_GROWTHMODEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_GrowthModel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_GrowthModel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_GrowthModel

% Last Modified by GUIDE v2.5 30-Dec-2011 13:35:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_GrowthModel_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_GrowthModel_OutputFcn, ...
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


% --- Executes just before cropWizard_GrowthModel is made visible.
function cropWizard_GrowthModel_OpeningFcn(hObject, eventdata, subHandles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_GrowthModel (see VARARGIN)

% Choose default command line output for cropWizard_GrowthModel
%handles = guidata(hObject);
%handles.subHandles.output = hObject;

% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes cropWizard_GrowthModel wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_GrowthModel_OutputFcn(hObject, eventdata, subHandles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];



function cropNameEdit_Callback(hObject, eventdata, subHandles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cropNameEdit as text
%        str2double(get(hObject,'String')) returns contents of cropNameEdit as a double


% --- Executes during object creation, after setting all properties.
function cropNameEdit_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to cropNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in categoryDDL.
function categoryDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns categoryDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from categoryDDL


% --- Executes during object creation, after setting all properties.
function categoryDDL_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to categoryDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeColourButton.
function changeColourButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to changeColourButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in growthModelDDL.
function growthModelDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to growthModelDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Just need to set the new growth model's state elements and populate the axes. 
renderGrowthModel(subHandles);



% --- Executes during object creation, after setting all properties.
function growthModelDDL_CreateFcn(hObject, eventdata, subHandles)
% hObject    handle to growthModelDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% % --- Executes on button press in setupGMButton.
% function setupGMButton_Callback(hObject, eventdata, subHandles)
% % hObject    handle to setupGMButton (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % GMData should already be set in the populateStep 
% % Where do we sort out the GMData? Do we pass the dialog the whole GMData
% % and let it figure it out? Or do we pass only a valid GMData?
% % I think we can only pass a valid one. If the parameters are not all
% % valid, then do not pass a GM parameter. Let the dialog use it's defaults.
% 
% % Looks very much like the validate step function. If step is valid, pass
% % the paramters, otherwise, dont.
% 
% % 1). If there are valid parameters for the growthModel, then we want to use
% % them to initialise the growthModel dialog.
% %
% % 2). We get the growth model from the DDL.
% %
% % 3). Then we look up the stepData. This will have an field 'wizardCrop'.
% % This field will have been initialised when the view is populated, and
% % will be saved as the real wizardCrop when we move on from the step. So we
% % will not need to check handles.wizardCrop because it will not be the
% % right one.
% %
% % 4). global GMData is used extensively in the dialog code. It would be a
% % nightmare changing it. We can get by if we populate GMData before we
% % launch the dialog, and then extract the parameters back when the dialog
% % closes. How then, do we make GMData? Set it empty, then for each
% % parameter in the list, combine handles into GMData? To get them back, you
% % could uncombine them.... Or is it better to go through the dialog and get
% % _EVERYTHING_ into the parameters model.
% %
% % In the past, growthModel has been a structure with the fields that will
% % be interpreted by the functions we defined. It really is better practice
% % to not lump everything together. Now, our growthModel is a structure that
% % contains fields for functions, parameters that are passed to said
% % functions, and functions that check the validity of the parameters. This
% % is a much more organised structure, and clearly extensible through the
% % events list. GMs also have element count and state description. They will
% % probably also have a product list (although it is possible that this
% % could be gotten through a function.) It depends where we want to put the
% % products of a transition function - as outputs from the function itself,
% % or as a list seperate to the function that needs to be maintained. In the
% % function seems nicer.
% %
% % So... what we should really be doing is restructuring the growth model so
% % that the parameters are set and gotten from the right place, rather than
% % GMData. They should really be set in the handles struct of the dialog.
% %
% % How do we structure them in the handles struct? What does the GMDialog
% % have control over? The parameters. So it should only be setting them. But
% % the parameters are associated with a particular 'event', which has a
% % name. The setupCategories function should be the ultimate arbiter. If it
% % is not set up in there, it is wrong. But it would be nice that if we
% % changed the name of an event in setupCategories, we dont have to change
% % it in the GMDialog all over the place. Regardless of what the events are
% % called, parameters for a given event will remain chunked. So if we
% % reference a parameter structure by number, it would be independent of any
% % name.
% %
% % Example:
% %
% % handles.gm.plantingParameters.A0 = x
% % handles.gm.plantingParameters.B0 = y
% %
% % handles.gm.events(1).parameters.B_post_coppice_loss = 20;
% % 
% % or perhaps
% % handles.gm.events('Coppice Harvest').parameters.B_post_coppice_loss = 20;
% % 
% %
% % Then later when we're done
% %
% % GMData = handles.gm;
% %
% % back on the other side, we need to get the planting parameters, and loop
% % through the events and set them. How about we set the name of the event
% % in the dialog, and we set the parameters for some event by the name, not
% % the index.
% 
% % Check current GM for validity.
% 
% [valid, msg] = validateStep(subHandles);
% 
% % Get the current dialog function, and parameters.
% wc = subHandles.wizardCrop;
% catIndex = find(strcmp(wc.categoryChoice, {wc.categories.name}));
% cat = subHandles.wizardCrop.categories(catIndex);
% gmChoices = get(subHandles.growthModelDDL, 'String');
% gmChoice = gmChoices{get(subHandles.growthModelDDL, 'Value')};
% gmIndex = find(strcmp(gmChoice, {cat.growthModels.name}));
% 
% handles = guidata(subHandles.growthModelDDL);
% sGM = handles.stepData.wizardCrop.categories(catIndex).growthModels(gmIndex);
% 
% 
% % Run the dialog
% if valid    
%     % If the cropNames list doesn't yet contain the current crop's name, add it.
%     if ~any(strcmp(handles.cropNamesList, handles.wizardCrop.name))
%         handles.cropNamesList = [handles.cropNamesList, handles.wizardCrop.name];
%     end
%     gmData = cat.growthModels(gmIndex).parameterDialog(cat.name, sGM, handles.cropNamesList);
% else
%     gmData = cat.growthModels(gmIndex).parameterDialog(cat.name, [],  handles.cropNamesList);
% end
% 
% % Retrieve the new data and save it. The protocol is that if the dialog is
% % cancelled, gmData has been set to empty.
% 
% if ~isempty(gmData)
%     sGM(1).propagationParameters = gmData.propagationParameters;
%     for i = 1:length(sGM.events)
%         sGM.events(i).parameters = gmData.events(i).parameters;
%     end
%     handles.stepData.wizardCrop.categories(catIndex).growthModels(gmIndex) = sGM;
%     guidata(subHandles.growthModelDDL, handles);
% end
% disp('qq')
% sGM(1).propagationParameters
% sGM.events(1).parameters
% sGM.events(2).parameters

%
% This function populates the step using the categories and crop
%
function populateStep(subHandles)

wizardCrop = subHandles.wizardCrop;


gmDescriptions = wizardCrop.category.possibleGrowthModelDescriptions;

set(subHandles.growthModelDDL, 'String', {gmDescriptions.name});

% Set the value of the growth model if that field exists.
gmName = wizardCrop.category.growthModelChoice; 
gmIndex = find(strcmp(gmName,  {gmDescriptions.name}));

if isempty(gmIndex)
   gmIndex = 1;
end

set(subHandles.growthModelDDL, 'Value', gmIndex);
    

% Populate the state elements list.
ses = gmDescriptions(gmIndex).stateDescription;
if length(ses) <= 7
    set(subHandles.stateElements1Label, 'String', ses);
    set(subHandles.stateElements2Label, 'String', '');    
elseif length(ses) <= 14
    set(subHandles.stateElements1Label, 'String', ses(1:7));
    set(subHandles.stateElements2Label, 'String', ses(8:14));    
else    
    set(subHandles.stateElements1Label, 'String', ses(1:7));
    set(subHandles.stateElements2Label, 'String', {ses(8:13), '...'});    
end

% Get the real (super) handles struct.
% Clear stepData and reset it to wizardCrop
handles = guidata(subHandles.growthModelDDL);
handles.stepData = [];
handles.stepData(1).wizardCrop = wizardCrop;
guidata(subHandles.growthModelDDL, handles);

% Populate the axes if appropriate
renderGrowthModel(subHandles);

% This function tries to find a growthModel and then renders it into the
% axes.
function renderGrowthModel(subHandles)

superHandles = guidata(subHandles.growthModelDDL);

wizardCrop = superHandles.stepData.wizardCrop;
gm = wizardCrop.category.growthModel;

if ~isempty(gm)
    gm.renderGrowthModel(subHandles.axes1);
end



function [valid, msg] = validateStep(subHandles)
msg = {};

wc = subHandles.wizardCrop;

% The growth model object should not be empty, and should be valid and
% ready.
if GrowthModel.isValid(wc.growthModel)
    valid = 1;
else
    valid = 0;
    msg = [msg, {'GrowthModel is not valid.'}];
end

if GrowthModel.isReady(wc.growthModel)
    valid = valid & true;
else
    valid = 0;
    msg = [msg, {'GrowthModel is not ''ready.'' Check that the parameters are ok.'}];
end


%
% This function saves the choices in this step to the crop.
% 
function wizardCrop = saveStep(subHandles)

handles = guidata(subHandles.growthModelDDL);
wizardCrop = handles.stepData.wizardCrop;
subHandles.wizardCrop = wizardCrop;

% Check that the selected GM has valid parameters.
[valid, msgs] = validateStep(subHandles);

if ~valid
   uiwait(errordlg([{'Step is not valid due to the following problems:', '', ''}, msgs], 'Step Not Valid'));
   wizardCrop = [];
   return
else
    % return the valid wizardCrop.
end



% --- Executes on selection change in stateElementsListBox.
function stateElementsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to stateElementsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns stateElementsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stateElementsListBox


% --- Executes during object creation, after setting all properties.
function stateElementsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stateElementsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setupGMButton.
function setupGMButton_Callback(hObject, eventdata, subHandles)
% hObject    handle to setupGMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set the gmChoice based on the DDL.
% Launch the GUI. If the return value is not empty, set the step's
% wizardCrop's growthModel.
% Save the step.

gmChoices = get(subHandles.growthModelDDL, 'String');
gmChoice = gmChoices{get(subHandles.growthModelDDL, 'Value')};

superHandles = guidata(hObject);

wizardCrop = superHandles.stepData.wizardCrop;
wizardCrop.category.growthModelChoice = gmChoice;    

gm = wizardCrop.category.growthModel.setupGrowthModel(wizardCrop.name);
if ~isempty(gm)
    wizardCrop.category.growthModel = gm;
    gm.renderGrowthModel(subHandles.axes1);
end

superHandles.stepData.wizardCrop = wizardCrop;
guidata(hObject, superHandles);
