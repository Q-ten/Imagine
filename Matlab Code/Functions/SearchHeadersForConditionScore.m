function [ classCols, conditionScores ] = SearchHeadersForConditionScore( headers, dates, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    classCols = zeros(6, 1);
    classPatterns = {'Female mature', 'Female 1-2 y.o.', 'Female weaners', 'Male mature', 'Male 1-2 y.o.', 'Male weaners',};
    for i = 1:length(headers)
       
        h = headers{i};
        k1 = strfind(h, 'Condition Score by class');
        if ~isempty(k1)           
            for j = 1:length(classPatterns)            
                k = strfind(h, classPatterns{j});                
                if ~isempty(k)
                   if (classCols(j) == 0)
                       classCols(j) = i; 
                   else
                       disp('Already for column that matches pattern.'); 
                   end
                end
            end            
        end        
    end
      
    % Now that we have the columns, we can extract the data for the month.
    % We can take the last day of the month for each month
    % Use the dates column for this.
    
    [y, m, d] = datevec(dates, 'dd/mm/yyyy');

    % How many indices do we need? Use last and first dates.
    monthCount = (y(end) - y(1)) * 12 - (m(1) - 1) + (m(end) - 1);
    if d(end) >= 28
        monthCount = monthCount + 1;
    end
    
    oldClassCols = [];
    if (any(classCols == 0))
        oldClassCols = classCols;
        classCols = classCols(classCols ~= 0);        
    end
    
    indices = zeros(monthCount, 1);
    indexCount = 0;
    for i = 1:length(m) - 1
        if m(i+1) ~= m(i)
            indexCount = indexCount + 1;
            indices(indexCount) = i;
        end
    end
    
    % Add the last entry if it counts.
    if (m(end) == m(end-1) && d(end) >= 28)
        indexCount = indexCount + 1;
        indices(indexCount) = length(m);    
    end
    
    startIndices = [1; (indices(1:end -1) + 1)];
    conditionScores = data(indices, classCols);
    
    for i = 1:length(indices)       
        row = data(indices(i), classCols);
        for j = 1:length(row)
           if isnan(row(j))
              % Try to get the last non-nan value in the month.
              % To deal with selling stock on the first of the month, check
              % the previous month too if it exists.
              ix = find(~isnan(data(startIndices(max(i-1, 1)):indices(i), classCols(j))), 1, 'last');
              if ~isempty(ix)
                 row(j) = data(startIndices(max(i-1, 1)) + ix - 1, classCols(j));
              end
           end
        end        
        conditionScores(i, :) = row;
    end
           
    if ~isempty(oldClassCols)
        newConditionScores = zeros(monthCount, length(oldClassCols));
        newConditionScores(:, oldClassCols ~= 0) = conditionScores;
        conditionScores = newConditionScores;
    end
    
end
