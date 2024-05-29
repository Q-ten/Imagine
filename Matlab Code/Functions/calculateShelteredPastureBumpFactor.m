% This function calculates the effect of a productivity bump in the
% sheltered zone in terms of an equivalent additional area of paddock.
% It's calculated in terms of the number of tree-heights of additional
% normal productivity pasture that would be equivalent to having the
% productivity bump.
%
% For example, if we had 25% productivity bump over 5 THs into the paddock
% (then back to normal, that would be 5*.25 = 1.25 additional THs worth of
% normal productivity. It's like having 1.25 THs of additional normal
% pasture added to the width of the paddock.
% Therefore, the output is in THs and can be added to the width of the
% paddock in order to calculate the additional productity. 
% out / width gives the overall percentage increase in the paddock's
% productivity.
% xs are the distances into the paddock in terms of THs. ys give the
% percentage increase at the corresponding x position. The bump function is
% linearly interpolated, and assumes the first y value is also valid at the
% tree line.
function out = calculateShelteredPastureBumpFactor(xs, ys, TH, alleyWidth)

%%%
% This first section adjusts the bump factor if the bump would extend past
% the next belt in the pasture. That is what TH and alleyWidth are used for
% - figuring out how many TH there are until the next belt, and therefore,
% the alley width in terms of tree heights.
% If our alley is smaller than the open paddock distance, we chop off the
% end of the bump function. At the end, we calculate the y value for that
% point according to a linear interpolation between it's two adjacent
% points in xs and ys.

alleyWidthInTH = alleyWidth / TH;

if (alleyWidth < xs(end) * TH)
    ix = find(alleyWidthInTH > xs(1:end-1), 1, 'last');

    if ~isempty(ix)
        % figure out the y value that corresponds to the point along the
        % interpolated line at alleyWidthInTH.
        midY = (alleyWidthInTH - xs(ix)) / (xs(ix+1) - xs(ix)) * (ys(ix+1) - ys(ix)) + ys(ix);
        xs = xs(1:ix+1);
        ys = ys(1:ix+1);
        xs(end) = alleyWidthInTH;
        ys(end) = midY;
    end
end
%%%


% Calculate the area under the curve of the given interpolated points.
% Assume no change between 0 and ys(1) (flat till ys(1)).
deltas = diff([0 xs]);
y_avs = mean([ys(1), ys(1:end-1); ys]);

out = deltas * y_avs';






