function TF = structeq(s1, s2)

if ~isstruct(s1) || ~isstruct(s2)
    error('Inputs must be structs')
end

s1fields = sort(fieldnames(s1));
s2fields = sort(fieldnames(s2));

if length(s1fields) == length(s2fields)
   TF = all(strcmp(s1fields, s2fields));
   if ~TF
       return
   end   
else
   TF = false;
   return
end

% At this point, we know that the fields of the structs match.

% cellstr, char, numeric, struct
for i = 1:length(s1fields)
   
    a = s1.(s1fields{i});
    b = s2.(s1fields{i});
    
    % check the types are the same.
    if iscellstr(a)
        TF = iscellstr(b);
        if (TF)
            TF = all(strcmp(a, b));
        end
    elseif ischar(a)
        TF = ischar(b);
        if (TF)
            TF = strcmp(a, b);
        end
    elseif isnumeric(a)
        TF = isnumeric(b);
        if (TF)
            if isempty(a)
                TF = isempty(b);
            else
                if isnan(a)
                    TF = isnan(b);
                else
                    TF = all(all(a == b));
                end
            end
        end
    elseif isstruct(a)
        TF = isstruct(b);
        if (TF)
            TF = structeq(a, b);
        end
    else
        error('Non-supported structeq type. Structs can only be checked if they consist of other structs, cell arrays of strings, strings, or numeric (including empty) arrays.');
    end
    if ~TF
        return
    end
end