% This is the implementation of a concrete SimplePastureGrowthModelDelegate 
% based on the Abstract class.
%
% The SimplePastureGrowthModel models a self-replacing flock on a pasture.
% It produces wool and sheep for sale.
% FOO is modeled in a simple way: a set small FOO is expected at the end of
% summer, which will then grow some amout per mm of rainfall.
% Fodder is required for the sheep when the FOO is below a threshold (eg
% 1100 kg / Ha.) This adds costs, particularly if the rain comes late.
%
classdef SimplePastureGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties
        modelName = 'Simple Pasture'; 
        
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


    % These are the Simple Pasture model specific properties.
    properties (Access = public)
        
        FOO
        fodderCosts
        woolSales
        sheepSales
        spatialInteractions

    end
       
    
    methods (Static)
       
        function obj = loadobj(obj)

            if isstruct(obj)
                newObj = SimplePastureGrowthModelDelegate();
                fns = fieldnames(obj);
                for i = 1:length(fns)
                    try
                       newObj.(fns{i}) = obj.(fns{i}); 
                    catch e
                    end
                end
            else                
                gm = setupParameters(obj.FOO, obj.fodderCosts, obj.woolSales, obj.sheepSales, obj.spatialInteractions);            
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
        function gmDel = SimplePastureGrowthModelDelegate(gm)
            if nargin > 0
                super_args = {gm};
            else
                super_args = {};
            end
            
            gmDel = gmDel@GrowthModelDelegate(super_args{:});
            
            % Now set up the specific default parameters for this growth model.
            
            % The priceModels, events and outputUnits need to be set up
            % here.
            [init, reg, dest] = makeSimplePastureImagineEvents;
            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            gmDel.productPriceModels = makeSimplePastureProductPriceModels;
            
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
            
            % The SimplePasture model only needs to add on some FOO if
            % there's been some rainfall.
            % In the period where we don't care, we'll set the FOO to 0.            
            
            % To work out the increasePerMM we use the max and min points
            % of the sin (ish) curve defined with peakFOOPerMMMonth,
            % peakFOOPer and the corresponding Min version.
            % We've got pi between each point and we have to offset the sin
            % curve.
            increasePerMM = GetFOOIncreasePerMM(gmd.FOO.peakFOOPerMMMonth, gmd.FOO.peakFOOPerMM, gmd.FOO.minFOOPerMMMonth, gmd.FOO.minFOOPerMM, sim.month);
            
            % The increasePerMM can be directly affected by competition.
            
            temporalModifier = 1;
            spatialModifier = 1;
%            lostYield = 0; % Used for putting competition cost into state.
      %      newState.competitionExtent = 0;
            
%             newState.yieldLostToOnlyCompetitionPerPaddock = 0;
%             newState.yieldGainWaterloggingPerPaddock = 0;
%             newState.waterloggingExtentPastNCZ = 0;
%             newState.competitionExtentPastNCZ = 0;
%             newState.waterImpact = 0;
%             newState.compImpact = 0;
%             newState.compIntensityAtNCZ = 0;
%             newState.waterIntensityAtNCZ = 0;
%             
%             yieldLossFromCompetition = 0;
%             yieldGainFromWaterlogging = 0;
%             compYieldLoss = 0;
%             waterYieldGain = 0;
%             waterExtent = 0;
%             compExtent = 0;
%             waterImpact = 0;
%             compImpact = 0;
%                         
            baseYield = 1;

            if ~isempty(gmd.spatialInteractions) && ~isempty(sim.currentSecondaryInstalledRegime)
                
                sis = gmd.spatialInteractions;
                if isempty(plantedCrop.state.NCZWidth)
                    NCZWidth = 0;
                else
                    NCZWidth = plantedCrop.state.NCZWidth;
                end
                
              %  if sis.isValid
             
                    % First calculate the impact. Need the expected GSR for
                    % that. Need to get the GSR to date. Then compare with
                    % expected GSR to date. Then scale by expected GSR.
                    firstRM = 1;
                    lastRM = 12;
                    if sim.month < lastRM 
                        % then estimate gsr
                        firstRelevantMonthIndex = (sim.year - 1) * 12 + firstRM;
                       GSR2Date = sum(sim.monthlyRainfall(firstRelevantMonthIndex:sim.monthIndex));
                       climateMgr = ClimateManager.getInstance;
                       averageRainfall = climateMgr.getMonthlyAverageRainfall;
                       avGSR2Date = sum(averageRainfall(firstRM:sim.month));
                       avGSR = sum(averageRainfall(firstRM:lastRM));
                       % expected gsr
                       gsr = avGSR * GSR2Date / avGSR2Date;
                    else
                        % Then we know the gsr.
                        firstRelevantMonthIndex = (sim.year - 1) * 12 + firstRM;
                       gsr = sum(sim.monthlyRainfall(firstRelevantMonthIndex:sim.monthIndex)); 
                    end
              
                    [compImpact, waterImpact] = getImpact(sis, gsr);
                    
                    % To calculate the spatial modifier, we'll ask the secondary
                    % regime for a few outputs. We need the crop area and the 'Crop
                    % Interface' length, which is basically how long the
                    % competition zone is.

                    % Once we have the biomass for a tree, we have the curve. Then
                    % with the extent and the interface length we can work out the
                    % area that's  affected. Then we need to ask the crop for it's
                    % area. We work out the effective lost area as a percentage of
                    % the total area. This is the spatial modifier.
                    cropInterfaceUnit = Unit('', 'Crop Interface Length', 'm');
                    cropAreaUnit = Unit('', 'Area', 'Ha');

                    % Also need the spacing within rows so we can calculate
                    % competition costs fairly with different layouts.
                    plantSpacing = sim.currentSecondaryInstalledRegime.getRegimeParameter('plantSpacing');
                    if isempty(plantSpacing)
                        error('Need to be able to access the regime''s plantSpacing parameter.');
                    end
                    
                    % Get the crop interface from the secondary regime. If the
                    % regime doesn't implement the crop interface output then we'll
                    % assume that it's zero.
                    cropInterface = Amount(0, cropInterfaceUnit); 
                    if ~isempty(sim.currentSecondaryInstalledRegime)
                         if ~isempty(sim.currentSecondaryPlantedCrop)
                            cropInterface = sim.currentSecondaryInstalledRegime.getAmount(cropInterfaceUnit);
                         end
                    end

                    cropArea = plantedCrop.getAmount(cropAreaUnit);
                    
                    % Get raw spatial interactions bounds from sis:
                    BGBMUnit = Unit('', 'Below-ground Biomass', 'Tonne');
                    AGBMUnit = Unit('', 'Above-ground Biomass', 'Tonne');
                    if~isempty(sim.currentSecondaryPlantedCrop)
                        BGBM = sim.currentSecondaryPlantedCrop.getAmount(BGBMUnit);
                        AGBM = sim.currentSecondaryPlantedCrop.getAmount(AGBMUnit);
                        if isempty(BGBM)
                            BGBM = Amount(0, BGBMUnit);
                            AGBM = Amount(0, AGBMUnit);
                        end
                    else
                        BGBM = Amount(0, BGBMUnit);
                        AGBM = Amount(0, AGBMUnit);
                    end
                    [compExtent, compYieldLoss, waterExtent, waterYieldGain] = sis.getRawSIBounds(AGBM.number * 1000, BGBM.number * 1000, plantSpacing);
                    
                    
                    
                    % Scale percentage numbers to [0, 1]
                    compYieldLoss = compYieldLoss / 100;
                    waterYieldGain = waterYieldGain / 100;
                    
                    csir = sim.currentSecondaryInstalledRegime;
                    exclusionZoneWidth = 0;
                    if ~isempty(csir)
                        regObj = csir.regimeObject;  
                        exclusionZoneWidth = regObj.getExclusionZoneWidth;
                    end
                    
        %            newState.competitionExtent = max(compExtent - NCZWidth - exclusionZoneWidth, 0);
                    
                    % modify bounds based on the NCZ
                    if compExtent > (NCZWidth + exclusionZoneWidth) && compExtent > 0
                        compYieldLoss = compYieldLoss * (compExtent - NCZWidth - exclusionZoneWidth) / compExtent;
                        compExtent = compExtent - NCZWidth - exclusionZoneWidth;
                    else
                       compExtent = 0; 
                       compYieldLoss = 0;
                    end
                    
                    if waterExtent > (NCZWidth + exclusionZoneWidth) && waterExtent > 0
                        waterYieldGain = waterYieldGain * (waterExtent - NCZWidth - exclusionZoneWidth) / waterExtent;
                        waterExtent = waterExtent - NCZWidth - exclusionZoneWidth;
                    else
                        waterExtent = 0; 
                        waterYieldGain = 0;
                    end                    
                    
                    affectedExtent = 0;
                    if compExtent > affectedExtent
                        affectedExtent = compExtent;
                    end
                    if waterExtent > affectedExtent
                        affectedExtent = waterExtent;
                    end
                    
                    % Must have +ve area.
                    if affectedExtent > 0 && ~isempty(cropInterface)

                        affectedAreaHa = cropInterface.number * affectedExtent / 10000;

                        areaOfSIWaterCurve = waterYieldGain * waterImpact * waterExtent / 2;
                        areaOfSICompCurve = compYieldLoss * compImpact * compExtent / 2;

                        areaOfSICompAbove100 = 0;
                        if compYieldLoss * compImpact > 1
                           ext = compExtent * (compYieldLoss * compImpact - 1) / (compYieldLoss * compImpact); 
                           areaOfSICompAbove100 = (compYieldLoss * compImpact - 1) * ext / 2;
                        end

                        normalAreaUnderCurve = 1 * affectedExtent;
                        areaUnderCurve = normalAreaUnderCurve - areaOfSICompCurve + areaOfSIWaterCurve + areaOfSICompAbove100;
                    
                        spatialModifier = areaUnderCurve / normalAreaUnderCurve;
                    
       %                 competitionSIComponent = (areaOfSICompCurve - areaOfSICompAbove100) / normalAreaUnderCurve;
       %                 waterloggingSIComponent = areaOfSIWaterCurve / normalAreaUnderCurve;
                        
             %           a = affectedAreaHa
             %           b = baseYield
             %           t = temporalModifier
             %           s = spatialModifier
                    
                        affectedAreaYield = affectedAreaHa * baseYield * temporalModifier * spatialModifier;

%                        yieldLossFromCompetition  = affectedAreaHa * baseYield * temporalModifier * competitionSIComponent;
%                        yieldGainFromWaterlogging = affectedAreaHa * baseYield * temporalModifier * waterloggingSIComponent;
                        
 %                       lostYield = affectedAreaHa * baseYield * temporalModifier - affectedAreaYield;
                        
                        % Totoal Yield comes from base * temporal yield
                        % on main alley, + base * temporal * spatial on
                        % affected area. Total Yield Per Ha comes from Total Yield / cropArea.
                        totalYieldPerHa = ((cropArea.number - affectedAreaHa) * baseYield * temporalModifier + affectedAreaYield) / cropArea.number;

                        % Therefore deduce spatial modifier:
                        spatialModifier = totalYieldPerHa / baseYield / temporalModifier;
                    end
               % end
            end
    
            % Apply spatial modifier.
            increasePerMM = increasePerMM * spatialModifier;
            
            if sim.month == gmd.FOO.firstFeedGapMonth
                FOOGrowth = sim.monthlyRainfall(sim.monthIndex) * increasePerMM;
                newState.FOO = gmd.FOO.availableAtStart + FOOGrowth;                
            elseif sim.month > gmd.FOO.firstFeedGapMonth && sim.month <= gmd.sheepSales.sheepSalesMonth

                FOOGrowth = sim.monthlyRainfall(sim.monthIndex) * increasePerMM;
                newState.FOO = newState.FOO + FOOGrowth;
            else
               newState.FOO = 0; 
            end
            
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
            model.spatialInteractions = gmDel.spatialInteractions;
            
            output = SimplePastureGrowthModelDialog(model, cropName);
            if ~isempty(output)
               gmDel.FOO = output.FOO;
               gmDel.fodderCosts = output.fodderCosts;
               gmDel.woolSales = output.woolSales;
               gmDel.sheepSales = output.sheepSales; 
               gmDel.spatialInteractions = output.spatialInteractions;
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
            title = 'Simple Pasture Growth Model';
            expo = {'The Pasture Growth Model simulates a self-replacing sheep flock.', ...
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
                numeratorUnits = Unit('', 'FOO', 'kg');
            end

            if isempty(denominatorUnits)
                denominatorUnits = Unit('', 'Area', 'Hectare');
            end
                    
                        
            if isempty(state)                
                if nargin == 3
                    
                    if length(denominatorUnits) ~= length(numeratorUnits)
                        error('SimplePastureGrowthModel needs the same number of numerator units as denominator units.');
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
                outputRates = Rate(0, numeratorUnits, denominatorUnits);
                outputsColumn = outputRates;            
                return
            end
                        
            % The only output is the FOO, returned as FOO / Ha
            outputRates(1).number = state.FOO;
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
            
            newState.FOO = 0;
            newState.NCZWidth = [];

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
    
            % We can use our woolSales parameters to average out the $/DSE
            % for wool.
            % Gives us $ / DSE (nominal)
            wool = ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.ewes))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.eweHoggets))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.eweLambs))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.rams))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.wethers))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.wetherHoggets))) + ...
                   prod(cell2mat(struct2cell(gmDel.woolSales.wetherLambs)));
            wool = wool / gmDel.woolSales.DSEPer1000;
            
            outputProducts = Rate(wool, unit, denominatorUnit);
            
        end
        
        % Feeding occurs during the feedgap.
        % Output tonnes of feed per DSE.
        function [outputProducts, eventOutputs] = transitionFunction_Feeding(gmDel, plantedCrop, sim) 


            % no outputProducts. But we have envent outputs of tonnes of grain per DSE. 
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
%             sheep2 = [
%                 ewes(1), ...
%                 eweHoggets(1), ...
%                 eweLambs(1), ...
%                 rams(1), ...
%                 wethers(1), ...
%                 wetherHoggets(1), ...
%                 wetherLambs(1)];            
            
            % How many weeks of the month did the sheep require feeding?
            % Get FOO at start of month and FOO at end.
            % If end of month FOO is less than required for grazing, then 4
            % weeks feed.
            % Otherwise, pro-rata based on how far through the month we'd
            % have had to wait if rainfall was evenly spread.
            stateStart = plantedCrop.states{1, sim.monthIndex - plantedCrop.plantedMonth + 1};
            FOOStart = stateStart.FOO;
            FOOEnd = plantedCrop.state.FOO;
            if (FOOEnd < gmDel.FOO.requiredBeforeGrazing)
                numberOfWeeks = 4;
            elseif (FOOStart > gmDel.FOO.requiredBeforeGrazing)
                numberOfWeeks = 0;
            else
                numberOfWeeks = 4 * (gmDel.FOO.requiredBeforeGrazing - FOOStart) / (FOOEnd - FOOStart); 
            end
            
            feedTonnesPer1000Ewes = sheep1 .* sheep2 * numberOfWeeks / 1000;
            feedTonnesPerDSE = feedTonnesPer1000Ewes / gmDel.woolSales.DSEPer1000;
            
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

            % The price for all sheep at CS2
            meatCS2 = ...
                   prod(CFAEwes([1 2])) + ...
                   prod(eweHoggets([1 2])) + ...
                   prod(eweLambs([1 2])) + ...
                   prod(CFARams([1 2])) + ...
                   prod(CFAWethers([1 2])) + ...
                   prod(wetherHoggets([1 2])) + ...
                   prod(wetherLambs([1 2]));
            % The price for all sheep at CS3:
            meatCS3 = ...
                   prod(CFAEwes([1 3])) + ...
                   prod(eweHoggets([1 3])) + ...
                   prod(eweLambs([1 3])) + ...
                   prod(CFARams([1 3])) + ...
                   prod(CFAWethers([1 3])) + ...
                   prod(wetherHoggets([1 3])) + ...
                   prod(wetherLambs([1 3]));
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
            
            % Work out total meat sales based on percentage of CS2 and
            % CS3.
            meat = meatCS2 * CS2 + meatCS3 * CS3;
               
            % Convert to DSE.
            meat = meat / gmDel.woolSales.DSEPer1000;
            
            outputProducts = Rate(meat, unit, denominatorUnit);
            
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
            valid = isa(gmd, 'SimplePastureGrowthModelDelegate');
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

%                     c1 = ImagineCondition('Quantity Based', 'FOO > threshold');
% 
%                     % Note that there is some subtlty in setting c1.string1 to a
%                     % single output value. The trigger panel has previously expected to be 
%                     % able to put the string straight into the control and set the
%                     % value.
%                     % I think it's better for forward compatability for the
%                     % triggerPanel to work out what the list of choices should be, then
%                     % select the one we've defined here. Therefore it should be fine
%                     % when setting the condition to list a single choice and have the
%                     % value = 1 (first choice).
% 
%                     c1.string1 = {'FOO'};
%                     c1.value1 = 1;
%                     c1.stringComp = {'=', '<', '>', '<=', '>='};
%                     c1.valueComp = 5;
%                     c1.string2 = num2str(gmDel.FOO.requiredBeforeGrazing);
%                     c1.value2 = 1;       
%                     
%                     c1.parameters1String = 'Area'; 
%                     c1.parameters2String = 'Hectare';
% 
% 
                    c1 = ImagineCondition.newCondition('Month Based', ['Month is ', months{gmDel.FOO.firstFeedGapMonth}]);
                    c1.monthIndex = gmDel.FOO.firstFeedGapMonth;
                     
%                     c1.string1 = '';
%                     c1.value1 = 1;
%                     c1.stringComp = 'Month is';
%                     c1.valueComp = 1;
%                     c1.string2 = months;
%                     c1.value2 = gmDel.FOO.firstFeedGapMonth;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    
                    
                    c2 = ImagineCondition.newCondition('Month Based', ['Month is ', months{gmDel.FOO.firstFeedGapMonth + 1}]);
                    c2.monthIndex = gmDel.FOO.firstFeedGapMonth + 1;
             
%                     c2.string1 = '';
%                     c2.value1 = 1;
%                     c2.stringComp = 'Month is';
%                     c2.valueComp = 1;
%                     c2.string2 = months;
%                     c2.value2 = gmDel.FOO.firstFeedGapMonth + 1;
%                     c2.parameters1String = '';
%                     c2.parameters2String = '';

                    

                    c3 = ImagineCondition.newCondition('Month Based', ['Month is ', months{gmDel.FOO.firstFeedGapMonth + 2}]);
                    c3.monthIndex = gmDel.FOO.firstFeedGapMonth + 2;
                    
%                     c3.string1 = '';
%                     c3.value1 = 1;
%                     c3.stringComp = 'Month is';
%                     c3.valueComp = 1;
%                     c3.string2 = months;
%                     c3.value2 = gmDel.FOO.firstFeedGapMonth + 2;
%                     c3.parameters1String = '';
%                     c3.parameters2String = '';
                            
                          
                    c4 = ImagineCondition.newCondition('And / Or / Not', 'C1, C2, OR C3');
                    c4.logicType = 'And';
                    c4.indices = [1, 2, 3];
                    
%                     c4.string1 = {'AND', 'OR', 'NOT'};
%                     c4.value1 = 2;
%                     c4.stringComp = '';
%                     c4.valueComp = 1;
%                     c4.string2 = '1 2 3';
%                     c4.value2 = 1;       
%                     c4.parameters1String = '';
%                     c4.parameters2String = '';

                    trigger = Trigger;
                    trigger.conditions = {c1 c2 c3 c4};
                    
                case 'Shearing'
                    % If the month is shearing month

                    c1 = ImagineCondition('Month Based', ['Month is ', gmDel.woolSales.shearingMonth]);
                    c1.monthIndex = gmDel.woolSales.shearingMonth;
                    
%                     c1.string1 = '';
%                     c1.value1 = 1;
%                     c1.stringComp = 'Month is';
%                     c1.valueComp = 1;
%                     c1.string2 = months;
%                     c1.value2 = gmDel.woolSales.shearingMonth;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';
                    
                    trigger = Trigger;
                    trigger.conditions = {c1};
                    
                case 'Sheep Sales'

                    % If the month is sheep sales month.
                    c1 = ImagineCondition('Month Based', ['Month is ', gmDel.sheepSales.sheepSalesMonth]);
                    c1.monthIndex = gmDel.sheepSales.sheepSalesMonth;
                    
%                     c1.string1 = '';
%                     c1.value1 = 1;
%                     c1.stringComp = 'Month is';
%                     c1.valueComp = 1;
%                     c1.string2 = months;
%                     c1.value2 = gmDel.sheepSales.sheepSalesMonth;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    trigger = Trigger;
                    trigger.conditions = {c1};
                    
                case 'Destruction'
                    % Destruction is based on the regime.
                    trigger = Trigger();
                otherwise
                    error('SimplePastureGrowthModelDelegate: Tried to get trigger for unknown event.');
            end
        end        
    end
    
end


% This function makes the triggers for the Simple Pasture events.
% The cost price models are provided with a default denominatorUnit.
% Note that the denominatorUnit must match the growthModelOutput units 
% or the regimeOutputUnits for the cropCategory this growthModel is made
% for.
function [initialEvents, regularEvents, destructionEvents] =  makeSimplePastureImagineEvents()

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
function pPMs = makeSimplePastureProductPriceModels


    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

%    denominatorUnit = Unit('', 'Wool', 'Kg');
    denominatorUnit = Unit('', 'Nominal Wool Income', 'Dollar');
    pPMs = PriceModel('Wool Income', unit, denominatorUnit);

%    denominatorUnit = Unit('', 'DSE', 'Unit');    
    denominatorUnit = Unit('', 'Nominal Meat Income', 'Dollar');
    pPMs(2) = PriceModel('Sheep Sales Income', unit, denominatorUnit);

end

