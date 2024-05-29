classdef CropCategory
   
    % A CropCategory defines a set of core events that may occur during
    % the lifecycle of any crop within this category. Also, a CropCategory
    % has a list of compatible growthModels that have been designed to work
    % with this category of crop and with the core events. For example, the
    % WoodyCoppicedCropCategory will have a Coppice Harvest as a core
    % event, so any growthModels in the list of growthModels for this
    % category will support the CoppiceHarvest event.
    
    properties
        % A String with the name of the category
        name
                
        % A list of Strings; the names of the core events for this
        % category.
        coreEvents
        
        % A list of Units; the types of Amounts that must be provided as
        % outputs by the growthModelDelegate, based on the state. The growthModel
        % may define extra cropOutputs, but must at least support the ones 
        % listed in cropOutputUnits. For example Biomass might be an
        % output.
        % Note that the list here is really only used to force a
        % growthModel to support them. The growthModel will provide it's
        % own list of outputUnits, which will provide the list to look up
        % when getting the cropOutputUnits.
        coreCropOutputUnits
        
        % A list of Units; the types of Amounts that must be provided as
        % outputs by the regimeDelegate. The growthModel will provide
        % products and outputs in terms of these units. (Eg per Ha, or Per
        % Tree)
        regimeOutputUnits
        
        % A list of GrowthModelDelegate class names that are compatible with this category. 
        growthModelDelegateClassNames
    
    end
    
    properties(Hidden)
       cropWizardImageFile
       cropWizardText
    end
    
    properties(Dependent)
       % Comes from the list of growthModels.
       growthModel 
       
       % The name of the growthModel
       growthModelChoice
       
       % List of possible growth model names and state descriptions, based on the
       % growthModelDelegateClassNames.
       % It returns a struct array with .name and .stateDescription fields.
       possibleGrowthModelDescriptions
       
        % A list of Units which contains those units that seem appropriate
        % for crops in this category to use when defining costs. For
        % example, the Woddy Plantation category may have Units of Tree, or Km of Belts as
        % possible units. These would not be available in the Annual
        % category.
        possiblePriceUnits
    end
    
    properties(Access = private)

        % List of GrowthModels. This array is only used for convenience in
        % the cropWizard.
        growthModels = GrowthModel.empty(1, 0)
        
        % Again, only used for convenience in the cropWizard
        growthModelIndex = 0
        
        % Used only for the cropWizard, but maintains a list of all
        % PriceModels that have been provided for this crop.
        priceModels = PriceModel.empty(1, 0)
    end
    
    methods (Static)
       
        function obj = loadobj(obj)
            if (strcmp(obj.name, 'Coppice Plantation'))
                obj.name = 'Coppice Tree Crop';
            end

            % Want to update the list of possible growthModels.
            updatedCat = CropCategory(obj.name);
            obj.growthModelDelegateClassNames = updatedCat.growthModelDelegateClassNames;
            obj.growthModel = obj.growthModel;
        end
    end
    
    methods
       
        function catObj = CropCategory(type)
            persistent cats   
           
                % We make a list of all the categories but select the one that
                % matches the name passed in.

                cats = [];
                if isempty(cats)
                    
                    catObj.name = 'Annual';
                    catObj.coreEvents = {'Planting', 'Harvesting'};
                    catObj.growthModelDelegateClassNames = {'RainfallBasedGrowthModelDelegate', ...
                                                            'FixedYieldGrowthModelDelegate', ...
                                                            'AnnualGrowthModelDelegate'};

                    units    = Unit('', 'Paddock', 'Unit');                
                    units(2) = Unit('', 'Area', 'Hectare');
                    % Might need to include 'tonnes of Grain' here later. 

                    catObj.coreCropOutputUnits = Unit.empty(1, 0);
                    catObj.regimeOutputUnits = units;

                    cats = catObj;
                    
                    catObj.name = 'Coppice Tree Crop';
                    catObj.coreEvents = {'Planting', 'Coppice Harvesting', 'Destructive Harvesting'};
                    catObj.growthModelDelegateClassNames = {'ABGompertzGrowthModelDelegate', 'FixedYieldGrowthModelDelegate'};                

                    units    = Unit('', 'Paddock', 'Unit');                
                    units(2) = Unit('', 'Area', 'Hectare'); 
                    units(3) = Unit('', 'Tree', 'Unit');
                    units(4) = Unit('', 'Belts', 'Km');
                    units(5) = Unit('', 'Rows', 'Km');
                    units(6) = Unit('', 'Crop Interface Length', 'm');

                    catObj.regimeOutputUnits = units;

                    units = Unit('', 'Above-ground Biomass', 'Tonne');
                    units(2) = Unit('', 'Below-ground Biomass', 'Tonne');
       %             units(3) = Unit('', 'Crop Interface Length', 'm');
                    
                    catObj.coreCropOutputUnits = units;

                    cats(2) = catObj;
                    
                    catObj.name = 'Pasture';
                    catObj.coreEvents = {'Establishment', 'Shearing', 'Sheep Sales', 'Destruction'};
                    catObj.growthModelDelegateClassNames = {'SimplePastureGrowthModelDelegate', 'GrassGroGrowthModelDelegate'};                

                    units    = Unit('', 'Paddock', 'Unit');                
                    units(2) = Unit('', 'Area', 'Hectare'); 
                    units(3) = Unit('', 'DSE', 'Unit');
                    
                    catObj.regimeOutputUnits = units;

                    units = Unit('', 'FOO', 'Tonne');
                    
                    catObj.coreCropOutputUnits = units;

                    cats(3) = catObj;
                end
                catObj = cats(strcmp({cats.name}, type));
            
            if isempty(catObj)
               disp('First argument passed to CropCategory constructor could not be matched to a known crop category.'); 
               catObj.name = '';
               catObj.coreEvents = {};
               catObj.growthModelDelegateClassNames = {};
            end
            
        end
        
        % Save the growth model to the list of saved growth models.
        function obj = set.growthModel(obj, gm)
            
            if isempty(gm)
                return
            end
            
            % Does the a growth model with the same name already exist? 
            ix = find(strcmp({obj.growthModels.name}, gm.name), 1);
            if isempty(ix)
               obj.growthModels(end + 1) = gm;
               obj.growthModelIndex = length(obj.growthModels);
            else
                obj.growthModels(obj.growthModelIndex) = gm;
            end
            
        end
        
        % Get the growth model from the list of saved growth models.
        function gm = get.growthModel(obj)
            if obj.growthModelIndex
                gm = obj.growthModels(obj.growthModelIndex);
            else
                gm = GrowthModel.empty(1, 0);
            end
        end
        
        % Returns the saved growthModel, or an empty array if it doesn't
        % exist.
        function gm = getSavedGrowthModel(obj, gmName)
            ix = find(strcmp({obj.growthModels.name}, gmName));
            if isempty(ix)
                gm = [];
            else
               gm = obj.growthModels(ix); 
            end            
        end

        % Gets the growth model name from the growthModel.
        function gmChoice = get.growthModelChoice(cat)
            if cat.growthModelIndex
                gmChoice = cat.growthModel.name;
            else
                gmChoice = '';
            end
        end
        
        % Swaps the growthModel from the list of growthModels based on the
        % new choice.
        function cat = set.growthModelChoice(cat, gmChoice)
                       
            gm = GrowthModel(gmChoice);
            if isempty(gm)
                disp('Unable to change growth model. Supplied growth model name is not a valid choice, at least for the current category.');
                return
            end
            
            % Find the growth model in the list if it exists.
            ix = find(strcmp({cat.growthModels.name}, gmChoice), 1);
            
            if ~isempty(ix)
                % Then set the new category
                cat.growthModelIndex = ix;
            else
                cat.growthModel = gm;
            end
        end % end set.growthModelChoice
        
        % Gets the growth model names and state descriptions from the const property of the
        % delegates. Uses the delegateClassNames to get to these.
        function gmDefs = get.possibleGrowthModelDescriptions(obj)
            gmNames = cell(size(obj.growthModelDelegateClassNames));
            gmStateDesc = gmNames;
            
            for i = 1:length(obj.growthModelDelegateClassNames)
                gmdMetaClass = meta.class.fromName(obj.growthModelDelegateClassNames{i});
                mpArray = findobj([gmdMetaClass.Properties{:}],'Name','modelName');
                
                if mpArray.HasDefault
                    gmNames{i} = mpArray.DefaultValue;
                else
                    gmNames{i} = '';
                end
                
                mpArray = findobj([gmdMetaClass.Properties{:}],'Name','stateDescription');
                  
                if mpArray.HasDefault
                    gmStateDesc{i} = mpArray.DefaultValue;
                else
                    gmStateDesc{i} = {};
                end
                
            end
            
            gmDefs = struct('name', gmNames, 'stateDescription', gmStateDesc);
            
        end
        
        % Use the definitions from the passed in priceModels, and match them to the
        % category's priceModels if possible. If they can be matched,
        % replace them. If not, leave them.
        function priceModels = getSavedPriceModelsFromDefinitions(obj, priceModels)
            for i = 1:length(priceModels)
                for j = 1:length(obj.priceModels)
                    if PriceModel.definitionMatches(obj.priceModels(j), priceModels(i))
                        priceModels(i) = obj.priceModels(j);
                        break;
                    end
                end
            end
        end % end getSavedPriceModelsFromDefinitions
        

        % Use the passed in priceModels, and match them to the
        % category's priceModels if possible. If they can be matched,
        % replace them. If not, add them.
        function obj = setSavedPriceModels(obj, priceModels)
            for i = 1:length(priceModels)
                matchFound = false;
                for j = 1:length(obj.priceModels)
                    if PriceModel.definitionMatches(obj.priceModels(j), priceModels(i))
                        obj.priceModels(j) = priceModels(i);
                        matchFound = true;
                        break;
                    end
                end
                if ~matchFound
                   obj.priceModels(end + 1) = priceModels(i); 
                end
            end
        end % end setSavedPriceModels
        
        % This function is used to update the name of a priceModel when the
        % event's name has changed, which is the case when we change the
        % name of an added financial event. The function returns true if it
        % successfully changed the name of the priceModel.
        function [obj, TF] = changePriceModelName(obj, origName, newName)
            ix = find(strcmp({obj.priceModels.name}, origName), 1, 'first');
            if isempty(ix)
               disp('Warning: Cannot find a priceModel with a matching name.');
               TF = false;
            else
                obj.priceModels(ix).name =newName;
                TF = true;
            end
        end
        
        % Returns a list of Units in which we could provide costs.
        % This list of units comes from the crop output units, the possible
        % regime units, and possible products. The crop output units and the product units come
        % from the growthModel. But the growth model list should contain at
        % least what is included in the core output units. The regime
        % output units are used directly.
        function pPUs = get.possiblePriceUnits(obj)
        
            % First in the list are the regime output units. Then the crop
            % output units, then the products with 'Harvested ' prefixing
            % the units.
            
            regUnits = obj.regimeOutputUnits;
            cropUnits = obj.growthModel.growthModelOutputUnits;
            productUnits = [obj.growthModel.productPriceModels.denominatorUnit];
            
            pPUs = [regUnits, cropUnits, productUnits];
            
        end
        
        function pPUSs = getPossiblePriceUnitStrings(obj)

            regUnits = obj.regimeOutputUnits;
            cropUnits = obj.growthModel.growthModelOutputUnits;
            productUnits = [obj.growthModel.productPriceModels.denominatorUnit];
            
            productUnitStrings = cell(1, length(productUnits));
            for i = 1:length(productUnits)
                productName = obj.growthModel.productPriceModels(i).name;
                nameLength = length(productName);
                if productName >= 7
                    if strcmp(productName((nameLength - 6):nameLength), ' Income')
                        productName = productName(1:(nameLength-7));
                    end
                end                        
                productUnitStrings{i} = [productUnits(i).readableDenominatorUnit, ' (', productName, ')'];
            end
            pPUSs = [{regUnits.readableDenominatorUnit, cropUnits.readableDenominatorUnit}, productUnitStrings];
        end
    end
    

    methods (Static)
        
        % A Static method to produce a list of all the CropCategories
        function cats = setupCategories()
           cats(1) = CropCategory('Annual');
           cats(2) = CropCategory('Coppice Tree Crop');
           cats(3) = CropCategory('Pasture');
        end
    
        % We want the Crop passed to the cropWizard to be up-to-date, that is it
        % should be in a state such that the crop can be populated.
        function cats = getCurrentCropCategories(existingCats)

            % Validate the input. Should be an array of CropCategories.
            if ~isa(existingCats, 'CropCategory')
                cats = CropCategory.empty(1, 0);
                return
            end
            
            % One of the things we want to do is go through the list of categories in
            % the crop

            cats = CropCategory.setupCategories();

            for i = 1:length(cats)

                % For each category in setupCategories, we want to use the crop's category if possible.
                % First check that there's one that matches in name.
                ix = find(strcmp({existingCats.name}, cats(i).name), 1);

                if ~isempty(ix)
                    % Then we've got a match. Use that category, but update it's public
                    % details.
                    existingCats(ix).growthModelDelegateClassNames = cats(i).growthModelDelegateClassNames;
                    existingCats(ix).coreEvents = cats(i).coreEvents;
                    cats(i) = existingCats(ix);        
                end
            end
        end % end getCurrentCropCategories
        
    end
    
end