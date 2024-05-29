function iterationData = processFarmScenarioIterations(imo, farmScenarioFilePath)

% Open the farm scenario file, which should have all the info we need to
% run the scenario.

ea = ExcelApp.getInstance;
ea.startSession;

[scenario, scenarioFile] = extractFarmScenario(farmScenarioFilePath);

ws = get(scenarioFile, 'Worksheets', 'Farm Scenario');        
outputsAnchor = ws.Range('OutputsAnchor');


% Setup pathPatterns, settings, cropDefinitions, paddocks,
% rotationDefinitions
pathPatterns.Root = scenario.settings('Root path');
pathPatterns.CropPathPattern = scenario.settings('CropPathPattern');
pathPatterns.ImagineSetupPathPattern = scenario.settings('ImagineSetupPathPattern');
pathPatterns.SimPathPattern = scenario.settings('SimPathPattern');
pathPatterns.DefaultCropPathPattern = scenario.settings('DefaultCropPathPattern');
pathPatterns.DefaultImagineSetupPathPattern = scenario.settings('DefaultImagineSetupPathPattern');
pathPatterns.APSIMPathPattern = scenario.settings('APSIMPathPattern');
pathPatterns.TemporalInteractionsPathPattern = scenario.settings('TemporalInteractionsPathPattern');

% If the farm scenario file contains a Temporal Interactions sheet, use
% that file as the temporal interactions data source.
for i = 1:scenarioFile.Worksheets.Count
    if strcmp(scenarioFile.Worksheets.Item(i).Name, 'Temporal Interactions')
        pathPatterns.TemporalInteractionsPathPattern = farmScenarioFilePath;
        break;
    end
end

cropDefinitions = scenario.cropDefinitions;
paddocks = scenario.paddocks;
rotationDefinitions = scenario.rotations;
overheads = NormDist.init(zeros(50, 1), zeros(50, 1));
overheads(1:length(scenario.overheads)) = scenario.overheads;

headers = fieldnames(scenario.iterations);

% Need to know how many options each header has for the iteration algorithm
% to work.
for i = 1:length(headers)
   headerCount(i) = length(scenario.iterations.(headers{i}));
end

% Iterate over all header options. The algorithm below goes through all the
% possible options based on an index and will work for as meany headers as
% you have.
for i = 1:prod(headerCount)
    % Get the headers for this iteration.
    row = {};
    for j = 1:length(headers)
        % mod each one by the number of elements in the current category.
        modder = headerCount(j);
        
        % divide and floor by the number of items in following categories.
        divisor = prod(headerCount(j+1:end));
        
        index = mod(floor((i - 1) / divisor), modder) + 1;
        
        iteration.(headers{j}) = scenario.iterations.(headers{j}){index};
        row{j} = iteration.(headers{j});
    end
    iterations(i) = iteration;
    
    % Now - run the farm for the given iteration.
    [farmProfits, farmData] = runFarmScenario(imo, iteration, paddocks, rotationDefinitions, cropDefinitions, pathPatterns, overheads, scenario.costData, scenario.priceData);

    s.farmData = farmData;
    s.farmProfits = farmProfits;
    
    % For each output, work it out and add it to a cell array so we can
    % insert it as a row.
    for j = 1:length(scenario.calculations)
       
        calc = scenario.calculations{j};
        out = calculateFarmFinancesOutput(calc, farmProfits, scenario.settings);
        for k = 1:length(out)
           row{end+1} = out(k); 
        end
    end
    
    % put row into scenario file.
    rowStart = get(outputsAnchor, 'Offset', i+1, 0);
    rowEnd = get(outputsAnchor, 'Offset', i+1, length(row)-1);
    rowRange = get(ws, 'Range', rowStart, rowEnd);
    set(rowRange, 'Value', row);

    s.row = row;
    iterationData(i) = s;

end

invoke(scenarioFile, 'Save');
ea.closeSession;

end


