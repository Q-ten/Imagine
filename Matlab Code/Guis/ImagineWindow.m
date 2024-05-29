function varargout = ImagineWindow(varargin)
% ImagineWindow M-file for ImagineWindow.fig
%      ImagineWindow, by itself, creates a new ImagineWindow or raises the existing
%      singleton*.
%
%      H = ImagineWindow returns the handle to a new ImagineWindow or the handle to
%      the existing singleton*.
%
%      ImagineWindow('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ImagineWindow.M with the given input arguments.
%
%      ImagineWindow('Property','Value',...) creates a new ImagineWindow or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImagineWindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImagineWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ImagineWindow

% Last Modified by GUIDE v2.5 26-Jun-2011 13:57:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImagineWindow_OpeningFcn, ...
                   'gui_OutputFcn',  @ImagineWindow_OutputFcn, ...
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


% --- Executes just before ImagineWindow is made visible.
function ImagineWindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImagineWindow (see VARARGIN)


% Choose default command line output for ImagineWindow
handles.output = hObject;

handles.cropMgr = CropManager.getInstance;
handles.iwm = ImagineWindowManager.getInstance;
handles.imagineOb = ImagineObject.getInstance;
handles.regimeMgr = RegimeManager.getInstance;
handles.climateMgr = ClimateManager.getInstance;
% ... add other managers here...

guidata(hObject, handles);

% This is all the ImagineWindow is responsible for. The 'Imagine' program
% does not reside here, but rather in the ImagineObject, which has an
% ImagineWindowManager which will have a reference to this window.

% This file should contain only callbacks from controls in this figure. And
% many of these will refer to the ImagineWindowManager.

%                 initialiseLayouts(handles);
%                 handles = guidata(hObject);
% 
%                 initialiseImagine(handles);
%                 handles = guidata(hObject);
% 
%                 layout_Callback(hObject, [], 1, 1);
% 
% 
% 
%                 % OOP part of ImagineWindow...
%                 % Requesting the singleton instance should create and set up the Manager
%                 % objects too.
%                 handles.imagineObj = ImagineObject.getInstance;
%                 handles.imagineObj.initialiseImagine;
% 
%                 handles.cropMgr = handles.imagineObj.cropManager;
%                 handles.regimeMgr = handles.imagineObj.regimeManager;
%                 handles.windowMgr = ImagineWindowManager.getInstance;
%                 handles.windowMgr.setupControls(handles.figure1, handles.controls);
% 
%                 % Here is where the ImagineWindowManager should set up the window instead
%                 % of having everything done in here. The code above should not be
%                 % necessary. Rather the managers should take care of everything. The
%                 % managers should be the only fields we add to handles.



% Show the splashScreen before we exit the startup.
uiwait(splashScreen)


% UIWAIT makes ImagineWindow wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ImagineWindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called





% --- Executes on selection change in cropListBox.
function cropListBox_Callback(hObject, eventdata, handles)
% hObject    handle to cropListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns cropListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cropListBox
selectionType = get(handles.figure1, 'SelectionType');
if strcmp(selectionType, 'open')
    editCropButton_Callback(handles.editCropButton, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function cropListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in editRainfallButton.
function editRainfallButton_Callback(hObject, eventdata, handles)
% hObject    handle to editRainfallButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

climateMgr = ClimateManager.getInstance;

climateMgr.editMonthlyRainfallParameters;
%climateMgr.drawFunction(handles.rainfallAxes);


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3


% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in removeRegimeButton.
function removeRegimeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeRegimeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)''
regimeIndex = get(handles.regimeListBox, 'Value');
if ~isempty(regimeIndex)
    if regimeIndex > 0
        handles.regimeMgr.removeRegime(regimeIndex);
    end
end

% --- Executes on button press in addAnnualRegimeButton.
function addAnnualRegimeButton_Callback(hObject, eventdata, handles)
% hObject    handle to addAnnualRegimeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.regimeMgr.addRegime('Annual');


% --- Executes on button press in addBeltRegimeButton.
function addBeltRegimeButton_Callback(hObject, eventdata, handles)
% hObject    handle to addBeltRegimeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%addRegime(handles, 'Belt', 0);
handles.regimeMgr.addRegime('Belt');

% --- Executes on button press in editRegimeButton.
function editRegimeButton_Callback(hObject, eventdata, handles)
% hObject    handle to editRegimeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
regimeIndex = get(handles.regimeListBox, 'Value');
if ~isempty(regimeIndex)
    if regimeIndex > 0
        handles.regimeMgr.editRegime(regimeIndex);
    end
end

% --- Executes on button press in editCropButton.
function editCropButton_Callback(hObject, eventdata, handles)
% hObject    handle to editCropButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cropNames = get(handles.cropListBox,'String');
if isempty(cropNames)
    return
end
selectedName = cropNames{get(handles.cropListBox,'Value')};
if ~isempty(selectedName)
    handles.cropMgr.editCrop(selectedName);
end

%addCrop(handles, 1);
% global imaginewindow
% 
% % get the crop
% cropNameList = get(handles.cropListBox, 'String');
% cropName = cropNameList(get(handles.cropListBox, 'Value'));
% cropIndex = find(strcmp(cropName, {imaginewindow.crops.name}),1);
% 
% % Open the crop dialogue
% uiwait(addCropOverview(imaginewindow.crops(cropIndex)));
% if(~isempty(imaginewindow.crops))
%     set(handles.cropListBox, 'String', {imaginewindow.crops.name});
% end

% --- Executes on button press in addNewCropButton.
function addNewCropButton_Callback(hObject, eventdata, handles)
% hObject    handle to addNewCropButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.cropMgr.addCrop;

%addCrop(handles, 0);
% 
% global imaginewindow;
% uiwait(addCropOverview);
% if(~isempty(imaginewindow.crops))
%     set(handles.cropListBox, 'String', {imaginewindow.crops.name});
% end

% --- Executes on button press in removeCropButton.
function removeCropButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeCropButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cropNames = get(handles.cropListBox,'String');
if isempty(cropNames)
    return
end
selectedName = cropNames{get(handles.cropListBox,'Value')};
if ~isempty(selectedName)
    handles.cropMgr.removeCrop(selectedName);
end

% --- Executes on selection change in regimeListBox.
function regimeListBox_Callback(hObject, eventdata, handles)
% hObject    handle to regimeListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns regimeListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from regimeListBox
selectionType = get(handles.figure1, 'SelectionType');
if strcmp(selectionType, 'open')
    editRegimeButton_Callback(handles.editRegimeButton, eventdata, handles);
end


% --- Executes during object creation, after setting all properties.
function regimeListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to regimeListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%Adds (or edits) a regime.
% type is the type of regime
% edittingLabel is used when a regime is to be editted rather than added.
% The type determines the list to look in.
% inplace is true when the selected regime (in listbox) is to be edited. If
% inplace is false, then we try to add a new regime.
function addRegime(handles, type, inplace)

global regimeData

regimeData = [];
edittingRegime = [];


% Are we editting? If so, what regime are we editting?
% And what type of regime is it? Which dialog do we open?
index = 0;
if(inplace)

   LBindex = get(handles.regimeListBox, 'Value');
   if(isempty(index))
       return
   end
   if(LBindex > length(handles.regimeLabels) || LBindex == 0)
       return
   end
   
   combinedList = [handles.primaryRegimes, handles.beltRegimes];
   combinedLabels = {combinedList.regimeLabel};
   selectedLabel = handles.regimeLabels{LBindex};
   index = find(strcmp(selectedLabel, combinedLabels), 1);
   
  if isempty(index)
     msgbox('Error: add(edit)Regime - the selected regime label doesn''t seem  to be a label for any regimes in our list.');
     return
  end
   
   if(index > length(handles.primaryRegimes))
       % then we must be in belt
       index = index - length(handles.primaryRegimes);
       edittingRegime = handles.beltRegimes(index);       
   else
       edittingRegime = handles.primaryRegimes(index);
   end

   type = edittingRegime.type;
   
end


% Which list do we care about? 1 for primary, 2 for belt.
% Also, get the list of start and end years for the regimes in the given
% zone. Need to pass this list to the regime dialog so it can make sure
% they dont overlap.
if(strcmp(type, 'Annual') || strcmp(type, 'Block'))
    list = 1;
    if(isempty(handles.primaryRegimes))
        regimeYears = [];
    else    
        regimeYears = [[handles.primaryRegimes.startYear]; [handles.primaryRegimes.finalYear]];
    end
elseif(strcmp(type, 'Belt') || strcmp(type, 'Border'))
    list = 2;
    if(isempty(handles.beltRegimes))
        regimeYears = [];
    else   
        regimeYears = [[handles.beltRegimes.startYear]; [handles.beltRegimes.finalYear]];
    end
else
    list = 0;
end

% General getting of crops and warning if there are none.
crops = handles.crops;

if(isempty(crops))
    msgbox('You need to define crops before you can define regimes.');
    return
end

% Fix for adding listOfCropNames to regimeData.
if ~isfield(handles.primaryRegimes, 'listOfCropNames') && ~isempty(handles.primaryRegimes)
    handles.primaryRegimes(end).listOfCropNames = {};
end
if ~isfield(handles.beltRegimes, 'listOfCropNames') && ~isempty(handles.beltRegimes)
    handles.beltRegimes(end).listOfCropNames = {};
end


if(strcmp(type, 'Annual'))

    primaryCrops = crops(strcmp({crops.category}, 'Annual'));
    companionCrops = crops(strcmp({crops.category}, 'Pasture'));    

    if(isempty(primaryCrops))
        msgbox('To define an Annual regime, you need to have defined crops in the Annual category. You might also want to define crops for companion planting.');
        return
    end

    if(index > 0)
        uiwait(AnnualRegimeDialog(crops, regimeYears, handles.regimeLabels, {primaryCrops.name}, {companionCrops.name}, edittingRegime));
    else
        uiwait(AnnualRegimeDialog(crops, regimeYears, handles.regimeLabels, {primaryCrops.name}, {companionCrops.name}));
    end
    
end


if(strcmp(type, 'Belt'))
   
    treeCrops = crops(strcmp({crops.category}, 'Coppice Tree Crop'));
    
    if(isempty(treeCrops))
        msgbox('To define a Belt, Block or Border regime, you need to have defined crops in the Tree category.');        
        return
    end
    
    if(index > 0)
        uiwait(BeltRegimeDialog(crops, regimeYears, handles.regimeLabels, {treeCrops.name}, {treeCrops.colour}, handles.imagineParameters, edittingRegime));
    else
        uiwait(BeltRegimeDialog(crops, regimeYears, handles.regimeLabels, {treeCrops.name}, {treeCrops.colour}, handles.imagineParameters));
    end
end

%%%%

% Do other regime types in here.

% Then check there are no conflicts.

% Check for cancel from the regime dialog too.

if(isempty(regimeData))
   return 
end

%%%%

if(list == 1)
    if(index > 0)
        handles.primaryRegimes(index) = regimeData;
        handles.primaryRegimeLines{index} = drawRegimes(regimeData, handles, handles.primaryRegimeLines{index});
    else
        handles.primaryRegimes;
        if(isempty(handles.primaryRegimes))
            handles.primaryRegimes = regimeData;
            handles.primaryRegimeLines = {drawRegimes(regimeData, handles, [])};
        else
            handles.primaryRegimes = [handles.primaryRegimes, regimeData];
            handles.primaryRegimeLines{end+1} = drawRegimes(regimeData, handles, []);
        end
    end    
elseif(list == 2)
    if(index > 0)
        handles.beltRegimes(index) = regimeData;
        handles.beltRegimeLines{index} = drawRegimes(regimeData, handles, handles.beltRegimeLines{index});
    else
        if(isempty(handles.beltRegimes))
            handles.beltRegimes = regimeData;
            handles.beltRegimeLines = {drawRegimes(regimeData, handles, [])};
        else
            handles.beltRegimes(end+1) = regimeData;
            handles.beltRegimeLines{end+1} = drawRegimes(regimeData, handles, []);
        end
    end  
end

% Now sort them both. NEED TO SORT THEIR LINE HANDLES AS WELL!

[handles.primaryRegimes, handles.primaryRegimeLines] = orderRegimes(handles.primaryRegimes, handles.primaryRegimeLines);
[handles.beltRegimes, handles.beltRegimeLines] = orderRegimes(handles.beltRegimes, handles.beltRegimeLines);

% Now set up the listbox strings. Lets put the primary labels first when they start on
% the same year.
[combinedList, junk] = orderRegimes([handles.primaryRegimes, handles.beltRegimes], zeros(1, length(handles.primaryRegimes) + length(handles.beltRegimes)));
handles.regimeLabels = {combinedList.regimeLabel};
set(handles.regimeListBox, 'String', handles.regimeLabels);
set(handles.regimeListBox, 'Value', find(strcmp(regimeData.regimeLabel, handles.regimeLabels), 1));
setupYearlySummary(handles);
guidata(handles.axes1, handles);


% Removes the regime from the listbox and the individual list.
function removeRegime(handles)

if(isempty(handles.regimeLabels))
    return
end

selectionIndex = get(handles.regimeListBox, 'Value');
selectedLabel = handles.regimeLabels{selectionIndex};
combinedList = [handles.primaryRegimes, handles.beltRegimes];
combinedLabels = {combinedList.regimeLabel};
index = find(strcmp(selectedLabel, combinedLabels), 1);

if isempty(index)
 msgbox('Error: removeRegime - the selected regime label doesn''t seem  to be a label for any regimes in our list.');
 return
end


if(index > length(handles.primaryRegimes))
   % then we must be in belt
   index = index - length(handles.primaryRegimes);
   handles.beltRegimes = handles.beltRegimes([1:index-1, index+1:end]);
   lines = handles.beltRegimeLines{index};
   for i = 1:length(lines)
      if(lines(i) > 0)
        delete(lines(i));
      end
   end
   handles.beltRegimeLines = handles.beltRegimeLines([1:index-1, index+1:end]);
else
   handles.primaryRegimes = handles.primaryRegimes([1:index-1, index+1:end]);
   lines = handles.primaryRegimeLines{index};
   for i = 1:length(lines)
      if(lines(i) > 0)
        delete(lines(i));
      end
   end
   handles.primaryRegimeLines = handles.primaryRegimeLines([1:index-1, index+1:end]);
end

% Now set up the listbox strings. Lets put the primary labels first when they start on
% the same year.
[combinedList, junk] = orderRegimes([handles.primaryRegimes, handles.beltRegimes], zeros(1, length(handles.primaryRegimes) + length(handles.beltRegimes)));
handles.regimeLabels = {combinedList.regimeLabel};
set(handles.regimeListBox, 'String', handles.regimeLabels);
if(get(handles.regimeListBox, 'Value') > length(handles.regimeLabels))
    set(handles.regimeListBox, 'Value', max([1, length(handles.regimeLabels)]));
end

guidata(handles.axes1, handles);
updateLayouts(handles);   
setupYearlySummary(handles);


% Saves current ImagineWindow setup
function wasSaved = saveImagine(handles)

imObj = ImagineObject.getInstance;

    % Need to use uiputfile, as uisave does not compile.
    % Need to use the last save path to init the save location, if it exists.
    if isempty(imObj.savePath)
        saveLoc = [ImagineObject.imagineRoot, '/Resources/ImagineSetups'];
    else
        saveLoc = imObj.savePath;
    end

    [file, path, filt] = uiputfile('.mat', 'Save Imagine setup to .MAT File', saveLoc);

    if(isequal(path, 0) || isequal(file, 0))
        % User cancelled save. Do nothing.
        wasSaved = false;
        return
    end

wasSaved = imObj.save(path, file);



% Asks user to choose which file to load from and loads ImagineWindow.
% Then use setupControls to set the figure up.
function loadSavedImagine(handles)

imObj = ImagineObject.getInstance;

    % Ask for the file to load.
    % Need to use the last load path to init the load location, if it exists.
    if isempty(imObj.savePath)
        loadLoc = [ImagineObject.imagineRoot, '/Resources/ImagineSetups'];
    else
        loadLoc = imObj.savePath;
    end

    [file, path, filt] = uigetfile('.mat', 'Load Imagine setup from File', loadLoc);

    if(isequal(path, 0) || isequal(file, 0))
        return
    end

imObj = ImagineObject.getInstance;
imObj.load(path, file);


% Uses handles to setup the controls.
%
function setupControls(handles)

set(handles.cropListBox, 'Value', 1);
set(handles.cropListBox, 'String', handles.cropList);

set(handles.regimeListBox, 'Value', 1);
set(handles.regimeListBox, 'String', handles.regimeLabels);

drawMonthlyRainfallModel(handles.rainfallModel, handles.rainfallAxes);

initialiseLayouts(handles);
handles = guidata(handles.axes1);
updateLayouts(handles);

for i = 1:length(handles.primaryRegimes)
    handles.primaryRegimeLines{i} = drawRegimes(handles.primaryRegimes(i), handles, []);
end
for i = 1:length(handles.beltRegimes)
    handles.beltRegimeLines{i} = drawRegimes(handles.beltRegimes(i), handles, []);
end
setupYearlySummary(handles);
guidata(handles.regimeListBox, handles);


% adds a crop to ImagineWindow.
% if inplace is tru, edit the selected crop.
function addCrop(handles, inplace)

global cropData

cropData = [];
cropIndex = 0;

if(inplace)
    % Get the selected crop
    index = get(handles.cropListBox, 'Value');
    if(isempty(index))
        return
    end
    if(index > length(handles.crops) || index == 0)
        return
    end
    cropName = handles.cropList(index);
    cropIndex = find(strcmp(cropName, {handles.crops.name}),1);
  %  uiwait(cropWizard(handles.imagineParameters, existingCropNames, handles.crops(cropIndex)));
    uiwait(cropWizard(handles.crops(cropIndex), {handles.crops.name}))
else
    uiwait(cropWizard([], {handles.crops.name}))
%    uiwait(cropWizard(handles.imagineParameters, existingCropNames));
end

% We may have cancelled the operation.
if(isempty(cropData))
    return;
end

% if crop is the only crop, then its the crop.

if(isempty(handles.crops))
    handles.crops = cropData;
    handles.cropList = {cropData.name};
    ix = 1;
else
    if(inplace)
        handles.crops(cropIndex)
        handles.crops(cropIndex) = cropData;    
    else
        handles.crops = [handles.crops cropData];
    end
    [handles.cropList, ix] = sort({handles.crops.name});
    handles.crops = handles.crops(ix);
end

set(handles.cropListBox, 'String', handles.cropList);

if(inplace)
    set(handles.cropListBox, 'Value', ix(cropIndex));
else        
    set(handles.cropListBox, 'Value', ix(end));    
end


updateLayouts(handles);
setupYearlySummary(handles);
guidata(handles.cropListBox, handles);


% Removes the selected crop if its Ok to do so.
%
function removeCrop(handles)

cropIndex = get(handles.cropListBox, 'Value');

if(isempty(cropIndex))
    return
end
if(cropIndex > length(handles.cropList))
    return
end

cropName = handles.cropList{cropIndex};

% Check if the crop is used in any of the regimes.
regimesWithCrop = {};
for i = 1:length(handles.primaryRegimes)
   inRegime = 0;
    regime = handles.primaryRegimes(i);
    if(strcmp(regime.type, 'Annual'))
       for j = 1:length(regime.parameters.rotationList)
          rotation = regime.parameters.rotationList(j);
          if(strcmp(rotation.crop, cropName) || strcmp(rotation.companionCrop, cropName))
             inRegime = 1;
          end
       end
    end   
   if(inRegime)
      regimesWithCrop = [regimesWithCrop, regime.regimeLabel]; 
   end
end
for i = 1:length(handles.beltRegimes)
    regime = handles.beltRegimes(i);
    if(strcmp(regime.type, 'Belt'))
        if(strcmp(regime.parameters.crop, cropName))
           regimesWithCrop = [regimesWithCrop, regime.regimeLabel]; 
        end
    end
end

regimesWithCrop = sort(regimesWithCrop);

if(~isempty(regimesWithCrop))
    qstring = {['The selected crop (', cropName, ') is used in the following regime(s):',], '',...
       char(regimesWithCrop), ...
    '', 'Removing this crop will ALSO REMOVE THESE REGIMES!', '', 'Are you sure you want to continue?'};
    button = questdlg(qstring, 'Confirm Crop and Regime Removal', 'Yes', 'No', 'No');
    if(strcmp(button, 'No'))
        return
    end
end

qstring = ['This action will remove the ', cropName, ' crop from Imagine. Are you sure you want to continue?'];
button = questdlg(qstring, 'Confirm Crop Removal', 'Yes', 'No', 'No');

if(strcmp(button, 'No'))
   return 
end

% Remove the regimes that have the crop in them.
for i = 1:length(regimesWithCrop)
  ix = find(strcmp(handles.regimeLabels, regimesWithCrop{i})); 
  set(handles.regimeListBox, 'Value', ix);
  removeRegime(handles);
  handles = guidata(handles.regimeListBox);
end

% Remove the crop
handles.crops = handles.crops([1:cropIndex-1, cropIndex+1:end]);
handles.cropList = handles.cropList([1:cropIndex-1, cropIndex+1:end]);

[handles.cropList, ix] = sort(handles.cropList);
handles.crops = handles.crops(ix);

guidata(handles.cropListBox, handles);

set(handles.cropListBox, 'String', handles.cropList);
set(handles.cropListBox, 'Value', 1);



% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function loadItem_Callback(hObject, eventdata, handles)
% hObject    handle to loadItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadSavedImagine(handles);

% --------------------------------------------------------------------
function wasSaved = saveItem_Callback(hObject, eventdata, handles)
% hObject    handle to saveItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wasSaved = saveImagine(handles);


% --- Executes on button press in simulateButton.
function simulateButton_Callback(hObject, eventdata, handles)
% hObject    handle to simulateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
simulate(handles);


% Function that checks whether ImagineWindow is ready for a simulation yet.
% If so, opens the simulation dialogue. If not, explains what the problem
% is.
function simulate(handles)

mstring = {};
problems = 0;

if ~handles.climateMgr.isReadyForSimulation
%if(~isValidRainfallModel(handles.rainfallModel, handles.imagineParameters.simLength))

    problems = problems + 1;
    mstring = [mstring, {['Problem ', num2str(problems), ':'], ...
                        'Rainfall model needs to be defined properly first.'}];
    
end

if(~handles.regimeMgr.isReadyForSimulation)
    problems = problems + 1;
    
    if(problems > 1)
        mstring = [mstring, {'', ''}];
    end
    
    mstring = [mstring, {['Problem ', num2str(problems), ':'], ...
                        'You need to define at least one regime, and all regimes must be valid with regimes not overlapping in their respective zones.'}];       
end

if(problems > 0)
    warndlg(mstring, 'Problems with Imagine setup');
else
    % Launch the simulation dialog.
    % It doesn't need any variables because it's now independent. It
    % queries the managers.
    SimulationManager.getInstance.launchSimulationDialogue;
end


% --------------------------------------------------------------------
function NewItem_Callback(hObject, eventdata, handles)
% hObject    handle to NewItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
qstring = {'Starting anew will get rid of the current setup.', '', 'Would you like to save it first?'};
title = 'Save first?';
button = questdlg(qstring, title);

if(isempty(button) || strcmp(button, 'Cancel'))
    return
elseif(strcmp(button, 'Yes'))
   wasSaved = saveItem_Callback(hObject, eventdata, handles); 
   if (wasSaved)
       uiwait(msgbox('Your setup has been saved. Starting anew...'));
   else
       return
   end
end
imObj = ImagineObject.getInstance();
imObj.initialiseImagine;
%loadSavedImagine(handles); %, 'emptyImagine.mat', './ImagineSetups/');


% --------------------------------------------------------------------
function uipushtoolNew_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NewItem_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function uipushtoolOpen_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadItem_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function uipushtoolSave_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveItem_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function layout_Callback(hObject, eventdata, i, j)
% hObject    handle to uipushtoolSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

set(handles.selectYearPatch, 'Visible', 'off');
set(handles.selectYearPatch, 'XData', (j-1)*70 + [6 6 64 64]);
set(handles.selectYearPatch, 'YData', 500-i*100 + [26 84 84 26]);
set(handles.selectYearPatch, 'Visible', 'on');

handles.summaryYear = (i-1)*10 + j;
guidata(hObject, handles);

setupYearlySummary(handles);


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1




% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SetupItem_Callback(hObject, eventdata, handles)
% hObject    handle to SetupItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function paddockLayoutItem_Callback(hObject, eventdata, handles)
% hObject    handle to paddockLayoutItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiwait(paddockSetupDialog());
