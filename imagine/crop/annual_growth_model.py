from copy import deepcopy

from imagine.util.underscore import underscore
import imagine.crop.annual_growth_model_aux as aux
import imagine.core.global_helpers as gh
from imagine.crop.growth_model import GrowthModel
from imagine.core.unit import Unit
from imagine.core.price_model import PriceModel
from imagine.core.amount import Amount
from imagine.core.rate import Rate
from imagine.crop.rainfall_based_annual_gm import RainfallBasedAnnualGM
from imagine.crop.spatial_interactions import SpatialInteractions
from imagine.events.imagine_event import ImagineEvent, ImagineEventStatus
from imagine.climate.climate_manager import ClimateManager
import numpy as np
import math
from imagine.core.base_model import BaseModel
from imagine.core.price_model import PriceModel
from imagine.core.cost_item import CostItem
from imagine.util.absorb_fields import absorb_fields
from imagine.util.underscore import underscore
from imagine.util.exists import exists
from dotwiz import DotWiz


class AnnualGrowthModel(GrowthModel):
    # Set up the specific default parameters for this growth model
    model_name = "Annual"
    supported_categories = ['Annual']
    state_description = ['Yield']

    _sub_model_mappings = {
        #        'FixedYieldGrowthModel': FixedYieldGrowthModel,
        'RainfallBasedAnnualGM': RainfallBasedAnnualGM
    }

    def __init__(self, category, d=None):
        super().__init__()

        self.propagation_parameters = None
        #        self.private_product_price_models, self.cost_price_models = _make_annual_gm_price_models()
        # self._product_price_rates, self._cost_price_rates = aux.make_annual_gm_price_rates()

        # Growth model defines empty event lists. Fill them here.
        self._growth_model_initial_events, self._growth_model_regular_events, self._growth_model_destruction_events = \
            aux.make_annual_gm_imagine_events()

        self._growth_model_financial_events = []

        self._gm_key = None

        if isinstance(d, dict):
            self.load_gm(d)

    def load_gm(self, d):
        # TODO: Check if this is sufficient. We may need to import each set of fields with more care.
        # crop config defines growth_model_parameters. That is provided here as d.
        # d is equivalent to self.propagation_parameters, but we construct propagation_parameters more carefully.
        # It's not a direct assignment.
        # There are some direct assignments though. Absorb those fields.
        prop_params = DotWiz()
        simple_fields = ["model_choice",
                         "harvest_index",
                         "temporal_interactions"]
        absorb_fields(prop_params, d, simple_fields)
        if "model_choice" in d:
            if d.model_choice in self._sub_model_mappings:
                sub_gm_param_key = underscore(d.model_choice + "Parameters")
                if sub_gm_param_key in d:
                    sub_gm = self._sub_model_mappings[d.model_choice](d[sub_gm_param_key])
                else:
                    sub_gm = self._sub_model_mappings[d.model_choice]()
                prop_params.sub_gm = sub_gm
                # To maintain compatibility, I'll add a field named the model choice, but in snake case.
                # I think it may be less confusing to refer to prop_params.sub_gm instead.
                self._gm_key = underscore(d.model_choice)
                prop_params[self._gm_key] = sub_gm
        if "spatial_interactions" in d:
            sis = SpatialInteractions(d.spatial_interactions)
            prop_params.spatial_interactions = sis

        self.propagation_parameters = prop_params

    def propagate_state(self, planted_crop, sim):
        product_rates = []

        # Return the potential products if planted_crop and sim are empty.
        if not sim and not planted_crop:
            if 'fixed_yield_gm' in self.propagation_parameters:
                _, product_rates = self.propagation_parameters['fixed_yield_gm'].propagate_state(None, None)
            new_state = None
            return new_state, product_rates

        # Important. Using deepcopy to create a new version of state. We then alter it.
        # It's vital that state never include any external objects. Only state data.
        new_state = deepcopy(planted_crop.state)

        # Base yield calculation
        prop_params = self.propagation_parameters
        if prop_params.model_choice not in ("ManualAnnualGM", "RainfallBasedAnnualGM"):
            raise ValueError(f'model_choice not set to recognized model in {planted_crop.crop_name}\'s'
                             f' AnnualGrowthModel configuration.')

        if prop_params['model_choice'] == 'ManualAnnualGM':
            base_yield = prop_params['manual_annual_gm'].calculate_yearly_yield(sim)
        elif prop_params['model_choice'] == 'RainfallBasedAnnualGM':
            base_yield = prop_params['rainfall_based_annual_gm']\
                .calculate_yearly_yield(sim, planted_crop.planted_month)

        # Apply the harvest index to the base yield if appropriate.
        # if prop_params['HIData']['units'] == 'Biomass':
        #     base_yield = base_yield * prop_params['HIData']['HI']
        if hasattr(prop_params, 'harvest_index'):
            base_yield *= prop_params.harvest_index

        # Calculate the temporal modifier
        temporal_modifier = 1

        if self.propagation_parameters.get('temporalModifiers'):
            previous_planted_crop_index = planted_crop.parent_regime.crop_index - 1
            if previous_planted_crop_index > 0:
                previous_planted_crop = planted_crop.parent_regime.planted_crops[previous_planted_crop_index]
                ppc_name = previous_planted_crop.crop_object.name
                ppc_cat = previous_planted_crop.crop_object.category_choice

                # Get the modifier index that matched the name, and failing
                # that the index that matched the category name.
                modifier_index = next(
                    (i for i, v in enumerate(self.propagation_parameters['temporalModifiers']) if v[0] == ppc_name),
                    None)
                if modifier_index is None:
                    modifier_index = next(
                        (i for i, v in enumerate(self.propagation_parameters['temporalModifiers']) if v[0] == ppc_cat),
                        None)

                if modifier_index is not None:
                    temporal_modifier = self.propagation_parameters['temporalModifiers'][modifier_index][1]

        spatial_modifier = 1
        lost_yield = 0

        new_state.yield_lost_to_only_competition_per_paddock = 0
        new_state.yield_gain_waterlogging_per_paddock = 0
        new_state.waterlogging_extent_past_ncz = 0
        new_state.competition_extent_past_ncz = 0
        new_state.water_impact = 0
        new_state.comp_impact = 0
        new_state.comp_intensity_at_ncz = 0
        new_state.water_intensity_at_ncz = 0

        spatial_interaction_detail = DotWiz({
            'comp_extent': 0,
            'comp_yield_loss': 0,
            'water_extent': 0,
            'water_yield_gain': 0,
            'base_yield': base_yield,
            'temporal_modifier': temporal_modifier
        })

        new_state.spatial_interaction_detail = []
        exclusion_zone_width = 0
        ncz_width = 0

        yield_loss_from_competition = 0
        yield_gain_from_waterlogging = 0
        comp_yield_loss = 0
        water_yield_gain = 0
        water_extent = 0
        comp_extent = 0
        water_impact = 0
        comp_impact = 0

        if self.propagation_parameters.spatial_interactions:

            sis = self.propagation_parameters.spatial_interactions
            if not planted_crop.state.ncz_width:
                ncz_width = 0
            else:
                ncz_width = planted_crop.state.ncz_width

            if self.propagation_parameters.model_choice in {'RainfallBasedAnnualGM', 'ManualAnnualGM'}:
                first_rm = self.propagation_parameters.rainfall_based_annual_gm.first_relevant_month
                last_rm = self.propagation_parameters.rainfall_based_annual_gm.last_relevant_month
            else:
                first_rm = 5
                last_rm = 10

            first_relevant_month_index = sim.year_index * 12 + first_rm - 1
            # Uncomment line below to prevent months prior to planting being relevant.
#            first_relevant_month_index = max(first_relevant_month_index, planted_crop.planted_month)
            if sim.month < last_rm:
                GSR2Date = np.sum(sim.monthly_rainfall.flat[first_relevant_month_index:sim.month_index + 1])
                climate_mgr = ClimateManager.get_instance()
                average_rainfall = climate_mgr.get_monthly_average_rainfall()
                av_GSR2Date = np.sum(average_rainfall[first_rm - 1:sim.month])
                av_GSR = np.sum(average_rainfall[first_rm - 1:last_rm])
                if av_GSR2Date == 0:
                    gsr = av_GSR
                else:
                    gsr = av_GSR * GSR2Date / av_GSR2Date
            else:
                gsr = np.sum(sim.monthly_rainfall.flat[first_relevant_month_index:sim.month_index + 1])

            comp_impact, water_impact = sis.get_impact(gsr)

            if sim.current_secondary_installed_regime:
                plant_spacing = sim.current_secondary_installed_regime.get_regime_parameter('plantSpacing')
                if not plant_spacing:
                    raise ValueError("Need to be able to access the regime's plantSpacing parameter.")
            else:
                plant_spacing = 1

            crop_interface = Amount(0, gh.crop_interface_length)
            if sim.current_secondary_installed_regime:
                if sim.current_secondary_planted_crop:
                    crop_interface = sim.current_secondary_installed_regime.get_amount(gh.crop_interface_length)

            crop_area = planted_crop.get_amount(gh.ha)

            AGBM_unit = gh.tonnes_of_agbm
            BGBM_unit = gh.tonnes_of_bgbm
            if sim.current_secondary_planted_crop:
                BGBM = sim.current_secondary_planted_crop.get_amount(BGBM_unit)
                AGBM = sim.current_secondary_planted_crop.get_amount(AGBM_unit)
                if not BGBM:
                    BGBM = Amount(0, BGBM_unit)
                    AGBM = Amount(0, AGBM_unit)
            else:
                BGBM = Amount(0, BGBM_unit)
                AGBM = Amount(0, AGBM_unit)
            comp_extent, comp_yield_loss, water_extent, water_yield_gain = sis.get_raw_si_bounds(AGBM.number * 1000,
                                                                                                 BGBM.number * 1000,
                                                                                                 plant_spacing)

            spatial_interaction_detail.comp_extent = comp_extent
            spatial_interaction_detail.comp_yield_loss = comp_yield_loss  # Raw yield loss - not scaled.
            spatial_interaction_detail.water_extent = water_extent
            spatial_interaction_detail.water_yield_gain = water_yield_gain

            # Scale percentage numbers to [0, 1]
            comp_yield_loss /= 100
            water_yield_gain /= 100

            csir = sim.current_secondary_installed_regime
            exclusion_zone_width = 0
            if csir:
                reg_obj = csir.regime_object
                exclusion_zone_width = reg_obj.get_exclusion_zone_width()

            spatial_interaction_detail.exclusion_zone_width = exclusion_zone_width
            spatial_interaction_detail.ncz_width = ncz_width

            # Modify bounds based on the NCZ
            if comp_extent > (ncz_width + exclusion_zone_width) and comp_extent > 0:
                comp_yield_loss *= (comp_extent - ncz_width - exclusion_zone_width) / comp_extent
                comp_extent -= ncz_width + exclusion_zone_width
            else:
                comp_extent = 0
                comp_yield_loss = 0

            if water_extent > (ncz_width + exclusion_zone_width) and water_extent > 0:
                water_yield_gain *= (water_extent - ncz_width - exclusion_zone_width) / water_extent
                water_extent -= ncz_width + exclusion_zone_width
            else:
                water_extent = 0
                water_yield_gain = 0

            affected_extent = max(comp_extent, water_extent)

            # Must have +ve area.
            if affected_extent > 0 and crop_interface:
                affected_area_ha = crop_interface.number * affected_extent / 10000

                area_of_si_water_curve = water_yield_gain * water_impact * water_extent / 2
                area_of_si_comp_curve = comp_yield_loss * comp_impact * comp_extent / 2

                area_of_si_comp_above_100 = 0
                if (comp_yield_loss * comp_impact) > 1:
                    ext = comp_extent * (comp_yield_loss * comp_impact - 1) / (comp_yield_loss * comp_impact)
                    area_of_si_comp_above_100 = (comp_yield_loss * comp_impact - 1) * ext / 2

                normal_area_under_curve = 1 * affected_extent
                area_under_curve = normal_area_under_curve - area_of_si_comp_curve + area_of_si_water_curve + area_of_si_comp_above_100

                spatial_modifier = area_under_curve / normal_area_under_curve

                competition_si_component = (area_of_si_comp_curve - area_of_si_comp_above_100) / normal_area_under_curve
                waterlogging_si_component = area_of_si_water_curve / normal_area_under_curve

                affected_area_yield = affected_area_ha * base_yield * temporal_modifier * spatial_modifier

                yield_loss_from_competition = affected_area_ha * base_yield * temporal_modifier * competition_si_component
                yield_gain_from_waterlogging = affected_area_ha * base_yield * temporal_modifier * waterlogging_si_component

                lost_yield = affected_area_ha * base_yield * temporal_modifier - affected_area_yield

                # Total Yield comes from base * temporal yield
                # on main alley, + base * temporal * spatial on
                # affected area. Total Yield Per Ha comes from Total Yield / cropArea.
                total_yield_per_ha = ((crop_area.number - affected_area_ha)
                                      * base_yield * temporal_modifier + affected_area_yield) / crop_area.number

                # Therefore deduce spatial modifier:
                if base_yield == 0:
                    spatial_modifier = 1
                else:
                    spatial_modifier = total_yield_per_ha / base_yield / temporal_modifier

                if sim.month == 12:
                    a = 1
                    # relevant_rain_to_date = relevant_rain_to_date

        new_state['yield'] = base_yield * temporal_modifier * spatial_modifier
        new_state.yield_lost_to_competition_per_paddock = lost_yield
        new_state.yield_lost_to_only_competition_per_paddock = yield_loss_from_competition
        new_state.yield_gain_waterlogging_per_paddock = yield_gain_from_waterlogging
        new_state.waterlogging_extent_past_ncz = max(water_extent, 0)
        new_state.competition_extent_past_ncz = max(comp_extent, 0)
        new_state.water_impact = water_impact
        new_state.comp_impact = comp_impact
        new_state.comp_intensity_at_ncz = comp_yield_loss * comp_impact
        new_state.water_intensity_at_ncz = water_yield_gain * water_impact

        spatial_interaction_detail.ncz_width = ncz_width
        spatial_interaction_detail.exclusion_zone_width = exclusion_zone_width
        spatial_interaction_detail.base_yield = base_yield
        spatial_interaction_detail.temporal_modifier = temporal_modifier

        new_state.spatial_interaction_detail = spatial_interaction_detail


        # Now finish off with the fixed_yield propagation and products.
        # Now we have the spatial and temporal modifiers, we can apply them.
        if exists(self, '.propagation_parameters.fixed_yield_gm.propagation_parameters'):
            fixed_yield_state, fixed_yield_products = self.propagation_parameters.fixed_yield_gm.propagate_state(
                planted_crop, sim)
            new_state.fixed_yield_data.state = fixed_yield_state
            new_state.fixed_yield_data.spatial_modifier = spatial_modifier
            new_state.fixed_yield_data.temporal_modifier = temporal_modifier

            # Get the fixed yield products if there are any.
            if exists(self, '.propagation_parameters.fixed_yield_gm.propagation_parameters.products'):
                product_names = self.propagation_parameters.fixed_yield_gm.propagation_parameters.products.keys()
                for i in range(len(fixed_yield_products)):
                    # measurable = fixed_yield_products[i].unit.measurable
                    spatial_modifier_here = 1
                    temporal_modifier_here = 1
                    if self.propagation_parameters.fixed_yield_gm.propagation_parameters.products[
                        product_names[i]]["spatially_modified"]:
                        spatial_modifier_here = spatial_modifier
                    if self.propagation_parameters.fixed_yield_gm.propagation_parameters.products[
                        product_names[i]]["temporally_modified"]:
                        temporal_modifier_here = temporal_modifier
                    fixed_yield_products[i].number *= spatial_modifier_here * temporal_modifier_here
                product_rates = fixed_yield_products

        return new_state, product_rates

    def calculate_outputs(self, state=None):
        numerator_units = []
        denominator_units = []
        output_rates = []

        if self.propagation_parameters:
            if self.propagation_parameters.spatial_interactions:

                if self.propagation_parameters.spatial_interactions.use_competition \
                        or self.propagation_parameters.spatial_interactions.use_waterlogging:
                    numerator_units = aux.spatial_interaction_output_numerator_units
                    denominator_units = aux.spatial_interaction_output_denominator_units
                    output_rates = [Rate(0, nu, du) for nu, du in zip(numerator_units, denominator_units)]

            # TODO: revise the fixed yield delegate. No 'rate' in argument and no [])
            if hasattr(self.propagation_parameters, 'fixed_yield_gm_delegate'):
                fixed_yield_output_rates = self.propagation_parameters.fixed_yield_gm_delegate.calculate_outputs()
                numerator_units.extend([output_rate.unit for output_rate in fixed_yield_output_rates])
                denominator_units.extend([output_rate.denominator_unit for output_rate in fixed_yield_output_rates])
                output_rates.extend(fixed_yield_output_rates)

        if not output_rates:
            if len(denominator_units) != len(numerator_units):
                raise ValueError("AnnualGrowthModel needs the same number of numerator units as denominator units.")
            output_rates = [Rate(0, nu, du) for nu, du in zip(numerator_units, denominator_units)]

        if state is None:
            return output_rates

        # Put the values in the rates...

        # The calculateOutputs function should return a column of
        # nothing outputs if the state is empty.

        # calculateOutputs must be able to provide a column of nothing
        # outputs if the state that is passed is empty.

        if self.propagation_parameters:
            if self.propagation_parameters.spatial_interactions:
                if self.propagation_parameters.spatial_interactions.use_competition or \
                        self.propagation_parameters.spatial_interactions.use_waterlogging:

                    if not state:
                        state = DotWiz()
                        state.comp_impact = 0
                        state.spatial_interaction_detail = DotWiz()
                        state.spatial_interaction_detail.comp_yield_loss = 0
                        state.spatial_interaction_detail.comp_extent = 0
                        state.spatial_interaction_detail.water_yield_gain = 0
                        state.spatial_interaction_detail.water_extent = 0
                        state.spatial_interaction_detail.ncz_width = 0
                        state.spatial_interaction_detail.exclusion_zone_width = 0
                        state.spatial_interaction_detail.base_yield = 0
                        state.spatial_interaction_detail.temporal_modifier = 0
                        state.spatial_interaction_detail.pre_spatial_yield = 0
                        state.spatial_interaction_detail.potential_waterlogging_mitigation_intensity = 0
                        state.spatial_interaction_detail.potential_competition_intensity = 0
                        state.spatial_interaction_detail.scaled_waterlogging_mitigation_intensity = 0
                        state.spatial_interaction_detail.scaled_competition_intensity = 0

                    # Set number in output rates.
                    output_rates[0].number = state.spatial_interaction_detail.comp_extent
                    output_rates[1].number = state.comp_impact
                    output_rates[2].number = state.spatial_interaction_detail.comp_yield_loss
                    output_rates[3].number = state.spatial_interaction_detail.comp_yield_loss * state.comp_impact
                    output_rates[4].number = state.water_impact
                    output_rates[5].number = state.spatial_interaction_detail.water_yield_gain
                    output_rates[6].number = state.spatial_interaction_detail.water_yield_gain * state.water_impact
                    output_rates[7].number = state.spatial_interaction_detail.ncz_width
                    output_rates[8].number = state.spatial_interaction_detail.exclusion_zone_width
                    output_rates[9].number = state.spatial_interaction_detail.base_yield
                    output_rates[10].number = state.spatial_interaction_detail.base_yield * \
                                              state.spatial_interaction_detail.temporal_modifier

                    # outputs_column = np.zeros((11, 1))
                    #
                    # outputs_column[0, 0] = Rate(state.spatial_interaction_detail.comp_extent, numerator_units[0],
                    #                             denominator_units[0])
                    # outputs_column[1, 0] = Rate(state.comp_impact, numerator_units[1], denominator_units[1])
                    # outputs_column[2, 0] = Rate(state.spatial_interaction_detail.comp_yield_loss, numerator_units[2],
                    #                             denominator_units[2])
                    # outputs_column[3, 0] = Rate(state.spatial_interaction_detail.comp_yield_loss * state.comp_impact,
                    #                             numerator_units[3], denominator_units[3])
                    # outputs_column[4, 0] = Rate(state.water_impact, numerator_units[4], denominator_units[4])
                    # outputs_column[5, 0] = Rate(state.spatial_interaction_detail.water_yield_gain, numerator_units[5],
                    #                             denominator_units[5])
                    # outputs_column[6, 0] = Rate(state.spatial_interaction_detail.water_yield_gain * state.water_impact,
                    #                             numerator_units[6], denominator_units[6])
                    # outputs_column[7, 0] = Rate(state.spatial_interaction_detail.ncz_width, numerator_units[7],
                    #                             denominator_units[7])
                    # outputs_column[8, 0] = Rate(state.spatial_interaction_detail.exclusion_zone_width,
                    #                             numerator_units[8], denominator_units[8])
                    # outputs_column[9, 0] = Rate(state.spatial_interaction_detail.base_yield, numerator_units[9],
                    #                             denominator_units[9])
                    # outputs_column[10, 0] = Rate(
                    #     state.spatial_interaction_detail.base_yield * state.spatial_interaction_detail.temporal_modifier,
                    #     numerator_units[9], denominator_units[9])

                    for r in output_rates:
                        if np.isnan(r.number):
                            r.number = 0

            if hasattr(self.propagation_parameters, "fixed_yield_gm_delegate"):
                if self.propagation_parameters.fixed_yield_gm_delegate.propagation_parameters:

                    # We need the propagate state function to populate the
                    # fixedYieldData property. It needs state,
                    # spatialModifier and temporalModifier.

                    if not hasattr(state, "fixed_yield_data"):
                        # TODO: update calcualte_outputs in fixed yield gm to take no args.
                        fixed_yield_outputs = self.propagation_parameters.fixed_yield_gm_delegate.calculate_outputs()
                        spatial_modifier = 1
                        temporal_modifier = 1
                    else:
                        fixed_yield_outputs = self.propagation_parameters.fixed_yield_gm_delegate.calculate_outputs(
                            state.fixed_yield_data.state
                        )
                        # If the output should be spatially or temporally
                        # modified, apply those modifiers if they exist.

                        # Get the actual spatial and temporal modifiers at this
                        # point.
                        spatial_modifier = state.fixed_yield_data.spatial_modifier
                        temporal_modifier = state.fixed_yield_data.temporal_modifier

                    # How do we match the outputs to the outputRates?
                    # I think we can assume that they're in order.

                    output_names = list(
                        self.propagation_parameters.fixed_yield_gm_delegate.propagation_parameters.outputs.keys())

                    for i in range(len(fixed_yield_outputs)):
                        spatial_modifier_here = 1
                        temporal_modifier_here = 1
                        if self.propagation_parameters.fixed_yield_gm_delegate.propagation_parameters.outputs[
                            output_names[i]
                        ].spatially_modified:
                            spatial_modifier_here = spatial_modifier
                        if self.propagation_parameters.fixed_yield_gm_delegate.propagation_parameters.outputs[
                            output_names[i]
                        ].temporally_modified:
                            temporal_modifier_here = temporal_modifier
                        fixed_yield_outputs[i].number = (
                                fixed_yield_outputs[i].number * spatial_modifier_here * temporal_modifier_here
                        )

                    output_rates = np.vstack((output_rates, fixed_yield_outputs))

        return output_rates

    # We get the growthModelOutputRates and Units from the calculateOutputs function.
    # @property
    # def growth_model_output_units(self):
    #     return self.calculate_outputs([], 'unit')
    #
    # @property
    # def growth_model_output_rates(self):
    #     return self.calculate_outputs([], 'rate')


    def transition_function_planting(self, planted_crop, sim):
        output_products = []
        event_outputs = []

        # Return list of products and outputs if called with no
        # arguments.
        # In the case of planting, not products or outputs are
        # produced.
        if not planted_crop and not sim:
            return output_products, event_outputs

        # This line creates the data that will be used for the yield in
        # the manualAnnual submodel.
        if self.propagation_parameters.model_choice == "ManualAnnualGM":
            self.propagation_parameters.manual_annual_gm.sample_distribution()

        new_state = DotWiz()
        new_state['yield'] = 0
        new_state.ncz_width = []
        new_state.yield_lost_to_competition_per_paddock = 0
        new_state.yield_lost_to_only_competition_per_paddock = 0
        new_state.yield_gain_waterlogging_per_paddock = 0
        new_state.waterlogging_extent_past_ncz = 0
        new_state.competition_extent_past_ncz = 0
        new_state.water_impact = 0
        new_state.comp_impact = 0
        new_state.comp_intensity_at_ncz = 0
        new_state.water_intensity_at_ncz = 0
        new_state.spatial_interaction_detail = []

        # Check for spatialModifiers in propagationParameters.
        if "spatial_interactions" in self.propagation_parameters:
            sis = self.propagation_parameters.spatial_interactions
            if sis:
                # Then we have a spatial interactions definition.
                if sis.use_ncz:

                    if sis.ncz_choice == "Fixed Width":
                        ncz_width = sis.ncz_fixed_width

                    elif sis.ncz_choice == "Optimised":

                        optimised_params = sis.ncz_optimised_parameters
                        if optimised_params and optimised_params.is_valid:
                            # Then use the NCZ parameters to
                            # calculate the width of the NCZ.
                            ncz_width = self.calculate_ncz_optimised_width(sis, planted_crop, sim)
                        else:
                            ncz_width = 0
                    else:
                        ncz_width = 0

                    new_state.ncz_width = ncz_width

                spatial_interaction_detail = DotWiz()
                spatial_interaction_detail.comp_extent = 0
                spatial_interaction_detail.comp_yield_loss = 0
                spatial_interaction_detail.water_extent = 0
                spatial_interaction_detail.water_yield_gain = 0
                spatial_interaction_detail.exclusion_zone_width = 0
                spatial_interaction_detail.ncz_width = 0
                spatial_interaction_detail.base_yield = 0
                spatial_interaction_detail.temporal_modifier = 0
                spatial_interaction_detail.potential_waterlogging_mitigation_intensity = 0
                spatial_interaction_detail.potential_competition_intensity = 0

                new_state.spatial_interaction_detail = spatial_interaction_detail

        if "fixed_yield_gm" in self.propagation_parameters:
            if "propagation_parameters" in self.propagation_parameters.fixed_yield_gm:
                fixed_yield_state, _ = self.propagation_parameters.fixed_yield_gm.propagate_state(
                    planted_crop, sim
                )
                new_state.fixed_yield_data.state = fixed_yield_state
                raise (NotImplementedError)
                # TODO: Figure out why spatial modifier and temporal modifier are not defined.
        #            new_state.fixed_yield_data.spatial_modifier = spatial_modifier
        #            new_state.fixed_yield_data.temporal_modifier = temporal_modifier

        planted_crop.state = new_state

        return output_products, event_outputs

    def transition_function_harvesting(self, planted_crop, sim):

        # Return list of products and outputs if called with no arguments.
        output_products = [Rate(0, num_unit, den_unit) for num_unit, den_unit in
                           zip(aux.harvest_products_numerator_units,
                               aux.harvest_products_denominator_units)]
        event_outputs = [Rate(0, num_unit, den_unit) for num_unit, den_unit in
                         zip(aux.harvest_event_outputs_numerator_units,
                             aux.harvest_event_outputs_denominator_units)]

        if not planted_crop and not sim:
            return output_products, event_outputs

        # Yield comes straight from state.
        output_products[0].number = planted_crop.state['yield']

        # Want an event output which is the income lost to competition.
        # Event outputs are ncz_area, competition_cost, and opportunity_cost.
        competition_cost = 0
        ncz_area = 0

        # Get grain price
        denominator_unit = gh.paddock
        numerator_unit = gh.tonnes_of_yield
        pm = planted_crop.crop_object.get_product_price_model(numerator_unit)
        grain_price = sim.get_price(pm)

        if "spatial_interactions" in self.propagation_parameters:
            sis = self.propagation_parameters.spatial_interactions
            if sis.use_competition:
                # Set competition cost
                competition_cost = Rate(
                    planted_crop.state.yield_lost_to_competition_per_paddock, numerator_unit, denominator_unit
                ) * grain_price

            if sis.use_ncz:
                crop_interface_unit = gh.crop_interface_length
                crop_interface = Amount(0, crop_interface_unit)
                if not sim.current_secondary_installed_regime:
                    crop_interface = sim.current_secondary_installed_regime.get_amount(crop_interface_unit)

                if crop_interface:
                    # Set ncz area
                    ncz_area = crop_interface.number * planted_crop.state.ncz_width / 10000

        # Calculate profit so far without competition
        profit_so_far = planted_crop.profit(planted_crop.planted_month, sim.month_index, False)
        open_paddock_yield = (
                planted_crop.state.spatial_interaction_detail.base_yield
                * planted_crop.state.spatial_interaction_detail.temporal_modifier
        )

        # Calculate area for primary and secondary regimes
        regime_area_unit = gh.ha
        primary_area = sim.current_primary_installed_regime.get_amount(regime_area_unit).number
        secondary_area = (
            0
            if not sim.current_secondary_installed_regime
            else sim.current_secondary_installed_regime.get_amount(regime_area_unit).number
        )

        # Update profit_so_far without considering competition
        profit_so_far += open_paddock_yield * primary_area * grain_price.number

        # Calculate cost using CostItem class
        harvesting_cost_price_models = planted_crop.crop_object.get_cost_price_models('Harvesting')
        cost_items = []
        total_cost = 0
        for pm in harvesting_cost_price_models:
            this_event_cost_item = CostItem(
                "Harvesting", pm, planted_crop, sim, event_outputs, output_products
            )
            cost_items.append(this_event_cost_item)
            total_cost += this_event_cost_item.cost.number

        profit_so_far -= total_cost

        # Calculate non-belt profit per hectare
        profit_per_hectare = profit_so_far / primary_area

        # Set opportunity cost
        opportunity_cost = (ncz_area + secondary_area) * profit_per_hectare + competition_cost.number

        event_outputs[0].number = ncz_area
        event_outputs[1].number = competition_cost.number
        event_outputs[2].number = opportunity_cost

        return output_products, event_outputs

    # def crop_name_has_changed(self, previous_name, new_name):
    #     # Need to update any temporal interaction names.
    #     # Could also go through the list of triggers.
    #     # temporalModifiers are a list of tuples with elements of the form
    #     # (['CropName'], [modifierPercentage])
    #     if self.propagation_parameters:
    #         if self.propagation_parameters.temporal_modifiers:
    #             for i in range(len(self.propagation_parameters.temporal_modifiers)):
    #                 if self.propagation_parameters.temporal_modifiers[i][0] == previous_name:
    #                     self.propagation_parameters.temporal_modifiers[i][0] = new_name

    # Checks that the class is right and things aren't empty
    def gm_is_valid(self):
        return isinstance(self, AnnualGrowthModel)

    # Checks that the parameters are consistent and ready to go!
    # Note, this should really check quite a bit more. At least that
    # all the fields exist and are of the correct type.
    def gm_is_ready(self):
        ready = self.gm_is_valid()
        if not ready or self.propagation_parameters is None:
            ready = False
        return ready

    def calculate_ncz_optimised_width(self, sis, planted_crop, sim):
        optimised_params = sis.ncz_optimised_parameters

        if sim.current_secondary_installed_regime is None:
            return 0

        if self.propagation_parameters.model_choice not in ['RainfallBasedAnnualGM', 'ManualAnnualGM']:
            return 0

        if optimised_params is not None and optimised_params.is_valid:
            if sim.month_index - 1 < optimised_params.pre_seeding_rainfall_months:
                climate_mgr = ClimateManager.get_instance()
                average_rainfall = climate_mgr.get_monthly_average_rainfall()
                if sim.month - 1 > optimised_params.pre_seeding_rainfall_months:
                    av_psr = sum(
                        average_rainfall[sim.month - 1 - optimised_params.pre_seeding_rainfall_months: sim.month - 1])
                else:
                    av_rain_x2 = average_rainfall * 2
                    av_psr = sum(av_rain_x2[
                                 12 + sim.month - 1 - optimised_params.pre_seeding_rainfall_months: 12 + sim.month - 1])
                psr = av_psr
            else:
                psr = sum(sim.monthly_rainfall.flat[
                          sim.month_index - optimised_params.pre_seeding_rainfall_months: sim.month_index])

            p = [optimised_params.poly_a, optimised_params.poly_b, optimised_params.poly_c]
            psr_est_yield = np.polyval(p, psr)

            est_yield = psr_est_yield * optimised_params.polynomial_predictive_capacity + \
                        optimised_params.long_term_average_yield * (1 - optimised_params.polynomial_predictive_capacity)

            if est_yield == 0:
                return 0

            yield_price = sim.product_price_table[planted_crop.crop_object.name][0][sim.year]

            if yield_price.number == 0:
                return 0

            income = yield_price.number * est_yield

            this_regimes_plants = planted_crop.parent_regime.planted_crops
            cum_costs = 0
            same_crop_count = 0
            area_unit = gh.ha

            for trp_ix, trp in enumerate(this_regimes_plants[:-1]):
                if planted_crop.crop_name == trp.crop_name:
                    hectares = planted_crop.parent_regime.get_amount(area_unit, trp.planted_month)
                    if hectares is None:
                        hectares = Amount(100, area_unit)

                    per_ha_costs = trp.costs(trp.planted_month, trp.destroyed_month, 0) / hectares.number
                    cum_costs += per_ha_costs
                    same_crop_count += 1

            if same_crop_count == 0:
                cost = optimised_params.long_term_average_costs
            else:
                cost = cum_costs / same_crop_count

            ratio = cost / income

            if not sim.current_secondary_planted_crop:
                agbmr = Amount(0, gh.tonnes_of_agbm)
                bgbmr = Amount(0, gh.tonnes_of_bgbm)
            else:
                agbmr = sim.current_secondary_planted_crop.get_amount(gh.tonnes_of_agbm)
                bgbmr = sim.current_secondary_planted_crop.get_amount(gh.tonnes_of_bgbm)

                if agbmr is None:
                    agbmr = Amount(0, gh.tonnes_of_agbm)
                    bgbmr = Amount(0, gh.tonnes_of_bgbm)

            plant_spacing = sim.current_secondary_installed_regime.get_regime_parameter('plantSpacing')
            if plant_spacing is None:
                raise ValueError("Need to be able to access the regime's plantSpacing parameter.")

            climate_mgr = ClimateManager.get_instance()
            average_rainfall = climate_mgr.get_monthly_average_rainfall()

            first_rm = self.propagation_parameters.rainfall_based_annual_gm.first_relevant_month
            last_rm = self.propagation_parameters.rainfall_based_annual_gm.last_relevant_month

            av_gsr = sum(average_rainfall[first_rm - 1:last_rm])

            if sim.month - 1 > optimised_params.pre_seeding_rainfall_months:
                av_psr = sum(
                    average_rainfall[sim.month - 1 - optimised_params.pre_seeding_rainfall_months:sim.month - 1])
            else:
                av_rain_x2 = average_rainfall * 2
                av_psr = sum(
                    av_rain_x2[12 + sim.month - 1 - optimised_params.pre_seeding_rainfall_months:12 + sim.month - 1])

            if av_psr == 0:
                est_gsr = av_gsr
            else:
                est_gsr = av_gsr * psr / av_psr

            comp_impact, _ = sis.get_impact(est_gsr)

            comp_extent, comp_yield_loss, _, _ = sis.get_raw_si_bounds(agbmr.number * 1000, bgbmr.number * 1000,
                                                                       plant_spacing)

            break_even_cropping_dist = sis.calculate_break_even_cropping_distance(comp_extent, comp_yield_loss,
                                                                                  comp_impact, ratio)

            csir = sim.current_secondary_installed_regime
            if csir:
                reg_obj = csir.regime_object
                exclusion_zone_width = reg_obj.get_exclusion_zone_width

                if math.isnan(break_even_cropping_dist):
                    break_even_cropping_dist = comp_extent + 0.5 - exclusion_zone_width

                if break_even_cropping_dist > exclusion_zone_width:
                    ncz_width = math.floor((break_even_cropping_dist - exclusion_zone_width) * 2) / 2
                else:
                    ncz_width = 0
            else:
                ncz_width = 0

        else:
            ncz_width = 0

        return ncz_width
