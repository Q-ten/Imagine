import math

from imagine.util.absorb_fields import absorb_fields


class SpatialInteractions:
    # SpatialInteractions object contains parameters to model water logging, competition
    # and their impact at various rainfall levels.

    def __init__(self, d=None):
        # Competition
        self.use_competition = False
        self.comp_yield_factor = 0
        self.comp_zero_impact_rainfall = 0
        self.comp_max_rainfall_for_full_impact = 0
        # self.comp_reach_factor
        # We're changing comp_reach_factor into 3 parameters
        # Root density
        # Row spacing
        # and relative radii.
        # The row spacing comes from the regime. We'll pass in the row
        # spacing in as a parameter as it's hard for the sis to be expected
        # to calculate it.
        self.root_density = 0  # Root density for competition
        self.relative_radii = 0  # Relative radii for competition

        # Waterlogging
        self.use_waterlogging = False
        # We should not have a separate reach factor for the waterlogging
        # if we have the same roots.
        # self.water_reach_factor
        self.water_yield_factor = 0
        self.water_zero_impact_rainfall = 0
        self.water_min_rainfall_for_full_impact = 0

        # NCZ
        self.use_ncz = False
        self.ncz_choice = 0
        self.ncz_fixed_width = 0
        self.ncz_optimised_parameters = 0

        # self.edit_parameters = 0
        # self.notes = ""
        if isinstance(d, dict):
            fields = [
                "use_competition",
                "comp_yield_factor",
                "comp_zero_impact_rainfall",
                "comp_max_rainfall_for_full_impact",
                "root_density",
                "relative_radii",
                "use_waterlogging",
                "water_yield_factor",
                "water_zero_impact_rainfall",
                "water_min_rainfall_for_full_impact",
                "use_ncz",
                "ncz_choice",
                "ncz_fixed_width",
                "ncz_optimised_parameters"
            ]
            absorb_fields(self, d, fields)

    # @staticmethod
    # def load_obj(s):
    #     # Load object from dictionary s
    #     # Then s contains our fields. Need to copy across what is
    #     # there.
    #     # If it still contains the comp_reach_factor or
    #     # water_reach_factor, then we need to adjust for the new
    #     # factors. We can estimate the parameters but print a
    #     # warning indicating the assumptions being made.
    #
    #     if isinstance(s, dict):
    #         obj = SpatialInteractions()
    #         for key, value in s.items():
    #             if hasattr(obj, key):
    #                 setattr(obj, key, value)
    #             else:
    #                 print(f"Deprecated Property: Property no longer supported in SpatialInteractions object: {key}")
    #         if 'comp_reach_factor' in s or 'water_reach_factor' in s:
    #             # assume row spacing of 2m.
    #             # assume rr of 0.4 (should be less than 1)
    #             # calculate the assumed root density.
    #
    #             obj.relative_radii = 0.4
    #             if s.get('comp_reach_factor', 0) > 0:
    #                 obj.root_density = 4 / (math.pi * 2 * s['comp_reach_factor']**2 * 0.4)
    #             else:
    #                 obj.root_density = 0.2
    #             print(f"Estimating Properties: comp_reach_factor and water_reach_factor no longer supported. Estimating relativeRadii as 0.4, and rootDensity as {obj.root_density} based on rowSpacing of 2m.")
    #         return obj
    #     else:
    #         return s

    def get_impact(self, gsr):
        # This method returns the percentage of full impact of the competition and
        # waterlogging effects.
        if self.use_competition:
            if gsr <= self.comp_max_rainfall_for_full_impact:
                comp_impact = 1
            elif gsr >= self.comp_zero_impact_rainfall:
                comp_impact = 0
            else:
                comp_impact = 1 - ((gsr - self.comp_max_rainfall_for_full_impact) / (self.comp_zero_impact_rainfall - self.comp_max_rainfall_for_full_impact))
        else:
            comp_impact = 0

        if self.use_waterlogging:
            if gsr >= self.water_min_rainfall_for_full_impact:
                water_impact = 1
            elif gsr <= self.water_zero_impact_rainfall:
                water_impact = 0
            else:
                water_impact = (gsr - self.water_zero_impact_rainfall) / (self.water_min_rainfall_for_full_impact - self.water_zero_impact_rainfall)
        else:
            water_impact = 0

        return comp_impact, water_impact

    def get_raw_si_bounds(self, agbm, bgbm, row_spacing):
        # Calculates the y-int and x-int of the competition and
        # waterlogging spatial interaction curves, before clipping occurs.
        if self.use_competition and bgbm > 0:
            # Old calculation
            # compExtent = sqrt(BGBM) * sis.compReachFactor;
            # compYieldLoss = AGBM / compExtent * sis.compYieldFactor;

            # New calculation
            comp_extent = 2 * (bgbm / (math.pi * row_spacing * self.root_density * self.relative_radii))**0.5
            comp_yield_loss = agbm * self.comp_yield_factor
        else:
            comp_extent = 0
            comp_yield_loss = 0

        if self.use_waterlogging:
            # Old calculation
            # waterExtent = sqrt(BGBM) * sis.waterReachFactor;
            # waterYieldGain = AGBM / waterExtent * sis.waterYieldFactor;

            # New calculation
            water_extent = 2 * (bgbm / (math.pi * row_spacing * self.root_density * self.relative_radii))**0.5
            water_yield_gain = agbm * self.water_yield_factor
        else:
            water_extent = 0
            water_yield_gain = 0

        return comp_extent, comp_yield_loss, water_extent, water_yield_gain

    @staticmethod
    def calculate_break_even_cropping_distance(comp_extent, comp_raw_yield_loss, comp_impact, ratio):
        # Uses the results from getImpact and getRawSIBounds, along with
        # the cost:income ratio to work out the optimal distance from the
        # stem that crops start breaking even.
        #
        # Currently only based on the competition
        if ratio > 1:
            # In the case where expected costs are greater than income
            # (ratio > 1) then we're predicting that we should leave the
            # whole paddock fallow.
            # We can indicate that by returning infinite or nan here.
            break_even_cropping_dist = float('nan')
            return break_even_cropping_dist

        y_int = comp_impact * comp_raw_yield_loss
        if y_int > ratio:
            break_even_cropping_dist = (y_int - ratio) / y_int * comp_extent
        else:
            break_even_cropping_dist = 0

        return break_even_cropping_dist
