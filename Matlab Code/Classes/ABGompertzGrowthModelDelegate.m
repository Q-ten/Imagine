% This is the implementaton of the AB-Gompertz Growth Model.
%
% This is a concrete subclass of the Abstract GrowthModelDelegate class.
%
% The AB-Gompertz model is designed for coppiced woody crops, such as an 
% Oil Mallee.
% The model tracks growth in both above and below ground biomass, with the
% rate of growth of each dependent on the relative size of above to below
% ground biomass.
% The Gompertz model is a growth function based on the idea of exponetial
% growth, with limited resources.
% This model extends that idea by additionally adjusting the internal
% growth rate according to the ratio of the above to below ground biomass
% and the available rainfall.
%
classdef ABGompertzGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties 
        modelName = 'AB-Gompertz'; 
        
        % A list of strings with the names of the CropCategories that this
        % GrowthModel will be appropriate to model.
        supportedCategories = {'Coppice Tree Crop'};
                   
        % This will be a string cell array with descriptions of each
        % element of the state.
        stateDescription = {'Above-ground biomass', 'Below-ground Biomass'};
        
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % These are the AB-Gompertz model specific properties.
    % Implementing the Abstract properties of GrowthModelDelegate.
    properties (Access = public)
                        
        % The ImagineEvents for this growth model. This is where the triggers will be stored, 
        % but the functions will also be defined in here.
        % You should define a function that returns the default list of
        % growthModelEvents. These should match the transitionFunctions
        % you've defined for each event.
       
        growthModelInitialEvents
        growthModelRegularEvents
        growthModelDestructionEvents
        growthModelFinancialEvents = ImagineEvent.empty(1, 0);

        
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
        
        % productPriceModels - a PriceModel for each product that can be
        % produced by this growthModel. The Units of the products are found
        % as the denominator of the PriceModels. 
        % When a product is produced, the Amount's unit can be used to work
        % out which price to use. It will match the denominator unit. (The
        % numerator will be in currency, probably $).
        productPriceModels
        
        % The Unit in which yield will be given, for example:
        % Unit('', 'Tree', 'Unit') or
        % Unit('', 'Belt', 'Hectare')
        yieldUnit
    
    end
    
    
    % Growthmodel parameters
    properties (Access = private)
        
        propagationParameters
        
        plantingParameters
        coppiceParameters
        destructiveHarvestParameters
        setupParameters
        privateYieldUnit
        
        privateProductPriceModels
    end
        
    methods (Static)
       
        function obj = loadobj(obj)
           
            % Need to check if it has a field productPriceModels and if so,
            % set the newObj's privateProductPriceModels.
            if isstruct(obj)
                newObj = ABGompertzGrowthModelDelegate();
                fns = fieldnames(obj);
                for i = 1:length(fns)
                    try
                       newObj.(fns{i}) = obj.(fns{i}); 
                    catch e
                    end
                end
                
                if isfield(obj, 'productPriceModels')
                    for i = 1:length(obj.productPriceModels)
                        % find the matching priceModel and replace it.
                        ix = find(strcmp({newObj.privateProductPriceModels.name}, obj.productPriceModels(i).name), 1, 'first');    
                        if ~isempty(ix)
                            newObj.privateProductPriceModels(ix) = obj.productPriceModels(i);
                        end
                    end
                end
                               
                obj = newObj;
                
                if ~isfield(obj, 'setupParameters')
                    obj.setupParameters = [];
                end
                
                if ~isfield(obj, 'privateYieldUnit')
                    obj.privateYieldUnit = Unit('', 'Tree', 'Unit');
                end
               
            else
                
                params = GompertzGMDialogue('setupParameters', obj.propagationParameters, obj.plantingParameters, obj.coppiceParameters, obj.destructiveHarvestParameters, obj.setupParameters, obj.yieldUnit);
  
                obj.propagationParameters = params.propagationParameters;
                obj.plantingParameters = params.plantingParameters;
                obj.coppiceParameters = params.coppiceParameters;
                obj.destructiveHarvestParameters = params.destructiveHarvestParameters;
                obj.setupParameters = params.setupParameters;
                obj.privateYieldUnit = params.yieldUnit;

            end            
        end
        
    end
    
    methods
    
        % These methods are required from the Abstract parent class
        % GrowthModelDelegate.
        
        % This is the constructor for the concrete subclass. It should set
        % up all the parent's Abstract properties here, then go on to setup
        % any parameters specific to the concrete subclass.
        function gmDel = ABGompertzGrowthModelDelegate(gm)
            
            if nargin > 0
                super_args = {gm};
            else
                super_args = {};
            end
            
            gmDel = gmDel@GrowthModelDelegate(super_args{:});   

            [init, reg, dest] = makeABGompertzImagineEvents;

            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            gmDel.privateProductPriceModels = makeABGompertzProductPriceModels;
            
            % Make the rainfall based output units by calling the calculate
            % outputs function with an empty state and a third argument.
            gmDel.calculateOutputs([], 'rate');
            
            % Now set up the specific default parameters for this growth model.
            
            % Could set up the parameters here, but I think I will leave it
            % up to the GUI. I feel that it's better if they are defined in
            % one place.        
        
        end
        
        % This function propagates the state over one month. This should be
        % set up as appropriate to the concrete subclass.
        function [newState, productRates] = propagateState(gmd, plantedCrop, sim)

            productRates = Rate.empty(1, 0);
            
            % Return the potential products if plantedCrop and sim are
            % empty.
            if (isempty(sim) && isempty(plantedCrop))
                if (gmd.propagationParameters.useCFI)
                    unit = Unit('', 'Sequestered Carbon', 'Tonne');
                    denominatorUnit = Unit('', 'Tree', 'Unit');
                    productRates = Rate(0, unit, denominatorUnit);
                end
                newState = [];
                return
            end
            
            year = sim.year;
            month = sim.month;
            rainfall = sim.monthlyRainfall;
            propParams = gmd.propagationParameters;
            plantMonth = plantedCrop.plantedMonth;

                
            % Get 'annual rainfall' from average of previous 3 months rainfall so as to work out
            % growth rates.
            if(year == 1 && month == 1)
                    rain = rainfall(month, year);
            elseif(year == 1 && month == 2)
                    rain = (rainfall(1, 1) + rainfall(2,1))/2;
            else
                monthsSinceStart = (year-1)*12+month;
                rain = mean(rainfall(monthsSinceStart-2:monthsSinceStart));
            end
            rain = rain * 12;
    
            state = plantedCrop.state;
            
            newState = ABGompertzPropagateState(state, propParams, year, month, rain, plantMonth);
            
            
            % Calculate CFI outputs...
            
            if propParams.useCFI
                newState.longTermAverage = state.longTermAverage;
                
                % Only calclate in December.
                if month == 12
              
                    % Work out current CFI and save to the state.
                    CFIBM = newState.AGBM;
                    if propParams.useBGBM
                        CFIBM = CFIBM + newState.BGBM;
                    end
                    if CFIBM < state.previousCFIBM
                        CFIBM = state.previousCFIBM;
                    elseif CFIBM > state.longTermAverage
                        CFIBM = state.longTermAverage;
                    end

                    if CFIBM > state.previousCFIBM
                        % Add the product for the difference.
                        unit = Unit('', 'Sequestered Carbon', 'Tonne');
                        denominatorUnit = Unit('', 'Tree', 'Unit');
                        % 0.27 is due to the amount of Carbon in a CO2
                        % molecule.
                        BMToCarbonConversion = propParams.ratioDryToGreenBM * propParams.fractionCarbonInDryBM / 0.27;
                        seqCarbon = (CFIBM - state.previousCFIBM) * (100 - propParams.CFIBuffer) / 100 * BMToCarbonConversion;
                        productRates = Rate(seqCarbon, unit, denominatorUnit);
                    end
                    % Last line 

                    newState.previousCFIBM = CFIBM;
                else
                    newState.previousCFIBM = state.previousCFIBM; 
                end
            end
            
        end
        
          
        % This function is responsible for setting up all the parameters
        % particular to the concrete subclass. It will probably launch a
        % GUI which will be passed the GrowthModelDelegate and the GUI will
        % alter the pubilc parameters that are available to it when it is
        % saved. No need to return the GMD since it is a handle class.
        function gmDel = setupGrowthModel(gmDel, cropName)
        
            if isempty(gmDel.propagationParameters) || isempty(gmDel.plantingParameters) || isempty(gmDel.coppiceParameters) || isempty(gmDel.destructiveHarvestParameters)
             p1 = gmDel.propagationParameters
             p2 = gmDel.plantingParameters
             p3 = gmDel.coppiceParameters
             p4 = gmDel.destructiveHarvestParameters
             ps.p1 = p1;
             ps.p2 = p2;
             ps.p3 = p3;
             ps.p4 = p4;
             
                disp('Some parameters are not valid yet')
                assignin('base', 'gompertzGMDel', gmDel);
                assignin('base', 'ps', ps);
            end
            output = GompertzGMDialogue(gmDel.propagationParameters, gmDel.plantingParameters, gmDel.coppiceParameters, gmDel.destructiveHarvestParameters, gmDel.setupParameters, gmDel.yieldUnit);
            if ~isempty(output)
               
                gmDel.propagationParameters = output.propagationParameters;
                gmDel.plantingParameters = output.plantingParameters;
                gmDel.coppiceParameters = output.coppiceParameters;
                gmDel.destructiveHarvestParameters = output.destructiveHarvestParameters;
                gmDel.setupParameters = output.setupParameters;
                gmDel.privateYieldUnit = output.yieldUnit;
            end
            
        end
        
        % This function renders a display of the growthModelDelegate's
        % parameters as a kind of summary. This is used in the crop wizard
        % and displays a summary of the saved growth model to be viewed
        % before and after the user enters the main GUI (launched via
        % setupGrowthModel above). This function should plot the summary on
        % ax, an axes object.
        function renderGrowthModel(gmDel, ax)
            
           
            picture = './Resources/MalleeBelt.jpg';
            title = 'AB-Gompertz Growth Model';
            expo = {'The AB-Gompertz Model maintains both the above and below ground biomass.'};

            try 
                im = imread(picture);
                im = im(end:-1:1,:,:);
            catch ME
                im = 0.3* ones(558, 800, 3);
            end

            axes(ax);
            cla
            image('CData', im);
            pos = [0 1600 0 1200];
            axis(pos);
            axis on
            hold on


            %intro =         {'Imagine is a tool designed to simulate the growth', ...
            %         'of crops on a paddock over time.', ...
            %         '', ...
            %         'Factors affecting the outcome of profitability can be ', ...
            %         'set up as probabilistic distributions and while there ', ...
            %         'may be complex interactions between the random ', ...
            %         'variables used, a monte carlo simulation ', ...
            %         'environment has been set up so that the distribution ', ...
            %         'of outcomes can be assessed.', ...
            %         '', ...
            %         'Crops grow according to a model set up by the user. ', ...
            %         'We have a rainfall based growth model that is ', ...
            %         'appropriate for annual crops, and a Gompertz based ', ...
            %         'growth model that grows above ground and below ', ...
            %         'ground biomass in tandem, which is suitable for trees.', ...
            %         '', ...
            %         'Imagine has been developed by Amir Abadi, Don Cooper ', ...
            %         'and Quenten Thomas.'};



            patch([0.05*pos(2) 0.05*pos(2) 0.95*pos(2) 0.95*pos(2)], [0.05*pos(4), 0.95*pos(4), 0.95*pos(4), 0.05*pos(4)], [0,0,0,0], 'k', 'FaceAlpha', 0.5);
            %view([0 90])

            %set(gcf, 'Name', 'Welcome');
            text(0.1*pos(2), 0.9*pos(4), title, 'Color', 1*[1,1,1], 'VerticalAlignment', 'top', 'FontSize', 16);
            text(0.1*pos(2), 0.8*pos(4), expo, 'Color', 1*[1,1,1], 'VerticalAlignment', 'top');
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
        function outputsColumn = calculateOutputs(gmd, state, unitOrRate)
            
            % Keep the units and rates so we don't always remake them.
            persistent numeratorUnits
            persistent denominatorUnits
            persistent outputRates
            
            
            % Create the units if this is the first time through.
            if isempty(numeratorUnits)
                numeratorUnits = Unit('', 'Above-ground Biomass', 'Tonne');
                numeratorUnits(2) = Unit('', 'Below-ground Biomass', 'Tonne');
            end

            if isempty(denominatorUnits)
                denominatorUnits = Unit('', 'Tree', 'Unit');
                denominatorUnits(2) = denominatorUnits(1);
            end
            
            
            % If there is no state, we must be after just the units.
            % This bracket sorts that out and returns. Otherwise it
            % continues below.
            if isempty(state)
                if nargin == 3
                    
                    if length(denominatorUnits) ~= length(numeratorUnits)
                        error('RainfallBasedGrowthModel needs the same number of numerator units as denominator units.');
                    end
                    
                    switch unitOrRate
                        
                        case 'unit'
                            outputsColumn = numeratorUnits;
                            
                        case 'rate'
                            if isempty(outputRates)
                                outputRates = Rate.empty(1, 0);
                                for i = 1:length(numeratorUnits)
                                    outputRates(i) = Rate(0, numeratorUnits(i), denominatorUnits(i));
                                end
                            end
                            outputsColumn = outputRates;
                    end
                    return
                end
            end
            
            
            % calculateOutputs must be able to provide a column of nothing
            % outputs if the state that is passed is empty.
            if isempty(state)
                state.AGBM = 0;
                state.BGBM = 0;
            end
            
            
            % Create the output columns.
            outputsColumn(1, 1) = Rate(state.AGBM, numeratorUnits(1), denominatorUnits(1));

            outputsColumn(2, 1) = Rate(state.BGBM, numeratorUnits(2), denominatorUnits(2));
            
        end
        
        % We get the growthModelOutputRates and Units from the
        % calculateOutputs function.
        function gMOUs = get.growthModelOutputUnits(gmDel)
            gMOUs = gmDel.calculateOutputs([], 'unit');
        end
        
        function gMORs = get.growthModelOutputRates(gmDel)
            gMORs = gmDel.calculateOutputs([], 'rate');
        end
        
        % productPriceModels is a dependent property because we might want
        % to include or exclude the Sequestered Carbon price model. We're assuming 
        % the sequestered carbon price model is the last one.
        function pMs = get.productPriceModels(gmDel)
           if gmDel.propagationParameters.useCFI
              pMs = gmDel.privateProductPriceModels; 
           else              
              pMs = gmDel.privateProductPriceModels(1:end -1);
           end
        end
        
        % Basically an inverse of the get method.
        function set.productPriceModels(gmDel, pPMs)           
           if gmDel.propagationParameters.useCFI
              gmDel.privateProductPriceModels = pPMs; 
           else              
              gmDel.privateProductPriceModels(1:end -1) = pPMs;
           end
           
        end
        
        function yu = get.yieldUnit(gmDel)
            yu = gmDel.privateYieldUnit;
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
        
        function [outputProducts, eventOutputs] = transitionFunction_Planting(gmDel, plantedCrop, sim) 
            outputProducts = Rate.empty(1, 0);             
            eventOutputs = Rate.empty(1, 0);
            
            % Return list of products and outputs if called with no
            % arguments.
            % In the case of planting, not products or outputs are
            % produced.
            if(isempty(plantedCrop) && isempty(sim))
               return; 
            end
            
            newState.AGBM = gmDel.plantingParameters.A0;
            newState.BGBM = gmDel.plantingParameters.B0;
           
            if gmDel.propagationParameters.useCFI
                
                % Calculate long term average.
                % Need to get the average rainfall from the climate model.
                % We need to get the trigger from the plantedCrop to work
                % out how the coppicing will be done, and therefore what
                % the long term average will be, based on average rainfall.
                
                regEvents = gmDel.growthModelRegularEvents;
                ix = find(strcmp({regEvents.name}, 'Coppice Harvesting'), 1, 'first');
                if isempty(ix)
                    error('Cannot find Coppice Harvesting event in the ABGompertzGrowthModelDelegate.');
                end
                
                trigger = plantedCrop.regularTriggers(ix);
                % There are two types of trigger handy - set biomass
                % threshold and predefined years and months.
                triggerType = '';
                if length(trigger.conditions{1}.shorthand) > 8
                   k = strfind(trigger.conditions{1}.shorthand, 'Month is') ;
                   if length(k) == 1 && k == 1
                      if strcmp(trigger.conditions{2}.shorthand, 'Harvest years') 
                          % Then we have a harvest years and month trigger.
                          triggerType = 'Harvest Years and Month';
                          harvestMonth = trigger.conditions{1}.monthIndex;  % It's a MonthBasedCondition
                          harvestYears = trigger.conditions{2}.indices;     % It's a TimeIndexedCondition, by Year.
                      end
                   end
                end
                
                if isempty(triggerType)
                   if strcmp(trigger.conditions{1}.shorthand, 'AGBM > threshold') || strcmp(trigger.conditions{1}.shorthand, 'AGBM >= threshold')
                        % We need to get the biomassThreshold into whatever
                        % it should be per tree. So we divide by the number
                        % of tree
                        % 30 tonnes per Hectare, with however many trees
                        % per hectare goes to 30 / however many per tree.
                        %
                        % 30 tonnes per Hectare, 5 hectares per paddock,
                        % 5000 trees per paddock.
                        % leads to how many tonnes per tree?
                        % 30 * 5 = tonnes per paddock. 150 / 5000 = tonnes
                        % per tree.
                        
                        triggerType = 'Biomass threshold';
                        % Its a QuantityBased one.
                        biomassThreshold = trigger.conditions{1}.rate.number;
                        unitSpeciesName = trigger.conditions{1}.rate.unit.speciesName;
                        unitUnitName = trigger.conditions{1}.rate.unit.unitName;
                        unitAmount = plantedCrop.getAmount( Unit('', unitSpeciesName, unitUnitName));                        
                        treeAmount = plantedCrop.getAmount( Unit('', 'Tree', 'Unit'));
                        biomassThreshold = biomassThreshold * unitAmount.number / treeAmount.number;
                   end
                end

                if isempty(triggerType)
                    error('CFI long term averaging not supported for the trigger type used.');
                end
                
                % Set up for the simulation.
                climateMgr = ClimateManager.getInstance;
                imObj = ImagineObject.getInstance;
                rainMonthAvs = climateMgr.getMonthlyAverageRainfall;
                rainfall = repmat(rainMonthAvs', 1, imObj.simulationLength);
 
                subState = newState;

                AGBM = zeros(1, imObj.simulationLength * 12);
                propParams = gmDel.propagationParameters;
                
                if propParams.useBGBM
                    BGBM = AGBM;
                end
                
                % For each month, simulate the biomass growth using the
                % average rainfall data.
                for year = 1:imObj.simulationLength
                    for month = 1:12

                        % Get 'annual rainfall' from average of previous 3 months rainfall so as to work out
                        % growth rates.
                        if(year == 1 && month == 1)
                                rain = rainfall(month, year);
                        elseif(year == 1 && month == 2)
                                rain = (rainfall(1, 1) + rainfall(2,1))/2;
                        else
                            monthsSinceStart = (year-1)*12+month;
                            rain = mean(rainfall(monthsSinceStart-2:monthsSinceStart));
                        end
                        rain = rain * 12;

                        subState = ABGompertzPropagateState(subState, propParams, year, month, rain, 1);

                        AGBM(year * 12 - 12 + month) = subState.AGBM;
                        
                        if propParams.useBGBM
                            BGBM(year * 12 - 12 + month) = subState.BGBM;
                        end                    
                        
                        switch triggerType

                            case 'Harvest Years and Month'
                                if month == harvestMonth && any(harvestYears == year)
                                    subState.AGBM = gmDel.coppiceParameters.postCoppiceA;
                                    subState.BGBM = (100 - gmDel.coppiceParameters.B_coppice_loss)/100 * subState.BGBM;
                                end
                            case 'Biomass threshold'
                                if subState.AGBM > biomassThreshold
                                    subState.AGBM = gmDel.coppiceParameters.postCoppiceA;
                                    subState.BGBM = (100 - gmDel.coppiceParameters.B_coppice_loss)/100 * subState.BGBM;
                                end
                        end
                    end
                end
                
                % Use the AGBM and BGBM data to work out the long term
                % average and set it in the state,
                if propParams.useBGBM
                   newState.longTermAverage = mean([AGBM, BGBM]); 
                else
                   newState.longTermAverage = mean(AGBM);
                end
                
                newState.previousCFIBM = 0;
            end
            
            plantedCrop.state = newState;
        end
        
        % The coppice function is quite simple. The parameters tell us how
        % much is left over. The amount harvested is then how much there
        % was to start - how much is left over.
        function [outputProducts, eventOutputs] = transitionFunction_Coppice_Harvesting(gmDel, plantedCrop, sim) 
            
            eventOutputs = Rate.empty(1, 0);
            unit = Unit('', 'Harvested Biomass', 'Tonne');
            denominatorUnit = gmDel.yieldUnit;
%            Unit('', 'Tree', 'Unit');
            
            costUnit = Unit('', 'Coppice Cost', 'Dollar');
            costDenominatorUnit = unit;
            
            timeUnit = Unit('', 'Coppice Harvest Time', 'Day');
            timeDenominatorUnit = Unit('', 'Paddock', 'Unit');
            
            % Return list of products and outputs if called with no
            % arguments.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, unit, denominatorUnit);
                if gmDel.propagationParameters.costParameters.useDensityBasedHarvestCost
                    eventOutputs = Rate(0, costUnit, costDenominatorUnit);
                    eventOutputs(2) = Rate(0, timeUnit, timeDenominatorUnit);
                end
                return;
            end
            
            
            state = plantedCrop.state;
            
            %   Well, we have post-coppice BM for AG, and a percentage lost
            %   for BG.
    
            newState.AGBM = gmDel.coppiceParameters.postCoppiceA;
            newState.BGBM = (100 - gmDel.coppiceParameters.B_coppice_loss)/100 * state.BGBM;
    
            if gmDel.propagationParameters.useCFI
               newState.longTermAverage = state.longTermAverage;
               newState.previousCFIBM = state.previousCFIBM;
            end
            
            
            harvestedAGBM = state.AGBM - newState.AGBM;
            
            outputProducts = Rate(harvestedAGBM, unit, denominatorUnit);
            
            
            % Work out cost of coppice harvesting according to density and
            % yield if it is turned on.
            if(gmDel.propagationParameters.costParameters.useDensityBasedHarvestCost)
              
                plantSpacing = plantedCrop.parentRegime.getRegimeParameter('plantSpacing');
                
                % 1. Yield in kg/m:
                    % We calculate tonnes per tree
                    % Convert to kg per tree (*1000)
                    % Convert to kg per m (/ intra-row spacing)
                    yieldKgPerTree = harvestedAGBM * 1000;
                    yieldKgPerM = harvestedAGBM * 1000 / plantSpacing;
                    
                % 2. Speed of harvester per hour:
                % Get the speed parameters from the propagationParameters.
                % We need to get a multiplier and a power parameter.
                % User needs to define a table that maps spacing between trees to the paramters.
                % We will interpolate between the provided numbers to get
                % our exact number.
                speedTableFactor = gmDel.propagationParameters.costParameters.speedTableFactor;
                speedTablePower  = gmDel.propagationParameters.costParameters.speedTablePower;
                speedFactor = interp1(1:length(speedTableFactor), speedTableFactor, plantSpacing);
                speedPower = interp1(1:length(speedTablePower), speedTablePower, plantSpacing);

                speedMPerHour = speedFactor * yieldKgPerTree ^ speedPower;
                
                % 3. Pour rate (harvested tonnes per hour):
                pourRate = yieldKgPerM * speedMPerHour / 1000;
                
                % 4. Harvest cost per tonne:
                costFactor = gmDel.propagationParameters.costParameters.costFactor;
                costPower = gmDel.propagationParameters.costParameters.costPower;
                
                eventOutputs = Rate(costFactor * pourRate ^ costPower, costUnit, costDenominatorUnit);                

                % Calculate days required to harvest.
                % Overhead = 1 day.
                % Operating hours per day = 8.
                % Assume 1 harvester in operation.
                % Hours = kmofrows / speed per km.
                hoursPerDay = 8;
                overheadDays = 1;
                harvestersOperating = 1;
                speedKmPerHour = speedMPerHour / 1000;
                paddocksToSpreadOverheadOver = 10;
                
                kmOfRows = plantedCrop.getAmount(Unit('', 'Rows', 'Km'));
                hours = kmOfRows.number / speedKmPerHour;
                days = hours / hoursPerDay / harvestersOperating;
                days = ceil(days + overheadDays / paddocksToSpreadOverheadOver);
                eventOutputs(2) = Rate(days, timeUnit, timeDenominatorUnit);

            end           
            plantedCrop.state = newState;
        end
        
        % When we do destructive harvesting, the whole crop goes.
        % Otherwise, very similar to coppice.
        function [outputProducts, eventOutputs] = transitionFunction_Destructive_Harvesting(gmDel, plantedCrop, sim) %#ok<INUSD,*MANU>
            eventOutputs = Rate.empty(1, 0);

            unit = Unit('', 'Harvested Biomass', 'Tonne');
          %  denominatorUnit = Unit('', 'Tree', 'Unit');
            denominatorUnit = gmDel.yieldUnit;
                    
            % Return list of products and outputs if called with no
            % arguments.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, unit, denominatorUnit);
                return; 
            end
            
            state = plantedCrop.state;
            
            newState.AGBM = 0;
            newState.BGBM = 0;

            if gmDel.propagationParameters.useCFI
               newState.longTermAverage = state.longTermAverage;
               newState.previousCFIBM = state.previousCFIBM;
            end
                
            outputProducts = Rate(state.AGBM - newState.AGBM, unit, denominatorUnit);
            plantedCrop.state = newState;
        end
        
    end
    
    
    methods
        
        % Checks that the class is right and things aren't empty
        function valid = gmdIsValid(gmd)
            valid = isa(gmd, 'ABGompertzGrowthModelDelegate');
        end
        
        % Checks that the parameters are consistent and ready to go!
        % Note, this should really check quite a bit more. At least that
        % all the fields exist and are of the correct type.
        function ready = gmdIsReady(gmd)
            ready = gmdIsValid(gmd);
            if ~ready || isempty(gmd.propagationParameters) || isempty(gmd.plantingParameters) || isempty(gmd.coppiceParameters)
                ready = 0;
            end
        end
        
        
        function cropNameHasChanged(gmd, previousName, newName)
              % No references to other crop names in the ABGompertz
              % growthmodel.
              % Note that we might need to update the event triggers one
              % day.
        end 

        
    end
    
end

% This function makes the triggers for the ABGompertz events.
function [initialEvents, regularEvents, destructionEvents] =  makeABGompertzImagineEvents()

    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    % Set up the planting event
    status = ImagineEventStatus('core', true, true, true, false, true);
    % Price is 'per Tree'
    denominatorUnit = Unit('', 'Tree', 'Unit');
    costPriceModel = PriceModel('Planting', unit, denominatorUnit, true);

    initialEvents = ImagineEvent('Planting', status, costPriceModel);

    % Set up the coppice event
    status = ImagineEventStatus('core', true, true, true, true, true);

    % Cost is 'per Tree' by default. But it could be given per km of Belts or
    % Rows.
    denominatorUnit = Unit('', 'Tree', 'Unit');
    costPriceModel = PriceModel('Coppice Harvest', unit, denominatorUnit, true);
    regularEvents = ImagineEvent('Coppice Harvesting', status, costPriceModel);

    % Set up the destructive harvest event
    status = ImagineEventStatus('core', true, true, true, false, true);

    % Cost is 'per Tree' by default. But it could be given per km of Belts or
    % Rows.
    denominatorUnit = Unit('', 'Tree', 'Unit');
    costPriceModel = PriceModel('Destructive Harvest', unit, denominatorUnit, true);

    % Want the incomePriceModels to be the same for both destructive and
    % coppice harvests, so incomePriceModels remains unchanged..

    destructionEvents = ImagineEvent('Destructive Harvesting', status, costPriceModel);

end


% This function makes the productPriceModels. 
% It defines what the products are. The denominator units used define the 
% units of the product. These are not changed later. Therefore care must be
% taken to ensure that the denominator units here match the numerator units
% in the rate returned by a transition function.
function pPMs = makeABGompertzProductPriceModels

    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    denominatorUnit = Unit('', 'Harvested Biomass', 'Tonne');
    pPMs = PriceModel('Biomass Income', unit, denominatorUnit);
    
    %
    % The sequestered carbon price model should be the last in the list.
    denominatorUnit = Unit('', 'Sequestered Carbon', 'Tonne');
    pPMs(end + 1) = PriceModel('Sequestered Carbon', unit, denominatorUnit);    

end



