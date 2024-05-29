% Assumes that the intputs are all arrays. We're going to put all the
% items in those arrays into a single dimensional array.
function out = catArrays(varargin)

%out = [];
i = 0;
hasOut = false;
for cx = 1:length(varargin)
    cxLength = length(varargin{cx});
    if ~isempty(varargin{cx})
        out(i+1:i+cxLength) = varargin{cx};
        i = i + cxLength;
        hasOut = true;
    end     
end
if (~hasOut)
    out = [];
end