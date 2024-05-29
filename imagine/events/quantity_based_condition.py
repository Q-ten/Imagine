from imagine.events.imagine_condition import ImagineCondition
from imagine.core.rate import Rate
from imagine.core.product import Product
from imagine.core.unit import Unit


class QuantityBasedCondition(ImagineCondition):

    quantity_type_options = ['Product', 'Output']
    null_event_name = 'Monthly Propagation'
    comparator_options = ['=', '<', '>', '<=', '>=']

    def __init__(self, quantity_type, event_name, comparator, rate, shorthand=""):
        super().__init__(shorthand)
        # self.quantity_type = 'Product'
        # self.event_name = self.null_event_name
        # self.rate = Rate()  # Assuming Rate is another class you have defined
        # self.comparator = '='
        self.quantity_type = quantity_type
        self.event_name = event_name
        self.comparator = comparator
        self.rate = rate


    @property
    def condition_type(self):
        return 'Quantity Based'

    """
    This property is not required in the python version.
    @property
    def figure_name(self):
        return 'conditionPanel_QuantityBased.fig'
    """

    @property
    def handles_field(self):
        return 'QuantityBasedHandles'

    def crop_name_has_changed(self, previous_name, new_name):
        pass

    def get_longhand(self):
        if self.comparator == '<':
            comp_string = 'is strictly less than'
        elif self.comparator == '<=':
            comp_string = 'is less than or equal to'
        elif self.comparator == '=':
            comp_string = 'is exactly equal to'
        elif self.comparator == '>':
            comp_string = 'is strictly greater than'
        elif self.comparator == '>=':
            comp_string = 'is greater than or equal to'
        else:
            comp_string = 'Error with Comparator string'

        if self.rate.number is None:  # Assuming the Rate class has a 'number' attribute
            amount_number = '?'
        else:
            amount_number = str(self.rate.number)

        units = f"{self.rate.unit.unit_name}(s) {self.rate.denominator_unit.readable_denominator_unit}"
        return f"{self.rate.unit.measurable} {comp_string} {amount_number} {units}"

    def is_triggered(self, sim, planted_crop):#output_rates, monthly_occurrences, regime_amounts):
        if sim.month_day == 1:
            output_rates = planted_crop.get_outputs_month_start(sim.month_index)
        else:
            output_rates = planted_crop.get_outputs_month_end(sim.month_index)

        monthly_occurrences = planted_crop.occurrences
        regime_amounts = planted_crop.parent_regime.outputs[sim.month_index, :]
        tf = False
        column = []

        if self.quantity_type == 'Product':
            if self.event_name == self.null_event_name:
                column = sim.sim_store.crop_store[planted_crop.crop_object.name].propagation_products[sim.month_index, :]
            else:
                column = sim.sim_store.crop_store[planted_crop.crop_object.name] \
                         .events[self.event_name].products[sim.month_index, :]
        elif self.quantity_type == 'Output':
            if self.event_name == self.null_event_name:
                column = sim.sim_store.crop_store[planted_crop.crop_object.name].outputs[sim.month_index, :]
                col_size = len(column)
                if sim.month_day == 1:
                    column = column[:col_size//2]
                else:
                    column = column[col_size // 2:]
            else:
                column = sim.sim_store.crop_store[planted_crop.crop_object.name].events[self.event_name] \
                         .event_outputs[sim.month_index, :]

        item = [it for it in column if it.unit == self.rate.unit and it.denominator_unit == self.rate.denominator_unit]
        if len(item) == 1:
            item = item[0]
            if self.comparator == '=':
                tf = item.number == self.rate.number
            elif self.comparator == '<=':
                tf = item.number <= self.rate.number
            elif self.comparator == '>=':
                tf = item.number >= self.rate.number
            elif self.comparator == '<':
                tf = item.number < self.rate.number
            elif self.comparator == '>':
                tf = item.number > self.rate.number
            return tf
        else:
            return False

        # if self.rate.denominator_unit == Unit:
        #     condition_total_amount = self.rate.number
        # else:
        #     den_unit = self.rate.denominator_unit
        #     regime_amount = [ra for ra in regime_amounts if den_unit == ra.unit]
        #     if not regime_amount:
        #         raise ValueError("Could not find an amount from the Regime to match the defined denominator unit.")
        #     condition_total_amount = self.rate.number * regime_amounts[0].number
        #
        # # Get the total amount from the product/output
        # is_propagation_event = self.event_name == self.null_event_name
        # occurrence_products = Product.empty(1, 0)
        # occurrence_outputs = Rate.empty(1, 0)
        # if not is_propagation_event or self.quantity_type == 'Product':
        #     for oc in monthly_occurrences:
        #         if oc.event_name == self.event_name:
        #             occurrence_products = oc.products
        #             occurrence_outputs = oc.event_outputs
        #             break
        #
        # if self.quantity_type == 'Product':
        #     ix = [i for i, product in enumerate(occurrence_products.quantity.unit) if self.rate.unit == product]
        #     if not ix:
        #         sim_total_amount = 0
        #     else:
        #         sim_total_amount = occurrence_products[ix[0]].quantity.number
        # elif self.quantity_type == 'Output':
        #     if is_propagation_event:
        #         ix = [i for i, unit in enumerate(output_rates.unit) if self.rate.unit == unit]
        #         if not ix:
        #             raise ValueError("Could not find a matching outputRate from propagation - should have found it.")
        #         sim_total_rate = output_rates[ix[0]]
        #     else:
        #         ix = [i for i, unit in enumerate(occurrence_outputs.unit) if self.rate.unit == unit]
        #         if not ix:
        #             sim_total_rate = Rate(0, Unit, Unit)
        #         else:
        #             sim_total_rate = occurrence_outputs[ix[0]]
        #
        #     if sim_total_rate.denominator_unit == Unit:
        #         sim_total_amount = sim_total_rate.number
        #     else:
        #         ix = [i for i, unit in enumerate(regime_amounts.unit) if self.rate.denominator_unit == unit]
        #         if not ix:
        #             raise ValueError("Unable to find a matching regime amount for the quantity's denominator unit.")
        #         sim_total_amount = sim_total_rate.number * regime_amounts[ix[0]].number
        # else:
        #     raise ValueError("quantityType not set correctly in QuantityBasedCondition.")

        # if self.comparator == '=':
        #     TF = sim_total_amount == condition_total_amount
        # elif self.comparator == '<=':
        #     TF = sim_total_amount <= condition_total_amount
        # elif self.comparator == '>=':
        #     TF = sim_total_amount >= condition_total_amount
        # elif self.comparator == '<':
        #     TF = sim_total_amount < condition_total_amount
        # elif self.comparator == '>':
        #     TF = sim_total_amount > condition_total_amount
        #
        # return TF

    def is_valid(self, *args):
        valid = super().is_valid()
        valid = valid and isinstance(self.rate, Rate)
        valid = valid and isinstance(self.event_name, str)
        valid = valid and isinstance(self.comparator, str)
        valid = valid and isinstance(self.quantity_type, str)
        valid = valid and self.rate is not None
        valid = valid and self.event_name != ""
        if valid:
            valid = valid and (self.comparator in self.comparator_options)
            valid = valid and (self.quantity_type in self.quantity_type_options)
        # Accepts in an optional list of eventNames to check against.
        if len(args) == 1:
            event_names = args[0]
            valid = valid and (self.event_name in event_names)
        return valid

