function simIDs = writeToAccess(sim, description, fileName)

if nargin < 3
    conn = openAccessConnection();
else
    conn = openAccessConnection(fileName);
end

if isempty(sim)
    return
end
if ~strcmp(class(sim), 'Simulation')
    error('First argument must be a Simulation or a vector of Simulations.');
end


% Disregard all sims that have already been added to the DB.
% Could give the option of replacing...
% NOT YET IMPLEMENTED


% Sim
% InstalledRegime
% PlantedCrop
% Occurrence
% Income
% Outputs
% EventOutputs
% Cost
% Price
% Unit

% First of all, calculate the units to add to the Unit table.
units = extractUnits(sim(1));

% Get the crop names that area actually used in the sim too.
%cropNames = extractCropNames(sim(1));

    tableName = 'Unit';
    fields = {'SpecificName', 'SpeciesName', 'UnitName'};
    types = {'string', 'string', 'string'};

    rows = [{units.specificName}' ...
            {units.speciesName}' ...
            {units.unitName}'];
            
    unitIDs = myInsertInto(conn, tableName, fields, types, rows);

    if ~all(size(units) == size(unitIDs))
        error('Vector of unit IDs from database insertion does not exactly match the vector of units from sim.');
    end

wb = waitbar(0, 'Please wait while data is loaded into the Access Database...');
    
%try

    % Add an entry for the sim. (Could check that the sim has not been added
    % already by setting a timestamp. Nice. But for later.

    tableName = 'Sim';
    fields = {'ScenarioID', 'NumberInScenario', 'CreatedTime', 'Description'};
    types = {'int', 'int', 'string', 'string'};

    % todo: Update following line when we pass in multiple sims and have
    % scenarios.
    simNumber = 1;
    rows = {0, simNumber, sim.timestamp, description};

    simIDs = myInsertInto(conn, tableName, fields, types, rows);


    % Set up soft col names for costs and income

        incomeOccIDCol = 1;
        productIndexCol = 2;
        incomeAmountUnitIDCol = 3;
        incomeAmountNumberCol = 4;
        incomePriceIDCol = 5;
        incomeTotalCol = 6;


        costOccIDCol = 1;
        costAmountUnitIDCol = 2;
        costAmountNumberCol = 3;
        costPriceIDCol = 4;
        costTotalCol = 5;

        eventOutputOccIDCol = 1;
        indexInEventOutputsCol = 2;
        eventOutputAmountUnitIDCol = 3;
        eventOutputAmountNumberCol = 4;

        outputColCount = 6;
        regimeOutputColCount = 5;

    % Each sim get proportional amount from 1 to 40 pc.
    endOfSimUpload = .01;
    endOfSimsUpload = 1;
    waitbar(endOfSimUpload, wb)


    simIndex = 0;
    % Get id for added sim row.
    for simID = simIDs

        % Update the wb.
        simIndex = simIndex + 1;    
        wbxSimStart = (endOfSimsUpload - endOfSimUpload) * (simIndex - 1) / length(simIDs) + endOfSimUpload;
        wbxSimEnd = (endOfSimsUpload - endOfSimUpload) * (simIndex) / length(simIDs) + endOfSimUpload;
        waitbar(wbxSimStart, wb);

        % Pre allocate a bunch of columns for the incomes and costs in this sim.
        incomeArr = zeros(5000, incomeTotalCol);
        costArr = zeros(5000, costTotalCol);
        eventOutputArr = zeros(5000, eventOutputAmountNumberCol);
        outputRows = zeros(5000, outputColCount);
        regimeOutputRows = zeros(5000, regimeOutputColCount);
        incomeIndex = 0;
        costIndex = 0;
        eventOutputIndex = 0;
        outputRowIndex = 0;
        regimeOutputRowIndex = 0;

        % For each sim, enter the prices, the climate data and then 
        % the regime data (which contains everything else).

        % Enter prices.
        % For each crop, get the list of product prices and cost prices.

        tableName = 'Price';
        fields = {'SimID', 'YearIndex', 'RateUnitID', 'RateNumber'};
        types = {'int', 'int', 'int', 'float'};

        % preallocate the columns to go in rows...
        % Get the number of prices.
        cropsUsedInSim = getCropNamesInSim(sim);
        for i = 1:length(cropsUsedInSim)
           cropsUsedInSim{i} = underscore(cropsUsedInSim{i}); 
        end
        cpt = sim.costPriceTable;
        cropNames = intersect(fieldnames(cpt), cropsUsedInSim);
        priceCount = 0;
        for i = 1:length(cropNames)
            priceCount = priceCount + length(fieldnames(cpt.(cropNames{i})));
        end
        ppt = sim.productPriceTable;
        cropNames = intersect(fieldnames(ppt), cropsUsedInSim);
        for i = 1:length(cropNames)
            priceCount = priceCount + size(ppt.(cropNames{i}), 1);
        end
        simIDCol = repmat({simID}, priceCount * 50, 1);
        yearCol = repmat([1:50]', priceCount, 1);    
        unitIDCol = zeros(50 * priceCount, 1);
        numberCol = zeros(50 * priceCount, 1);

        dbBaseOffset = 0;
        cptDBIx = struct([]);
        for i = 1:length(cropNames)
           cropName = cropNames{i};
           eventNames = fieldnames(cpt.(cropName));
           for j = 1:length(eventNames)
                eventName = eventNames{j};
                costUnit = cpt.(cropName).(eventName)(1).denominatorUnit;

                unitID = unitIDs(costUnit == units);
                if ~(size(unitID, 1) == 1 && size(unitID, 2) == 1)
                    error('Cost UnitID not found.');
                end
                if (unitID == 0)
                    error(['Cost UnitID is 0. Event name: ', eventName, ' of crop ', cropName])
                end
                unitIDCol(dbBaseOffset + 1:dbBaseOffset + 50, 1) = repmat(unitID, 50, 1);
                numberCol(dbBaseOffset + 1:dbBaseOffset + 50, 1) = [cpt.(cropName).(eventName).number]';

                cptDBIx(1).(cropName).(eventName) = dbBaseOffset;  % dbBaseOffset + 1 + firstDBPriceIDForSim = first dbIndex for this price 
                dbBaseOffset = dbBaseOffset + 50;      % 50 here for 50 years - length of the sim.            
           end
        end

        % Products are done slightly differently... each crop has a pxm Rate
        % array. Number of columns is number fo products and correspond to
        % productPriceModels.
        pptDBIx = struct([]);
        for i = 1:length(cropNames)
           cropName = cropNames{i};
           for j = 1:size(ppt.(cropName), 1)

                priceUnit = ppt.(cropName)(j, 1).denominatorUnit;

                % handleEq
                unitID = unitIDs(priceUnit == units);
                if ~(size(unitID, 1) == 1 && size(unitID, 2) == 1)
                    error('Product UnitID not found.');
                end
                if (unitID == 0)
                    error(['Product UnitID is 0. Product number ', num2str(j), ' of crop ', cropName])
                end

                unitIDCol(dbBaseOffset + 1:dbBaseOffset + 50, 1) = repmat(unitID, 50, 1);
                numberCol(dbBaseOffset + 1:dbBaseOffset + 50, 1) = [ppt.(cropName)(j, :).number]';

                pptDBIx(1).(cropName)(j) = dbBaseOffset;  % dbBaseOffset + 1 + firstDBPriceIDForSim = first dbIndex for this price 
                dbBaseOffset = dbBaseOffset + 50;      % 50 here for 50 years - length of the sim.            
           end
        end
        rows = [simIDCol ...
                num2cell(yearCol) ...
                num2cell(unitIDCol)...
                num2cell(numberCol)];

        priceIDs = myInsertInto(conn, tableName, fields, types, rows);
        assignin('base', 'priceIDs', priceIDs);

        priceIDBase = priceIDs(1) - 1;

        % Add an entry for each InstalledRegime.
        tableName = 'InstalledRegime';
        fields = {'SimID', 'RegimeLabel', 'Zone', 'InstalledMonthIndex', 'FinalMonthIndex'};
        types = {'int', 'string', 'string', 'int', 'int'};

        installedRegimeCount = length(sim.installedRegimes);
        rows = [repmat({simID}, installedRegimeCount, 1) ...
                {sim.installedRegimes.regimeLabel}' ...
                {sim.installedRegimes.zone}' ...
                {sim.installedRegimes.installedMonth}' ...
                {sim.installedRegimes.finalMonth}' ];

        installedRegimeIDs = myInsertInto(conn, tableName, fields, types, rows);

        % For each regime, add an entry for each PlantedCrop
        for installedRegimeIndex = 1:length(installedRegimeIDs)

            wbxrstart = (wbxSimEnd - wbxSimStart) * .75 * (installedRegimeIndex - 1) / length(installedRegimeIDs) + wbxSimStart;
            wbxrend = (wbxSimEnd - wbxSimStart) * .75 * installedRegimeIndex / length(installedRegimeIDs) + wbxSimStart;
            waitbar(wbxrstart, wb);

            
            installedRegimeID = installedRegimeIDs(installedRegimeIndex);
            tableName = 'PlantedCrop';
            fields = {'InstalledRegimeID', 'Name', 'NumberInRegime', 'PlantMonthIndex', 'FinalMonthIndex'};
            types = {'int', 'string', 'int', 'int', 'int'};

            ir = sim.installedRegimes(installedRegimeIndex);

            plantedCropCount = length(ir.plantedCrops);

            rows = [repmat({installedRegimeID}, plantedCropCount, 1) ...
                    {ir.plantedCrops.cropName}' ...
                    num2cell(1:plantedCropCount)' ...
                    {ir.plantedCrops.plantedMonth}' ...
                    {ir.plantedCrops.destroyedMonth}' ];

            plantedCropIDs = myInsertInto(conn, tableName, fields, types, rows);

            % For each PlantedCrop add rows for each Occurrence.        
            for plantedCropIndex = 1:length(plantedCropIDs)
               plantedCropID = plantedCropIDs(plantedCropIndex); 

                wbxrcstart = (wbxrend - wbxrstart) * (plantedCropIndex - 1) / plantedCropCount + wbxrstart;
                wbxrcend = (wbxrend - wbxrstart) * plantedCropIndex / plantedCropCount + wbxrstart;
                waitbar(wbxrcstart, wb);
               
               tableName = 'Occurrence';
               fields = {'PlantedCropID', 'OccurrenceNumberInCrop', 'EventName', 'MonthIndex'};
               types = {'int', 'int', 'string', 'int'};

               pc = ir.plantedCrops(plantedCropIndex);
               occurrenceCount = length(pc.occurrences);

               rows = [repmat({plantedCropID}, occurrenceCount, 1) ...
                      num2cell(1:occurrenceCount)' ...
                      {pc.occurrences.eventName}' ...
                      {pc.occurrences.monthIndex}' ];

              occurrenceIDs = myInsertInto(conn, tableName, fields, types, rows);
              cropName = pc.cropObject.name;

              % For each Occurrence, add the cost, add the income for each
              % product.
              for occurrenceIndex = 1:occurrenceCount

                  occ = pc.occurrences(occurrenceIndex);
                  occID = occurrenceIDs(occurrenceIndex);
                  occurrenceIndex = occurrenceIndex;
                  try              
                      amountUnitID = [unitIDs(occ.costItems.quantity.unit == units)];

                      amountNumber = occ.costItems.quantity.number;
                      occYear = floor((occ.monthIndex - 1) / 12) + 1;
                      costPriceID = cptDBIx.(underscore(cropName)).(underscore(occ.eventName)) + priceIDBase + occYear;
                      costTotal = occ.costItems.cost.number;

                      % TODO - I think this happens because regime units aren't
                      % going into the Unit table.
                      if isempty(amountUnitID)
                          error('Couldn''t find amountUnitID for cost.');
                      end

                      if length(amountUnitID) ~= 1
                          error('Cant single out a cost price.');
                      end

                      costRow = [occID, amountUnitID, amountNumber, costPriceID, costTotal];

                      costIndex = costIndex + 1;
                      costArr(costIndex, :) = costRow;

                  catch e
                      disp(e.message)
                      % This can happen if costItems is empty. In the case of
                      % an intrinsic event - due to say sequestered carbon. No
                      % cost involved but there's a product and income.
                  end              

                  % Now put in the products.
                  for productIndex = 1:length(occ.products)                 

                      amountUnitID = unitIDs(occ.products(productIndex).quantity.unit == units);
                      amountNumber = occ.products(productIndex).quantity.number;

                      % This is bizarre. The following line causes Matlab
                      % to seg fault on Amir's new computer. When we braek
                      % it up into a few lines, it goes fine.
                     % cropProductUnits = [ppt.(underscore(cropName))(:, 1).denominatorUnit];
                      
                      a = ppt.(underscore(cropName));
                      b = a(:, 1);
                      c = [b.denominatorUnit];
                      
                      cropProductUnits = c;
                      productIndexInCrop = find(occ.products(productIndex).price.denominatorUnit == cropProductUnits);
                      if isempty(productIndexInCrop) || length(productIndexInCrop) ~= 1
                          error('Cant single out a product price.');
                      end
                      incomePriceID = pptDBIx.(underscore(cropName))(productIndexInCrop) + priceIDBase + occYear;
                      totalIncome = occ.products(productIndex).income.number;

                      if isempty(amountUnitID)
                          error('Could not find amountUnitID for product.');
                      end

                      prodRow = [occID, productIndexInCrop, amountUnitID, amountNumber, incomePriceID, totalIncome];

                      incomeIndex = incomeIndex + 1;
                      incomeArr(incomeIndex, :) = prodRow;                  
                  end

                  % Now put in the event outputs.
                  for eoIndex = 1:length(occ.eventOutputs)

                      amountUnitID = unitIDs(occ.eventOutputs(eoIndex).unit == units);
                      amountNumber = occ.eventOutputs(eoIndex).number;

                      if isempty(amountUnitID)
                          error('Couldn''t assign a unitID to eventOutput.');
                      end

                      eoRow = [occID, eoIndex, amountUnitID, amountNumber];

                      eventOutputIndex = eventOutputIndex + 1;
                      eventOutputArr(eventOutputIndex, :) = eoRow;                  
                  end
              end

              % Still in the plantedCrop loop. We've just gone through the
              % planted crop's occurrences. Now we can go through the outputs.
              % We need to get multiply the numbers by the denominator amount
              % to get the real amount. So we have to go and get everything.
              % Lets write a function to do that for us. These functions are
              % huge and unwieldy.
              wbxrcostart = (wbxrcend - wbxrcstart) * 0.05 + wbxrcstart;
              wbxrcoend = (wbxrcend - wbxrcstart) * 0.95 + wbxrcstart;            
              waitbar(wbxrcostart, wb);

              newOutputRows = createDBOutputRowsForPlantedCrop(pc, plantedCropID, units, unitIDs, wb, wbxrcostart, wbxrcoend);
               if ~isempty(newOutputRows)
                   outputRows(outputRowIndex + 1:outputRowIndex + size(newOutputRows, 1), :) = newOutputRows;
                   outputRowIndex = outputRowIndex + size(newOutputRows, 1);
               end      
            end

            % Still in the installedRegime loop.
            % Need to add the regimeOutputs to the database.
            newRegimeOutputRows = createDBRegimeOutputRowsForInstalledRegime(ir, installedRegimeID, units, unitIDs);
            if ~isempty(newRegimeOutputRows)
                   regimeOutputRows(regimeOutputRowIndex + 1:regimeOutputRowIndex + size(newRegimeOutputRows, 1), :) = newRegimeOutputRows;
                   regimeOutputRowIndex = regimeOutputRowIndex + size(newRegimeOutputRows, 1);
            end   

            waitbar(wbxrend, wb);

        end

        wbx = (wbxSimEnd - wbxSimStart) * .75 + wbxSimStart;
        waitbar(wbx, wb);

        % Now that the income and cost columns have been populated, add them to
        % the DB in one go.
       tableName = 'Income';
       fields = {'OccurrenceID', 'IndexInProducts', 'AmountUnitID', 'AmountNumber', 'PriceID', 'TotalIncome'};
       types = {'int', 'int', 'int', 'float', 'int', 'int'};

       incomeIDs = myInsertInto(conn, tableName, fields, types, incomeArr(1:incomeIndex, :));
       waitbar((wbxSimEnd - wbxSimStart) * .8 + wbxSimStart, wb);

       tableName = 'Cost';
       fields = {'OccurrenceID', 'AmountUnitID', 'AmountNumber', 'PriceID', 'TotalCost'};
       types = {'int', 'int', 'float', 'int', 'int'};

       costIDs = myInsertInto(conn, tableName, fields, types, costArr(1:costIndex, :));
       waitbar((wbxSimEnd - wbxSimStart) * .85 + wbxSimStart, wb);

       tableName = 'EventOutput';
       fields = {'OccurrenceID', 'IndexInEventOutputs' 'AmountUnitID', 'AmountNumber'};
       types = {'int', 'int', 'int', 'float'};

       eventOutputIDs = myInsertInto(conn, tableName, fields, types, eventOutputArr(1:eventOutputIndex, :));
       waitbar((wbxSimEnd - wbxSimStart) * .9 + wbxSimStart, wb);


        tableName = 'Output';
        fields = {'PlantedCropID', 'MonthIndex', 'MonthDay', 'IndexInOutputs',  'AmountUnitID', 'AmountNumber'};
        types = {'int', 'int', 'int', 'int', 'int', 'float'};

%         for batchIndex = 100:100:outputRowIndex       
%             endIndex = batchIndex
%             startIndex = batchIndex - 99;
%             outputIDs(startIndex:endIndex) = myInsertInto(conn, tableName, fields, types, outputRows(startIndex:endIndex, :));
%         end
%         outputIDs(startIndex:endIndex) = myInsertInto(conn, tableName, fields, types, outputRows(startIndex:endIndex, :));
%         
        outputIDs = myInsertInto(conn, tableName, fields, types, outputRows(1:outputRowIndex, :));
        waitbar((wbxSimEnd - wbxSimStart) * .95 + wbxSimStart, wb);


        tableName = 'RegimeOutput';
        fields = {'InstalledRegimeID', 'MonthIndex', 'IndexInRegimeOutputs', 'AmountUnitID', 'AmountNumber'};
        types = {'int', 'int', 'int', 'int', 'float'};

        regimeOutputIDs = myInsertInto(conn, tableName, fields, types, regimeOutputRows(1:regimeOutputRowIndex, :));
        waitbar((wbxSimEnd - wbxSimStart) * .98 + wbxSimStart, wb);


        % Finish off the sim by adding the rainall.    
        tableName = 'MonthlyRainfall';
        fields = {'SimID', 'MonthIndex', 'Rainfall'};
        types = {'int', 'int', 'float'};

        rainfallRows = ...
                [ repmat({simID}, 600, 1), ...
                  num2cell(1:600)', ...
                  num2cell(reshape(sim.monthlyRainfall, 600, 1)) ];
        rainfallIDs = myInsertInto(conn, tableName, fields, types, rainfallRows);
        waitbar((wbxSimEnd - wbxSimStart) * 1 + wbxSimStart, wb);

    end     % end simN

    delete(wb)
    conn.close

% catch e
%     disp(e.message)
%     delete(wb);
% end











