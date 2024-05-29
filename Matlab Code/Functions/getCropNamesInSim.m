function cropNames = getCropNamesInSim(sim)

    cropNames = {};
    
    for i = 1:length(sim.installedRegimes)
    
        % Then for each plantedCrop, get its outputs too.
        for j = 1:length(sim.installedRegimes(i).plantedCrops)
            pc = sim.installedRegimes(i).plantedCrops(j);
            crop = pc.cropObject;
            cropNames{end + 1} = crop.name;
        end
    end

    cropNames = unique(cropNames);
    
end