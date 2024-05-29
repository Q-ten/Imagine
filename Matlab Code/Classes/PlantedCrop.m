classdef PlantedCrop < handle
    %PlantedCrop Contains data for a crop undergoing a simulation.
    %   A PlantedCrop is one that is being simulated while the object
    %   exists. It will have a reference to the Crop object, a list of
    %   events (or at least the triggers for the events) which will be the
    %   combined triggers from the regime too, and it will have a list of
    %   previous events that have occurred during the lifecycle of the
    %   crop.
    %
    %   It can be either the primary or the secondary regime crop.
    
    properties
        
        % states - maintain the state of the crop throughout the lifetime of the sim.
        % It will be a 2xn array of states where the first row is the state
        % at the beginning of the month, and the second row has the state
        % at the end of the month.
        % Columns count months, with the first column containing the state
        % of the crop in the month it was first planted. So states(1,1)
        % contains the initial state of the crop.
        states
                
        % parentRegime - the InstalledRegime under which this crop has been
        % planted.
        parentRegime
               
        % A reference to the Crop object
        cropObject
        
        % A list of triggers that will be used for the crop, with a
        % property for each section of the triggers.
        % These triggers must correspond to the events in
        % growthModelInitialEvents, growthModelRegularEvents and
        % growthModelDestructionEvents. We use the index of the trigger to
        % find the imagineEvent.        
        regularTriggers
        destructionTriggers
        
        % occurences
        % See Dependent section.
        
        % outputs
        % See Dependent section
        
        % plantedMonth - the monthIndex that the plantedCrop was planted
        plantedMonth
        
        % destroyedMonth - the monthIndex that the plantedCrop was
        % destroyed. Is NaN before it's destroyed.
        destroyedMonth = NaN
                
    end
    
    properties (Access = private)
       occurrenceCount = 0
       privateOccurrences
       
      % privateOutputUnitsColumn
       privateOutputsMonthEnd = Rate.empty(1, 0);
       privateOutputsMonthStart = Rate.empty(1, 0);
       privateOutputsMonthEndIndex = 0
       privateOutputsMonthStartIndex = 0
       
       recentProductsList = Product.empty(1, 0);
    end
    
    properties (Dependent)

        cropName
        
        % Gets or sets the current state of the crop.
        state
        monthIndex
        monthDay          
        
        % occurrences - A list of Occurrences, where an occurrence
        % represents an event having been triggered during the sim.
        occurrences 
        
        % outputs - a history of the outputs of this Planted Crop, with
        % outputs in both the beginning of the month and the end.
        % The output names can be found under outputs.names, a cell column
        % of names.
        % Then under monthStart, the row of the output name corresponds to the 
        % row of the values.
        % So if outputs.names{2, 1} = 'Biomass', then outputsMonthStart(2,:)
        % would give the Biomass Amount at the start of the months.
        % outputsMonthStart (an array of Amounts)
        % outputsMonthEnd (an array of Amounts)
  %      outputsMonthStart
  %      outputsMonthEnd
        
        outputsMonthStartSize
        outputsMonthEndSize
        
    end
    
    % The constructor
    methods
       
        % The PlantedCrop constructor either takes 0 arguments or 
        function obj = PlantedCrop(cropObject, parentRegime, sim, initialisationEventIndex)
            
            if nargin == 0
                return
            elseif nargin ~= 4
                error('Must pass 0 or 4 arguments to the PlantedCrop constructor.');
            else
            
                obj.cropObject = cropObject;

                obj.parentRegime = parentRegime;

                obj.privateOccurrences = Occurrence.empty(1,0);
                obj.plantedMonth = sim.monthIndex;


                % Need to combine the triggers from the regime and the crop...
                % The way it works is that if an event is defined by the
                % regime, use that event's trigger. Otherwise use the crop's
                % trigger.

                obj.regularTriggers =  [obj.cropObject.growthModel.growthModelRegularEvents.trigger];

                for i = 1:length(obj.regularTriggers)
                    % For each event in the crop check if the trigger is
                    % defined in the regime. If it is, use the trigger from the
                    % regime.
                    %
                    % Note that the way triggers work is that if they have been
                    % defined in the regime then we should use those triggers.
                    % Otherwise we should use the crop ones. So here, we start
                    % with the crop triggers, but overwrite them if the regime
                    % defines the same trigger.

                    % Get the name of the event from the crop's growthModel's
                    % events using the index.
                    eventName = obj.cropObject.growthModel.growthModelRegularEvents(i).name;

                    % Try to get the trigger from regime. It will return an
                    % empty array if none exist.
                    regimeTrigger = obj.parentRegime.getRegimeTrigger(cropObject.name, eventName);

                    if ~isempty(regimeTrigger)
                       obj.regularTriggers(i) = regimeTrigger; 
                    end

                end
                
                % Add the financial triggers to the regular triggers.
               
                cropFinancialEvents = obj.cropObject.financialEvents;  
                cropFinancialTriggers = [cropFinancialEvents.trigger];
                for i = 1:length(cropFinancialEvents)
                   eventName = obj.cropObject.financialEvents(i).name;
                   regimeTrigger = obj.parentRegime.getRegimeTrigger(cropObject.name, eventName);
                   if ~isempty(regimeTrigger)
                       cropFinancialTriggers(i) = regimeTrigger; 
                   else
                       cropFinancialTriggers(i) = cropFinancialEvents(i).trigger;                        
                   end
                end
                
                % Note - we need to go via the regime so we can deal with
                % regime redefined growthModel financial events too.
                obj.regularTriggers = [obj.regularTriggers, [obj.cropObject.growthModel.growthModelFinancialEvents.trigger], cropFinancialTriggers];


                
                obj.destructionTriggers = [obj.cropObject.growthModel.growthModelDestructionEvents.trigger];

                for i = 1:length(obj.destructionTriggers)

                    % Get the name of the event from the crop's growthModel's
                    % events using the index.
                    eventName = obj.cropObject.growthModel.growthModelDestructionEvents(i).name;

                    % Try to get the trigger from regime. It will return an
                    % empty array if none exist.
                    regimeTrigger = obj.parentRegime.getRegimeTrigger(cropObject.name, eventName);

                    if ~isempty(regimeTrigger)
                       obj.destructionTriggers(i) = regimeTrigger; 
                    end

                end

                % Run the initialisationEvent
                % Note that this will set the initial state as the
                % transitionFunction will be called.
                evt = cropObject.growthModel.growthModelInitialEvents(initialisationEventIndex);
                obj.calculateOutputs;
                obj.processEvent(evt, sim);
                obj.calculateOutputs;

            end
        end
    end
    
    % The costs, income and profit methods.
    methods

        % Calculate costs from the previous events.
        % Return the monthly costs in the range given by firstMonth to
        % lastMonth.
        % If asList evaluates to true, then an array of monthly costs is
        % returned. Otherwise the sum of the costs over this period is
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
            
            cs = zeros(1, lastMonth - firstMonth + 1);
            
            for i = 1:length(obj.occurrences)
                mI = obj.occurrences(i).monthIndex;
                if mI >= firstMonth && mI <= lastMonth
                    cInd = mI - firstMonth + 1;
                    cost = 0;
                    for j = 1:length(obj.occurrences(i).costItems)
                        cost = cost + obj.occurrences(i).costItems(j).cost.number;
                    end
                    cs(cInd) = cs(cInd) + cost;
                end                        
            end
            
            if ~asList 
                cs = sum(cs);
            end
            
        end
        
        % Calculate income from the previous events.
        % Return the monthly income in the range given by firstMonth to
        % lastMonth.
        % If asList evaluates to true, then an array of monthly income is
        % returned. Otherwise the sum of the income over this period is
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
            
            ins = zeros(1, lastMonth - firstMonth + 1);
            
            for i = 1:length(obj.occurrences)
                mI = obj.occurrences(i).monthIndex;
                if mI >= firstMonth && mI <= lastMonth
                    inInd = mI - firstMonth + 1;
                    income = 0;
                    for j = 1:length(obj.occurrences(i).products)
                        income = income + obj.occurrences(i).products(j).income.number;
                    end
                    ins(inInd) = ins(inInd) + income;
                end                        
            end
            
            if ~asList 
                ins = sum(ins);
            end
        end
            
        % Calculate profits from the previous events.
        % Return the monthly profits in the range given by firstMonth to
        % lastMonth.
        % If asList evaluates to true, then an array of monthly profits is
        % returned. Otherwise the sum of the profits over this period is
        % returned.
        function ps = profit(obj, firstMonth, lastMonth, asList)
            ps = obj.income(firstMonth, lastMonth, asList) - obj.costs(firstMonth, lastMonth, asList);
        end
        
    end
    
    
    % The get/set methods of dependent variables.
    methods 
       
        function cN = get.cropName(obj)
            cN = obj.cropObject.name;
        end
        
        % Returns the current month index of the sim in which this
        % plantedCrop is a part.
        function mI = get.monthIndex(obj)
            mI = obj.parentRegime.monthIndex;
        end
        
        % Returns the current month day of the sim in which this
        % plantedCrop is a part.
        function mI = get.monthDay(obj)
            mI = obj.parentRegime.monthDay;
        end
        
        % Returns the list of occurrences. A private occurrences property
        % maintains a list that gets longer when needed.
        function ocs = get.occurrences(obj)
           ocs = obj.privateOccurrences(1:obj.occurrenceCount); 
        end
        
        
        % Gets and sets the current state from the history of states, based
        % on the sim's current month (via the parent regime)
        function st = get.state(obj)
            
            if isempty(obj.states)
                st = [];
                return
            end
            
            st = []; 
            if obj.monthDay == 1                      
                st = obj.states{1, obj.monthIndex - obj.plantedMonth + 1};
            elseif obj.monthDay == 30
                st = obj.states{2, obj.monthIndex - obj.plantedMonth + 1};            
            end
        end
        
        function set.state(obj, st)
            % increase size if necessary
            col = obj.monthIndex - obj.plantedMonth + 1;
                        
%             size(obj.states, 2)
%             if size(obj.states, 2) <= col
%                 if col < 600
%                     obj.states(1, 600) = obj.states(1,1);
%                     obj.states(1, 600) = obj.states(1,599);
%                 elseif col < 6000
%                     obj.states(1, 6000) = obj.states(1,1);
%                     obj.states(1, 6000) = obj.states(1,5999);    
%                 else
%                     obj.states(1, col * 2) = obj.states(1,1);
%                     obj.states(1, col * 2) = obj.states(1,col * 2 - 1);    
%                 end
%             end
%             
            if obj.monthDay == 1
                if isempty(obj.states)
                    obj.states = {st};    
                else
                    obj.states{1, col} = st;
                end
            elseif obj.monthDay == 30
                obj.states{2, col} = st;            
            end
        end
        
    end
    
    % The simulation methods
    methods
        
        % Returns the Amount of type unit in the given month.
        % If monthIndex and day omitted, then the latest data is returned,
        % whenever that may be. In most circumstances that will be the
        % current month and day, however a planting event may require data
        % from another crop, in which case the outputs will not have been
        % propagated. Therefore, we check the crop is still planted, then
        % return the end outputs.
        % This function indexes the outputs array, which in turn contains
        % Rates. So getAmount is actually getRate, but that doesn't quite
        % sound right.
        function amt = getAmount(obj, unit, monthIndex, monthDay)
            
            if nargin == 2
                monthIndex = obj.monthIndex;
                monthDay = obj.monthDay;
            end
            
            if (monthIndex > obj.monthIndex) || (monthIndex == obj.monthIndex && monthDay > obj.monthDay)                  
                amt = Amount.empty(1, 0);   
                return
            end
            
            if (unit == Unit)
                amt = Amount(1, unit);
                return
            end
            
            
            outputColumnUnits = Unit.empty(1, 0);
            outputColumn = Rate.empty(1, 0);
            try
               if monthDay == 1
                   outputColumn = obj.privateOutputsMonthStart(:, monthIndex - obj.plantedMonth + 1);
               else
                   outputColumn = obj.privateOutputsMonthEnd(:, monthIndex - obj.plantedMonth + 1);
               end
               outputColumnUnits = [outputColumn.unit];
            catch                
            end

            % Work out the index of the matching column:
            if isempty(outputColumnUnits)
                ix = [];
            else                
                ix = find(outputColumnUnits == unit, 1, 'first');                
            end
            
            amt = Rate.empty(1, 0);
            if ~isempty(ix)
               if monthDay == 1
                   if obj.privateOutputsMonthStartIndex >= monthIndex - obj.plantedMonth + 1
                        amt = outputColumn(ix);
                   end
               else
                   if obj.privateOutputsMonthEndIndex ~= 0
                        amt = outputColumn(ix);
                   end
               end
            end
            
            if isempty(amt)
               amt = obj.parentRegime.getAmount(unit, monthIndex); 
            end
            
            
%             % Grab the units column from outputs.
%             outputsColumn = Amount.empty(1, 0);
%             if monthDay == 1
%                 % Getting the size of outputsMonthStart is incredibly
%                 % inefficient. Rather we can calculate it.
%                 % Outputs columsn is simply outputsMonthStartIndex.
%                 
% %                 if size(obj.outputsMonthStart, 2) >= monthIndex - obj.plantedMonth + 1
% %                     outputsColumn = obj.outputsMonthStart(:, monthIndex - obj.plantedMonth + 1);
% %                 end
%                 if obj.privateOutputsMonthStartIndex >= monthIndex - obj.plantedMonth + 1
%                     outputsColumn = obj.getOutputsMonthStart([], monthIndex - obj.plantedMonth + 1);
%                 end
%             else
%                 % To check if outputsMonthEnd is empty, we can check if
%                 % outputsMonthEndIndex == 0.
% %                 if ~isempty(obj.outputsMonthEnd)
% %                     outputsColumn = obj.outputsMonthEnd(:, monthIndex - obj.plantedMonth + 1);
% %                 end
%                 % Todo: Improve efficiency. We allocate a column of new
%                 % Rates and then select one. Can we not simply put some
%                 % checks on the privateOuputsMonthEnd and then access it
%                 % directly?
%                 if obj.privateOutputsMonthEndIndex ~= 0
%                     outputsColumn = obj.getOutputsMonthEnd([], monthIndex - obj.plantedMonth + 1);
%                 end
%             end
%             
%             % Work out the index of the matching column
%             if isempty(outputsColumn)
%                 ix = [];
%             else
%                 ix = find([outputsColumn.unit] == unit, 1, 'first');
%             end
%             
%             if isempty(ix)
%                amt = obj.parentRegime.getAmount(unit, monthIndex); 
%             else
%                amt = outputsColumn(ix);
           
            
        end
        
        % Returns the amount of production for the unit that was most
        % recently harvested. rp will be an Amount if product can be found,
        % or else it will be empty.
        function rp = getMostRecentProduction(obj, speciesName)
            
            rp = Amount.empty(1, 0);
           ix = [];
           if ~isempty(obj.recentProductsList)
               a = [obj.recentProductsList.quantity];
               b = [a.unit];
               ix = find(strcmp({b.speciesName}, speciesName), 1, 'first');
           end
           
           if ~isempty(ix)
               rp = obj.recentProductsList(ix).quantity;
           end
        end
        
        % Calculates the outputs for the plantedCrop, based on the plantedCrop's state.
        % It then updates the plantedCrop's outputs history.
        % This mostly just wraps the function that's found in the Crop's growthModelDelegate.
        function calculateOutputs(obj)
            % The GrowthModel will calculate the outputs based on the
            % state. If it turns out the sim is required as well, we'll
            % change the code to pass the sim too. But the idea of outputs
            % is that they are a function of the state at each point in
            % time. Add stuff to the state if you need it tracked for
            % outputs.
            
            % The outputs returned from the current state will need to be added 
            % to the PlantedCrop's outputs property.
            
            % Just a check to not recalculate the start month outputs if
            % they've already been done at the end of the previous month.
            if obj.monthDay == 1 && obj.privateOutputsMonthStartIndex < obj.monthIndex - obj.plantedMonth + 1
                outputsColumn = obj.cropObject.growthModel.calculateOutputs(obj.state);
                obj.setOutputsMonthStartColumn(obj.monthIndex - obj.plantedMonth + 1, outputsColumn);
            else
                outputsColumn = obj.cropObject.growthModel.calculateOutputs(obj.state);
                obj.setOutputsMonthEndColumn(obj.monthIndex - obj.plantedMonth + 1, outputsColumn);
            end            
        end
        
        function setOutputsMonthStartColumn(obj, colInd, outputsColumn)
            % Costly
            if size(obj.privateOutputsMonthStart, 2) < colInd
                if isempty(obj.privateOutputsMonthStart)
                    if isempty(outputsColumn)
                        % If a crop has no outputs, everything should
                        % remain zero.
                        return
                    end
                    % make it with 14 months
                    obj.privateOutputsMonthStart = repmat(outputsColumn, 1, 14);
                    obj.privateOutputsMonthStartIndex = colInd;
                    return
                else
                    % make it with the full range.
                    imOb = ImagineObject.getInstance;
                    newMonths = [obj.privateOutputsMonthStart repmat(outputsColumn, 1, imOb.simulationLength * 12 - 14)];
                    obj.privateOutputsMonthStart = newMonths;
                    obj.privateOutputsMonthStartIndex = colInd;
                    return
                end
            end
%             for i = 1:length(outputsColumn)
%                 % Just set the number in the existing rate.
%                 % This is actually slower for some reason...
%                 obj.privateOutputsMonthStart(i, colInd).number = outputsColumn(i).number;
%             end
            obj.privateOutputsMonthStart(:, colInd) = outputsColumn;  
            obj.privateOutputsMonthStartIndex = colInd;
        end
        
        function setOutputsMonthEndColumn(obj, colInd, outputsColumn)
            sz = size(obj.privateOutputsMonthEnd, 2);
            if sz < colInd
                if isempty(obj.privateOutputsMonthEnd)
                    if isempty(outputsColumn)
                        % If a crop has no outputs, everything should
                        % remain zero.
                        return
                    end
                    % make it with 14 months
                    obj.privateOutputsMonthEnd = repmat(outputsColumn, 1, 14);
                    obj.privateOutputsMonthEndIndex = 1;
                    return
                else
                    % make it with the full range.
                    imOb = ImagineObject.getInstance;
                    newMonths = [obj.privateOutputsMonthEnd repmat(outputsColumn, 1, imOb.simulationLength * 12 - 14)];
                    obj.privateOutputsMonthEnd = newMonths;
                    obj.privateOutputsMonthEndIndex = 15;
                    return
                end
             end
  
%             for i = 1:length(outputsColumn)
%                 obj.privateOutputsMonthEnd(i, colInd).number = outputsColumn(i).number;
%             end
            
            obj.privateOutputsMonthEnd(:, colInd) = outputsColumn;
            obj.privateOutputsMonthEndIndex = colInd;
        end
        
%         function omec = get.outputsMonthEnd(obj)
%             if obj.privateOutputsMonthEndIndex > 0
%                 omec = obj.privateOutputsMonthEnd(:, 1:obj.privateOutputsMonthEndIndex);
%             else
%                 omec = Rate.empty(1, 0);
%             end            
%         end
        
        function sz = get.outputsMonthStartSize(obj)
            sz = [size(obj.privateOutputsMonthStart, 1), obj.privateOutputsMonthStartIndex];
        end
        
        function sz = get.outputsMonthEndSize(obj)
            sz = [size(obj.privateOutputsMonthEnd, 1), obj.privateOutputsMonthEndIndex];            
        end
               
        
%         function omsc = get.outputsMonthStart(obj)
%             if obj.privateOutputsMonthStartIndex > 0
%                 omsc = obj.privateOutputsMonthStart(:, 1:obj.privateOutputsMonthStartIndex);
%             else
%                 omsc = Rate.empty(1, 0);
%             end
%         end
        
        % Provides an interface to outputsMonthStart by indexing columns.
        % This is a potentially slow task as all the Rates need to be
        % reallocated each time. Cannot use : operator to indicate all rows
        % or columns. Instead use empty array. []
        function omsc = getOutputsMonthStart(obj, rowIndices, colIndices)
            if obj.privateOutputsMonthStartIndex <= 0
                omsc = Rate.empty(1, 0);            
                return
            end
            availableCols = 1:obj.privateOutputsMonthStartIndex;
            allRows = true;
            allCols = true;
            if nargin == 3
                if ~isempty(colIndices)
                    allCols = false;
                end
                if ~isempty(rowIndices)
                    allRows = false;
                end
            end
            if nargin == 2
                if ~isempty(rowIndices)
                    allRows = false;
                end
            end
            
            if allRows && allCols
                omsc = obj.privateOutputsMonthStart(:, availableCols);                                           
            elseif allRows && ~allCols
                % Costly
                omsc = obj.privateOutputsMonthStart(:, availableCols(colIndices));                                           
            elseif ~allRows && allCols
                omsc = obj.privateOutputsMonthStart(rowIndices, availableCols);                                           
            else
                omsc = obj.privateOutputsMonthStart(rowIndices, availableCols(colIndices));                           
            end
        end
        
        % Provides an interface to outputsMonthStart by indexing columns.
        % This is a potentially slow task as all the Rates need to be
        % reallocated each time. Cannot use : operator to indicate all rows
        % or columns. Instead use empty array. []
        function omsc = getOutputsMonthEnd(obj, rowIndices, colIndices)
            if obj.privateOutputsMonthEndIndex <= 0
                omsc = Rate.empty(1, 0);            
                return
            end
            availableCols = 1:obj.privateOutputsMonthEndIndex;
            allRows = true;
            allCols = true;
            if nargin == 3
                if ~isempty(colIndices)
                    allCols = false;
                end
                if ~isempty(rowIndices)
                    allRows = false;
                end
            end
            if nargin == 2
                if ~isempty(rowIndices)
                    allRows = false;
                end
            end
            
            if allRows && allCols
                omsc = obj.privateOutputsMonthEnd(:, availableCols);                                           
            elseif allRows && ~allCols
                % Costly
                omsc = obj.privateOutputsMonthEnd(:, availableCols(colIndices));                                           
            elseif ~allRows && allCols
                omsc = obj.privateOutputsMonthEnd(rowIndices, availableCols);                                           
            else
                omsc = obj.privateOutputsMonthEnd(rowIndices, availableCols(colIndices));                           
            end
        end
        
        % Checks all the regular events and if triggered, processes them.
        % fakeOut is to process the events but not officially.
        function ocs = processEvents(obj, sim, fakeOut)            

            if (nargin == 2)
                fakeOut = false;
            end
            ocs = Occurrence.empty(1, 0);
            
            ix = 1;
            for i = 1:length(obj.regularTriggers)
            
                % Check each trigger
                if sim.isTriggered(obj.regularTriggers(i), obj)
                   gmEvents = obj.cropObject.growthModel.growthModelRegularEvents;
                   gmFinEvents = obj.cropObject.growthModel.growthModelFinancialEvents;
                   finEvents = obj.cropObject.financialEvents;
                   if (i <= length(gmEvents))
                       % If triggered, process.
                       imEvent = gmEvents(i);
                   elseif i <= (length(gmEvents) + length(gmFinEvents))
                       imEvent = gmFinEvents(i - length(gmEvents));
                   else
                       imEvent = finEvents(i - length(gmEvents) - length(gmFinEvents));
                   end
                   oc = obj.processEvent(imEvent, sim, fakeOut);                       
                   if (fakeOut)
                       ocs(ix) = oc;
                       ix = ix + 1;
                   end
                end
                
            end
            
        end
        
        % Checks whether the destruction event is triggered and if so,
        % processes it. In this sense it is similar to processEvents.
        % However, if triggered, it will return True, which is meant to be
        % a signal to the simulationManager to end the crop soon - that is
        % it wont be the currentPlantedCrop of the regime any more.
        function TF = checkForDestruction(obj, sim)
               
            TF = false;
            
            for i = 1:length(obj.destructionTriggers)
            
                % Check each trigger
                if obj.parentRegime.parentSim.isTriggered(obj.destructionTriggers(i))
                   
                    % Set TF to true to signal crop desctruction should
                    % commence.
                    TF = true;
                   
                    % And process as normal.
                    imEvent = obj.cropObject.growthModel.growthModelDestructionEvents(i);
                    obj.processEvent(imEvent, sim);
                    
                end
                
            end
        end
        
        % This function simply wraps the Crop's growthModel's
        % propagateState function. The returned state is the newly
        % propagated state.
        % Note that we don't simply set the new state because when the
        % simulation is running we want to run primary and secondary at the
        % same time and we don't want the sim to have the primary crop
        % propagated before the secondary has been calculated. See the
        % simulationManager for where propagateState is used.
        function newState = propagateState(obj, sim)
            [newState, productRates] = obj.cropObject.growthModel.propagateState(obj, sim);
            
            if ~isempty(productRates)
                productAmounts = Amount.empty(1, 0);
    
                % Multiply rate by amount of the denominator...
                for j = 1:length(productRates)                      
                    r = productRates(j);
                    productAmounts(j) = r * obj.getAmount(r.denominatorUnit);                        
                end

                % Create the Occurrence
                oc = Occurrence(QuantityBasedCondition.nullEventName, productAmounts, Amount.empty(1, 0), obj, sim);
                obj.addOccurrence(oc);
            end            
        end
        
        
        % This function transfers the current end state for the month to
        % the start state for the next month. It takes an optional argument
        % monthEndState which sets the months's end state after the
        % transfer. This is because in the simulation, we do the harvest
        % etc at the end of the month, and this changes the state which
        % becomes the next months' state, but we want to maintain the
        % post-propagation state (before harvest) as the month end state.
        function transferStateToNextMonth(obj, monthEndState)
            
            % must be at the end of the month to call this.
            if obj.monthDay == 30
                
                % Transfer the state
                obj.states{1, obj.monthIndex - obj.plantedMonth + 1 + 1} = obj.state;
                
                % Set the outputs for the start of the next month...
                outputsColumn = obj.cropObject.growthModel.calculateOutputs(obj.state);
                obj.setOutputsMonthStartColumn(obj.monthIndex - obj.plantedMonth + 1 + 1, outputsColumn);
                
                % If we got the monthEndState argument then reset the
                % current monthEnd state
                if nargin == 2
                    obj.state = monthEndState;
                end
            else
                error('Tried to transfer the state between months before the end of the month.');
            end
        end
        
    end
    
    methods (Access = private)
        % Maintains the occurrenceIndex and the size of the occurrence list
        % so it's not always expanding.
        function addOccurrence(obj, oc)
            if obj.occurrenceCount == length(obj.privateOccurrences)
                obj.privateOccurrences(obj.occurrenceCount * 2 + 5) = Occurrence;                
            end
            obj.occurrenceCount = obj.occurrenceCount + 1;
            obj.privateOccurrences(obj.occurrenceCount) = oc;
            
            % If the occurrence has a product in it, then update the private most
            % recent product list.
            if ~isempty(oc.products)
                for i = 1:length(oc.products)
                   % add the product to the list.
                   ix = [];
                   if ~isempty(obj.recentProductsList)
                       a = [obj.recentProductsList.quantity];
                       b = [a.unit];
                       ix = find(strcmp({b.speciesName}, oc.products(i).quantity.unit.speciesName), 1, 'first');
                   end
                   if isempty(ix)
                       obj.recentProductsList(end + 1) = oc.products(i);
                   else
                       obj.recentProductsList(ix) = oc.products(i);                       
                   end
                end
            end
        end
        
        % Processes a single event, imEvent.
        function oc = processEvent(obj, imEvent, sim, fakeOut)
            
            if (nargin == 3)
                fakeOut = false;
            end
            
            eventOutputAmounts = Amount.empty(1, 0);
                
            if strcmp(imEvent.status.origin, 'core')
                % 1) call the transition function on the plantedCrop
                %    and get the Amounts produced.
                % 2) create an Occurrence
                % 3) Add products to Occurrence
                % 4) Add costItems to Occurrence
                % 5) Add Occurrence to the plantedCrop          

                % At this stage, they are really rates. Product Rates.
                % Note that eventTransition will update it's own state.
                if (fakeOut)
                    tempState = obj.state;
                end
                [productRates, eventOutputRates] = obj.cropObject.growthModel.eventTransition(imEvent.name, obj, sim);
                if (fakeOut)
                    obj.state = tempState;
                end
                
                productAmounts = Amount.empty(1, 0);
                
                % Multiply rate by amount of the denominator...
                for j = 1:length(productRates)                      
                    r = productRates(j);
                    productAmounts(j) = r * obj.getAmount(r.denominatorUnit);                        
                end
                
                % Multiply rate by amount of the denominator...
                % Do eventOutputs first.
                for j = 1:length(eventOutputRates)                      
                    r = eventOutputRates(j);
                 %   du = r.denominatorUnit
                 %   u = r.unit
                    denominatorAmount = obj.getAmount(r.denominatorUnit);
                    if isempty(denominatorAmount)
                        % Maybe it was a product - check the products for
                        % the amount.
                        for k = 1:length(productAmounts)                      
                            pa = productAmounts(k);
                            if (pa.unit == r.denominatorUnit)
                                denominatorAmount = pa;
                                break;
                            end
                        end
                    end
                    eventOutputAmounts(j) = r * denominatorAmount;                        
                end
                
                

            elseif strcmp(imEvent.status.origin, 'cropNew')
                % Then it's a financial event created in the crop.

                % There are no product rates. Just cost items.
                % So there are no productAmounts.
                productAmounts = Amount.empty(1, 0);
                
            elseif strcmp(imEvent.status.origin, 'regimeNew')
                % Then it's a financial event created in the regime.
                
                % There are no product rates. Just cost items.
                % So there are no productAmounts.
                productAmounts = Amount.empty(1, 0);
            else strcmp(imEvent.status.origin, 'growthModelFinancial')
                % There are no product rates. Just cost items.
                % So there are no productAmounts.
                productAmounts = Amount.empty(1, 0);                
            end
            
            % Create the Occurrence.
            oc = Occurrence(imEvent.name, productAmounts, eventOutputAmounts, obj, sim);
            if ~fakeOut
                obj.addOccurrence(oc); 
            end            
        end
        
    end
    
end























