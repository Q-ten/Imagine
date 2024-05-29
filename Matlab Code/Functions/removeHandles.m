% This function takes in a handles structure and deletes
% each field

function removeHandles(handles)

if(isempty(handles))
    return
end

fields = fieldnames(handles);

for i = 1:length(fields)
    try
        % We try/catch because if we delete a parent, the child will no longer be
        % valid, and so throw an exception. So if it's an invalid handle object, we don't care.
        if ishandle(handles.(fields{i}))              
            delete(handles.(fields{i}));
        end
    catch ME
        % Done it this way because MATLAB had a bug in the message, and
        % would have extra periods at the end in different versions.
        % If it starts with this then its ok.
        findindex = strfind(ME.message, 'Invalid');
        
        if ~isempty(findindex)
            continue
        else
            throw(ME)
        end
    end
end