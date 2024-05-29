function childrenOfType = extractChildHandlesByType(target, type)

childrenOfType = [];
children = get(target, 'Children');

isbar = false;
if strcmp(type, 'bar')
    isbar = true;
end
isscatter = false;
if strcmp(type, 'scatter')
    isscatter = true;
end

if (isbar)
    for i = 1:length(children)
        if strcmp(get(children(i), 'Type'), 'hggroup') && isprop(children(i), 'BarLayout')            
            childrenOfType(end+1) = children(i);
        else
            childrenOfType = [childrenOfType, extractChildHandlesByType(children(i), type)];
        end
    end
elseif (isscatter)
    for i = 1:length(children)
        if strcmp(get(children(i), 'Type'), 'hggroup') && isprop(children(i), 'SizeData')            
            childrenOfType(end+1) = children(i);
        else
            childrenOfType = [childrenOfType, extractChildHandlesByType(children(i), type)];
        end
    end

else
    for i = 1:length(children)
        if strcmp(get(children(i), 'Type'), type)            
            childrenOfType(end+1) = children(i);
        else
            childrenOfType = [childrenOfType, extractChildHandlesByType(children(i), type)];
        end
    end
end

end