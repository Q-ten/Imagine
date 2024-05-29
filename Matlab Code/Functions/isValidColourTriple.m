% A simple function to check that the variable passed is a 1x3 double with
% values in the range [0, 1].
function TF = isValidColourTriple(colourTriple)
    
    TF = true;

    if ndims(colourTriple) ~= 2 || ~isnumeric(colourTriple)
        TF = false;
    end
    
    if TF
        if size(colourTriple, 1) ~= 1 || size(colourTriple, 2) ~= 3
           TF = false; 
        end
    end
    if TF 
       if max(colourTriple) > 1 || min(colourTriple) < 0
           TF = false;
       end
    end
        
end