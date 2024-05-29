function s = joinStrings(ss, joiner, penultimateJoiner, lastJoiner)

    % Joins strings together by adding joiner in between the strings in ss.
    % lastJoiner is tacked on the end. penultimateJoiner is used instead of
    % joiner between the last two items in ss.
    % eg: joinStrings({'A', 'B', 'C'}, ', ', ', and ', '.') = 'A, B, and
    % C.'
    
    if nargin < 4
        lastJoiner = '';
    end
    if nargin < 3
        penultimateJoiner = joiner;
    end
    
    l = length(ss);
    s = '';
    for i = 1:l        
        if i == (l-1)
            s = [s, ss{i}, penultimateJoiner];                                    
        elseif i == l
            s = [s, ss{i}, lastJoiner];                        
        else
            s = [s, ss{i}, joiner];            
        end
    end

end