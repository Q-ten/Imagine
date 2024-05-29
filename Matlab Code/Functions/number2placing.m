% Returns a string representing the positive integer n as a placing
% eg, 1 goes to '1st', 32 goes to '32nd'
function p = number2placing(n)

if floor(n) == n && ceil(n) == n && n > 0

    switch mod(n, 10)

        case 1
            p = [num2str(n), 'st'];    
        case 2
            p = [num2str(n), 'nd'];            
        case 3
            p = [num2str(n), 'rd'];
        otherwise
            p = [num2str(n), 'th'];
    end
end