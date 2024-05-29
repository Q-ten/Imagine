function varargout = BeltRegimeDialog(varargin)
% BELTREGIMEDIALOG M-file for BeltRegimeDialog.fig
%      BELTREGIMEDIALOG, by itself, creates a new BELTREGIMEDIALOG or raises the existing
%      singleton*.
%
%      H = BELTREGIMEDIALOG returns the handle to a new BELTREGIMEDIALOG or the handle to
%      the existing singleton*.
%
%      BELTREGIMEDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BELTREGIMEDIALOG.M with the given input arguments.
%
%      BELTREGIMEDIALOG('Property','Value',...) creates a new BELTREGIMEDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BeltRegimeDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BeltRegimeDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BeltRegimeDialog

% Last Modified by GUIDE v2.5 25-Jun-2013 08:39:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BeltRegimeDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @BeltRegimeDialog_OutputFcn, ...
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


% --- Executes just before BeltRegimeDialog is made visible.
function BeltRegimeDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BeltRegimeDialog (see VARARGIN)

handles.output = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Arguments:
%
% Pass in a single struct containing arguments in the following fields.
%
% existingRegimeDefinitions
% existingCropDefinitions
% regimeParameters
%
% existingRegimeDefinitions - a struct array with fields regimeLabels,
% regimeStartYears, regimeFinalYears, regimeCategory, regimeType
%
% existingCropDefinitions - a struct array with a field cropName,
% cropCategory, and eventDefinitions
%
% regimeParameters will be a struct containing the parameters used to define this regime.
% Will be empty or absent if this is a new regime, but present if this is
% an editted regime.

if nargin < 4
    disp('Must pass a regimeArguments struct, which should have at least two fields - the regimeDefinitons and the cropDefinitions.')
    return
end
    
regimeArguments = varargin{1};

argumentFields = {'regimeDefinitions', 'cropDefinitions'};

% For each argument field, add it to handles if it exists. Otherwise set it
% to empty.
% NOTE - Perhaps this should be done so that handles is defined with
% default values, and then the for loop overwrites fields if they exist in
% the regimeArguments struct.
for i = 1:length(argumentFields)
    if isfield(regimeArguments, argumentFields{i})
        handles.(argumentFields{i}) = regimeArguments.(argumentFields{i});
    else
        handles.(argumentFields{i}) = [];
    end
end

%%%%%%%%%%%%%%%
% Specify cropDefinition and RegimeDefinition and other fixed parameters.

% We should have been passed the existingCropDefinitions. Use them to
% create handles.cropsList and handles.cropsColours

% get the crop definitions that are tree crops.
treeCropDefinitions = handles.cropDefinitions(strcmp({handles.cropDefinitions.categoryName}, 'Coppice Tree Crop'));
if isempty(treeCropDefinitions)   
    uiwait(warndlg('No tree crops are defined, or at least none were passed to the Belt Regime Dialog.'));
    delete(handles.figure1);
    return
end
handles.cropsList = {treeCropDefinitions.name};
handles.cropColours = {treeCropDefinitions.colour};

% create the regime specific parameters regimeYears (covering the years for
% secondary regimes) and existingRegimeLabels (covering all regimes)
secondaryRegimeDefinitions = handles.regimeDefinitions(strcmp({handles.regimeDefinitions.type}, 'secondary'));
handles.regimeYears = [[secondaryRegimeDefinitions.startYear]; [secondaryRegimeDefinitions.finalYear]];
handles.secondaryRegimeDefinitions = secondaryRegimeDefinitions;

handles.existingRegimeLabels = {handles.regimeDefinitions.regimeLabel};

% Use ImagineObject to set up handle.imagineParameters
    imOb = ImagineObject.getInstance;
    iPs.simLength = imOb.simulationLength;
    iPs.paddockWidth = imOb.paddockWidth;
    iPs.paddockLength = imOb.paddockLength;
    handles.imagineParameters = iPs;

% Set up months list and a list of the border and belt controls so that
% they are easily enabled or disabled as one. 
handles.months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
handles.borderControlsList = [handles.gapLengthAtCornersLabel, handles.gapLengthAtCornersEdit];
handles.beltControlsList = [handles.requiredHeadlandLabel, handles.headlandEdit, ...
              handles.numberOfBeltsLabel, handles.beltNumDDL, ...
              handles.spacingBetweenBeltsLabel, handles.beltSpacingEdit];

%%%%%%%%%%%%%%%%%%
% Specify default values and then load the values passed to overwrite if
% they exist

% The Belt Regime specifies a layout of woody crops within a paddock. The
% woody crops are grown in plantation along belts within the paddock and/or 
% along the borders. The belt regime parameters define whether the belts or
% borders are used, and the details of the layout.
% Also defined are the harvest events. These are coppice harvests and don't
% destroy the crop. The user can choose how the coppice events are defined.
% Additionally the standard parameters of a regime need to be defined.

% Set up default regime parameters

   handles.regimeLabel =  'New Belt Regime';
   handles.timelineColour = [1 0 0]; % red
   handles.startYear =  1;
   handles.finalYear =  1;
   handles.plantingMonth = 'Apr';
   handles.crop = handles.cropsList{1};
   handles.harvestYears = [];
   handles.harvestMonth = 'Jan';
   handles.rowsPerBelt = 1;
   handles.rowSpacing = 2;
   handles.exclusionZone = 1;
   handles.plantSpacing = 2;
   handles.headland = 30;
   handles.beltNum = 9;
  
   handles.biomassThreshold = 0;
   handles.biomassThresholdUnit = '';
   handles.coppiceTriggerChoice = '';
   
   handles.gapLengthAtCorners = 30;
   handles.useBelts = 0;
   handles.useBorders = 0;
   handles.cropEvents = [];

handles.cropEventTriggers = struct('cropName', {}, 'eventTriggers', {});


% has
% cropName
% eventsTriggers
    % has
    % eventName
    % trigger

if isfield(regimeArguments, 'regimeParameters')
   
    regParList = {'regimeLabel', 'timelineColour', 'startYear', 'finalYear', 'cropEventTriggers'};

    for i = 1:length(regParList)
       if isfield(regimeArguments.regimeParameters, regParList{i})
           % Then overwrite the default regPars with what is provided in
           % the regimeArguments.
           handles.(regParList{i}) = regimeArguments.regimeParameters.(regParList{i});
       end
    end  
    
    % if we got the beltRegimeParameters, then get all it's parameters too.
    % Put everything into handles.
    if isfield(regimeArguments.regimeParameters, 'beltRegimeParameters')
       
        regParList = {'useBelts', 'useBorders', 'crop', 'harvestYears', 'plantingMonth', ...
                      'harvestMonth', 'rowsPerBelt', 'rowSpacing', 'exclusionZone', 'plantSpacing', ...
                      'headland', 'beltNum', 'biomassThreshold', 'biomassThresholdUnit', 'coppiceTriggerChoice'};

        for i = 1:length(regParList)
            brp = regimeArguments.regimeParameters.beltRegimeParameters
           if isfield(regimeArguments.regimeParameters.beltRegimeParameters, regParList{i})
               % Then overwrite the default regPars with what is provided in
               % the regimeArguments.
               regParList{i}
               handles.(regParList{i}) = regimeArguments.regimeParameters.beltRegimeParameters.(regParList{i});
           end
        end 
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update CropEventTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% At this point we'll have loaded the cropEventTriggers that were last
% saved in the regime. However there could have been changes in the crops
% themselves. For instance we could have added or removed a financial
% event.
% We should make sure the current crop's events are present in the regime's
% cropEventTriggers struct. We want to keep what was there if it's still
% appropriate, but use the crop's ones if they are there.
% So we import ones that aren't already there. (Add newly defined financial
% events), we overwrite ones that are still there, unless the ones in the
% regime are regime redefined.
% That amounts to overwriting all the events, except ones that are regime
% redefined, or defferred to regime.
% This is something that should occur before we run a simulation as well.
% If we change something in the crop, don't we want that reflected in the
% regimes too? For example, if we say that an event is not regime
% redefinable in the crop, we should not use the regime one.
if ~isempty(handles.cropEventTriggers)
    handles.cropEventTriggers = updateCropEventTriggers({handles.crop}, handles.cropEventTriggers);
end




%%%%%%%%%%%%%%%%%%%
% Update regimeYears and existingRegimeLabels after we've saved the passed
% regime's parameters.

    if ~isempty(handles.secondaryRegimeDefinitions)
       % if we find the regime years for this crop in the given regime years,
       % we'll just get rid of them.
       handles.regimeYears = handles.regimeYears(:,~(handles.startYear == handles.regimeYears(1,:) | handles.finalYear == handles.regimeYears(2,:)));
    end
    
    if ~isempty(handles.regimeDefinitions)
       % similarly, we should remove the current regime's name from the list of
       % names that it cant use.
       handles.existingRegimeLabels = handles.existingRegimeLabels(~strcmp(handles.regimeLabel, handles.existingRegimeLabels));
    end 

   

% % The first two parameters are the lists of crops and imagine parameters that
% % are available.
% % The first two parameters are the lists of crops and companion crops that
% % are available.
% 
% %used to be:
% % (crops, regimeYears, handles.regimeLabels, {treeCrops.name}, {treeCrops.colour}, handles.imagineParameters, edittingRegime))
% 
% % Changing to :
% % regimeArguments.
% % It has at least two arguments: regimeDefinitions, cropDefinitions, and
% % probable regimeParameters.
% 
% % most of what we need is provided in the regime and crop definitions.
% 
% 
% 
% 
% if nargin < 7    
%    uiwait(msgbox('Need to pass the regime dialog the crops list now, as first argument.'))
% elseif ~isValidCrop(varargin{1})
%    uiwait(msgbox('Need to pass the regime dialog the crops list now, as first argument'))  
% end
% 
% handles.crops = varargin{1};
% 
% if(nargin < 9)
%     handles.regimeYears = [];
%     handles.primaryCrops = {'Barley', 'Canola', 'Wheat', 'Test'};
%     handles.companionCrops = {'None', 'Lucerne', 'Pasture', 'Salt Pastures', 'Test'};
%     handles.existingRegimeLabels = {};
% else
%     handles.regimeYears = varargin{2};
%     handles.existingRegimeLabels = varargin{3};
%     handles.primaryCrops = varargin{4};
%     handles.companionCrops = ['None', varargin{5}];
% end
% 
% 
% if(nargin < 9)
%     handles.cropsList = {'Native Reveg', 'Oil Mallee', 'Pine'};
%     handles.cropColours = {[0 0 1], [0 1 0], [1 0 0]};
%     imOb = ImagineObject.getInstance;
%     iPs.simLength = imOb.simulationLength;
%     iPs.paddockWidth = imOb.paddockWidth;
%     iPs.paddockLength = imOb.paddockLength;
%     handles.imagineParameters = iPs;
%     handles.regimeYears = [];
%     handles.existingRegimeLabels = {};
% else
%     handles.regimeYears = varargin{2};    
%     handles.existingRegimeLabels = varargin{3};
%     handles.cropsList = varargin{4};
%     handles.cropColours = varargin{5};
%     handles.imagineParameters = varargin{6};
% end
% 
% handles.months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
% handles.borderControlsList = [handles.gapLengthAtCornersLabel, handles.gapLengthAtCornersEdit];
% handles.beltControlsList = [handles.requiredHeadlandLabel, handles.headlandEdit, ...
%               handles.numberOfBeltsLabel, handles.beltNumDDL, ...
%               handles.spacingBetweenBeltsLabel, handles.beltSpacingEdit];
% 
% % Check if we have an incoming regime. If so, fill up the dialog, else
% % initialise the dialog.
% if(nargin > 9)
%    handles.regimeLabel =  varargin{7}.regimeLabel;
%    handles.timelineColour = varargin{7}.timelineColour;
%    handles.startYear =  varargin{7}.startYear;
%    handles.finalYear =  varargin{7}.finalYear;
%    handles.plantingMonth = varargin{7}.parameters.plantingMonth;
%    handles.crop = varargin{7}.parameters.crop; 
%    handles.harvestYears = varargin{7}.parameters.harvestYears;
%    handles.harvestMonth = varargin{7}.parameters.harvestMonth;
%    handles.rowsPerBelt = varargin{7}.parameters.rowsPerBelt;
%    handles.rowSpacing = varargin{7}.parameters.rowSpacing;
%    handles.exclusionZone = varargin{7}.parameters.exclusionZone;
%    handles.plantSpacing = varargin{7}.parameters.plantSpacing;
%    handles.headland = varargin{7}.parameters.headland;
%    handles.beltNum = varargin{7}.parameters.beltNum;
%    if isfield(varargin{7}.parameters, 'biomassThreshold')
%        handles.biomassThreshold = varargin{7}.parameters.biomassThreshold;
%    else
%        handles.biomassThreshold = 0;
%    end
%    if isfield(varargin{7}.parameters, 'biomassThresholdUnit')
%        handles.biomassThresholdUnit = varargin{7}.parameters.biomassThresholdUnit;
%    else
%        handles.biomassThresholdUnit = '';
%    end
%    
%   if isfield(varargin{7}.parameters, 'coppiceTriggerChoice')
%        handles.coppiceTriggerChoice = varargin{7}.parameters.coppiceTriggerChoice;
%    else
%        handles.coppiceTriggerChoice = '';
%    end
%   
%    
%    if isfield(varargin{7}.parameters, 'cropEvents')
%         handles.cropEvents = varargin{7}.parameters.cropEvents;
%    else
%        handles.cropEvents = [];
%    end
%    
%    if isfield(varargin{7}.parameters, 'customCoppiceConditions')
%        handles.customCoppiceConditions = varargin{7}.parameters.customCoppiceConditions;
%    end
%    
%   
%    if(isfield(varargin{7}.parameters, 'gapLengthAtCorners'))
%         handles.gapLengthAtCorners = varargin{7}.parameters.gapLengthAtCorners;
%    else
%        handles.gapLengthAtCorners = 30;
%    end
%    if(isfield(varargin{7}.parameters, 'useBelts'))
%        handles.useBelts = varargin{7}.parameters.useBelts;
%    else
%        handles.useBelts = 1;
%    end
%    if(isfield(varargin{7}.parameters, 'useBelts'))
%        handles.useBorders = varargin{7}.parameters.useBorders;
%    else
%        handles.useBorders = 0;
%    end
%    
%    % if we find the regime years for this crop in the given regime years,
%    % we'll just get rid of them.
%    handles.regimeYears = handles.regimeYears(:,~(handles.startYear == handles.regimeYears(1,:) | handles.finalYear == handles.regimeYears(2,:)))
%    
%    % similarly, we should remove the current regime's name from the list of
%    % names that it cant use.
%    handles.existingRegimeLabels = handles.existingRegimeLabels(~strcmp(handles.regimeLabel, handles.existingRegimeLabels));
%    
% else
%    handles.regimeLabel =  'New Belt Regime';
%    handles.timelineColour = [1 0 0]; % blue
%    handles.startYear =  1;
%    handles.finalYear =  1;
%    handles.crop = handles.cropsList{1};
%    handles.harvestYears = [];
%    handles.harvestMonth = 'Jan';
%    handles.rowsPerBelt = 1;
%    handles.rowSpacing = 2;
%    handles.exclusionZone = 1;
%    handles.plantSpacing = 2;
%    handles.headland = 30;
%    handles.beltNum = 9;
%   
%    handles.biomassThreshold = 0;
%    handles.biomassThresholdUnit = '';
%    handles.coppiceTriggerChoice = '';
%    
%    handles.gapLengthAtCorners = 30;
%    handles.useBelts = 0;
%    handles.useBorders = 0;
%    handles.cropEvents = [];
% end
% 
% handles = handles
% ce = handles.cropEvents
% ce = mergeCropEvents(handles.crops(strcmp({handles.crops.name}, handles.crop)), handles.cropEvents)
% handles.cropEvents = ce


 % Update handles structure
guidata(hObject, handles);

setupControls(handles);
% axes(handles.axes1);
% treesx = 30:2:(1000-30);
% treesy = 30*ones(1,length(treesx));
% hold on
% scatter(treesx, treesy, 4, [0 0.5 0]);
% scatter(treesx, treesy+2, 4, [0 0.5 0]);
% scatter(treesx, treesy+4, 4, [0 0.5 0]);
% axis([0 1000 0 1000])

% UIWAIT makes BeltRegimeDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BeltRegimeDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1} = [];
else
    varargout{1} = handles.output;
    close(handles.figure1);
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(gcf);

% --- Executes on button press in acceptButton.
function acceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
returnRegime(handles);



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in startYearDDL.
function startYearDDL_Callback(hObject, eventdata, handles)
% hObject    handle to startYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns startYearDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from startYearDDL


% --- Executes during object creation, after setting all properties.
function startYearDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finalYearDDL.
function finalYearDDL_Callback(hObject, eventdata, handles)
% hObject    handle to finalYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns finalYearDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finalYearDDL


% --- Executes during object creation, after setting all properties.
function finalYearDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finalYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cropDDL.
function cropDDL_Callback(hObject, eventdata, handles)
% hObject    handle to cropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns cropDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cropDDL
updatePaddockSummary(handles)

% --- Executes during object creation, after setting all properties.
function cropDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cropDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function harvestYearsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to harvestYearsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harvestYearsEdit as text
%        str2double(get(hObject,'String')) returns contents of harvestYearsEdit as a double

harvestYears = str2num(get(hObject, 'String'));
if(~any(isnan(harvestYears)))
    handles.harvestYears = floor(harvestYears); 
    guidata(hObject, handles);
end
set(hObject, 'String', num2str(handles.harvestYears));


% --- Executes during object creation, after setting all properties.
function harvestYearsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harvestYearsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in rowsPerBeltDDL.
function rowsPerBeltDDL_Callback(hObject, eventdata, handles)
% hObject    handle to rowsPerBeltDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns rowsPerBeltDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rowsPerBeltDDL
updateBeltWidth(handles);

% --- Executes during object creation, after setting all properties.
function rowsPerBeltDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rowsPerBeltDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rowSpacingEdit_Callback(hObject, eventdata, handles)
% hObject    handle to rowSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rowSpacingEdit as text
%        str2double(get(hObject,'String')) returns contents of rowSpacingEdit as a double
updateBeltWidth(handles);

% --- Executes during object creation, after setting all properties.
function rowSpacingEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rowSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function exclusionZoneEdit_Callback(hObject, eventdata, handles)
% hObject    handle to exclusionZoneEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of exclusionZoneEdit as text
%        str2double(get(hObject,'String')) returns contents of exclusionZoneEdit as a double
updateBeltWidth(handles);

% --- Executes during object creation, after setting all properties.
function exclusionZoneEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exclusionZoneEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plantSpacingEdit_Callback(hObject, eventdata, handles)
% hObject    handle to plantSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plantSpacingEdit as text
%        str2double(get(hObject,'String')) returns contents of plantSpacingEdit as a double
plantSpacing = str2double(get(hObject, 'String'));
if(~isnan(plantSpacing))
    
    min_ = 1;
    max_ = 100;
    
    if(plantSpacing < min_)
        plantSpacing = min_;
    elseif(plantSpacing > max_)
        plantSpacing = max_;
    end       
    
    handles.plantSpacing = plantSpacing; 
    guidata(hObject, handles);
end
set(hObject, 'String', num2str(handles.plantSpacing));
updatePaddockSummary(handles);


% --- Executes during object creation, after setting all properties.
function plantSpacingEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plantSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function headlandEdit_Callback(hObject, eventdata, handles)
% hObject    handle to headlandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of headlandEdit as text
%        str2double(get(hObject,'String')) returns contents of headlandEdit as a double
headland = str2double(get(hObject, 'String'));
if(~isnan(headland))    
        
    min_ = 10;
    max_ = 100;
    
    if(headland < min_)
        headland = min_;
    elseif(headland > max_)
        headland = max_;
    end   
    
    handles.headland = headland;
    guidata(hObject, handles);
end
set(hObject, 'String', num2str(handles.headland));
updatePaddockSummary(handles);


% --- Executes during object creation, after setting all properties.
function headlandEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to headlandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in beltNumDDL.
function beltNumDDL_Callback(hObject, eventdata, handles)
% hObject    handle to beltNumDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns beltNumDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from beltNumDDL
updateBeltSpacing(handles, 'beltNum');

% --- Executes during object creation, after setting all properties.
function beltNumDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beltNumDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function beltSpacingEdit_Callback(hObject, eventdata, handles)
% hObject    handle to beltSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beltSpacingEdit as text
%        str2double(get(hObject,'String')) returns contents of beltSpacingEdit as a double
updateBeltSpacing(handles, 'beltSpacing');

% --- Executes during object creation, after setting all properties.
function beltSpacingEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beltSpacingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function regimeLabelEdit_Callback(hObject, eventdata, handles)
% hObject    handle to regimeLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of regimeLabelEdit as text
%        str2double(get(hObject,'String')) returns contents of regimeLabelEdit as a double


% --- Executes during object creation, after setting all properties.
function regimeLabelEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to regimeLabelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
handles.timeLineColour = C;
guidata(handles.changeColourButton, handles);
set(handles.timelineColourPanel, 'BackgroundColor', C);


% --- Executes on selection change in plantMonthDDL.
function plantMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to plantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns plantMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plantMonthDDL


% --- Executes during object creation, after setting all properties.
function plantMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plantMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% Initialises the controls based on the values in handles.
%
function setupControls(handles)

set(handles.cropDDL, 'String', handles.cropsList);
set(handles.regimeLabelEdit, 'String', handles.regimeLabel);
set(handles.timelineColourPanel, 'BackgroundColor', handles.timelineColour);
set(handles.startYearDDL, 'Value', handles.startYear);
set(handles.finalYearDDL, 'Value', handles.finalYear);

cropIndex = find(strcmp(handles.crop, handles.cropsList), 1);

if(cropIndex == 0)
    msgbox('Error: setupControls (beltRegime) the belt regime we''re tyring to load is not in the list of valid crops.');
    close(gcf)
else
    set(handles.cropDDL, 'Value', cropIndex);
end

set(handles.harvestYearsEdit, 'String', num2str(handles.harvestYears));

monthIndex = find(strcmp(handles.harvestMonth, handles.months));
set(handles.harvestMonthDDL, 'Value', monthIndex);

monthIndex = find(strcmp(handles.plantingMonth, handles.months));
set(handles.plantMonthDDL, 'Value', monthIndex);




set(handles.rowsPerBeltDDL, 'Value', handles.rowsPerBelt);
set(handles.rowSpacingEdit, 'String', num2str(handles.rowSpacing));
set(handles.exclusionZoneEdit, 'String', num2str(handles.exclusionZone));
updateBeltWidth(handles);

set(handles.plantSpacingEdit, 'String', num2str(handles.plantSpacing));
set(handles.headlandEdit, 'String', num2str(handles.headland));
set(handles.beltNumDDL, 'Value', handles.beltNum);
updateBeltSpacing(handles, 'beltNum');

set(handles.useBeltsCB, 'Value', handles.useBelts);
set(handles.useBordersCB, 'Value', handles.useBorders);
set(handles.gapLengthAtCornersEdit, 'String', num2str(handles.gapLengthAtCorners, '%3.2f'));
enableControls(handles.useBorders, handles.borderControlsList);
enableControls(handles.useBelts, handles.beltControlsList);

% Set up the biomass threshold units by getting the regimeOutputUnits.
cropMgr = CropManager.getInstance();
cropName = handles.cropsList{cropIndex};
regimeUnits = cropMgr.getCropsRegimeUnits(cropName);
% Have to select the first cell of regimeUnits. cropManager can take in a
% list of cropNames and returns a cell arraty of regimeUnits accordingly.
% We want the first one.
regimeUnits = regimeUnits{1};
BTUs = {regimeUnits.readableDenominatorUnit};
set(handles.biomassThresholdUnitsDDL, 'String', BTUs);

%BTUs = get(handles.biomassThresholdUnitsDDL, 'String');
btuIX = find(strcmp(handles.biomassThresholdUnit, BTUs));
if isempty(btuIX)
  btuIX = 1;
end
set(handles.biomassThresholdUnitsDDL, 'Value', btuIX);
handles.regimeUnits = regimeUnits;
handles.biomassThresholdUnit = BTUs{btuIX};

if handles.biomassThreshold > 0
    set(handles.biomassThresholdEdit, 'String', num2str(handles.biomassThreshold));
else
    set(handles.biomassThresholdEdit, 'String', '');
end

% Set to choice 1 by default.
handles.coppiceTriggerChoice = 'coppiceChoice1';

% In case some saved files have old coppiceTriggerChoices, this will save
% them from crashing.
switch handles.coppiceTriggerChoice
    
    case 'Harvest years and month'
        handles.coppiceTriggerChoice = 'coppiceChoice1';

    case 'Biomass threshold'
        handles.coppiceTriggerChoice = 'coppiceChoice2';
        
    case 'Custom Trigger'
        handles.coppiceTriggerChoice = 'coppiceChoice3';        
end

% Figure out the coppiceTriggerChoice based on the conditions for the
% Coppice Harvesting event.

cropEventTriggers = handles.cropEventTriggers;
if ~isempty(cropEventTriggers) && ~isempty(handles.crop)
    % Find the crop.
    cix = find(strcmp(handles.crop, {cropEventTriggers.cropName}), 1, 'first');
    if ~isempty(cix)
        cet = cropEventTriggers(cix);
        eix = find(strcmp('Coppice Harvesting', {cet.eventTriggers.name}), 1, 'first');
        if ~isempty(eix)
            et = cet.eventTriggers(eix);
 
            if (et.regimeRedefined)
                handles.coppiceTriggerChoice = 'coppiceChoice3';        
            else
                % If it is we need to select the last radio button that was
                % used.
                % We can check the condition list. If the month index
                % choice was made, the conditions will start with a XXX
                % If the quantity based choice was made the condtion
                % will have the 'Quantity Based' type.
                conditions = et.trigger.conditions;
                switch conditions{1}.conditionType

                    case 'Month Based'
                        handles.coppiceTriggerChoice = 'coppiceChoice1';
                    case 'Quantity Based'
                        handles.coppiceTriggerChoice = 'coppiceChoice2';
                end
            end
            
        end
    end
end    

disp(handles.coppiceTriggerChoice)
           
% This small line of code should be enough to set the coppice choice. Don't
% quite know what was going on with the commented code just below.
if ~isempty(handles.coppiceTriggerChoice)
   set(handles.(handles.coppiceTriggerChoice), 'Value', 1); 
end

% i = 1;
% while 1
%     
%     if isfield(handles, ['coppiceChoice', num2str(i)])
%         radio = getfield(handles, ['coppiceChoice', num2str(i)]);
% %        radio = handles(['coppiceChoice', num2str(i)]);
%         str = get(radio, 'String');
%         
%         if strcmp(str, handles.coppiceTriggerChoice )
%             set(radio, 'Value', get(radio, 'Max'));            
%             break;
%         end
%     else
%         break;
%     end
%     i = i + 1;
% end
handles.regimeUnits
guidata(handles.biomassThresholdUnitsDDL, handles);

% This function calculates the number of belts and the belt spacing.
% If basedOn is beltNum then a spacing is immediately calculated.
% If basedOn is beltSpacing then the given spacing is used to calculate the
% best number of belts, and then the spacing is recalculated.
function updateBeltSpacing(handles, basedOn)


paddockWidth = handles.imagineParameters.paddockWidth;

if strcmp(basedOn, 'beltSpacing')
   
    beltSpacing = str2double(get(handles.beltSpacingEdit, 'String'));
    if(isnan(beltSpacing) || beltSpacing <= 0)
       set(handles.beltSpacingEdit, 'String', num2str(handles.beltSpacing, '%3.2f')); 
       return
    end
    
    beltNum = round(paddockWidth / beltSpacing) - 1;
    if(beltNum <= 0)
        beltNum = 1;
    end
    
    if(beltNum >= 50)
        beltNum = 50;
    end
    
elseif strcmp(basedOn, 'beltNum')
   
    beltNum = get(handles.beltNumDDL, 'Value');    
    
end

beltSpacing = paddockWidth / (beltNum + 1);

set(handles.beltNumDDL, 'Value', beltNum);
set(handles.beltSpacingEdit, 'String', num2str(beltSpacing, '%3.2f'));

handles.beltSpacing = beltSpacing;
handles.beltNum = beltNum;
guidata(handles.beltNumDDL, handles);

updatePaddockSummary(handles);


% Updates the beltwidth based on the factors that go into it.
function updateBeltWidth(handles)

% If the controls say something illegible, reset to the saved values.
rowSpacing = str2double(get(handles.rowSpacingEdit, 'String'));
exclusionZone = str2double(get(handles.exclusionZoneEdit, 'String'));
rowsPerBelt = get(handles.rowsPerBeltDDL, 'Value');

if~(isnan(rowSpacing) || isnan(exclusionZone) || isnan(rowsPerBelt))
    
    if(rowSpacing < 1)
        rowSpacing = 1;
    elseif(rowSpacing > 20)
        rowSpacing = 20;
    end 
    
    if(exclusionZone < 0)
        exclusionZone = 0;
    elseif(exclusionZone > 10)
        exclusionZone = 10;
    end 
    
    % Then they are fine and update the handles parameters with new values.
    handles.rowSpacing = rowSpacing;
    handles.exclusionZone = exclusionZone;
    handles.rowsPerBelt = rowsPerBelt;   
    handles.beltWidth = rowSpacing * (rowsPerBelt - 1) + 2 * exclusionZone;
    set(handles.beltWidthLabel, 'String', num2str(handles.beltWidth, 2));
    guidata(handles.rowsPerBeltDDL, handles);    
end

% Now set the controls to have the saved values. Reverts if there were bad
% values.
set(handles.rowSpacingEdit, 'String', num2str(handles.rowSpacing, 2));
set(handles.exclusionZoneEdit, 'String', num2str(handles.exclusionZone, 2));    
set(handles.rowsPerBeltDDL, 'Value', handles.rowsPerBelt);    

updatePaddockSummary(handles);


% Returns the regime in the global regimeData
% 
function returnRegime(handles)

% Should really check that the regime is valid before we send it back...

% Assuming that its ok...

rd.regimeLabel = get(handles.regimeLabelEdit, 'String');
rd.startYear = get(handles.startYearDDL, 'Value');
rd.finalYear = get(handles.finalYearDDL, 'Value');
rd.timelineColour = get(handles.timelineColourPanel, 'BackgroundColor');
rd.type = 'Belt';
rd.parameters.useBelts = get(handles.useBeltsCB, 'Value');
rd.parameters.useBorders = get(handles.useBordersCB, 'Value');
rd.parameters.crop = handles.cropsList{get(handles.cropDDL, 'Value')};
rd.parameters.harvestYears = handles.harvestYears;
rd.parameters.plantingMonth = handles.months{get(handles.plantMonthDDL, 'Value')};
rd.parameters.harvestMonth = handles.months{get(handles.harvestMonthDDL, 'Value')};
rd.parameters.rowsPerBelt = handles.rowsPerBelt;
rd.parameters.rowSpacing = handles.rowSpacing;
rd.parameters.exclusionZone = handles.exclusionZone;
rd.parameters.plantSpacing = handles.plantSpacing;
rd.parameters.headland = handles.headland;
rd.parameters.beltNum = handles.beltNum;
rd.parameters.biomassThreshold = handles.biomassThreshold;
rd.parameters.biomassThresholdUnit = handles.biomassThresholdUnit;
rd.parameters.coppiceTriggerChoice = handles.coppiceTriggerChoice;

rd.listOfCropNames = {rd.parameters.crop};

if isfield(handles, 'coppiceTriggerChoice')
    rd.parameters.coppiceTriggerChoice = handles.coppiceTriggerChoice;
end

if isfield(handles, 'customCoppiceConditions')
    rd.parameters.customCoppiceConditions = handles.customCoppiceConditions;
end

rd.parameters.gapLengthAtCorners = str2double(get(handles.gapLengthAtCornersEdit, 'String'));

problems = 0;
mstring = {};

if(rd.startYear > rd.finalYear)
    problems = problems + 1;
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''re trying to set the final year to be earlier than the start year.'}];
           
elseif(any(any(handles.regimeYears >= rd.startYear & handles.regimeYears <= rd.finalYear)))

    problems = problems + 1;
    
    % Then the years overlap.
    
    % Get strings for the existing years
    rangeStrings = {};
    for i = 1:size(handles.regimeYears, 2)
       rangeStrings{i} = [num2str(handles.regimeYears(1, i)), ' - ', num2str(handles.regimeYears(2, i))];
    end
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''ve selected a range of years that overlap existing regimes.', '', ...
               'Your range is ', '', [num2str(rd.startYear), ' - ', num2str(rd.finalYear), '.'], '', ...
               'The existing regimes range over the following years:', '', ...
               char(rangeStrings), ...
               '', 'Please select a range that doesn''t conflict with these years.'}];
end

if(~(rd.parameters.useBelts || rd.parameters.useBorders))
    problems = problems + 1;
 
    if(problems > 1)
       mstring = [mstring, {'', ''}];
    end
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You need to select either belts or borders or both.', ''}];
end

if(any(strcmp(handles.existingRegimeLabels, rd.regimeLabel)))
    problems = problems + 1;
    
    if(problems > 1)
       mstring = [mstring, {'', ''}];
    end
    
    mstring = [mstring, {['Problem', num2str(problems), ':'], ...
               'You''ve chosen a regime label that already exists. Please choose a label that is different to all in the list below:', '', ...
               char(handles.existingRegimeLabels)}];
end

if(problems > 0)
    warndlg(mstring, 'Problems with Regime');
    return
end

createBeltRegimeEvents(handles);
handles = guidata(handles.defineTriggersButton);
rd.cropEventTriggers = handles.cropEventTriggers;

assignin('base', 'rd', rd);

handles.output = rd;
guidata(handles.figure1, handles);
uiresume(gcf);



function gapLengthAtCornersEdit_Callback(hObject, eventdata, handles)
% hObject    handle to gapLengthAtCornersEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gapLengthAtCornersEdit as text
%        str2double(get(hObject,'String')) returns contents of gapLengthAtCornersEdit as a double
gapLength = str2double(get(hObject, 'String'));

if(~isnan(gapLength))   

    if(gapLength < 10)
        gapLength = 10;
    elseif(gapLength > 100)
        gapLength = 100;
    end

end

set(hObject, 'String', num2str(gapLength, '%3.2f'));
handles.gapLengthAtCorners = gapLength;
guidata(hObject, handles);

updatePaddockSummary(handles);


% --- Executes during object creation, after setting all properties.
function gapLengthAtCornersEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gapLengthAtCornersEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useBordersCB.
function useBordersCB_Callback(hObject, eventdata, handles)
% hObject    handle to useBordersCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useBordersCB

handles.useBorders = get(hObject, 'Value');
enableControls(handles.useBorders, handles.borderControlsList);
guidata(hObject, handles);
updatePaddockSummary(handles);


% --- Executes on button press in useBeltsCB.
function useBeltsCB_Callback(hObject, eventdata, handles)
% hObject    handle to useBeltsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useBeltsCB
handles.useBelts = get(hObject, 'Value');
enableControls(handles.useBelts, handles.beltControlsList);
guidata(hObject, handles);
updatePaddockSummary(handles);


% Enables or disables the given controls for borders based on input
%
%
function enableControls(enable, controlHandles)

if(enable)
   eString = 'on'; 
else
    eString = 'off';
end

for i = 1:length(controlHandles)
    set(controlHandles(i), 'Enable', eString); 
end


% Updates the visual representation in the two axes.
function updatePaddockSummary(handles)

% First update the summary view.

beltS.useBelts = handles.useBelts;
beltS.useBorders = handles.useBorders;

if(handles.useBelts || handles.useBorders)
    beltS.exclusionZone = handles.exclusionZone;
    beltS.rowsPerBelt = handles.rowsPerBelt;
    beltS.rowSpacing = handles.rowSpacing;
    beltS.beltColour = handles.cropColours{get(handles.cropDDL, 'Value')};
end

if(handles.useBelts)
    beltS.headland = handles.headland;
    beltS.beltNum = handles.beltNum;
end

if(handles.useBorders)
    beltS.gapLengthAtCorners = handles.gapLengthAtCorners;
end

% Draw the belts on a white background. (Perhaps cross hatching would
% indicate that it is not relevant? Or not defined?
drawPaddockSummaryOnAxes(handles.axes1, [1 1 1], handles.imagineParameters, beltS)


% --- Executes on button press in defineTriggersButton.
function defineTriggersButton_Callback(hObject, eventdata, handles)
% hObject    handle to defineTriggersButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Pass the trigger dialog the cropEventTriggers structure which should
% contain exactly the information that the trigger dialog needs and
% affects.
createBeltRegimeEvents(handles);
handles = guidata(hObject);

cropEventTriggers = handles.cropEventTriggers;

% In order for the trigger dialog to work with the trigger panel, we'll
% convert the RegimeEventTriggers into Events and pass them across.
cropMgr = CropManager.getInstance;

%disp(['Making cropEvents for regime trigger dialog... ']);

for i = 1:length(cropEventTriggers)
    cropEvents = cropMgr.getCropsEvents(cropEventTriggers(i).cropName);
    newCropEvents(i).cropName = handles.cropEventTriggers.cropName; %#ok<AGROW>
    
%    disp(['Crop name: ', newCropEvents(i).cropName]);
%    assignin('base', 'cropEvents', cropEvents);
%    assignin('base', 'cropEventTriggers', cropEventTriggers);
    for j = 1:length(cropEvents)
        status = cropEvents(j).status;
        newCropEvents(i).events(j) = cropEventTriggers(i).eventTriggers(j).convertToEvent(status); %#ok<AGROW>
%        disp(['   Event name: ', newCropEvents(i).events(j).name]);
                           
%        for k = 1:length(cropEventTriggers(i).eventTriggers(j).trigger.conditions)
%            disp(['      Condition: ', newCropEvents(i).events(j).trigger.conditions(k).shorthand, ', type: ', newCropEvents(i).events(j).trigger.conditions(k).conditionType]);
%        end
    end
end
%assignin('base', 'newCropEvents1', newCropEvents);
%rr = newCropEvents.events(2).status.regimeRedefined;
%uiwait(msgbox(['Coppice redefined before? ', num2str(rr)]));
newCropEvents = triggerDialog(newCropEvents);
%if ~isempty(newCropEvents)
%    rr = newCropEvents.events(2).status.regimeRedefined;
%    uiwait(msgbox(['Coppice redefined after? ', num2str(rr)]));
%end
%assignin('base', 'newCropEvents2', newCropEvents);

% We want to check for the custom coppice trigger. If we chose to go into
% the trigger dialog to set the custom coppice trigger, we could have
% chosen to 'revert' in which case the previous trigger would have been
% shown. If that is what happened, then we want to show this in the dialog
% by not having the custom radio button selected.
% Therefore we will make the check and necessary adjustments below when we
% find the Coppice Harvesting event.

if isempty(newCropEvents)
    return
else
%    disp('Saving regime cropEventTriggers');
    
    for i = 1:length(newCropEvents)
       % The crop names should match..
       if ~strcmp(newCropEvents(i).cropName, cropEventTriggers(i).cropName) 
           error('We got back a cropEvents struct that doesn''t match what we sent.');
       end
       
%       disp(['Crop name: ', newCropEvents(i).cropName]);
       
       % Assuming the crops match, retrieve the regime trigger data.
       for j = 1:length(newCropEvents(i).events)
           cropEventTriggers(i).eventTriggers(j) = cropEventTriggers(i).eventTriggers(j).convertFromEvent(newCropEvents(i).events(j));
%           disp(['   Event name: ', cropEventTriggers(i).eventTriggers(j).eventName]);
           
%           for k = 1:length(cropEventTriggers(i).eventTriggers(j).trigger.conditions)
%                disp(['      Condition: ', cropEventTriggers(i).eventTriggers(j).trigger.conditions(k).shorthand, ', type: ', cropEventTriggers(i).eventTriggers(j).trigger.conditions(k).conditionType]);
%           end
           
           if strcmp(cropEventTriggers(i).eventTriggers(j).name, 'Coppice Harvesting')
                % Then we need to check if it's reverted, and if it's
                % selected in the radio button.
                if (cropEventTriggers(i).eventTriggers(j).regimeRedefined)
                    set(handles.coppiceChoice3, 'Value', 1);
                    handles.coppiceTriggerChoice = 'coppiceChoice3';
                else
                    % If it is we need to select the last radio button that was
                    % used.
                    % We can check the condition list. If the month index
                    % choice was made, the conditions will start with a XXX
                    % If the quantity based choice was made the condtion
                    % will have the 'Quantity Based' type.
                    conditions = cropEventTriggers(i).eventTriggers(j).trigger.conditions;
                    switch conditions(1).conditionType
                        
                        case 'Month Based'
                            set(handles.coppiceChoice1, 'Value', 1);
                            handles.coppiceTriggerChoice = 'coppiceChoice1';
                        case 'Quantity Based'
                            set(handles.coppiceChoice2, 'Value', 1);
                            handles.coppiceTriggerChoice = 'coppiceChoice2';
                    end
                end               
           end
       end
    end
    
    handles.cropEventTriggers = cropEventTriggers;
end
%assignin('base', 'cets', cropEventTriggers);
guidata(hObject, handles);





% createBeltRegimeEvents
%
% makes the cropEvents list contain entries for the core events in the
% crop. Sets planting and harvesting events for all crops used.
function createBeltRegimeEvents(handles)

beltCropNames = get(handles.cropDDL, 'String');
cropName = beltCropNames{get(handles.cropDDL, 'Value')};
%crop = handles.crops(strcmp({handles.crops.name}, cropName));
startYear = get(handles.startYearDDL, 'Value');
finalYear = get(handles.finalYearDDL, 'Value');
plantMonth = handles.months{get(handles.plantMonthDDL, 'Value')};
harvestMonth = handles.months{get(handles.harvestMonthDDL, 'Value')};

    % Make sure that cropEventTriggers has an element for our crop.
    % Get it's index in the array and make it cropIndex.
    % Hereafter we can assume handles.cropEventTriggers(cropIndex) will
    % give us the struct with cropName and an array of eventTriggers in it.
    
    if isempty(handles.cropEventTriggers)
        cropIndex = [];
    else
        cropIndex = find(strcmp({handles.cropEventTriggers.cropName}, cropName));
    end
    
    if isempty(cropIndex)
        % If we don't yet have events for the crop, we should load them
        % from the crop.
        % But what if the crop changes? Perhaps we should load the events from the crop here every time
        % but overwrite the crop's event with the regimes event data if it exists, and then, only some fields. 
        % It should definitely be the crop's growthmodel events and
        % financial events that are used, not the category's events.
         
        % add the events for the crop by accessing the cropManager.
        
        cet.cropName = cropName;
        cropMgr = CropManager.getInstance;
        cropEvents = cropMgr.getCropsEvents(cropName);
        
        assignin('base', 'gottenCropEvents', cropEvents);
        
        % create the eventTriggers, a struct array with eventName, trigger.
        for k = 1:length(cropEvents)
            ets(k) = RegimeEventTrigger(cropEvents(k).name, cropEvents(k).trigger, cropEvents(k).status.regimeRedefinable); %#ok<AGROW>
            dET = ets(k);
        end
        cet.eventTriggers = ets;
        cropIndex = length(handles.cropEventTriggers)+1;
       
        handles.cropEventTriggers(cropIndex) = cet;
        
        disp('New cropEventTrigger...');
        
    end



% Need to define planting, coppice harvesting and destructive harvesting.

% Planting:

        c1 = ImagineCondition.newCondition('Month Based', ['Month is ', plantMonth]);
        ix = find(strcmp(c1.monthStrings, plantMonth));
        c1.monthIndex = ix;
        
%         c1.string1 = '';
%         c1.value1 = 1;
%         c1.stringComp = 'Month is';
%         c1.valueComp = 1;
%         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%         c1.value2 = get(handles.plantMonthDDL, 'Value');
%         c1.parameters1String = '';
%         c1.parameters2String = '';
        
        c2 = ImagineCondition.newCondition('Time Index Based', 'Is first year');
        c2.indexType = 'Year';
        c2.indices = startYear;
        
%         c2.string1 = {'Year', 'Month'};
%         c2.value1 = 1;
%         c2.stringComp = {'=', '<', '>', '<=', '>='};
%         c2.valueComp = 1;
%         c2.string2 = num2str(startYear);
%         c2.value2 = 1;       
%         c2.parameters1String = '';
%         c2.parameters2String = '';

        c3 = ImagineCondition.newCondition('And / Or / Not', 'C1 AND C2');
        c3.logicType = 'And';
        c3.indices = [1 2];
        
%         c3.string1 = {'AND', 'OR', 'NOT'};
%         c3.value1 = 1;
%         c3.stringComp = '';
%         c3.valueComp = 1;
%         c3.string2 = '1 2';
%         c3.value2 = 1;       
%         c3.parameters1String = '';
%         c3.parameters2String = '';
        
        plantConditions = {c1 c2 c3};
        
    
    
        
        
% Coppice Harvesting:    
    coppiceChoice = '';
if isfield(handles, 'coppiceTriggerChoice')
    coppiceChoice = handles.coppiceTriggerChoice;
end

% red is a flag for setting the redefined flag of the trigger. Custom
% trigger sets it true. Below the switch, where the conditions are set, we
% set the redefined flag. Only for this event.
red = 0;

switch coppiceChoice
    
    % 'Harvest years and month'
    case 'coppiceChoice1'

        c1 = ImagineCondition.newCondition('Month Based', ['Month is ', harvestMonth]);
        ix = find(strcmp(c1.monthStrings, harvestMonth));
        c1.monthIndex = ix;

%         c1.string1 = '';
%         c1.value1 = 1;
%         c1.stringComp = 'Month is';
%         c1.valueComp = 1;
%         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%         c1.value2 = get(handles.harvestMonthDDL, 'Value');
%         c1.parameters1String = '';
%         c1.parameters2String = '';
        
        c2 = ImagineCondition.newCondition('Time Index Based', 'Harvest years');
        c2.indexType = 'Year';
        c2.indices = str2num(get(handles.harvestYearsEdit, 'String'));
        
%         c2.string1 = {'Year', 'Month'};
%         c2.value1 = 1;
%         c2.stringComp = {'=', '<', '>', '<=', '>='};
%         c2.valueComp = 1;
%         c2.string2 = get(handles.harvestYearsEdit, 'String');
%         c2.value2 = 1;       
%         c2.parameters1String = '';
%         c2.parameters2String = '';

        c3 = ImagineCondition.newCondition('And / Or / Not', 'C1 AND C2');
        c3.logicType = 'And';
        c3.indices = [1 2];

%         c3.string1 = {'AND', 'OR', 'NOT'};
%         c3.value1 = 1;
%         c3.stringComp = '';
%         c3.valueComp = 1;
%         c3.string2 = '1 2';
%         c3.value2 = 1;       
%         c3.parameters1String = '';
%         c3.parameters2String = '';

        harvestConditions = {c1 c2 c3};
    
    % 'Biomass threshold'
    case 'coppiceChoice2'
        
        % Need to use the biomassThresholdUnit and the rest of the
        % parameters in the regime to calculate total biomass.

        % Now we have the units in the Quantity Based condition we can just
        % put in the value for threshold and the units into parameters 1,
        % along with Tonnes in parameters 2.
        
        c1 = ImagineCondition.newCondition('Quantity Based', 'AGBM > threshold');
        c1.quantityType = 'Output';
        c1.eventName = QuantityBasedCondition.nullEventName;
        c1.comparator = '>=';
        AGBMUnit = Unit('', 'Above-ground Biomass', 'Tonne');

        BTUs = {handles.regimeUnits.readableDenominatorUnit};
        ix = find(strcmp(handles.biomassThresholdUnit, BTUs), 1, 'first');
        BTU = handles.regimeUnits(ix);

        c1.rate = Rate(handles.biomassThreshold, AGBMUnit, BTU);
                
        % Note that there is some subtlty in setting c1.string1 to a
        % single output value. The trigger panel has previously expected to be 
        % able to put the string straight into the control and set the
        % value.
        % I think it's better for forward compatability for the
        % triggerPanel to work out what the list of choices should be, then
        % select the one we've defined here. Therefore it should be fine
        % when setting the condition to list a single choice and have the
        % value = 1 (first choice).
        
%         c1.string1 = {'Above-ground Biomass'};
%         c1.value1 = 1;
%         c1.stringComp = {'=', '<', '>', '<=', '>='};
%         c1.valueComp = 5;
%         c1.string2 = num2str(handles.biomassThreshold);
%         c1.value2 = 1;       
%         c1.parameters1String = BTU.speciesName;
%         c1.parameters2String = BTU.unitName;
        
        harvestConditions = {c1};
        
        
    % 'Custom Trigger'
    case 'coppiceChoice3'
    
        % If we've selected the custom trigger, we need to set the
        % redefined flag and set the conditions
        
        % The problem with the custom trigger is what we do when we set it
        % and what we do when we set away from it. When we set it, we put
        % either a blank trigger in, the old trigger in, or whatever else
        % is in and make it editable.
        
        % When we set away from the trigger, it would be nice to go back to
        % what we had when we started, or possibly what we've got set in
        % the crop. So - a revert from redefine either gets the crops
        % trigger condition, or it gets the conditions that it had just
        % before it got set.
        
        % Should we set the custom conditions and revert conditions in the
        % trigger to empty from the start? (One blank never condition).
        
        % Another problem is if when we go into the trigger dialog and
        % redefine the triggers for coppice, we'd like when we get back to
        % the belt dialog for the custom trigger radio to be selected.
        
        % This could be fairly easy to check. After the uiwait in the
        % callback for the define triggers button, we check the redefine
        % flag for the coppice trigger, and if set we select the custom
        % trigger.
        % If redefine is not set, then what do we do? Well, on the revert
        % in the trigger dialog, we'll have loaded the conditions that were
        % saved. Do we always have to have a condition list to revert to?
        % No. We might not have put in any parameters for biomass for
        % example. We do not have to provide years for harvesting.
        
        % Ok - the solution is to have no revert option for redefined.
        % If we want to set custom conditions, we set custom, then go to
        % define triggers and we will have access to the conditons. We
        % cannot revert in that dialog.
        
        % When we come back to the belt regime dialog, we can change from
        % custom back to the biomass or harvest years defn.
        
        % So - do not show revert or redefine button for locked and defered
        % It would be like the redefined option would make locked and
        % defered act like unlocked and defered. Ie, trigger must be set.
        
        % So - this code here should set the redefined flag. The other
        % sections should also set it - to zero. It can also populate it
        % with either an empty condition, or the coppice custom conditon,
        % which could be part of the regime parameters.
        
        % Now, why would coppiceCustomConditions exist? Because when we
        % return from the redefine triggers button, we check if we have a
        % custom trigger for coppice. If we do, then we set the regime's
        % coppiceCustomConditions to the coppice event's conditions.
        
        red = 1;
        
        if isfield(handles, 'customCoppiceConditions')
            harvestConditions = handles.customCoppiceConditions;
        else
%            harvestConditions = emptyCondition('Custom Condition 1');
             harvestConditions = ImagineCondition.newCondition('Never', 'Custom Condition 1');
        end
            
    otherwise
        % Do the harvest years.
        
        c1 = ImagineCondition.newCondition('Month Based', ['Month is ', harvestMonth]);
        ix = find(strcmp(c1.monthStrings, harvestMonth));
        c1.monthIndex = ix;

%         c1.string1 = '';
%         c1.value1 = 1;
%         c1.stringComp = 'Month is';
%         c1.valueComp = 1;
%         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%         c1.value2 = get(handles.harvestMonthDDL, 'Value');
%         c1.parameters1String = '';
%         c1.parameters2String = '';
        
        c2 = ImagineCondition.newCondition('Time Index Based', 'Harvest years');
        c2.indexType = 'Year';
        c2.indices = str2num(get(handles.harvestYearsEdit, 'String'));
        
%         c2.string1 = {'Year', 'Month'};
%         c2.value1 = 1;
%         c2.stringComp = {'=', '<', '>', '<=', '>='};
%         c2.valueComp = 1;
%         c2.string2 = get(handles.harvestYearsEdit, 'String');
%         c2.value2 = 1;       
%         c2.parameters1String = '';
%         c2.parameters2String = '';
        
        c3 = ImagineCondition.newCondition('And / Or / Not', 'C1 AND C2');
        c3.logicType = 'And';
        c3.indices = [1 2];

%         c3.string1 = {'AND', 'OR', 'NOT'};
%         c3.value1 = 1;
%         c3.stringComp = '';
%         c3.valueComp = 1;
%         c3.string2 = '1 2';
%         c3.value2 = 1;       
%         c3.parameters1String = '';
%         c3.parameters2String = '';

        harvestConditions = [c1 c2 c3];
        
end
        
 
     % Destructive Harvesting:    
        c1 = ImagineCondition.newCondition('Month Based', ['Month is ', harvestMonth]);
        ix = find(strcmp(c1.monthStrings, harvestMonth));
        c1.monthIndex = ix;

%         c1.string1 = '';
%         c1.value1 = 1;
%         c1.stringComp = 'Month is';
%         c1.valueComp = 1;
%         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%         c1.value2 = get(handles.harvestMonthDDL, 'Value');
%         c1.parameters1String = '';
%         c1.parameters2String = '';
        
        c2 = ImagineCondition.newCondition('Time Index Based', 'Last regime year');
        c2.indexType = 'Year';
        c2.indices = finalYear;
        
%         c2.string1 = {'Year', 'Month'};
%         c2.value1 = 1;
%         c2.stringComp = {'=', '<', '>', '<=', '>='};
%         c2.valueComp = 1;
%         c2.string2 = num2str(finalYear);
%         c2.value2 = 1;       
%         c2.parameters1String = '';
%         c2.parameters2String = '';
        
        c3 = ImagineCondition.newCondition('And / Or / Not', 'C1 AND C2');
        c3.logicType = 'And';
        c3.indices = [1 2];

%         c3.string1 = {'AND', 'OR', 'NOT'};
%         c3.value1 = 1;
%         c3.stringComp = '';
%         c3.valueComp = 1;
%         c3.string2 = '1 2';
%         c3.value2 = 1;       
%         c3.parameters1String = '';
%         c3.parameters2String = '';

        destructiveConditions = {c1 c2 c3};
        
% We've made the conditions for the events.
% Now we create the Triggers and teh RegimeEventTriggers.
% Note thate the Coppice harvesting event can be redefined.

    % Planting
    plantTrigger = Trigger;
    plantTrigger.conditions = plantConditions;
    plantIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Planting'));    
    ret = handles.cropEventTriggers(cropIndex).eventTriggers(plantIx);
    ret = ret.setPrivateTrigger(plantTrigger);
    handles.cropEventTriggers(cropIndex).eventTriggers(plantIx) = ret;

    % Coppice Harvesting
    harvestTrigger = Trigger;
    harvestTrigger.conditions = harvestConditions;
    harvestIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Coppice Harvesting'));
    ret = handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx);
    
    % This is a long way of saying it, but I want to highlight the
    % redefined flag that needs to be set for this event. Is set to 1 if
    % we have a custom trigger.
    if (red)
        ret.regimeRedefined = 0;
        trig = ret.trigger;
        ret.regimeRedefined = 1;
        retrig = ret.trigger;
        if isempty(retrig)
            % If we've never had a redefined trigger before,
            % then set it to the default. Lets use what is in the trigger.
            % If that is empty too, we'll use the nothing trigger.
            if isempty(trig)
                ret = ret.setPrivateRedefinedTrigger(harvestTrigger);
            else
                ret = ret.setPrivateRedefinedTrigger(trig);
            end
        end    
    elseif ~isempty(ret)     % QV 19-03-2018. I don't want to have to have the Coppice Harvest and Destructive Harvesting events for a pine using Fixed Yield model.     
        ret.regimeRedefined = 0;
        ret = ret.setPrivateTrigger(harvestTrigger);    
    end
    
    handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx) = ret;

    % Destructive Harvesting
    destructiveHarvestTrigger = Trigger;
    destructiveHarvestTrigger.conditions = destructiveConditions;
    destructiveIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Destructive Harvesting'));
    ret = handles.cropEventTriggers(cropIndex).eventTriggers(destructiveIx);

    if (~isempty(ret))  % QV 19-03-2018. I don't want to have to have the Coppice Harvest and Destructive Harvesting events for a pine using Fixed Yield model.
        ret = ret.setPrivateTrigger(destructiveHarvestTrigger);
        handles.cropEventTriggers(cropIndex).eventTriggers(destructiveIx) = ret;
    end
    
guidata(handles.defineTriggersButton, handles);


% --- Executes on selection change in harvestMonthDDL.
function harvestMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to harvestMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns harvestMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from harvestMonthDDL


% --- Executes during object creation, after setting all properties.
function harvestMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harvestMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function biomassThresholdEdit_Callback(hObject, eventdata, handles)
% hObject    handle to biomassThresholdEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of biomassThresholdEdit as text
%        str2double(get(hObject,'String')) returns contents of biomassThresholdEdit as a double
biomassThreshold = str2num(get(hObject, 'String'));
if(~isnan(biomassThreshold) && length(biomassThreshold) == 1)
    handles.biomassThreshold = biomassThreshold; 
    guidata(hObject, handles);
end
set(hObject, 'String', num2str(handles.biomassThreshold));

% --- Executes during object creation, after setting all properties.
function biomassThresholdEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to biomassThresholdEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in biomassThresholdUnitsDDL.
function biomassThresholdUnitsDDL_Callback(hObject, eventdata, handles)
% hObject    handle to biomassThresholdUnitsDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns biomassThresholdUnitsDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from biomassThresholdUnitsDDL
biomassThresholdUnits = get(hObject, 'String');
biomassThresholdUnit  = biomassThresholdUnits{get(hObject, 'Value')};

handles.biomassThresholdUnit = biomassThresholdUnit; 
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function biomassThresholdUnitsDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to biomassThresholdUnitsDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel8.
function uipanel8_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel8 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set the new choice in handles.
selectedRadio = eventdata.NewValue;
ctc = get(selectedRadio, 'Tag');
handles.coppiceTriggerChoice = ctc;
guidata(hObject, handles);
