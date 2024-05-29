function [ classCols, dailyNumbers, monthlyNumbers ] = SearchHeadersForNumbers( headers, dates, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    classCols = zeros(6, 1);
    classPatterns = {'Mature Females', 'Female 1-2 y.o.', 'Female weaners', 'Mature Males', 'Male 1-2 y.o.', 'Male weaners'};
    for i = 1:length(headers)
       
        h = headers{i};
        k = strfind(h, 'Numbers');
        if ~isempty(k)            
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
    
    dailyNumbers = data(:, classCols);
    
    % Now that we have the columns, we can extract the data for the month.
    % We can take the last day of the month for each month
    % Use the dates column for this.
    
    [y, m, d] = datevec(dates, 'dd/mm/yyyy');

    % How many indices do we need? Use last and first dates.
    monthCount = (y(end) - y(1)) * 12 - (m(1) - 1) + (m(end) - 1);
    if d(end) >= 28
        monthCount = monthCount + 1;
    end
    
    indices = zeros(monthCount, 1);
    indexCount = 0;
    for i = 1:length(m) - 1
        if m(i+1) ~= m(i)
            indexCount = indexCount + 1;
            indices(indexCount) = i;
        end;
    end
    
    % Add the last entry if it counts.
    if (m(end) == m(end-1) && d(end) >= 28)
        indexCount = indexCount + 1;
        indices(indexCount) = length(m);    
    end
    
    monthlyNumbers = data(indices, classCols);
    
end

