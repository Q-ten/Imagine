% This is a template for a concrete AnnualGrowthModelDelegate based on the
% Abstract class.
%
% To calculate base yield, the user can select either a French-Schultz type
% model where yield is based on rainfall via a quadratic curve or simply
% imported data that defines a trend.
%
% It also provides a temporal modifier mechanism to give yield boosts or
% declines based on the crop that was planted in the previous year.
%
% It also gives a spatial yield modifier so that belts of trees may affect
% the yield. Crops close to the belts suffer yield decline due to water
% competition with the belt crop.
%
% For the rainfall derived base yield, the yield is meant to be based on 
% rain that falls during the growing
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
classdef AnnualGrowthModelDelegate < GrowthModelDelegate
    
    % Properties from parent include 
    % state
    % gm - handle to the owning GrowthModel
    % stateSize
    % supportedImagineEvents

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % These are the concrete implementations of the Abstract properties
    properties
        modelName = 'Annual'; 
        
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
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % These are the Rainfall Based model specific properties.
    properties (Access = public)
        
        propagationParameters
        
        
        % eg propagtionParameters
        % eg event1TransitionFunctionParameters.
        % eg event2TransitionFunctionParameters.        
    end
    
    properties (Access = private)
        fixedYieldData = struct('state', [], 'spatialModifier', 1, 'temporalModifier', 1);
        privateProductPriceModels = PriceModel.empty(1, 0);
    end
    
    methods (Static)
       
        function obj = loadobj(obj)

            if isstruct(obj)
                newObj = AnnualGrowthModelDelegate();
                fns = fieldnames(obj);
                for i = 1:length(fns)
                    try                        
                        if strcmp(fns{i}, 'productPriceModels')
                            newObj.privateProductPriceModels = obj.productPriceModels;
                        else
                           newObj.(fns{i}) = obj.(fns{i}); 
                        end
                    catch e
                    end
                end
                obj = newObj;
            end
            gm = AnnualsGMDialog('setupParameters', obj.propagationParameters);
            obj.propagationParameters = gm.propagationParameters;                
        end
        
        function agmdel = convertFromRainfallBasedGMDelegate(rbgmdel)
            agmdel = AnnualGrowthModelDelegate;
            
            % Just need to pull out the propagation parameters and put them in the right spot.
            agmdel.propagationParameters.temporalModifiers = rbgmdel.propagationParameters.temporalModifiers;
            agmdel.propagationParameters.spatialModifiers = rbgmdel.propagationParameters.spatialModifiers;
            
            params.A = -rbgmdel.propagationParameters.p(1);
            params.B = rbgmdel.propagationParameters.p(2);
            params.C = rbgmdel.propagationParameters.p(3);
            params.firstRelevantMonth = rbgmdel.propagationParameters.firstRelevantMonth;
            params.lasstRelevantMonth = rbgmdel.propagationParameters.lastRelevantMonth;

            agmdel.propagationParameters.rainfallBasedAnnualGM = RainfallBasedAnnualGM(params);
            agmdel.propagationParameters.modelChoice = 'RainfallBasedAnnualGM';
            agmdel.propagationParameters.HIData = HarvestIndexData;
            agmdel.propagationParameters.HIData.units = 'Yield';
            agmdel.propagationParameters.HIData.HI = 1;
            
        end
    end
    
    methods
    
        % These methods are required from the Abstract parent class
        % GrowthModelDelegate.
        
        % This is the constructor for the concrete subclass. It should set
        % up all the parent's Abstract properties here, then go on to setup
        % any parameters specific to the concrete subclass.
        function gmDel = AnnualGrowthModelDelegate(gm)
            if nargin > 0
                super_args = {gm};
            else
                super_args = {};
            end
            
            gmDel = gmDel@GrowthModelDelegate(super_args{:});
            
            % Now set up the specific default parameters for this growth model.
            
            % The priceModels, events and outputUnits need to be set up
            % here.
            [init, reg, dest] = makeAnnualGMImagineEvents;
            gmDel.growthModelInitialEvents = init;
            gmDel.growthModelRegularEvents = reg;
            gmDel.growthModelDestructionEvents = dest;
            
            gmDel.privateProductPriceModels = makeAnnualGMProductPriceModels;
            
            % Make the rainfall based output units by calling the calculate
            % outputs function with an empty state and a third argument.
            gmDel.calculateOutputs([], 'rate');
            
            % Could set up the parameters here, but you could leave it
            % up to the GUI. It's probably better if they are defined in
            % one place.
            
        end
        
        function ppms = get.productPriceModels(gmd)
           ppms = gmd.privateProductPriceModels;
           
           % Return the basic product price models, plus any that come from the fixed yield growth model.
           if isfield(gmd.propagationParameters, 'fixedYieldGMDelegate')
               if ~isempty(gmd.propagationParameters.fixedYieldGMDelegate.productPriceModels)
                   ppms = [ppms, gmd.propagationParameters.fixedYieldGMDelegate.productPriceModels];
               end
           end
        end
        
        function set.productPriceModels(gmd, ppms)
           % When we're setting the product price models, we want to set
           % the data, but not the titles. So we'd never really want to set
           % them from scratch.           
           if isempty(ppms)
               return
           end
           
           % We're going to try and update the local price model by finding
           % a match in the inputted price models, and then do the same for
           % all the other price models in the fixed yield gm. That way, if
           % they happen to define the same product, and later we load them
           % oddly, the price model will be defined in both places.
           
           % First uniqueify the input pricemodels. Error if not unique.
           inputPPMNames = {ppms.name};
           [uniquePPMNames, m, n] = unique(inputPPMNames);
           if length(uniquePPMNames) ~= length(ppms)
               error('Passed in non-unique list of product price models to set.');
           end      
                      
           % Try and replace the local private price model.
           ix = find(strcmp(inputPPMNames, gmd.privateProductPriceModels.name), 1, 'first');
           if ~isempty(ix)
              gmd.privateProductPriceModels = ppms(ix);
           end
           
           % Now go through and replace the fixed yield product price
           % models.
           fixedYieldPriceModels = gmd.propagationParameters.fixedYieldGMDelegate.productPriceModels;
           for i = 1:length(fixedYieldPriceModels)
               ix = find(strcmp(inputPPMNames, fixedYieldPriceModels(i).name), 1, 'first');
               if ~isempty(ix)
                  fixedYieldPriceModels(i) = ppms(ix);
               end
           end
           
           % Replace the product price models in the fixed yield gm delegate.
           gmd.propagationParameters.fixedYieldGMDelegate.productPriceModels = fixedYieldPriceModels;           
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
                if isfield(gmd.propagationParameters, 'fixedYieldGMDelegate')
                    [~, productRates] = gmd.propagationParameters.fixedYieldGMDelegate.propagateState([], []);
                end
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
%            year = sim.year;
%             relevantRainToDate = sim.monthlyRainfall((1:12 >= propParams.firstRelevantMonth & ...
%                                               1:12 <= propParams.lastRelevantMonth & ...
%                                               1:12 >= mod(plantedCrop.plantedMonth, 12) & ... 
%                                               1:12 <= sim.month), year);
%             baseYield = max(0, polyval(propParams.p, sum(relevantRainToDate)));
%             

            % Uss the sub-GMs to calcualte base yield.
            if strcmp(propParams.modelChoice, 'ManualAnnualGM')
                baseYield = propParams.manualAnnualGM.calculateYearlyYield(sim);
            elseif strcmp(propParams.modelChoice, 'RainfallBasedAnnualGM')
                baseYield = propParams.rainfallBasedAnnualGM.calculateYearlyYield(sim, plantedCrop.plantedMonth);               
            else
                error('modelChoice not set to recognized model.');                
            end
            
            % Apply the harvest index to the base yield if appropriate.
            if (strcmp(propParams.HIData.units, 'Biomass'))
               baseYield = baseYield * propParams.HIData.HI; 
            end
            
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
            
            spatialInteractionDetail.compExtent = 0;
            spatialInteractionDetail.compYieldLoss = 0;
            spatialInteractionDetail.waterExtent = 0;
            spatialInteractionDetail.waterYieldGain = 0;
            spatialInteractionDetail.baseYield = baseYield;
            spatialInteractionDetail.temporalModifier = temporalModifier;
            

            newState.spatialInteractionDetail = [];
            exclusionZoneWidth = 0;
            NCZWidth = 0;
            
            yieldLossFromCompetition = 0;
            yieldGainFromWaterlogging = 0;
            compYieldLoss = 0;
            waterYieldGain = 0;
            waterExtent = 0;
            compExtent = 0;
            waterImpact = 0;
            compImpact = 0;
                        
            if ~isempty(gmd.propagationParameters.spatialModifiers)% && ~isempty(sim.currentSecondaryInstalledRegime)
                
                sis = gmd.propagationParameters.spatialModifiers;
                if isempty(plantedCrop.state.NCZWidth)
                    NCZWidth = 0;
                else
                    NCZWidth = plantedCrop.state.NCZWidth;
                end
                
              %  if sis.isValid

                    % If we're using the rainfallBased model the use the
                    % relevant months.
                    % Otherwise make them up. We assume May to October.
                    if strcmp(gmd.propagationParameters.modelChoice, {'RainfallBasedAnnualGM', 'ManualAnnualGM'})
                        firstRM = gmd.propagationParameters.rainfallBasedAnnualGM.firstRelevantMonth;
                        lastRM = gmd.propagationParameters.rainfallBasedAnnualGM.lastRelevantMonth;
                    else
                        firstRM = 5;
                        lastRM = 10;
                    end
                    
                    % First calculate the impact. Need the expected GSR for
                    % that. Need to get the GSR to date. Then compare with
                    % expected GSR to date. Then scale by expected GSR.
                    if sim.month < lastRM 
                        % then estimate gsr
                        firstRelevantMonthIndex = (sim.year - 1) * 12 + firstRM;
                       GSR2Date = sum(sim.monthlyRainfall(firstRelevantMonthIndex:sim.monthIndex));
                       climateMgr = ClimateManager.getInstance;
                       averageRainfall = climateMgr.getMonthlyAverageRainfall;
                       avGSR2Date = sum(averageRainfall(firstRM:sim.month));
                       avGSR = sum(averageRainfall(firstRM:lastRM));
                       % expected gsr
                       if (avGSR2Date == 0)
                           gsr = avGSR;
                       else
                           gsr = avGSR * GSR2Date / avGSR2Date;
                       end
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
                    if ~isempty(sim.currentSecondaryInstalledRegime)
                        plantSpacing = sim.currentSecondaryInstalledRegime.getRegimeParameter('plantSpacing');
                        if isempty(plantSpacing)
                            error('Need to be able to access the regime''s plantSpacing parameter.');
                        end
                    else
                        plantSpacing = 1;
                    end
                    
                    % Get the crop interface from the secondary regime. If the
                    % regime doesn't implement the crop interface output then we'll
                    % assume that it's zero.
                    cropInterface = Amount(0, cropInterfaceUnit); 
                    if ~isempty(sim.currentSecondaryInstalledRegime)
                         if ~isempty(sim.currentSecondaryPlantedCrop)
                            cropInterface = sim.currentSecondaryInstalledRegime.getAmount(cropInterfaceUnit);
                         end
                    else
                        cropInterface = Amount.empty(1, 0);
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
                    
                    spatialInteractionDetail.compExtent = compExtent;
                    spatialInteractionDetail.compYieldLoss = compYieldLoss;  %Raw yield loss - not scaled.
                    spatialInteractionDetail.waterExtent = waterExtent;
                    spatialInteractionDetail.waterYieldGain = waterYieldGain;
                    
                    % Scale percentage numbers to [0, 1]
                    compYieldLoss = compYieldLoss / 100;
                    waterYieldGain = waterYieldGain / 100;

                    csir = sim.currentSecondaryInstalledRegime;                                        
                    exclusionZoneWidth = 0;
                    if ~isempty(csir)
                        regObj = csir.regimeObject;  
                        exclusionZoneWidth = regObj.getExclusionZoneWidth;
                    end
                    
                    spatialInteractionDetail.exclusionZoneWidth = exclusionZoneWidth;
                    spatialInteractionDetail.NCZWidth = NCZWidth;

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
                        if (compYieldLoss * compImpact) > 1
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
                        if (baseYield == 0)
                            spatialModifier = 1;
                        else
                            spatialModifier = totalYieldPerHa / baseYield / temporalModifier;
                        end
                        if sim.month == 12
                           a = 1; 
                  %         relevantRainToDate = relevantRainToDate;
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
            
            spatialInteractionDetail.NCZWidth = NCZWidth;
            spatialInteractionDetail.exclusionZoneWidth = exclusionZoneWidth;
            spatialInteractionDetail.baseYield = baseYield;
            spatialInteractionDetail.temporalModifier = temporalModifier;
            
            newState.spatialInteractionDetail = spatialInteractionDetail;
            
            % Now finish off with the fixedYield propagation and products.
            % now we have the spatial and temporal modifiers we can apply
            % them.
            if ~isempty(gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters)
                [fixedYieldState, fixedYieldProducts] = gmd.propagationParameters.fixedYieldGMDelegate.propagateState(plantedCrop, sim);
                newState.fixedYieldData.state = fixedYieldState;
                newState.fixedYieldData.spatialModifier = spatialModifier;
                newState.fixedYieldData.temporalModifier = temporalModifier; 
                
                % Get the fixed yield products if there are any.
                if ~isempty(gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.products)       
                   
                    productNames = fieldnames(gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.products);
                    for i = 1:length(fixedYieldProducts)
                      % speciesName = fixedYieldProducts(i).unit.speciesName;
                       spatialModifierHere = 1;
                       temporalModifierHere = 1;
                       if (gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.products.(productNames{i}).spatiallyModified)
                           spatialModifierHere = spatialModifier;
                       end
                       if (gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.products.(productNames{i}).temporallyModified)
                           temporalModifierHere = temporalModifier;
                       end
                       fixedYieldProducts(i).number = fixedYieldProducts(i).number * spatialModifierHere * temporalModifierHere;
                    end
                    productRates = fixedYieldProducts;
                end                                
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
            output = AnnualsGMDialog(cropInfo, gmDel.propagationParameters, cropNames, {cats.name});
            if ~isempty(output)               
                gmDel.propagationParameters = output.propagationParameters;
                gmDel.growthModelFinancialEvents = gmDel.propagationParameters.fixedYieldGMDelegate.growthModelFinancialEvents;
            end
        end
        
        % This function renders a display of the growthModelDelegate's
        % parameters as a kind of summary. This is used in the crop wizard
        % and displays a summary of the saved growth model to be viewed
        % before and after the user enters the main GUI (launched via
        % setupGrowthModel above). This function should plot the summary on
        % ax, an axes object.
        function renderGrowthModel(gmDel, ax)
            modelChoice = 'Unknown';
            if strcmp(gmDel.propagationParameters.modelChoice, 'RainfallBasedAnnualGM')
                modelChoice = 'French-Schultz Model';
            elseif strcmp(gmDel.propagationParameters.modelChoice, 'ManualAnnualGM')
                modelChoice = 'Manual Trend Model';
            end
            picture = './Resources/field-rain.jpg';
            title = 'Annual Growth Model';
            expo = {'The Rainfall-based Growth Model models simple base yield output based', ... 
                    'on a quadratic function of GSR (Growing Season Rainfall).', ...
                    'The base yield is adjusted by temporal and spatial modifiers as appropriate,'...
                    'with the temporal modifier taking into account previous crops or crop ', ...
                    'categories, and the spatial modifier taking into account relevant', ...
                    'competition and benefit effects of any trees that may be planted.', ...
                    '', ...
                    '', ...
                    'Current base yield model choice is: ', ...
                    '', ...
                    modelChoice};

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

        function outputsColumn = calculateOutputs(gmd, state, unitOrRate) 
            
             numeratorUnits = Unit.empty(1, 0);
             denominatorUnits = Unit.empty(1, 0);
             outputRates = Rate.empty(1, 0);
                          
%             persistent numeratorUnits
%             persistent denominatorUnits
%             persistent outputRates
%             
%             if isempty(numeratorUnits)
%                 numeratorUnits = Unit.empty(1, 0);
%             end
% 
%             if isempty(denominatorUnits)
%                 denominatorUnits = Unit.empty(1, 0);
%             end
%                
%             if isempty(outputRates)
%                 outputRates = Rate.empty(1, 0);
%             end
            
            if ~isempty(gmd.propagationParameters)
                if ~isempty(gmd.propagationParameters.spatialModifiers)

                    if (gmd.propagationParameters.spatialModifiers.useCompetition || gmd.propagationParameters.spatialModifiers.useWaterlogging)
                        % Note that I'm not sure about these units
                        % - it hasn't really worked out with the
                        % three fields. Needs some further thought.
                        % This would naturally seem like a good
                        % place to use the third field, but it
                        % didn't work smoothly in other spots in
                        % the code so I dropped it.
                        % Worth going back to in future.
                        numeratorUnits(1) = Unit('', 'Root Mass Extent', 'm');
                        numeratorUnits(2) = Unit('', 'Competition Scale Factor', 'Percent');    % Impact
                        numeratorUnits(3) = Unit('', 'Competition at Tree (Raw) (DL)', 'Percent');
                        numeratorUnits(4) = Unit('', 'Competition at Tree (Scaled) (SL)', 'Percent');
%                        numeratorUnits(4) = Unit('', 'Competition Extent', 'm');
                        numeratorUnits(5) = Unit('', 'WLM Scale Factor', 'Percent');
                        numeratorUnits(6) = Unit('', 'WLM at Tree (Raw) (DL)', 'Percent');
                        numeratorUnits(7) = Unit('', 'WLM at Tree (Scaled) (SL)', 'Percent');
%                        numeratorUnits(8) = Unit('', 'WLM Extent', 'm');
                        numeratorUnits(8) = Unit('', 'NCZ Width', 'm');
                        numeratorUnits(9) = Unit('', 'Exclusion Zone Width', 'm');
                        numeratorUnits(10) = Unit('', 'Base Yield', 'Tonne');    % Area Hectare
                        numeratorUnits(11) = Unit('', 'Temporally Modified Yield', 'Tonne');

                        denominatorUnits(1) = Unit('', '', 'Unit');
                        denominatorUnits(2) = Unit('', '', 'Unit');
                        denominatorUnits(3) = Unit('', '', 'Unit');
                        denominatorUnits(4) = Unit('', '', 'Unit');
                        denominatorUnits(5) = Unit('', '', 'Unit');
                        denominatorUnits(6) = Unit('', '', 'Unit');
                        denominatorUnits(7) = Unit('', '', 'Unit');
                        denominatorUnits(8) = Unit('', '', 'Unit');                                
                        denominatorUnits(9) = Unit('', '', 'Unit');
                        denominatorUnits(10) = Unit('', 'Area', 'Hectare');
                        denominatorUnits(11) = Unit('', 'Area', 'Hectare');
                        
                        for i = 1:length(numeratorUnits)
                           outputRates(i) = Rate(0, numeratorUnits(i), denominatorUnits(i)); 
                        end
                    end
                end
                if isfield(gmd.propagationParameters, 'fixedYieldGMDelegate')
                    fixedYieldOutputRates = gmd.propagationParameters.fixedYieldGMDelegate.calculateOutputs([], 'rate');
                    numeratorUnits = [numeratorUnits, [fixedYieldOutputRates.unit]];
                    denominatorUnits = [denominatorUnits, [fixedYieldOutputRates.denominatorUnit]];
                    outputRates = [outputRates, fixedYieldOutputRates];
                end
            end                    
            
            if isempty(state)
                if nargin == 3
                    if length(denominatorUnits) ~= length(numeratorUnits)
                        error('AnnualGrowthModel needs the same number of numerator units as denominator units.');
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
        
            % Put the values in the rates...

            % The calculateOutputs function should return a column of
            % nothing outputs if the state is empty. 
            
            % calculateOutputs must be able to provide a column of nothing
            % outputs if the state that is passed is empty.
                         
           outputsColumn = Rate.empty(1, 0);    % Set up an empty outputs column by default. If we're using spatial modifiers then give the other parameters.
            
           if ~isempty(gmd.propagationParameters)
                if ~isempty(gmd.propagationParameters.spatialModifiers)
                    if (gmd.propagationParameters.spatialModifiers.useCompetition || gmd.propagationParameters.spatialModifiers.useWaterlogging)
                        
                        if isempty(numeratorUnits)
                            calculateOutputs(gmd, [], 'rate') 
                        end
                        
                        if isempty(state)
                            state.compImpact = 0;
                            state.spatialInteractionDetail.compYieldLoss = 0;
                            state.spatialInteractionDetail.compExtent = 0;
                            state.waterImpact = 0;
                            state.spatialInteractionDetail.waterYieldGain = 0;
                            state.spatialInteractionDetail.waterExtent = 0;
                            state.spatialInteractionDetail.NCZWidth = 0;
                            state.spatialInteractionDetail.exclusionZoneWidth = 0;
                            state.spatialInteractionDetail.baseYield = 0;
                            state.spatialInteractionDetail.temporalModifier = 0;
                            state.spatialInteractionDetail.preSpatialYield = 0;
                            state.spatialInteractionDetail.potentialWaterloggingMitigationIntensity = 0;
                            state.spatialInteractionDetail.potentialCompetitionIntensity = 0;
                            state.spatialInteractionDetail.scaledWaterloggingMitigationIntensity = 0;
                            state.spatialInteractionDetail.scaledCompetitionIntensity = 0;
                            
                        end                       
                        
                        outputsColumn(1, 1) = Rate(state.spatialInteractionDetail.compExtent, numeratorUnits(1), denominatorUnits(1));
                        outputsColumn(2, 1) = Rate(state.compImpact, numeratorUnits(2), denominatorUnits(2));
                        outputsColumn(3, 1) = Rate(state.spatialInteractionDetail.compYieldLoss, numeratorUnits(3), denominatorUnits(3));
                        outputsColumn(4, 1) = Rate(state.spatialInteractionDetail.compYieldLoss * state.compImpact, numeratorUnits(4), denominatorUnits(4));
%                        outputsColumn(4, 1) = Rate(state.spatialInteractionDetail.compExtent, numeratorUnits(4), denominatorUnits(4));
                        outputsColumn(5, 1) = Rate(state.waterImpact, numeratorUnits(5), denominatorUnits(5));
                        outputsColumn(6, 1) = Rate(state.spatialInteractionDetail.waterYieldGain, numeratorUnits(6), denominatorUnits(6));
                        outputsColumn(7, 1) = Rate(state.spatialInteractionDetail.waterYieldGain * state.waterImpact, numeratorUnits(7), denominatorUnits(7));
%                        outputsColumn(8, 1) = Rate(state.spatialInteractionDetail.waterExtent, numeratorUnits(8), denominatorUnits(8));
                        outputsColumn(8, 1) = Rate(state.spatialInteractionDetail.NCZWidth, numeratorUnits(8), denominatorUnits(8));
                        outputsColumn(9, 1) = Rate(state.spatialInteractionDetail.exclusionZoneWidth, numeratorUnits(9), denominatorUnits(9));
                        outputsColumn(10, 1) = Rate(state.spatialInteractionDetail.baseYield, numeratorUnits(10), denominatorUnits(10));
                        outputsColumn(11, 1) = Rate(state.spatialInteractionDetail.baseYield * state.spatialInteractionDetail.temporalModifier, numeratorUnits(11), denominatorUnits(11));
                       
                        for i = 1:size(outputsColumn, 1)
                           if isnan(outputsColumn(i, 1).number) 
                               outputsColumn(i, 1).number = 0;
                           end
                        end
                        
                    end
                end
                
                if isfield(gmd.propagationParameters, 'fixedYieldGMDelegate')
                   if ~isempty(gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters)

                        % We need the propagate state function to populate the
                        % fixedYieldData property. It needs state,
                        % spatialModifier and temporalModifier.

                        if ~isfield(state, 'fixedYieldData')
                            fixedYieldOutputs = gmd.propagationParameters.fixedYieldGMDelegate.calculateOutputs([], 'rate');
                            spatialModifier = 1;
                            temporalModifier = 1;
                        else
                            fixedYieldOutputs = gmd.propagationParameters.fixedYieldGMDelegate.calculateOutputs(state.fixedYieldData.state);
                            % If the output should be spatially or temporally
                            % modified, apply those modifiers if they exist.

                           % Get the actual spatial and temporal modifiers at this
                           % point.
                           spatialModifier = gmd.fixedYieldData.spatialModifier;
                           temporalModifier = gmd.fixedYieldData.temporalModifier;
                        end
                        
                       % How do we match the outputs to the outputRates?
                       % I think we can assume that they're in order.

                       outputNames = fieldnames(gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.outputs);
                        for i = 1:length(fixedYieldOutputs)
                      %     speciesName = fixedYieldOutputs(i).unit.speciesName;
                           spatialModifierHere = 1;
                           temporalModifierHere = 1;
                           if (gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.outputs.(outputNames{i}).spatiallyModified)
                               spatialModifierHere = spatialModifier;
                           end
                           if (gmd.propagationParameters.fixedYieldGMDelegate.propagationParameters.outputs.(outputNames{i}).temporallyModified)
                               temporalModifierHere = temporalModifier;
                           end
                           fixedYieldOutputs(i).number = fixedYieldOutputs(i).number * spatialModifierHere * temporalModifierHere;
                        end
                        outputsColumn = [outputsColumn; fixedYieldOutputs];
                   end
                end

           end
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
            
            % This line creates the data that will be used for the yield in
            % the manualAnnual submodel.
            if strcmp(gmDel.propagationParameters.modelChoice, 'ManualAnnualGM')
                gmDel.propagationParameters.manualAnnualGM.sampleDistribution;
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
            
            newState.spatialInteractionDetail = [];
            
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
                    
                    spatialInteractionDetail.compExtent = 0;
                    spatialInteractionDetail.compYieldLoss = 0;
                    spatialInteractionDetail.waterExtent = 0;
                    spatialInteractionDetail.waterYieldGain = 0;
                    spatialInteractionDetail.exclusionZoneWidth = 0;
                    spatialInteractionDetail.NCZWidth = 0;
                    spatialInteractionDetail.baseYield = 0;
                    spatialInteractionDetail.temporalModifier = 0;
                    spatialInteractionDetail.potentialWaterloggingMitigationIntensity = 0;
                    spatialInteractionDetail.potentialCompetitionIntensity = 0;
                    

                    newState.spatialInteractionDetail = spatialInteractionDetail;

                end
            end            
            
            if isfield(gmDel.propagationParameters, 'fixedYieldGMDelegate')
                 if isfield(gmDel.propagationParameters.fixedYieldGMDelegate, 'propagationParameters')
                    [fixedYieldState, ~] = gmDel.propagationParameters.fixedYieldGMDelegate.propagateState(plantedCrop, sim);
                    newState.fixedYieldData.state = fixedYieldState;
                    newState.fixedYieldData.spatialModifier = spatialModifier;
                    newState.fixedYieldData.temporalModifier = temporalModifier; 
                 end
            end
            
            plantedCrop.state = newState;
        end
        
        function [outputProducts, eventOutputs] = transitionFunction_Harvesting(gmDel, plantedCrop, sim) 
            
                            
            numeratorUnit = Unit('', 'Yield', 'Tonne');
            denominatorUnit = Unit('', 'Area', 'Hectare');
            eoNumeratorUnit1 = Unit('', 'Competition Income Loss', 'Dollar');
%            eoDenominatorUnit1 = Unit('', 'Paddock', 'Unit');
            eoDenominatorUnit1 = Unit();
            eoNumeratorUnit2 = Unit('', 'NCZ Area', 'Hectare');
            eoNumeratorUnit3 = Unit('', 'Belt Opportunity Cost', 'Dollar');
            

            % Return list of products and outputs if called with no
            % arguments.
            % In the case of planting, not products or outputs are
            % produced.
            if(isempty(plantedCrop) && isempty(sim))
                outputProducts = Rate(0, numeratorUnit, denominatorUnit);
                eventOutputs = Rate(0, eoNumeratorUnit1, eoDenominatorUnit1);
                eventOutputs(2) = Rate(0, eoNumeratorUnit2, eoDenominatorUnit1);
                eventOutputs(3) = Rate(0, eoNumeratorUnit3, eoDenominatorUnit1);
                return; 
            end
            
            % Harvest outputs are Competition Income Loss
            % And NCZ Area - both per paddock
            outputProducts = Rate(plantedCrop.state.yield, numeratorUnit, denominatorUnit);

            if (isnan(plantedCrop.state.yield))
                a = 1;
            end
            
            % Want an event output which is the income lost to competition.
            competitionCost = 0;
            NCZArea = 0;

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
                        NCZArea = cropInterface.number * plantedCrop.state.NCZWidth / 10000;
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
            
            % Now let's try to work out the profit of this crop.
            % We've already worked out the products. So we can get the
            % income. The last item to check is the cost for this event. We
            % need to check that someone hasn't made the cost for this
            % event dependent on this event output! But if not, we can
            % calculate everything we need.
            % We need to work out the open paddock yield though.
            
            profitSoFar = plantedCrop.profit(plantedCrop.plantedMonth, sim.monthIndex, false);
            openPaddockYield = plantedCrop.state.spatialInteractionDetail.baseYield * plantedCrop.state.spatialInteractionDetail.temporalModifier;

            regimeAreaUnit = Unit('', 'Area', 'Hectare');
            primaryArea = sim.currentPrimaryInstalledRegime.getAmount(regimeAreaUnit).number;
            if (isempty(sim.currentSecondaryInstalledRegime))
                secondaryArea = 0;
            else
                secondaryArea = sim.currentSecondaryInstalledRegime.getAmount(regimeAreaUnit).number;
            end
            
            % We know that yield is the only product for the Annual crop.
            % Therefore we know that there is only 1 row of product prices for this
            % crop.
            %      yieldPrice = sim.productPriceTable.('Oil_Mallee')(1, year)
            yieldPrice = sim.productPriceTable.(underscore(plantedCrop.cropObject.name))(1, sim.year).number;
            
            % this profitSoFar doesn't take competition into account as
            % we're trying to work out the opportunity cost of belts.
            profitSoFar = profitSoFar + openPaddockYield * primaryArea * yieldPrice;

            % Try to get the price for this event.
            eventCostPrice = sim.getCostPrice(plantedCrop.cropObject.name, 'Harvesting');
            
            if (eventCostPrice.denominatorUnit == eoNumeratorUnit3)
               error(['Attempt made to calculate Annual crop Harvesting cost in terms of opportunity cost of belts. That doesn''t make sense.', ...
                     ' Sorry it shows up in the list, but there was no other feasible way to get opportunity cost of belts without doing this.', ...
                     ' Please just make sure you don''t use the Belt Opportunity Cost as the unit in terms of which to calculate the Harvesting cost.']); 
            end
            
            % Use the costItem class to do all the calculations for us.
            % Just give it the eventOutputs we've worked out so far.
            thisEventCostItem = CostItem('Harvesting', plantedCrop, sim, eventOutputs, outputProducts);
            
            profitSoFar = profitSoFar - thisEventCostItem.cost.number;
            
            % Ok, no we can work out the non-belt profit per hectare.
            % Check that primaryArea + NCZ + secondaryArea = 100. I think
            % we reduce the primary area by the ncz area.
            profitPerHectare = profitSoFar / (primaryArea);
            
            opportunityCost = (NCZArea + secondaryArea) * profitPerHectare + competitionCost.number;
            
            eventOutputs(3) = Rate(opportunityCost, eoNumeratorUnit3, eoDenominatorUnit1);
                        
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
            valid = isa(gmd, 'AnnualGrowthModelDelegate');
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
           
           if ~strcmp(gmDel.propagationParameters.modelChoice, {'RainfallBasedAnnualGM', 'ManualAnnualGM'})
                NCZWidth = 0;
                return;
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
                    
                    if (estYield == 0)
                        NCZWidth = 0;
                        return
                    end
                    
                    % We assume that the yield is the only product and
                    % therefore it's the first product... hence the 1 in
                    % the following line.
                    yieldPrice = sim.productPriceTable.(underscore(plantedCrop.cropObject.name))(1, sim.year);
                    
                    if (yieldPrice.number == 0)
                        NCZWidth = 0;
                        return
                    end
                    
                    % This is the price per Ha.
                    income = yieldPrice.number * estYield;
                    
              %      plantCost = sim.costPriceTable.(underscore(plantedCrop.cropObject.name)).('Planting')(sim.year);
              %      harvestCost = sim.costPriceTable.(underscore(plantedCrop.cropObject.name)).('Harvesting')(sim.year);
                    
                    % To calculate costs, we look to the average costs seen
                    % in the past. For the first year planted, we use the
                    % values provided in the NCZOptimizedParameters.
                    thisRegimesPlants = plantedCrop.parentRegime.plantedCrops;
                    cumCosts = 0;
                    sameCropCount = 0;
                    areaUnit = Unit('', 'Area', 'Hectare');
                    for trpIx = 1:length(thisRegimesPlants)-1
                        if strcmp(plantedCrop.cropName, thisRegimesPlants(trpIx).cropName)
                            % Need to convert total cost to per Ha costs.
                            
                            hectares = plantedCrop.parentRegime.getAmount(areaUnit, thisRegimesPlants(trpIx).plantedMonth);
                            if isempty(hectares)
                                hectares = Amount(100, areaUnit);
                            end
                            perHaCosts = thisRegimesPlants(trpIx).costs(thisRegimesPlants(trpIx).plantedMonth, thisRegimesPlants(trpIx).destroyedMonth, 0) / hectares.number;
                            cumCosts = cumCosts + perHaCosts;
                            sameCropCount = sameCropCount + 1;
                        end
                    end                    
                    
                    if (sameCropCount == 0)
                       cost = optimisedParams.longTermAverageCosts;
                    else
                        % Need to convert total cost to per Ha costs.
                       plantedCrop.parentRegime.getAmount(areaUnit);
                       cost = cumCosts / sameCropCount;
                    end
                    
                    % Need to find all the past instances of this crop.
%                    cost = plantCost + harvestCost;
                                        
                    ratio = cost / income;
                    
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
                    
                    firstRM = gmDel.propagationParameters.rainfallBasedAnnualGM.firstRelevantMonth;
                    lastRM = gmDel.propagationParameters.rainfallBasedAnnualGM.lastRelevantMonth;
                    
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
                    if (avPSR == 0)
                        estGSR = avGSR;
                    else
                        estGSR = avGSR * PSR / avPSR;                    
                    end
                    
                    [compImpact, ~] = getImpact(sis, estGSR);
                    
                    [compExtent, compYieldLoss, ~, ~] = getRawSIBounds(sis, AGBMr.number * 1000, BGBMr.number * 1000, plantSpacing);
                    
                    breakEvenCroppingDist = calculateBreakEvenCroppingDistance(sis, compExtent, compYieldLoss, compImpact, ratio);
                        
                    csir = sim.currentSecondaryInstalledRegime;
                    if ~isempty(csir)
                       
                        regObj = csir.regimeObject;  
                        exclusionZoneWidth = regObj.getExclusionZoneWidth;

                        if isnan(breakEvenCroppingDist)
                            % If we get an infinite number, just set it to
                            % the extent. We don't get to put the whole
                            % paddock into fallow, but here we have a
                            % choice over the affected competition zone.
                            breakEvenCroppingDist = compExtent + 0.5 - exclusionZoneWidth;
                        end
                        
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
function [initialEvents, regularEvents, destructionEvents] =  makeAnnualGMImagineEvents()

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
function pPMs = makeAnnualGMProductPriceModels


    % All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    denominatorUnit = Unit('', 'Yield', 'Tonne');
    pPMs = PriceModel('Yield Income', unit, denominatorUnit);


end

