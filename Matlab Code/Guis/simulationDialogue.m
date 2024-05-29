function varargout = simulationDialogue(varargin)
% SIMULATIONDIALOGUE M-file for simulationDialogue.fig
%      SIMULATIONDIALOGUE, by itself, creates a new SIMULATIONDIALOGUE or raises the existing
%      singleton*.
%
%      H = SIMULATIONDIALOGUE returns the handle to a new SIMULATIONDIALOGUE or the handle to
%      the existing singleton*.
%
%      SIMULATIONDIALOGUE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMULATIONDIALOGUE.M with the given input arguments.
%
%      SIMULATIONDIALOGUE('Property','Value',...) creates a new SIMULATIONDIALOGUE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before simulationDialogue_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to simulationDialogue_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help simulationDialogue

% Last Modified by GUIDE v2.5 18-Feb-2014 17:15:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @simulationDialogue_OpeningFcn, ...
                   'gui_OutputFcn',  @simulationDialogue_OutputFcn, ...
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


% --- Executes just before simulationDialogue is made visible.
function simulationDialogue_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to simulationDialogue (see VARARGIN)

handles.setupComplete = false;
handles.controls = handles;

% Choose default command line output for simulationDialogue
handles.output = handles.figure1;

handles.simMgr = SimulationManager.getInstance;
%handles.simMgr.simulationWindow = handles.figure1;
handles.numberOfSims = 0;
handles.runningSim = false;

% Save the positions so I can redraw the axes.
axes1Pos = get(handles.axes1, 'Position');
axes2Pos = get(handles.axes2, 'Position');
axes2LabelPos = get(handles.axes2Label, 'Position');
figurePos =  get(handles.figure1, 'Position');

% x, y, width, height

handles.bottomMargin = axes2Pos(2);
handles.rightMargin = figurePos(3) - axes2Pos(1) - axes2Pos(3);
handles.controlPaneWidth = axes2Pos(1);
handles.axesGap = axes1Pos(2) - axes2Pos(2) - axes2Pos(4);
handles.axesTitleBottomMargin = axes2LabelPos(2) - axes2Pos(2) - axes2Pos(4);
handles.axesTitleRightMargin = figurePos(3) - axes2LabelPos(1) - axes2LabelPos(3);
handles.controlPanelInset = 7;

handles.minFigureHeight = 680;
handles.minFigureWidth = 900;

handles.primaryOn = true;
handles.secondaryOn = true;
handles.shouldCombine = false;

handles.plotTypes = {'Monthly', ...
                     'Yearly', ...
                     'Cumulative'};

set(handles.popupmenuPlotType, 'String', handles.plotTypes);                  
set(handles.popupmenuPlotType, 'Value', 2);
handles.lastSavedPlotType = '';

                 
handles.unitsAvailable = [Unit('', 'Paddock', 'Unit'), Unit('', 'Area', 'Hectare')];
handles.unit = handles.unitsAvailable(2);

set(handles.checkboxCombine, 'Value', handles.shouldCombine);

set(handles.editDiscountRate, 'String', '5');
handles.discountRate = 0.05;

% Update handles structure
guidata(hObject, handles);


% Takes care of refreshPlot.
establishRegimesCropsAndPlots(handles);

handles.setupComplete = true;

% UIWAIT makes simulationDialogue wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = simulationDialogue_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function simulationNumEdit_Callback(hObject, eventdata, handles)
% hObject    handle to simulationNumEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of simulationNumEdit as text
%        str2double(get(hObject,'String')) returns contents of simulationNumEdit as a double


% --- Executes during object creation, after setting all properties.
function simulationNumEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to simulationNumEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numberOfSims = str2double(get(handles.simulationNumEdit, 'String'));

% Could pass handles.controls to simulateInMonhs so that it has access to
% the controls
handles.simMgr.simulateInMonths(numberOfSims);
refreshPlot(handles);

% function writeToExcel(handles)
% 
% if(handles.numberOfSims > 0)
% 
%     % get a path to the file to save to.
%     
%     [file, path, filt] = uiputfile('.xls', 'Save Simulations to Excel file');
%     copyfile('ImagineExcelTemplate.xls', [path, file], 'f');
%     warning off MATLAB:xlswrite:AddSheet
%     xlswrite([path, file], handles.income{1}', 'Primary Income', 'A3');
%     xlswrite([path, file], handles.income{2}', 'Belt Income', 'A3');
%     xlswrite([path, file], handles.costs{1}',  'Primary Costs', 'A3');
%     xlswrite([path, file], handles.costs{2}',  'Belt Costs', 'A3');
%     xlswrite([path, file], handles.rainfall', 'Rainfall', 'A3');
%     xlswrite([path, file], handles.sAGBM{1}', 'Starting Primary AGBM', 'A3');
%     xlswrite([path, file], handles.fAGBM{1}', 'Final Primary AGBM', 'A3');
%     xlswrite([path, file], handles.sAGBM{2}', 'Starting Belt AGBM', 'A3');
%     xlswrite([path, file], handles.fAGBM{2}', 'Final Belt AGBM', 'A3');
%     
%     xlswrite([path, file], handles.sBGBM{1}', 'Starting Primary BGBM', 'A3');
%     xlswrite([path, file], handles.fBGBM{1}', 'Final Primary BGBM', 'A3');
%     xlswrite([path, file], handles.sBGBM{2}', 'Starting Belt BGBM', 'A3');
%     xlswrite([path, file], handles.fBGBM{2}', 'Final Belt BGBM', 'A3');
%    
% end
% 
% % --- Executes on button press in saveToExcelButton.
% function saveToExcelButton_Callback(hObject, eventdata, handles)
% % hObject    handle to saveToExcelButton (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
%     writeToExcel(handles);
% 
% 
% % --- Executes on button press in cancelSimCB.
% function cancelSimCB_Callback(hObject, eventdata, handles)
% % hObject    handle to cancelSimCB (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of cancelSimCB
% 
% 
% % --- Executes on button press in saveToAccessButtom.
% function saveToAccessButtom_Callback(hObject, eventdata, handles)
% % hObject    handle to saveToAccessButtom (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% writeToAccess(handles);
% 
% 
% function writeToAccess(handles)
% 
% if(handles.numberOfSims <= 0)
%     warndlg('It looks like there is no simulation data. Have you run a simulation yet?','No simulation data');
%     return
% end
% numberOfSims = handles.numberOfSims;
%     
% % Make a backup of the DB and also get name of desired location.
%     [file, path, filt] = uiputfile('.mdb', 'Save Simulations to Access database');
%     
%     if(isequal(path, 0) || isequal(file, 0))
%         % If path or file are zero, user cancelled the export. Do nothing.
%         return
%     end
%     
%     copyfile('ImagineBackup.mdb', 'Imagine.mdb', 'f');
% 
%     conn = database('Imagine Database', '', '');
%     
% %    prompt = {'Enter experiment title', 'Enter experiment description'};
% %    dlgTitle  = 'Experiment information for database';
% %    answer = inputdlg(prompt, dlgTitle, [1; 10])
%     
% % Start progress bar.
% 
% progress = progressUI('Export Progress', 'Exporting Simulations to Access...', '');
% assignin('base', 'progress', progress);
% %sf = @progressUI('timerUpdate', );
% pTimer = timer('Period', 0.05, 'TimerFcn', {progress.timerUpdateFcn, progress}, 'ExecutionMode', 'fixedRate');
% 
% functions(progress.timerInitFcn)
% functions(progress.timerUpdateFcn)
% 
% tic
% 
%     % Get Experiment ID
%     colnames = {'Title', 'Description'};
% %    exData = [answer(1), answer(2)];
%     exData = {'abc', 'def'};
%     fastinsert(conn, 'Experiments', colnames, exData);
%     curs = exec(conn, 'select max(ExperimentID) from Experiments');
%     curs = fetch(curs);
%     experimentID = curs.Data{1};
%                       
%     MonthlyCostColNames = {'SimID', 'MonthIndex', 'CostItemID', 'Zone', 'Multiplier' , 'UnitQuantity', 'UnitCost', 'Cost'};
%     MonthlyIncomeColNames = {'SimID', 'MonthIndex', 'ProductID', 'Zone', 'Amount' , 'UnitQuantity', 'UnitPrice', 'Income'};
%     BiomassColNames = {'SimID', 'MonthIndex', 'Zone', ... 
%                            'StartingBelowGroundBM', 'FinalBelowGroundBM', ...
%                            'StartingAboveGroundBM', 'FinalAboveGroundBM', ...                                   
%                            'StartingTotalBM', 'FinalTotalBM'};
%     UnitColNames = {'SimID', 'MonthIndex', 'Zone', ...
%                     'Hectares', 'Trees', 'KmOfBelts', 'KmOfRows'};
%     RainfallColNames = {'SimID', 'MonthIndex', 'Rainfall'};
%     
%     MonthlyCostData = cell(1000, 8);
%     MonthlyIncomeData = cell(1000, 8);
%     BiomassData = cell(handles.imagineParameters.simLength * 12, 9);
%     UnitData = cell(handles.imagineParameters.simLength * 12, 7);
%     RainfallData = cell(handles.imagineParameters.simLength * 12, 3);
%     
% init = toc;
%     
%     % Found the following array to represent approximate percentage of time
%     % spent in each section:
%     testedInit = 0.0288;
%     %   = [2.8375    1.3927    5.6040    1.4324   46.5656   33.7605    8.4073]
%     testTimes = [0.3848    0.1889    0.7599    0.1942    6.3141    4.5778    1.1400]; % time distribution on development computer
%     
%           
%     % For each Sim   
%     for i = 1:length(handles.simulations)
%        
%     tic
%         % Update progress bar to show sim num  
%         expectedTimes = init / testedInit * testTimes;
% %         if i == 1
% %             expectedTimes = init / testedInit * testTimes;
% %         else
% %             
% %             expectedTimes = mean([simCrops', simRecords', simInsert]);
% %         end
%         
%         componentNumber = 1;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%         tte = ceil(expectedTime / 0.05)
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         % Get simulation ID
%         colnames = {'ExperimentID'};
%         exData = experimentID;
%         fastinsert(conn, 'Sims', colnames, exData);
%         
%         curs = exec(conn, 'select max(SimID) from Sims');
%         curs = fetch(curs);    
%         simID = curs.Data{1};
%                   
%         % Add all the crops
%         for j = 1:length(handles.crops)
%             crop = handles.crops(j);
%                         
%             colnames = {'CropName', 'CropCategory'};
%             exData = {crop.name, crop.category};
%             fastinsert(conn, 'Crop', colnames, exData);            
%             
%             curs = exec(conn, 'select max(CropID) from Crop');
%             curs = fetch(curs);
%             cropID = curs.Data{1};
%             
%             handles.crops(j).cropID = cropID;
% 
%             
%             % Add the Costs
%             for k = 1:length(crop.costItems)
%                 cI = crop.costItems(k);
%                 
%                 colnames = {'CropID', 'CostItemName', 'CostItemUnitType'};
%                 exData = {cropID, cI.name, cI.unitType};
%                 fastinsert(conn, 'CostItem', colnames, exData);                  
%                 curs = exec(conn, 'select max(CostItemID) from CostItem');
%                 curs = fetch(curs);
%                 cIID = curs.Data{1};
%                 handles.crops(j).costItems(k).costItemID = cIID;
%             end
%             % Add the Products
%             for k = 1:length(crop.products)
%                 p = crop.products(k);
%                 
%                 if(strcmp(crop.category, 'Tree'))
%                     p.unitType = 'per Tree';
%                 else
%                     p.unitType = 'per Hectare';
%                 end
%                     
%                 colnames = {'CropID', 'ProductName', 'ProductUnitType'};
%                 exData = {cropID, p.name, p.unitType};
%                 fastinsert(conn, 'Product', colnames, exData);       
%                 
%                 curs = exec(conn, 'select max(ProductID) from Product');
%                 curs = fetch(curs);
%                 pID = curs.Data{1};
%                 handles.crops(j).products(k).productID = curs.Data{1};
%             end
%                         
%         end
%            
%         simCrops(i) = toc;
%         tic
%         
%         componentNumber = 2;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         monthlyCostIndex = 1;
%         monthlyIncomeIndex = 1;
%         
%         simData = handles.simulations(i);
%         
%         % Add the monthly data for costs, income, rainfall, biomass
%         for year = 1:handles.imagineParameters.simLength
% 
%            
%             
%            for month = 1:12
% 
%               for zone = 1:2
% %                  simData = handles.simulations((year - 1)* 12 + month);
%                   record = simData.records{zone}(year, month); %handles.simulations{i, zone}(year, month);                  
%                   crop = handles.crops(strcmp({handles.crops.name}, record.cropName));
%                   
%                 % add costMultipliers to keep it happy               
%                 record.costMultipliers = ones(1, length(record.costs));
%     
%                 if ~isempty(crop)
%                 
%                 %  Add the costs if there were any
% %                   for j = 1:length(record.costs)
% %                        if((record.costMultipliers(j) > 0) && (record.costUnitQuantities(j) > 0))
% %                             cIIDs = [crop.costItems.costItemID];
% %                             MonthlyCostData(monthlyCostIndex,:) = {simID, ((year - 1)*12 + month), cIIDs(j), zone, ...
% %                                 record.costMultipliers(j), record.costUnitQuantities(j), record.costPrices(j), ...
% %                                 record.costMultipliers(j)* record.costUnitQuantities(j)* record.costPrices(j)};  
% %                             monthlyCostIndex = monthlyCostIndex + 1;
% %                        end
% %                   end
% 
%                   for j = 1:length(record.costs)
%                        if record.costUnitQuantities(j) > 0
%                             cIIDs = [crop.costItems.costItemID];
%                             MonthlyCostData(monthlyCostIndex,:) = {simID, ((year - 1)*12 + month), cIIDs(j), zone, ...
%                                 1, record.costUnitQuantities(j), record.costPrices(j), ...
%                                 record.costUnitQuantities(j)* record.costPrices(j)};  
%                             monthlyCostIndex = monthlyCostIndex + 1;
%                        end
%                   end
% 
% 
%                   %  Add the products if there were any
%                   for j = 1:length(record.productAmounts)
%                        if((record.productAmounts(j) > 0) && (record.productUnitQuantities(j) > 0))
%                             pIDs = [crop.products.productID];
%                             MonthlyIncomeData(monthlyIncomeIndex,:) = {simID, ((year - 1)*12 + month), pIDs(j), zone, ...
%                                 record.productAmounts(j), record.productUnitQuantities(j), record.productPrices(j), ...
%                                 record.productAmounts(j)* record.productUnitQuantities(j)* record.productPrices(j)}; 
%                             monthlyIncomeIndex = monthlyIncomeIndex + 1;
%                         end
%                   end
% 
%                 end
%                 
%                   
%                   %  Add the biomass data             
%                    BiomassData(((year-1)*12+month -1)*2 + zone,:) = {simID, ((year - 1)*12 + month), zone, ...
%                         record.startBGBM, record.finalBGBM, ...
%                         record.startAGBM, record.finalAGBM, ...                                
%                         record.startBGBM + record.startAGBM, record.finalBGBM + record.finalAGBM};
%               
%                   % Add the unit quantity data
%                   UnitData(((year-1)*12+month -1)*2 + zone,:) = {simID, ((year - 1)*12 + month), zone, ...
%                         record.hectares, record.trees, ...
%                         record.kmOfBelts, record.kmOfRows};
%              
%               end
% 
%                 
%               %  Add the rainfall data for each month (not each zone).
%               RainfallData(((year-1)*12+month),:) = {simID, ((year - 1)*12 + month), simData.rainData((year - 1)*12 + month)};
%             
%            end
%         end
%         
%         simRecords(i) = toc;
%         
%         % Insert data for the simuation.
% 
%         componentNumber = 3;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         tic
%         fastinsert(conn, 'MonthlyCost',    MonthlyCostColNames, MonthlyCostData(1:monthlyCostIndex-1,:));
%         simInsert(i, 1) = toc;
%         
%         componentNumber = 4;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         tic
%         fastinsert(conn, 'MonthlyIncome',   MonthlyIncomeColNames, MonthlyIncomeData(1:monthlyIncomeIndex-1,:));   
%         simInsert(i, 2) = toc;
%         
%         componentNumber = 5;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         tic
%         fastinsert(conn, 'MonthlyBiomass',  BiomassColNames, BiomassData);  
%         simInsert(i, 3) = toc;
%         
%         componentNumber = 6;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         tic
%         fastinsert(conn, 'MonthlyUnits',  UnitColNames, UnitData);  
%         simInsert(i, 4) = toc;
%         
%         componentNumber = 7;
%         startPercentageInSim = sum(expectedTimes(1:componentNumber - 1)) / sum(expectedTimes);
%         finalPercentageInSim = sum(expectedTimes(1:componentNumber)) / sum(expectedTimes);
%         startPercent = (i - 1 + startPercentageInSim) / numberOfSims; 
%         finalPercent = (i - 1 + finalPercentageInSim) / numberOfSims;
%         expectedTime = expectedTimes(componentNumber)
%        tte = ceil(expectedTime / 0.05)
%         
%         stop(pTimer)
%         set(pTimer, 'StartFcn', {progress.timerInitFcn, progress, startPercent, finalPercent, expectedTime}, 'TasksToExecute', ceil(expectedTime / 0.05)); 
%         start(pTimer);
%         
%         tic
%         fastinsert(conn, 'MonthlyRainfall', RainfallColNames, RainfallData);  
%         simInsert(i, 5) = toc;
%       
%     end
% 
%     assignin('base', 'simInsert', simInsert);
%     assignin('base', 'simRecords', simRecords);
%     assignin('base', 'simCrops', simCrops);
%     assignin('base', 'init', init);
%     
%     close(curs)
%     close(conn)
%     
%     copyfile('Imagine.mdb', [path, file], 'f');
%     %movefile('ImagineBackup.mdb', 'Imagine.mdb', 'f');
%     
%     msgbox('Completed export to Access.');
%     
        
    
% this function should plot the data from the last simulation depending
% on the plot settings in the controls of the sidebar.
function plotData(handles, plotableData, simNum)

if isfield(handles, 'plotableData') && isfield(handles, 'simNum')
    plotableData = handles.plotableData;
    simNum = handles.simNum;
else
    return
end

if size(plotableData, 2) == 0 || simNum == 0
    return
end

% primIncomePerMonth = zeros(handles.numberOfSims, 600);
% beltIncomePerMonth = primIncomePerMonth;
% primCostsPerMonth = primIncomePerMonth;
% beltCostsPerMonth = primIncomePerMonth;

% primBGBM = zeros(handles.numberOfSims, 1200);
% beltBGBM = primBGBM;
% primAGBM = primBGBM;
% beltAGBM = primBGBM;
% 
% for simNum = 1:handles.numberOfSims
% 
%         %totalIncomePerMonth{simNum} = cumsum(sum([handles.income{1}(simNum, :); handles.income{2}(simNum, :)]));
%         %totalCostsPerMonth{simNum} = cumsum(sum([handles.costs{1}(simNum, :); handles.costs{2}(simNum, :)]));
%         
%         % Set up the four fundamental plot elements: Income, cost, AGBM,
%         % BGBM.
%         primIncomePerMonth(simNum, :) = handles.zoneIncomePerMonth{1}(simNum, :);
%         beltIncomePerMonth(simNum, :) = handles.zoneIncomePerMonth{2}(simNum, :);        
%         
%         primCostsPerMonth(simNum, :) = handles.zoneCostsPerMonth{1}(simNum, :);
%         beltCostsPerMonth(simNum, :) = handles.zoneCostsPerMonth{2}(simNum, :);        
%         
%         primBGBM(simNum, :) = reshape([handles.sBGBM{1}(simNum, :); handles.fBGBM{1}(simNum, :)], 1, 1200);
%         beltBGBM(simNum, :) = reshape([handles.sBGBM{2}(simNum, :); handles.fBGBM{2}(simNum, :)], 1, 1200);
%         
%         primAGBM(simNum, :) = reshape([handles.sAGBM{1}(simNum, :); handles.fAGBM{1}(simNum, :)], 1, 1200);
%         beltAGBM(simNum, :) = reshape([handles.sAGBM{2}(simNum, :); handles.fAGBM{2}(simNum, :)], 1, 1200);
%                       
% end

% x is the month array - x2 is a double month array for use with BM
% (to deal with starting and final biomass)
x = 1:600;        
x2 = reshape([x-1;x], 1, 1200);

% Grab the setup from the controls

setup.plotElement = handles.plotElements{get(handles.plotElementsDDL, 'Value')};
setup.cumulative = get(handles.cumulativeDDL, 'Value') == 2;

setup.combined = get(handles.combinedCB, 'Value');
setup.primary = get(handles.primaryCB, 'Value');
setup.belt = get(handles.beltCB, 'Value');

setup.combinedUnit = handles.combinedUnits{get(handles.combinedUnitsDDL, 'Value')};
setup.primaryUnit = handles.primaryUnits{get(handles.primaryUnitsDDL, 'Value')};
setup.beltUnit = handles.beltUnits{get(handles.beltUnitsDDL, 'Value')};

setup.startMonth = str2double(get(handles.startMonthEdit, 'String'));
setup.finishMonth = str2double(get(handles.finishMonthEdit, 'String'));

% set a handy boolean.
isBMPlot = any(strcmp(setup.plotElement, {'Below Ground Biomass', 'Above Ground Biomass', 'Total Biomass'}));

% Extract data controls dictate
switch setup.plotElement
    case 'Profit'
            data{1} = plotableData.p_incomePerMonth(setup.startMonth:setup.finishMonth, 1:simNum) - plotableData.p_costsPerMonth(setup.startMonth:setup.finishMonth, 1:simNum); 
            data{2} = plotableData.b_incomePerMonth(setup.startMonth:setup.finishMonth, 1:simNum) - plotableData.b_costsPerMonth(setup.startMonth:setup.finishMonth, 1:simNum); 
            data{3} = data{1} + data{2};
            time = x;
    case 'Income'
            data{1} = plotableData.p_incomePerMonth(setup.startMonth:setup.finishMonth, 1:simNum); 
            data{2} = plotableData.b_incomePerMonth(setup.startMonth:setup.finishMonth, 1:simNum);
            data{3} = data{1} + data{2};
            time = x;        
    case 'Costs'
            data{1} = plotableData.p_costsPerMonth(setup.startMonth:setup.finishMonth, 1:simNum);
            data{2} = plotableData.b_costsPerMonth(setup.startMonth:setup.finishMonth, 1:simNum);
            data{3} = data{1} + data{2};
            time = x;        
    case 'Below Ground Biomass'
            data{1} = plotableData.p_BGBM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum); 
            data{2} = plotableData.b_BGBM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum);
            data{3} = data{1} + data{2};
            time = x2;          
    case 'Above Ground Biomass'
            data{1} = plotableData.p_AGBM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum); 
            data{2} = plotableData.b_AGBM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum);
            data{3} = data{1} + data{2};
            time = x2;        
    case 'Total Biomass'
            data{1} = plotableData.p_BM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum);
            data{2} = plotableData.b_BM(setup.startMonth*2-1:setup.finishMonth*2, 1:simNum);
            data{3} = data{1} + data{2};
            time = x2;
end
% switch setup.plotElement
%     case 'Profit'
%             data{1} = primIncomePerMonth(:, setup.startMonth:setup.finishMonth) - primCostsPerMonth(:, setup.startMonth:setup.finishMonth); 
%             data{2} = beltIncomePerMonth(:, setup.startMonth:setup.finishMonth) - beltCostsPerMonth(:, setup.startMonth:setup.finishMonth); 
%             data{3} = data{1} + data{2};
%             time = x;
%     case 'Income'
%             data{1} = primIncomePerMonth(:, setup.startMonth:setup.finishMonth); 
%             data{2} = beltIncomePerMonth(:, setup.startMonth:setup.finishMonth);
%             data{3} = data{1} + data{2};
%             time = x;        
%     case 'Costs'
%             data{1} = primCostsPerMonth(:, setup.startMonth:setup.finishMonth);
%             data{2} = beltCostsPerMonth(:, setup.startMonth:setup.finishMonth);
%             data{3} = data{1} + data{2};
%             time = x;        
%     case 'Below Ground Biomass'
%             data{1} = primBGBM(:, setup.startMonth*2-1:setup.finishMonth*2); 
%             data{2} = beltBGBM(:, setup.startMonth*2-1:setup.finishMonth*2);
%             data{3} = data{1} + data{2};
%             time = x2;          
%     case 'Above Ground Biomass'
%             data{1} = primAGBM(:, setup.startMonth*2-1:setup.finishMonth*2); 
%             data{2} = beltAGBM(:, setup.startMonth*2-1:setup.finishMonth*2);
%             data{3} = data{1} + data{2};
%             time = x2;        
%     case 'Total Biomass'
%             data{1} = primBGBM(:, setup.startMonth*2-1:setup.finishMonth*2) + primAGBM(:, setup.startMonth*2-1:setup.finishMonth*2); 
%             data{2} = beltBGBM(:, setup.startMonth*2-1:setup.finishMonth*2) + beltAGBM(:, setup.startMonth*2-1:setup.finishMonth*2);
%             data{3} = data{1} + data{2};
%             time = x2;
% end

% Grab the appropriate unitQuantity vectors.
%uQNames = {setup.primaryUnit, setup.beltUnit, setup.combinedUnit};

if setup.primary
   
    switch setup.primaryUnit
        case 'per Month'
                            uQ{1} = ones(1, setup.finishMonth - setup.startMonth + 1);        
          
        case 'per Hectare'
                            uQ{1} = plotableData.p_hectares(setup.startMonth:setup.finishMonth);
    end
    
    if isBMPlot
            uQ{1} = reshape([uQ{1}; uQ{1}], 2*length(uQ{1}), 1);
    else
            uQ{1} = uQ{1}';
    end

end


if setup.belt

    switch setup.beltUnit
        case 'per Month'            
                uQ{2} = ones(1, setup.finishMonth - setup.startMonth + 1);        
        case 'per Hectare'
                uQ{2} = plotableData.b_hectares(setup.startMonth:setup.finishMonth);
        case 'per Tree'
                uQ{2} = plotableData.b_trees(setup.startMonth:setup.finishMonth);        
        case 'per Km of Belts'
                uQ{2} = plotableData.b_kmOfBelts(setup.startMonth:setup.finishMonth);
        case 'per Km of Rows'
                uQ{2} = plotableData.b_kmOfRows(setup.startMonth:setup.finishMonth);
    end

    if isBMPlot
            uQ{2} = reshape([uQ{2}; uQ{2}], 2*length(uQ{2}), 1);
    else
            uQ{2} = uQ{2}';
    end

end
    

if setup.combined
   
    switch setup.combinedUnit
    
        case 'per Month'
                            uQ{3} = ones(1, setup.finishMonth - setup.startMonth + 1);        
          
        case 'per Hectare'
                            uQ{3} = plotableData.p_hectares(1, setup.startMonth:setup.finishMonth);
    end
    
    if isBMPlot
            uQ{3} = reshape([uQ{3}; uQ{3}], 2*length(uQ{3}), 1);
    else
            uQ{3} = uQ{3}';
    end
end

% 
% for i = 1:2
%     switch uQNames{i}
%         case 'per Month'
%             if ~isBMPlot
%                 uQ{i} = ones(1, setup.finishMonth - setup.startMonth + 1);        
%             else
%                 uQ{i} = ones(1, setup.finishMonth*2 - (setup.startMonth*2 - 1) + 1);
%             end            
%         case 'per Hectare'
%             if ~isBMPlot
%                 uQ{i} = handles.hectares{i}(1, setup.startMonth:setup.finishMonth);
%             else
%                 temp = reshape([handles.hectares{i}(1, :); handles.hectares{i}(1, :)], 1, 1200);
%                 uQ{i} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%             end  
%         case 'per Tree'
%             if ~isBMPlot
%                 uQ{i} = handles.trees{i}(1, setup.startMonth:setup.finishMonth);
%             else
%                 temp = reshape([handles.trees{i}(1, :); handles.trees{i}(1, :)], 1, 1200);
%                 uQ{i} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%             end              
%         case 'per Km of Belts'
%             if ~isBMPlot
%                 uQ{i} = handles.kmOfBelts{i}(1, setup.startMonth:setup.finishMonth);
%             else
%                 temp = reshape([handles.kmOfBelts{i}(1, :); handles.kmOfBelts{i}(1, :)], 1, 1200);
%                 uQ{i} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%             end  
%         case 'per Km of Rows'
%             if ~isBMPlot
%                 uQ{i} = handles.kmOfRows{i}(1, setup.startMonth:setup.finishMonth);
%             else
%                 temp = reshape([handles.kmOfRows{i}(1, :); handles.kmOfRows{i}(1, :)], 1, 1200);
%                 uQ{i} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%             end  
%     end
% end
% switch uQNames{3}
%     case 'per Month'
%         if ~isBMPlot
%             uQ{3} = ones(1, setup.finishMonth - setup.startMonth + 1);
%         else
%             uQ{3} = ones(1, setup.finishMonth*2 - (setup.startMonth*2 - 1) + 1);
%         end            
%     case 'per Hectare'
%         if ~isBMPlot
%             uQ{3} = handles.hectares{1}(1, setup.startMonth:setup.finishMonth) + handles.hectares{2}(1, setup.startMonth:setup.finishMonth);
%         else
%             temp = reshape([handles.hectares{i}(1, :); handles.hectares{i}(1, :)], 1, 1200);
%             uQ{3} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%         end  
%     case 'per Tree'
%         if ~isBMPlot
%             uQ{3} = handles.trees{1}(1, setup.startMonth:setup.finishMonth) + handles.trees{2}(1, setup.startMonth:setup.finishMonth);
%         else
%             temp = reshape([handles.trees{i}(1, :); handles.trees{i}(1, :)], 1, 1200);
%             uQ{3} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%         end              
%     case 'per Km of Belts'
%         if ~isBMPlot
%             uQ{3} = handles.kmOfBelts{1}(1, setup.startMonth:setup.finishMonth) + handles.kmOfBelts{2}(1, setup.startMonth:setup.finishMonth);
%         else
%             temp = reshape([handles.kmOfBelts{i}(1, :); handles.kmOfBelts{i}(1, :)], 1, 1200);
%             uQ{3} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%         end  
%     case 'per Km of Rows'
%         if ~isBMPlot
%             uQ{3} = handles.kmOfRows{1}(1, setup.startMonth:setup.finishMonth) + handles.kmOfRows{2}(1, setup.startMonth:setup.finishMonth);
%         else
%             temp = reshape([handles.kmOfRows{i}(1, :); handles.kmOfRows{i}(1, :)], 1, 1200);
%             uQ{3} = temp(setup.startMonth*2-1:setup.finishMonth*2);
%         end  
% end


set(handles.titleLabel, 'String', setup.plotElement);

for i = 1:3
    if setup.cumulative
        if ~isBMPlot
            data{i} = cumsum(data{i});
        end
    end
end

if isBMPlot
    time = time(setup.startMonth*2-1:setup.finishMonth*2);
else
    time = time(setup.startMonth:setup.finishMonth);
end


% Clear both axes.
% If primary and belt are both on we set up both the axes.
% Otherwise, we set up just one.
axes(handles.axes1);
cla
hold on
axes(handles.axes2);
cla
hold on

if setup.primary && setup.belt
    % axes1 goes to 400 / 250
    pos = get(handles.axes1, 'Position');
    pos(2) = 400;
    pos(4) = 250;
    set(handles.axes1, 'Position', pos); 
    set(handles.axes2, 'Visible', 'on');
    set(handles.axes2Label, 'Visible', 'on');
    set(handles.axes2Label, 'String', 'Belt');
    set(handles.axes1Label, 'String', 'Primary');
    
    pAxes = handles.axes1;
    bAxes = handles.axes2;
else
    set(handles.axes2, 'Visible', 'off');
    set(handles.axes2Label, 'Visible', 'off');
    if setup.primary    
        set(handles.axes1Label, 'String', 'Primary');
    elseif setup.belt
        set(handles.axes1Label, 'String', 'Belt');        
    elseif setup.combined
        set(handles.axes1Label, 'String', 'Combined');
    end
    % axes1 goes to 100 / 550
    pos = get(handles.axes1, 'Position');
    pos(2) = 100;
    pos(4) = 550;
    set(handles.axes1, 'Position', pos); 
    pAxes = handles.axes1;
    bAxes = handles.axes1;
end

colours = colormap('Lines');

% Sort out the labels
% Should be able to use the DDLs if everything is working properly.
% Profit, Income and costs give $
% Biomass gives tonnes of BM
if any(strcmp(setup.plotElement, {'Profit', 'Income', 'Costs'}))
    unitStr = '$ ';
else
    unitStr = 'tonnes of BM ';
end
primaryYLabel = [unitStr, '/ ', setup.primaryUnit];
beltYLabel = [unitStr, '/ ', setup.beltUnit];
combinedYLabel = [unitStr, '/ ', setup.combinedUnit];

% Plot the data
if setup.combined
  % 
       data{3} = data{3} ./ repmat(uQ{3}, 1, simNum);
       if setup.cumulative || ~any(strcmp(setup.plotElement, {'Profit', 'Income', 'Costs'}))
           plot(handles.axes1, time, data{3}); %, 'Color', colours);  
       else
           for i = 1:handles.simNum
               axes(handles.axes1)
               scatter(time, data{3}(:,i), 15, colours(i,:)); 
           end
       end
       axes(handles.axes1);
       xlabel('Months');
       ylabel(combinedYLabel);
       set(handles.axes1, 'XMinorTick', 'on');
       set(handles.axes1, 'Box', 'off');
       set(handles.axes1, 'XTick', 0:60:600);
%   end
end
if setup.primary
 %  for i = 1:handles.numberOfSims 
       data{1} = data{1} ./ repmat(uQ{1}, 1, simNum);
       if setup.cumulative || ~any(strcmp(setup.plotElement, {'Profit', 'Income', 'Costs'}))
           plot(pAxes, time, data{1}); %(i,:), 'Color', colours(i, :)); 
       else
           for i = 1:handles.simNum
               axes(handles.axes1)
               scatter(time, data{1}(:,i), 15, colours(i,:)); 
           end
       end
       axes(pAxes);
       xlabel('Months');
       ylabel(primaryYLabel);
       set(pAxes, 'XMinorTick', 'on');
       set(pAxes, 'Box', 'off');
       set(pAxes, 'XTick', 0:60:600);
%   end
end
if setup.belt
%   for i = 1:handles.numberOfSims
      data{2} = data{2} ./ repmat(uQ{2}, 1, simNum);
      if setup.cumulative || ~any(strcmp(setup.plotElement, {'Profit', 'Income', 'Costs'}))
          plot(bAxes, time, data{2}); %(i,:), 'Color', colours(i, :)); 
      else
         for i = 1:handles.simNum
             axes(handles.axes2)
             scatter(time, data{2}(:,i), 15, colours(i,:)); 
         end
      end
       axes(bAxes);
       ylabel(beltYLabel);
       xlabel('Months');
       set(bAxes, 'XMinorTick', 'on');
       set(bAxes, 'Box', 'off');
       set(bAxes, 'XTick', 0:60:600);
%   end
end

set(handles.axes1, 'YTickMode', 'auto');
set(handles.axes2, 'YTickMode', 'auto');

%refresh(gcf)    
    
%
% This should be called when any range control is changed.
% Its function is to maintain the choherence between the controls.
% The input gives a 1 or 2 for controlCol for start and finish, and 1, 2, 3
% for controlRow if the control is the monthDDL, yearDDL, 
% or monthEdit respectively that was changed.
function fixMonthControls(handles, controlRow, controlCol)    

% We assume that the edits have been vetted before they get here.
% As far as possible, accomodate the change. If the DDL changes,
% update the edit, and vice versa.

% If the start has changed, check that it is not now after the
% finish. If it is, move the finish forward by a year. If after this,
% the month is past 600, move the start and finish back till the finish is
% at 600.


% Do the analagous thing the other way.
data = [get(handles.startMonthDDL, 'Value'), get(handles.finishMonthDDL, 'Value'); ...
        get(handles.startYearDDL,  'Value'), get(handles.finishYearDDL,  'Value'); ...
        str2double(get(handles.startMonthEdit, 'String')), str2double(get(handles.finishMonthEdit, 'String'))];
    
if ~(controlRow == 3)
    % We changed a DDL - update the months value
    data(3, controlCol) = (data(2, controlCol) - 1) * 12 + data(1, controlCol);
else
    % Else we changed the edit. Check for errors.
    data(3, 1) = floor(data(3, 1));
    data(3, 2) = floor(data(3, 2));
    if data(3, 1) < 1
        data(3, 1) = 1;
    end
    if data(3, 1) > 600
        data(3, 1) = 600;
    end
    if data(3, 2) < 1
        data(3, 2) = 1;
    end
    if data(3, 2) > 600
        data(3, 2) = 600;
    end
end

% Sort out any problems
if data(3, 1) > data(3, 2)
    if controlCol == 1
        % We set the start. Try to preserve it.
        data(3, 2) = data(3, 1) + 12;
        if data(3, 2) > 600
            data(3, 2) = 600;
            data(3, 1) = 600 - 11;
        end
    end
    if controlCol == 2
        % We set the finish. Try to preserve the finish.
        data(3, 1) = data(3, 2) - 12;
        if data(3, 1) < 1
            data(3, 1) = 1;
            data(3, 2) = 12;
        end
    end
end
    
% Redo the controls.
for i = 1:2
    data(1, i) = mod(data(3, i) - 1, 12) + 1;
    data(2, i) = (data(3, i) - data(1, i)) / 12 + 1;
end

set(handles.startMonthDDL, 'Value', data(1, 1));
set(handles.finishMonthDDL, 'Value', data(1, 2)); 
set(handles.startYearDDL,  'Value', data(2, 1));
set(handles.finishYearDDL,  'Value', data(2, 2)); 
set(handles.startMonthEdit, 'String', num2str(data(3, 1)));
set(handles.finishMonthEdit, 'String', num2str(data(3, 2)));    


% --- Executes on button press in summaryStatsButton.
function summaryStatsButton_Callback(hObject, eventdata, handles)
% hObject    handle to summaryStatsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

summaryStatsDialog(handles);


% --- Executes on selection change in startMonthDDL.
function startMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to startMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns startMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from startMonthDDL
fixMonthControls(handles, 1, 1);
if ~handles.runningSim
    refreshPlot(handles);
end


% --- Executes during object creation, after setting all properties.
function startMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finishMonthDDL.
function finishMonthDDL_Callback(hObject, eventdata, handles)
% hObject    handle to finishMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns finishMonthDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finishMonthDDL
fixMonthControls(handles, 1, 2);
if ~handles.runningSim
    refreshPlot(handles);
end


% --- Executes during object creation, after setting all properties.
function finishMonthDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finishMonthDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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
fixMonthControls(handles, 2, 1);
if ~handles.runningSim
    refreshPlot(handles);
end


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


% --- Executes on selection change in finishYearDDL.
function finishYearDDL_Callback(hObject, eventdata, handles)
% hObject    handle to finishYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns finishYearDDL contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finishYearDDL
fixMonthControls(handles, 2, 2);
if ~handles.runningSim
    refreshPlot(handles);
end


% --- Executes during object creation, after setting all properties.
function finishYearDDL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finishYearDDL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function startMonthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to startMonthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startMonthEdit as text
%        str2double(get(hObject,'String')) returns contents of startMonthEdit as a double

% Check that he input is a number. If not, call fix with the DDLs.
num = str2double(get(hObject, 'String'));
if isnan(num)
    fixMonthControls(handles, 1, 1);
    return
else
    fixMonthControls(handles, 3, 1);
    if ~handles.runningSim
        refreshPlot(handles);
    end
end

% --- Executes during object creation, after setting all properties.
function startMonthEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startMonthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finishMonthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to finishMonthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finishMonthEdit as text
%        str2double(get(hObject,'String')) returns contents of finishMonthEdit as a double

% Check that he input is a number. If not, call fix with the DDLs.
num = str2double(get(hObject, 'String'));
if isnan(num)
    fixMonthControls(handles, 1, 2);
    return
else
    fixMonthControls(handles, 3, 2);
    if ~handles.runningSim
        refreshPlot(handles);
    end
end

% --- Executes during object creation, after setting all properties.
function finishMonthEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finishMonthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listboxRegimeFilter.
function listboxRegimeFilter_Callback(hObject, eventdata, handles)
% hObject    handle to listboxRegimeFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxRegimeFilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxRegimeFilter
regStrings = get(hObject, 'String');
vs = get(hObject, 'Value');
% If there are more than one regimes selected, remember just the first one
% in the list.
handles.previouslySelectedRegime = regStrings{vs(1)};
guidata(hObject, handles);
populateCropFilter(handles);

% --- Executes during object creation, after setting all properties.
function listboxRegimeFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxRegimeFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listboxCropFilter.
function listboxCropFilter_Callback(hObject, eventdata, handles)
% hObject    handle to listboxCropFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxCropFilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxCropFilter
cropStrings = get(hObject, 'String');
handles.previouslySelectedCrop = cropStrings{get(hObject, 'Value')};
guidata(hObject, handles);
populatePlotSelection(handles);

% --- Executes during object creation, after setting all properties.
function listboxCropFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxCropFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listboxPlotSelection.
function listboxPlotSelection_Callback(hObject, eventdata, handles)
% hObject    handle to listboxPlotSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxPlotSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxPlotSelection
plotStrings = get(hObject, 'String');
handles.previouslySelectedPlot = plotStrings{get(hObject, 'Value')};
guidata(hObject, handles);
refreshPlot(handles);

% --- Executes during object creation, after setting all properties.
function listboxPlotSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxPlotSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxCombine.
function checkboxCombine_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCombine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCombine
refreshPlot(handles);

% --- Executes on button press in checkboxCumulative.
function checkboxCumulative_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCumulative (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCumulative
refreshPlot(handles);

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'controlPaneWidth') && handles.setupComplete
    setupAxes(handles);    
end

% --- Executes on button press in pushbuttonClearRegimeList.
function pushbuttonClearRegimeList_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearRegimeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listboxRegimeFilter, 'Value', []);
handles.previouslySelectedRegime = [];
guidata(hObject, handles);
populateCropFilter(handles);

% --- Executes on button press in pushbuttonClearCropList.
function pushbuttonClearCropList_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearCropList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listboxCropFilter, 'Value', []);
handles.previouslySelectedCrop = [];
guidata(hObject, handles);
populatePlotSelection(handles);

% Sets up the filter lists and plor list.
function establishRegimesCropsAndPlots(handles)
           
handles.simMgr.simulationWindow = handles.figure1;

% Get the regimeDefinitions and CropDefinitions.
handles.regDefs = handles.simMgr.regimeMgr.regimeDefinitions;
handles.cropDefs = handles.simMgr.cropMgr.cropDefinitions;
handles.cropDefsProductUnits = handles.simMgr.cropMgr.getCropsProductUnits({handles.cropDefs.name});
handles.cropDefsOutputUnits = handles.simMgr.cropMgr.getCropsOutputUnits({handles.cropDefs.name});
handles.cropDefsOutputRates = handles.simMgr.cropMgr.getCropsOutputRates({handles.cropDefs.name});
handles.cropDefsEventOutputUnits = handles.simMgr.cropMgr.getCropsEventOutputUnits({handles.cropDefs.name});
handles.cropDefsEventOutputRates = handles.simMgr.cropMgr.getCropsEventOutputRates({handles.cropDefs.name});

handles.previouslySelectedRegime = [];
handles.previouslySelectedCrop = [];
handles.previouslySelectedPlot = 'Profit';

guidata(handles.listboxRegimeFilter, handles);

populateRegimeFilter(handles);


% Uses the regDefs in handles to fill in the regimeLabels.
% This is the top level so all regimes should be listed.
function populateRegimeFilter(handles)

set(handles.listboxRegimeFilter, 'String', {handles.regDefs.regimeLabel});
set(handles.listboxRegimeFilter, 'Value', handles.previouslySelectedRegime);
populateCropFilter(handles);


% Gets the selected regime labels from the regimeFilter and
% populates the list box with the selected crops.
% Selects the previously selected entry if possible. Selected entry
% is remembered when it is explicitly selected so there is no need 
% to save it here.
function populateCropFilter(handles)

regimeIndices = get(handles.listboxRegimeFilter, 'Value');
if isempty(regimeIndices)
    regimeIndices = 1:length(handles.regDefs);
end

cropList = sort(unique([handles.regDefs(regimeIndices).cropNameList]));
set(handles.listboxCropFilter, 'String', cropList);

% Now select the previouslySelectedCrop if possible. Otherwise set Value to
% [], without changing previouslySelectedCrop. find returns [] if no match,
% so this is perfect.
ix = find(strcmp(handles.previouslySelectedCrop, cropList), 1, 'first');
set(handles.listboxCropFilter, 'Value', ix);

populatePlotSelection(handles);


% Gets the selected crops from the cropFilter and populates the
% list with the available plots. Selects the previously selected
% entry if possible.
% SimMgr will remember the previously selected item. The selected
% item will be set every time it is explicitly selected, (or
% cleared).
function populatePlotSelection(handles)
            
% Crops are not garaunteed to be in the same order as handles.cropDefs,
% unlike the regimeDefs were. So we have to get the actual names of the
% crops to use.
cropStrings = get(handles.listboxCropFilter, 'String');
cropFilterIndices = get(handles.listboxCropFilter, 'Value');
if isempty(cropFilterIndices)
   cropFilterIndices = 1:length(cropStrings) ;
end

cropNamesToUse = cropStrings(cropFilterIndices);

cropLogicals = false(1, length(handles.cropDefs));
for i = 1:length(handles.cropDefs)
    handles.cropDefs(i).name
    ix = find(strcmp(handles.cropDefs(i).name, cropNamesToUse), 1, 'first');
    if ~isempty(ix)
        cropLogicals(i) = true;
    end
    
end

% cropLogicals should now index the cropDefinitions.

% cropDefsProductUnits is a cell array of arrays of units. 
% We can concat entries in cells using the neat cat(1, cell{:}) trick. 

productUnitsInCells = handles.cropDefsProductUnits(cropLogicals);
productUnitsToUse = catArrays(productUnitsInCells{:});
if (~isempty(productUnitsToUse))
    productSpecies = unique({productUnitsToUse.speciesName});
else
    productSpecies = {};
end


outputUnitsInCells = handles.cropDefsOutputUnits(cropLogicals);
outputUnitsToUse = catArrays(outputUnitsInCells{:});
if (~isempty(outputUnitsToUse))
    outputSpecies = unique({outputUnitsToUse.speciesName});
else
    outputSpecies = {};
end

eventOutputUnitsInCells = handles.cropDefsEventOutputUnits(cropLogicals);
eventOutputUnitsToUse = catArrays(eventOutputUnitsInCells{:});
if (~isempty(eventOutputUnitsToUse))
    eventOutputSpecies = unique({eventOutputUnitsToUse.speciesName});
else
    eventOutputSpecies = {};
end

outputRatesInCells = handles.cropDefsOutputRates(cropLogicals);
outputRatesToUse = catArrays(outputRatesInCells{:});
if (~isempty(outputRatesToUse))
    outputRatesThatHaveNoDenominatorUnit = outputRatesToUse([outputRatesToUse.denominatorUnit] == Unit);
    outputUnitsThatHaveNoDenominatorUnit = [outputRatesThatHaveNoDenominatorUnit.unit];
else
    outputUnitsThatHaveNoDenominatorUnit = {};
end


if isempty(outputUnitsThatHaveNoDenominatorUnit)
   handles.outputSpeciesThatHaveNoDenominatorUnit = {};
else
    handles.outputSpeciesThatHaveNoDenominatorUnit = unique({outputUnitsThatHaveNoDenominatorUnit.speciesName});   
end

eventOutputRatesInCells = handles.cropDefsEventOutputRates(cropLogicals);
eventOutputRatesToUse = catArrays(eventOutputRatesInCells{:});
if (~isempty(eventOutputRatesToUse))
    eventOutputRatesThatHaveNoDenominatorUnit = eventOutputRatesToUse([eventOutputRatesToUse.denominatorUnit] == Unit);   
    eventOutputUnitsThatHaveNoDenominatorUnit = [eventOutputRatesThatHaveNoDenominatorUnit.unit];
else
    eventOutputUnitsThatHaveNoDenominatorUnit = {};
end

if isempty(eventOutputUnitsThatHaveNoDenominatorUnit)
   handles.eventOutputSpeciesThatHaveNoDenominatorUnit = {};
else
    handles.eventOutputSpeciesThatHaveNoDenominatorUnit = unique({eventOutputUnitsThatHaveNoDenominatorUnit.speciesName});   
end


guidata(handles.listboxPlotSelection, handles);

% The list should have 'Profit', 'Income', 'Cost' first.
% Then the list of products, then the list of outputs.

defaultPlots = {'Profit', 'Income', 'Cost'};

for i = 1:length(productSpecies)    
    productSpecies{i} = ['P:  ', productSpecies{i}];
end

for i = 1:length(outputSpecies)    
    outputSpecies{i} = ['O:  ', outputSpecies{i}];
end

for i = 1:length(eventOutputSpecies)    
    eventOutputSpecies{i} = ['EO: ', eventOutputSpecies{i}];
end

plotsToUse = [defaultPlots, productSpecies, outputSpecies, eventOutputSpecies];

set(handles.listboxPlotSelection, 'String', plotsToUse);

% Try to set the previous selected plot if possible. Otherwise set Value to
% [], without changing previouslySelectedPlot. find returns [] if no match,
% so this is perfect.
ix = find(strcmp(handles.previouslySelectedPlot, plotsToUse), 1, 'first');
if isempty(ix)
    % If there's no previous plot, default to 'Profit' in the first slot.
    set(handles.listboxPlotSelection, 'Value', 1);
else
    set(handles.listboxPlotSelection, 'Value', ix);
end

% Now we should actually plot something if there is a plot selection.
refreshPlot(handles); 


% This function should check the plot in the plot selection listbox, work
% out what the filter is and request the data from the SimulationManager.
% Then it updates the plot.
function refreshPlot(handles)

% Get start and end month from the controls.
startMonth = str2double(get(handles.startMonthEdit, 'String'));
endMonth = str2double(get(handles.finishMonthEdit, 'String'));

% Required data for request:

% type - Financial, product, output
% speciesName
% regime names to use
% crop names to use

plotSelections = get(handles.listboxPlotSelection, 'String');
selectionIndex = get(handles.listboxPlotSelection, 'Value');
plotSelection = plotSelections{selectionIndex};
showDenominatorUnits = true;

if selectionIndex <= 3 
    type = 'financial';
    speciesName = plotSelection;
else
    % species name comes from the bit after the 'O:  ' or 'P:  '
    % both of which have 4 characters. So use the 5th character on.
    if strcmp(plotSelection(1), 'P')
        type = 'product';
        speciesName = plotSelection(5:end);
    elseif strcmp(plotSelection(1), 'O')
        type = 'output';
        speciesName = plotSelection(5:end);    
        % If it is an output, then the denominator unit might be just unit.
        % We need to know about that.
        
        ix = find(strcmp(handles.outputSpeciesThatHaveNoDenominatorUnit, speciesName), 1, 'first');
        if ~isempty(ix)
           showDenominatorUnits = false;
        end
    elseif strcmp(plotSelection(1:2), 'EO')
        type = 'eventOutput';
        speciesName = plotSelection(5:end);    
        % If it is an event output, then the denominator unit might be just unit.
        % We need to know about that.
        
        ix = find(strcmp(handles.eventOutputSpeciesThatHaveNoDenominatorUnit, speciesName), 1, 'first');
        if ~isempty(ix)
           showDenominatorUnits = false;
        end
    else
        error('Unknown plot type selected.');
    end
end

cropStrings = get(handles.listboxCropFilter, 'String');
cropFilterIndices = get(handles.listboxCropFilter, 'Value');
if isempty(cropFilterIndices)
   cropFilterIndices = 1:length(cropStrings) ;
end

cropNamesToUse = cropStrings(cropFilterIndices);

regimeIndices = get(handles.listboxRegimeFilter, 'Value');
if isempty(regimeIndices)
    if length(cropNamesToUse) == 1
        % We want to include only those regimes that include the selected
        % crop. a 'regime definition' is a struct that has a field cropNameList which has the
        % names of the crops for the regime. handles.regDefs is a list of
        % these. 
        cropName = cropNamesToUse{1};
        regIxs = 1:length(handles.regDefs);
        for i = regIxs
            ix = find(strcmp(cropName, handles.regDefs(i).cropNameList), 1, 'first');
            if ~isempty(ix)
                regimeIndices = [regimeIndices, i];
            end
        end
    else
        regimeIndices = 1:length(handles.regDefs);
    end
end

regimeNamesToUse = {handles.regDefs(regimeIndices).regimeLabel};
%arg.regimeLabelsToUse = regimeNamesToUse;

% Need to check if the denominator unit is just Unit or if it's something
% that can be changed to other regime units.
if ~showDenominatorUnits
    set(handles.textUnitsLabel, 'Visible', 'off');    
    set(handles.popupmenuUnitSelection, 'Visible', 'off');
    set(handles.popupmenuUnitSelection, 'String', {});
    set(handles.popupmenuUnitSelection, 'Value', 1);    
    handles.unit = Unit;
else
    
    % Get available units, save them and update the drop down list. Use
    % previously saved unit if possible. Note that the DDL callback should
    % save the selected unit to handles before calling refreshPlot.
    unitsAvailable = handles.simMgr.getCommonRegimeUnits(regimeNamesToUse);
    if ~isempty(unitsAvailable)
        handles.unitsAvailable = unitsAvailable;
    end

    readableUnits = {handles.unitsAvailable.readableDenominatorUnit};
    ix = find(strcmp(readableUnits, handles.unit.readableDenominatorUnit), 1, 'first');
    set(handles.popupmenuUnitSelection, 'String', readableUnits);
    set(handles.popupmenuUnitSelection, 'Visible', 'on');
    set(handles.textUnitsLabel, 'Visible', 'on');    
    if ~isempty(ix)
        set(handles.popupmenuUnitSelection, 'Value', ix);
    else
        setDefaultPlotUnit(handles);
    %    set(handles.popupmenuUnitSelection, 'Value', 1);   
    end
    % Need to set the unit again in case it just changed.
    handles.unit = handles.unitsAvailable(get(handles.popupmenuUnitSelection, 'Value'));
end

% Pull the plot data from the simulation manager. Perhaps this function
% should take the desired unit as an input.
% Also, we want the primary and secondary data to give us month start and
% month end. Then we have enough that we can make any of the following
% graph types: monthly (start), monthly(end), monthly(both), sum, average
% monthly, average yearly.
[primaryData, secondaryData, outputUnit] = handles.simMgr.getPlotData(type, speciesName, regimeNamesToUse, cropNamesToUse, handles.unit);

if isempty(outputUnit)
   set(handles.pushbuttonWriteToAccess, 'Enable', 'off');
else
   set(handles.pushbuttonWriteToAccess, 'Enable', 'on');       
end

% outputUnit is the units that the primary and secondary data are given in.
% the unit passed to the getPlotData function is actually the denominator
% unit.
% So if handles.unit = (Paddock, Unit)
% and outputUnit = (Yield, Tonnes) then we'd say the primary and secondary
% data are in Tonnes of Yield per Paddock.

% Set the available plot types. Select the last saved plot type if
% possible, otherwise choose the Monthly plot type.
% If type is financial calculate NPVs otherwise clear NPVs.
switch type
    case 'financial'
        plotTypes = {'Monthly', 'Yearly', 'Cumulative'};
        handles.primaryNPV = calculateNPV(primaryData, handles.discountRate);
        handles.secondaryNPV = calculateNPV(secondaryData, handles.discountRate);
        myplot = @bar;        
    case 'product'
        plotTypes = {'Monthly', 'Yearly', 'Cumulative'};
        handles.primaryNPV = 0;
        handles.primaryNPV = 0;
        myplot = @bar;
    case 'output'
        plotTypes = {'Monthly'};
        handles.primaryNPV = 0;
        handles.primaryNPV = 0;
        myplot = @plot;
    case 'eventOutput'
        plotTypes = {'Monthly', 'Yearly'};
        handles.primaryNPV = 0;
        handles.primaryNPV = 0;
        myplot = @bar;
end

set(handles.popupmenuPlotType, 'String', plotTypes);
ix = find(strcmp(handles.lastSavedPlotType, plotTypes), 1, 'first');
if isempty(ix)
    setDefaultPlotType(handles);
    %set(handles.popupmenuPlotType, 'Value', 1);
else    
    set(handles.popupmenuPlotType, 'Value', ix);    
end

plotType = handles.plotTypes{get(handles.popupmenuPlotType, 'Value')}; 

xAxisData = 1:handles.simMgr.imagineOb.simulationLength * 12;
xUnits = 'Months';

switch plotType
    
    case 'Monthly' 
        
        if strcmp(type, 'output')
            % If it's a Monthly plot and it's an output type we have to use
            % a plot style graph with start and end points for each month.
            % Therefore xAxisData needs to go have entries x, x+.99 for
            % each month and we reshape the primary and secondary data into
            % a single row.
            
            myplot = @plot;        

            if ~isempty(primaryData)
                primaryData = primaryData(:, startMonth:endMonth);
                primaryData = reshape(primaryData, size(primaryData, 2) * 2, 1);
            end
            if ~isempty(secondaryData)
                secondaryData = secondaryData(:, startMonth:endMonth);
                secondaryData = reshape(secondaryData, size(secondaryData, 2) * 2, 1);
            end
            xAxisData = xAxisData(:, startMonth:endMonth);
            xAxisData(2, :) = xAxisData + 1 - 0.01;
            xAxisData = reshape(xAxisData, size(xAxisData, 2) * 2, 1);        

        else
            % If it's a Monthly plot and a financial or product based plot
            % type we need to add up any contributions for the month. That
            % means month start is added to month end values.
            myplot = @bar;

            % Need just the start of month values.
            if ~isempty(primaryData)
                primaryData = sum(primaryData(:, startMonth:endMonth));
            end
            if ~isempty(secondaryData)
                secondaryData = sum(secondaryData(:, startMonth:endMonth));
            end
            xAxisData = xAxisData(:, startMonth:endMonth);

        end
        
    case 'Yearly'
        myplot = @bar;        
        xUnits = 'Years';
        
        % Not really appropriate for outputs. Makes sense for financials
        % and products.
        % Use Month end values.
        % Need to pad the start and the end with zeros to force 12 x n
        % lengths.
        leadingZeros = mod(startMonth - 1, 12); 
        trailingZeros = mod(12 - mod(endMonth, 12), 12);
        if ~isempty(primaryData)
            % Add month start and month end values.
            primaryData = sum(primaryData);
            % Pad with leading and trailing zeros
            primaryData = [zeros(1, leadingZeros), primaryData(:, startMonth:endMonth), zeros(1, trailingZeros)];
            % Reshape so each covered year has it's own column
            primaryData = reshape(primaryData, 12, length(primaryData) / 12);
            % Sum contents of each column to get yearly data.
            primaryData = sum(primaryData);
        end
        if ~isempty(secondaryData)
            % As above
            secondaryData = sum(secondaryData);
            secondaryData = [zeros(1, leadingZeros), secondaryData(:, startMonth:endMonth), zeros(1, trailingZeros)];
            secondaryData = reshape(secondaryData, 12, length(secondaryData) / 12);
            secondaryData = sum(secondaryData);
        end
        xAxisData = xAxisData(:, (startMonth - leadingZeros)+11:12:(endMonth + trailingZeros));
        xAxisData = xAxisData / 12;
        
    case 'Cumulative'
        myplot = @plot;        
        
        % Add month start and month end values.
        if ~isempty(primaryData)
            primaryData = sum(primaryData);
            primaryData = primaryData(:, 1:endMonth);  
            primaryData = cumsum(primaryData);
            primaryData = primaryData(startMonth:endMonth);
        end
        if ~isempty(secondaryData)
            secondaryData = sum(secondaryData);
            secondaryData = secondaryData(:, 1:endMonth);  
            secondaryData = cumsum(secondaryData);
            secondaryData = secondaryData(startMonth:endMonth);
        end
        xAxisData = xAxisData(:, startMonth:endMonth);
        
%     case 'Average Monthly'
%         myplot = @plot;        
% 
%         % Not really appropriate unless we have multiple simulations.
%         % For now do a runnning average.
%         if ~isempty(primaryData)
%             primaryData = primaryData(2, 1:endMonth);  
%             primaryData = cumsum(primaryData);
%             primaryData = primaryData ./ 1:endMonth;
%             primaryData = primaryData(startMonth:endMonth);
%         end
%         if ~isempty(secondaryData)
%             secondaryData = secondaryData(2, 1:endMonth);  
%             secondaryData = cumsum(secondaryData);
%             secondaryData = secondaryData ./ 1:endMonth;
%             secondaryData = secondaryData(startMonth:endMonth);
%         end
%         
%     case 'Average Yearly'
%         myplot = @bar;        
% 
%         % Not really appropriate unless we have multiple simulation.
end

% Now use outputUnit to label axes.

shouldCombine = get(handles.checkboxCombine, 'Value');

if ~isempty(primaryData) && ~isempty(secondaryData) 
    % Now it comes down to whether combine is on.
    if shouldCombine
       % Then we should have a single axes, with the label 'Combined'
        
       data = primaryData + secondaryData;
       cla(handles.axes1);
       cla(handles.axes2);
       myplot(handles.axes1, xAxisData, data);
       handles.primaryOn = true;
       handles.secondaryOn = true;
       handles.shouldCombine = shouldCombine;
       
    else
        % Then we have both axes with their 'Primary' and 'Secondary'
        % titles.
       cla(handles.axes1);
       cla(handles.axes2);
       myplot(handles.axes1, xAxisData, primaryData);    
       myplot(handles.axes2, xAxisData, secondaryData);    
       
       handles.primaryOn = true;
       handles.secondaryOn = true;
       handles.shouldCombine = shouldCombine; 
    end

elseif isempty(primaryData) && ~isempty(secondaryData) 
    % Show only the secondary axes.
       cla(handles.axes1);
       cla(handles.axes2);
       myplot(handles.axes2, xAxisData, secondaryData);    
       
       handles.primaryOn = false;
       handles.secondaryOn = true;
       handles.shouldCombine = false; 
       
elseif ~isempty(primaryData) && isempty(secondaryData) 
    % Show only the primary axes.
       cla(handles.axes1);
       cla(handles.axes2);
       myplot(handles.axes1, xAxisData, primaryData);    

       handles.primaryOn = true;
       handles.secondaryOn = false;
       handles.shouldCombine = false; 
else
    % They are both empty. 
    return    
end

guidata(handles.figure1, handles);
if strcmp(type, 'financial')
    set(handles.axes1NPVLabel, 'Visible', 'on');
    set(handles.axes2NPVLabel, 'Visible', 'on');
end
setupAxes(handles)
xlabel(handles.axes1, xUnits);
xlabel(handles.axes2, xUnits);
ylabel(handles.axes1, [outputUnit.readableUnit, '  ', handles.unit.readableDenominatorUnit]);
ylabel(handles.axes2, [outputUnit.readableUnit, '  ', handles.unit.readableDenominatorUnit]);

if ~strcmp(type, 'financial')
    set(handles.axes1NPVLabel, 'Visible', 'off');
    set(handles.axes2NPVLabel, 'Visible', 'off');
end


function setDefaultPlotUnit(handles)
    % Default plot type is Yearly
    % Default units are per Hectare, then per Paddock if not available
    
    % Also look at handles.unit, which is set in the opening
    % function.

    unitsAvailable = get(handles.popupmenuUnitSelection, 'String');
    ix = find(strcmp(unitsAvailable, 'per Hectare of Area'), 1, 'first');
    if ~isempty(ix)            
        set(handles.popupmenuUnitSelection, 'Value', ix);
    else
        ix = find(strcmp(unitsAvailable, 'per Paddock'), 1, 'first');
        if ~isempty(ix)            
            set(handles.popupmenuUnitSelection, 'Value', ix);
        else
            set(handles.popupmenuUnitSelection, 'Value', 1);
        end
    end

function setDefaultPlotType(handles)
    % Default plot type is Yearly
    % Default units are per Hectare, then per Paddock if not available
    
    % Also look at handles.lastSavedPlotType, which is set in the opening
    % function.

    unitsAvailable = get(handles.popupmenuPlotType, 'String');
    ix = find(strcmp(unitsAvailable, 'Yearly'), 1, 'first');
    if ~isempty(ix)            
        set(handles.popupmenuPlotType, 'Value', ix);
    else
        ix = find(strcmp(unitsAvailable, 'Monthly'), 1, 'first');
        if ~isempty(ix)            
            set(handles.popupmenuPlotType, 'Value', ix);
        else
            set(handles.popupmenuPlotType, 'Value', 1);
        end
    end

    
% This function simply sizes, positions, enables and sets visible the axes and
% labels.
function setupAxes(handles)

primaryOn = handles.primaryOn;
secondaryOn = handles.secondaryOn;
shouldCombine = handles.shouldCombine;

% Only allow primary or secondary on if those crops exist.
% hasPrimary = ~isempty(find(strcmp({handles.regDefs.type}, 'primary'), 1));
% hasSecondary = ~isempty(find(strcmp({handles.regDefs.type}, 'secondary'), 1));
% primaryOn = primaryOn && hasPrimary;
% secondaryOn = secondaryOn && hasSecondary;
% shouldCombine = shouldCombine && hasPrimary && hasSecondary;

% Save the positions so I can redraw the axes.
axes1Pos = get(handles.axes1, 'Position');
axes2Pos = get(handles.axes2, 'Position');
axes1LabelPos = get(handles.axes1Label, 'Position');
axes2LabelPos = get(handles.axes2Label, 'Position');
axes1NPVLabelPos = get(handles.axes1NPVLabel, 'Position');
axes2NPVLabelPos = get(handles.axes2NPVLabel, 'Position');
figurePos =  get(handles.figure1, 'Position');

if figurePos(3) < handles.minFigureWidth
    figurePos(3) = handles.minFigureWidth;
end
if figurePos(4) < handles.minFigureHeight
    figurePos(4) = handles.minFigureHeight;
end
set(handles.figure1, 'Position', figurePos);

% Set the control panel position:
controlPanelPos = get(handles.uipanelControlPanel, 'Position');
controlPanelPos(1) = handles.controlPanelInset;
controlPanelPos(2) = figurePos(4) - controlPanelPos(4) - handles.controlPanelInset;
set(handles.uipanelControlPanel, 'Position', controlPanelPos);

% x, y, width, height

axesWidth = figurePos(3) - handles.controlPaneWidth - handles.rightMargin;
smallAxesHeight = (figurePos(4) - handles.bottomMargin - 2 * handles.axesGap) / 2;
largeAxesHeight = (figurePos(4) - handles.bottomMargin - handles.axesGap);

% handles.bottomMargin = axes2Pos(2);
% handles.rightMargin = figurePos(3) - axes2Pos(1) - axes2Pos(3);
% handles.controlPaneWidth = axes2Pos(1);
% handles.axesGap = axes1Pos(2) - axes2Pos(2) - axes2Pos(4);
% handles.axesTitleBottomMargin = axes2Label1Pos(2) - axes2Pos(2) - axes2Pos(4);
% handles.axesTitleRightMargin = figurePos(3) - axes2Label1Pos(1) - axes2Label1Pos(3);
if primaryOn 
    primaryVis = 'on';
else
    primaryVis = 'off';
end

set(handles.axes1, 'Visible', primaryVis);
set(handles.axes1Label, 'Visible', primaryVis);

if secondaryOn
    if primaryOn && shouldCombine
        secondaryVis = 'off';
    else
        secondaryVis = 'on';
    end
else
    secondaryVis = 'off';
    cla(handles.axes2);
end

set(handles.axes2, 'Visible', secondaryVis);
set(handles.axes2Label, 'Visible', secondaryVis);

if primaryOn && secondaryOn 
    % Now it comes down to whether combine is on.
    if shouldCombine
        
       % Then we should have a single axes, with the label 'Combined'
       set(handles.axes1, 'Position', [axes1Pos(1), handles.bottomMargin, axesWidth, largeAxesHeight]);
       set(handles.axes1Label, 'Position', [figurePos(3) - handles.axesTitleRightMargin - axes1LabelPos(3), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes1LabelPos(3), axes1LabelPos(4)]);
       set(handles.axes1Label, 'String', 'Combined');
       
       set(handles.axes1NPVLabel, 'String', ['NPV: ', cur2str(handles.primaryNPV + handles.secondaryNPV, 0)]);
       set(handles.axes1NPVLabel, 'Position',[axes1NPVLabelPos(1), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes1NPVLabelPos(3), axes1NPVLabelPos(4)]);

        set(handles.axes1NPVLabel, 'Visible', 'on');
        set(handles.axes2NPVLabel, 'Visible', 'off');
    else
        % Then we have both axes with their 'Primary' and 'Secondary'
        % titles.
        set(handles.axes1, 'Position', [axes1Pos(1), handles.bottomMargin + smallAxesHeight + handles.axesGap, ...
                                        axesWidth, smallAxesHeight]);
        set(handles.axes1Label, 'Position', [figurePos(3) - handles.axesTitleRightMargin - axes1LabelPos(3), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes1LabelPos(3), axes1LabelPos(4)]);
        
        set(handles.axes2, 'Position', [axes2Pos(1), handles.bottomMargin, axesWidth, smallAxesHeight]);
        set(handles.axes2Label, 'Position', [figurePos(3) - handles.axesTitleRightMargin - axes2LabelPos(3), ...
                                        handles.bottomMargin + smallAxesHeight + handles.axesTitleBottomMargin, ...
                                        axes2LabelPos(3), axes2LabelPos(4)]);
                                    
        set(handles.axes1Label, 'String', 'Primary');
        set(handles.axes2Label, 'String', 'Secondary');
        
       set(handles.axes1NPVLabel, 'String', ['NPV: ', cur2str(handles.primaryNPV, 0)]);
       set(handles.axes1NPVLabel, 'Position',[axes1NPVLabelPos(1), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes1NPVLabelPos(3), axes1NPVLabelPos(4)]);

       set(handles.axes2NPVLabel, 'String', ['NPV: ', cur2str(handles.secondaryNPV, 0)]);
       set(handles.axes2NPVLabel, 'Position',[axes2NPVLabelPos(1), ...
                                        handles.bottomMargin + smallAxesHeight + handles.axesTitleBottomMargin, ...
                                        axes2NPVLabelPos(3), axes2NPVLabelPos(4)]);

        set(handles.axes1NPVLabel, 'Visible', 'on');
        set(handles.axes2NPVLabel, 'Visible', 'on');
    end

elseif ~primaryOn && secondaryOn 
    % Show only the secondary axes.
     
       set(handles.axes2, 'Position', [axes2Pos(1), handles.bottomMargin, axesWidth, largeAxesHeight]);
       set(handles.axes2Label, 'Position', [figurePos(3) - handles.axesTitleRightMargin - axes2LabelPos(3), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes2LabelPos(3), axes2LabelPos(4)]);
                                    
       set(handles.axes2NPVLabel, 'String', ['NPV: ', cur2str(handles.secondaryNPV, 0)]);
       set(handles.axes2NPVLabel, 'Position',[axes2NPVLabelPos(1), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes2NPVLabelPos(3), axes2NPVLabelPos(4)]);
                                    
       set(handles.axes2Label, 'String', 'Secondary');    
       set(handles.axes1NPVLabel, 'Visible', 'off');
       set(handles.axes2NPVLabel, 'Visible', 'on');
       
elseif primaryOn && ~secondaryOn 
    % Show only the primary axes.
    set(handles.axes1, 'Position', [axes1Pos(1), handles.bottomMargin, axesWidth, largeAxesHeight]);
    set(handles.axes1Label, 'Position', [figurePos(3) - handles.axesTitleRightMargin - axes1LabelPos(3), ...
                                    figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                    axes1LabelPos(3), axes1LabelPos(4)]);
                                
    set(handles.axes1NPVLabel, 'String', ['NPV: ', cur2str(handles.primaryNPV, 0)]);
    set(handles.axes1NPVLabel, 'Position',[axes1NPVLabelPos(1), ...
                                        figurePos(4) - handles.axesGap + handles.axesTitleBottomMargin, ...
                                        axes1NPVLabelPos(3), axes1NPVLabelPos(4)]);
    set(handles.axes1Label, 'String', 'Primary');    
    set(handles.axes1NPVLabel, 'Visible', 'on');
    set(handles.axes2NPVLabel, 'Visible', 'off');
        
else
    % They are both empty. 
    return    
end
    

% --- Executes on selection change in popupmenuUnitSelection.
function popupmenuUnitSelection_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuUnitSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuUnitSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuUnitSelection
handles.unit = handles.unitsAvailable(get(hObject, 'Value'));
guidata(hObject, handles);
refreshPlot(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuUnitSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuUnitSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuPlotType.
function popupmenuPlotType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPlotType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuPlotType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuPlotType

% If we're here the user has selected a plot type. Save it.
contents = get(hObject,'String');
handles.lastSavedPlotType = contents{get(hObject,'Value')};
guidata(hObject, handles);
refreshPlot(handles);

% --- Executes during object creation, after setting all properties.
function popupmenuPlotType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPlotType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editDiscountRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDiscountRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDiscountRate as text
%        str2double(get(hObject,'String')) returns contents of
%        editDiscountRate as a double
discRate = str2double(get(hObject, 'String'));
if isnan(discRate)
    set(hObject, 'String', num2str(handles.discountRate * 100));
else
    handles.discountRate = discRate / 100;
    guidata(hObject, handles);
    refreshPlot(handles);
end

% --- Executes during object creation, after setting all properties.
function editDiscountRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDiscountRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Calculate the NPV from the given data. The data is a 2xn array of dollar
% values covering n months, where the first row is taken to be at the start
% of the month and the second row is taken to be at the end of the month.
function NPV = calculateNPV(finData, discountRate)

    if isempty(finData)
        NPV = 0;
        return
    end
    
    months0 = 0:1:size(finData, 2)-1;
    months1 = 1:size(finData, 2);
    discStart = (1 + (discountRate / 12)) .^ months0;
    discEnd = (1 + (discountRate / 12)) .^ months1;
    discs = [discStart; discEnd];
    NPV = sum(sum(finData ./ discs));
    


% --- Executes on button press in pushbuttonWriteToAccess.
function pushbuttonWriteToAccess_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonWriteToAccess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.simMgr.writeSimToAccess


% --------------------------------------------------------------------
function uipushtoolExtractPlotData_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolExtractPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extractPlotData(handles.figure1, true)
