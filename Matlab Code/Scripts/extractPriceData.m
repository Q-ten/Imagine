function priceData = extractPriceData(scenarioFile)
    
ps = get(scenarioFile, 'Worksheets', 'Yield Prices');        
fs = get(scenarioFile, 'Worksheets', 'Farm Scenario');        

% Get the headers
priceHeadersRange = ps.Range('PriceHeaders');
priceHeaders = priceHeadersRange.Value;

% Go through all the rows and pull out items. If the crop has not been
% added, add it. If the price has not been added to the crop, add it.
% Then add the row data to it.
currentCell = ps.Range('CropPriceAnchor').get('Offset', 1, 0);
xlDown = 4;
priceData = [];

while true
    % If current cell is empty, do xl down to get next cell. If that's
    % empty, then break.
    if isnan(currentCell.Value)
        currentCell = currentCell.get('End', xlDown);        
        if isnan(currentCell.Value)
            break;
        end
    end
    
    endCell = currentCell.get('Offset', 0, 0 + length(priceHeaders) + 2);
    currentRowRange = ps.get('Range', currentCell, endCell);
    currentRow = currentRowRange.Value;
    price.mean = currentRow{end-1};
    price.sd = currentRow{end};
    price.headers = [];
    for i = 1:length(priceHeaders)
        v = currentRow{1+i};
        if ~isnan(v)
            price.headers.(priceHeaders{i}) = v;
        end
    end
        
    % priceData.Wheat = priceRow
    if isfield(priceData, currentRow{1})
        priceData.(currentRow{1})(end+1) = price;                    
    else
        priceData.(currentRow{1}) = price;                    
    end       
    
    currentCell = currentCell.get('Offset', 1, 0);
end
    
end