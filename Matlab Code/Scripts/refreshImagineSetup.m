function [success, isLoaded, settings] = refreshImagineSetup(headers, pathPatterns, cropDefinitions, settings)
% REFRESHIMAGINESETUP - Uses the headers and the path pattern to work out
% where an Imagine Run should exist in the file system. Checks that the
% imagine run file is younger than the crop files it uses. If not, or if it
% doesn't exist, the imagine run is created from the default run and the
% rotation recreated.

% success is set to true or false based on whether the imagine run was
% successfully refreshed.

% headers contains: Location, Climate, Soil, (Nitrogen), Rotation.

% settings has references to the data needed to define the crops. Like the
% APSIM file, the default crop file, the temporal interactions file and the
% default imagineSetup file.

% pathPatterns defines the root, the crop path pattern and the imagineRun
% path pattern.

if nargin < 4
    settings = [];
end    

isLoaded = false;

% Refresh the crop files.
[success, crops, cropFileInfos, settings] = refreshCropFiles(headers, pathPatterns, cropDefinitions, settings);
if ~success
    error('Unable to refresh the crop files.')
end

imagineSetupPath = generatePath(pathPatterns.Root, headers, pathPatterns.ImagineSetupPathPattern);
imagineSetupFileInfo = dir(imagineSetupPath);
defaultImagineSetupPath = generatePath(pathPatterns.Root, headers, pathPatterns.DefaultImagineSetupPathPattern);
defaultImagineSetupFileInfo = dir(defaultImagineSetupPath);

if isempty(defaultImagineSetupFileInfo) || isempty(defaultImagineSetupFileInfo.datenum)
   success = false;
   error('settings.DefaultImagineSetupPath is invalid');
end

upToDate = true;
if isempty(imagineSetupFileInfo) || isempty(imagineSetupFileInfo.datenum)
    upToDate = false;
else
    % Test each crop file to see if it's younger.
    for i = 1:length(cropFileInfos)
        if cropFileInfos(i).datenum > imagineSetupFileInfo.datenum
            upToDate = false;
            break;
        end
    end
    % Test the default Imagine setup to see if it's younger.
    if defaultImagineSetupFileInfo.datenum > imagineSetupFileInfo.datenum
       upToDate = false; 
    end
end

imo = ImagineObject.getInstance;

if ~upToDate
    % Load the default setup, set it up and save it to the Imagine setup
    % location.
    imo.load(defaultImagineSetupPath ,'');
    
    % 1. For each crop in rotation, insert the crop file into CropManager.
    % If it is already in the crop, replace the crop.
    % cropManager.replaceCrop.
    % Otherwise, add the crop.
    % 2. Set up the rotation to use the crops we want.
    % 3. Remove the crops we don't need.
    % 4. Save the setup.
    
    % 1.
    uniqueCrops = unique(crops);
    for i = 1:length(uniqueCrops)
        % Get the crop from our crops list.
        crop = uniqueCrops(i);
        cropCode = crop.name;
        if ismember(cropCode, imo.cropManager.cropNames)
            imo.cropManager.replaceCrop(cropCode, crop);
        else
            imo.cropManager.addCropObject(crop);
        end
    end
    
    % 2. 
    rotationItem = imo.regimeManager.regimes(1).delegate.rotationList(1);   
    rotationCodes = regexp(headers.Rotation, '\.', 'split');
    
    for i = 1:length(rotationCodes)
        cropCode = rotationCodes{i};
        crop = crops(ismember(cropCode, {crops.name})); % We name the crops according to the code, not the 'name'.
        
        rotationItem.crop = cropCode;
        rotationItem.category = crop.categoryChoice;
        if strcmp(rotationItem.category, 'Pasture')
            rotationItem.DSE = 12;
        else
            rotationItem.DSE = 0;
        end
        rotationItem.companionCrop = '';

        if i == 1
            rotationList = rotationItem;
        else
            rotationList(i) = rotationItem;
        end
    end
    imo.regimeManager.regimes(1).delegate.rotationList = rotationList;
    imo.regimeManager.regimes(1).delegate = AnnualRegimeDelegate.createAnnualRegimeEvents(imo.regimeManager.regimes(1).delegate);
    % Go via the regimeManager and an event is triggered.
    imo.regimeManager.replaceRegime(imo.regimeManager.regimes(1).regimeLabel, imo.regimeManager.regimes(1));
    
    % 3. Remove un-needed crops from crops list.
    managerCrops = imo.cropManager.cropDefinitions;
    for i = 1:length(managerCrops)
        if ~ismember(managerCrops(i).name, {crops.name})
            imo.cropManager.removeCrop(managerCrops(i).name, true);
        end
    end
    
    % 4. Save the setup file.
    try
        imo.save(imagineSetupPath, '');
        success = true;
    catch e
        disp(e);
        success = false;
    end
    
    isLoaded = true;
else
    % Not sure if we should return to say it's up to date, or return it loaded into Imagine.
    % I think we should probably return success and the setupPath, and
    % perhaps whether it's loaded. Or just success and whether it's loaded.
    % That work's best.
    success = true;
    isLoaded = false;
end


