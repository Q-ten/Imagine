from dotwiz import DotWiz

from imagine.events.imagine_event import ImagineEvent
from imagine.events.imagine_event_status import ImagineEventStatus
import imagine.core.global_helpers as gh


def make_annual_gm_imagine_events():
    # All units for the prices will be in dollars.

    # Set up the planting event
    # IES args: origin, cropDefinitionLocked, deferredToRegime, deferredToRegimeLocked, regimeRedefinable, regimeRedefinableLocked
    # The annual growth model defers to regime and leaves it at that.
    status = ImagineEventStatus('core', True, True, True, False, True)
    initial_events = [ImagineEvent('Planting', status)]

    # There are no 'regular' events.
    regular_events = []

    # Set up the harvest event
    status = ImagineEventStatus('core', True, True, True, False, True)
    destruction_events = [ImagineEvent('Harvesting', status)]

    return initial_events, regular_events, destruction_events


# def _make_annual_gm_price_models():
#     # All units for the prices will be in dollars.
#     # Note: If FixedYieldGrowthModel is used as a sub model, then that submodel defines the product price models.
#     product_price_models = [PriceModel('Yield Income', dollars, tonnes_of_yield)]
#     cost_price_models = [
#         PriceModel('Planting', dollars, ha, True),
#         PriceModel('Harvesting', dollars, ha, True),
#     ]
#     return product_price_models, cost_price_models

# def make_annual_gm_price_rates():
#     # All units for the prices will be in dollars.
#     # Note: If FixedYieldGrowthModel is used as a sub model, then that submodel defines the product price models.
#     product_price_rates = DotWiz()
#     product_price_rates['Yield Income'] = gh.dollars_per_tonne_of_yield
#
#     cost_price_rates = DotWiz()
#     cost_price_rates['Planting'] = gh.dollars_per_ha
#     cost_price_rates["Harvesting"] = gh.dollars_per_ha
#
#     return product_price_rates, cost_price_rates


spatial_interaction_output_numerator_units = [
    gh.root_mass_extent,
    gh.competition_scale_factor,
    gh.competition_at_tree_raw_dl,
    gh.competition_at_tree_scaled_sl,
    gh.wlm_scale_factor,
    gh.wlm_at_tree_raw_dl,
    gh.wlm_at_tree_scaled_sl,
    gh.ncz_width,
    gh.exclusion_zone_width,
    gh.base_yield,
    gh.temporally_modified_yield
]

spatial_interaction_output_denominator_units = [
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.unity,
    gh.ha,
    gh.ha
]

# No Planting transition function outputs

# Harvest transition function
harvest_products_numerator_units = [
    gh.tonne_of_yield
]
harvest_products_denominator_units = [
    gh.ha
]
harvest_event_outputs_numerator_units = [
    gh.ncz_area,
    gh.competition_income_loss,
    gh.belt_opportunity_cost
]
harvest_event_outputs_denominator_units = [
    gh.unity,
    gh.unity,
    gh.unity
]
