from imagine.events.imagine_condition import ImagineCondition
from imagine.core.rate import Rate


class QuantityBasedCondition(ImagineCondition):

    quantity_type_options = ['Product', 'Output']
    null_event_name = 'Monthly Propagation'
    comparator_options = ['=', '<', '>', '<=', '>=']

    def __init__(self, quantity_type, event_name, comparator, rate, shorthand=""):
        super().__init__(shorthand)
        self.quantity_type = quantity_type
        self.event_name = event_name
        self.comparator = comparator
        self.rate = rate


    @property
    def condition_type(self):
        return 'Quantity Based'

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

    def is_triggered(self, sim, planted_crop):
        # if sim.month_day == 1:
        #     output_rates = planted_crop.get_outputs_month_start(sim.month_index)
        # else:
        #     output_rates = planted_crop.get_outputs_month_end(sim.month_index)
        #
        # monthly_occurrences = planted_crop.occurrences
        # regime_amounts = planted_crop.parent_regime.outputs[sim.month_index, :]
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
                    column = column[:col_size // 2]
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

