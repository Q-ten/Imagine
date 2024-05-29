% This is a template for a concrete RainfallbasedGrowthModelDelegate based on the
% Abstract class.
%
% The rainfall based growth model is designed to model Annual crops, and
% simply uses a quadratic function to match yearly rainfall to yield. 
%
% It also provides a temporal modifier mechanism to give yield boosts or
% declines based on the crop that was planted in the previous year.
%
% It also gives a spatial yield modifier so that belts of trees may affect
% the yield. Crops close to the belts suffer yield decline due to water
% competition with the belt crop.
%
% The yield is meant to be based on a rain that falls during the growing
% season. It's quite a crude mechanism, simply defined by a quadratic
% curve. However, because we need to provide growth figures each month, we
% actually return the yield based on the growing season rainfall to date.
% By the end of the growing season, the result will match and along the way
% it will grow in a near-linear but at least increasing way, which is reasonable.
% 
% The temporal modifier simply uses a lookup table of crop and category
% names with yield modifiers. Because the crop must be an independent
% object, it cannot refer to other crops currently in Imagine. Therefore it
% must use names and categories. If the name of the crop in a previous year
% matches a name in the lookup table, that entry's yield modifier is used.
% If no matching name is found, the category name is tried. If neither the 
% name nor the category match, no yield modifier is applied. 
%
% The spatial temporal modifier assumes a maximal yield drop of crops on
% the edge of the alley, with the yield loss declining linearly into the
% field to the point where there is no competition. Therefore yield loss
% into the field is a function of the maximal yield loss at the edge, and
% the distance into the field that the competition acts.
% 
% We've used a simple mechanism that says the maximal yield loss is
% a function of the belt crop's above ground biomass (more leaves mean
% more transpiration, mean more water taken from the alley) and the
% distance of competition is a function of the below ground biomass (more
% roots mean that they cover a larger area.) The particular function used
% is described more in the transition function.
%
classdef RainfallBasedGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties
        modelName = 'Rainfall Based'; 
        
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


    % These are the Rainfall Based model specific properties.
    properties (Access = public)
        
        propagationParameters
        
        
        % eg propagtionParameters
        % eg event1TransitionFunctionParameters.
        % eg event2TransitionFunctionParameters.        
    end
    
    methods (Static)
       
        function obj = loadobj(obj)

            if isstruct(obj)
                newObj = RainfallBasedGrowthModelDelegate();
                fns = fieldnames(obj);
                for i = 1:length(fns)
                    try
                       newObj.(fns{i}) = obj.(fns{i}); 
                    catch e
                    end
                end
            else                
                gm = setupParameters(obj.propagationParameters);
                obj.propagationParameters = gm.propagationParameters;
                
                % The RainfallBasedGrowthModelDialog outputs empty entries
                % for plantingParmaeters and harvestingParameters but these
                % aren't actually fields of the growthModelDelegate. So
                % just use the propagationParameters field.

%                 gmFields = fieldnames(gm);
%                 for i = 1:length(gmFields)
%                    obj.(gmFields{i}) = gm.(gmFields{i}); 
%                 end
            end
        end
        
    end
    
    methods
    
        % These methods are required from the Abstract parent class
        % GrowthModelDelegate.
        
        % This is the constructor for the concrete subclass. It should set
        % up all the parent's Abstract properties here, then go on to setup
        % any parameters specific to the concrete subclass.
        function gmDel = RainfallBasedGrowthModelDelegate(gm)
            if nargin > 0
                super_args = {gm};
            else
                super_args = {};
            end
            
            gmDel = gmDel@GrowthModelDelegate(super_args{:});
            
            % Now set up the specific default parameters for this growth model.
            
            % The priceModels, events and outputUnits need to be set up
            % here.
            [init, reg, dest] = makeRainfallBasedImagineEvents;
            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            gmDel.productPriceModels = makeRainfallBasedProductPriceModels;
            
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
            
            % The rainfall based propagation works by calculating a base
            % yield, then modifying it by a temporal modifier (did previous
            % crop provide boost or defecit?) and a spatial modifier (do
            % existing trees in belts harm the yield?)
            
            % Base yield is calculated by summing the rain to date over the
            % 'relevant months' then applying the quadratic yield curve.
            % This can be calculated each month based on the rain to date
            % to provide some idea of how the crop is progressing.
            
            propParams = gmd.propagationParameters;
            
            % Need to get the rain to date over the relevant months.
            year = sim.year;
            relevantRainToDate = sim.monthlyRainfall((1:12 >= propParams.firstRelevantMonth & ...
                                              1:12 <= propParams.lastRelevantMonth & ...
                                              1:12 >= mod(plantedCrop.plantedMonth, 12) & ... 
                                              1:12 <= sim.month), year);
            baseYield = max(0, polyval(propParams.p, sum(relevantRainToDate)));
            
            % Calculate the temporal modifier by checking if the previous
            % year's crop is in the list of temporal modifiers.
            % If the crop cannot be found, we check if the category is in
            % the list. If a match is found then we use the percentage as
            % the temporal modifier.
            temporalModifier = 1;
            
            if ~isempty(gmd.propagationParameters.temporalModifiers)
                % Need to get the previous crop. Go via the plantedCrop's
                % parentRegime, it's list of planted crops and get the one
                % before if it exists. We won't go to the length of getting a
                % crop from a previous regime yet.

                previousPlantedCropIndex = plantedCrop.parentRegime.cropIndex - 1;
                if previousPlantedCropIndex > 0
                    previousPlantedCrop = plantedCrop.parentRegime.plantedCrops(previousPlantedCropIndex);
                    pPCName = previousPlantedCrop.cropObject.name;
                    pPCCat  = previousPlantedCrop.cropObject.categoryChoice;

                    % Get the modifier index that matched the name, and failing
                    % that the index that matched the categoy name.
                    gmd.propagationParameters
                    modifierIndex = find(strcmp(pPCName, gmd.propagationParameters.temporalModifiers(:,1)));
                    if isempty(modifierIndex)
                        modifierIndex = find(strcmp(pPCCat, gmd.propagationParameters.temporalModifiers(:,1)));                
                    end

                    if ~isempty(modifierIndex)
                        temporalModifier = gmd.propagationParameters.temporalModifiers{modifierIndex,2} / 100;     
                        assignin('base', 'tm', temporalModifier);
                    end

                end
            end            
            
            spatialModifier = 1;
            lostYield = 0; % Used for putting competition cost into state.
      %      newState.competitionExtent = 0;
            
            newState.yieldLostToOnlyCompetitionPerPaddock = 0;
            newState.yieldGainWaterloggingPerPaddock = 0;
            newState.waterloggingExtentPastNCZ = 0;
            newState.competitionExtentPastNCZ = 0;
            newState.waterImpact = 0;
            newState.compImpact = 0;
            newState.compIntensityAtNCZ = 0;
            newState.waterIntensityAtNCZ = 0;
            
            yieldLossFromCompetition = 0;
            yieldGainFromWaterlogging = 0;
            compYieldLoss = 0;
            waterYieldGain = 0;
            waterExtent = 0;
            compExtent = 0;
            waterImpact = 0;
            compImpact = 0;
                        
            if ~isempty(gmd.propagationParameters.spatialModifiers) && ~isempty(sim.currentSecondaryInstalledRegime)
                
                sis = gmd.propagationParameters.spatialModifiers;
                if isempty(plantedCrop.state.NCZWidth)
                    NCZWidth = 0;
                else
                    NCZWidth = plantedCrop.state.NCZWidth;
                end
                
              %  if sis.isValid
             
                    % First calculate the impact. Need the expected GSR for
                    % that. Need to get the GSR to date. Then compare with
                    % expected GSR to date. Then scale by expected GSR.
                    firstRM = gmd.propagationParameters.firstRelevantMonth;
                    lastRM = gmd.propagationParameters.lastRelevantMonth;
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
                    
                        competitionSIComponent = (areaOfSICompCurve - areaOfSICompAbove100) / normalAreaUnderCurve;
                        waterloggingSIComponent = areaOfSIWaterCurve / normalAreaUnderCurve;
                        
             %           a = affectedAreaHa
             %           b = baseYield
             %           t = temporalModifier
             %           s = spatialModifier
                    
                        affectedAreaYield = affectedAreaHa * baseYield * temporalModifier * spatialModifier;

                        yieldLossFromCompetition  = affectedAreaHa * baseYield * temporalModifier * competitionSIComponent;
                        yieldGainFromWaterlogging = affectedAreaHa * baseYield * temporalModifier * waterloggingSIComponent;
                        
                        lostYield = affectedAreaHa * baseYield * temporalModifier - affectedAreaYield;
                        
                        % Totoal Yield comes from base * temporal yield
                        % on main alley, + base * temporal * spatial on
                        % affected area. Total Yield Per Ha comes from Total Yield / cropArea.
                        totalYieldPerHa = ((cropArea.number - affectedAreaHa) * baseYield * temporalModifier + affectedAreaYield) / cropArea.number;

                        % Therefore deduce spatial modifier:
                        spatialModifier = totalYieldPerHa / baseYield / temporalModifier;
                        if sim.month == 12
                           a = 1; 
                           relevantRainToDate = relevantRainToDate;
                        end
                    end
               % end
            end

            newState.yield = baseYield * temporalModifier * spatialModifier;
            newState.yieldLostToCompetitionPerPaddock = lostYield;
            newState.yieldLostToOnlyCompetitionPerPaddock = yieldLossFromCompetition;
            newState.yieldGainWaterloggingPerPaddock = yieldGainFromWaterlogging;
            newState.waterloggingExtentPastNCZ = max(waterExtent, 0);
            newState.competitionExtentPastNCZ = max(compExtent, 0);
            newState.waterImpact = waterImpact;
            newState.compImpact = compImpact;
            newState.compIntensityAtNCZ = compYieldLoss * compImpact;
            newState.waterIntensityAtNCZ = waterYieldGain * waterImpact;
            if length(newState.yield) > 1
               a =1; 
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
            
            % Need current list of crop names and category list to go at
            % the end.  
            cropMgr = CropManager.getInstance;
            cropNames = cropMgr.cropNames;
            cats = CropCategory.setupCategories;
            output = RainfallBasedGMDialogue(cropInfo, gmDel.propagationParameters, cropNames, {cats.name});
            if ~isempty(output)
               
                gmDel.propagationParameters = output.propagationParameters;
                
            end
        end
        
        % This function renders a display of the growthModelDelegate's
        % parameters as a kind of summary. This is used in the crop wizard
        % and displays a summary of the saved growth model to be viewed
        % before and after the user enters the main GUI (launched via
        % setupGrowthModel above). This function should plot the summary on
        % ax, an axes object.
        function renderGrowthModel(gmDel, ax)
            picture = './Resources/field-rain.jpg';
            title = 'Rainfall-based Growth Model';
            expo = {'The Rainfall-based Growth Model models simple base yield output based', ... 
                    'on a quadratic function of GSR (Growing Season Rainfall).', ...
                    'The base yield is adjusted by temporal and spatial modifiers as appropriate,'...
                    'with the temporal modifier taking into account previous crops or crop ', ...
                    'categories, and the spatial modifier taking into account relevant', ...
                    'competition and benefit effects of any trees that may be planted.'};

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
                numeratorUnits = Unit.empty(1, 0);
            end

            if isempty(denominatorUnits)
                denominatorUnits = Unit.empty(1, 0);
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
                            if isempty(outputRates)
                                for i = 1:length(numeratorUnits)
                                    outputRates(i) = Rate(0, numeratorUnits(i), denominatorUnits(i));
                                end
                            end
                            outputsColumn = outputRates;
                    end
                    return
                end
            end
                
            
            % The calculateOutputs function should return a column of
            % nothing outputs if the state is empty. In this case however,
            % there are no outputs, so we don't have to worry.
            
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
        
        % The Planting transition function should initialise the state. 
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
            
            newState.yield = 0;
            newState.NCZWidth = [];
            newState.yieldLostToCompetitionPerPaddock = 0;
        %    newState.competitionExtent = 0;
            
            newState.yieldLostToOnlyCompetitionPerPaddock = 0;
            newState.yieldGainWaterloggingPerPaddock = 0;
            newState.waterloggingExtentPastNCZ = 0;
            newState.competitionExtentPastNCZ = 0;
            newState.waterImpact = 0;
            newState.compImpact = 0;
            newState.compIntensityAtNCZ = 0;
            newState.waterIntensityAtNCZ = 0;
            
            % Check for spatialModifiers in propagationParameters. 
            fns = fieldnames(gmDel.propagationParameters);
            ix = find(strcmp(fns, 'spatialModifiers'), 1, 'first');
            
            if ~isempty(ix)
                sis = gmDel.propagationParameters.spatialModifiers;
                if ~isempty(sis)
                    % Then we have a spatial interactions definition.
                    if sis.useNCZ
                       
                        switch sis.NCZChoice
                            
                            case 'Fixed Width'
                                NCZWidth = sis.NCZFixedWidth;
                                
                            case 'Optimised'
                                
                                optimisedParams = sis.NCZOptimisedParameters;
                                if (~isempty(optimisedParams))
                                    if (optimisedParams.isValid)
                                        % Then use the NCZ parameters to
                                        % calculate the width of the NCZ.
                                        NCZWidth = gmDel.calculateNCZOptimisedWidth(sis, plantedCrop, sim);                                       
                                    else
                                       NCZWidth = 0; 
                                    end
                                else
                                    NCZWidth = 0;                                   
                                end                                
                        end
                        newState.NCZWidth = NCZWidth;
                    end
                end
            end            
            
            plantedCrop.state = newState;
        end
        
        function [outputProducts, eventOutputs] = transitionFunction_Harvesting(gmDel, plantedCrop, sim) %#ok<MANU>
            
                            
            numeratorUnit = Unit('', 'Yield', 'Tonne');
            denominatorUnit = Unit('', 'Area', 'Hectare');
            eoNumeratorUnit1 = Unit('', 'Competition Income Loss', 'Dollar');
            eoDenominatorUnit1 = Unit('', 'Paddock', 'Unit');
            eoNumeratorUnit2 = Unit('', 'NCZ Area', 'Dollar');
            

            % Return list of products and outputs if called with no
            % arguments.
            % In the case of planting, not products or outputs are
            % produced.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, numeratorUnit, denominatorUnit);
                eventOutputs = Rate(0, eoNumeratorUnit1, eoDenominatorUnit1);
                eventOutputs(2) = Rate(0, eoNumeratorUnit2, eoDenominatorUnit1);
                return; 
            end
            
            % Harvest outputs are Competition Income Loss
            % And NCZ Area - both per paddock
            outputProducts = Rate(plantedCrop.state.yield, numeratorUnit, denominatorUnit);

            
            
            % Want an event output which is the income lost to competition.
            competitionCost = 0;
            NCZArea = 0;
            NCZOpportunityCost = 0;
            if(~isempty(gmDel.propagationParameters.spatialModifiers))
                sis = gmDel.propagationParameters.spatialModifiers;
                if (sis.useCompetition)
                    grainIncome = sim.productPriceTable.(underscore(plantedCrop.cropName))(1, sim.year);
                    assignin('base', 'grainIncome', grainIncome);
                    paddockUnit = Unit('', 'Paddock', 'Unit');
                    tonnesUnit = Unit('', 'Yield', 'Tonne');
                    competitionCost = Rate(plantedCrop.state.yieldLostToCompetitionPerPaddock, tonnesUnit, paddockUnit) * grainIncome;                    
                end
                
                if (sis.useNCZ)
                    cropInterfaceUnit = Unit('', 'Crop Interface Length', 'm');
                    cropInterface = Amount(0, cropInterfaceUnit); 
                    if ~isempty(sim.currentSecondaryInstalledRegime)
                         if ~isempty(sim.currentSecondaryPlantedCrop)
                            cropInterface = sim.currentSecondaryInstalledRegime.getAmount(cropInterfaceUnit);
                         end
                    end
                    if ~isempty(cropInterface)
                        NCZArea = cropInterface.number * plantedCrop.state.NCZWidth;
                    end
                    
                    % Way too hard to work out net profit for primary area at 
                    % this stage. List of costs tricky (discount rate?) and
                    % income tricky (how do we undo competition here?).
                    % Net profit for uncompeted primary crop can be
                    % calculated from cost per Ha (discounted if preferred)
                    % and income per paddock and income lost to
                    % competition.
                end
                
            end

            if (competitionCost == 0)        
                eventOutputs = Rate(0, eoNumeratorUnit1, eoDenominatorUnit1);
                
            else
                eventOutputs = Rate(competitionCost.number, eoNumeratorUnit1, eoDenominatorUnit1);                                
                assignin('base', 'compCost', eventOutputs);                   
            end
            
            
            eventOutputs(2) = Rate(NCZArea, eoNumeratorUnit2, eoDenominatorUnit1);
            
            % This is a destruction event, so we don't need to change the
            % state.            
        end
        
        
        function cropNameHasChanged(gmd, previousName, newName)
            % Need to update any temporal interaction names.
            % Could also go through the list of triggers.
            % temporalModifiers are a cell array with rows of the form
            % {['CropName'], [modifierPercentage]}
            if ~isempty(gmd.propagationParameters)
                if ~isempty(gmd.propagationParameters.temporalModifiers)
                    for i = 1:length(gmd.propagationParameters.temporalModifiers)
                        if strcmp(gmd.propagationParameters.temporalModifiers{i, 1}, previousName)
                            gmd.propagationParameters.temporalModifiers{i, 1} = newName;
                        end
                    end
                end
            end
        end  
        
    end
    
    % Validation Methods
    methods
        
        % Checks that the class is right and things aren't empty
        function valid = gmdIsValid(gmd)
            valid = isa(gmd, 'RainfallBasedGrowthModelDelegate');
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
        

    end
    
    methods (Access = private)
        
       % Private method to calculate NCZ Optimised Width.
       function NCZWidth = calculateNCZOptimisedWidth(gmDel, sis, plantedCrop, sim)
           
           optimisedParams = sis.NCZOptimisedParameters;
           
           if isempty(sim.currentSecondaryInstalledRegime)
               NCZWidth = 0;
               return
           end
           
           if (~isempty(optimisedParams))
                if (optimisedParams.isValid)
                    % Then use the NCZ parameters to
                    % calculate the width of the NCZ.
                    
                    % Get the relevant pre-seeding rainfall from the sim.
                    
                    % when is a month's rainfall defined? After planting,
                    % ready for propagation. So when planting, can only use
                    % previous month's rainfall. If we're less than the
                    % required months old, use known rain means instead.
                    % Usually, the competition will not exist at that point
                    % anyway because the AGBM will be tiny.
                    if ((sim.monthIndex - 1) < optimisedParams.preSeedingRainfallMonths)
                        climateMgr = climateManager.getInstance;
                        averageRainfall = climateMgr.getMonthlyAverageRainfall;
                        if sim.month - 1 > optimisedParams.preSeedingRainfallMonths
                           avPSR = averageRainfall(sim.month - 1 - optimisedParams.preSeedingRainfallMonths: sim.month - 1); 
                        else
                            avRainX2 = [averageRainfall, averageRainfall];
                            avPSR = sum(avRainX2(12 + sim.month - 1 - optimisedParams.preSeedingRainfallMonths: 12 + sim.month - 1));
                        end
                        PSR = avPSR;
                    else                       
                        PSR = sum(sim.monthlyRainfall(sim.monthIndex - optimisedParams.preSeedingRainfallMonths: sim.monthIndex - 1));
                    end
                    p = [optimisedParams.polyA, optimisedParams.polyB, optimisedParams.polyC];
                    PSREstYield = polyval(p, PSR);
                    
                    estYield = PSREstYield * optimisedParams.polynomialPredictiveCapacity + ...
                                    optimisedParams.longTermAverageYield * (1 - optimisedParams.polynomialPredictiveCapacity);
                             
                    
                    % We assume that the yield is the only product and
                    % therefore it's the first product... hence the 1 in
                    % the following line.
                    yieldPrice = sim.productPriceTable.(underscore(plantedCrop.cropObject.name))(1, sim.year);
                    
                    % This is the price per Ha.
                    income = yieldPrice.number * estYield;
                    
                    plantCost = sim.costPriceTable.(underscore(plantedCrop.cropObject.name)).('Planting')(sim.year);
                    harvestCost = sim.costPriceTable.(underscore(plantedCrop.cropObject.name)).('Harvesting')(sim.year);
                    
                    cost = plantCost + harvestCost;
                                        
                    ratio = cost.number / income;
                    
                    % Now we have the ratio, at what width do we reach that
                    % ratio?
                    
                    % Need to calculate yield and reach factor.
                    % Get the AGBM and BGBM rates from the belt crop.
                    if ~isempty(sim.currentSecondaryPlantedCrop)
                        u = Unit('', 'Above-ground Biomass', 'Tonne');
                        AGBMr = sim.currentSecondaryPlantedCrop.getAmount(u);
                        BGBMr = sim.currentSecondaryPlantedCrop.getAmount(Unit('', 'Below-ground Biomass', 'Tonne'));
                        if isempty(AGBMr)
                            AGBMr = Amount(0, Unit('', 'Above-ground Biomass', 'Tonne'));
                            BGBMr = Amount(0, Unit('', 'Below-ground Biomass', 'Tonne'));
                        end
                    else
                            AGBMr = Amount(0, Unit('', 'Above-ground Biomass', 'Tonne'));
                            BGBMr = Amount(0, Unit('', 'Below-ground Biomass', 'Tonne'));
                    end
                    % We want to convert these to kg / m.
                    %
                    % TODO: write a conversion function. For now we know
                    % that we've got it in Tonnes and we happen to know
                    % that it's given per tree. This should not be taken
                    % for granted though.
                    %
                    % Need to divide by plant spacing.
                    plantSpacing = sim.currentSecondaryInstalledRegime.getRegimeParameter('plantSpacing');
                    if isempty(plantSpacing)
                        error('Need to be able to access the regime''s plantSpacing parameter.');
                    end
                    
                    % Do we need to calculate proportion of impact of waterlogging as well
                    % as competition? Yes.
                    % So we need the average GSR. We can get GSR by asking
                    % for the 'relevant rain' months from the gmDel. (This
                    % object). Then we can ask the climate mgr for the
                    % average rainfall in each of those months, and add it
                    % up. That will then get us the impact value for both
                    % comp and waterlogging.
                    
                    climateMgr = ClimateManager.getInstance;
                    averageRainfall = climateMgr.getMonthlyAverageRainfall;
                    
                    firstRM = gmDel.propagationParameters.firstRelevantMonth;
                    lastRM = gmDel.propagationParameters.lastRelevantMonth;
                    
                    avGSR = sum(averageRainfall(firstRM:lastRM));
                    
                    % Figure out the average pre-seeding rainfall.
                    if sim.month - 1 > optimisedParams.preSeedingRainfallMonths
                       avPSR = sum(averageRainfall(sim.month - 1 - optimisedParams.preSeedingRainfallMonths: sim.month - 1)); 
                    else
                        avRainX2 = [averageRainfall, averageRainfall];
                        avPSR = sum(avRainX2(12 + sim.month - 1 - optimisedParams.preSeedingRainfallMonths: 12 + sim.month - 1));
                    end

                    % estimate gsr by scaling average gsr based on current
                    % psr and average psr.
                    estGSR = avGSR * PSR / avPSR;                    
                    
                    [compImpact, ~] = getImpact(sis, estGSR);
                    
                    [compExtent, compYieldLoss, ~, ~] = getRawSIBounds(sis, AGBMr.number * 1000, BGBMr.number * 1000, plantSpacing);
                    
                    breakEvenCroppingDist = calculateBreakEvenCroppingDistance(sis, compExtent, compYieldLoss, compImpact, ratio);
                        
                    csir = sim.currentSecondaryInstalledRegime;
                    if ~isempty(csir)
                       
                        regObj = csir.regimeObject;  
                        exclusionZoneWidth = regObj.getExclusionZoneWidth;

                        % IF the exclusion zone is greater than the breakeven
                        % dist, the NCZ is 0. Otherwise calculate the NCZ and
                        % round to nearest 0.5m.
                        if breakEvenCroppingDist > exclusionZoneWidth
                            NCZWidth = floor((breakEvenCroppingDist - exclusionZoneWidth) * 2) / 2;
                        else
                            NCZWidth = 0;
                        end        
                    else
                        NCZWidth = 0;
                    end
                else
                   NCZWidth = 0; 
                end
            else
                NCZWidth = 0;                                   
            end
       end
        
    end
    
end


% This function makes the triggers for the RainfallBased events.
% The cost price models are provided with a default denominatorUnit.
% Note that the denominatorUnit must match the growthModelOutput units 
% or the regimeOutputUnits for the cropCategory this growthModel is made
% for.
function [initialEvents, regularEvents, destructionEvents] =  makeRainfallBasedImagineEvents()

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

% This function makes the productPriceModels. 
% It defines what the products are. The denominator units used define the 
% units of the product. These are not changed later. Therefore care must be
% taken to ensure that the denominator units here match the numerator units
% in the rate returned by a transition function.
function pPMs = makeRainfallBasedProductPriceModels


    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    denominatorUnit = Unit('', 'Yield', 'Tonne');
    pPMs = PriceModel('Yield Income', unit, denominatorUnit);


end

