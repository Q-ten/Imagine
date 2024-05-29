% This function adds the fields of the second argument to those of the
% first.
% Repeated field names are not taken care of. If there is a repeat, the
% field of the second argument is the one that survives. The value in the
% first is overwritten.
%
function handles = combineFields(handles, extraHandles)

extraFields = fieldnames(extraHandles);
for j = 1:length(extraFields)
    theField = extraFields{j};           
    handles = setfield(handles, theField, getfield(extraHandles, theField));
end