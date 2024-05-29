from imagine.crop.growth_model import make_growth_model_units
from imagine.events.imagine_event import ImagineEvent
from imagine.events.imagine_event_status import ImagineEventStatus
import imagine.core.global_helpers as gh


def make_sheltered_pasture_imagine_events():
    """
    This function makes the triggers for the Sheltered Pasture events.
    """
    # IES args: origin, cropDefinitionLocked, deferredToRegime, deferredToRegimeLocked, regimeRedefinable, regimeRedefinableLocked

    # Set up the planting event (called Establishment)
    status = ImagineEventStatus('core', True, True, True, False, True)
    initial_events = [ImagineEvent('Establishment', status)]

    # Regular events are 'Shearing', 'Sheep Sales', and 'Feeding'.
    status = ImagineEventStatus('core', True, False, True, False, True)
    regular_events = [ImagineEvent('Shearing', status)]

    status = ImagineEventStatus('core', True, False, True, False, True)
    regular_events.append(ImagineEvent('Sheep Sales', status))

    status = ImagineEventStatus('core', True, False, True, False, True)
    regular_events.append(ImagineEvent('Feeding', status))

    # Only a token destruction event
    status = ImagineEventStatus('core', True, True, True, False, True)
    destruction_events = [ImagineEvent('Destruction', status)]

    return initial_events, regular_events, destruction_events


units = make_growth_model_units()

units.outputs.numerator_units = [gh.foo, gh.foo_shortfall, gh.shelter_productivity_bump]
units.outputs.denominator_units = [gh.ha, gh.unity, gh.unity]

units.event_outputs.numerator_units.establishment = []
units.event_outputs.denominator_units.establishment = []
units.event_outputs.numerator_units.shearing = []
units.event_outputs.denominator_units.shearing = []
units.event_outputs.numerator_units.feeding = [gh.fodder]
units.event_outputs.denominator_units.feeding = [gh.dse]
units.event_outputs.numerator_units.sheep_sales = []
units.event_outputs.denominator_units.sheep_sales = []

units.products.numerator_units.establishment = []
units.products.denominator_units.establishment = []
units.products.numerator_units.shearing = [gh.wool_income]
units.products.denominator_units.shearing = [gh.dse]
units.products.numerator_units.feeding = []
units.products.denominator_units.feeding = []
units.products.numerator_units.sheep_sales = [gh.meat_income]
units.products.denominator_units.sheep_sales = [gh.dse]

