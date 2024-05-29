% This function provides a way to drill down into matlab objects and alter 
% parameters in a general way.
function ob = bulkParameterEditor(ob, fieldPath, value)

    field = fieldPath(1);
    
    if (length(fieldPath) > 1)    
        subOb = ob.(field.field);
        if (length(subOb) > 1)
            
            if (~isempty(field.indices))
                subObs = subOb(field.indices);
            elseif (isfunction(field.test))
                ixs = find(subOb, field.test(subOb));
                subObs = subOb(ixs);
            end
            
            for i = 1:length(subObs)
                subObs(ix) = bulkParameterEditor(subObs(ix), fieldPath(2:end), value);
            end
            ob.(field.field) = subObs;
        else
            newOb = bulkParameterEditor(subOb, fieldPath(2:end), value);
            if (~isa(newOb, 'handle'))
                ob.(field.field) = bulkParameterEditor(subOb, fieldPath(2:end), value);            
            end
        end
    else
        ob.(field.field) = value;
    end 

end

% EG
% 
% fields = [ ...
%     makeField('growthModel', [] , []), ...
%     makeField('delegate', [] , []), ...
%     makeField('FOO', [] , []), ...
%     makeField('availableAtStart', [] , []), ...
%     ...
% ];
% 
% fields2 = [ ...
%     makeField('growthModel', [] , []), ...
%     makeField('delegate', [] , []), ...
%     makeField('propagationParameters', [] , []), ...
%     makeField('products', [] , []), ...
%     makeField('Timber', [] , []), ...
%     makeField('series', [] , []), ...
%     ...
% ];
% 
% makeField = @(field, indices, test) struct('field',field,'indices',indices, 'test', test);

