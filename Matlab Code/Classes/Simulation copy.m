classdef Simulation < handle
    %Simulation Represents a single Imagine Simulation.
    %   A Simulation contains the data generated. It will maintain the
    %   probablistic climate data, the price data, and other data.
    %   It will maintain the results of the simulation as it progresses.
    %   Results include various regime amounts, harvested amounts, prices, costs, profit, etc. 
    %
    %   Within the Simulation, we'll want to record low-level data like
    %   primary crops, secondary crops, costs, income, Amounts, regimes,
    %   etc, as well as higher level data like total income per month,
    %   total cost, total biomass (primary, secondary) etc. These might be
    %   dependent properties, or we may have a function that calculates the
    %   data from the lower level data. I think this might be a really good
    %   idea. Also, the lower level data need not be stored in full each
    %   month, but rather when there is a change. So the state of each crop
    %   might be recorded, with other things like costs recorded only when
    %   they change. So long as there is enough data to recreate the final
    %   data, saving less lower level data might well be a good thing.
    %
    %   What data might we want? 
    %   Regime names per month, crop names per month, crop state per month.
    %   Costs each month for each event (i.e. event occurance and cost)
    %   Products and income from harvest events (as well as costs)
    %   Amounts of stuff each month. I.e. Ha per zone, trees, km of Belts,
    %   etc.
    %
    %   NOTE - NO RATES STORED. 
    %   While products and crop specific amounts may be provided
    %   directly as Rates (Amounts with a denominator Unit) they are
    %   converted into Amounts (per Paddock amounts) by multiplying by the
    %   appropriate entry in regimeAmountData before they are stored in
    %   here. So cropAmountData and product Amounts and income will all be
    %   stored as per paddock amounts.
    
    
    properties
        
        % The current monthIndex of the sim.
        monthIndex
        % The month day is 1 at the beginning of the month and 30 at the
        % end of the month. It's done this way incase we extend it to a
        % daily sim later.
        monthDay
        
        % A list of installed regimes. This will contain the regimes that
        % have been installed in the history of the sim
        installedRegimes
        
        primaryRegimeIndex
        secondaryRegimeIndex
        
        % productPriceTable - An array of Rates.
        % A struct with fields corresponding to crop names.
        % Note that the fields have spaces replaced with underscores.
        % Each field is [p x m] array of Rates. The jth column holds the prices for
        % year j. The denominator units of the Rates gives the unit of the
        % product.
        %
        % Entries are valid only up to the current year.
        % For example, if the Biomass product is the first entry of the
        % 'Oil Mallee' crop you would index the price as follows:
        % productPriceTable.('Oil_Mallee')(1, year)
        % Note that the space has been replaced with an underscore.
        productPriceTable
        
        % costPriceTable - An array of Rates.
        % A struct with fields corresponding to crop names.
        % Note that the fields have spaces replaced with underscores.
        % Each field is broken down into further fields - one for each
        % event name. The field at this level contains a list of Rates,
        % with one Rate for each year that the sim will run. The entries
        % are only valid up to the current year however. Entries for future
        % years are '1 Unit/Unit' rates.
        % For example, to index the Planting event of a Wheat crop use
        % costPriceTable.('Wheat').('Planting')(year)
        costPriceTable
        
        % These are just like the productPriceTablea and costPriceTable,
        % except they hold NormDist arrays that represent the disrtibution
        % that the values in those tables were sampled from.
        productPriceModelTable
        costPriceModelTable
        
        
        % An array of the rainfall received each month so far.
        % It's a 12 x m array where m is the number of years the sim runs
        % for. Months not passed yet are NaN.
        monthlyRainfall
        
    end
    
    methods
       
        function obj = Simulation()
           obj.monthIndex = 0;
           obj.monthDay = 0;
           obj.installedRegimes = InstalledRegime.empty(1, 0);
           obj.primaryRegimeIndex = 0;
           obj.secondaryRegimeIndex = 0;

           % Set the rainfall chart to NaNs to start with.
           imOb = ImagineObject.getInstance;
           obj.monthlyRainfall = nan(12, imOb.simulationLength);
           obj.privateTimestamp = datestr(now, 'mm-dd-yyyy HH:MM:SS');
        end
        
    end
    
    properties (Dependent)
       
        % These both come from the monthIndex
        month
        year
       
        % We'll want to tally up the costs, income and profit to date.
        % But these should be calculated from the properties rather than
        % saved.
        % It's unlikely we'll need to calculate these often, but we could
        % maintain a persistent variable in the calculation method maybe.
       
        costsToDate
        incomeToDate
        profitToDate
    
        currentPrimaryInstalledRegime
        currentSecondaryInstalledRegime
        currentPrimaryPlantedCrop
        currentSecondaryPlantedCrop
        
        timestamp
        
    end
    
    properties (Access = private)
       privateTimestamp 
    end
    
    methods
       
        function ts = get.timestamp(obj)
           ts = obj.privateTimestamp; 
        end
        
        % These methods are just shortcuts for getting the current regime
        % or crop.
       function inReg = get.currentPrimaryInstalledRegime(obj)
            if ~obj.primaryRegimeIndex == 0
                inReg = obj.installedRegimes(obj.primaryRegimeIndex); 
            else
                inReg = InstalledRegime.empty(1, 0);
            end
        end
        
        function inReg = get.currentSecondaryInstalledRegime(obj)
            if ~obj.secondaryRegimeIndex == 0
                inReg = obj.installedRegimes(obj.secondaryRegimeIndex); 
            else
                inReg = InstalledRegime.empty(1, 0);
            end
        end
        
        function plCrop = get.currentPrimaryPlantedCrop(obj)
            if ~obj.primaryRegimeIndex == 0
                plCrop = obj.currentPrimaryInstalledRegime.currentPlantedCrop;
            else
                plCrop = PlantedCrop.empty(1, 0);
            end
        end
        
        function plCrop = get.currentSecondaryPlantedCrop(obj)
            if ~obj.secondaryRegimeIndex == 0
                plCrop = obj.currentSecondaryInstalledRegime.currentPlantedCrop;
            else
                plCrop = PlantedCrop.empty(1, 0);
            end
        end

        function inReg = installedRegime(obj, zone)           
            if zone == 1 
               inReg = obj.currentPrimaryInstalledRegime;                
            elseif zone == 2
               inReg = obj.currentSecondaryInstalledRegime;
            else
                inReg = [];
            end            
        end
        
        function inReg = plantedCrop(obj, zone)           
            if zone == 1 
               inReg = obj.currentPrimaryPlantedCrop;                
            elseif zone == 2
               inReg = obj.currentSecondaryPlantedCrop;
            else
                inReg = [];
            end            
        end       
                
        % Get the year from the monthIndex
        function y = get.year(sim)
           y = floor((sim.monthIndex - 1) / 12) + 1;
        end
        
        % get the month from the monthIndex
        function m = get.month(sim)
           m = mod(sim.monthIndex - 1, 12) + 1;
        end
        
    end
    
    
    methods
       
        % Calculates the monthly costs of the installedRegimes in this Simulation,
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
            
            for i = 1:length(obj.installedRegimes)
                cs = cs + obj.installedRegimes(i).costs(firstMonth, lastMonth, asList);
            end
            
        end
        
        % Calculates the monthly income for this sim from each event for
        % each crop for each regime.
        % The income will cover the date range supplied by firstMonth and lastMonth
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
            
            for i = 1:length(obj.installedRegimes)
                ins = ins + obj.installedRegimes(i).income(firstMonth, lastMonth, asList);
            end
        
        end
        
        % Calculates the monthly profits of the installedRegimes in this Simulation,
        % over the date range supplied by firstMonth and lastMonth
        % If asList is true, then ps is an array containing the monthly profits starting
        % from firstMonth. Otherwise, the total over the period is
        % returned.
        function ps = profit(obj, firstMonth, lastMonth, asList)
            ps = obj.income(firstMonth, lastMonth, asList) - obj.costs(firstMonth, lastMonth, asList);
        end
        
        % Costs, Income, Profit to date are just shorthand for a reference
        % to the more general functions.
        function costs = get.costsToDate(obj)
            costs = obj.costs(1, obj.monthIndex);
        end
        
        function income = get.incomeToDate(obj)
            income = obj.income(1, obj.monthIndex);
        end
       
        function profits = get.profitToDate(obj)
            profits = obj.profit(1, obj.monthIndex);
        end
       
        % Gets the price for the crop with name cropName and product with
        % unit productUnit in year if supplied, or currentYear if not
        % supplied.
        function p = getProductPrice(obj, cropName, productUnit, year)
           
            if nargin == 3
               year = obj.year;
            end
            
            cropName = underscore(cropName);
           
            priceColumn = obj.productPriceTable.(cropName)(:, year);
            ix = find([priceColumn.denominatorUnit] == productUnit, 1, 'first');
            
            if isempty(ix)
                p = Rate.empty(1, 0);
            else
                p = priceColumn(ix);
            end
            
        end
        
        % Gets the price for the crop with name cropName and product with
        % unit productUnit in year if supplied, or currentYear if not
        % supplied.
        function p = getCostPrice(obj, cropName, eventName, year)
                      
            if nargin == 3
               year = obj.year;
            end
            
            cropName = underscore(cropName);
            eventName = underscore(eventName);
        
            try 
                p = obj.costPriceTable.(cropName).(eventName)(year);
                
            catch e
                disp(['Call to Simulation.getCostPrice failed. ', ...
                      'costPrices.', cropName, '.', eventName, '(', year, ') throws an exception. Returned an empty Rate instead.']);
                throw(e)
            end
            
        end
        
    end
    
    % Simulation methods
    methods 
        
        % Installs a regime in zone if it can.
        function installRegimeIfPossible(obj, zone)
            
            regMgr = RegimeManager.getInstance;
            
            % Check that there is not already a regime installed.
            if strcmp(zone, 'primary')
                if ~isempty(obj.currentPrimaryInstalledRegime)
                    return
                else
                    inReg = regMgr.requestRegimeInstallation(zone, obj);
                    if ~isempty(inReg)
                        obj.primaryRegimeIndex = length(obj.installedRegimes) + 1;
                        obj.installedRegimes(obj.primaryRegimeIndex) = inReg;                    
                    end
                end
            elseif strcmp(zone, 'secondary')
                if ~isempty(obj.currentSecondaryInstalledRegime)
                    return
                else
                    inReg = regMgr.requestRegimeInstallation(zone, obj);
                    if ~isempty(inReg)
                        obj.secondaryRegimeIndex = length(obj.installedRegimes) + 1;
                        obj.installedRegimes(obj.secondaryRegimeIndex) = inReg;                    
                    end
                end
            end            
            
        end
    
        
        function TF = isTriggered(sim, trig, plantedCrop)
            
            condTruths = false(1, length(trig.conditions));
                        
            
            if nargin == 2
                plantedCrop = PlantedCrop.empty(1, 0);
            end
            
            % For each condition in the trigger
            for j = 1:length(trig.conditions)
                
                cond = trig.conditions{j};
                
                switch cond.conditionType
           
                    case 'Time Index Based'
%                         monthIndex = varargin{1};
%                         yearIndex = varargin{2};
                         condTruths(j) = cond.isTriggered(sim.monthIndex, sim.year);
                    case 'Month Based'
                        % Pass the month index.
                        condTruths(j) = cond.isTriggered(sim.monthIndex);
                    case 'Event Happened Previously'
%                          simMonthIndex = varargin{1};
%                          occurrences = varargin{2};
                        if isempty(plantedCrop.occurrences)
                            condTruths(j) = false;
                        else
                            TF = cond.isTriggered(sim.monthIndex, plantedCrop.occurrences);
                            if isnan(TF)
                                a = 12;
                            end
                            condTruths(j) = TF;
                        end
                    case 'Quantity Based'        
%                            outputRates = varargin{1};
%                            monthlyOccurrences = varargin{2};
%                            regimeAmounts = varargin{3};
                        if (sim.monthDay == 1)
                            outputs = plantedCrop.getOutputsMonthStart([], plantedCrop.monthIndex - plantedCrop.plantedMonth + 1);
                        else
                            outputs = plantedCrop.getOutputsMonthEnd([], plantedCrop.monthIndex - plantedCrop.plantedMonth + 1);
                        end
                        condTruths(j) = cond.isTriggered(outputs, plantedCrop.occurrences, plantedCrop.parentRegime.outputs(:, sim.monthIndex));  
                    case 'And / Or / Not'
%                         conditionIndex = varargin{1};
%                         conditionTruths = varargin{2};
                            TF = cond.isTriggered(j, condTruths); 
                            if isnan(TF)
                                a = 12;
                            end
                        condTruths(j) = cond.isTriggered(j, condTruths);    
                    case 'And / Or'
                        condTruths(j) = cond.isTriggered(j, condTruths);
                    case 'Never'
                        condTruths(j) = cond.isTriggered();
                    otherwise
                        error('Trying to create a condition with unknown type.');

                end
                
                
                
                
%                 % Set the condition
%                 cond = trig.conditions(j);
%             
%                 % Pull out parameters.
%                 type = cond.conditionType;
%                 
%                 if strcmp(type, 'Never')
%                     continue
%                 end
%                 
%                 try
%                     s1 = cond.string1{cond.value1};
%                 catch e %#ok<NASGU>
%                     s1 = '';
%                 end
%                 try
%                     comp = cond.stringComp{cond.valueComp};
%                 catch e %#ok<NASGU>
%                     comp = '';
%                 end                
%                 try
%                     s2 = cond.string2{cond.value2};
%                 catch e %#ok<NASGU>
%                     s2 = '';
%                 end              
%                 params1 = cond.parameters1String;
%                 params2 = cond.parameters2String;
%                 
%                 year = sim.year;
%                 month = sim.month;
%                 
%                 switch type
% 
%                         case 'Time Index Based'
% 
%                             % Figure out the number to compare.
%                             if strcmp(s1, 'Month')
%                                 indexValue = sim.monthIndex;
%                             elseif strcmp(s1, 'Year')
%                                 indexValue = year;
%                             end               
% 
%                             % Grab the numbers from the string
%                             values = str2num(cond.string2); %#ok<ST2NM>
% 
%                             % Use comparator
%                             switch comp
% 
%                                 case '='
%                                     condTruths(j) = any(values == indexValue);                    
%                                 case '<='
%                                     condTruths(j) = (indexValue  <= values(1));
%                                 case '>='
%                                     condTruths(j) = (indexValue  >= values(1));
%                                 case '<'
%                                     condTruths(j) = (indexValue  < values(1));
%                                 case '>'
%                                     condTruths(j) = (indexValue  > values(1));
%                             end
%                             
%                     case 'Month Based'
%                         
%                         % Value2 should be equal to month.
%                      %   condTruths = condTruths
%                      %   cond = cond
%                         condTruths(j) = (cond.value2 == month);
%                                  
%                     case 'AND / OR / NOT' 
%                 
%                             % get list of conditions to compare.
%                             conditionsToCombine = str2num(cond.string2);
% 
%                             % Run through the list of conditions and check each one.
%                             if strcmp(s1, 'AND')
%                                 v = true;
%                                 for ix = 1:length(conditionsToCombine)
%                                     v = v && condTruths(conditionsToCombine(ix));
%                                 end
%                                 condTruths(j) = v;
%                             elseif strcmp(s1, 'OR')
%                                 v = false;
%                                 for ix = 1:length(conditionsToCombine)
%                                     v = v || condTruths(conditionsToCombine(ix));
%                                 end
%                                 condTruths(j) = v;       
%                             elseif strcmp(s1, 'NOT')
%                                 % if multiple, take the first
%                                 condTruths(j) = ~condTruths(conditionsToCombine(1));
%                             end   
%                         
%                         
%                     case 'Event Happened Previously'
%                 
%                         % Check which event it was that was meant to have happened,
%                         % then get the appropriate range of time from the records
%                         % and check for the event's existance. It must be
%                         % in the
%                         % same regime, crop and zone.
%                         condTruths(j) = false;
% 
%                         allegedEventName = s1;
%                         currentMonthIndex = sim.monthIndex;
%                         monthEntry = str2num(cond.string2);
% 
%                          switch comp
% 
%                             case '='
%                                 % Can have multiple months. The others can only
%                                 % have one and be valid.
%                                 monthIndiciesToCheck = currentMonthIndex - monthEntry;
% 
%                             case '<='
%                                 % Ok
%                                 monthIndiciesToCheck = [1: currentMonthIndex - monthEntry];
% 
%                             case '>='
%                                 % OK.
%                                 monthIndiciesToCheck = [currentMonthIndex - monthEntry:currentMonthIndex];                        
% 
%                              case '<'
%                                 % OK. If it happened less than one month ago, it could
%                                 % only have happened in this month. -1 + 1 cancel
%                                 % out.
%                                 monthIndiciesToCheck = [currentMonthIndex - monthEntry + 1:currentMonthIndex];     
% 
%                             case '>'
%                                  % OK. If it happened more than one month ago, (2
%                                  % months ago or earlier) we'd have current - 1 -1.
%                                  monthIndiciesToCheck = [1: currentMonthIndex - monthEntry - 1];
%                                  
%                              otherwise
%                                  error('Error in Simulation.isTriggered, Event Happened Previously. Unrecognised comparator.');
% 
%                          end
% 
%                          % Check all previous events for matching the required
%                          % criteria.
%                          for ii = 1:length(plantedCrop.occurrences)
%                              oc = plantedCrop.occurrences(ii);
%                              ocMonthIndex = oc.monthIndex;
%                              if any(ocMonthIndex == monthIndiciesToCheck)
%                                  if strcmp(allegedEventName, oc.eventName)
%                                      condTruths(j) = 1;
%                                   break;
%                                  end
%                              end                
%                          end
%                          
%                          
%                     case 'Quantity Based'
%                     
%                         condTruths(j) = false;
% 
%                         % We need to calculate the quantity and then check
%                         % whether it meets the comparison.
%                         quantityName = cond.string1{cond.value1};
% 
%                           % Need to identify the output or product.
%                           % Then get the output or product
%                           % Then convert the Rate in the condition to an
%                           % Amount so we can compare the number to the
%                           % condition number.
%                           
%                           productUnits = plantedCrop.cropObject.growthModel.productUnits;
%                           productNames = {productUnits.speciesName};
% 
%                           outputRates = plantedCrop.cropObject.growthModel.growthModelOutputRates;
%                           outputNames = {};
%                           if (~isempty(outputRates))                          
%                               outputUnits = [outputRates.unit];
%                               outputNames = {outputUnits.speciesName};    
%                           end
%                           
%                           amount = Amount.empty(1, 0);
%                           ix = find(strcmp(productNames, quantityName), 1, 'first');                          
%                           if (~isempty(ix))
%                               % then our quantity is a product.
%                               occurrences = plantedCrop.occurrences;
%                               assignin('base', 'ocs', occurrences);
%                               if (sim.monthDay == 1)
%                                   ix = find(and([occurrences.monthDay] == 1, [occurrences.monthIndex] == sim.monthIndex));
%                               else
%                                   ix = find(and([occurrences.monthDay] == 30, [occurrences.monthIndex] == sim.monthIndex));
%                               end
%                               
%                               
%                               occurrences = occurrences(ix);
%                               
%                               if (~isempty(occurrences))
%                                   % Go through the occurrences until we
%                                   % find an occurrence that has a product
%                                   % that matches the one we're after.
%                                   located = false;
%                                   for i = 1:length(occurrences)
%                                      oc = occurrences(i);                                     
%                                      for k = 1:length(oc.products)
%                                          prod = oc.products(k);
%                                          if strcmp(prod.quantity.unit.speciesName, quantityName)
%                                              % Then we've found it!  
%                                              amount = prod.quantity;
%                                              located = true;
%                                              break;
%                                          end
%                                      end
%                                      if located
%                                          break;
%                                      end
%                                   end
%                               end
%                               
%                           end
%                           
%                           ix = find(strcmp(outputNames, quantityName), 1, 'first');
%                           if (~isempty(ix))
%                               % then our quantity is an output.
%                               if (sim.monthDay == 1)
%                                  outputColumn = plantedCrop.getOutputsMonthStart([], sim.monthIndex - plantedCrop.plantedMonth + 1); 
%                               else
%                                  outputColumn = plantedCrop.getOutputsMonthEnd([], sim.monthIndex - plantedCrop.plantedMonth + 1); 
%                               end
%                               
%                               for i = 1:length(outputColumn)
%                                  outputRate = outputColumn(i); 
%                                  if(strcmp(outputRate.unit.speciesName, quantityName))
%                                      amount = outputRate * plantedCrop.getAmount(outputRate.denominatorUnit);
%                                  end
%                               end
%                           end
%                           
%                           % now we have found the amount if it exists.
%                           if (~isempty(amount))
%                               % Get the regime amount used in the
%                               % condition. We'll divide the total amount by
%                               % the number in this amount. This is the one
%                               % under param1.
%                               
%                               % If we can match param1 to one of the regime
%                               % output units, then we convert the amount.
%                               % Otherwise we leave it as is.
%                               regimeUnits = plantedCrop.cropObject.category.regimeOutputUnits;
%                               regimeUnitReadableNames = {regimeUnits.readableDenominatorUnit};
%                               ix = find(strcmp(regimeUnitReadableNames, params1), 1, 'first');
%                               if (~isempty(ix))
%                                   % then we modify amount.
%                                   regimeAmount = plantedCrop.getAmount(regimeUnits(ix));
%                                   amount.number = amount.number / regimeAmount.number;
%                               end
%                               
%                               quantity = amount.number;
%                               if isempty(quantity)
%                                   quantity = 0;
%                               end
%                               
%                               comparedQuantity = str2double(cond.string2);
% 
%                              switch cond.stringComp{cond.valueComp}
% 
%                                 case '='
%                                     condTruths(j) = [quantity == comparedQuantity];
% 
%                                 case '<='
%                                     condTruths(j) = [quantity <= comparedQuantity];
% 
%                                 case '>='
%                                     condTruths(j) = [quantity >= comparedQuantity];                        
% 
%                                  case '<'
%                                     condTruths(j) = [quantity < comparedQuantity];     
% 
%                                 case '>'
%                                     condTruths(j) = [quantity > comparedQuantity];
%                              end
% 
%                           end
%                           
%                     otherwise
%                         error('We haven''t implemented the trigger logic yet.');
%                             
%                 end % end switch
                           
            end % end for 
               
            TF = condTruths(end);
            
        end % end testTrigger(sim, trig)
        
    end
    
    
    
    
    
    
    % This is the end of the newly defined Simulation.
    
    
    
    
    
%     
%     
%     
%     
%     
%     
%     properties
%             
%         
%         
%         
%         
%         
%         
%         
%         
%         % It is appropriate to store information about the simulation in
%         % the Simulation. Therefore, it will keep track of it's installed
%         % regimes, primary and secondary and the month index.
%         primaryInstalledRegime
%         secondaryInstalledRegime
%          
%         % Store 1x600 arrays for total income, cost and biomass.
%         monthlyIncome
%         monthlyCost
%         monthlyBiomass
%         
%         % Store the proabablistic generated data including the climate data, 
%         % the cost data and the price data.
%         climateData
%         productPriceData
%         costPriceData
%         
%         % Crop States
%         % cropStateData{zone, startOrFinish, month} = cropState
%         % Will be the state of the crop defined in zone, at the
%         % startOrFinish of month. So the state is kept for each month, in
%         % each zone at both the beginning and end of the month.
%         cropStateData
% 
%         
%         % All the following lists should be ordered by (month, zone)
%         
%         % Store regime names when they change.
%         % Has month, zone, name
%         regimeNameData
%         
%         % Store crop names when they change.
%         % Has month, zone, name
%         cropNameData
%         
%         % Regime defined amounts
%         % Store month, zone, Amount
%         % Eg Ha, lasts as long as the regime does unless changed.
%         regimeAmountData
%         
%         % Crop specific amounts
%         % Store month, zone, Amount
%         % Eg, Biomass. Lasts as long as the crop does, unless changed.
%         % Will relate to the crop most recently planted in zone.
%         cropAmountData
%                 
%         % Events
%         % month, zone, eventName
%         % Will be an event for the most recently planted crop in zone.
%         eventData
%         
%         % Costs
%         % month, zone, eventName, cost
%         % Will be a cost for an event for the most recently planted crop in
%         % zone.
%         costData
%         
%         % Products
%         % month, zone, eventName, productName, Amount
%         % Will be a product for an event for crop in zone in month with
%         % Amount of product harvested.
%         productData
%         
%         % Income
%         % month, zone, productName, income
%         % Will be some income from selling the productName from zone in
%         % month.
%         incomeData
%                 
%     end
%     
% 
%     
%     methods
%         
%         function sim = Simulation
%             
%             % Set up the running parameters.
%             sim.monthIndex = 1;
%             sim.primaryInstalledRegime = InstalledRegime.empty(1,0);
%             sim.secondaryInstalledRegime = InstalledRegime.empty(1,0);
%             
%             
%             % Populate the properties with initial values and empty structs
%             % so we can refer to the properties immediately.
%             sim.monthlyIncome = zeros(1, 600);
%             sim.monthlyCost = zeros(1, 600);
%             sim.monthlyBiomass = zeros(1, 600);
%             sim.cropStateData = cell(2, 2, 600);
%              
%             sim.regimeNameData = struct('month', {}, 'zone', {}, 'name', {});
%             sim.cropNameData = struct('month', {}, 'zone', {}, 'name', {});
%             sim.regimeAmountData = struct('month', {}, 'zone', {}, 'amount', {});
%             sim.cropAmountData = struct('month', {}, 'zone', {}, 'amount', {});
%             sim.eventData = struct('month', {}, 'zone', {}, 'eventName', {});
%             sim.costData = struct('month', {}, 'zone', {}, 'eventName', {}, 'cost', {});
%             sim.productData = struct('month', {}, 'zone', {}, 'eventName', {}, 'product', {});
%             sim.incomeData = struct('month', {}, 'zone', {}, 'name', {}, 'income', {});
%             
%         end
%         
%         
%         % The simulation tests the condition given as cond. The sim
%         % contains the data required to test the condition.
%         function TF = testTrigger(sim, trig, simMgr)
%             
%             condTruths = false(1, length(trig.conditions));
%                         
%             % For each condition in the trigger
%             for j = 1:length(trig.conditions)
% 
%                 % Set the condition
%                 cond = trig.conditions(j);
%             
%                 % Pull out parameters.
%                 type = cond.conditionType;
%                 s1 = cond.string1{cond.value1};
%                 comp = cond.compString{cond.compValue};
%                 s2 = cond.string2{cond.value2};
%                 params1 = cond.parameters1String;
%                 params2 = cond.parameters2String;
%                 
%                 year = simMgr.year;
%                 month = simMgr.month;
%                 monthIndex = simMgr.monthIndex;
%                 
%                 switch type
% 
%                         case 'Time Index Based'
% 
%                             % Figure out the number to compare.
%                             if strcmp(s1, 'Month')
%                                 indexValue = monthIndex;
%                             elseif strcmp(s1, 'Year')
%                                 indexValue = year;
%                             end               
% 
%                             % Grab the numbers from the string
%                             values = str2num(s2); %#ok<ST2NM>
% 
%                             % Use comparator
%                             switch cond.stringComp{cond.valueComp}
% 
%                                 case '='
%                                     condTruths(j) = any(values == indexValue);                    
%                                 case '<='
%                                     condTruths(j) = (indexValue  <= values(1));
%                                 case '>='
%                                     condTruths(j) = (indexValue  >= values(1));
%                                 case '<'
%                                     condTruths(j) = (indexValue  < values(1));
%                                 case '>'
%                                     condTruths(j) = (indexValue  > values(1));
%                             end
%                             
%                     case 'Month Based'
%                         
%                         % Value2 should be equal to month.
%                         condTruths(j) = cond.value2 == month;
%                         
%                         
%                     case 'Event Happened Previously'
%                 
%                         % Check which event it was that was meant to have happened,
%                         % then get the appropriate range of time from the records
%                         % and check for the event's existance. It must be in the
%                         % same regime, crop and zone.
%                         condTruths(j) = 0;
% 
%                         allegedEventName = cond.string1{cond.value1};
%                         currentMonthIndex = year * 12 - 12 + month;
%                         monthEntry = str2num(cond.string2);
% 
%                          switch cond.stringComp{cond.valueComp}
% 
%                             case '='
%                                 % Can have multiple months. The others can only
%                                 % have one and be valid.
%                                 monthIndiciesToCheck = currentMonthIndex - monthEntry;
% 
%                             case '<='
%                                 % Ok
%                                 monthIndiciesToCheck = [1: currentMonthIndex - monthEntry];
% 
%                             case '>='
%                                 % OK.
%                                 monthIndiciesToCheck = [currentMonthIndex - monthEntry:currentMonthIndex];                        
% 
%                              case '<'
%                                 % OK. If it happened less than one month ago, it could
%                                 % only have happened in this month. -1 + 1 cancel
%                                 % out.
%                                 monthIndiciesToCheck = [currentMonthIndex - monthEntry + 1:currentMonthIndex];     
% 
%                             case '>'
%                                  % OK. If it happened more than one month ago, (2
%                                  % months ago or earlier) we'd have current - 1 -1.
%                                  monthIndiciesToCheck = [1: currentMonthIndex - monthEntry - 1];
% 
%                          end
% 
%                          % Check all previous events for matching the required
%                          % criteria.
% 
% 
%                          for ii = 1:length(previousEvents)
%                              pe = previousEvents(ii);
%                              peMonthIndex = pe.year * 12 - 12 + pe.month;
%                              if any(peMonthIndex == monthIndiciesToCheck)
%                                      if all([zone == pe.zone, ...
%                                              strcmp(allegedEventName, pe.eventName), ...
%                                              strcmp(regimeLabel, pe.regimeName), ...
%                                              strcmp(cropName, pe.cropName)]);
% 
%                                          condTruths(j) = 1;
%                                       break;
%                                      end
% 
%                              end                
%                          end
% 
%                     otherwise
%                             
%                 end % end switch
%            
%             end % end for 
%                
%         end % end testTrigger(sim, trig)
%         
%     end
    
end

