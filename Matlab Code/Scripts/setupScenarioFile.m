% setScenarioFile
% This is a simple script that sets the scenarioFile variable to a file
% path found via a file browser that's opened when this script is run.

if ~exist('loc', 'var')   
    loc = '.';
end
if ~ischar(loc)
   loc = '.'; 
end
if exist(loc, 'dir') == 0
    loc = '.';
end

[file, path, filt] = uigetfile('.xlsm', 'Find Farm Scenario Setup file', loc);
if ~isnumeric(file) && ~isnumeric(path)    
    scenarioFile = [path, file];
    disp(['Scenario File set to ', scenarioFile])
    loc = path;
end