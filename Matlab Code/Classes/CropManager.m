classdef (Sealed = true) CropManager < handle
   
    % The CropManager maintains the list of crops to be used in Imagine,
    % and is responsible for adding, editting, and removing crops.
    
    % Not sure if we want other objects to be able to get at the crops yet.
    
    % Not sure if we want events on properties that may be relevant to the
    % ImagineWindow. We might want to put them in the crop itself. Not
    % sure. It would be nice if when a crop colour is changed via the crop
    % dialogue that the ImagineWindow hears the change and updates the
    % colour 'automatically'.
    
    % Yes - it is the crop manager that should notify of crop changes. The
    % cropManager notifies the ImagineWindow manager. So... Managers talk
    % to Managers, and the things they manage, and not much else. And they
    % only talk to Managers by notifying of an event, and the other Manager
    % listening.
    
    % Implement a singleton class.
    methods (Access = private)
        function cropMgr = CropManager()
        end
        
        % Put code that would normally appear in the constructor in here.
        function cropManagerConstructor(obj)
        
        end
    end
    
    methods (Static)
        function singleObj = getInstance(loadedObj)
            persistent localObj
            
            % If a CropManager is passed in and is not the localObj,
            % then set it as the localObj.
            if nargin >= 1
                if isa(loadedObj, 'CropManager') && localObj ~= loadedObj
                    localObj = loadedObj;
                else
                    disp('Tried passing an object that''s not a CropManager to CropManager.getInstance.');
                end
            end
            
%             disp(['CropManager is empty: ',  num2str(isempty(localObj))]);
%             if ~isempty(localObj)
%                 disp(['CropManager is valid: ',  num2str(isvalid(localObj))]);
%             end
            if isempty(localObj) || ~isvalid(localObj)
                localObj = CropManager;
                localObj.cropManagerConstructor;
            end
                singleObj = localObj;
        end
    end
    
    
    properties (Access = private)
        % A list of crops currently in Imagine. They should all be valid
        % crops.
        crops = Crop.empty(0, 0);
    end

    properties (Dependent)
        cropCount
        cropNames
        cropDefinitions
    end
        
    events
        % Many of these events should pass a new crop list in the eventdata.
        
       CropAdded % Means we should add a crop to the list.
       CropRemoved % Will mean the name should be removed in the window.
              
       % Means that an edit has occured. 
       % Name, colour, category could have changed. 
       % This one might just contain a structure that 
       % has relevant editted fields... (Changed to what? From what?)
       CropEditted
       
       % In handler for CropEditted we may trigger these three events.
       CropCategoryChanged  % Will affect any regimes the crop was in.
       CropColourChanged % Will mean the ImagineWindow should use different colour.
       CropNameChanged % Will mean the crop list should be updated.
    end
    
    methods
        
        function cropCount = get.cropCount(cm)
           cropCount = length(cm.crops);
        end
        
        function cropNames = get.cropNames(cm)
            cropNames = {cm.crops.name};
        end
        
        % Add a new crop from scratch
        function addCrop(cm)
            % This function must create the crop wizard dialogue, wait for
            % the result and then store it if it returns a valid crop.
     
            newCrop = cropWizard([], cm.cropNames);
            
            if isempty(newCrop)
              
            elseif Crop.isValid(newCrop)
                cm.addCropObject(newCrop);
            else
                error('The cropWizard returned an object that the Crop class deemed invalid.');
            end
            
        end

        function addCropObject(cm, newCrop)
            cm.crops(end+1) = newCrop;
            cm.sortCrops;

            % Broadcast the event
            evtData = CropListChangedEventData(cm.cropNames, '', newCrop.name);
            notify(cm, 'CropAdded', evtData);            
        end

        
        % Edit an existing crop
        function editCrop(cm, c)
            % This function should work the same as addCrop, but passes the
            % existing crop to the crop wizard, then replaces the old crop
            % if the dialogue retuns a valid crop.
            
            % We let the user pass the index of the crop, or it's name if desired.
            if isnumeric(c)
                if c >= 1 && c <= cm.cropCount
                   cropIndex = c;
                else
                    error('Crop index passed is out of bounds.');
                end
            elseif ischar(c)
                cropIndex = find(strcmp(cm.cropNames, c), 1); 
                if isempty(cropIndex)
                    error('Cannot find crop with matching name to edit.');
                end
            else
                error('Problem determining which crop to edit. Must pass the index of the crop, or it''s name. Argument was neither a string nor a numeric.');
            end
            
            % Now, a Crop is a handle class, so we want to make sure that
            % the handle for the crop stays the same in case other objects
            % refer to it.
            % However, we don't want the wizard to save all it's changes
            % directly to that handle. So we duplicate the Crop, edit that,
            % then if it's saved we absorb the new parameters into the
            % handle, and if it's cancelled, we discard the duplicate.
            cropToEdit = cm.crops(cropIndex);
            try 
                delete('croptemp.mat');
            catch e
            end
            save ('croptemp.mat', 'cropToEdit');
            loadS = load('croptemp.mat');
            dupCrop = loadS.cropToEdit;
            clear loadS
            try 
                delete('croptemp.mat');
            catch e
            end
            
            % We pass the list of crop names so that the wizard can check
            % that we don't assign an existing name to the editted crop.
            newCrop = cropWizard(dupCrop, cm.cropNames);
            
            
            if Crop.isValid(newCrop)
                
                cm.replaceCrop(cropToEdit.name, newCrop);
                
%                 % then replace the crop.
%                 previousName = cropToEdit.name;
% 
%                 cropToEdit.absorb(newCrop);
%                 cm.sortCrops;
%                 
%                 % ImagineWindowManager should register to hear about this
%                 % event
%                 % Also the RegimeManager so it can update it's crop's names
%                 % if necessary.
%                 % Probably, each delegate should implement a
%                 % updateChangedCropName method or something.
%                 evtData = CropListChangedEventData(cm.cropNames, previousName, newCrop.name);
%                 notify(cm, 'CropEditted', evtData);
%             
%                 if ~strcmp(previousName, newCrop.name)
%                     evtData = CropNameChangedEventData(previousName, newCrop.name);
%                     notify(cm, 'CropNameChanged', evtData);
%                     
%                     for c = cm.crops
%                        c.growthModel.cropNameHasChanged(previousName, newCrop.name); 
%                     end
%                     
%                 end
%                     
%                 if ~strcmp(cropToEdit.categoryChoice, newCrop.categoryChoice)
%                     evtData = CropCategoryChangedEventData(cm.cropNames, previousName, newCrop.name, cropToEdit.categoryChoice, newCrop.categoryChoice);
%                     notify(cm, 'CropCategoryChanged', evtData);
%                 end
%                     
%                 if ~all(cropToEdit.colour == newCrop.colour)
%                     evtData = CropListChangedEventData(cm.cropNames, previousName, newCrop.name, cropToEdit.colour, newCrop.colour);
%                     notify(cm, 'CropColourChanged', evtData);
%                 end
                
            elseif isempty(newCrop)
                % must have cancelled.
            else
                error('The cropWizard returned an object that the Crop class deemed invalid.');
            end
            
        end
        
        function replaceCrop(cm, originalCropName, replacementCrop)

            % We let the user pass the index of the crop, or it's name if desired.
            cropIndex = find(strcmp(cm.cropNames, originalCropName), 1); 
            if isempty(cropIndex)
                error('Cannot find crop with matching name to edit.');
            end

            cropToEdit = cm.crops(cropIndex);
            
            try 
                delete('croptemp.mat');
            catch e
            end
            save ('croptemp.mat', 'cropToEdit');
            loadS = load('croptemp.mat');
            dupCrop = loadS.cropToEdit;
            clear loadS
            try 
                delete('croptemp.mat');
            catch e
            end
            
            if Crop.isValid(replacementCrop)
                % then replace the crop.
                previousName = cropToEdit.name;

                cropToEdit.absorb(replacementCrop);
                cm.sortCrops;
                
                % ImagineWindowManager should register to hear about this
                % event
                % Also the RegimeManager so it can update it's crop's names
                % if necessary.
                % Probably, each delegate should implement a
                % updateChangedCropName method or something.
            
                if ~strcmp(previousName, replacementCrop.name)
                    evtData = CropNameChangedEventData(previousName, replacementCrop.name);
                    notify(cm, 'CropNameChanged', evtData);
                    
                    for c = cm.crops
                       c.growthModel.cropNameHasChanged(previousName, replacementCrop.name); 
                    end
                    
                end
                    
                if ~strcmp(dupCrop.categoryChoice, replacementCrop.categoryChoice)
                    evtData = CropCategoryChangedEventData(previousName, replacementCrop.name, dupCrop.categoryChoice, replacementCrop.categoryChoice);
                    notify(cm, 'CropCategoryChanged', evtData);
                end
                    
                if ~all(dupCrop.colour == replacementCrop.colour)
                    evtData = CropColourChangedEventData(previousName, replacementCrop.name, dupCrop.colour, replacementCrop.colour);
                    notify(cm, 'CropColourChanged', evtData);
                end
                
                % Have to do this last. The previous notifications can be
                % used to update underlying data, whereas this one kind of
                % assumes all the data is up to date.
                evtData = CropListChangedEventData(cm.cropNames, previousName, replacementCrop.name);
                notify(cm, 'CropEditted', evtData);

            end
           
        end
        
        % Removes a crop.
        function removeCrop(cm, cropName, force)
            % Checks that the user wants to remove the crop.
            % Generates a message that explains which regimes the crop is
            % in, and that the regimes will be deleted as well.
            % If all ok, the crop is removed.
            
            if nargin < 3
               % Optional flag to disable checks for removal.
                force = false;
            end
            
            cropIndex = find(strcmp(cropName, {cm.crops.name}), 1, 'first');
          
            if(isempty(cropIndex))
               disp('Can''t find crop to remove.');
                return
            end

            % Check if the crop is used in any of the regimes.
            regimeMgr = RegimeManager.getInstance;
            usedRegimeDefinitions = regimeMgr.regimesThatUseCrop(cropName);
            regimesWithCrop = {};
            
            if ~isempty(usedRegimeDefinitions)
                regimesWithCrop = {usedRegimeDefinitions.regimeLabel};
                regimesWithCrop = sort(regimesWithCrop);

                if (force)
                    button = 'Yes';
                else
                    qstring = {['The selected crop (', cropName, ') is used in the following regime(s):',], '',...
                       char(regimesWithCrop), ...
                    '', 'Removing this crop will ALSO REMOVE THESE REGIMES!', '', 'Are you sure you want to continue?'};
                    button = questdlg(qstring, 'Confirm Crop and Regime Removal', 'Yes', 'No', 'No');
                end
                
                if(strcmp(button, 'No'))
                    return
                else
                    % Then remove all the regimes with this crop and force
                    % it since we've already asked.
 %                   for i = 1:length(regimesWithCrop)
   %                     regimeMgr.removeRegime(regimesWithCrop{i}, true);
    %                end
                end
            end

            if (force)
                button = 'Yes';
            else
                qstring = ['This action will remove the ', cropName, ' crop from Imagine. Are you sure you want to continue?'];
                button = questdlg(qstring, 'Confirm Crop Removal', 'Yes', 'No', 'No');
            end
            
            if(strcmp(button, 'No'))
               return 
            end

            cropObj = cm.crops(cropIndex);
            cm.crops = [cm.crops(1:cropIndex - 1) cm.crops(cropIndex + 1: end)];
            delete(cropObj);

            % Notify that the crop has been deleted.
            evtData = CropListChangedEventData(cm.cropNames, cropName, '');
            evtData.forceRegimeRemoval = true;
            evtData.regimesToRemove = regimesWithCrop;
            notify(cm, 'CropRemoved', evtData);            
        end
        
        % Loads a crop from a .mat file.
        function loadCrop(cm, path, file)
            % If the crop already exists in the list, it replaces it.
            % Otherwise the crop is added.
            cropData = load([path, file]);

            % Can customise the load process here. This can be used for backward
            % compatability.

            if isfield(cropData, 'crop')
                if strcmp(class(cropData.crop), 'Crop')
                    crop = cropData.crop;
                end
            end
            
            names = {cm.crops.name};
            if(Crop.isValid(crop) || true)
                if ismember(crop.name, names)
                   cm.replaceCrop(crop.name, crop);
                else
                   cm.addCropObject(crop);
                end
            else
                error(['Invalid crop file at ' path, file]);
            end
            
        end
        
        % Saves a crop as a .mat file.
        function saveCrop(cm, cropName, path, file)
            % Save the crop with name cropName to a .mat file
            % at the specified path and file name.            
            crop = cm.crops(strcmp({cm.crops.name}, cropName));
            
            if Crop.isValid(crop)                
                filename = [path, file];
                save(filename, 'crop');
            end
            
        end
        
        % Just orders the crops alphabetically according to name.
        function sortCrops(cm)
            names = {cm.crops.name};
            [~, IX] = sort(names);
            cm.crops = cm.crops(IX);
            
        end
        
        
        % Constructs an array of crop defintiions.
        function cropdefs = get.cropDefinitions(cropMgr)
            
            names = cropMgr.cropNames;
            categoryNames = {cropMgr.crops.categoryChoice};
            colours = {cropMgr.crops.colour};
            % NOTE - Need to sort out the full list of events.
            %imagineEvents = {cropMgr.crops.growthModelEvents};
            
            cropdefs = struct('name', names, 'categoryName', categoryNames, 'colour', colours);%, 'imagineEvent', imagineEvents);
        end
        
        % This function returns a PlantedCrop as requested.
        % It is intended to be called from InstalledRegime when a crop's
        % initialisation trigger has been triggered.
        function pC = getPlantedCrop(cropMgr, cropName, installedRegime, sim, initialisationEventIndex)
            cropHandle = cropMgr.crops(strcmp({cropMgr.crops.name}, cropName));
            pC = PlantedCrop(cropHandle, installedRegime, sim, initialisationEventIndex);
        end
        
        % Returns a list of the ImagineEvents listed as the
        % initialisationEvents for the given crop.
        function initEvents = getCropsInitialEvents(cropMgr, cropName)
            strcmp({cropMgr.crops.name}, cropName)
            assignin('base', 'crops', cropMgr.crops)
            initEvents = cropMgr.crops(strcmp({cropMgr.crops.name}, cropName)).growthModel.growthModelInitialEvents;
            
        end
        
        % This function returns the full list of events for a given crop.
        % It includes the growthModel events and the extra financial
        % events.
        function es = getCropsEvents(cropMgr, cropName)
           es = cropMgr.crops(strcmp({cropMgr.crops.name}, cropName)).growthModel.growthModelEvents;
           es = [es cropMgr.crops(strcmp({cropMgr.crops.name}, cropName)).financialEvents];
        end
        
        % Function returns a cell array with entries corresponding to the
        % crop names provided. Each cell contains the units of the products
        % the crop can produce. cropNames can either be a single name (a string) or a
        % cell array of crop name strings.
        function pUs = getCropsProductUnits(cropMgr, cropNames)
           
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   pUs{i} = cropMgr.crops(cropIndex).growthModel.productUnits; 
                end                
            end
            
        end
        
        % Function returns a cell array with entries corresponding to the
        % crop names provided. Each cell contains the units of the outputs
        % the crop can produce. cropNames can either be a single name (a string) or a
        % cell array of crop name strings.
        function oUs = getCropsOutputUnits(cropMgr, cropNames)
           
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   oUs{i} = cropMgr.crops(cropIndex).growthModel.growthModelOutputUnits; 
                end                
            end
            
        end
        
        % Function returns a cell array with entries corresponding to the
        % crop names provided. Each cell contains the rates of the outputs
        % the crop can produce. cropNames can either be a single name (a string) or a
        % cell array of crop name strings.
        function oRs = getCropsOutputRates(cropMgr, cropNames)
           
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   oRs{i} = cropMgr.crops(cropIndex).growthModel.growthModelOutputRates; 
                end                
            end
            
        end

        % Function returns a cell array with entries corresponding to the
        % crop names provided. Each cell contains the rates of the outputs
        % the crop can produce. cropNames can either be a single name (a string) or a
        % cell array of crop name strings.
        function rUs = getCropsRegimeUnits(cropMgr, cropNames)
           
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   rUs{i} = cropMgr.crops(cropIndex).category.regimeOutputUnits; 
                end                
            end
            
        end
        
        function [products, rates] = getCropsProductAndOutputRatesForEvent(cropMgr, cropNames, eventName)
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   [cropProducts, cropRates] =  cropMgr.crops(cropIndex).growthModel.getProductAndOutputRatesForEvent(eventName);
                   products{i} = cropProducts;
                   rates{i} = cropRates;
                end                
            end
            
        end
        
        function rates = getCropsPropagationProductRates(cropMgr, cropNames)
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                        
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   rates{i} = cropMgr.crops(cropIndex).growthModel.getPropagationProductRates;
                end                
            end            
        end

        function units = getCropsEventOutputUnits(cropMgr, cropNames)            
            
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
            
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   % Get the supportedImagineEvents from the growth model
                   % and test each event to get the eventOutput rates.
                   eventNames = cropMgr.crops(cropIndex).growthModel.supportedImagineEvents;
                   allEventOutputRates = Rate.empty(1, 0);
                   for j = 1:length(eventNames)
                      [~, eventOutputRates] = cropMgr.crops(cropIndex).growthModel.eventTransition(eventNames{j}, [], []);
                      allEventOutputRates = [allEventOutputRates, eventOutputRates];
                   end               
                   units{i} = [allEventOutputRates.unit];
                end                
            end
        end

        function rates = getCropsEventOutputRates(cropMgr, cropNames)
            if isa(cropNames, 'char')
                cropNames = {cropNames};
            end
                       
            for i = 1:length(cropNames)
               
                cropIndex = find(strcmp(cropNames{i}, cropMgr.cropNames), 1, 'first');
                if isempty(cropIndex)
                    error('Can''t find the crop name in the list of crops.');
                else
                   % Get the supportedImagineEvents from the growth model
                   % and test each event to get the eventOutput rates.
                   eventNames = cropMgr.crops(cropIndex).growthModel.supportedImagineEvents;
                   allEventOutputRates = Rate.empty(1, 0);
                   for j = 1:length(eventNames)
                      [~, eventOutputRates] = cropMgr.crops(cropIndex).growthModel.eventTransition(eventNames{j}, [], []);
                      allEventOutputRates = [allEventOutputRates, eventOutputRates];
                   end                   
                   rates{i} = allEventOutputRates;
                end                
            end
        end
        
        % generatePrices goes through all the crops and all their costs and
        % products and produces a productPriceTable and costPriceTable
        function [costPriceTable, productPriceTable, costPriceModelTable, productPriceModelTable] = generatePrices(cropMgr)

            % The format for both is
            % priceTable.(cropName).(eventName/productName) and that will
            % be an array of prices for each year.
            productPriceTable = {};
            costPriceTable = {};       
            productPriceModelTable = {};
            costPriceModelTable = {};
            imOb = ImagineObject.getInstance;
                
            for i = 1:length(cropMgr.crops)
               
                % For each crop create the entry in productPriceTable and
                % costPriceTable.
                cropName = underscore(cropMgr.crops(i).name);
                productPriceTable.(cropName) = {};
                costPriceTable.(cropName) = {};                
                productPriceModelTable.(cropName) = {};
                costPriceModelTable.(cropName) = {};                
                
                gmEvents = cropMgr.crops(i).growthModel.growthModelEvents;
                allEvents = [gmEvents, cropMgr.crops(i).financialEvents];
                for j = 1:length(allEvents)
                    eventName = allEvents(j).name;

                    [m,v,s] = allEvents(j).costPriceModel.trend.createTrendSeries(imOb.simulationLength);
                    
                    % There's a better way to do this, but for now we'll
                    % copy everything into the costPriceTable. Ideally we
                    % would not be storing the units every time.
                    yearlyPrices = Rate(s, allEvents(j).costPriceModel.unit, allEvents(j).costPriceModel.denominatorUnit);
                    costPriceTable.(underscore(cropName)).(underscore(eventName)) = yearlyPrices;
                    
                    % The cost price model table gives a list of NormDists
                    % that the costs in the cost price table have been
                    % sampled from.
                    costPriceModelTable.(underscore(cropName)).(underscore(eventName)) = NormDist.init(m, v);                    
                end
                
                % Get the productPriceModels for this crop.
                gmProductPriceModels = cropMgr.crops(i).growthModel.productPriceModels;
                
                % For products, preallocate the pxm array of rates...
                productRates(length(gmProductPriceModels), imOb.simulationLength) = Rate; %#ok<AGROW>
                
                % The plan is to work out one row of rates, then set that
                % row in the productRates array.
                for j = 1:length(gmProductPriceModels)

                    [m,v,s] = gmProductPriceModels(j).trend.createTrendSeries(imOb.simulationLength);
                    
                    yearlyPrices = Rate(s, gmProductPriceModels(j).unit, gmProductPriceModels(j).denominatorUnit);
                    productRates(j, :) = yearlyPrices; %#ok<AGROW>
                    productRateModels(j, :) = NormDist.init(m, v); %#ok<AGROW>
                end
                
                productPriceTable.(cropName) = productRates(1:length(gmProductPriceModels), :);
                productPriceModelTable.(cropName) = productRateModels(1:length(gmProductPriceModels), :);

            end
            
        end

        
    end
    
    
end