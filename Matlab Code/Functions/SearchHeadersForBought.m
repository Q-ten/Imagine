function [ classCols, bought ] = SearchHeadersForBought( headers, dates, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    classCols = zeros(6, 1);
    classPatterns = {'Mature Females', 'Ewes', 'Ewe Lambs', 'Mature Males', 'Wethers', 'Wether Lambs'};
    for i = 1:length(headers)
       
        h = headers{i};
        k1 = strfind(h, 'Stock traded');
        k2 = strfind(h, 'Bought');
        if ~isempty(k1) && ~isempty(k2)            
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
    % We need to sum all the entries for each month.
    
    [y, m, d] = datevec(dates, 'dd/mm/yyyy');

    % How many indices do we need? Use last and first dates.
    monthCount = (y(end) - y(1)) * 12 - (m(1) - 1) + (m(end) - 1);
    if d(end) >= 28
        monthCount = monthCount + 1;
    end
    
    % Need to deal with case where classCols has 0s in. (No column found)
    oldClassCols = [];
    if (any(classCols == 0))
        oldClassCols = classCols;
        classCols = classCols(classCols ~= 0);        
    end
    
    bought = zeros(monthCount, length(classCols));
    indexCount = 1;
    for i = 1:length(m) - 1
        if (i > 1)
            if m(i) ~= m(i-1)
                indexCount = indexCount + 1;
            end
        end
        bought(indexCount, :) = bought(indexCount, :) + data(i, classCols);
    end
    
            
    if ~isempty(oldClassCols)
        newBought = zeros(monthCount, length(oldClassCols));
        newBought(:, oldClassCols ~= 0) = bought;
        bought = newBought;
    end
    
end
