function imagineRun = GetImagineRun( headers, pathPatterns, cropSettings, allPhases )
%GETIMAGINERUN - Finds and returns results from an Imagine run or creates and saves
% the run before returning results, if it doesn't exist or if it's out of date.

% Specifying an Imagine run requires headers:
% Location
% Climate
% Soil
% Nitrogen
% Rotation (crops list)
% XXX - Rotation phase. (Not used any more)

% The headers will be used with the path patterns to generate the paths for
% the imagineRuns.

% Furthermore, we need a path pattern so we can generate the paths of the
% default files and where to look to load and save the imagine run files
% and crop files.
% pathPatterns will be a struct with root, imagineRunPattern, cropPattern
% as fields.

% In addition we need crop creating settings including the temporal
% interactions file, the location of the APSIM yield data file and the location
% of the default crops.

% allPhases is a true or false flag to indicate whether all the phases for
% the sim should be run, collated and returned, or just the one specified
% in headers.rotation



% Call refreshImagineSetup to make sure that the imagineSetup exists.

% If the imagine setup is not actually changed, then the simulation files
% maybe up to date. If so, we can just load them and return the contents.

% Let's make it not possible to return just one phase. Let's make it that
% we have to return all of them.




end

