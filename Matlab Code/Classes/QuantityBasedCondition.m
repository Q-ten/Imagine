% The Quantity Based Condition defines a quantity that can be compared
% against to determine if this condition is true or not.

classdef QuantityBasedCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType 
       figureName
       handlesField
   end
   
   properties (Constant)
      quantityTypeOptions = {'Product', 'Output'};
      nullEventName = 'Monthly Propagation';
      comparatorOptions = {'=', '<', '>', '<=', '>='};
   end
   
   % Define the properties for the TimeIndexedCondition
   properties
       % Should be 'Product', 'Output'
       % Possibly need to consider propagation products (think sequestered
       % carbon)
       quantityType
       
       % Event name for the case of products and event outputs.
       % There will be a special case (empty eventName) in which it is the
       % propagation pseudo-event that is meant. In this case if the
       % quantityType is Product, we're referring to propagation products
       % and if Output, we're referring to regular outputs.
       % For the user, the first 'event name' in the list will be the
       % special Propagation Event.
       eventName
       
       % The product, output or event output rate.
       % Contains the amount, the units and the denominator units.
       % For some quantities, the denominator units will just be Unit.
       % These are for things like NCZ or scale factors. They're not
       % defined in relation to regime quantities.
       %
       % rate number should be nan if not defined.
       rate
       
       % A string that will be one of {'=', '<', '>', '<=', '>='}
       comparator
       
       % Denominator unit to define how the user defines the quantity
       % For some quantities, this will just be Unit because it's not
       % always possible or practical to define a quantity as per X.
       % yield can be per Ha or per Paddock.
       % but scale factor is just a straight percentage. It's not per Ha.
  %     denominatorUnits
   end
    
   methods
      
       function type = get.conditionType(obj)
          type = 'Quantity Based'; 
       end
                  
       function fn = get.figureName(obj)
          fn = 'conditionPanel_QuantityBased.fig'; 
       end
       
       function fn = get.handlesField(obj)
          fn = 'QuantityBasedHandles'; 
       end
       
       function obj = QuantityBasedCondition(shorthand)                     
            obj = obj@ImagineCondition(shorthand);

            obj.quantityType = 'Product';
            obj.eventName = obj.nullEventName;
            obj.rate = Rate.empty(1, 0);
            obj.comparator = '=';
     %       obj.denominatorUnit = Unit.empty(1, 0);

       end
              
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end

       function lh = getLonghand(obj)
 
            switch obj.comparator
                case '<'
                    compString = 'is strictly less than';
                case '<='
                    compString = 'is less than or equal to';
                case '='
                    compString = 'is exactly equal to';
                case '>'
                    compString = 'is strictly greater than';
                case '>='
                    compString = 'is greater than or equal to';
                otherwise
                    compString = 'Error with Comparator string';
            end
                    
            if isnan(obj.rate.number)
               amountNumber = '?'; 
            else
               amountNumber = num2str(obj.rate.number); 
            end
            
            % Add the units to the end. The denominator and numerator units
            % are stored in param 1 and 2 respectively.
%            units = [param2, ' ', param1];
%            lh = [string1{value1}, ' ', compString, ' ', amountNumber, ' ', units];

            % eg: Yield is exactly equal to 5 Tonne(s) per Paddock
            
            % param2 = Tonne(s)
            % param1 = 'per Paddock'
            
            %  Tonne(s) comes from the rate.unit.unitName possibly with a
            %  (s) attached.
            
            % per Paddock comes from readable denominator unit from the
            % obj.denominatorUnit - but only if it's not Unit.
            
            % Possibly, if a Unit is just Unit, then readable denominator
            % unit is just ''.
            units = [obj.rate.unit.unitName, '(s) ', obj.rate.denominatorUnit.readableDenominatorUnit];
            lh = [obj.rate.unit.speciesName, ' ', compString, ' ', amountNumber, ' ', units];
            
       end
       
       % Loads a set of controls into the panel and returns the handles to
       % them as subHandles.
       function loadCondition(obj, panel, varargin)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           % Want to get in the events, and all the possible quantities and
           % denominator units. We'll save it in the handlesField and then 
           % the logic in the panel can do the rest. We just set it up.
           if nargin == 7
               productRates = varargin{1};
               outputRates = varargin{2};
               eventRates = varargin{3};    % eventRates need to be in the order they're listed in the crop.
               regimeUnits = varargin{4};
               thisEventName = varargin{5};
           else
              error(['5 additional arguments are required (7 total with the condition object and the standard panel). They are: ' ...
                    'The product rates, the output rates, an array of eventRates for each event for this crop, the regime units, and the name of the event we''re making this condition for.']);
           end
           
           if ~isa(eventRates, 'EventRate')
                error('The 3rd argument supplied to loadCondition was not an array of EventRates.');
           end
           
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           % Set up the comaparator
           set(newControls.popupmenuComparator, 'String', obj.comparatorOptions);
           ix = find(strcmp(obj.comparator, obj.comparatorOptions), 1, 'first');
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuComparator, 'Value', ix);
           
           % We ask for the current event name so we can make sure we're
           % not triggering a quantity based on our own event.
           % We remove it from the list.
           % Add the pseudo propagation event rate to the front of the list of eventRates. 
           % To avoid Goedellian problems where a trigger may depend on the
           % quantities generated in an event that's looked at later - and
           % that event may depend on the quantities of the earlier event
           % we'll establish the rule that only quantities from events
           % listed earlier in the list can be used to trigger events later
           % in the list.
           % We may need to come back to that one...        
           thisEventIndex = find(strcmp({eventRates.eventName}, thisEventName), 1, 'first');
           if ~isempty(thisEventIndex)
              eventRates = eventRates(1:thisEventIndex - 1);
           end
           propagationEventRate = EventRate.empty(1, 0);
           if ~isempty(productRates) || ~isempty(outputRates)
               % Then we include the propagation event. Otherwise, it won't
               % make sense to include it.
               propagationEventRate = EventRate(obj.nullEventName, productRates, outputRates);
           end
          
           eventRates = [propagationEventRate, eventRates];
           
           handles.(obj.handlesField).data.eventRates = eventRates;
           handles.(obj.handlesField).data.regimeUnits = regimeUnits;
           handles.(obj.handlesField).data.amount = [];
           if ~isempty(obj.rate)
               handles.(obj.handlesField).data.amount = obj.rate.number;
           end
           guidata(panel, handles);
           
           % Now use the panel logic to populate the quantityType choices.
           % Then fill in the quantityType
           figureMFile = [obj.figureName(1:end-4)];
           feval(figureMFile, 'populateQuantityTypeOptions', handles);
           ix = find(strcmp(obj.quantityTypeOptions, obj.quantityType), 1, 'first');
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuQuantityTypeOptions, 'Value', ix);
           
           % Now use the panel logic to populate the eventName choices.
           % Then fill in the eventName
           feval(figureMFile, 'populateEventNames', handles);
           % populateEventNames(handles)
           eventNames = get(newControls.popupmenuEventChoice, 'String');
           ix = find(strcmp(eventNames, obj.eventName), 1, 'first');
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuEventChoice, 'Value', ix);
           
           % Now use the panel logic to populate the quantity choices.
           % Then fill in the quantity
           feval(figureMFile, 'populateQuantityChoices', handles);
           %populateQuantityChoices(handles)
           quantityNames = get(newControls.popupmenuQuantityChoice, 'String');
           ix = 1;
           if isempty(quantityNames)
              error('We hope tnot to get here. The idea is that there will always be a quantity in the list of quantities.'); 
           end
           if ~isempty(obj.rate)              
               ix = find(strcmp(quantityNames, obj.rate.unit.speciesName), 1, 'first');
           end
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuQuantityChoice, 'Value', ix);
         
           % Now use the panel logic to populate the denominator choices.
           % Then fill in the denomnatorUnit
           feval(figureMFile, 'populateUnitOptions', handles);
           %populateUnitOptions(handles)
           if ~isempty(obj.rate)
               if (obj.rate.denominatorUnit ~= Unit)
                   unitStrings = get(newControls.popupmenuDenominatorUnits, 'String');
                   ix = find(strcmp(unitStrings, obj.rate.denominatorUnit.readableDenominatorUnit), 1, 'first');
                   if isempty(ix)
                       ix = 1;
                   end
                   set(newControls.popupmenuDenominatorUnits, 'Value', ix);
               end
           end
           
           % At this point, we have a quantity chosen. If the rate is
           % empty, we can populate it with the details of the defaults 
           % that have been loaded.
           if isempty(obj.rate)
               eventNames = get(newControls.popupmenuEventChoice, 'String');
               defaultEventName = eventNames{get(newControls.popupmenuEventChoice, 'Value')};
               ix = find(strcmp(defaultEventName, {eventRates.eventName}), 1, 'first');
               
               quantityTypeIndex = get(newControls.popupmenuQuantityTypeOptions, 'Value');
               quantityTypeChoice = obj.quantityTypeOptions{quantityTypeIndex};
               rateField = [lower(quantityTypeChoice), 'Rates'];

               quantityRates = eventRates(ix).(rateField);
               quantityUnits = [quantityRates.unit];
               quantityNames = get(newControls.popupmenuQuantityChoice, 'String');
               defaultQuantityName = quantityNames{get(newControls.popupmenuQuantityChoice, 'Value')};
               ix = find(strcmp(defaultQuantityName, {quantityUnits.speciesName}), 1, 'first');
               defaultQuantityRate = quantityRates(ix);
               obj.rate = Rate(0, defaultQuantityRate.unit, defaultQuantityRate.denominatorUnit);
           end
               
           % If the rate is empty (because its a new condition) we should
           % be able to populate it now.
           % Or, perhaps we should populate the rate with (0, unit, unit)
           % A Unit species name is a dummy unit. Could use that to tell if
           % its empty.
           
           % Now fill in the quantity.
           set(newControls.editAmount, 'String', num2str(obj.rate.number));
           
       end
       
       % Uses the controls in subHandles to extract the parameters that
       % define this condition.
       function saveCondition(obj, panel)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           % If there is no data field in newControls, we must be in a
           % 'saveCondition' call that's been called before load condition.
           % We need to wait until loadCondition is called, then
           % saveCondiiton is called again. (Messy, but this works).
           if ~isfield(newControls, 'data')
               return
           end
           
           obj.quantityType = obj.quantityTypeOptions{get(newControls.popupmenuQuantityTypeOptions, 'Value')};
           eventNames = get(newControls.popupmenuEventChoice, 'String');
           if isempty(eventNames)
            obj.eventName = '';            
           else
            obj.eventName = eventNames{get(newControls.popupmenuEventChoice, 'Value')};
           end
           obj.comparator = obj.comparatorOptions{get(newControls.popupmenuComparator, 'Value')};
           
           rateNumber = str2double(get(newControls.editAmount, 'String'));
                     
            eventRates = handles.(obj.handlesField).data.eventRates;
            ix = find(strcmp({eventRates.eventName}, obj.eventName), 1, 'first');

            rateField = [lower(obj.quantityType), 'Rates'];
            rates = eventRates(ix).(rateField);
            rateIndex = get(newControls.popupmenuQuantityChoice, 'Value');
            rate = rates(rateIndex);

            rateUnit = rate.unit;

            regimeUnits = handles.(obj.handlesField).data.regimeUnits;
            readableDenominatorUnits = get(newControls.popupmenuDenominatorUnits, 'String');
            if isempty(readableDenominatorUnits)
                rateDenominatorUnit = Unit;
            else
                ix = get(newControls.popupmenuDenominatorUnits, 'Value');
                rateDenominatorUnit = regimeUnits(ix);
            end
            
            obj.rate = Rate(rateNumber, rateUnit, rateDenominatorUnit);            
           
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
           % Initialise all trigger checks with nan to indicate that it
           % can't be found at this point.
           TF = nan;
           
           % The trigger requires the occurrences for the current month.
           % If an occurrence for an event is not found in the list, it's
           % quantity is deemed to be 0. 0 per anything is still zero, so
           % it can be compared directly to the rate number.
                      
           % Expect in the current monthIndex and year.
           if nargin == 4
               outputRates = varargin{1};
               monthlyOccurrences = varargin{2};
               regimeAmounts = varargin{3};              
           else
               error('QuantityBasedCondition: isTriggered expects 3 arguments other than itself - the output rates, the occurrences from the current month and regimeAmounts for the current month.');
           end
           
           % Get the numbers to compare - want totals.
           
           % Get the total amount that's defined in the condition.
           if (obj.rate.denominatorUnit == Unit)
               conditionTotalAmount = rate.number;
           else
               denUnit = obj.rate.denominatorUnit;
               ix = find(denUnit == [regimeAmounts.unit], 1, 'first');           
               if isempty(ix)
                   error('Could not find an amount from the Regime to match the defined denominator unit.');
               end
               conditionTotalAmount = obj.rate.number * regimeAmounts(ix).number;
           end
           
           % Get the total amount from the product/output
           % The propagation products are actually created as occurrences,
           % with the name of hte event being our null event name.
           % So the method for getting the amount will be identical.
           isPropagationEvent = strcmp(obj.eventName, obj.nullEventName);
           occurrenceProducts = Product.empty(1, 0);
           occurrenceOutputs = Rate.empty(1, 0);
           if ~isPropagationEvent || strcmp(obj.quantityType, 'Product')
               for i = 1:length(monthlyOccurrences)
                   oc = monthlyOccurrences(i);
                   if strcmp(oc.eventName, obj.eventName)
                       occurrenceProducts = oc.products;
                       occurrenceOutputs = oc.eventOutputs;
                       break;
                   end
               end
           end
           
           switch obj.quantityType
               case 'Product'
                    if isempty(occurrenceProducts)
                        ix = [];
                    else
                        ix = find(obj.rate.unit == [occurrenceProducts.quantity.unit], 1, 'first');
                    end
                    if isempty(ix)
                        % Then there was no product in the occurrence list.
                        % Then we assume the quantity is 0.
                        simTotalAmount = 0;
                    else
                        simTotalAmount = occurrenceProducts(ix).quantity.number;
                    end
               case 'Output'
                    if (isPropagationEvent)
                        % Look in outputs.
                        ix = find(obj.rate.unit == [outputRates.unit], 1, 'first');
                        if isempty(ix)
                             error('Could not find a matching outputRate from propagtion - should have found it.');
                        end
                        simTotalRate = outputRates(ix);
                    else
                        % Look for occurrences.
                        ix = find(obj.rate.unit == [occurrenceOutputs.unit], 1, 'first');
                        if isempty(ix)
                            simTotalRate = Rate(0, Unit, Unit);
                        else                            
                            simTotalRate = occurrenceOutputs(ix);
                        end
                    end
                    % Now we've got the rate, get the amount by multiplying
                    % by the appropriate regimeUnit if there's a
                    % denominator unit.
                    if simTotalRate.denominatorUnit == Unit
                        simTotalAmount = simTotalRate.number;
                    else
                        ix = find(obj.rate.denominatorUnit == [regimeAmounts.unit], 1, 'first');
                        if isempty(ix)
                            error('Unable to find a matching regime amount for the quantity''s denominator unit.');
                        end
                        simTotalAmount = simTotalRate.number * regimeAmounts(ix).number;
                    end
               otherwise
                   error('quantityType not set correctly in QuantityBasedCondition.')
           end
           
            switch obj.comparator
                case '='
                    TF = [simTotalAmount == conditionTotalAmount];

                case '<='
                    TF = [simTotalAmount <= conditionTotalAmount];

                case '>='
                    TF = [simTotalAmount >= conditionTotalAmount];                        

                 case '<'
                    TF = [simTotalAmount < conditionTotalAmount];     

                case '>'
                    TF = [simTotalAmount > conditionTotalAmount];
            end
           
       end
       
   end
    
   methods
                    
       function setupFromOldStructure(obj, s)
  
        % The quantities in the past were always outputs.
        obj.quantityType = 'Output';
        obj.eventName = obj.nullEventName;  % We're supporting only the outputs - not event outputs.
        obj.comparator = s.stringComp{s.valueComp};
        obj.rate = Rate(str2num(s.string2), Unit, Unit('', 'Hectare', 'Area')); % This is just a good guess - nothing more.
        condUpdater = ConditionUpdater.getInstance;
        condUpdater. addQuantityCondition(obj, s);
        
        % Note that there is some subtlty in setting c1.string1 to a
        % single output value. The trigger panel has previously expected to be 
        % able to put the string straight into the control and set the
        % value.
        % I think it's better for forward compatability for the
        % triggerPanel to work out what the list of choices should be, then
        % select the one we've defined here. Therefore it should be fine
        % when setting the condition to list a single choice and have the
        % value = 1 (first choice).
        
%         c1.string1 = {'Above-ground Biomass'};
%         c1.value1 = 1;
%         c1.stringComp = {'=', '<', '>', '<=', '>='};
%         c1.valueComp = 5;
%         c1.string2 = num2str(handles.biomassThreshold);
%         c1.value2 = 1;       
%         c1.parameters1String = BTU.speciesName;
%         c1.parameters2String = BTU.unitName;
       end
       
       function valid = isValid(cond, varargin)
            valid = isValid@ImagineCondition(cond);
            valid = valid && isa(cond, 'QuantityBasedCondition');
            valid = valid && isa(cond.rate, 'Rate');
            valid = valid && ischar(cond.eventName);
            valid = valid && ischar(cond.comparator);
            valid = valid && ischar(cond.quantityType);
            valid = valid && ~isempty(cond.rate);
            valid = valid && ~isempty(cond.eventName);
            if (valid)
                valid = valid && any(strcmp(cond.comparator, cond.comparatorOptions));
                valid = valid && any(strcmp(cond.quantityType, cond.quantityTypeOptions));
            end
            % Accepts in an optional list of eventNames to check against.
            if nargin == 2
               eventNames = varargin{1}; 
               valid = valid && any(strcmp(cond.eventName, eventNames));
            end
       end % end isValid
        
   end

end