function clone = cloneHandleObject(hObj)

% This method saves the passed object to a file, then loads it from that
% file as a completely new object, but with the same data. It then deletes
% the file it saved.

save('__TEMPCLONEDOBJECT.mat', 'hObj');
cloneS = load('__TEMPCLONEDOBJECT.mat');
clone = cloneS.hObj;
delete('__TEMPCLONEDOBJECT.mat');
