%
% This function goes through every object handle in objs (and all children) and wherever there
% is a callback that refers to 'handles', it replaces it with subHandles. 
function callbackToUseSubHandles(objs, newField)

    if nargin < 2
        newField = 'subHandles';
    end
        

    % For each control in objs, change the 'handles' bit in the callbacks to
    % 'handles.subHandles'
    for i = 1:length(objs)
        try
            cb = get(objs(i), 'Callback');
            if strcmp(class(cb), 'function_handle')
                cbn = str2func(strrep(func2str(cb), 'guidata(hObject)', ['getfield(guidata(hObject), ''', newField, ''')']));
                set(objs(i), 'Callback',cbn);
            else
                cbn = strrep(cb, 'guidata(gcbo)', ['getfield(guidata(gcbo), ''', newField, ''')']);
                set(objs(i), 'Callback',cbn);
            end
        catch ME
           % not all controls have a callback property 
        end

        try 
            ch = get(objs(i), 'Children');
            if ~isempty(ch)
                callbackToUseSubHandles(ch, newField);
            end
        catch ME
           % not all controls have a Children property 
        end
    end
