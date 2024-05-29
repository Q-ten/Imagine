classdef SimulationManager < handle
    % SimulationManager Responsible for performing simulations.
    %   SimulationManager will check that the ImagineObject and other
    %   Managers have sufficient information to go ahead with a simulation.
    %   Then it will provide a simulation dialogue, where the user can set
    %   the number of simulations to run, which plots to see, and start and
    %   stop the simulations.
    %   The SimulationManager may also deal with saving the simulations or
    %   exporting them to Access or another database. It may have a
    %   delegate class to deal with this.
    %
    %   SimulationManager will be a singleton class.
    %
    %   Properties will maintain a list of Simulations, which it will add
    %   to as simulations are started.
    
    % Implement a singleton class.
    methods (Access = private)
        function simMgr = SimulationManager()
        end
        
        % Put code that would normally appear in the constructor in here.
        function simulationManagerConstructor(obj)
            obj.refreshManagerPointers;
        end
    end
    
    methods (Static)
        function singleObj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = SimulationManager;
                localObj.simulationManagerConstructor;
            end
                singleObj = localObj;
        end
    end
    
    
    properties
        
        % Maintains it's own handles to the singleton objects in Imagine
        imagineOb
        cropMgr
        regimeMgr
        climateMgr
        
        % simulationWindow
        simulationWindow
        
        % A list of Simulations
        simulations = Simulation.empty(1, 0)
        
    end
    
    methods
        
                
        function refreshManagerPointers(simMgr)
          simMgr.imagineOb = ImagineObject.getInstance;          
          simMgr.cropMgr = CropManager.getInstance;
          simMgr.regimeMgr = RegimeManager.getInstance;
          simMgr.climateMgr = ClimateManager.getInstance;

          
          %           if ishandle(iwm.window)
%               handles = guidata(iwm.window);
%               handles.cropMgr = CropManager.getInstance;
%               handles.iwm = ImagineWindowManager.getInstance;
%               handles.imagineOb = ImagineObject.getInstance;
%               handles.regimeMgr = RegimeManager.getInstance;
%               handles.climateMgr = ClimateManager.getInstance;
% 
%               guidata(iwm.window, handles);
%           end              
        end
        
        function launchSimulationDialogue(simMgr)
            if ishandle(simMgr.simulationWindow)
                close(simMgr.simulationWindow)
            end
            simMgr.simulationWindow = simulationDialogue;
        end
        
        % Checks that Imagine is ready for a simulation. Requires that
        % crops exist, that regimes exist, that a sufficient climate model
        % exists, etc.
        function TF = isReadyForSimulation(simMgr)
            TF = simMgr.regimeMgr.isReadyForSimulation && simMgr.climateMgr.isReadyForSimulation;
        end
               
        
        % Runs numberOfSims simulations.
        function simulateInMonths(simMgr, numberOfSims)

            handles = guidata(simMgr.simulationWindow);
            handles.isRunning = true;
            guidata(handles.figure1, handles);

            wb = waitbar(0, {'Please wait while simulation completes...';'';'Sim: 0';'Year: 0'; 'Month:0';''});
%            try
                for simNum = 1:numberOfSims

                    wbxsstart = (simNum - 1) / numberOfSims;
                    wbxsend = simNum / numberOfSims;
                    waitbar(wbxsstart, wb, {'Please wait while simulation completes...';'';['Sim: ', num2str(simNum)];'Year: 0'; 'Month:0';''});

                    % Create the simulation
                    sim = Simulation();

                    % Create the price data that will be used in the simulation and fed
                    % to sim slowly as the simulation unfolds.
                    [sim.costPriceTable, sim.productPriceTable, sim.costPriceModelTable, sim.productPriceModelTable] = simMgr.cropMgr.generatePrices; 

%                    sim.costPriceTable
%                    sim.productPriceTable


%                     % Create the rainfall data that will be used in the simulation and
%                     % fed to sim slowly as the simulation unfolds.
%                     monthlyRainfall = simMgr.climateMgr.generateMonthlyRainfall;
                    % Resorted to putting it all in at the beginning
                    sim.monthlyRainfall = simMgr.climateMgr.generateMonthlyRainfall;
                    

                    % Run the simulation
                    for year = 1:simMgr.imagineOb.simulationLength

                        wbxsystart = (wbxsend - wbxsstart) * (year - 1) / simMgr.imagineOb.simulationLength + wbxsstart;
                        wbxsyend = (wbxsend - wbxsstart) * (year) / simMgr.imagineOb.simulationLength + wbxsstart;
                        waitbar(wbxsystart, wb, {'Please wait while simulation completes...';'';['Sim: ', num2str(simNum)];['Year: ', num2str(year)]; 'Month:0';''});
                        
                        % Set month index and day to first day of first month of the new year.
                        sim.monthIndex = year * 12 - 12 + 1;
                        sim.monthDay = 1;

                        % Update costs of events.
                        % Update prices of products.

                        % Get handles to the installedRegimes 
                        pR = sim.currentPrimaryInstalledRegime;
                        sR = sim.currentSecondaryInstalledRegime;

                        for month = 1:12
                                        
                            wbxsymstart = (wbxsyend - wbxsystart) * (month - 1) / 12 + wbxsystart;
                            % End not needed as this is the lowest level.
                            % wbxsymend = (wbxsyend - wbxsystart) * (month) / 12 + wbxsystart;
                            waitbar(wbxsymstart, wb, {'Please wait while simulation completes...';'';['Sim: ', num2str(simNum)];['Year: ', num2str(year)]; ['Month:', num2str(month)];''});
                            
                            % Update month index and day.
                            sim.monthIndex = year * 12 - 12 + month;

                            % When sim.monthDay is set to one, it will transfer
                            % plantedCrop states from the end of the previous
                            % month to the start of the new one.
                            sim.monthDay = 1;

                            % Install new regimes if possible.
                            if month == 1

                                if isempty(pR)
                                   sim.installRegimeIfPossible('primary');
                                   pR = sim.currentPrimaryInstalledRegime;
                                end

                                if isempty(sR)
                                   sim.installRegimeIfPossible('secondary');
                                   sR = sim.currentSecondaryInstalledRegime;
                                end
                            end

                            % Month Start

                            % Calculate the regime outputs and check if planting 
                            % is possible in both regimes. Do secondary first
                            % as primary needs secondary area to calculate it's
                            % own area.

                            if ~isempty(sR)
                                sR.calculateOutputs;                            
                            end

                            if ~isempty(pR)
                                pR.calculateOutputs;
                            end

                            if ~isempty(sR)
                                sR.plantIfPossible;
                            end

                            if ~isempty(pR)
                                pR.plantIfPossible;
                            end

                            % Set primary and secondary Planted Crops
                            pPC = sim.currentPrimaryPlantedCrop;
                            sPC = sim.currentSecondaryPlantedCrop;

                            % Update crop outputs for month start
                            if ~isempty(pPC)
                                pPC.calculateOutputs;
                            end

                            if ~isempty(sPC)
                                sPC.calculateOutputs;
                            end

                            % Check for any other 'month start' events...
                            % DO THIS LATER IF NEEDED

                            % Update rainfall
                    % Resorted to putting all the rainfall in at
                    % the beginning so we can cheat sometimes and
                    % look ahead. See above for where we just put
                    % it all in at once.
                    %       sim.monthlyRainfall(sim.monthIndex) = monthlyRainfall(sim.monthIndex);

                            % Propagate state from month start to month end for each
                            % regime.
                            postPropPS = [];
                            postPropSS = [];

                            % Get the new states
                            if ~isempty(pPC)
                                postPropPS = pPC.propagateState(sim);
                            end

                            if ~isempty(sPC)
                                postPropSS = sPC.propagateState(sim);
                            end

                            % Month End
                            sim.monthDay = 30;

                            % Set the new states once month end is set.
                            if ~isempty(pPC)
                                pPC.state = postPropPS;
                            end

                            if ~isempty(sPC)
                                sPC.state = postPropSS;
                            end

                            % Update crop outputs for month end.
                            if ~isempty(pPC)
                                pPC.calculateOutputs;
                            end

                            if ~isempty(sPC)
                                sPC.calculateOutputs;
                            end

                            % Check for the crop to be destroyed (final harvest) in both regimes.
                            pPCDestroyed = false;
                            if ~isempty(pPC)
                                pPCDestroyed = pPC.checkForDestruction(sim);
                            end

                            sPCDestroyed = false;
                            if ~isempty(sPC)
                                sPCDestroyed = sPC.checkForDestruction(sim);
                            end

                            % Test event triggers and process any events that occur for
                            % current crops in both regimes. Note that some of these
                            % events may be follow ons from a destructive harvest, so they
                            % are processed after we potentially trigger crop
                            % destruction. We still have a handle to the Planted Crop,
                            % so we can process events as we have not yet destroyed the
                            % crop.
                            if ~isempty(pPC)
                                pPC.processEvents(sim);                            
                            end

                            if ~isempty(sPC)  
                                sPC.processEvents(sim);
                            end

                            % To destroy the crop, we set the Installed Regime's crop
                            % index to 0.
                            % If not destroyed, transfer state to next month.
                            % We pass the post propagation state because it
                            % should set the end month state back to that after
                            % it moves the current state to the next month.
                            if pPCDestroyed
                               pR.cropIndex = 0; 
                               pPC.destroyedMonth = sim.monthIndex;
                            elseif ~isempty(pPC)
                               pPC.transferStateToNextMonth(postPropPS);    
                            end

                            if sPCDestroyed
                               sR.cropIndex = 0; 
                               sPC.destroyedMonth = sim.monthIndex;
                            elseif ~isempty(sPC)
                                sPC.transferStateToNextMonth(postPropSS);                                                                               
                            end


                        end % End months

                        % End regime if appropriate.
                        if ~isempty(pR)
                            if pR.finalMonth == sim.monthIndex
                                sim.primaryRegimeIndex = 0;              
                            end
                        end

                        if ~isempty(sR)
                            if sR.finalMonth == sim.monthIndex
                                sim.secondaryRegimeIndex = 0;              
                            end
                        end

                    end % End years and so simulation

                    if isempty(simMgr.simulations)
                        simMgr.simulations = sim;
                    else
                        simMgr.simulations(end + 1) = sim;
                    end

                end % end number of sims

                assignin('base', 'sims', simMgr.simulations) 
                assignin('base', 'sim', simMgr.simulations(end)) 

                handles = guidata(handles.figure1);
                handles.isRunning = false;
                guidata(handles.figure1, handles);
%             catch e
%                 disp(e.message)
%             end

            delete(wb);
            
        end % end SimulateInMonths(simMgr, numberOfSims)
       
        % This function returns data from the last simulation according to 
        % the type of data requested and filtered by the regimeLabelsToUse
        % and the cropNamesToUse.
        % The last entry, units, says what output the results should be in.
        % primaryData and secondaryData hold values (doubles) for each
        % month up to simulation length. 
        % For financials and products, we
        % have just the monthly values. For outputs, we have two rows.
        % First row is month start values, second row has month end values.
        function [primaryData, secondaryData, outputUnit] = getPlotData(simMgr, type, speciesName, regimeLabelsToUse, cropNamesToUse, unit)
            
            % Get the installedRegimes that match the regimeLabels to use.
            
            % For each installedRegime, select only the plantedCrops that match the cropNamesToUse. 
            
            % For the selected crops, get the occurences that match the
            % type and species name.
            
            % Compile these occurrences into the data to return.
            
            % Add the data to the appropriate output.
            
            % Set up the data matrices. The first row is for monthStart.
            % Second row for monthEnd.
            imOb = ImagineObject.getInstance;
            primaryData = zeros(2, imOb.simulationLength * 12);
            secondaryData = primaryData;
            outputUnit = Unit.empty(1, 0);
            
            if isempty(simMgr.simulations)
                return
            end
            
            % For now just use the last sim.
            sim = simMgr.simulations(end);
            inRegsToUse = InstalledRegime.empty(1, 0);
            
            % Get the installedRegimes that match.
            regimeLabels = {sim.installedRegimes.regimeLabel};
            for i = 1:length(regimeLabelsToUse)
                ix = find(strcmp(regimeLabelsToUse{i}, regimeLabels), 1, 'first');
                if ~isempty(ix)
                    inRegsToUse(end + 1) = sim.installedRegimes(ix);
                end
            end
            
            % Looks like inRegsToUse is set correctly by this point.
            
            % Work out the number amount of 'units' each month for primary
            % and secondary.
            primaryRegUnitNumbers = ones(1, imOb.simulationLength * 12);
            secondaryRegUnitNumbers = ones(1, imOb.simulationLength * 12);
            
            for i = 1:length(inRegsToUse)
                                
                amts = inRegsToUse(i).getAmounts(unit);

                if strcmp(inRegsToUse(i).zone, 'primary') || strcmp(inRegsToUse(i).zone, 'exclusive')
                    primaryRegUnitNumbers(inRegsToUse(i).installedMonth:inRegsToUse(i).finalMonth) = [amts.number];                
                elseif strcmp(inRegsToUse(i).zone, 'secondary')
                    secondaryRegUnitNumbers(inRegsToUse(i).installedMonth:inRegsToUse(i).finalMonth) = [amts.number];                
                else
                    error('Found an installedRegime with unknown zone.');
                end

            end

            % Make primary regime unit numbers match the two rows of
            % primaryData and secondaryData.
            primaryRegUnitNumbers = [primaryRegUnitNumbers;primaryRegUnitNumbers];
            secondaryRegUnitNumbers = [secondaryRegUnitNumbers; secondaryRegUnitNumbers];

            
            
            % Now to get the occurrences via the plantedCrops
            primaryPlantedCropsToUse = {};
            secondaryPlantedCropsToUse = {};
            for i = 1:length(inRegsToUse)
                plantedCropNames = {inRegsToUse(i).plantedCrops.cropName};
                cropLogicals = false(1, length(plantedCropNames));
                for j = 1:length(plantedCropNames)
                    ix = find(strcmp(plantedCropNames{j}, cropNamesToUse), 1, 'first');
                    if ~isempty(ix)
                        cropLogicals(j) = true;
                    end
                end
                
                if strcmp(inRegsToUse(i).zone, 'primary') || strcmp(inRegsToUse(i).zone, 'exclusive')
                    primaryPlantedCropsToUse{end+1} = inRegsToUse(i).plantedCrops(cropLogicals);                
                elseif strcmp(inRegsToUse(i).zone, 'secondary')
                    secondaryPlantedCropsToUse{end+1} = inRegsToUse(i).plantedCrops(cropLogicals);                                    
                else
                    error('Found an installedRegime with unknown zone.');
                end
            end
            
            allPrimaryPlantedCropsToUse = cat(2, primaryPlantedCropsToUse{:});
            allSecondaryPlantedCropsToUse = cat(2, secondaryPlantedCropsToUse{:});

            if ~isempty(allPrimaryPlantedCropsToUse)
                allPrimaryOccurrences = cat(2, [allPrimaryPlantedCropsToUse.occurrences]);
            else
                allPrimaryOccurrences = Occurrence.empty(1, 0);
            end
            if ~isempty(allSecondaryPlantedCropsToUse)
                allSecondaryOccurrences = cat(2, [allSecondaryPlantedCropsToUse.occurrences]);
            else
                allSecondaryOccurrences = Occurrence.empty(1, 0);
            end
            
            somePrimaryOutputs = false;
            someSecondaryOutputs = false;
            
            % Looks like allPlantedCropsToUse is working ok too.
            switch type
                
                case 'financial'

                    primaryRows = ([allPrimaryOccurrences.monthDay] == 30) + 1;
                    secondaryRows = ([allSecondaryOccurrences.monthDay] == 30) + 1;

                    switch speciesName

                        case 'Profit'
                            for i = 1:length(allPrimaryOccurrences)
                                % Add income
                                for j = 1:length(allPrimaryOccurrences(i).products)
                                    primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    + allPrimaryOccurrences(i).products(j).income.number;
                                end
                                
                                % Subtract costs.
                                for j = 1:length(allPrimaryOccurrences(i).costItems)
                                    if isempty(allPrimaryOccurrences(i).costItems(j).quantity)
                                        
                                    end
                                    primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    - allPrimaryOccurrences(i).costItems(j).cost.number;
                                 end
                            end
                            
                            for i = 1:length(allSecondaryOccurrences)
                                % Add income
                                for j = 1:length(allSecondaryOccurrences(i).products)
                                   secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                         + allSecondaryOccurrences(i).products(j).income.number;
                                end
                                
                                % Subtract costs.
                                for j = 1:length(allSecondaryOccurrences(i).costItems)
                                    secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                          - allSecondaryOccurrences(i).costItems(j).cost.number;
                                 end
                            end

                        case 'Income'
                            for i = 1:length(allPrimaryOccurrences)
                                % Add income
                                for j = 1:length(allPrimaryOccurrences(i).products)
                                    primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    + allPrimaryOccurrences(i).products(j).income.number;
                                end
                            end
                            
                            for i = 1:length(allSecondaryOccurrences)
                                % Add income
                                for j = 1:length(allSecondaryOccurrences(i).products)
                                   secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                         + allSecondaryOccurrences(i).products(j).income.number;
                                end
                            end

                        case 'Cost'
                            % Costs are not negative. Higher costs are bad.
                            for i = 1:length(allPrimaryOccurrences)
                                % Subtract costs.
                                for j = 1:length(allPrimaryOccurrences(i).costItems)
                                    primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    + allPrimaryOccurrences(i).costItems(j).cost.number;
                                 end
                            end
                            
                            for i = 1:length(allSecondaryOccurrences)
                                % Subtract costs.
                                for j = 1:length(allSecondaryOccurrences(i).costItems)
                                    
                                    secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                          + allSecondaryOccurrences(i).costItems(j).cost.number;
                                 end
                            end
                        otherwise
                            error('Unknown speciesName presented to SimulationManager.getPlotData for type ''financial''.');
                    end
                    
                    outputUnit = Unit('', 'Money', 'Dollar');
                    
                    primaryData = primaryData ./ primaryRegUnitNumbers;
                    secondaryData = secondaryData ./ secondaryRegUnitNumbers;
                    
                case 'product'
                    % If the type is product, use the species name to match
                    % the species name in the units of the occurrences that
                    % match the regimes, and the crops.
                    
                    primaryRows = ([allPrimaryOccurrences.monthDay] == 30) + 1;
                    secondaryRows = ([allSecondaryOccurrences.monthDay] == 30) + 1;
                    
                    % Also uses primary and secondary occurrences.
                    % Looking for the quantity produced. Not the income or
                    % costs.
                    for i = 1:length(allPrimaryOccurrences)
                        % Get the quantity if the product matches.
                        for j = 1:length(allPrimaryOccurrences(i).products)
                            % check if the unit name matches.
                            % if so, get the multiplier. 
                            % This unit should come from the simulation
                            % winodw, but that will come later. For now, we
                            % assume that all the units are the same.
                            prod = allPrimaryOccurrences(i).products(j);
%                                 ucm = UnitConvertor.getUnitConversionMultiplier(a1.unit.unitName, a2.denominatorUnit.unitName);
                            ucm = 1;
                            if strcmp(prod.quantity.unit.speciesName, speciesName)
                                primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    + prod.quantity.number * ucm;
                                outputUnit = prod.quantity.unit;                                                       

                            end
                        end
                    end

                    for i = 1:length(allSecondaryOccurrences)
                        % Get the quantity if the product matches.
                        for j = 1:length(allSecondaryOccurrences(i).products)
                            % check if the unit name matches.
                            % if so, get the multiplier. 
                            % This unit should come from the simulation
                            % winodw, but that will come later. For now, we
                            % assume that all the units are the same.
                            prod = allSecondaryOccurrences(i).products(j);
%                                 ucm = UnitConvertor.getUnitConversionMultiplier(a1.unit.unitName, a2.denominatorUnit.unitName);
                            ucm = 1;
                            if strcmp(prod.quantity.unit.speciesName, speciesName)
                                secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                    + prod.quantity.number * ucm;
                                outputUnit = prod.quantity.unit;                                                       
                            end
                        end
                    end
                    
                    primaryData = primaryData ./ primaryRegUnitNumbers;
                    secondaryData = secondaryData ./ secondaryRegUnitNumbers;

                    
                case 'output'
                    % For each installedCrop, work out the appropriate row
                    % for the desired output.
                    % Get the numbers out of those rows and put them in the
                    % appropriate month.
                    
                    % However, for outputs, we need to use the rate of the
                    % output to convert it to Per Paddock so that when we
                    % divide by the appropriate regime output, it will be
                    % given in the desired units. 
                    
                    % This only applies to outputs. Products are given as quantities (per
                    % Paddock) and so is income I believe (as it's based on
                    % a quantity).
                    
                    % There's a situation where we want to work out the
                    % harvest cost of mallees - which is a calculation
                    % beyond what we can practically do in the crop window.
                    
                    % So we're providing an output that has a unit rate.
                    
                    for i = 1:length(allPrimaryPlantedCropsToUse)
                       
                        pC = allPrimaryPlantedCropsToUse(i);
                        
                        % Get the row index we want..

                        % Its inefficient to get outputs from PC.
                        % This call copies the whole thing first and the
                        % checks if it's empty.                        
%                         if isempty(pC.outputsMonthStart)
%                             continue;
%                         else                             
                        if any(pC.outputsMonthStartSize == [0, 0])
                            continue;
                        else

                            
                            %  sns = pC.getOutputsMonthStart([], 1).unit.speciesName;
                          %  sn = speciesName;
                            unsTemp = pC.getOutputsMonthStart(:, 1);    % BUG - This is a Matlab bug again. Needs to be spread over two lines to work properly.
                            uns = [unsTemp.unit];
                            ix = find(strcmp({uns.speciesName}, speciesName), 1, 'first');
                            if isempty(ix)
                                continue
                            end
                        end
                        
                        % If here then there are outputs to add.
                        
                        somePrimaryOutputs = true;
                        
                        if isnan(pC.destroyedMonth)
                            lastMonthIndex = imOb.simulationLength * 12;
                        else
                            lastMonthIndex = pC.destroyedMonth;
                        end
                        outputsMS = pC.getOutputsMonthStart(ix, []);
                        outputsME = pC.getOutputsMonthEnd(ix, []);

                        % NOTE that all the units are going to be the
                        % same.
                        outputsMSDenQuants = pC.parentRegime.getAmounts(outputsMS(1, 1).denominatorUnit);
                        % This gives the regime quantities. Need to get the
                        % planted crop amounts. Need to index via regime
                        % and plant start month.
                        plantMonthRelativeToRegime = pC.plantedMonth - pC.parentRegime.installedMonth - 1;
                        outputsMSDenQuants = outputsMSDenQuants(plantMonthRelativeToRegime:plantMonthRelativeToRegime + length(outputsMS) - 1);
                        outputsMSQuantNs = [outputsMS.number] .* [outputsMSDenQuants.number];
                        
                        outputsMEDenQuants = pC.parentRegime.getAmounts(outputsME(1, 1).denominatorUnit);
                        % This gives the regime quantities. Need to get the
                        % planted crop amounts. Need to index via regime
                        % and plant start month.
                        outputsMEDenQuants = outputsMEDenQuants(plantMonthRelativeToRegime:plantMonthRelativeToRegime + length(outputsME) - 1);
                        outputsMEQuantNs = [outputsME.number] .* [outputsMEDenQuants.number];
                        
                        primaryData(1, pC.plantedMonth:lastMonthIndex) = outputsMSQuantNs;                        
                        primaryData(2, pC.plantedMonth:lastMonthIndex) = outputsMEQuantNs;                                                
                        
                        if isempty(outputsMS)
                           outputUnit = outputsME(1).unit; 
                        else
                           outputUnit = outputsMS(1).unit; 
                        end                                         
                    end
                    
                    for i = 1:length(allSecondaryPlantedCropsToUse)
                       
                        pC = allSecondaryPlantedCropsToUse(i);
                        
                        % Get the row index we want..
%                         if isempty(pC.outputsMonthStart)
%                             continue;
%                         else
                        if any(pC.outputsMonthStartSize == [0, 0])
                            continue
                        else
                            unsTemp = pC.getOutputsMonthStart(:, 1);    % BUG - This is a Matlab bug again. Needs to be spread over two lines to work properly.
                            uns = [unsTemp.unit];
                            ix = find(strcmp({uns.speciesName}, speciesName), 1, 'first');
                            if isempty(ix)
                                continue
                            end
                        end
                        
                        % If here then there are outputs to add.
                        
                        someSecondaryOutputs = true;
                        
                        if isnan(pC.destroyedMonth)
                            lastMonthIndex = imOb.simulationLength * 12;
                        else
                            lastMonthIndex = pC.destroyedMonth;
                        end
                        
                        outputsMS = pC.getOutputsMonthStart(ix, []);
                        outputsME = pC.getOutputsMonthEnd(ix, []);

                        
                        % NOTE that all the units are going to be the
                        % same.
                        if ~strcmp(outputsMS(1, 1).denominatorUnit.readableUnit, 'Units')
                            outputsMSDenQuants = pC.parentRegime.getAmounts(outputsMS(1, 1).denominatorUnit);
                            outputsMSQuantNs = [outputsMS.number] .* [outputsMSDenQuants(1:length(outputsMS)).number];

                            outputsMEDenQuants = pC.parentRegime.getAmounts(outputsME(1, 1).denominatorUnit);
                            outputsMEQuantNs = [outputsME.number] .* [outputsMEDenQuants(1:length(outputsME)).number];
                        else
                            outputsMSQuantNs = [outputsMS.number];
                            outputsMEQuantNs = [outputsME.number];
                        end
                        
                        secondaryData(1, pC.plantedMonth:lastMonthIndex) = outputsMSQuantNs;                        
                        secondaryData(2, pC.plantedMonth:lastMonthIndex) = outputsMEQuantNs;                                                

                        if isempty(outputsMS)
                           outputUnit = outputsME(1).unit; 
                        else
                           outputUnit = outputsMS(1).unit; 
                        end                                        

                    end
                                        
                    primaryData = primaryData ./ primaryRegUnitNumbers;
                    secondaryData = secondaryData ./ secondaryRegUnitNumbers;
                case 'eventOutput'
                                        
                    % If the type is an eventOutput, it should be just like a product.
                    % Except that it can be an Amount or a Rate...
                    % I think when it goes to access, if it's a Rate it
                    % gets converted to a per Paddock amount.
                    
                    % So we copied that section and changed it accordingly.
                    % Use the species name to match
                    % the species name in the units of the occurrences that
                    % match the regimes, and the crops.
                    
                    primaryRows = ([allPrimaryOccurrences.monthDay] == 30) + 1;
                    secondaryRows = ([allSecondaryOccurrences.monthDay] == 30) + 1;
                    
                    hasPrimaryData = false;
                    hasSecondaryData = false;
                    
                    % Also uses primary and secondary occurrences.
                    % Looking for the quantity produced. Not the income or
                    % costs.
                    for i = 1:length(allPrimaryOccurrences)
                        % Get the quantity if the product matches.
                        for j = 1:length(allPrimaryOccurrences(i).eventOutputs)
                            % check if the unit name matches.
                            % if so, get the multiplier. 
                            % This unit should come from the simulation
                            % winodw, but that will come later. For now, we
                            % assume that all the units are the same.
                            eventOutput = allPrimaryOccurrences(i).eventOutputs(j);
%                                 ucm = UnitConvertor.getUnitConversionMultiplier(a1.unit.unitName, a2.denominatorUnit.unitName);
                            ucm = 1;
                            if strcmp(eventOutput.unit.speciesName, speciesName)
                                primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) = primaryData(primaryRows(i), allPrimaryOccurrences(i).monthIndex) ...
                                                                                                    + eventOutput.number * ucm;
                                outputUnit = eventOutput.unit;  
                                hasPrimaryData = true;
                            end
                        end
                    end

                    for i = 1:length(allSecondaryOccurrences)
                        % Get the quantity if the product matches.
                        for j = 1:length(allSecondaryOccurrences(i).eventOutputs)
                            % check if the unit name matches.
                            % if so, get the multiplier. 
                            % This unit should come from the simulation
                            % winodw, but that will come later. For now, we
                            % assume that all the units are the same.
                            eventOutput = allSecondaryOccurrences(i).eventOutputs(j);
%                                 ucm = UnitConvertor.getUnitConversionMultiplier(a1.unit.unitName, a2.denominatorUnit.unitName);
                            ucm = 1;
                            if strcmp(eventOutput.unit.speciesName, speciesName)
                                secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) = secondaryData(secondaryRows(i), allSecondaryOccurrences(i).monthIndex) ...
                                                                                                    + eventOutput.number * ucm;
                                outputUnit = eventOutput.unit;
                                hasSecondaryData = true;
                            end
                        end
                    end
                    
                    primaryData = primaryData ./ primaryRegUnitNumbers;
                    secondaryData = secondaryData ./ secondaryRegUnitNumbers;
                otherwise
                    error('Unknown type presented to SimulationManager.getPlotData.');
            end
            
            if strcmp(type, 'output')
                % if a zone had no input, set it empty.
                if ~somePrimaryOutputs
                    primaryData = [];
                end
                if ~someSecondaryOutputs
                    secondaryData = [];
                end                    
            elseif strcmp(type, 'eventOutput')
                % if data is all zeros, set it empty.
                if all(all(primaryData == 0)) && hasPrimaryData == false
                    primaryData = [];
                end
                if all(all(secondaryData == 0)) && hasSecondaryData == false
                    secondaryData = [];
                end                    
            else
                % if data is all zeros, set it empty.
                if all(all(primaryData == 0))
                    primaryData = [];
                end
                if all(all(secondaryData == 0))
                    secondaryData = [];
                end                    
            end
                       
        end
        
        % This function looks at the list of installed regimes given as
        % input and returns a list of output units that are common to all the regimes in the list. 
        function commonUnits = getCommonRegimeUnits(simMgr, regimeLabelsToUse)
            
            % The unimaginative way to do this is to add all the first
            % counted regime's units, then iterate through the rest
            % removing any units in the list that aren't in the one being
            % looked at.
   
            if isempty(simMgr.simulations)
                commonUnits = Unit.empty(1, 0);
                return
            end
            
            inRegsToUse = InstalledRegime.empty(1, 0);
            
            % For now just use the last sim.
            sim = simMgr.simulations(end);
   
            % Get the installedRegimes that match.
            regimeLabels = {sim.installedRegimes.regimeLabel};
            for i = 1:length(regimeLabelsToUse)
                ix = find(strcmp(regimeLabelsToUse{i}, regimeLabels), 1, 'first');
                if ~isempty(ix)
                    inRegsToUse(i) = sim.installedRegimes(ix);
                end
            end        
            
            if isempty(inRegsToUse)
                commonUnits = Unit.empty(1, 0);
                return
            end
            
            commonUnits = inRegsToUse(1).regimeOutputUnits;
            
            % For the rest of the installed regimes
            % Check that each item still in commonUnits is represented in
            % the regime. If not, don't keep it for next time.
            for i = 2:length(inRegsToUse)
                saveUnits = true(1,length(commonUnits));
                
                for j = 1:length(commonUnits)
                   ix = find(commonUnits(j) == inRegsToUse(i).regimeOutputUnits, 1, 'first');
                   if isempty(ix)
                        saveUnits(j) = false;
                   end                   
                end
                commonUnits = commonUnits(saveUnits);
                
            end
            
            % By here, we should have stripped out all the units that
            % aren't represented in each regime to use.
            
        end
        
        function writeSimToAccess(simMgr)
           if isempty(simMgr.simulations)
               return
           end
           description = inputdlg('Please enter a description for this sim. It will be saved with the new entry in Access.','Enter Description', 6);
           if ~isempty(description)
              writeToAccess(simMgr.simulations(end), description{1})
           end
        end
    end
    
end

