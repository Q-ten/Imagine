% turns out it's implemented in the containers.Map class. $%@&^%#!
% classdef map
%    % A simple implementation of a map class. No optimisation whatsoever.
%    % Would be lovely if it were a hashmap, or sorted, or even a tree. 
%    % But no. It's just a list we have to search through completely each
%    % time. But it's convenient.
%     
%     properties
%        keys
%        values
%     end
%     
%     methods
%        
%         function obj = map(keys, values)
%            ok = false;
%            if length(keys) == length(values) 
%               if length(unique(keys)) == length(keys)
%                   if iscell(keys) && iscell(values)                    
%                     if all(cellfun(@(x)(ischar(x)), keys))
%                        ok = true; 
%                     end
%                   end
%               end
%            end
%            if ok
%               obj.keys = keys;
%               obj.values = values;
%            else
%               error('keys and values must both be cell arrays of the same length. keys must not have repeats.'); 
%            end
%         end
%         
%         function subsasgn(a,ss,b)
%             s = ss.subs{1};
%             if ischar(s)
%                 ix = find(ismember(a.keys, s), 1, 'first');
%                 if isempty(ix)
%                     a.keys{end + 1} = s;
%                     a.values{end + 1} = b;
%                 else
%                     a.values{ix} = b;
%                 end
%             else
%                 error('Must supply a string as the key.');
%             end
%         end
%     
%         function c = subsref(a, ss)
%             ind = ss(1);
%             switch ind.type
%                 case '()'
%                     s = ind.subs{1};
%                     if ischar(s)
%                         ix = find(ismember(a.keys, s), 1, 'first');
%                         if isempty(ix)
%                            error('Key not found.'); 
%                         else
%                             c = a.values{ix};
%                         end
%                         if length(ss) > 1
%                            c = subsref(c, ss(2:end)); 
%                         end
%                     else
%                         error('Must supply a string as the key.');
%                     end                                
%                 case '{}'
%                     error('Cell style indexing invalid for map class');
%                 case '.'
%                     c = builtin('subsref',a,ss);
% %                     subsref(a, ss);
% %                     if (length(ss) > 1)
% %                         c = subsref(a.(ss(1).subs), ss(2:end));
% % %                        c = subsref(c, ss(2:end));
% %                     else
% %                         c = a.(ss(1).subs);
% %                     end
%             end
%         end
%         
%         function clearKeyValue(a, key)
%             if ischar(key)
%                 ix = find(ismember(a.keys, key), 1, 'first');
%                 if isempty(ix)
%                    error('Key not found.'); 
%                 else
%                     a.keys = a.keys([1:(ix-1), (ix+1):end]);
%                     a.values = a.values([1:(ix-1), (ix+1):end]);
%                 end
%             else
%                 error('Must supply a string as the key.');                
%             end
%         end
%     end
% end