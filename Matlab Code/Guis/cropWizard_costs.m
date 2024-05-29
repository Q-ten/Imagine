function varargout = cropWizard_costs(varargin)
% CROPWIZARD_COSTS M-file for cropWizard_costs.fig
%      CROPWIZARD_COSTS, by itself, creates a new CROPWIZARD_COSTS or raises the existing
%      singleton*.
%
%      H = CROPWIZARD_COSTS returns the handle to a new CROPWIZARD_COSTS or the handle to
%      the existing singleton*.
%
%      CROPWIZARD_COSTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CROPWIZARD_COSTS.M with the given input arguments.
%
%      CROPWIZARD_COSTS('Property','Value',...) creates a new CROPWIZARD_COSTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropWizard_costs_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropWizard_costs_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropWizard_costs

% Last Modified by GUIDE v2.5 30-Jan-2011 09:12:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropWizard_costs_OpeningFcn, ...
                   'gui_OutputFcn',  @cropWizard_costs_OutputFcn, ...
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


% --- Executes just before cropWizard_costs is made visible.
function cropWizard_costs_OpeningFcn(hObject, eventdata, subHandles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cropWizard_costs (see VARARGIN)

% Choose default command line output for cropWizard_costs
%subHandles.output = hObject;

%handles = guidata(hObject);

% Import the trend dialogue into the trendPanel.



% Update handles structure
%guidata(hObject, subHandles);

% UIWAIT makes cropWizard_costs wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cropWizard_costs_OutputFcn(hObject, eventdata, handles) 
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
priceModelDefinitions = wc.getUniquePriceModelDefinitions('Cost');

% Use the definitions to get the crop's saved priceModels. This will now
% include ones that haven't yet been saved, copied from the definition
% list.
savedPriceModels = wc.category.getSavedPriceModelsFromDefinitions(priceModelDefinitions);

% Check that the denominatorUnit that was saved is still valid. If it's
% not, set it's denominatorUnitIsCurrent  property to false.
handles = guidata(subHandles.trendPanel);
handles.stepData.possiblePriceUnits = wc.category.possiblePriceUnits;
handles.stepData.possiblePriceUnitStrings = wc.category.getPossiblePriceUnitStrings;
handles.stepData.priceModels = savedPriceModels;
guidata(subHandles.trendPanel, handles);
savedPriceModels = checkPriceModelsForCurrentUnits(handles, savedPriceModels);


% Set the names in the listbox.
set(subHandles.costsListBox, 'String', {savedPriceModels.markedUpName});

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
handles.stepData.saveListener = saveListener(handles.figure1, subHandles.costsListBox, handles.trendData.saveNotifier);

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

% for each of the events in the growthModel, set the cost price model
% The events are handle events, so we don't need to save them - just
% modifying them will do.
gmes = wc.growthModel.growthModelEvents;
fes = wc.financialEvents;
for i = 1:length(gmes)
   ix = find(strcmp({handles.stepData.priceModels.name}, gmes(i).costPriceModel.name), 1, 'first');
   if ~isempty(ix)
       gmes(i).costPriceModel = handles.stepData.priceModels(ix);
   end
end

for i = 1:length(fes)
   ix = find(strcmp({handles.stepData.priceModels.name}, fes(i).costPriceModel.name), 1, 'first');
   if ~isempty(ix)
       fes(i).costPriceModel = handles.stepData.priceModels(ix);
   end
end

wc.financialEvents = fes;
wc.growthModel.growthModelEvents = gmes;

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


% --- Executes on selection change in costsListBox.
function costsListBox_Callback(hObject, eventdata, subHandles)
% hObject    handle to costsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns costsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from costsListBox

% On change of product name in the list box, save the previous trend and load the trend for the
% selected product.
saveTrend(subHandles);
setTrend(subHandles, get(hObject, 'Value'));



% --- Executes during object creation, after setting all properties.
function costsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to costsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% setTrend looks up the priceModels in stepData and sets the trend to the
% one given by pmIndex. Sets the current priceModelIndex to the pmIndex.
%
% It also needs to set the enable, the string and the value for the units
% drop down list.
function setTrend(subHandles, pmIndex)

% Set the product index
set(subHandles.costsListBox, 'Value', pmIndex);

handles = guidata(subHandles.trendPanel);
trend = handles.stepData.priceModels(pmIndex).trend;

if isempty(trend)
   trend = Trend(); 
end

handles.trendData.trend = trend;
handles.stepData.priceModelIndex = pmIndex;
pm = handles.stepData.priceModels(pmIndex);
guidata(subHandles.trendPanel, handles);

set(handles.subHandles.trendDataEdit, 'String', '');
set(handles.subHandles.varDataEdit, 'String', '');

assignin('base', 'pm', pm)

eventOutputUnits = getAdditionalPriceUnitsForEvent(handles, pmIndex);

extendedPossiblePriceUnits = [handles.stepData.possiblePriceUnits, eventOutputUnits];
if ~isempty(eventOutputUnits)
    extendedPossiblePriceUnitStrings = [handles.stepData.possiblePriceUnitStrings, eventOutputUnits.readableDenominatorUnit];
else
    extendedPossiblePriceUnitStrings = handles.stepData.possiblePriceUnitStrings;
end

ix = find(extendedPossiblePriceUnits == pm.denominatorUnit, 1);

if ~pm.denominatorUnitIsCurrent
    nonCurrentUnitString = [pm.denominatorUnit.readableDenominatorUnit, ' [No Longer Current]'];
    set(subHandles.costUnitsDDL, 'String', [extendedPossiblePriceUnitStrings, nonCurrentUnitString]);
%    set(subHandles.costUnitsDDL, 'String', [{extendedPossiblePriceUnits.readableDenominatorUnit}, nonCurrentUnitString]);
    set(subHandles.costUnitsDDL, 'Value', length(extendedPossiblePriceUnits) + 1);
    set(subHandles.costUnitsDDL, 'Enable', 'on');
else
    if pm.allowCostUnitChanges && ~isempty(ix)    
        set(subHandles.costUnitsDDL, 'String', extendedPossiblePriceUnitStrings);
  %      set(subHandles.costUnitsDDL, 'String', {extendedPossiblePriceUnits.readableDenominatorUnit});
        set(subHandles.costUnitsDDL, 'Value', ix);
        set(subHandles.costUnitsDDL, 'Enable', 'on');
    else
        set(subHandles.costUnitsDDL, 'Enable', 'off');
        set(subHandles.costUnitsDDL, 'String', {pm.denominatorUnit.readableDenominatorUnit});
        set(subHandles.costUnitsDDL, 'Value', 1);
    end
end    
trendDialogue('loadTrendData', subHandles);


% Save trend gets the data from handles.trendData and puts it into the
% current priceModel in stepData.
function saveTrend(subHandles)

handles = guidata(subHandles.trendPanel);
pmIndex = handles.stepData.priceModelIndex;
trend = handles.trendData.trend;

% Save the trend, update the marked up names, save the handles srtuct.
handles.stepData.priceModels(pmIndex).trend = trend;
set(subHandles.costsListBox, 'String', {handles.stepData.priceModels.markedUpName});
guidata(subHandles.trendPanel, handles);

function eventPriceUnits = getAdditionalPriceUnitsForEvent(handles, pmIndex)

% handles.stepData.possiblePriceUnits gives the units that come from
% regime, crop and outputs. We want to add to that the units particular to
% the event from eventOutputs.
pm = handles.stepData.priceModels(pmIndex);

gmd = handles.stepData.wizardCrop.growthModel.delegate;
growthModelEvents = [gmd.growthModelInitialEvents, gmd.growthModelRegularEvents, gmd.growthModelDestructionEvents];
% Find the pricemodel with matching name to get the event name.
assignin('base', 'gmes',growthModelEvents);
cps = [growthModelEvents.costPriceModel];
gmCPMNames = {cps.name};
ix = find(strcmp(gmCPMNames, pm.name), 1, 'first');
if(~isempty(ix))
    % Can use the matching ImagineEvent's name to get at the transition
    % function.
    
    eventPriceUnits = handles.stepData.wizardCrop.growthModel.delegate.getEventOutputUnits(growthModelEvents(ix).name);    
else
    % This could happen if it's a financial event, in which case we can't
    % (yet) put in any eventOutputs. Just use the main ones.
    eventPriceUnits = Unit.empty(1,0); 
end



% --- Executes on selection change in costUnitsDDL.
function costUnitsDDL_Callback(hObject, eventdata, subHandles)
% hObject    handle to costUnitsDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns costUnitsDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from costUnitsDDL
handles = guidata(hObject);
eventIndex = get(subHandles.costsListBox, 'Value');
eventOutputUnits = getAdditionalPriceUnitsForEvent(handles, eventIndex);
eventOutputUnitStrings = {};
if ~isempty(eventOutputUnits)
    eventOutputUnitStrings = {eventOutputUnits.readableDenominatorUnit};
end
extendedPossiblePriceUnits = [handles.stepData.possiblePriceUnits, eventOutputUnits];
selectedIndex = get(hObject, 'Value');
if selectedIndex > length(extendedPossiblePriceUnits)
    return
else
    handles.stepData.priceModels(handles.stepData.priceModelIndex).denominatorUnit = extendedPossiblePriceUnits(get(hObject, 'Value'));
    handles.stepData.priceModels(handles.stepData.priceModelIndex).denominatorUnitIsCurrent = true;
    set(subHandles.costsListBox, 'String', {handles.stepData.priceModels.markedUpName});
    set(hObject, 'String', [handles.stepData.possiblePriceUnitStrings, eventOutputUnitStrings]);
    guidata(hObject, handles);    
end

% --- Executes during object creation, after setting all properties.
function costUnitsDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to costUnitsDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function savedPriceModels = checkPriceModelsForCurrentUnits(handles, savedPriceModels)

% For each price model, get the denominator unit, and get the extended
% possible price units, then check that the saved denominator unit matches one
% of those possiblePriceUnits.

for pmIndex = 1:length(savedPriceModels)
    eventOutputUnits = getAdditionalPriceUnitsForEvent(handles, pmIndex);
    extendedPossiblePriceUnits = [handles.stepData.possiblePriceUnits, eventOutputUnits];
    
    ix = find(extendedPossiblePriceUnits == savedPriceModels(pmIndex).denominatorUnit, 1, 'first');
    if isempty(ix)
        savedPriceModels(pmIndex) = savedPriceModels(pmIndex).markDenominatorUnitValidity(false);
    else
        savedPriceModels(pmIndex) = savedPriceModels(pmIndex).markDenominatorUnitValidity(true);        
    end
end








