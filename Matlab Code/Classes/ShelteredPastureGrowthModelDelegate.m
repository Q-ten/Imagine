% This is the implementation of a concrete ShelteredPastureGrowthModelDelegate 
% based on the Abstract class.
%
% The ShelteredPastureGrowthModel models a self-replacing flock on a pasture.
% It produces wool and sheep for sale.
% FOO is modeled in a simple way: a set small FOO is expected at the end of
% summer, which will then grow some amout per mm of rainfall.
% Fodder is required for the sheep when the FOO is below a threshold (eg
% 1100 kg / Ha.) This adds costs, particularly if the rain comes late.
%
classdef ShelteredPastureGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties
        modelName = 'Sheltered Pasture'; 
        
        % A list of strings with the names of the CropCategories that this
        % GrowthModel will be appropriate to model.
        supportedCategories = {'Pasture'};
                   
        % This will be a string cell array with descriptions of each
        % element of the state. Usually just one or two words - more labels
        % than descriptions.
        stateDescription = {'FOO'};
       
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


    % These are the Sheltered Pasture model specific properties.
    properties (Access = public)
        
        FOO
        fodderCosts
        woolSales
        sheepSales
%        spatialInteractions        

    end
       
    
    methods (Static)
       
        function obj = loadobj(obj)

            if isstruct(obj)
                newObj = ShelteredPastureGrowthModelDelegate();
                fns = fieldnames(obj);
                for i = 1:length(fns)
                    try
                       newObj.(fns{i}) = obj.(fns{i}); 
                    catch e
                    end
                end
                if(isfield(newObj.FOO, 'firstFeedGapMonth') && ~isfield(newObj.FOO, 'startMonth'))
                   newObj.FOO.startMonth = newObj.FOO.firstFeedGapMonth;
                end
                obj = newObj;
            else                
                gm = setupParameters(obj.FOO, obj.fodderCosts, obj.woolSales, obj.sheepSales);%, obj.spatialInteractions);            
                gmFields = fieldnames(gm);
                for i = 1:length(gmFields)
                   obj.(gmFields{i}) = gm.(gmFields{i}); 
                end
            end
        end
        
    end
    
    methods
    
        % These methods are required from the Abstract parent class
        % GrowthModelDelegate.
        
        % This is the constructor for the concrete subclass. It should set
        % up all the parent's Abstract properties here, then go on to setup
        % any parameters specific to the concrete subclass.
        function gmDel = ShelteredPastureGrowthModelDelegate(gm)
            if nargin > 0
                super_args = {gm};
            else
                super_args = {};
            end
            
            gmDel = gmDel@GrowthModelDelegate(super_args{:});
            
            % Now set up the specific default parameters for this growth model.
            
            % The priceModels, events and outputUnits need to be set up
            % here.
            [init, reg, dest] = makeShelteredPastureImagineEvents;
            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            gmDel.productPriceModels = makeShelteredPastureProductPriceModels;
            
            % Make the rainfall based output units by calling the calculate
            % outputs function with an empty state and a third argument.
            gmDel.calculateOutputs([], 'rate');
            
            % Could set up the parameters here, but you could leave it
            % up to the GUI. It's probably better if they are defined in
            % one place.
            
        end
        
        % This function propagates the state over one month. This should be
        % set up as appropriate to the concrete subclass.
        % Need to return the state - not set it in plantedCrop as we have
        % to change the month day before we set the state.
        function [newState, productRates] = propagateState(gmd, plantedCrop, sim)
        
            productRates = Rate.empty(1, 0);
            
            % Return the potential products if plantedCrop and sim are
            % empty.
            if (isempty(sim) && isempty(plantedCrop))
                newState = [];
                return
            end
            
            newState = plantedCrop.state;

            % Check if we need to set the initial FOO.   
            % regime year is the number of years into the regime.
            regimeYear = sim.year - (floor(sim.currentPrimaryInstalledRegime.installedMonth-1/ 12)+1) + 1;            
            if (gmd.FOO.startMonth && regimeYear == 1)
                if (sim.month < gmd.FOO.startMonth)
                    plantedCrop.state.FOO = 0;
                    newState.FOO = plantedCrop.state.FOO;
                    newState.percentShortfall = 1;
                    return
                end
                if (sim.month == gmd.FOO.startMonth)                    
                    plantedCrop.state.FOO = gmd.FOO.availableAtStart;
                    newState.FOO = plantedCrop.state.FOO;
                end
            end
            
            startingFOO = plantedCrop.state.FOO;
            
            % Import the settings from the designated settings file.
            [~, name, ~] = fileparts(gmd.FOO.shelterSettingsFile);
            settings = eval(name);
                    
            % Simple lookup table for the number of days in a month.
            daysInMonthLookup = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

            % The ShelteredPasture model only needs to add on some FOO if
            % there's been some rainfall.
            % In the period where we don't care, we'll set the FOO to 0.            
            
%             1. Use monthly growth rates and rainfall to determine OP (Open Paddock, i.e. unsheltered) growth.
%         		a. Additionally, adjust growth in the sheltered zone.
%             2. Calculate the consumption based on the DSE in paddock (regime provides this).
%             3. Determine the remaining FOO after consumption. 
%                 a. Limit consumption to the FOO grazing minimum
%             4. Figure out the FOO shortfall and replace with feed grain. 
%                 a. Also determine the percentage shortfall to include in the outputs.

            
            % 1. Use monthly growth rates and rainfall to determine OP growth
            dailyIncreasePerMM = settings.growthPerMMRain_byMonth(sim.month);
            daysInMonth = daysInMonthLookup(sim.month);
            
            
            % 1a. Additionally, adjust growth in the sheltered zone.
                        % To replace
%             CressyDailyEvaporationByMonthLookup = [6, 5.6, 3.8, 2.3, 1.2, 0.8, 0.8, 1.3, 2.2, 3.2, 4.3, 5.2];            
%             openPaddockDailyEvaporation = CressyDailyEvaporationByMonthLookup(sim.month);
%             
%             imo = ImagineObject.getInstance();
%             treeHeight = 20; % meters
%             windDirection = 20; % degrees
%             
%             evapSavings = calculateAverageWaterSavedWithShelter(imo.paddockLength, imo.paddockWidth, treeHeight, openPaddockDailyEvaporation, windDirection) * daysInMonth;
%             
%            monthlyAvailableWater = sim.monthlyRainfall(sim.monthIndex);% + evapSavings;
            

            monthlyFOOGrowthPerHa = sim.monthlyRainfall(sim.monthIndex) * dailyIncreasePerMM * daysInMonth;
            
            
            % If the paddock is sheltered, apply the shelter benefits
            % through increased sheep sales.
            % Get the regime's tree height.
            heightUnit = Unit('', 'Height', 'm');
            if~isempty(sim.currentSecondaryPlantedCrop)
                TH = sim.currentSecondaryPlantedCrop.getAmount(heightUnit);
            else
                TH = [];
            end
            
            imo = ImagineObject.getInstance();             

            if (~isempty(TH))
               TH = TH.number;
               beltNo = sim.currentSecondaryInstalledRegime.regimeObject.delegate.getRegimeParameter('beltNum');
               beltWidth = sim.currentSecondaryInstalledRegime.regimeObject.delegate.getBeltWidth();
               alleyWidth = imo.paddockWidth / beltNo - beltWidth;
            else
               TH = 0;
               beltNo = 1;
               alleyWidth = 1;
            end

            bumpFOO = settings.shelterProductivityBoostFunction(settings, sim.monthlyRainfall(sim.monthIndex), sim, gmd, beltNo, alleyWidth, TH, imo.paddockWidth, imo.paddockLength, monthlyFOOGrowthPerHa);
            
            newState.bumpPercentage = bumpFOO / monthlyFOOGrowthPerHa;
            
            % bumpFOO is the extra FOO from the bump. In whatever units
            % OPProductivity (last argument in shelterProductivityBoostFunction) is given in. 
            newState.FOOGrowthPerHa = monthlyFOOGrowthPerHa + bumpFOO;
            
            
            
            
            
            % 2. Calculate the consumption based on the DSE in paddock
            % (regime provides this).
            DSEIndex = find(strcmp({plantedCrop.parentRegime.regimeOutputUnits.speciesName}, 'DSE'), 1, 'first');
            HectaresIndex = find(strcmp({plantedCrop.parentRegime.regimeOutputUnits.speciesName}, 'Area'), 1, 'first');
            
            totalDSE = plantedCrop.parentRegime.outputs(DSEIndex).number;
            totalArea = plantedCrop.parentRegime.outputs(HectaresIndex).number;
            DSEPerHa = totalDSE / totalArea;
            
            monthlyConsumptionPerHa = settings.dailyConsumptionPerDSE * DSEPerHa * daysInMonth; % kg / ha / month.
            
            
%             3. Determine the remaining FOO after consumption. 
%                 a. Limit consumption to the FOO grazing minimum
           
            % For now, without senesence we'll reset to the starting FOO in August.
            % Resetting to zero seemed a bit extreme - we have to build up
            % to the minimum FOO before we graze again.
            if (sim.month == 8)
               newState.FOO = gmd.FOO.availableAtStart; 
            end
                        
            % this is all on a per ha basis.
            maxFOO = newState.FOO + newState.FOOGrowthPerHa;
            if maxFOO > gmd.FOO.requiredBeforeGrazing
                % Then we're consuming
                if maxFOO - gmd.FOO.requiredBeforeGrazing > monthlyConsumptionPerHa
                    % Then we have a surplus.
                    newState.FOO = maxFOO - monthlyConsumptionPerHa; 
                    newState.percentShortfall = 0;
                else
                    % Then we're constrained.
                    FOOConsumed = maxFOO - gmd.FOO.requiredBeforeGrazing;
                    newState.percentShortfall = 1 - (FOOConsumed / monthlyConsumptionPerHa);
                    newState.FOO = gmd.FOO.requiredBeforeGrazing;
                end
            else
                % Then we're handfeeding.
                newState.FOO = maxFOO;
                newState.percentShortfall = 1;                
            end
            
            if (newState.FOO < 0)
                newState.FOO = 0;
            end 
            
            % 4. Figure out the FOO shortfall and replace with feed grain. 
            % This is done in the Feeding event using the percentShortfall.
            
        end
        
        % This function is responsible for setting up all the parameters
        % particular to the concrete subclass. It will probably launch a
        % GUI which will be passed the GrowthModelDelegate and the GUI will
        % alter the pubilc parameters that are available to it when it is
        % saved.
        function gmDel = setupGrowthModel(gmDel, cropName)

            model.FOO = gmDel.FOO;
            model.fodderCosts = gmDel.fodderCosts;
            model.woolSales = gmDel.woolSales;
            model.sheepSales = gmDel.sheepSales;
%            model.spatialInteractions = gmDel.spatialInteractions;
            
            output = ShelteredPastureGrowthModelDialog(model, cropName);
            if ~isempty(output)
               gmDel.FOO = output.FOO;
               gmDel.fodderCosts = output.fodderCosts;
               gmDel.woolSales = output.woolSales;
               gmDel.sheepSales = output.sheepSales; 
%               gmDel.spatialInteractions = output.spatialInteractions;
                for i = 1:length(gmDel.growthModelRegularEvents)
                   gmDel.growthModelRegularEvents(i).trigger = gmDel.getTriggerForEvent(gmDel.growthModelRegularEvents(i).name); 
                end

            end
        end
        
        % This function renders a display of the growthModelDelegate's
        % parameters as a kind of summary. This is used in the crop wizard
        % and displays a summary of the saved growth model to be viewed
        % before and after the user enters the main GUI (launched via
        % setupGrowthModel above). This function should plot the summary on
        % ax, an axes object.
        function renderGrowthModel(gmDel, ax)
            picture = './Resources/SimplePasture.jpg';
            title = 'Sheltered Pasture Growth Model';
            expo = {'The Sheltered Pasture Growth Model simulates a self-replacing sheep flock.', ...
                    'It uses a simple rain-based model to estimate FOO growth, and while the', ... 
                    'FOO is below an initial threshold, the flock must be grain fed.', ...
                    'Once the pasture FOO threshold is reached no further fodder costs', ...
                    'are incurred.'...
                    };
            try 
                im = imread(picture);
                im = im(end:-1:1,:,:);
            catch ME
                im = 0.3* ones(626, 417, 3);
            end

            axes(ax);
            cla
            image('CData', im);
            pos = [0 626 0 417];
            axis(pos);
            axis on
            hold on

           patch([0.05*pos(2) 0.05*pos(2) 0.95*pos(2) 0.95*pos(2)], [0.05*pos(4), 0.95*pos(4), 0.95*pos(4), 0.05*pos(4)], [0,0,0,0], 'k', 'FaceAlpha', 0.5);

           % Put it at 10%, 10%
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

        function outputsColumn = calculateOutputs(gmd, state, unitOrRate) %#ok<MANU>
            
            persistent numeratorUnits
            persistent denominatorUnits
            persistent outputRates
            
            if isempty(numeratorUnits)
                numeratorUnits = [ ...
                    Unit('', 'FOO', 'kg'), ...
                    Unit('', 'FOO Shortfall', '%'), ...
                    Unit('', 'Shelter Productivity Bump', '%') ...
                ];
            end

            if isempty(denominatorUnits)
                denominatorUnits = [ ...
                    Unit('', 'Area', 'Hectare'), ...
                    Unit('', '', 'Unit'), ...
                    Unit('', '', 'Unit'), ...
                ];
            end
                    
                        
            if isempty(state)                
                if nargin == 3
                    
                    if length(denominatorUnits) ~= length(numeratorUnits)
                        error('ShelteredPastureGrowthModel needs the same number of numerator units as denominator units.');
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
                outputRates = [ ...
                    Rate(0, numeratorUnits(1), denominatorUnits(1)); ...
                    Rate(0, numeratorUnits(2), denominatorUnits(2)); ...
                    Rate(0, numeratorUnits(3), denominatorUnits(3)); ...
                    ];
                outputsColumn = outputRates;            
                return
            end
                        
            % The only output is the FOO, returned as FOO / Ha
            outputRates = [
                Rate(state.FOO, numeratorUnits(1), denominatorUnits(1)); ...
                Rate(state.percentShortfall * 100, numeratorUnits(2), denominatorUnits(2)); ...
                Rate(state.bumpPercentage * 100, numeratorUnits(3), denominatorUnits(3)) ...
            ];
            outputsColumn = outputRates;
            
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
        % The Establishment transition function should initialise the state. 
        function [outputProducts, eventOutputs] = transitionFunction_Establishment(gmDel, plantedCrop, sim) 
            outputProducts = Rate.empty(1, 0);
            eventOutputs = Rate.empty(1, 0);
            
            % Return list of products and outputs if called with no
            % arguments.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate.empty(1, 0);
                return; 
            end
            
                        
            % ASSUMES planting always in month 1. (forced by the regime.)
            % regime year is the number of years into the regime.
            regimeYear = sim.year - (floor(sim.currentPrimaryInstalledRegime.installedMonth-1/ 12)+1) + 1;            
            if sim.month == 1 && regimeYear > 1
                % This carries over the FOO from the end of last year when
                % we start a new crop in the same regime.
                lastCropIndex = regimeYear - 1;
                newState.FOO = sim.currentPrimaryInstalledRegime.plantedCrops(lastCropIndex).states{2, 12}.FOO;
                newState.percentShortfall = sim.currentPrimaryInstalledRegime.plantedCrops(lastCropIndex).states{2, 12}.percentShortfall;
                newState.bumpPercentage = sim.currentPrimaryInstalledRegime.plantedCrops(lastCropIndex).states{2, 12}.bumpPercentage;
                newState.NCZWidth = [];
                plantedCrop.state = newState;
                return
            end 
            
            newState.FOO = 0;
            newState.NCZWidth = [];
            newState.percentShortfall = 0;
            newState.bumpPercentage = 0;

            plantedCrop.state = newState;
        end
        
        function [outputProducts, eventOutputs] = transitionFunction_Shearing(gmDel, plantedCrop, sim) 

            eventOutputs = Rate.empty(1, 0);

            % outputProducts are wool. In this GM we actually output a 
            % homogenised $/DSE based on the structure of the flock and
            % the nominal prices and amounts expected from the different 
            % components
            unit = Unit('', 'Nominal Wool Income', 'Dollar');
            denominatorUnit = Unit('', 'DSE', 'Unit');

            % Return list of products and outputs if called with no
            % arguments.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, unit, denominatorUnit);
                return; 
            end
    
            % Get the settings from the settings file.
            [~, name, ~] = fileparts(gmDel.FOO.shelterSettingsFile);
            settings = eval(name);

            
            % We can use our woolSales parameters to average out the $/DSE
            % for wool.
            % Gives us $ / DSE (nominal)
            wool = [ ...
                    cell2mat(struct2cell(gmDel.woolSales.ewes))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.eweHoggets))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.eweLambs))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.rams))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.wethers))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.wetherHoggets))'; ...
                    cell2mat(struct2cell(gmDel.woolSales.wetherLambs))';
                    ];
            
            % Head, Kg/Hd, $/kg.
            woolHd = wool(:, 1);
            incomePerHd = wool(:,2) .* wool(:,3);
            
            % If the paddock is sheltered, apply the shelter benefits
            % through increased sheep sales.
            % Get the regime's tree height.
            heightUnit = Unit('', 'Height', 'm');
            if ~isempty(sim.currentSecondaryPlantedCrop)
                TH = sim.currentSecondaryPlantedCrop.getAmount(heightUnit);
            else
                TH = [];
            end
            
            if (~isempty(TH))
               TH = TH.number;
            else
                TH = 0;
            end
            
            if (TH > settings.shelterBenefitMinHeight)
                TH = min(TH, settings.shelterBenefitMaxHeight);
                allDeaths = [ ...
                    settings.allDeaths.ewe; ...,
                    settings.allDeaths.eweHogget; ...,
                    settings.allDeaths.eweLamb; ...,
                    settings.allDeaths.ram; ...,
                    settings.allDeaths.wether; ...,
                    settings.allDeaths.wetherHogget; ...,
                    settings.allDeaths.wetherLamb; ...
                    ];
                woolHd = woolHd + allDeaths * settings.shelterBenefitMax * ...
                    (TH - settings.shelterBenefitMinHeight) / ...
                    (settings.shelterBenefitMaxHeight - settings.shelterBenefitMinHeight);
                woolHd = floor(woolHd);
            end 
                
            woolIncome = sum(woolHd .* incomePerHd) / gmDel.woolSales.DSEPer1000;
            
            outputProducts = Rate(woolIncome, unit, denominatorUnit);
            
        end
        
        % Feeding occurs during the feedgap.
        % Output tonnes of feed per DSE.
        function [outputProducts, eventOutputs] = transitionFunction_Feeding(gmDel, plantedCrop, sim) 


            % no outputProducts. But we have event outputs of tonnes of grain per DSE.
            unit = Unit('', 'Feed Grain', 'Tonne');
            denominatorUnit = Unit('', 'DSE', 'Unit');

            % Return list of products and outputs if called with no
            % arguments.
            outputProducts = Rate.empty(1, 0);
            if(isempty(plantedCrop) && isempty(sim))
                eventOutputs = Rate(0, unit, denominatorUnit);
                return; 
            end
    
            % Work out the tonnes required per 1000 ewes, and divide by DSE
            % per 1000 ewes.
            % Use the numbers from the woolSales table.
            
            ewes = cell2mat(struct2cell(gmDel.woolSales.ewes));
            eweHoggets = cell2mat(struct2cell(gmDel.woolSales.eweHoggets));
            eweLambs = cell2mat(struct2cell(gmDel.woolSales.eweLambs));
            rams = cell2mat(struct2cell(gmDel.woolSales.rams));
            wethers = cell2mat(struct2cell(gmDel.woolSales.wethers));
            wetherHoggets = cell2mat(struct2cell(gmDel.woolSales.wetherHoggets));
            wetherLambs = cell2mat(struct2cell(gmDel.woolSales.wetherLambs));

            sheep1 = [
                ewes(1), ...
                eweHoggets(1), ...
                eweLambs(1), ...
                rams(1), ...
                wethers(1), ...
                wetherHoggets(1), ...
                wetherLambs(1)];
            
            sheep2  = [
                gmDel.fodderCosts.ewe, ...
                gmDel.fodderCosts.eweHogget, ...
                gmDel.fodderCosts.eweLamb, ...
                gmDel.fodderCosts.ram, ...
                gmDel.fodderCosts.wether, ...
                gmDel.fodderCosts.wetherHogget, ...
                gmDel.fodderCosts.wetherLamb, ...
                ];

            % How many weeks of the month did the sheep require feeding?
            % We can use the percentShortfall parameter on the state to
            % work out how to pro-rata the supplementary feeding.
            
            % FEB 2018 - Overriding the 'numberOfWeeks' calc          
            % We're just simplifying to 1 month = 4 weeks.
            if (plantedCrop.state.percentShortfall > 0)
                numberOfWeeks = 4 * plantedCrop.state.percentShortfall;
            end
                        
            % sheep1 gives hd. sheep2 gives kg/hd/week. (in a 1000 ewe flock)           
            % total kg/week = kg/hd/week * hd.
            % so sheep1 * sheep2 = kg/week
            % tonnes/month = kg/week * weeks / 1000; (still in terms of a
            % 1000 ewe flock).
            feedTonnesPer1000Ewes = sheep1 * sheep2' * numberOfWeeks / 1000;
            
            % convert from a 1000 ewe flock to however big our flock
            % actually is.
            feedTonnesPerDSE = feedTonnesPer1000Ewes / gmDel.woolSales.DSEPer1000;
            % tonnes / 1000 ewes / month / (DSE / 1000 ewes) = tonnes / DSE / month 
            
            % gives tonnes/DSE in this month.
            eventOutputs = Rate(feedTonnesPerDSE, unit, denominatorUnit);
            
        end
        
        
        function [outputProducts, eventOutputs] = transitionFunction_Sheep_Sales(gmDel, plantedCrop, sim) 
            
            unit = Unit('', 'Nominal Meat Income', 'Dollar');
            denominatorUnit = Unit('', 'DSE', 'Unit');

            eventOutputs = Rate.empty(1, 0);

            % Return list of products and outputs if called with no
            % arguments.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, unit, denominatorUnit);
                return; 
            end
            
            % Get the settings from the settings file.
            [~, name, ~] = fileparts(gmDel.FOO.shelterSettingsFile);
            settings = eval(name);

            % We can use our sheepSales parameters to average out the $/DSE
            % for sheep.
            % Gives us $ / DSE (nominal)
            CFAEwes = cell2mat(struct2cell(gmDel.sheepSales.CFAEwes));
            eweHoggets = cell2mat(struct2cell(gmDel.sheepSales.eweHoggets));
            eweLambs = cell2mat(struct2cell(gmDel.sheepSales.eweLambs));
            CFARams = cell2mat(struct2cell(gmDel.sheepSales.CFARams));
            CFAWethers = cell2mat(struct2cell(gmDel.sheepSales.CFAWethers));
            wetherHoggets = cell2mat(struct2cell(gmDel.sheepSales.wetherHoggets));
            wetherLambs = cell2mat(struct2cell(gmDel.sheepSales.wetherLambs));

            salesHd = [ ...
                CFAEwes(1); ...
                eweHoggets(1); ...
                eweLambs(1); ...
                CFARams(1); ...
                CFAWethers(1); ...
                wetherHoggets(1); ...
                wetherLambs(1) ...
                ];
            
            % If the paddock is sheltered, apply the shelter benefits
            % through increased sheep sales.
            % Get the regime's tree height.
            heightUnit = Unit('', 'Height', 'm');
            if~isempty(sim.currentSecondaryPlantedCrop)
                TH = sim.currentSecondaryPlantedCrop.getAmount(heightUnit);
            else
                TH = [];
            end
            
            if (~isempty(TH))
               TH = TH.number;
            else
                TH = 0;
            end
            
            if (TH > settings.shelterBenefitMinHeight)
                TH = min(TH, settings.shelterBenefitMaxHeight);
                allDeaths = [ ...
                    settings.allDeaths.ewe; ...,
                    settings.allDeaths.eweHogget; ...,
                    settings.allDeaths.eweLamb; ...,
                    settings.allDeaths.ram; ...,
                    settings.allDeaths.wether; ...,
                    settings.allDeaths.wetherHogget; ...,
                    settings.allDeaths.wetherLamb; ...
                    ];
                salesHd = salesHd + allDeaths * settings.shelterBenefitMax * ...
                    (TH - settings.shelterBenefitMinHeight) / ...
                    (settings.shelterBenefitMaxHeight - settings.shelterBenefitMinHeight);
                salesHd = floor(salesHd);
            end 
            
            % Percentage of CS2 / CS3...
            currentFOO = plantedCrop.state.FOO;
            
            if (currentFOO < gmDel.FOO.for100PercentCS2)
               CS2 = 1;
               CS3 = 0;
            elseif (currentFOO > gmDel.FOO.for100PercentCS3)
               CS2 = 0;
               CS3 = 1;
            else
               CS2 = (currentFOO - gmDel.FOO.for100PercentCS2) / (gmDel.FOO.for100PercentCS3 -  gmDel.FOO.for100PercentCS2);
               CS3 = 1 - CS2;
            end
            
            % The price per hd.
            price = [ ...
                CFAEwes(2) * CS2 + CFAEwes(3) * CS3; ...
                eweHoggets(2) * CS2 + eweHoggets(3) * CS3; ...
                eweLambs(2) * CS2 + eweLambs(3) * CS3; ...
                CFARams(2) * CS2 + CFARams(3) * CS3; ...
                CFAWethers(2) * CS2 + CFAWethers(3) * CS3; ...
                wetherHoggets(2) * CS2 + wetherHoggets(3) * CS3; ...
                wetherLambs(2) * CS2 + wetherLambs(3) * CS3 ...
            ];

            % Work out total meat sales based on Hd in each category and price.
            meatSales = salesHd .* price;
                           
            % Convert to DSE.
            meatSales = sum(meatSales / gmDel.woolSales.DSEPer1000);
            
            outputProducts = Rate(meatSales, unit, denominatorUnit);
            
        end
        
        
        % Destruction doesn't do anything but we implement the function
        % so that the framework works.
        function [outputProducts, eventOutputs] = transitionFunction_Destruction(gmDel, plantedCrop, sim) %#ok<MANU>
            
            outputProducts = Rate.empty(1, 0);
            eventOutputs = Rate.empty(1, 0);
                
        end
       
        
    end

    % Validation Methods
    methods
        
        % Checks that the class is right and things aren't empty
        function valid = gmdIsValid(gmd)
            valid = isa(gmd, 'ShelteredPastureGrowthModelDelegate');
        end
        
        % Checks that the parameters are consistent and ready to go!
        % Note, this should really check quite a bit more. At least that
        % all the fields exist and are of the correct type.
        function ready = gmdIsReady(gmd)
            ready = gmdIsValid(gmd);
            if ~ready || isempty(gmd.FOO) || ...
                isempty(gmd.fodderCosts) || isempty(gmd.woolSales) || isempty(gmd.sheepSales)
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
   
    methods
        function trigger = getTriggerForEvent(gmDel, eventName)

            months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
            switch eventName

                case 'Establishment'
                    % Establishment is based on the regime
                    trigger = Trigger();

                case 'Feeding'

                    trigger = Trigger;
                    
                    % Feb 2018 - Setting to threshold based again.
                    numeratorUnits = Unit('', 'FOO', 'kg');
                    denominatorUnits = Unit('', 'Area', 'Hectare');
                    
                    c1 = ImagineCondition.newCondition('Quantity Based', 'FOO > threshold');
                    c1.comparator = '<=';
                    c1.quantityType = 'Output';                    
                    c1.rate = Rate(gmDel.FOO.requiredBeforeGrazing, numeratorUnits, denominatorUnits);
                    
                    trigger.conditions = {c1};
                    
                case 'Shearing'
                    % If the month is shearing month

                    c1 = ImagineCondition.newCondition('Month Based', ['Month is ', gmDel.woolSales.shearingMonth]);
                    c1.monthIndex = gmDel.woolSales.shearingMonth;
                    
                    trigger = Trigger;
                    trigger.conditions = {c1};
                    
                case 'Sheep Sales'

                    % If the month is sheep sales month.
                    c1 = ImagineCondition.newCondition('Month Based', ['Month is ', gmDel.sheepSales.sheepSalesMonth]);
                    c1.monthIndex = gmDel.sheepSales.sheepSalesMonth;
                    
                    trigger = Trigger;
                    trigger.conditions = {c1};
                    
                case 'Destruction'
                    % Destruction is based on the regime.
                    trigger = Trigger();
                otherwise
                    error('ShelteredPastureGrowthModelDelegate: Tried to get trigger for unknown event.');
            end
        end        
    end
    
end


% This function makes the triggers for the Sheltered Pasture events.
% The cost price models are provided with a default denominatorUnit.
% Note that the denominatorUnit must match the growthModelOutput units 
% or the regimeOutputUnits for the cropCategory this growthModel is made
% for.
function [initialEvents, regularEvents, destructionEvents] =  makeShelteredPastureImagineEvents()

    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');
    status = ImagineEventStatus('core', true, true, true, false, true);

    % Set up the planting event
    % Price is 'per Hectare'
    denominatorUnit = Unit('', 'Area', 'Hectare');
    costPriceModel = PriceModel('Establishment', unit, denominatorUnit, true);

    initialEvents  = ImagineEvent('Establishment', status, costPriceModel);
 
    % Regular events are 'Shearing', 'Sheep Sales'.
    status = ImagineEventStatus('core', true, false, true, false, true);

    % Price is 'per nominal shearing cost'
%    denominatorUnit = Unit('', 'Nominal Shearing Cost', 'Hectare');
    denominatorUnit = Unit('', 'DSE', 'Unit');
    costPriceModel = PriceModel('Shearing', unit, denominatorUnit, true);

    regularEvents(1)  = ImagineEvent('Shearing', status, costPriceModel);

    denominatorUnit = Unit('', 'DSE', 'Unit');
    costPriceModel = PriceModel('Sheep Sales', unit, denominatorUnit, true);
    
    regularEvents(2) = ImagineEvent('Sheep Sales', status, costPriceModel);
 
    % Feeding Event
     denominatorUnit = Unit('', 'Feed Grain', 'Tonne');
     costPriceModel = PriceModel('Feeding', unit, denominatorUnit, true);
     regularEvents(3) = ImagineEvent('Feeding', status, costPriceModel);
            
    
    % Only a token destruction event
    status = ImagineEventStatus('core', true, true, true, false, true);
    denominatorUnit = Unit('', 'Area', 'Hectare');
    costPriceModel = PriceModel('Destruction', unit, denominatorUnit, true);
    destructionEvents = ImagineEvent('Destruction', status, costPriceModel);

end

% This function makes the productPriceModels. 
% It defines what the products are. The denominator units used define the 
% units of the product. These are not changed later. Therefore care must be
% taken to ensure that the denominator units here match the numerator units
% in the rate returned by a transition function.
function pPMs = makeShelteredPastureProductPriceModels

    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

%    denominatorUnit = Unit('', 'Wool', 'Kg');
    denominatorUnit = Unit('', 'Nominal Wool Income', 'Dollar');
    pPMs = PriceModel('Wool Income', unit, denominatorUnit);

%    denominatorUnit = Unit('', 'DSE', 'Unit');    
    denominatorUnit = Unit('', 'Nominal Meat Income', 'Dollar');
    pPMs(2) = PriceModel('Sheep Sales Income', unit, denominatorUnit);

end

