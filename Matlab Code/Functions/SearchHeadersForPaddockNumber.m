function [ classCols, paddockNumbers ] = SearchHeadersForPaddockNumber( headers, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    classCols = zeros(6, 1);
    classPatterns = {'Paddock no. occupied', 'Ewe yearlings', 'Ewe weaners', 'Paddock no. occupied', 'Wether yearlings', 'Wether weaners',};
    classAntiPatterns = {'(', 'XXX', 'XXX', '(', 'XXX', 'XXX'};
    for i = 1:length(headers)
       
        h = headers{i};
        k = strfind(h, 'Paddock no. occupied');
        if ~isempty(k)           
            for j = 1:length(classPatterns)            
                k1 = strfind(h, classPatterns{j});      
                k2 = strfind(h, classAntiPatterns{j});
                if ~isempty(k1) && isempty(k2)
                   if (classCols(j) == 0)
                       classCols(j) = i; 
                   else
                       disp('Already for column that matches pattern.'); 
                   end
                end
            end            
        end        
    end

    paddockNumbers = data(:, classCols);
    
end
