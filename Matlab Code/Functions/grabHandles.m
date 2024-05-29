% This function takes the handles in hs, and returns a handles structure
% which contains the handles in hs associated by their tag names.
% The process is recursive, so if a handle has children, it grabs their
% handles too.
%
function handles = grabHandles(hs)

   handles = [];
   for i = 1:length(hs)
       
    tg = get(hs(i), 'Tag');
    ch = get(hs(i), 'Children');
    
    handles = setfield(handles, tg, hs(i));
    
    if(~isempty(ch))
        % For each child handle, grab the handles then add them.
        extraHandles = grabHandles(ch);
        handles = combineFields(handles, extraHandles);
    end
end
   
   