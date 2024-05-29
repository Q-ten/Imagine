function path = generatePath(root, headers, pathPattern)
% GENERATEPATH - replaces the components of the path defined in square
% brackets with the contents of the appropriate header.
% For example, if path is '[Root]/Loc_[Location]' and 
% headers.Location = 'Tammin'
% and root = "C:/ImagineRuns'
% then the result is 'C:/ImagineRuns/Loc_Tammin'

headers.Root = root;
repstr = '${headers.($1)}';
path = regexprep(pathPattern, '\[([^\[]|.])*]', repstr);

end