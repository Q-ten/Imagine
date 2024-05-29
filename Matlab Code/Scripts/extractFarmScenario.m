function [scenario, scenarioFile] = extractFarmScenario(farmScenarioFilePath)

    ea = ExcelApp.getInstance;
    scenarioFile = ea.getExcelFile(farmScenarioFilePath);
%    scenarioFile = excelObj.Workbooks.Open(farmScenarioFilePath, false, false);

    pause(.1)   % seems to be needed in order for the next line to work consistently.
    ws = get(scenarioFile, 'Worksheets', 'Farm Scenario');        
    
    % 1. Get the general settings.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'SettingsAnchor');
    % Skip the header.
    settings = containers.Map(regionCells(2:end, 1), regionCells(2:end, 2));
        
    % 2. Get the overheads.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'OverheadsAnchor');
    for i = 2:size(regionCells, 1)
        row = regionCells(i, :);
       overheads(row{1}) = NormDist(row{2}, row{3});
    end
    
    % 3. Get the paddocks.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'PaddocksAnchor');
    paddock.name = '';
    paddock.soil = '';
    paddock.area = 0;
    paddocks = paddock;
    for i = 2:size(regionCells, 1);
        row = regionCells(i, :);
        paddock.name = row{1};
        paddock.soil = row{2};
        paddock.area = row{3};
        paddocks(i - 1) = paddock;
    end
    
    % 4. Get the iterations.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'IterationsAnchor');    
    iterations = [];
    for j = 1:size(regionCells, 2)
       header = regionCells{1, j};
       iterations.(header) = {};
       for i = 1:size(regionCells, 1) - 1
           c = regionCells{i + 1, j};
           if isnan(c)
               break;
           else
               iterations.(header){end+1} = c;
           end
       end
    end
    
    % 5. Get the crop definitions.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'CropsAnchor');
    headers = regionCells(1, :);
    for i = 1:size(regionCells, 1) - 1
       s = [];
       for j = 1:length(headers)
           c = regionCells{i+1, j};
           if isnan(c)
               error('Empty cell found. Crop Definitions table must be full.');
           else
               s.(headers{j}) = c;
           end           
       end
       cropDefs(i) = s;
    end
    
    % 6. Get the rotations.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'RotationsAnchor');
    s = [];
    s.paddock = '';
    s.rotation = {};
    for i = 1:size(regionCells, 1) - 1
       row = regionCells(i+1, :); 
       s.paddock = row{1};
       s.rotation = regexp(row{2}, ',', 'split');
       rotations(i) = s;
    end            
    
    % 7. Get the calculations we need.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'CalculationsAnchor');
    calculations = regionCells(2:end, 1)';
    
    scenario.settings = settings;
    scenario.overheads = overheads;
    scenario.paddocks = paddocks;
    scenario.iterations = iterations;
    scenario.cropDefinitions = cropDefs;
    scenario.rotations = rotations;
    scenario.calculations = calculations;
    
    % 8. Get the cost data.
    scenario.costData = extractCostData(scenarioFile);
    
    % 9. Get the price data
    scenario.priceData = extractPriceData(scenarioFile);
    
    % 10. Clear the outputs area.
    [regionCells, region, rowOffset] = getRangeRegionFromAnchor(ws, 'OutputsAnchor');
    outputsAnchor = ws.Range('OutputsAnchor');
    heading = get(outputsAnchor, 'Value');
    invoke(region, 'ClearContents')
    set(outputsAnchor, 'Value', heading);
    % Put the headings in there.
    % First the headers.
    % Then the reults of calling the calculate outputs function with no
    % argument.
    row = fieldnames(scenario.iterations)';
    for i = 1:length(calculations)
       headings = calculateFarmFinancesOutput(calculations{i}, []);
       row(end+1:end+length(headings)) = headings;
    end
    rowStart = get(outputsAnchor, 'Offset', 1, 0);
    rowEnd = get(outputsAnchor, 'Offset', 1, length(row)-1);
    rowRange = get(ws, 'Range', rowStart, rowEnd);
    set(rowRange, 'Value', row);
    
    invoke(scenarioFile, 'Save');
end
