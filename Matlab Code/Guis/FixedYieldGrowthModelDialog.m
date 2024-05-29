function varargout = FixedYieldGrowthModelDialog(varargin)
% FIXEDYIELDGROWTHMODELDIALOG M-file for FixedYieldGrowthModelDialog.fig
%      FIXEDYIELDGROWTHMODELDIALOG, by itself, creates a new FIXEDYIELDGROWTHMODELDIALOG or raises the existing
%      singleton*.
%
%      H = FIXEDYIELDGROWTHMODELDIALOG returns the handle to a new FIXEDYIELDGROWTHMODELDIALOG or the handle to
%      the existing singleton*.
%
%      FIXEDYIELDGROWTHMODELDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FIXEDYIELDGROWTHMODELDIALOG.M with the given input arguments.
%
%      FIXEDYIELDGROWTHMODELDIALOG('Property','Value',...) creates a new FIXEDYIELDGROWTHMODELDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FixedYieldGrowthModelDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FixedYieldGrowthModelDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FixedYieldGrowthModelDialog

% Last Modified by GUIDE v2.5 19-Mar-2018 16:55:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FixedYieldGrowthModelDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @FixedYieldGrowthModelDialog_OutputFcn, ...
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


% --- Executes just before FixedYieldGrowthModelDialog is made visible.
function FixedYieldGrowthModelDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FixedYieldGrowthModelDialog (see VARARGIN)

% Choose default command line output for FixedYieldGrowthModelDialog
handles.output = [];

handles.propagationParameters.products = [];
handles.propagationParameters.outputs = [];

% Will pass in a cropInfo struct and the propagationParameters if they
% exist.
% nargin = 3
% if nargin < 4
%     nargin = 4;
%     cropInfo.cropName = 'Wheat';
%     cropInfo.cropType = 'Annual';
%     varargin{1} = cropInfo;
% end


if (nargin < 4)
    error(['Must pass in at least a cropInfo struct to the FixedYieldGrowthModelDialog and optionally ', ...
            'an existing propagationParameters struct.']);
else
    handles.cropInfo = varargin{1};
    % Assume that we've got a cropName and a cropType.
    set(handles.figure1, 'Name', ['Fixed Yield Growth Model Dialog, ', handles.cropInfo.cropName]);
    
    % get the list of available regime outputs based on the cropType.
    cats = CropCategory.setupCategories();
    catNames = {cats.name};    
    ix = find(strcmp(catNames, handles.cropInfo.cropType), 1, 'first');
    if isempty(ix)
        error('Cannot identify the cropType passed to FixedYieldGrowthModelDialog.');
    else
        handles.regimeOutputUnits = cats(ix).regimeOutputUnits;
    end
end
if nargin > 4
    pp = varargin{2};
    % For top-level parameters
    fieldsToOverwrite = {'products', 'outputs'};
    for i = 1:length(fieldsToOverwrite)
        if isfield(pp, fieldsToOverwrite{i})
            handles.propagationParameters.(fieldsToOverwrite{i}) = pp.(fieldsToOverwrite{i});
        end        
    end
    
    % Though we're not checking, both outputs and products should have a
    % number of fields, each with series, unit, and denominatorUnit as
    % fields.
    
end

if nargin > 5
    handles.modifierAware = varargin{3};
else
    handles.modifierAware = false;
end

handles.modifierControls = [handles.textModifierLabel, handles.uipanelModifierPanel, handles.checkboxSpatiallyModified, handles.checkboxTemporallyModified];

% Initialise the variable nameRemap
% It's used for remembering how names have been changed in this setup.
handles.nameRemap = {};

% Update handles structure
guidata(hObject, handles);

populateControls(handles);


% Setup the selection record
handles = guidata(hObject);
handles.selectedIndices = [];
guidata(hObject, handles);

% UIWAIT makes FixedYieldGrowthModelDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FixedYieldGrowthModelDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles.nameRemap;
close(handles.figure1);

function populateControls(handles)
updateProductList(handles);
updateOutputList(handles);

plist = get(handles.listboxProducts, 'String');
olist = get(handles.listboxOutputs, 'String');

if ~isempty(plist)
    set(handles.listboxProducts, 'Value', 1);
    set(handles.listboxOutputs, 'Value', []);
elseif ~isempty(olist)
    set(handles.listboxProducts, 'Value', []);
    set(handles.listboxOutputs, 'Value', 1);
else
    set(handles.listboxProducts, 'Value', []);
    set(handles.listboxOutputs, 'Value', []);
end

if (handles.modifierAware)
    set(handles.modifierControls, 'Visible', 'on');
else
    set(handles.modifierControls, 'Visible', 'off');    
end

refreshEnables(handles);
refreshTable(handles);



% Loads the selected series into the table.
function refreshTable(handles)

prodNames = stripHTML(get(handles.listboxProducts, 'String'));
outNames = stripHTML(get(handles.listboxOutputs, 'String'));
prodSelIxs = get(handles.listboxProducts, 'Value');
outSelIxs = get(handles.listboxOutputs, 'Value');

if isempty(prodNames) && isempty(outNames)
    % Clear the table.
    cnames = {};
    thedata = [];
    set(handles.uitableData, 'Data', thedata, 'ColumnName', cnames);    
    clearTable(handles);
            
    return
elseif isempty(prodNames)
    cnames = outNames(outSelIxs);
elseif isempty(outNames)
    cnames = prodNames(prodSelIxs);
else
    cnames = [prodNames(prodSelIxs), outNames(outSelIxs)];    
end


thedata = [];
isOutput = false;
if ~isempty(prodNames)
    for i = 1:length(prodSelIxs)
       productName = prodNames{prodSelIxs(i)};
       if ~isempty(handles.propagationParameters.products)
           series = handles.propagationParameters.products.(productName).series;
           thedata(1:length(series), i) = series;
            if length(cnames) == 1
                % Then we load the units.
                unit = handles.propagationParameters.products.(productName).unit;
                denUnit =  handles.propagationParameters.products.(productName).denominatorUnit;
                spatiallyModified = handles.propagationParameters.products.(productName).spatiallyModified;
                temporallyModified = handles.propagationParameters.products.(productName).temporallyModified;
            end
       end
    end
end

if ~isempty(outNames)
    for i = 1:length(outSelIxs)
       outputName = outNames{outSelIxs(i)};
       if ~isempty(handles.propagationParameters.outputs)
           series = handles.propagationParameters.outputs.(outputName).series;
           thedata(1:length(series), i + length(prodSelIxs)) = series;

            if length(cnames) == 1
               % Then we load the units.
               unit = handles.propagationParameters.outputs.(outputName).unit;
               denUnit =  handles.propagationParameters.outputs.(outputName).denominatorUnit;
               spatiallyModified = handles.propagationParameters.outputs.(outputName).spatiallyModified;
               temporallyModified = handles.propagationParameters.outputs.(outputName).temporallyModified;
               isOutput = true;
            end
       end
    end
end

set(handles.uitableData, 'Data', thedata, 'ColumnName', cnames, 'ColumnEditable', true(1, length(cnames)));


% Now set up the unit panel.
if length(cnames) == 1
    setupUnitPanelWithUnits(handles, unit, denUnit, isOutput);
    if (handles.modifierAware)
        setupModifierPanel(handles, spatiallyModified, temporallyModified);
    end
else
    setupUnitPanelWithMultiple(handles);
    if (handles.modifierAware)
        setupModifierPanelWithMultiple(handles);
    end
end

function setupModifierPanel(handles, spatiallyModified, temporallyModified)

set(handles.uipanelModifierPanel, 'Title', '');
set(handles.checkboxSpatiallyModified, 'Value', spatiallyModified);
set(handles.checkboxTemporallyModified, 'Value', temporallyModified);
set(handles.checkboxSpatiallyModified, 'Enable', 'on');
set(handles.checkboxTemporallyModified, 'Enable', 'on');

function setupModifierPanelWithMultiple(handles)

set(handles.uipanelModifierPanel, 'Title', 'Multiple Selection');
set(handles.checkboxSpatiallyModified, 'Value', false);
set(handles.checkboxTemporallyModified, 'Value', false);
set(handles.checkboxSpatiallyModified, 'Enable', 'off');
set(handles.checkboxTemporallyModified, 'Enable', 'off');


% Load the data from the numerator and denominator units into the unit
% panel and clear the unit panel title.
function setupUnitPanelWithUnits(handles, numerator, denominator, isOutput)


denominatorUnitReadables = {handles.regimeOutputUnits.readableDenominatorUnit};
if isOutput
    denominatorUnitReadables = ['No Denominator Unit Required', denominatorUnitReadables];
end
set(handles.popupmenuDenominatorUnit, 'String', ['Select Unit...', denominatorUnitReadables]);
ix = find(strcmp(denominator.readableDenominatorUnit, denominatorUnitReadables), 1, 'first');
if isempty(ix)
%    error('Cannot find the right denominator unit.');
    if (denominator == Unit)
        set(handles.popupmenuDenominatorUnit, 'Value', 2);
        set(handles.textDenominatorSpeciesName, 'String', '[None]');
        set(handles.textDenominatorUnitName, 'String', '[None]');        
    else
        set(handles.popupmenuDenominatorUnit, 'Value', 1);
        set(handles.textDenominatorSpeciesName, 'String', '[None]');
        set(handles.textDenominatorUnitName, 'String', '[None]');
    end
else
    set(handles.popupmenuDenominatorUnit, 'Value', ix + 1);
    set(handles.textDenominatorSpeciesName, 'String', denominator.speciesName);
    set(handles.textDenominatorUnitName, 'String', denominator.unitName);
end
set(handles.popupmenuDenominatorUnit, 'Enable', 'on');

set(handles.uipanelUnitDefinition, 'Title', '');
set(handles.editNumeratorSpeciesName, 'String', numerator.speciesName);
set(handles.editNumeratorUnitName, 'String', numerator.unitName);
set(handles.editNumeratorSpeciesName, 'Enable', 'on');
set(handles.editNumeratorUnitName, 'Enable', 'on');

% Disable the unit panel, clear the controls and set the title to be
% Multiple Selection.
function setupUnitPanelWithMultiple(handles)

set(handles.uipanelUnitDefinition, 'Title', 'Multiple Selection');
set(handles.popupmenuDenominatorUnit, 'String', {''});
set(handles.popupmenuDenominatorUnit, 'Value', 1);
set(handles.popupmenuDenominatorUnit, 'Enable', 'off');
set(handles.textDenominatorSpeciesName, 'String', '');
set(handles.textDenominatorUnitName, 'String', '');
set(handles.editNumeratorSpeciesName, 'String', '');
set(handles.editNumeratorUnitName, 'String', '');
set(handles.editNumeratorSpeciesName, 'Enable', 'off');
set(handles.editNumeratorUnitName, 'Enable', 'off');

function clearTable(handles)

set(handles.uipanelUnitDefinition, 'Title', 'No Product or Output Selected');
set(handles.popupmenuDenominatorUnit, 'String', {''});
set(handles.popupmenuDenominatorUnit, 'Value', 1);
set(handles.popupmenuDenominatorUnit, 'Enable', 'off');
set(handles.textDenominatorSpeciesName, 'String', '');
set(handles.textDenominatorUnitName, 'String', '');
set(handles.editNumeratorSpeciesName, 'String', '');
set(handles.editNumeratorUnitName, 'String', '');
set(handles.editNumeratorSpeciesName, 'Enable', 'off');
set(handles.editNumeratorUnitName, 'Enable', 'off');

set(handles.uipanelModifierPanel, 'Title', 'No Product or Output Selected');
set(handles.checkboxSpatiallyModified, 'Value', false);
set(handles.checkboxTemporallyModified, 'Value', false);
set(handles.checkboxSpatiallyModified, 'Enable', 'off');
set(handles.checkboxTemporallyModified, 'Enable', 'off');


% --- Executes on button press in pushbuttonImportClipboard.
function pushbuttonImportClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImportClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get data from the clipboard.
S = uiimport('-pastespecial');
assignin('base', 'S', S);
if ~isempty(S)
   
   series = extractSeriesFromImport(S);
   addSeries(handles, series);
   
end

% --- Executes on button press in pushbuttonImportFile.
function pushbuttonImportFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImportFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% get data from the clipboard.
S = uiimport('-file');
assignin('base', 'S', S);
if ~isempty(S)
   % get the series out out...
   series = extractSeriesFromImport(S);
   
   addSeries(handles, series);
   
end

function addSeries(handles, series)
% Check if we're possibly overwriting existing series,
% If so ask the user if they want to overwrite them
% Then create new product series for the new ones or replace data of the
% overwritten products or outputs.
% Select the indices of all the new data and have it displayed.
fns = fieldnames(series);
prodNames = stripHTML(get(handles.listboxProducts, 'String'));
outNames = stripHTML(get(handles.listboxOutputs, 'String'));
allNames = [prodNames, outNames];

for i = 1:length(fns)
  ix =find(strcmpi(fns{i}, allNames), 1, 'first');
  if ~isempty(ix)
      % Then we check if the user wants to overwrite the existing item.
      if ix > length(prodNames)
          quest = {'An output called ', allNames{ix}, ' already exists.', ...
              'Would you like to overwrite the existing data with the new data?'};
      else
          quest = {'A product called ', allNames{ix}, ' already exists.', ...
              'Would you like to overwrite the existing data with the new data?'}; 
      end

      button = questdlg(quest, ['Overwrite existing data?'], 'Yes', 'Skip', 'Skip');

        if isempty(button)
            return
        end
        if strcmp(button, 'Skip')
            continue
        end  

        % Then we overwrite the series data.
        if ix > length(prodNames)
            handles.propagationParameters.outputs.(allNames{ix}).series = series.(fns{i});
        else
            handles.propagationParameters.products.(allNames{ix}).series = series.(fns{i});
        end
  else
       % Then we just add the series as a new product.
       denUnit = Unit('', '', '');
       numUnit = denUnit;
       s = struct('series', series.(fns{i}), 'unit', numUnit, 'denominatorUnit', denUnit, 'spatiallyModified', handles.modifierAware, 'temporallyModified', handles.modifierAware);
       handles.propagationParameters.products.(fns{i}) = s; 
  end      

end
if ~isempty(handles.propagationParameters.products)
    fns = fieldnames(handles.propagationParameters.products);
%    ix = find(strcmp(fns, newName), 1, 'first');
    vals = checkValidUnits(handles.propagationParameters.products, handles);
    set(handles.listboxProducts, 'String', markupStringsAsValid(fns, vals));
    set(handles.listboxProducts, 'Value', 1);
end
if ~isempty(handles.propagationParameters.outputs)
    fns = fieldnames(handles.propagationParameters.outputs);
%    ix = find(strcmp(fns, newName), 1, 'first');
    vals = checkValidUnits(handles.propagationParameters.outputs, handles);
    set(handles.listboxOutputs, 'String', markupStringsAsValid(fns, vals));
    set(handles.listboxOutputs, 'Value', 1);
end
guidata(handles.figure1, handles);
refreshTable(handles);



% --- Executes on selection change in listboxProducts.
function listboxProducts_Callback(hObject, eventdata, handles)
% hObject    handle to listboxProducts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxProducts contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxProducts
set(handles.listboxOutputs, 'Value', []);
refreshTable(handles);
refreshEnables(handles);

% --- Executes during object creation, after setting all properties.
function listboxProducts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxProducts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listboxOutputs.
function listboxOutputs_Callback(hObject, eventdata, handles)
% hObject    handle to listboxOutputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxOutputs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxOutputs
set(handles.listboxProducts, 'Value', []);
refreshTable(handles);
refreshEnables(handles);

% --- Executes during object creation, after setting all properties.
function listboxOutputs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxOutputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Works out whether we should be allowed to use the rename, remove, change
% to output/product buttons.
function refreshEnables(handles)
prodNames = stripHTML(get(handles.listboxProducts, 'String'));
outNames = stripHTML(get(handles.listboxOutputs, 'String'));
prodSelIxs = get(handles.listboxProducts, 'Value');
outSelIxs = get(handles.listboxOutputs, 'Value');

singleSelect = false;
if length([prodSelIxs, outSelIxs]) == 1
    singleSelect = true;
end

set(handles.pushbuttonRenameProduct, 'Enable', 'off');
set(handles.pushbuttonRemoveProduct, 'Enable', 'off');
set(handles.pushbuttonChangeToOutput, 'Enable', 'off');

set(handles.pushbuttonRenameOutput, 'Enable', 'off');
set(handles.pushbuttonRemoveOutput, 'Enable', 'off');
set(handles.pushbuttonChangeToProduct, 'Enable', 'off');

if singleSelect
    if ~isempty(prodSelIxs)
        set(handles.pushbuttonRenameProduct, 'Enable', 'on');
        set(handles.pushbuttonRemoveProduct, 'Enable', 'on');
    else
        set(handles.pushbuttonRenameOutput, 'Enable', 'on');
        set(handles.pushbuttonRemoveOutput, 'Enable', 'on');
    end
end

%if length([prodSelIxs, outSelIxs]) > 1
    if ~isempty(prodSelIxs)
        set(handles.pushbuttonChangeToOutput, 'Enable', 'on');
    end
    if ~isempty(outSelIxs)
        set(handles.pushbuttonChangeToProduct, 'Enable', 'on');
    end
%end   


% --- Executes on button press in pushbuttonRenameOutput.
function pushbuttonRenameOutput_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRenameOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Assume that the enable is fine - so there's a single selection in the
% product list.
outputNames = stripHTML(get(handles.listboxOutputs, 'String'));
ixs = get(handles.listboxOutputs, 'Value');

if length(ixs) > 1 
    return
end

% Get the new name.
name = inputdlg('Please enter the new name for the output.', 'Change Output Name', 1, outputNames(ixs));
if isempty(name)
    return
end
if isempty(name{1})
    return
end

newName = underscore(name{1});
% does it already exist?
ix = find(strcmp(newName, outputNames));
if length(ix) > 1
    msgbox('Cannot use this name. Please try again and use something different.', 'Name already used');
    return
end

handles.propagationParameters.outputs.(newName) = handles.propagationParameters.outputs.(outputNames{ixs});
handles.propagationParameters.outputs = rmfield(handles.propagationParameters.outputs, outputNames{ixs});
guidata(hObject, handles);

fns = fieldnames(handles.propagationParameters.outputs);
vals = checkValidUnits(handles.propagationParameters.outputs, handles);
set(handles.listboxOutputs, 'String', markupStringsAsValid(fns, vals));

refreshTable(handles);



% --- Executes on button press in pushbuttonAddOutput.
function pushbuttonAddOutput_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAddOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name = inputdlg('Please enter the name for the new output.', 'New Output', 1, {'Enter new output name'});
if isempty(name)
    return
end
if isempty(name{1})
    return
end
newName = underscore(name{1});

% Add a new product with an empty series and unit units.
denUnit = Unit('', '', '');
numUnit = denUnit;
imobj = ImagineObject.getInstance();
series = zeros(1, imobj.simulationLength * 12);
s = struct('series', series, 'unit', numUnit, 'denominatorUnit', denUnit, 'spatiallyModified', handles.modifierAware, 'temporallyModified', handles.modifierAware);
handles.propagationParameters.outputs.(newName) = s;
guidata(hObject, handles);

fns = fieldnames(handles.propagationParameters.outputs);
ix = find(strcmp(fns, newName), 1, 'first');
    vals = checkValidUnits(handles.propagationParameters.outputs, handles);
    set(handles.listboxOutputs, 'String', markupStringsAsValid(fns, vals));

%set(handles.listboxProducts, 'String', fns);
set(handles.listboxProducts, 'Value', []);
set(handles.listboxOutputs, 'Value', ix);

refreshTable(handles);


% --- Executes on button press in pushbuttonRemoveOutput.
function pushbuttonRemoveOutput_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRemoveOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
outNames = stripHTML(get(handles.listboxOutputs, 'String'));
ixs = get(handles.listboxOutputs, 'Value');
outName = outNames{ixs};
button = questdlg('Are you sure you want to remove this output?', ['Remove ', outName , ' Output'], 'Yes', 'Cancel', 'Cancel');

if isempty(button)
    return
end
if strcmp(button, 'Cancel')
    return
end

handles.propagationParameters.outputs = rmfield(handles.propagationParameters.outputs, outName);
if length(outNames) > 1
   set(handles.listboxOutputs, 'Value', 1); 
else
   set(handles.listboxOutputs, 'Value', []);     
end
guidata(hObject, handles);
updateOutputList(handles);
refreshTable(handles);


function series = extractSeriesFromImport(S)

if isempty(S)
    series = [];
    return 
end

assignin('base', 'S', S);
fns = fieldnames(S);

if length(fns) == 3
   %Then we have may have a colHeaders variable
   % Extract the columns. 
   if strcmp(fns{3}, 'colheaders')
      
      for i = 1:length(S.colheaders)         
         newS.(underscore(S.colheaders{i})) = S.data(:, i); 
      end
  
       S = newS;
   end
elseif strcmp(fns{1}, 'textdata') || strcmp(fns{2}, 'textdata')
    series = [];
    msgbox({'Import data needs to be in the form of contiguous columns with cloumn headers.', '', 'Cannot use the data provided.'}, 'Data Not In Required Format');
    return;
end

if length(fns) > 1
   series = seriesFromVectorsImportDialog(S);    
else
   % Set up series so it's defined if it falls through the test below.
   series = S.(fns{1});
   sz = size(S.(fns{1}));
   if  sz(1) > 1
       if sz(2) > 1
           series = seriesFromVectorsImportDialog(S);
       end
   end
end


% --- Executes on button press in pushbuttonAccept.
function pushbuttonAccept_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAccept (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check that all the products and units are valid.
pvals = checkValidUnits(handles.propagationParameters.products, handles);
ovals = checkValidUnits(handles.propagationParameters.outputs, handles);
valid = true;
if isempty([pvals; ovals])
    valid = false;
end
if valid && ~all([pvals; ovals])
    valid = false;
end

if ~valid
    msgbox({'Not every product or output has a valid set of units defined.', ...
            'You need to define these before the growth modelcan be accepted.'}, 'Growth Model not valid');
    return
end

handles.output = handles.propagationParameters;
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


% --- Executes on button press in pushbuttonRenameProduct.
function pushbuttonRenameProduct_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRenameProduct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% There's another factor here, which is that we'd like to keep track of the
% products we rename so we can apply the new names to the financial events
% that may already exist. If we supply a list of renamed products to the
% growthModelDelegate, it can arrange to rename it's financial events
% accordingly first before it does anything else.
% The renaming map will be of the style {'product 1 start name', 'product 1 new name'; 'product 2 start name', 'product 2 new name'; ...}
% We'll achieve this using the function replaceName(handles, oldName, newName)

% Assume that the enable is fine - so there's a single selection in the
% product list.
prodNames = stripHTML(get(handles.listboxProducts, 'String'));
ixs = get(handles.listboxProducts, 'Value');

if length(ixs) > 1 
    return
end

% Get the new name.
name = inputdlg('Please enter the new name for the product.', 'Change Product Name', 1, prodNames(ixs));
if isempty(name)
    return
end
if isempty(name{1})
    return
end

newName = underscore(name{1});
% does it already exist?
ix = find(strcmp(newName, prodNames));
if length(ix) > 1
    msgbox('Cannot use this name. Please try again and use something different.', 'Name already used');
    return
end
oldName = prodNames{ixs};
handles.propagationParameters.products.(newName) = handles.propagationParameters.products.(oldName);
handles.propagationParameters.products = rmfield(handles.propagationParameters.products, oldName);
guidata(hObject, handles);

fns = fieldnames(handles.propagationParameters.products);
vals = checkValidUnits(handles.propagationParameters.products, handles);
set(handles.listboxProducts, 'String', markupStringsAsValid(fns, vals));

refreshTable(handles);

replaceName(handles, oldName, newName)

% --- Executes on button press in pushbuttonAddProduct.
function pushbuttonAddProduct_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAddProduct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

name = inputdlg('Please enter the name for the new product.', 'New Product', 1, {'Enter new product name'});
if isempty(name)
    return
end
if isempty(name{1})
    return
end
newName = underscore(name{1});

% Add a new product with an empty series and unit units.
denUnit = Unit('', '', '');
numUnit = denUnit;
imobj = ImagineObject.getInstance();
series = zeros(1, imobj.simulationLength * 12);
s = struct('series', series, 'unit', numUnit, 'denominatorUnit', denUnit, 'spatiallyModified', handles.modifierAware, 'temporallyModified', handles.modifierAware);
handles.propagationParameters.products.(newName) = s;
guidata(hObject, handles);

fns = fieldnames(handles.propagationParameters.products);
ix = find(strcmp(fns, newName), 1, 'first');
    vals = checkValidUnits(handles.propagationParameters.products, handles);
    set(handles.listboxProducts, 'String', markupStringsAsValid(fns, vals));

%set(handles.listboxProducts, 'String', fns);
set(handles.listboxProducts, 'Value', ix);
set(handles.listboxOutputs, 'Value', []);

refreshTable(handles);

% --- Executes on button press in pushbuttonRemoveProduct.
function pushbuttonRemoveProduct_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRemoveProduct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prodNames = stripHTML(get(handles.listboxProducts, 'String'));
ixs = get(handles.listboxProducts, 'Value');
prodName = prodNames{ixs};
button = questdlg('Are you sure you want to remove this product?', ['Remove ', prodName , ' Product'], 'Yes', 'Cancel', 'Cancel');

if isempty(button)
    return
end
if strcmp(button, 'Cancel')
    return
end

handles.propagationParameters.products = rmfield(handles.propagationParameters.products, prodName);
if length(prodNames) > 1
   set(handles.listboxProducts, 'Value', 1); 
else
   set(handles.listboxProducts, 'Value', []);     
end
guidata(hObject, handles);
updateProductList(handles);
refreshTable(handles);

function editNumeratorUnitName_Callback(hObject, eventdata, handles)
% hObject    handle to editNumeratorUnitName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumeratorUnitName as text
%        str2double(get(hObject,'String')) returns contents of editNumeratorUnitName as a double

% Get the text
unitName = get(hObject, 'String');

% Work out which product or output we should set the unit for.
pix = get(handles.listboxProducts, 'Value');
oix = get(handles.listboxOutputs, 'Value');
if isempty(pix)
    % must be an output
    % Get the name
    onames = stripHTML(get(handles.listboxOutputs, 'String'));
    oname = onames{oix};
    handles.propagationParameters.outputs.(oname).unit.unitName = unitName;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of outputs
    updateOutputList(handles);
else
    % must be a product
    % Get the name
    pnames = stripHTML(get(handles.listboxProducts, 'String'));
    pname = pnames{pix};
    handles.propagationParameters.products.(pname).unit.unitName = unitName;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of products
    updateProductList(handles);
end
refreshTable(handles)


% --- Executes during object creation, after setting all properties.
function editNumeratorUnitName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumeratorUnitName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDenominatorUnit.
function popupmenuDenominatorUnit_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDenominatorUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDenominatorUnit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDenominatorUnit
if get(hObject,'Value') == 1
   % Then we've selected 'Select Unit'...
   % Save a nothing unit.
   denUnit = Unit('', '', '');
else
   % Then we can match with one of the actual units.
   % We should save it.
    contents = cellstr(get(hObject,'String'));
    readableDenominatorUnit = contents{get(hObject,'Value')};
    denominatorUnitReadables = {handles.regimeOutputUnits.readableDenominatorUnit};
    ix = find(strcmp(readableDenominatorUnit, denominatorUnitReadables), 1, 'first');
    if isempty(ix)
        if strcmp('No Denominator Unit Required', readableDenominatorUnit)
            denUnit  = Unit;
        else
            error('Cannot find the denominator unit that gave rise to the selection.');
        end
    else
        denUnit = handles.regimeOutputUnits(ix);
    end
end

% Work out which product or output we should set the unit for.
pix = get(handles.listboxProducts, 'Value');
oix = get(handles.listboxOutputs, 'Value');
if isempty(pix)
    % must be an output
    % Get the name
    onames = stripHTML(get(handles.listboxOutputs, 'String'));
    oname = onames{oix};
    handles.propagationParameters.outputs.(oname).denominatorUnit = denUnit;
    % Save the unit
    guidata(hObject, handles);
    % Update the list of outputs
    updateOutputList(handles);
else
    % must be a product
    % Get the name
    pnames = stripHTML(get(handles.listboxProducts, 'String'));
    pname = pnames{pix};
    handles.propagationParameters.products.(pname).denominatorUnit = denUnit;
    % Save the unit
    guidata(hObject, handles);
    % Update the list of products
    updateProductList(handles);
end
refreshTable(handles)

function updateOutputList(handles)
    if ~isempty(handles.propagationParameters.outputs)
        vals = checkValidUnits(handles.propagationParameters.outputs, handles);
        fns = fieldnames(handles.propagationParameters.outputs);
        set(handles.listboxOutputs, 'String', markupStringsAsValid(fns, vals));
    end
    
function updateProductList(handles)
    if ~isempty(handles.propagationParameters.products)
        vals = checkValidUnits(handles.propagationParameters.products, handles);
        fns = fieldnames(handles.propagationParameters.products);
        set(handles.listboxProducts, 'String', markupStringsAsValid(fns, vals));
    end
    
% --- Executes during object creation, after setting all properties.
function popupmenuDenominatorUnit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDenominatorUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumeratorSpeciesName_Callback(hObject, eventdata, handles)
% hObject    handle to editNumeratorSpeciesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumeratorSpeciesName as text
%        str2double(get(hObject,'String')) returns contents of editNumeratorSpeciesName as a double
% Get the text
speciesName = get(hObject, 'String');

% Work out which product or output we should set the unit for.
pix = get(handles.listboxProducts, 'Value');
oix = get(handles.listboxOutputs, 'Value');
if isempty(pix)
    % must be an output
    % Get the name
    onames = stripHTML(get(handles.listboxOutputs, 'String'));
    oname = onames{oix};
    handles.propagationParameters.outputs.(oname).unit.speciesName = speciesName;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of outputs
    updateOutputList(handles);
else
    % must be a product
    % Get the name
    pnames = stripHTML(get(handles.listboxProducts, 'String'));
    pname = pnames{pix};
    handles.propagationParameters.products.(pname).unit.speciesName = speciesName;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of products
    updateProductList(handles);
end
refreshTable(handles)


% --- Executes during object creation, after setting all properties.
function editNumeratorSpeciesName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumeratorSpeciesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% for aech string in the cell array strs, the corresponding entry in vals
% determines whether the text should be marked up to be coloured green or red.
function markup = markupStringsAsValid(strs, vals)
markup = {};
for i = 1:length(strs)
    if vals(i)
        markup{i} = ['<HTML><FONT color="green">', strs{i}, '</FONT></HTML>'];
    else
        markup{i} = ['<HTML><FONT color="red">', strs{i}, '</FONT></HTML>'];        
    end
end

% Items will be a struct with each field having units and denominatorsUnits
% The speciesName and the unitName of the units should be non-empty.
% The denominatorUnit must match one of the regimeOutputUnits in handles.
function vals = checkValidUnits(items, handles)
vals = [];
if isempty(items)
    return;
end
fns = fieldnames(items);
if isempty(fns)
    return
end
vals = false(length(fns), 1);
for i = 1:length(fns)
    it = items.(fns{i});
    val = ~isempty(it.unit.unitName) && ~isempty(it.unit.speciesName);
    if val
        denominatorReadableUnit = it.denominatorUnit.readableDenominatorUnit;
        ix = find(strcmp({handles.regimeOutputUnits.readableDenominatorUnit}, denominatorReadableUnit), 1, 'first');
        if ~isempty(ix)
            val = true;
        else
            % If the unit is actually the default Unit, rather than an
            % empty non-unit of Unit('', '', '') then this must be an
            % output with no denominator unit required.
            % This is the only case where we can have set the denominator
            % unit to be Unit.
            if it.denominatorUnit == Unit
                val = true;
            end
        end
    end
    vals(i) = val;
end

% --- Executes on button press in pushbuttonChangeToOutput.
function pushbuttonChangeToOutput_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChangeToOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% For each product, add as output, remove as product, then refresh both
% listboxes.
pixs = get(handles.listboxProducts, 'Value');
pnames = stripHTML(get(handles.listboxProducts, 'String'));

for i = 1:length(pixs)
    pname = pnames{pixs(i)};
    handles.propagationParameters.outputs.(pname) = handles.propagationParameters.products.(pname);
    handles.propagationParameters.products = rmfield(handles.propagationParameters.products, pname);
end
guidata(hObject, handles);
updateProductList(handles);
updateOutputList(handles);
onames = stripHTML(get(handles.listboxOutputs, 'String'));
% Select the same ones, but now in outputs.
for i = 1:length(pixs)
    pname = pnames{pixs(i)};
    ix = find(strcmp(pname, onames), 1, 'first');
    oixs(i) = ix;
end
set(handles.listboxOutputs, 'Value', oixs);
set(handles.listboxProducts, 'Value', []);
refreshEnables(handles);


% --- Executes on button press in pushbuttonChangeToProduct.
function pushbuttonChangeToProduct_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChangeToProduct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% For each output, add as product, remove as output, then refresh both
% listboxes.
oixs = get(handles.listboxOutputs, 'Value');
onames = stripHTML(get(handles.listboxOutputs, 'String'));

for i = 1:length(oixs)
    oname = onames{oixs(i)};
    handles.propagationParameters.products.(oname) = handles.propagationParameters.outputs.(oname);
    handles.propagationParameters.outputs = rmfield(handles.propagationParameters.outputs, oname);
end
guidata(hObject, handles);
updateProductList(handles);
updateOutputList(handles);
pnames = stripHTML(get(handles.listboxProducts, 'String'));
% Select the same ones, but now in products.
for i = 1:length(oixs)
    oname = onames{oixs(i)};
    ix = find(strcmp(oname, pnames), 1, 'first');
    pixs(i) = ix;
end
set(handles.listboxProducts, 'Value', pixs);
set(handles.listboxOutputs, 'Value', []);
refreshEnables(handles);

% --- Executes during object creation, after setting all properties.
function pushbuttonChangeToOutput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonChangeToOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbuttonPasteClipboard.
function pushbuttonPasteClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPasteClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Grab the data from the clipboard.
data = getTableFromClipboard;

if(isempty(data))
    return    
end

% If there is data there, work out how to add it to the table data.
% Paste it into the columns from the selected cell across the visible cells
% as if we were pasting into Excel.
tableData = get(handles.uitableData, 'Data');
[length, width] = size(tableData);

selectedIndices = handles.selectedIndices;

newSelectedIndices = [];

% If there's more data on the clipboard than we can fit, we truncate it.
for i = 1:size(selectedIndices, 1)
    % If the coordinates are outside the table, lose them.
    if(selectedIndices(i, 1) <= length && selectedIndices(i, 2) <= width)
        newSelectedIndices(end+1, :) = selectedIndices(i, :);
    end
end
selectedIndices = newSelectedIndices;

if(isempty(selectedIndices))
    Msgbox('Please select top left cell to paste from.', 'No cell selected.');
    return
end
if(size(selectedIndices, 1) > 1)
    Msgbox('Please select only one cell to paste from.', 'Multiple Paste Cells')
    return
end

insertRow = selectedIndices(1, 1);
insertCol = selectedIndices(1, 2);
rowEnd = insertRow + size(data, 1) - 1;
colEnd = insertRow + size(data, 2) - 1;
if(rowEnd > length)
    rowEnd = length;
end
if(colEnd > width)
    colEnd = width;
end

rows = insertRow:rowEnd;
cols = insertCol:colEnd;
data(1:size(rows, 2), 1:size(cols, 2))
%tableData(rows, cols) = data(1:length(rows), 1:length(cols));
% Bizarrely length(rows) says index exceeded...
tableData(rows, cols) = data(1:size(rows, 2), 1:size(cols, 2));

set(handles.uitableData, 'Data', tableData);
saveTable(handles);
 
 % Loads the selected series into the table.
function saveTable(handles)

% Step through the list of products or outputs.
% Save each column in the table to the next selected product or output.

tableData = get(handles.uitableData, 'Data');

prodNames = stripHTML(get(handles.listboxProducts, 'String'));
outNames = stripHTML(get(handles.listboxOutputs, 'String'));
prodSelIxs = get(handles.listboxProducts, 'Value');
outSelIxs = get(handles.listboxOutputs, 'Value');

if isempty(prodNames) && isempty(outNames)
    % Clear the table.
    cnames = {};
    thedata = [];
    set(handles.uitableData, 'Data', thedata, 'ColumnName', cnames);    
    clearTable(handles);
            
    return
elseif isempty(prodNames)
    cnames = outNames(outSelIxs);
elseif isempty(outNames)
    cnames = prodNames(prodSelIxs);
else
    cnames = [prodNames(prodSelIxs), outNames(outSelIxs)];    
end

if (length(cnames) ~= size(tableData, 2))    
    error('Trying to save data, but we dont have matching columns and series.');
end

for i = 1:size(tableData, 2)
    if(i <= length(prodSelIxs))
        % Then its a product series.
        structName = 'products';
    else
        % Its an output series.
        structName = 'outputs';
    end
    seriesName = cnames{i};
    series = tableData(:, i);
    handles.propagationParameters.(structName).(seriesName).series = series;    
end
guidata(handles.figure1, handles); 
 
% --- Executes when selected cell(s) is changed in uitableData.
function uitableData_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableData (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

handles.selectedIndices = eventdata.Indices;
guidata(hObject, handles);


% --- Executes on button press in checkboxSpatiallyModified.
function checkboxSpatiallyModified_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSpatiallyModified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSpatiallyModified
% Get the text
modified = get(hObject, 'Value');

% Work out which product or output we should set the unit for.
pix = get(handles.listboxProducts, 'Value');
oix = get(handles.listboxOutputs, 'Value');
if isempty(pix)
    % must be an output
    % Get the name
    onames = stripHTML(get(handles.listboxOutputs, 'String'));
    oname = onames{oix};
    handles.propagationParameters.outputs.(oname).spatiallyModified = modified;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of outputs
else
    % must be a product
    % Get the name
    pnames = stripHTML(get(handles.listboxProducts, 'String'));
    pname = pnames{pix};
    handles.propagationParameters.products.(pname).spatiallyModified = modified;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of products
end

% --- Executes on button press in checkboxTemporallyModified.
function checkboxTemporallyModified_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTemporallyModified (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSpatiallyModified
% Get the text
modified = get(hObject, 'Value');

% Work out which product or output we should set the unit for.
pix = get(handles.listboxProducts, 'Value');
oix = get(handles.listboxOutputs, 'Value');
if isempty(pix)
    % must be an output
    % Get the name
    onames = stripHTML(get(handles.listboxOutputs, 'String'));
    oname = onames{oix};
    handles.propagationParameters.outputs.(oname).temporallyModified = modified;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of outputs
else
    % must be a product
    % Get the name
    pnames = stripHTML(get(handles.listboxProducts, 'String'));
    pname = pnames{pix};
    handles.propagationParameters.products.(pname).temporallyModified = modified;
    % Save the unit
    guidata(hObject, handles);
    % Update the ilst of products
end


% --- Executes when entered data in editable cell(s) in uitableData.
function uitableData_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableData (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
 saveTable(handles)
 

% nameRemap will be a strng cell array of two columns. The left column
% contains original names. The right column contains the new names.
function replaceName(handles, oldName, newName)

nameRemap = handles.nameRemap;
if isempty(nameRemap)
    nameRemap = {oldName, newName};
else
    % If the oldName has actually already been changed, it will be in the
    % second column.
    ixr = find(strcmp(nameRemap(:, 2), oldName), 1, 'first');
    if ~isempty(ixr)
        % Then we found old name in the second column. Just replace it and
        % we're done.
        nameRemap{ixr, 2} = newName;        
    else
        % Then we haven't yet changed this name and we must need to add it
        % to the list.
        nameRemap = [nameRemap; oldname, newName];
    end
end

handles.nameRemap = nameRemap;
guidata(handles.figure1, handles);
