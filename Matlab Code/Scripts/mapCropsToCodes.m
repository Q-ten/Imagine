% We need to convert the crop names to crop codes so that we can
% include alternatives of the same crop with unique names.
function codedTemporalModifiers = mapCropsToCodes(cropTemporalModifiers, cropDefinitions)

    codedTemporalModifiers = {};
    for i = 1:size(cropTemporalModifiers, 1)
        crop = cropTemporalModifiers{i, 1};
        modifier = cropTemporalModifiers{i, 2};
        cropDefs = cropDefinitions(ismember({cropDefinitions.Crop}, crop));
        codes = {cropDefs.Code};
        for j =1:length(codes)
            codedTemporalModifiers{end + 1, 1} = codes{j};
            codedTemporalModifiers{end, 2} = modifier;            
        end
    end

end
