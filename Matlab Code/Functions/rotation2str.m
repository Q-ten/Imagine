% This function returns a string representation of the rotation. 
% Rotation is a crop rotation as per Imagine software.
function str = rotation2str(rotation)

if strcmp(rotation.category, 'Pasture')
    str = ['Jan - Dec', '    ', rotation.crop];    
else
    str = [rotation.plant, ' - ', rotation.harvest, '    ', rotation.crop];
end

if(strcmp(rotation.companionCrop, 'None') || isempty(rotation.companionCrop))
    return
else
    str = [str, ' (', rotation.companionCrop, ')'];
end
