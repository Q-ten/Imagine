from imagine.crop.growth_model import GrowthModel
from imagine.core.rate import Rate
from imagine.core.unit import Unit
from imagine.core.price_model import PriceModel
from imagine.events.imagine_event import ImagineEvent, ImagineEventStatus
from imagine.util.absorb_fields import absorb_fields


def _make_ab_gompertz_product_price_models():
    # All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar')

    # Set up the biomass income price model
    denominator_unit = Unit('', 'Harvested Biomass', 'Tonne')
    p_p_ms = [PriceModel('Biomass Income', unit, denominator_unit)]

    # The sequestered carbon price model should be the last in the list.
    denominator_unit = Unit('', 'Sequestered Carbon', 'Tonne')
    p_p_ms.append(PriceModel('Sequestered Carbon', unit, denominator_unit))

    return p_p_ms


def _make_ab_gompertz_imagine_events():
    # All units for the prices will be in dollars.
    unit = Unit('', 'Money', 'Dollar');

    # Set up the planting event
    status = ImagineEventStatus('core', True, True, True, False, True)

    # Price is 'per Tree'
    denominator_unit = Unit('', 'Tree', 'Unit')
    cost_price_model = PriceModel('Planting', unit, denominator_unit, True)
    initial_events = ImagineEvent('Planting', status, cost_price_model)

    # Set up the coppice event
    status = ImagineEventStatus('core', True, True, True, True, True)

    # Cost is 'per Tree' by default. But it could be given per km of Belts or
    # Rows.
    denominator_unit = Unit('', 'Tree', 'Unit')
    cost_price_model = PriceModel('Coppice Harvest', unit, denominator_unit, True)
    regular_events = ImagineEvent('Coppice Harvesting', status, cost_price_model)

    # Set up the destructive harvest event
    status = ImagineEventStatus('core', True, True, True, False, True)

    # Cost is 'per Tree' by default. But it could be given per km of Belts or
    # Rows.
    denominator_unit = Unit('', 'Tree', 'Unit')
    cost_price_model = PriceModel('Destructive Harvest', unit, denominator_unit, True)
    destruction_events = ImagineEvent('Destructive Harvesting', status, cost_price_model)

    return initial_events, regular_events, destruction_events


class ABGompertzGrowthModel(GrowthModel):
    # This is the implementaton of the AB-Gompertz Growth Model.
    #
    # This is a concrete subclass of the Abstract GrowthModelDelegate class.
    #
    # The AB-Gompertz model is designed for coppiced woody crops, such as an
    # Oil Mallee.
    # The model tracks growth in both above and below ground biomass, with the
    # rate of growth of each dependent on the relative size of above to below
    # ground biomass.
    # The Gompertz model is a growth function based on the idea of exponetial
    # growth, with limited resources.
    # This model extends that idea by additionally adjusting the internal
    # growth rate according to the ratio of the above to below ground biomass
    # and the available rainfall.
    model_name = 'AB-Gompertz'
    supported_categories = ['Coppice Tree Crop']
    state_description = ['Above-ground biomass', 'Below-ground Biomass']
    growth_model_initial_events, growth_model_regular_events, growth_model_destruction_events = \
        _make_ab_gompertz_imagine_events()

    def __init__(self, category, gm=None):
        super().__init__(gm)
        self.propagation_parameters = None
        self.planting_parameters = None
        self.coppice_parameters = None
        self.destructive_harvest_parameters = None
        self.setup_parameters = None
        self.private_yield_unit = None
        self.private_product_price_models = _make_ab_gompertz_product_price_models
        self.growth_model_financial_events = []

    # Need to check if it has a field productPriceModels and if so,
    # set the newObj's privateProductPriceModels.
    def loadobj(self, obj):
        pass

    def load_gm(self, d):
        # TODO: Check if this is sufficient. We may need to import each set of fields with more care.
        fields = ["propagation_parameters",
                  "planting_parameters",
                  "coppice_parameters",
                  "destructive_harvest_parameters",
                  "setup_parameters"]
        absorb_fields(self, d, fields)

    # This function propagates the state over one month. This should be
    # set up as appropriate to the concrete subclass.
    def propagate_state(self, planted_crop, sim):
        pass

    # This function is responsible for setting up all the parameters
    # particular to the concrete subclass. It will probably launch a
    # GUI which will be passed the GrowthModelDelegate and the GUI will
    # alter the pubilc parameters that are available to it when it is
    # saved. No need to return the GMD since it is a handle class.
    def setup_growth_model(self, crop_name):
        pass

    # This function renders a display of the growthModelDelegate's
    # parameters as a kind of summary. This is used in the crop wizard
    # and displays a summary of the saved growth model to be viewed
    # before and after the user enters the main GUI (launched via
    # setupGrowthModel above). This function should plot the summary on
    # ax, an axes object.
    def render_growth_model(self, ax):
        pass

    # This function calculates the growthModel outputs based on the
    # state. Outputs are given in term of Rates in a similar fashion to
    # the products.
    # It throws an error if the units in the outputColumn don't match
    # the units provided by the growthModel.
    def calculate_outputs(self, state, unit_or_rate):
        pass

    # We get the growthModelOutputRates and Units from the
    # calculateOutputs function.
    @property
    def growth_model_output_units(self):
        pass

    # We get the growthModelOutputRates and Units from the
    # calculateOutputs function.
    @property
    def growth_model_output_rates(self):
        pass

    # productPriceModels is a dependent property because we might want
    # to include or exclude the Sequestered Carbon price model. We're assuming
    # the sequestered carbon price model is the last one.
    @property
    def product_price_models(self):
        pass

    # Basically an inverse of the get method.
    @property
    def yield_unit(self):
        pass

    # As well as these core methods, you need to implement methods for
    # each supported ImagineEvent of the form
    # outputProducts = transitonFunction_EVENTNAME(gmDel, ...)
    # where EVENTNAME happens to be the name of the event that is supported.
    def transition_function_planting(self, planted_crop, sim):
        pass

    # The coppice function is quite simple. The parameters tell us how
    # much is left over. The amount harvested is then how much there
    # was to start - how much is left over.
    def transition_function_coppice_harvesting(self, planted_crop, sim):
        pass

    # When we do destructive harvesting, the whole crop goes.
    # Otherwise, very similar to coppice.
    def transition_function_destructive_harvesting(self, planted_crop, sim):
        pass

    # Checks that the class is right and things aren't empty
    def gmd_is_valid(self):
        pass

    # Checks that the parameters are consistent and ready to go!
    # Note, this should really check quite a bit more. At least that
    # all the fields exist and are of the correct type.
    def gmd_is_ready(self):
        pass

    def crop_name_has_changed(self, previous_name, new_name):
        pass


