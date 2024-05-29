import numpy as np

from imagine.core import ImagineObject
from imagine.core.rate import Rate
from imagine.crop.growth_model import GrowthModel
import imagine.crop.sheltered_pasture_growth_model_aux as aux
from imagine.events.condition_syntax import condition_helpers
from imagine.util.absorb_fields import absorb_fields
from imagine.util.get_month_index_from_month import get_month_index_from_month
import imagine.core.global_helpers as gh
from dotwiz import DotWiz
import copy
from imagine.util.resolve_imagine_path import resolve_imagine_path
from imagine.util.import_script_as_module import import_script_as_module


class ShelteredPastureGrowthModel(GrowthModel):
    """
    This is the implementation of a concrete ShelteredPastureGrowthModel
    based on the Abstract class.

    The ShelteredPastureGrowthModel models a self-replacing flock on a pasture.
    It produces wool and sheep for sale.
    FOO is modeled in a simple way: a set small FOO is expected at the end of
    summer, which will then grow some amount per mm of rainfall.
    Fodder is required for the sheep when the FOO is below a threshold (eg
    1100 kg / Ha.) This adds costs, particularly if the rain comes late.

    Shelter benefits are applied via an external python file that the user supplies.
    """

    # Properties from parent include
    # state
    # gm - handle to the owning GrowthModel
    # stateSize
    # supportedImagineEvents

    model_name = "Sheltered Pasture"
    supported_categories = ['Pasture']
    state_description = ['FOO']

    def __init__(self,  category, d=None):
        super().__init__()

        # The ImagineEvents for this growth model. This is where the triggers will be stored,
        # but the functions will also be defined in here.
        # You should define a function that returns the default list of
        # growthModelEvents. These should match the transitionFunctions
        # you've defined for each event.
        self._growth_model_initial_events, self._growth_model_regular_events, self._growth_model_destruction_events = \
            aux.make_sheltered_pasture_imagine_events()

        self._growth_model_financial_events = []

        # Now set up the specific default parameters for this growth model.
        # The priceModels, events and outputUnits need to be set up here.
        self.propagation_parameters = None
        if isinstance(d, dict):
            self.load_gm(d)
        else:
            raise NotImplementedError("Creating an instance of a ShelteredPastureGrowthModel without providing "
                                      "configuration dictionary is not yet supported.")
            self.setup_default_parameters()

    def load_gm(self, d):
        # crop config defines growth_model_parameters. That is provided here as d.
        # d is equivalent to self.propagation_parameters, but we construct propagation_parameters more carefully.
        # It's not necessarily a direct assignment.
        # There are some direct assignments though. Absorb those fields.
        prop_params = DotWiz()

        simple_fields = ["foo",
                         "fodder_requirements",
                         "wool_sales",
                         "sheep_sales",
                         "dse_per_1000_ewes",
                         "shelter_settings_file",
                         "shelter_settings_function"
                         ]
        absorb_fields(prop_params, d, simple_fields)

        if "foo" in d and "start_month" in d.foo:
            d.foo.start_month_index = get_month_index_from_month(d.foo.start_month)

        # Then handle/check/add fields as necessary

        # Finally set propagation_parameters
        self.propagation_parameters = prop_params

        self.get_event_by_name('Shearing').trigger = self.get_trigger_for_regular_event('Shearing')
        self.get_event_by_name('Feeding').trigger = self.get_trigger_for_regular_event('Feeding')
        self.get_event_by_name('Sheep Sales').trigger = self.get_trigger_for_regular_event('Sheep Sales')

    def propagate_state(self, planted_crop, sim):
        product_rates = []

        # Return the potential products if planted_crop and sim are empty.
        if not sim and not planted_crop:
            new_state = None
            return new_state, product_rates

        new_state = copy.deepcopy(planted_crop.state)
        prop_params = self.propagation_parameters

        # Check if we need to set the initial FOO.
        regime_year = sim.year - (sim.current_primary_installed_regime.installed_month // 12) + 1
        if prop_params.foo.start_month and regime_year == 1:
            if sim.month_index < prop_params.foo.start_month_index:
                planted_crop.state.foo = 0
                new_state.foo = planted_crop.state.foo
                new_state.percent_shortfall = 1
                return new_state, product_rates
            if sim.month_index == prop_params.foo.start_month_index:
                planted_crop.state.foo = prop_params.foo.available_at_start
                new_state.foo = planted_crop.state.foo

        starting_foo = planted_crop.state.foo

        # Import the settings from the designated settings file.
        module_path = resolve_imagine_path(prop_params.shelter_settings_file)
        settings_module = import_script_as_module(module_path, "shelter_settings_module")
        settings = getattr(settings_module, prop_params.shelter_settings_function)()

        # Simple lookup table for the number of days in a month.
        days_in_month_lookup = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        # The ShelteredPasture model only needs to add on some FOO if
        # there's been some rainfall.
        # In the period where we don't care, we'll set the FOO to 0.

        #   1. Use monthly growth rates and rainfall to determine OP (Open Paddock, i.e. unsheltered) growth.
        #       a. Additionally, adjust growth in the sheltered zone.
        #   2. Calculate the consumption based on the DSE in paddock (regime provides this).
        #   3. Determine the remaining FOO after consumption.
        #       a. Limit consumption to the FOO grazing minimum
        #   4. Figure out the FOO shortfall and replace with feed grain.
        #       a. Also determine the percentage shortfall to include in the outputs.

        # TODO: is it daily increase? The way the settings are described it's more
        #   like an increase based solely on the mm that month and how fast the mm get
        #   converted to FOO during that month. Not a daily increase.
        daily_increase_per_mm = settings.growth_per_mm_rain_by_month[sim.month-1]
        days_in_month = days_in_month_lookup[sim.month-1]
        year_ix = sim.month_index // 12
        month_ix = sim.month_index % 12
        monthly_foo_growth_per_ha = sim.monthly_rainfall[year_ix, month_ix] * daily_increase_per_mm * days_in_month

        # Apply shelter benefits
        # If the paddock is sheltered, apply the shelter benefits
        # through increased sheep sales.
        # Get the regime's tree height.
        height_unit = gh.tree_height
        if sim.current_secondary_planted_crop:
            th = sim.current_secondary_planted_crop.get_amount(height_unit)
        else:
            th = None

        imo = ImagineObject.get_instance()

        if th:
            th = th.number
            belt_no = sim.current_secondary_installed_regime.regime_object.get_regime_parameter('belt_num')
            belt_width = sim.current_secondary_installed_regime.regime_object.get_regime_parameter('belt_width')
            alley_width = imo.paddock_width / belt_no - belt_width
        else:
            th = 0
            belt_no = 1
            alley_width = 1

        year_ix = sim.month_index // 12
        month_ix = sim.month_index % 12
        bump_foo = settings.shelter_productivity_boost_function(settings, sim.monthly_rainfall[year_ix, month_ix], sim,
                                                                prop_params, belt_no, alley_width, th, imo.paddock_width,
                                                                imo.paddock_length, monthly_foo_growth_per_ha)

        new_state.bump_percentage = bump_foo / monthly_foo_growth_per_ha

        # bump_foo is the extra FOO from the bump. In whatever units
        # OP_productivity (last argument in shelter_productivity_boost_function) is given in.
        new_state.foo_growth_per_ha = monthly_foo_growth_per_ha + bump_foo

        # 2. Calculate the consumption based on the DSE in paddock
        # (regime provides this).
        dse_index = next(
            i for i, unit in enumerate(planted_crop.parent_regime.regime_output_units) if unit.measurable == 'stocking rate')
        hectares_index = next(
            i for i, unit in enumerate(planted_crop.parent_regime.regime_output_units) if unit.measurable == 'area')

        total_dse = planted_crop.parent_regime.outputs[sim.month_index, dse_index].number
        total_area = planted_crop.parent_regime.outputs[sim.month_index, hectares_index].number
        dse_per_ha = total_dse / total_area

        monthly_consumption_per_ha = settings.daily_consumption_per_dse * dse_per_ha * days_in_month  # kg / ha / month.

        # 3. Determine the remaining FOO after consumption.
        #     a. Limit consumption to the FOO grazing minimum

        # For now, without senescence we'll reset to the starting FOO in August.
        # Resetting to zero seemed a bit extreme - we have to build up
        # to the minimum FOO before we graze again.
        if sim.month_index == 7:
            new_state.foo = prop_params.foo.available_at_start

        # this is all on a per ha basis.
        max_foo = new_state.foo + new_state.foo_growth_per_ha
        if max_foo > prop_params.foo.required_before_grazing:
            # Then we're consuming
            if max_foo - prop_params.foo.required_before_grazing > monthly_consumption_per_ha:
                # Then we have a surplus.
                new_state.foo = max_foo - monthly_consumption_per_ha
                new_state.percent_shortfall = 0
            else:
                # Then we're constrained.
                foo_consumed = max_foo - prop_params.foo.required_before_grazing
                new_state.percent_shortfall = 1 - (foo_consumed / monthly_consumption_per_ha)
                new_state.foo = prop_params.foo.required_before_grazing
        else:
            # Then we're handfeeding.
            new_state.foo = max_foo
            new_state.percent_shortfall = 1

        if new_state.foo < 0:
            new_state.foo = 0

        # 4. Figure out the FOO shortfall and replace with feed grain.
        # This is done in the Feeding event using the percent_shortfall.

        return new_state, product_rates

    # def setup_growth_model(self, crop_name):
    #     # This function is responsible for setting up all the parameters
    #     pass  # Implementation goes here

    # def render_growth_model(self, ax):
    #     # This function renders a display of the growthModelDelegate's parameters
    #     pass  # Implementation goes here

    def calculate_outputs(self, state=None):
        # This function calculates the growthModel outputs based on the state.
        output_rates = [Rate(0, nu, du) for nu, du in zip(aux.units.outputs.numerator_units,
                                                          aux.units.outputs.denominator_units)]

        if state is not None:
            output_rates[0].number = state.foo
            output_rates[1].number = state.percent_shortfall * 100
            output_rates[2].number = state.bump_percentage * 100

        return output_rates

    # Transition functions for each supported ImagineEvent
    def transition_function_establishment(self, planted_crop, sim):
        # Transition function for Establishment event

        output_products = []; event_outputs = []
        if not planted_crop and not sim:
            return output_products, event_outputs

        new_state = DotWiz()
        new_state.foo = 0
        new_state.ncz_width = []
        new_state.percent_shortfall = 0
        new_state.bump_percentage = 0
        planted_crop.state = new_state
        return output_products, event_outputs

    def transition_function_shearing(self, planted_crop, sim):
        # Transition function for Shearing event
        event_outputs = []
        output_products = [Rate(0, nu, du) for nu, du in zip(aux.units.products.numerator_units.shearing,
                                                             aux.units.products.denominator_units.shearing)]
        if not planted_crop and not sim:
            return output_products, event_outputs

        prop_params = self.propagation_parameters

        wool = np.array(prop_params.wool_sales.matrix, dtype=object)
        # Each row is category | # per 1000 ewes | kg/hd | $/kg
        wool_hd = wool[:, 1]
        wool_income_per_hd = wool[:, 2] * wool[:, 3]

        # Calculate the deaths prevented due to shelter benefits
        deaths_prevented_dict = self.get_shelter_mortality_benefit(sim)
        if deaths_prevented_dict:
            deaths_prevented = np.array([deaths_prevented_dict[category] for category in wool[:,0]])
            wool_hd += deaths_prevented
            wool_hd = np.floor(wool_hd)

        # Use dot product to sum wool income per category for 1000 ewe flock
        #   Convert from flock to DSE basis
        wool_income = wool_hd.dot(wool_income_per_hd) / prop_params.dse_per_1000_ewes

        output_products[0].number = wool_income
        return output_products, event_outputs

    def transition_function_feeding(self, planted_crop, sim):
        # Transition function for Feeding event
        output_products = []
        # event_outputs are just fodder required in t/dse
        event_outputs = [Rate(0, nu, du) for nu, du in zip(aux.units.event_outputs.numerator_units.feeding,
                                                           aux.units.event_outputs.denominator_units.feeding)]
        if not planted_crop and not sim:
            return output_products, event_outputs

        prop_params = self.propagation_parameters

        # Import the settings from the designated settings file.
        module_path = resolve_imagine_path(prop_params.shelter_settings_file)
        settings_module = import_script_as_module(module_path, "shelter_settings_module")
        settings = getattr(settings_module, prop_params.shelter_settings_function)()

        shortfall_weeks = 4 * planted_crop.state.percent_shortfall if planted_crop.state.percent_shortfall > 0 else 0
        wool = np.array(prop_params.wool_sales.matrix, dtype=object)

        # 1000 ewe flock. Get head count per category from wool sales table.
        # Col 0 has the category strings. Col 1 has the head count.
        flock_hd = wool[:, 1]
        # Add on the sheep that didn't die thanks to the shelter benefit.
        # TODO: Check if we ought to include this. It was missing in the Matlab version.
        #   Non-dead sheep didn't need to eat but generated income.
        # deaths_prevented_dict = self.get_shelter_mortality_benefit(sim)
        # deaths_prevented = np.array([deaths_prevented_dict[category] for category in wool[:, 0]])
        # flock_hd += deaths_prevented
        # flock_hd = np.floor(flock_hd)

        # 1. Get the fodder requirements are given on a kg per hd per week basis.
        # 2. Take dot product to get total fodder kg for a 1000 ewe flock per week of feeding.
        #       Divide by 1000 to get tonnes.
        # 3. Apply weekly fodder requirement to number of shortfall weeks for the month.
        # 4. Convert to a per DSE basis with the conversion factor.
        fodder_req_kgs = np.array([prop_params.fodder_requirements[category] for category in wool[:, 0]])
        flock_fodder_req_per_week_tonnes = flock_hd.dot(fodder_req_kgs) / 1000
        monthly_flock_fodder_req_tonnes = shortfall_weeks * flock_fodder_req_per_week_tonnes

        event_outputs[0].number = monthly_flock_fodder_req_tonnes / prop_params.dse_per_1000_ewes
        return output_products, event_outputs

    def transition_function_sheep_sales(self, planted_crop, sim):
        # Transition function for Sheep Sales event
        event_outputs = []
        # Just one product: meat income.
        output_products = [Rate(0, nu, du) for nu, du in zip(aux.units.products.numerator_units.sheep_sales,
                                                             aux.units.products.denominator_units.sheep_sales)]
        if not planted_crop and not sim:
            return output_products, event_outputs

        prop_params = self.propagation_parameters

        sheep_sales = np.array(prop_params.sheep_sales.matrix, dtype=object)
        sales_hd = sheep_sales[:, 1]

        # Calculate the deaths prevented due to shelter benefits
        deaths_prevented_dict = self.get_shelter_mortality_benefit(sim)
        if deaths_prevented_dict:
            deaths_prevented = np.array([deaths_prevented_dict[category] for category in sheep_sales[:, 0]])
            sales_hd += deaths_prevented
            sales_hd = np.floor(sales_hd)

        # Percentage of CS2 / CS3...
        current_foo = planted_crop.state.foo

        if current_foo < prop_params.foo.for_100_percent_cs2:
            cs2 = 1
            cs3 = 0
        elif current_foo > prop_params.foo.for_100_percent_cs3:
            cs2 = 0
            cs3 = 1
        else:
            cs2 = (current_foo - prop_params.foo.for_100_percent_cs2) / (
                        prop_params.foo.for_100_percent_cs3 - prop_params.foo.for_100_percent_cs2)
            cs3 = 1 - cs2

        # The price per head
        cs2_prices = sheep_sales[:, 2]
        cs3_prices = sheep_sales[:, 3]
        prices = cs2_prices * cs2 + cs3_prices * cs3

        # Take dot product to sum total meat sales across all categories.
        # and convert from per flock to per DSE basis.
        meat_sales_per_dse = sales_hd.dot(prices) / prop_params.dse_per_1000_ewes
        output_products[0].number = meat_sales_per_dse
        return output_products, event_outputs

    # Destruction event doesn't do anything, but still needs to be implemented.
    def transition_function_destruction(self, planted_crop, sim):
        # Transition function for Destruction event
        return [], []

    # Validation Methods
    def gm_is_valid(self):
        # Checks that the class is right and things aren't empty
        # TODO: implement this properly
        return True

    def gm_is_ready(self):
        # Checks that the parameters are consistent and ready to go!
        # TODO: implement this properly
        return True

    def get_trigger_for_event(self, event_name):
        # Gets the trigger for a given event
        pass  # Implementation goes here

    def get_shelter_mortality_benefit(self, sim):
        # If there are shelter benefits, this reduces the number of sheep that die.
        # Get the number of deaths per category form the shelter benefits settings file.
        # Calculate the mortality shelter benefit and return the deaths prevented per category.
        prop_params = self.propagation_parameters

        # Import the settings from the designated settings file.
        module_path = resolve_imagine_path(prop_params.shelter_settings_file)
        settings_module = import_script_as_module(module_path, "shelter_settings_module")
        settings = getattr(settings_module, prop_params.shelter_settings_function)()

        # Get the regime's tree height.
        height_unit = gh.tree_height
        if sim.current_secondary_planted_crop is not None:
            th = sim.current_secondary_planted_crop.get_amount(height_unit)
        else:
            th = None

        if th:
            th = th.number
        else:
            th = 0

        if th > settings.shelter_benefit_min_height:
            th = min(th, settings.shelter_benefit_max_height)
            # We model a certain number of deaths in each category (per 1000 ewes).
            # We model shelter benefits as providing a reduction in those deaths.
            # There is a minimum tree height for benefits to kick in. And a maximum height above which there's
            # no benefit. This modelling is not impacted by the number of thickness of belts as we assume sheep
            # will gather near trees when they need the shelter.
            # There is also a maximum benefit in terms of the percentage of deaths that can be prevented.
            # Therefore we model the number of sheep sheared as the base number + the number of deaths prevented.
            percent_deaths_prevented = settings.shelter_benefit_max * \
                                       (th - settings.shelter_benefit_min_height) / \
                                       (settings.shelter_benefit_max_height - settings.shelter_benefit_min_height)
            deaths_prevented = {}
            for key, value in settings.all_deaths.items():
                deaths_prevented[key] = value * percent_deaths_prevented

            return deaths_prevented

    def get_trigger_for_regular_event(self, event_name):
        prop_params = self.propagation_parameters

        if event_name == 'Feeding':
            # return condition_helpers.output_comparator(gh.foo_per_ha, "<", prop_params.foo.required_before_grazing)
            shortfall_rate = Rate(0, gh.foo_shortfall, gh.unity)
            return condition_helpers.output_comparator(shortfall_rate, ">", 0)

        if event_name == 'Shearing':
            return condition_helpers.month_is(prop_params.wool_sales.month)

        if event_name == 'Sheep Sales':
            return condition_helpers.month_is(prop_params.sheep_sales.month)

