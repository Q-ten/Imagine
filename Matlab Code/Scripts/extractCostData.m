function costData = extractCostData(scenarioFile)
    
cs = get(scenarioFile, 'Worksheets', 'Costs');        
fs = get(scenarioFile, 'Worksheets', 'Farm Scenario');        

% Get the headers
costHeadersRange = cs.Range('CostHeaders');
costHeaders = costHeadersRange.Value;

% Go through all the rows and pull out items. If the crop has not been
% added, add it. If the Cost has not been added to the crop, add it.
% Then add the row data to it.
currentCell = cs.Range('CropCostAnchor').get('Offset', 1, 0);
xlDown = 4;
costData = [];

while true
    % If current cell is empty, do xl down to get next cell. If that's
    % empty, then break.
    if isnan(currentCell.Value)
        currentCell = currentCell.get('End', xlDown);        
        if isnan(currentCell.Value)
            break;
        end
    end
    
    endCell = currentCell.get('Offset', 0, 2 + length(costHeaders) + 2);
    currentRowRange = cs.get('Range', currentCell, endCell);
    currentRow = currentRowRange.Value;
    cost.mean = currentRow{end-1};
    cost.sd = currentRow{end};
    cost.month = currentRow{3};
    cost.headers = [];
    for i = 1:length(costHeaders)
        v = currentRow{3+i};
        if ~isnan(v)
            cost.headers.(costHeaders{i}) = v;
        end
    end
        
    % costData.Wheat.Seeding(1) = costsRow
    if isfield(costData, currentRow{1})
        if isfield(costData.(currentRow{1}), currentRow{2})
            costData.(currentRow{1}).(currentRow{2})(end+1) = cost;
        else
            costData.(currentRow{1}).(currentRow{2}) = cost;            
        end
    else
        costData.(currentRow{1}).(currentRow{2}) = cost;                    
    end
       
    
    currentCell = currentCell.get('Offset', 1, 0);
end
    
end