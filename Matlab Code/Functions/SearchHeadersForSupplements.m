function [ mainCols, youngCols, priceCols, suppCostByMonth ] = SearchHeadersForSupplements( headers, dates, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    % supplementCols is a list of indices that match
    % maintenance, production1, production2, production3 for main, young
    % and price.
    
    mainCols = zeros(4, 1);
    youngCols = zeros(4, 1);
    priceCols = zeros(4, 1);
    
    mainNumbersCols = zeros(2, 1);
    youngNumbersCols = zeros(4, 1);

    mainNumberPatterns = {'Mature Females', 'Mature Males'};
    youngNumberPatterns = {'Female 1-2 y.o.', 'Female weaners', 'Male 1-2 y.o.', 'Male weaners'};
    
    typePatterns = {'Maint Suppt', 'Prod Suppt 1', 'Prod Suppt 2', 'Prod Suppt 3'};
    pricePatterns = {'Maintenance supplement price', 'Production supplement 1 price', 'Production supplement 2 price', 'Production supplement 3 price'};
    for i = 1:length(headers)     
        h = headers{i};
        k = strfind(h, 'Supplement intake by type');
        if ~isempty(k)            
            for j = 1:length(typePatterns)            
                k = strfind(h, typePatterns{j});                
                if ~isempty(k)
                   if (mainCols(j) == 0)
                       mainCols(j) = i; 
                   else
                       youngCols(j) = i;      
                   end
                end
            end            
        end        
        
        k = strfind(h, 'price');
        if ~isempty(k)            
            for j = 1:length(pricePatterns)            
                k = strfind(h, pricePatterns{j});                
                if ~isempty(k)
                   if (priceCols(j) == 0)
                       priceCols(j) = i; 
                   end
                end
            end            
        end
        
        k = strfind(h, 'Numbers');
        kk = strfind(h, 'Mature');
        if ~isempty(k)  
            if ~isempty(kk)
                for j = 1:length(mainNumberPatterns)            
                    k = strfind(h, mainNumberPatterns{j});
                    if ~isempty(k)
                       if (mainNumbersCols(j) == 0)
                           mainNumbersCols(j) = i; 
                       else
                           disp('Already for column that matches pattern.'); 
                       end
                    end
                end                           
            else
                for j = 1:length(youngNumberPatterns)            
                    k = strfind(h, youngNumberPatterns{j});
                    if ~isempty(k)
                       if (youngNumbersCols(j) == 0)
                           youngNumbersCols(j) = i; 
                       else
                           disp('Already for column that matches pattern.'); 
                       end
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
        
    suppCostByMonth = zeros(monthCount, 1);
    indexCount = 1;
    for i = 1:length(m) - 1
        if (i > 1)
            if m(i) ~= m(i-1)
                indexCount = indexCount + 1;
            end
        end
        
        dayMain1 = data(i, mainCols);
        dayYoung1 = data(i,  youngCols);
        dayPrice1 = data(i, priceCols);
        
        dayMain2 = zeros(1, length(mainCols));
        dayYoung2 = zeros(1, length(youngCols));
        dayPrice2 = zeros(1, length(priceCols));
        
        dayMainNumbers = sum(data(i, mainNumbersCols), 2);
        dayYoungNumbers = sum(data(i, youngNumbersCols), 2);
        
        notNAN = ~isnan(dayMain1);
        dayMain2(notNAN) = dayMain1(notNAN);
        
        notNAN = ~isnan(dayYoung1);
        dayYoung2(notNAN) = dayYoung1(notNAN);
        
        notNAN = ~isnan(dayPrice1);
        dayPrice2(notNAN) = dayPrice1(notNAN);

        dayCost = dayPrice2 .* (dayMain2 * dayMainNumbers / 1000 + dayYoung2 * dayYoungNumbers / 1000);
        suppCostByMonth(indexCount) = suppCostByMonth(indexCount) + sum(dayCost);
    end
        
    
end
