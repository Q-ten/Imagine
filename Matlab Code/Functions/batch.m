function batch( data, method )

    % Run method on each item of data

    for i = 1:length(data)       
        method(data(i));        
    end

end

