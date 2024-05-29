function default = absorbFields(default, existing)

% For each field in existing, check if the field exists in default.
% If it does and it's a struct, replace the field in default with the
% result of absorbFields on that struct.
% If it's not a struct, replace the field.
if isstruct(existing) && ~isempty(existing)
    fns = fieldnames(existing);
    for i = 1:length(fns)
        fn = fns{i};
        % Sometimes the existing one will have been populated as an empty
        % struct. If so, then we should keep the default as well.
        if isfield(default, fn) && ~isempty(existing.(fn))
            % Only take the existing field if the 'structness' matches the
            % default.
            if isstruct(default.(fn)) && isstruct(existing.(fn))
                % If both are structs, then abosrb the struct
                default.(fn) = absorbFields(default.(fn), existing.(fn));
            elseif ~isstruct(default.(fn)) && ~isstruct(existing.(fn))
                % Only abosrb the existing field directly if it both are not structs.
                default.(fn) = existing.(fn);
            end
        end    
    end
end

