import numpy as np

# This function calculates the effect of a productivity bump in the
# sheltered zone in terms of an equivalent additional area of paddock.
# It's calculated in terms of the number of tree-heights (TH) of additional
# normal productivity pasture that would be equivalent to having the
# productivity bump.
#
# For example, if we had a 25% productivity bump over 5 THs into the paddock
# (then back to normal), that would be 5 * 0.25 = 1.25 additional THs worth of
# normal productivity. It's like having 1.25 THs of additional normal
# pasture added to the width of the paddock.
# Therefore, the output is in THs and can be added to the width of the
# paddock in order to calculate the additional productivity.
# out / width gives the overall percentage increase in the paddock's
# productivity.
# xs are the distances into the paddock in terms of THs. ys give the
# percentage increase at the corresponding x position. The bump function is
# linearly interpolated, and assumes the first y value is also valid at the
# tree line.
def calculate_sheltered_pasture_bump_factor(xs, ys, TH, alley_width):
    ###
    # This first section adjusts the bump factor if the bump would extend past
    # the next belt in the pasture. TH (tree height) and alleyWidth are used for
    # determining how many tree heights there are until the next belt, thus
    # calculating the alley width in terms of tree heights.
    # If our alley is narrower than the open paddock distance, we truncate the
    # end of the bump function. Finally, we calculate the y value for that
    # point using linear interpolation between its two adjacent points in xs and ys.

    # If no trees, return no bump.
    if not TH:
        return 0

    # Adjust the bump factor if the bump would extend past the next belt in the pasture
    alley_width_in_TH = alley_width / TH

    if alley_width_in_TH < xs[-1]:
        ix = None
        for i, x in enumerate(xs[:-1]):
            if x < alley_width_in_TH:
                ix = i

        if ix is not None:
            # figure out the y value that corresponds to the point along the interpolated line at alley_width_in_TH
            mid_y = ((alley_width_in_TH - xs[ix]) / (xs[ix + 1] - xs[ix])) * (ys[ix + 1] - ys[ix]) + ys[ix]
            xs = xs[:ix + 2]  # include the next index for slicing
            ys = ys[:ix + 2]  # include the next index for slicing
            xs[-1] = alley_width_in_TH
            ys[-1] = mid_y

    # Calculate the area under the curve of the given interpolated points
    # Assume no change between 0 and ys(1) (flat till ys(1)).
    xs = [0] + xs
    ys = [ys[0]] + ys       # Insert the first height at 0.
    deltas = np.diff(xs)
    y_avs = np.mean([ys[:-1], ys[1:]], axis=0)

    # Calculate the output as the sum of trapezoids under the curve
    out = np.sum(deltas * y_avs)

    return out
