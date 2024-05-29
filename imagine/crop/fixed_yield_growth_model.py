from dotwiz import DotWiz

from imagine.core.rate import Rate
from imagine.crop.growth_model import GrowthModel, make_growth_model_units
from imagine.events.imagine_event import ImagineEvent
from imagine.events.imagine_event_status import ImagineEventStatus
from imagine.util.absorb_fields import absorb_fields
import imagine.core.global_helpers as gh
from imagine.util.load_series_data import load_series_data


def make_fixed_yield_imagine_events(category):
    if category.name == "Coppice Tree Crop":
        status = ImagineEventStatus('core', True, True, True, False, True)
        initial_events = [ImagineEvent('Planting', status)]
        regular_events = []
        status = ImagineEventStatus('core', True, True, True, False, True)
        destruction_events = [ImagineEvent('Destructive Harvesting', status)]
        return initial_events, regular_events, destruction_events
    else:
        status = ImagineEventStatus('core', True, True, True, False, True)
        initial_events = [ImagineEvent('Planting', status)]
        regular_events = []
        status = ImagineEventStatus('core', True, True, True, False, True)
        destruction_events = [ImagineEvent('Harvesting', status)]
        return initial_events, regular_events, destruction_events


class FixedYieldGrowthModel(GrowthModel):
    model_name = 'Fixed Yield'
    supported_categories = ['Annual', 'Coppice Tree Crop']
    state_description = []

    def __init__(self, category, d=None, modifier_aware=False):
        super().__init__()
        self._growth_model_initial_events, self._growth_model_regular_events, self._growth_model_destruction_events = \
            make_fixed_yield_imagine_events(category)
        self._growth_model_financial_events = []
        if category.name == "Coppice Tree Crop":
            self.transition_function_destructive_harvesting = self.transition_function_harvesting
        self.product_price_models = []
        self.internal_price_model_list = []
        self.propagation_parameters = None
        self.private_modifier_aware = modifier_aware

        self.units = make_growth_model_units()
        self.output_rates = []
        self.propagation_product_rates = []

        if d is not None:
            self.load_gm(d)

    def load_gm(self, d):
        # crop config defines growth_model_parameters. That is provided here as d.
        # d is equivalent to self.propagation_parameters, but we construct propagation_parameters more carefully.
        # It's not necessarily a direct assignment.
        # There are some direct assignments though. Absorb those fields.
        prop_params = DotWiz()

        simple_fields = ["products",
                         "outputs"
                         ]
        absorb_fields(prop_params, d, simple_fields)
        for prod in prop_params.products:
            if "series" in prod:
                pass
#                prod.series = load_series_data(prod.series)
#         for output in prop_params.outputs:
#             if "series" in output:
#                 output.series = load_series_data(output.series)

        self.propagation_parameters = prop_params

        # We don't have a fixed set of outputs like we might with other growth models.
        # But the configuration does set the units. So run through the configuration and generate the units.
        self.make_units()


    @property
    def modifier_aware(self):
        return self.private_modifier_aware

    def propagate_state(self, planted_crop, sim):
        """
        This function propagates the state over one month. This should be
        set up as appropriate to the concrete subclass.
        Need to return the state - not set it in plantedCrop as we have
        to change the month day before we set the state.

        In the FixedYieldGrowthModel the products are produced in the
        propagation (here) rather than in a harvest function because
        there is no way to know beforehand what events will be needed for
        a particular crop. It would be nice if this class could be used
        for all cropCategories.

        Products are simply all the non-zero entries in the product
        series.
        Outputs are returned in full each month.

        :param planted_crop: The planted crop object
        :param sim: The simulation object
        :return: A tuple containing the new state and product rates
        """

        if not self.propagation_parameters:
            return [], []

        if not sim and not planted_crop:
            return [], self.propagation_product_rates

        if not sim and not planted_crop:
            return [], []

        outputs_col = []
        product_rates = []

        # Outputs and products are defined in the propagation parameters as objects with fields:
        # unit:             The numerator unit. Like tonnes of wheat, or tree height in m.
        # denominator_unit: The denominator unit for the output or product. Is it per something, like per ha or per dse?
        # series:           An 1D array of numbers by month to represent the product or output.
        # index_type:       "absolute" or "relative". If not absolute, then relative.
        #                   index type sets whether the series starts at beginning of the sim, or whether
        #                   it starts when the crop is planted.
        #
        if 'outputs' in self.propagation_parameters:
            for ix, (output_name, output_data) in enumerate(self.propagation_parameters.outputs.items()):
                denominator_unit = self.units.outputs.denominator_units[ix]
                numerator_unit = self.units.outputs.numerator_units[ix]
                series_index = sim.month_index if output_data.index_type == "absolute" else sim.month - planted_crop.plant_month
                outputs_col.append(Rate(output_data.series[series_index], numerator_unit, denominator_unit))

        if 'products' in self.propagation_parameters:
            for ix, (product_name, product_data) in enumerate(self.propagation_parameters.products.items()):
                denominator_unit = self.units.propagation_products.denominator_units[ix]
                numerator_unit = self.units.propagation_products.numerator_units[ix]
                series_index = sim.month_index if product_data.index_type == "absolute" else sim.month - planted_crop.plant_month
                product_rates.append(Rate(product_data.series[series_index], numerator_unit, denominator_unit))

#        return outputs_col, [rate for rate in product_rates if rate.number > 0]
        return outputs_col, product_rates

    def calculate_outputs(self, state=None):
        """
        This function calculates the growthModel outputs based on the
        state. Outputs are given in term of Rates in a similar fashion to
        the products.
        It throws an error if the units in the outputColumn don't match
        the units provided by the growthModel.

        If state is empty then calculateOutputs returns the units or rates
        (with 0 as the number) that this function would return when it had a state.

        For the FixedYieldGrowthModel, propagate_state sets the state column to the output rates
        so there is no calculation necessary.

        :param state: The state of the growth model
        :return: The calculated outputs
        """
        output_rates = []

        if not self.propagation_parameters:
            return output_rates

        if 'outputs' in self.propagation_parameters:
            if state is None:
                return self.output_rates
            else:
                output_rates = state

        return output_rates

    def transition_function_planting(self, planted_crop=None, sim=None):
        output_products = []
        event_outputs = []
        new_state = []
        if planted_crop is not None:
            if 'outputs' in self.propagation_parameters:
                for ix, (output_name, output_data) in enumerate(self.propagation_parameters.outputs.items()):
                    denominator_unit = self.units.outputs.denominator_units[ix]
                    numerator_unit = self.units.outputs.numerator_units[ix]
                    series_index = sim.month_index if output_data.index_type == "absolute" else sim.month - planted_crop.plant_month
                    new_state.append(Rate(output_data.series[series_index], numerator_unit, denominator_unit))
            planted_crop.state = new_state
        return output_products, event_outputs

    def transition_function_harvesting(self, planted_crop=None, sim=None):
        output_products = []
        event_outputs = []
        return output_products, event_outputs

    def gm_is_valid(self):
        return isinstance(self, FixedYieldGrowthModel)

    def gm_is_ready(self):
        ready = self.is_valid()
        ready = ready and (hasattr(self.propagation_parameters, 'outputs') or
                           hasattr(self.propagation_parameters, 'products'))
        for output_name, output_data in self.propagation_parameters.outputs.items():
            ready = ready and all([
                hasattr(output_data, 'unit'),
                hasattr(output_data, 'denominator_unit'),
                hasattr(output_data, 'series'),
                hasattr(output_data, 'index_type')
            ])
        for product_name, product_data in self.propagation_parameters.products.items():
            ready = ready and all([
                hasattr(product_data, 'unit'),
                hasattr(product_data, 'denominator_unit'),
                hasattr(product_data, 'series'),
                hasattr(product_data, 'index_type')
            ])

        return ready

    def make_units(self):
        # The fixed yield growth model doesn't use transition functions and so
        # cannot generate event_outputs or products from the transition functions.
        # All the outputs are generated in propagate state from configuration.
        # This function runs through the configuration to determine the lists of products and outputs.
        units = self.units
        prop_params = self.propagation_parameters
        for output_name, output_data in prop_params.outputs.items():
            denominator_unit = getattr(gh, output_data.denominator_unit, None)
            numerator_unit = getattr(gh, output_data.unit, None)
            if numerator_unit is None or denominator_unit is None:
                raise ValueError(f"Units provided for output in FixedYieldGrowthModel "
                                 f"configuration are not found or invalid: {output_name}\n{output_data}")
            units.outputs.denominator_units.append(denominator_unit)
            units.outputs.numerator_units.append(numerator_unit)
            self.output_rates.append(Rate(0, numerator_unit, denominator_unit))

        for product_name, product_data in prop_params.products.items():
            denominator_unit = getattr(gh, product_data.denominator_unit, None)
            numerator_unit = getattr(gh, product_data.unit, None)

            if numerator_unit is None or denominator_unit is None:
                raise ValueError(f"Units provided for product in FixedYieldGrowthModel "
                                 f"configuration are not found or invalid: {product_name}\n{product_data}")
            units.propagation_products.denominator_units.append(denominator_unit)
            units.propagation_products.numerator_units.append(numerator_unit)
            self.propagation_product_rates.append(Rate(0, numerator_unit, denominator_unit))






