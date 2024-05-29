function TFs = doubleeq(A, B, smallValue)

if nargin < 3
   smallValue = 1e-10; 
end

if ~all(size(A) == size(B))
    error('A and B must be the same size.');
end

TFs = abs(A - B) < smallValue;

end