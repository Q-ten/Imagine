function [ MECols, MEIntake ] = SearchHeadersForHerbageMEIntake( headers, data )

    % classCols is a list of indices that match 
    % Ewes, Ewe hoggets, Ewe weaners, Wethers, Wether Hoggers, Wether
    % Weaners.
    
    % supplementCols is a list of indices that match
    % maintenance, production1, production2, production3 for main, young
    % and price.
    
    MECols = [0,0];
    
    for i = 1:length(headers)     
        h = headers{i};
        k = strfind(h, 'ME intake by source (Herbage)');
        if ~isempty(k)
            if (MECols(1) == 0)
                MECols(1) = i;
            else
                MECols(2) = i;
            end
        end                
    end

    MEIntake = zeros(size(data, 1), length(MECols));
    for i = 1:length(MECols)
        if (MECols(i) > 0)
            MEIntake(:, i) = data(:, MECols(i));
        end
    end
    
end

