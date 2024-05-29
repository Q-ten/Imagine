% This is a template for a concrete FixedYieldGrowthModelDelegate based on the
% Abstract class.
%
% The FixedYieldGrowthModelDelegate keeps its data in the
% propagationParameters field as described below.
% Outputs are produced each month. Products are produced whenever they are
% non-zero.
classdef FixedYieldGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties
        modelName = 'Fixed Yield'; 
        
        % A list of strings with the names of the CropCategories that this
        % GrowthModel will be appropriate to model.
        supportedCategories = {'Annual'};
                   
        % This will be a string cell array with descriptions of each
        % element of the state. Usually just one or two words - more labels
        % than descriptions.
        stateDescription = {'Yield'};
       
    end
           
    properties
                
        % The ImagineEvents for this growth model. This is where the triggers will be stored, 
        % but the functions will also be defined in here.
        % You should define a function that returns the default list of
        % growthModelEvents. These should match the transitionFunctions
        % you've defined for each event.
       
        growthModelInitialEvents
        growthModelRegularEvents
        growthModelDestructionEvents        
        growthModelFinancialEvents = ImagineEvent.empty(1, 0);
        
        % productPriceModels - a PriceModel for each product that can be
        % produced by this growthModel. The Units of the products are found
        % as the denominator of the PriceModels. 
        % When a product is produced, the Amount's unit can be used to work
        % out which price to use. It will match the denominator unit. (The
        % numerator will be in currency, probably $).
        %
        % We could think about keeping copies of past priceModels in case
        % we accidentally delete the product and therefore the priceModel,
        % but for now we keep it simple.
        productPriceModels
    end
    
    properties (Dependent)

        % growthModelOutputUnits - a list of Units that provide list of the
        % types of outputs the growthModel provides when passed the state
        % of a PlantedCrop. This list should include the union of all the
        % coreCropOutputUnits provided by the cropCategorys that this
        % growthModel supports.
        %
        % These will come from calling calculateOutputs with an argument. 
        growthModelOutputUnits
        
        % growthModelOutputRates - a list of 0 rates that provide the
        % rate units that come out of the calculateOuputs function.
        % The rates can be important if you need to know how the
        % denominator will come out.
        % There is a case where the denominator will be nothing or just
        % 'unit' when it doesn't make sense for the rate to be a rate, but
        % an amount. Eg, height of Wheat. Doesn't make sense to divide by
        % Hectares. Or even more starkly - colour of wheat. This is a
        % weird but possibly useful output, but would be silly for it to be a rate.
        %
        % These will come from calling calculateOutputs with an argument.
        growthModelOutputRates 
 
                
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Access = private)
        % Maintain a list of priceModels that have been defined.
        % If we set up a new product, we check if it has a priceModel in
        % this list before creating a new priceModel for it.
        internalPriceModelList 
    end

    % These are the Fixed Yield model specific properties.
    % All the data for the model is defined in here.
    properties (Access = public)
        
        propagationParameters
        
        % propagationParameters will be provided by the GUI and will
        % contain product series and output series as well as the numerator
        % and denominator units for the rates these are output in.
        
%         propagationParamaters.products.(productName).series
%         propagationParamaters.products.(productName).unit
%         propagationParamaters.products.(productName).denominatorUnit
%         propagationParamaters.products.(productName).spatiallyModified
%         propagationParamaters.products.(productName).temporallyModified
% 
%         propagationParamaters.outputs.(outputName).series
%         propagationParamaters.outputs.(outputName).unit
%         propagationParamaters.outputs.(outputName).denominatorUnit
%         propagationParamaters.outputs.(outputName).spatiallyModified
%         propagationParamaters.outputs.(outputName).temporallyModified
%         
    end
    
    properties (Access = private)
        % This boolean is set when constructed and remains fixed.
        % It can be accessed by the getter.
        private_modifierAware
    end
    
    properties (Dependent)
        modifierAware
    end
    
    methods
        function TF = get.modifierAware(obj)
           TF = obj.private_modifierAware; 
        end
    end
    
    methods
    
        % These methods are required from the Abstract parent class
        % GrowthModelDelegate.
        
        % This is the constructor for the concrete subclass. It should set
        % up all the parent's Abstract properties here, then go on to setup
        % any parameters specific to the concrete subclass.
%        function gmDel = FixedYieldGrowthModelDelegate(gm, modifierAware)
        function gmDel = FixedYieldGrowthModelDelegate(modifierAware)
%             if nargin > 0
%                 super_args = {gm};
%             else
%                 super_args = {};
%             end
%                         
%             gmDel = gmDel@GrowthModelDelegate(super_args{:});
            
            if nargin > 0
                gmDel.private_modifierAware = modifierAware;
            else
                gmDel.private_modifierAware = false;
            end
            
            % Now set up the specific default parameters for this growth model.
            
            % The priceModels, events and outputUnits need to be set up
            % here.
            [init, reg, dest] = makeFixedYieldImagineEvents;
            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            % To start with we can't say what the products are. That will
            % only come after the growthModel has been defined.
            gmDel.productPriceModels = PriceModel.empty(1, 0);
            %makeFixedYieldProductPriceModels(gmDel);
            
%             % Make the rainfall based output units by calling the calculate
%             % outputs function with an empty state and a third argument.
%             gmDel.calculateOutputs([], 'rate');
            
            
        end
        
        % This function propagates the state over one month. This should be
        % set up as appropriate to the concrete subclass.
        % Need to return the state - not set it in plantedCrop as we have
        % to change the month day before we set the state.
        %
        % In the FixedYieldGrowthModel the products are produced in the
        % propagation (here) rather than in a harvest function because
        % there is no way to know beforehand what events will be needed for
        % a particular crop. It would be nice if this class could be used
        % for all cropCategories.
        %
        % Products are simply all the non-zero entries in the product
        % series.
        % Outputs are returned in full each month.
        function [newState, productRates] = propagateState(gmDel, plantedCrop, sim)        

                        
            if isempty(gmDel.propagationParameters)
                newState = [];
                productRates = Rate.empty(1, 0);
                return
            end
            
            % Return the potential products if plantedCrop and sim are
            % empty.
            if (isempty(sim) && isempty(plantedCrop))  
                if isstruct(gmDel.propagationParameters.products)
                    fns = fieldnames(gmDel.propagationParameters.products);
                    for i = 1:length(fns)
                            denominatorUnit = gmDel.propagationParameters.products.(fns{i}).denominatorUnit;
                            numeratorUnit = gmDel.propagationParameters.products.(fns{i}).unit;
                            productRates(i) = Rate(0, numeratorUnit, denominatorUnit);
                    end
                end
                newState = [];
                return
            end                                
            
            % For the fixed yield price models, we need to create a column
            % of outputs - that's the state that can be directly returned
            % by calculateOuputs.
            if isstruct(gmDel.propagationParameters.outputs)
                fns = fieldnames(gmDel.propagationParameters.outputs);
                if (~isempty(fns))
                    outputsCol(length(fns), 1) = Rate();
                    for i = 1:length(fns)
                        denominatorUnit = gmDel.propagationParameters.outputs.(fns{i}).denominatorUnit;
                        numeratorUnit = gmDel.propagationParameters.outputs.(fns{i}).unit;
                        outputsCol(i, 1) = Rate(gmDel.propagationParameters.outputs.(fns{i}).series(sim.monthIndex), numeratorUnit, denominatorUnit);
                    end

                    newState = outputsCol;            
                else
                    newState = Rate.empty(1, 0);                    
                end
            else
                newState = Rate.empty(1, 0);
            end
            
            % For the fixed yield price models, we need to create one for each
            % product described in the propagationParameters.
            if isstruct(gmDel.propagationParameters.products)
                fns = fieldnames(gmDel.propagationParameters.products);
                if (~isempty(fns))
                    outputProducts(length(fns), 1) = Rate;
                    for i = 1:length(fns)
                        denominatorUnit = gmDel.propagationParameters.products.(fns{i}).denominatorUnit;
                        numeratorUnit = gmDel.propagationParameters.products.(fns{i}).unit;
                        outputProducts(i) = Rate(gmDel.propagationParameters.products.(fns{i}).series(sim.monthIndex), numeratorUnit, denominatorUnit);
                    end

                    productRates = outputProducts(outputProducts.number > 0);
                else
                    productRates = Rate.empty(1,0);
                end
            else
                productRates = Rate.empty(1,0);
            end                        
        end
        
        % This function is responsible for setting up all the parameters
        % particular to the concrete subclass. It will probably launch a
        % GUI which will be passed the GrowthModelDelegate and the GUI will
        % alter the pubilc parameters that are available to it when it is
        % saved.
        function gmDel = setupGrowthModel(gmDel, cropName)
                    
            cropInfo.cropType = 'Annual';
            cropInfo.cropName = cropName;
            [outputA, outputB] = FixedYieldGrowthModelDialog(cropInfo, gmDel.propagationParameters, gmDel.modifierAware);
            if ~isempty(outputA)
%                 gmDelOutput = output{1};
%                 nameRemap = output{2};
                gmDel.propagationParameters = outputA;
                gmDel.makeFinancialEvents(outputB);
            end
            
            % Now we need to make sure that the priceModels are ok.
            % Let's not delete price models. If we go into the growthModel
            % setup and delete some product and then add it again, it would
            % be nice if we could keep the priceModels we had defined
            % before.
            gmDel.refreshPriceModelList(outputB);
            
        end
        
        % The FixedYieldGrowthModel provides financial events so that
        % whenever a product is produced, a cost can be associated with
        % that production. Users can redefine these such that they never
        % occur. In the costs page of the crop wizard, perhaps we can get
        % it to check for events that never occur and remove them. Or
        % potentially, we could ask the user to check a box in the
        % FixedYieldGM dialog to say that a cost should or should not be
        % created. Either way, this function will be required and should be
        % called after a growth model returns.
        function makeFinancialEvents(gmDel, nameRemap)
            if isempty(gmDel.propagationParameters)
               gmDel.growthModelFinancialEvents = ImagineEvent.empty(1, 0); 
            end
            
            % If the nameRemap is supplied, first go through and rename the
            % financial events if they already exist.
            if nargin == 2
                if ~isempty(nameRemap)                    
                    finEventNames = {gmDel.growthModelFinancialEvents.name};
                    for i = 1:size(nameRemap, 1)
                        % Try to find the name in the existing financial
                        % events. It really should be there.
                        ix = find(strcmp([nameRemap{i, 1}, ' Production'], finEventNames), 1, 'first');
                        if ~isempty(ix)
                            gmDel.growthModelFinancialEvents(ix).name = [nameRemap{i, 2}, ' Production'];
                            gmDel.growthModelFinancialEvents(ix).costPriceModel.name = [nameRemap{i, 2}, ' Production'];
                        else
                           % Really should have found the name...
                           error('Renamed product''s original name couldn''t be found as a financial event. Suggests a logic error somewhere.');
                        end
                    end
                end
            end
            
            % If the product already has a corresponding financial event,
            % keep that, and make sure the trigger is correct. If it
            % doesn't exist, get rid of it.
            % To do this we will create a new list of ImagineEvents, but
            % where we can reuse an existing one, we will do so. The ones
            % that are left over, we'll delete (in case there's a reference
            % to them somewhere - this deletion is probably not necessary).
            newFinEvents = ImagineEvent.empty(1, 0);
            if ~isempty(gmDel.propagationParameters.products)
                fns = fieldnames(gmDel.propagationParameters.products);
            else
                fns = {};
            end
            finEventNames = {};
            if ~isempty(gmDel.growthModelFinancialEvents)
                finEventNames = {gmDel.growthModelFinancialEvents.name};
            end
            % Start by asuming they'll all be delete, then spare the ones
            % we want to reuse.
            finEventIndicesToDelete = true(1, length(finEventNames));
            for i = 1:length(fns)
                productName = fns{i};
                finEventIx = [];
                for j = 1:length(finEventNames)
                   if strcmp([productName, ' Production'], finEventNames{j})
                      finEventIx = j;
                      break
                   end
                end
                if isempty(finEventIx)
                   % Then we need to create a new financial event for this product. 

%                   function ies = ImagineEventStatus(origin, cropDefinitionLocked, deferredToRegime, deferredToRegimeLocked, regimeRedefinable, regimeRedefinableLocked)
                    status = ImagineEventStatus('growthModelFinancial', true, false, true, false, true);
                    
                    % All units for the prices will be in dollars.
                    % The unit of the product is the denominator unit for
                    % our price. eg $ / tonne of yield.
                    unit = Unit('', 'Money', 'Dollar');
                    denominatorUnit = gmDel.propagationParameters.products.(fns{i}).unit;
                    
                    costPriceModel = PriceModel([productName, ' Production'], unit, denominatorUnit, true);
                    newFinEvents (i) = ImagineEvent([productName, ' Production'], status, costPriceModel);
                else
                   % Then we need to reuse the financial event we already
                   % have.
                   finEventIndicesToDelete(finEventIx) = false;
                   newFinEvents(i) = gmDel.growthModelFinancialEvents(finEventIx);                   
                end
                
                % Set up the trigger and condition (quantity > 0)
                quantityCondition = QuantityBasedCondition([productName, ' production > 0']);
                quantityCondition.eventName = QuantityBasedCondition.nullEventName;
                quantityCondition.quantityType = 'Product';
                quantityCondition.rate = Rate(0, gmDel.propagationParameters.products.(fns{i}).unit, gmDel.propagationParameters.products.(fns{i}).denominatorUnit);
                quantityCondition.comparator = '>';
                newFinEvents(i).trigger.conditions = {quantityCondition};
                
            end
            
            % Delete any of the financial events we didnt use.
            delete(gmDel.growthModelFinancialEvents(finEventIndicesToDelete));

            % Store the new finacnial events
            gmDel.growthModelFinancialEvents = newFinEvents;

        end
        
        % Goes through the list of products in the propagationParameters
        % and removes the ones that aren't needed and adds the ones that
        % are.
        function refreshPriceModelList(gmDel, nameRemap)
            
           if nargin < 2
              nameRemap = {}; 
           end
           
           % First we'll change then names of the price models if the
           % products have changed.           
           for i = 1:size(nameRemap, 1)
               ix = find(strcmp([nameRemap{i, 1}, ' Income'], {gmDel.productPriceModels.name}), 1, 'first');
               if ~isempty(ix)
                  % Then we've found a product that has been renamed. Let's rename it's price model too. 
                  gmDel.productPriceModels(ix).name = [nameRemap{i, 2}, ' Income'];
               end
           end
           
           % For each product in the propagationParameters, get the corresponding
           % priceModel from internalPriceModelList.
           try
               products = gmDel.propagationParameters.products;
           catch e
              return
           end
           
           if isempty(products)
               fns = {};
           else
               fns = fieldnames(products);
           end
           
           ixs = zeros(length(fns), 1);
           for i = 1:length(fns)
                ix = find(strcmp([fns{i}, ' Income'], {gmDel.productPriceModels.name}), 1, 'first');
                if isempty(ix)
                   unit = Unit('', 'Money', 'Dollar');
                   denominatorUnit = products.(fns{i}).unit;
                   gmDel.productPriceModels(end+1) = PriceModel([fns{i}, ' Income'], unit, denominatorUnit);
                   ixs(i) = length(gmDel.productPriceModels);
                else
                   ixs(i) = ix;
                end
           end
           gmDel.productPriceModels = gmDel.productPriceModels(ixs);
            
        end
        
        % This function renders a display of the growthModelDelegate's
        % parameters as a kind of summary. This is used in the crop wizard
        % and displays a summary of the saved growth model to be viewed
        % before and after the user enters the main GUI (launched via
        % setupGrowthModel above). This function should plot the summary on
        % ax, an axes object.
        function renderGrowthModel(gmDel, ax)
        
            
        end
        
        % This function calculates the growthModel outputs based on the
        % state. Outputs are given in term of Rates in a similar fashion to
        % the products.
        % It throws an error if the units in the outputColumn don't match
        % the units provided by the growthModel.
        %
        % If state is empty and a third argument is supplied which is
        % 'unit' or 'rate' then calculateOutputs returns the units or rates
        % (with 0 as the number) that this function would return when it had a state.
        % If state is supplied along with the third argument, it is
        % ignored.
        % 
        % When the third argument is supplied, this function makes the output units for this growth model. These are the
        % units we want to keep track of as the crop grows, and which we might want
        % to apply costs to, but are not products.
        % For example biomass might be an output for plantation crops. Shoots,
        % leaves, height etc might be outputs for grasses. Soil moisture content
        % might also be an output.

        function outputsColumn = calculateOutputs(gmd, state, unitOrRate) %#ok<MANU>
            
%            persistent numeratorUnits
%            persistent denominatorUnits
%            persistent outputRates

            % numeratorUnits = Unit.empty(1, 0);                
            % Need to get the outputs from the gmd. Probably in a
            % similar manner to the propagation
%             if ~isfield(gmd, 'propagationParameters')
%                outputsColumn = Rate.empty(1, 0); 
%                return 
%             end
            numeratorUnits = Unit.empty(1, 0);
            denominatorUnits = Unit.empty(1, 0);
            outputRates = Rate.empty(1, 0);
            
            if isempty(gmd.propagationParameters)
                outputsColumn = outputRates;
                return
            end
            
            if isstruct(gmd.propagationParameters.outputs)
                fns = fieldnames(gmd.propagationParameters.outputs);
                for i = 1:length(fns)
                        denominatorUnit = gmd.propagationParameters.outputs.(fns{i}).denominatorUnit;
                        numeratorUnit = gmd.propagationParameters.outputs.(fns{i}).unit;
                        numeratorUnits(i) = numeratorUnit;
                        denominatorUnits(i) = denominatorUnit;
                        outputRates(i) = Rate(0, numeratorUnit, denominatorUnit);
                end
            %    outputsColumn = outputRates;
           % else
            %    outputsColumn = Rate.empty(1, 0);
            end
                    
            if isempty(state)
                if nargin == 3
                    
                    if length(denominatorUnits) ~= length(numeratorUnits)
                        error('RainfallBasedGrowthModel needs the same number of numerator units as denominator units.');
                    end
                    
                    switch unitOrRate
                        
                        case 'unit'
                            outputsColumn = numeratorUnits;
                            
                        case 'rate'
%                            if isempty(outputRates)
                                for i = 1:length(numeratorUnits)
                                    outputRates(i) = Rate(0, numeratorUnits(i), denominatorUnits(i));
                                end
 %                           end
                            outputsColumn = outputRates;
                    end
                    return
                end
            end                
            
            % In the case of the fixed yield growth model, we'll just
            % output the state. it should be a column of outpts.            
            outputsColumn = state;            
            
        end
        
        % We get the growthModelOutputRates and Units from the
        % calculateOutputs function.
        function gMOUs = get.growthModelOutputUnits(gmDel)
            gMOUs = gmDel.calculateOutputs([], 'unit');
        end
        
        function gMORs = get.growthModelOutputRates(gmDel)
            gMORs = gmDel.calculateOutputs([], 'rate');
        end
        
        
        % As well as these core methods, you need to implement methods for
        % each supported ImagineEvent of the form
        %
        % outputProducts = transitonFunction_EVENTNAME(gmDel, ...)
        % where EVENTNAME happens to be the name of the event that is supported.
        %
        % outputProducts should actually be rates. As in 20 tonnes of
        % Biomass per Ha. The Ha Amount comes from the regime and the total
        % amount comes from the multiplication of the two.
        %
        % The transition functions should update the state within
        % plantedCrop.
        
        % The Planting transition function should initialise the state. 
        function [outputProducts, eventOutputs] = transitionFunction_Planting(gmDel, plantedCrop, sim) %#ok<INUSD,MANU>
            outputProducts = Rate.empty(1, 0);
            eventOutputs = Rate.empty(1, 0);
            %newState.yield = 0;
            
            %plantedCrop.state = newState;
        end
        
        function [outputProducts, eventOutputs] = transitionFunction_Harvesting(gmDel, plantedCrop, sim) %#ok<INUSD,MANU>
            
            outputProducts = Rate.empty(1, 0);            
            eventOutputs = Rate.empty(1, 0);
        end        
        
    end
    
    % Validation Methods
    methods
        
        % Checks that the class is right and things aren't empty
        function valid = gmdIsValid(gmd)
            valid = isa(gmd, 'FixedYieldGrowthModelDelegate');
        end
        
        % Checks that the parameters are consistent and ready to go!
        % Note, this should really check quite a bit more. At least that
        % all the fields exist and are of the correct type.
        function ready = gmdIsReady(gmd)
            ready = gmdIsValid(gmd);
            if ~ready || isempty(gmd.propagationParameters)
                ready = 0;
            end
        end
        
        % This function makes the productPriceModels.
        % It defines what the products are. The denominator units used define the 
        % units of the product. These are not changed later. Therefore care must be
        % taken to ensure that the denominator units here match the numerator units
        % in the rate returned by a transition function.
        function pPMs = makeFixedYieldProductPriceModels(obj)

            % All units for the prices will be in dollars.
            unit = Unit('', 'Money', 'Dollar');

            % If we don't have propagationParameters yet, return.
            if isempty(obj.propagationParameters)
                pPMs = PriceModel.empty(1, 0);
                return
            elseif isemtpy(obj.propagationParameters.products)
                pPMs = PriceModel.empty(1, 0);                
                return
            end
            
            % For the fixed yield price models, we need to create one for each
            % product described in the propagationParameters.
            fns = fieldnames(obj.propagationParameters.products);
            for i = 1:length(fns)
                denominatorUnit = obj.propagationParameters.products.(fns{i}).unit;
                pPMs(i) = PriceModel([fns{i}, ' Income'], unit, denominatorUnit);
            end

        end
        
        % Doesn't need to do anything as the Fixed Yield Growth Model
        % doesn't use names of other crops.
        function cropNameHasChanged(gmd, previousName, newName)
            
        end
        
    end
    
end


% This function makes the triggers for the FixedYeidl events.
%
% Perhaps we should pass in a parameter so that we can specify a category.
% Can we do away with events altogether? Could we simply have a manual
% category in which we specify the manual growth model??
% The manual category has no events at all - only financial events that the
% user must specify.
% The state would exist as the 'outputs' that get set.
% The products would not be produced by events, but rather in the
% propagation stage. Any costs need to be synced up.
% 
% For now, we keep it based on the Annual Regime. Next we'll give it it's
% own category and remove all the events. Just propagation.
% Perhaps we need to include establishment and removal or something.
% So we still have planting events and destruction events. They are
% deferred to the regime, but they can be overwritten in the crop or in the
% regime. So they're free events.
% But then how do regimes interact with the crops? It's complicated and I
% have no solution at this stage.
function [initialEvents, regularEvents, destructionEvents] =  makeFixedYieldImagineEvents()

    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    % Set up the planting event
    status = ImagineEventStatus('core', true, true, true, false, true);
    % Price is 'per Hectare'
    denominatorUnit = Unit('', 'Area', 'Hectare');
%    incomePriceModels = PriceModel.empty(1, 0);
    costPriceModel = PriceModel('Planting', unit, denominatorUnit, true);

    initialEvents  = ImagineEvent('Planting', status, costPriceModel);

 
    % There are no 'regular' events.
    regularEvents = ImagineEvent.empty(1, 0);
    
    % Set up the harvest event
    status = ImagineEventStatus('core', true, true, true, false, true);

    % Income is defined in $ / Tonne of Grain 
    % Cost is 'per Hectare by default. But it could be given per Paddock
    % perhaps
    
    denominatorUnit = Unit('', 'Area', 'Hectare');
    costPriceModel = PriceModel('Harvesting', unit, denominatorUnit, true);

    destructionEvents = ImagineEvent('Harvesting', status, costPriceModel);

end

