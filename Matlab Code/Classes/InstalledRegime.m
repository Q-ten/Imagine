classdef InstalledRegime < handle
    %InstalledRegime Maintains data associated with a cropping regime that
    %is currently being simulated.
    %   An InstalledRegime has a list of crops (or cropNames perhaps), a list of 
    %   planting events so it knows how to get a new crop planted and a 
    %   PlantedCrop which is the crop currently planted under the regime.
    
    properties
        
        % parentSim - handle to the sim in which this regime is installed.
        parentSim
        
        % A handle to the Regime object for the regime
        regimeObject
        
        % The zone of the regime - 'primary' or 'secondary'
        % Could be made to be dependent
        zone
        
        % plantedCrops - a list of PlantedCrops, in order of when the crops
        % were planted.
        plantedCrops
        
        % outputs - outputs is a 
        % [a x m] array of Amounts containing the outputs from each month,
        % where a is the number of outputs calculated per month, and m is
        % the number of months in the simulation.
        outputs
       
        % cropIndex - the index of the current plantedCrop
        cropIndex
                
        % list of crop names used in the regime
        % Could be made to be dependent
        cropNames
        
        % initialTriggers - a cell array of trigger arrays. The cell array
        % corresponds to cropNames. Each cell contains an array of triggers
        % that match the corresponding crop's initialisation events.
        initialTriggers
        
        % installedMonth  - the monthIndex in which this regime was
        % installed.
        installedMonth
        
        % finalMonth - the monthIndex after which the regime will not be
        % installed.
        % Could be made to be dependent
        finalMonth
                        
    end
     
    % InstalledRegime constructor
    methods
        
        function obj = InstalledRegime(regimeObject, parentSim, zone)
            
            cropMgr = CropManager.getInstance;
            
            if nargin == 0
                return
            elseif nargin ~= 3
                error('Must pass 0 or 3 arguments to the InstalledRegime constructor.');
            else

                
                obj.regimeObject = regimeObject;
                obj.parentSim = parentSim;
                obj.zone = zone;
                obj.plantedCrops = PlantedCrop.empty(1, 0);
                obj.outputs = Amount.empty(1, 0); 
             %   obj.outputs.monthStart = Amount.empty(1, 0);
            %    obj.outputs.monthEnd = Amount.empty(1, 0);
                obj.cropIndex = 0;
                obj.cropNames = obj.regimeObject.cropNameList;
                obj.installedMonth = parentSim.monthIndex;
                obj.finalMonth = obj.regimeObject.finalYear * 12;

                % The only slightly difficult bit is the initialTriggers.
                %
                % InitialTriggers is a cell array whose indices correspond with
                % cropNames. Each cell has a list of initialTriggers that
                % should be used by the crop that corresponds to that cell.

                for i = 1:length(obj.cropNames)

                    % For each crop, we need to get the list of initialEvents.

                    % Need to combine the triggers from the regime and the crop...
                    % The way it works is that if an event is defined by the
                    % regime, use that event's trigger. Otherwise use the crop's
                    % trigger.

                    initialEvents = cropMgr.getCropsInitialEvents(obj.cropNames{i}); 

                    for j = 1:length(initialEvents)
                        % For each event in the crop check if the trigger is
                        % defined in the regime. If it is, use the trigger from the
                        % regime. Overwrite the triggers set just above.

                        % Try to get the trigger from regime. It will return an
                        % empty array if none exist.
                        obj.initialTriggers{i} = Trigger.empty(1, 0);
                        
                        regimeTrigger = obj.getRegimeTrigger(obj.cropNames{i}, initialEvents(j).name);

                        if ~isempty(regimeTrigger)
                           obj.initialTriggers{i}(end + 1) = regimeTrigger; 
                        else
                            % Set the crop's triggers as the default.
                            obj.initialTriggers{i} = [initialEvents.trigger];
                        end

                    end            
                end
                
            end            
        end
        
    end
    
    properties (Dependent)
       monthIndex
       monthDay
       currentPlantedCrop
       regimeLabel
       regimeOutputUnits
    end
    
    % get / set methods for dependent variables.
    methods

        % gets the current planted crop
        function cc = get.currentPlantedCrop(obj)
            if ~obj.cropIndex == 0
                cc = obj.plantedCrops(obj.cropIndex);
            else
                cc = PlantedCrop.empty(1, 0);
            end
        end
                        
        % Returns the current month index of the sim in which this
        % plantedCrop is a part.
        function mI = get.monthIndex(obj)
            mI = obj.parentSim.monthIndex;
        end
        
        % Returns the current month day of the sim in which this
        % plantedCrop is a part. 
        function mI = get.monthDay(obj)
            mI = obj.parentSim.monthDay;
        end
        
        function rL = get.regimeLabel(obj)
            rL = obj.regimeObject.regimeLabel;
        end
        
        function rOUs = get.regimeOutputUnits(obj)
            if ~isempty(obj.outputs)
                rOUs = [obj.outputs(:, 1).unit]; 
            else
                rOUs = Unit.empty(0, 1);
            end
        end
        
    end
    
    % Income, cost, profit methods
    methods
               
        % Calculates the monthly costs of the plantedCrops in this regime,
        % over the date range supplied by firstMonth and lastMonth
        % If asList is true, then cs is an array containing the monthly costs starting
        % from firstMonth. Otherwise, the total over the period is
        % returned.
        function cs = costs(obj, firstMonth, lastMonth, asList)
        
            if lastMonth < firstMonth
                cs = [];
                return;
            end
            
            if lastMonth > obj.monthIndex
               lastMonth = obj.monthIndex;
            end
            
            if firstMonth < 1 
                firstMonth = 1;
            end
            
            if asList
                cs = zeros(1, lastMonth - firstMonth + 1);
            else
                cs = 0;
            end
            
            for i = 1:length(obj.plantedCrops)
                cs = cs + obj.plantedCrops(i).costs(firstMonth, lastMonth, asList);
            end
            
        end
        
        % Calculates the monthly income of the plantedCrops in this regime,
        % over the date range supplied by firstMonth and lastMonth
        % If asList is true, then ins is an array containing the monthly income starting
        % from firstMonth. Otherwise, the total over the period is
        % returned.        
        function ins = income(obj, firstMonth, lastMonth, asList)
            if lastMonth < firstMonth
                ins = [];
                return;
            end
            
            if lastMonth > obj.monthIndex
               lastMonth = obj.monthIndex;
            end
            
            if firstMonth < 1 
                firstMonth = 1;
            end
            
            if asList
                ins = zeros(1, lastMonth - firstMonth + 1);
            else
                ins = 0;
            end
            
            for i = 1:length(obj.plantedCrops)
                ins = ins + obj.plantedCrops(i).income(firstMonth, lastMonth, asList);
            end
        
        end
        
        % Calculates the monthly profits of the plantedCrops in this regime,
        % over the date range supplied by firstMonth and lastMonth
        % If asList is true, then ps is an array containing the monthly profits starting
        % from firstMonth. Otherwise, the total over the period is
        % returned.
        function ps = profit(obj, firstMonth, lastMonth, asList)
            ps = obj.income(firstMonth, lastMonth, asList) - obj.costs(firstMonth, lastMonth, asList);
        end
        
    end
    
    % Methods for Simulation
    methods
        
        % Calculates the outputs for the installedRegime, based on the sim.
        % It then updates the installedRegime's outputs history
        % This mostly just wraps the function that's found in the Regime's RegimeDelegate.
        function calculateOutputs(obj)
            
            outputsColumn = obj.regimeObject.calculateOutputs(obj.parentSim);
            
            % The outputs returned from the current state will need to be added 
            % to the InstalledRegime's outputs property.

                if isempty(obj.outputs)
                    obj.outputs = outputsColumn';
                else
                    obj.outputs(:, obj.monthIndex - obj.installedMonth + 1) = outputsColumn';
                end                
            
        end
        
        function p = getRegimeParameter(obj, pname)
           p = obj.regimeObject.getRegimeParameter(pname); 
        end
        
        % Returns the Amount of type unit in the given month.
        function amt = getAmount(obj, unit, monthIndex)
            
            if (nargin == 2)
                monthIndex = obj.parentSim.monthIndex;
            end
            
            if (monthIndex > obj.monthIndex)                  
                amt = Amount.empty(1, 0);   
                return
            end
                 
            if (unit == Unit)
                amt = Amount(1, unit);
                return
            end

            % Grab the units column from outputs.
            outputColumnUnits = Unit.empty(1, 0);
            outputColumn = Amount.empty(1, 0);
            try
               outputColumn = obj.outputs(:, monthIndex - obj.installedMonth + 1);
               outputColumnUnits = [outputColumn.unit] ;
            catch                
            end
            
            % Work out the index of the matching column
            ix = find((outputColumnUnits == unit), 1, 'first');
            
            if isempty(ix)
               amt = Amount.empty(1, 0); 
            else
               amt = outputColumn(ix);
            end
            
        end
        
        % Like getAmount, but returns an array as long as the
        % installedRegime has existed.
        function amts = getAmounts(obj, unit)
        
            % Work out the index of the matching column
            ix = find(([obj.outputs(:, 1).unit] == unit), 1, 'first');
            
            if obj.finalMonth > obj.parentSim.monthIndex
               lastCol = obj.parentSim.monthIndex - obj.installedMonth + 1;
            else
               lastCol = obj.finalMonth - obj.installedMonth + 1; 
            end
            
            if isempty(ix)
               if (unit == Unit)                
                   amts = repmat(Amount(1, unit), 1, lastCol);                
               else
                   amts = Amount.empty(1, 0); 
               end
               return
            else
               amts = obj.outputs(ix, 1:lastCol);
            end        
        end
        
        % This function checks if there is not already a crop planted under
        % this installed regime and if not, then it tests the regime's
        % initialisation triggers in order. If one of the triggers is
        % triggered, then the crop corresponding to that trigger is
        % initialised.
        function plantIfPossible(obj)
            
            % Check if there is a crop already planted.
            
            if ~(obj.cropIndex == 0) 
                % Then we already have a crop planted.
                % Note that when a plantedCrop's destruction event is
                % triggered the SimulationManager sets the cropIndex back
                % to zero before the month ends.
                return
            end
            
            % If not, then test the initialisation triggers.
            % If one of these is triggered, then initialise that crop.
            
            % The difficult question is: How do we then initialise the
            % crop?
            
            % The elegant answer is that we simply create a PlantedCrop and
            % pass the constructor the relevant details it needs.
            % So what does it need? For a start it needs to know which
            % planting event was triggered. So perhaps we just pass the
            % plantingEventIndex. Then it will need things like the crop
            % object handle, a reference to the installedRegime, etc.
            %
            % But if the PlantedCrop comes from the CropManager, the
            % CropManager can supply all that.
            
            cropMgr = CropManager.getInstance;

            for i = 1:length(obj.initialTriggers)
                for j = 1:length(obj.initialTriggers{i})
                    
                    if obj.parentSim.isTriggered(obj.initialTriggers{i}(j))
                        
                        
                        
                        
                        % How do we get a planted crop? From the
                        % CropManager of course!
                        cropName = obj.cropNames{i};
                        initialisationEventIndex = j;
                        
                        pC = cropMgr.getPlantedCrop(cropName, obj, obj.parentSim, initialisationEventIndex);
                        
                        % Add the planted crop.
                        obj.cropIndex = length(obj.plantedCrops) + 1;
                        obj.plantedCrops(obj.cropIndex) = pC;
                        
                        % May need to fix up the units for the planting
                        % cost. Just redo them.
                        % If the costItem quantity returns non-zero as a
                        % regime output, use that value in the quantity.
                        obj.calculateOutputs;
                        ciQuantityUnit = pC.occurrences(1).costItems(1).quantity.unit;
                        amt = obj.getAmount(ciQuantityUnit);
                        if ~isempty(amt)
                            pC.occurrences(1).costItems(1).quantity.number = amt.number;
                        end
                        
                        % Return after the first trigger goes off. We don't
                        % want lots of crops being planted!
                        return
                        
                    end
                end                
            end
            
        end
        
        % Returns a trigger if it has been defined in the regime for the
        % crop and the event. Returns an empty trigger if none found.
        function rT = getRegimeTrigger(obj, cropName, eventName)
            
            rT = Trigger.empty(1, 0); 
            
            % Get the crop names
            cETs = obj.regimeObject.cropEventTriggers;
            cropNamesInRegime = {cETs.cropName};
            
            
            % Get the index of the crop in the regime
            regimeCropIndex = find(strcmp(cropNamesInRegime, cropName), 1, 'first');
            
            if isempty(regimeCropIndex)
                return
            else
                
                eTs = cETs(regimeCropIndex).eventTriggers;
                
                eventIndex = find(strcmp({eTs.eventName}, eventName), 1, 'first');
                if ~isempty(eventIndex)
                    ret = eTs(eventIndex);
                    rT = ret.trigger;
                end                
            end

        end
    end
    
end

