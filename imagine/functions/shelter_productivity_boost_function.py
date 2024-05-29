from imagine.functions.calculate_sheltered_pasture_bump_factor import calculate_sheltered_pasture_bump_factor

def shelter_productivity_boost_function(out, monthly_rainfall, sim, gmd, belt_no, alley_width, TH, paddock_width, paddock_height, OP_productivity):
    """
    Returns the additional FOO that comes from the shelter productivity boost.
    TH is the current tree height.
    OPProductivity is the FOO generated at Open Paddock.
    """
    # Estimate ETo and scale the bump function by the monthly ETo
    est_ETo = out.expected_daily_eto_by_month[sim.month-1]
    # DSM20180613 changed the following line to remove ETO in bump function
    # est_bump_function = out.sheltered_bump_factor_by_ETo * est_ETo
    est_bump_function = out.sheltered_bump_factor_by_eto

    # Calculate the overall 'extra' paddock width (in TH) equivalent
    additional_TH = calculate_sheltered_pasture_bump_factor(out.model_distances_in_tree_heights, est_bump_function, TH, alley_width)
    additional_TH *= belt_no

    # Calculate the paddock's additional FOO from the bump function
    FOO_from_bump = OP_productivity * additional_TH * TH / paddock_width

    return FOO_from_bump
