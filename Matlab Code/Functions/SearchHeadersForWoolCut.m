function [ classCols, woolCut ] = SearchHeadersForWoolCut( headers, dates, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    classCols = zeros(6, 1);
    classPatterns = {'ewe adults', 'ewe adults', 'lambs', 'wether adults', 'wether adults', 'lambs',};
    for i = 1:length(headers)
       
        h = headers{i};
        k1 = strfind(h, 'Wool cut/head');
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
    % We need to sum all the entries for each month.
    
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
    
    woolCut = zeros(monthCount, length(classCols));
    indexCount = 1;
    for i = 1:length(m) - 1        
        if (i > 1)
            if m(i) ~= m(i-1)
                indexCount = indexCount + 1;
            end
        end
        dailyWoolCut1 = data(i, classCols);
        notNAN = ~isnan(dailyWoolCut1);
        dailyWoolCut2 = zeros(1, length(classCols));
        dailyWoolCut2(notNAN) = dailyWoolCut1(notNAN);
        woolCut(indexCount, :) = woolCut(indexCount, :) + dailyWoolCut2;
    end
    
    if ~isempty(oldClassCols)
        newWoolCut = zeros(monthCount, length(oldClassCols));
        newWoolCut(:, oldClassCols ~= 0) = woolCut;
        woolCut = newWoolCut;
    end
end
