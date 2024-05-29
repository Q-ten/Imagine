% Gets the list of all the units in the sim
function units = extractUnits(sim)

units = Unit.empty(1, 0);



for i = 1:length(sim.installedRegimes)
    
    % each regime has some regime outputs too.
    if ~isempty(sim.installedRegimes(i).outputs)
        outputUnits = [sim.installedRegimes(i).outputs(:, 1).unit];
        units = [units, outputUnits];
    end
    
    % Then for each plantedCrop, get its outputs too.
    for j = 1:length(sim.installedRegimes(i).plantedCrops)
        pc = sim.installedRegimes(i).plantedCrops(j);
        crop = pc.cropObject;
        
        % Add the outputs units and denominator units.
        firstOutputsCol = pc.getOutputsMonthStart([], 1);
        if ~isempty(firstOutputsCol)
            units = [units, [firstOutputsCol.unit], [firstOutputsCol.denominatorUnit]];
        end
        
        incomePriceModels = crop.getUniquePriceModelDefinitions('Income');
        costPriceModels =  crop.getUniquePriceModelDefinitions('Cost');
        
        incomeDenUnits = [incomePriceModels.denominatorUnit];
        costDenUnits = [costPriceModels.denominatorUnit];
        
        gmDel = crop.growthModel.delegate;
        
        % for each event
        
        ies = [gmDel.growthModelInitialEvents, gmDel.growthModelRegularEvents, gmDel.growthModelDestructionEvents];
        eous = Unit.empty(1, 0);
        pus = Unit.empty(1, 0);
        for k = 1:length(ies)
            eous = [eous, gmDel.getEventOutputUnits(ies(k).name)];
            pus = [pus, gmDel.getOutputProductUnits(ies(k).name)];
        end               
        units = [units, incomeDenUnits, costDenUnits, eous, pus];        
    end
end

uniqueUnits = units(1);

for i = 2:length(units)
   
    if ~any(uniqueUnits == units(i))
        uniqueUnits = [uniqueUnits, units(i)];
    end
end

units = uniqueUnits;

