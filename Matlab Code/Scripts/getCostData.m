function costsOut = getCostData(costData, headers)

% Goes through the priceData structure and figures out what price to use
% based on the headers.

crop = headers.Crop;
if strcmpi(crop, 'Fallow')
   costsOut.Planting.mean = 0;
   costsOut.Planting.sd = 0;
   costsOut.Planting.month = 4;
   costsOut.Planting.headers = [];
   costsOut.Harvesting.mean = 0;
   costsOut.Harvesting.sd = 0;
   costsOut.Harvesting.month = 12;
   costsOut.Harvesting.headers = [];
   return
end
if ~isfield(costData, crop)
   error('Crop not found in costData'); 
end
if ~isfield(costData.(crop), 'Planting')
   error(['Planting event not found in costData for ', crop]); 
end
if ~isfield(costData.(crop), 'Harvesting')
   error(['Harvesting event not found in costData for ', crop]); 
end

costs = costData.(crop);
costNames = fieldnames(costs);
for costIndex = 1:length(costNames)
    costName = costNames{costIndex};
    rows = costs.(costName);
    rowsThatApply = [];

    % Get the rows that apply by simply eliminating those that don't match.
    rowToUse = -1;
    largestHeaderCount = -1;
    for i = 1:length(rows)

        row = rows(i);
        applies = true;
        headerCount = 0;
        if ~isempty(row.headers)        
            headerNames = fieldnames(row.headers);
            headerCount = length(headerNames);
            for j = 1:headerCount
                temp = headerNames{j};
                if ~strcmp(row.headers.(temp), headers.(temp))
                    applies = false;
                    break;
                end
            end
        end

        if (applies)
           if isempty(rowsThatApply)
               rowsThatApply = row; 
           else
               rowsThatApply(end + 1) = row;            
           end
           if headerCount > largestHeaderCount
              rowIndexToUse = length(rowsThatApply);
              rowToUse = row;
              largestHeaderCount = headerCount;
           end

        end
    end

    % Find the row with the most items. If there are rows with equal numbers of
    % items in the headers, then we have a problem. Also - the one with the
    % most number of headers should be a subset of all the others. So we can
    % test for that too.
    rowsToTest = [rowsThatApply(1:rowIndexToUse - 1), rowsThatApply((rowIndexToUse + 1):end)];

    for i = 1:length(rowsToTest)
        % Check that each header in the row is present in the rowToUse and that
        % there are less headers.
        row = rowsToTest(i);
        if ~isempty(row.headers)
            headerNames = fieldnames(row.headers);
            headerCount = length(headerNames);
            if (headerCount >= largestHeaderCount)
                error('Matching price rows exist with equal level of specificity leading to ambiguous price definition.')
            end
            for j = 1:headerCount
               if ~isfield(rowToUse.headers, headerNames{j})
                   error(['Detected inconsistency in price rows implying ambiguity for crop ', headers.Crop]);
               end
            end
        end
    end

    % If we've not errored by this point, then we have a row to use.
    costsOut.(costName) = rowToUse;
end

end