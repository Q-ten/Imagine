from copy import deepcopy

from imagine.core import ImagineObject
from imagine.core.amount import Amount
from imagine.core.occurance import Occurrence
from imagine.events.quantity_based_condition import QuantityBasedCondition
import imagine.core.global_helpers as gh
from dotwiz import DotWiz


class PlantedCrop:

    def __init__(self, crop_object=None, parent_regime=None, sim=None, initialisation_event=None):
        if not crop_object and not parent_regime and not sim and not initialisation_event:
            return
        elif not crop_object or not parent_regime or not sim or not initialisation_event:
            raise ValueError('Must pass 0 or 4 arguments to the PlantedCrop constructor.')
        else:
            self.crop_object = crop_object
            self.parent_regime = parent_regime
            self.occurrences = []
            self.sim = sim
            # self.private_occurrences = []
            # self.private_outputs_month_start = None
            # self.private_outputs_month_end = None
            self.planted_month = sim.month_index
            self.destroyed_month = None         # Set by simulation manager after destruction
            self._output_col_length = len(crop_object.crop_rate_defs.output_rates)
            self._setup_triggers()

            self.states = None
            self.recent_products_list = []

            # Process the initial event.
            self.process_event(initialisation_event, sim)

            # Calculate the outputs after the initialisation event because the state may have changed.
            self.calculate_outputs()

    def costs(self, first_month, last_month, as_list):
        if last_month < first_month:
            return []

        if last_month > self.month_index:
            last_month = self.month_index

        if first_month < 1:
            first_month = 1

        cs = [0] * (last_month - first_month + 1)

        for occurrence in self.occurrences:
            month_index = occurrence.month_index
            if first_month <= month_index <= last_month:
                cost = sum(cost_item.cost.number for cost_item in occurrence.cost_items)
                cs[month_index - first_month] += cost

        if not as_list:
            cs = sum(cs)

        return cs

    def income(self, first_month, last_month, as_list):
        if last_month < first_month:
            return []

        if last_month > self.month_index:
            last_month = self.month_index

        if first_month < 1:
            first_month = 1

        ins = [0] * (last_month - first_month + 1)

        for occurrence in self.occurrences:
            month_index = occurrence.month_index
            if first_month <= month_index <= last_month:
                income = sum(product.income.number for product in occurrence.products)
                ins[month_index - first_month] += income

        if not as_list:
            ins = sum(ins)

        return ins

    def profit(self, first_month, last_month, as_list):
        return self.income(first_month, last_month, as_list) - self.costs(first_month, last_month, as_list)

    @property
    def crop_name(self):
        return self.crop_object.name

    @property
    def month_index(self):
        return self.sim.month_index

    @property
    def month_day(self):
        return self.sim.month_day

    # @property
    # def occurrences(self):
    #     return self.private_occurrences[:self.occurrence_count]

    @property
    def state(self):
        if not self.states:
            return None
        if self.month_day == 1:
            return self.states[0][self.month_index - self.planted_month]
        elif self.month_day == 30:
            return self.states[1][self.month_index - self.planted_month]

    @state.setter
    def state(self, st):
        col = self.month_index - self.planted_month
        if self.month_day == 1:
            if not self.states:
                self.states = [[st], []]
            elif len(self.states[0] == col):
                self.states[0].append(col)
            else:
                self.states[0][col] = st
        elif self.month_day == 30:
            if len(self.states[1]) == col:
                self.states[1].append(st)
            else:
                self.states[1][col] = st

    # Why was this necessary? I've been enforcing outputs being the same size once configured.
    # @property
    # def outputs_month_start_size(self):
    #     return len(self.private_outputs_month_start), self.private_outputs_month_start_index
    #
    # @property
    # def outputs_month_end_size(self):
    #     return len(self.private_outputs_month_end), self.private_outputs_month_end_index

    def month_start_outputs(self, month_index=None):
        if not month_index:
            month_index = self.sim.month_index
        return self.sim.sim_store.crop_store[self.crop_name].outputs[month_index, 0:self._output_col_length]

    def month_end_outputs(self, month_index=None):
        if not month_index:
            month_index = self.sim.month_index
        return self.sim.sim_store.crop_store[self.crop_name].outputs[month_index, self._output_col_length:]

    def get_amount(self, unit, month_index=None, month_day=None):
        if month_index is None:
            month_index = self.month_index
        if month_day is None:
            month_day = self.month_day

        if month_index > self.month_index or (month_index == self.month_index and month_day > self.month_day):
            return Amount()

        if unit == gh.unity:
            return Amount(1, gh.unity)

        if month_day == 1:
            output_column = self.month_start_outputs(month_index)
        else:
            output_column = self.month_end_outputs(month_index)

        ix = next((i for i, output in enumerate(output_column) if output is not None and output.unit == unit), None)

        if ix is not None:
            # TODO: remove this if not needed.
            # I don't understand what this was for.
            # if month_day == 1:
            #     if self.private_outputs_month_start_index >= month_index - self.planted_month:
            #         return output_column[ix]
            # else:
            #     if self.private_outputs_month_end_index != 0:
            #         return output_column[ix]
            return output_column[ix]

        return self.parent_regime.get_amount(unit, month_index)

    def get_most_recent_production(self, measurable):
        rp = Amount()
        ix = next((i for i, product in enumerate(self.recent_products_list) if
                   product.quantity.unit.measurable == measurable), None)
        if ix is not None:
            rp = self.recent_products_list[ix].quantity
        return rp

    def calculate_outputs(self):
        # TODO: remove this. I can't figure out why the extra condition is there.
#        if self.month_day == 1 and self.private_outputs_month_start_index < self.month_index - self.planted_month:
        outputs_column = self.crop_object.growth_model.calculate_outputs(self.state)
        if self.month_day == 1: # and self.private_outputs_month_start_index < self.month_index - self.planted_month:
            self.month_start_outputs(self.month_index)[:] = outputs_column
#            self.set_outputs_month_start_column(self.month_index - self.planted_month, outputs_column)
        else:
            outputs_column = self.crop_object.growth_model.calculate_outputs(self.state)
            self.month_end_outputs(self.month_index)[:] = outputs_column
#            self.set_outputs_month_end_column(self.month_index - self.planted_month, outputs_column)

    # def set_outputs_month_start_column(self, col_ind, outputs_column):
    #     if len(self.private_outputs_month_start) < col_ind:
    #         if not self.private_outputs_month_start:
    #             if not outputs_column:
    #                 return
    #             self.private_outputs_month_start = [outputs_column] * 14
    #             self.private_outputs_month_start_index = col_ind
    #             return
    #         else:
    #             im_ob = ImagineObject.get_instance()
    #             new_months = self.private_outputs_month_start + [outputs_column] * (
    #                         im_ob.simulation_length * 12 - 14)
    #             self.private_outputs_month_start = new_months
    #             self.private_outputs_month_start_index = col_ind
    #             return
    #     self.private_outputs_month_start[:, col_ind] = outputs_column
    #     self.private_outputs_month_start_index = col_ind

    # def set_outputs_month_end_column(self, col_ind, outputs_column):
    #     if len(self.private_outputs_month_end) < col_ind:
    #         if not self.private_outputs_month_end:
    #             if not outputs_column:
    #                 return
    #             self.private_outputs_month_end = [outputs_column] * 14
    #             self.private_outputs_month_end_index = 1
    #             return
    #         else:
    #             im_ob = ImagineObject.get_instance()
    #             new_months = self.private_outputs_month_end + [outputs_column] * (im_ob.simulation_length * 12 - 14)
    #             self.private_outputs_month_end = new_months
    #             self.private_outputs_month_end_index = 15
    #             return
    #     self.private_outputs_month_end[:, col_ind] = outputs_column
    #     self.private_outputs_month_end_index = col_ind

    # TODO: Find what is calling get_outputs.
    #   I expect I'll need to change how it is called and how it works to work with sim_store.
    # def get_outputs(self, row_indices=None, year_indices=None, month_day=1):
    #     # This could be a more straightforward way to access outputs.
    #     if month_day == 1 and self.private_outputs_month_start:
    #         return self.private_outputs_month_start[row_indices, year_indices-self.planted_year]
    #     elif month_day == 30 and self.private_outputs_month_end:
    #         return self.private_outputs_month_end[row_indices, year_indices-self.planted_year]
    #
    #     return None

    # def _set_outputs_column(self, outputs_col, month_day=1):
    #     pass
    #
    # def get_outputs_month_start(self, row_indices=None, col_indices=None):
    #     if self.private_outputs_month_start:
    #         return self.private_outputs_month_start[row_indices, col_indices]
    #     return None
    #
    #
    # def _get_outputs_month_start(self, row_indices=[], col_indices=[]):
    #     available_cols = list(range(1, self.private_outputs_month_start_index + 1))
    #     all_rows = not row_indices
    #     all_cols = not col_indices
    #
    #     if all_rows and all_cols:
    #         return self.private_outputs_month_start[:, available_cols]
    #     elif all_rows and not all_cols:
    #         return self.private_outputs_month_start[:, [available_cols[i] for i in col_indices]]
    #     elif not all_rows and all_cols:
    #         return self.private_outputs_month_start[row_indices, available_cols]
    #     else:
    #         return self.private_outputs_month_start[row_indices, [available_cols[i] for i in col_indices]]
    #
    # def get_outputs_month_end(self, row_indices=[], col_indices=[]):
    #     available_cols = list(range(1, self.private_outputs_month_end_index + 1))
    #     all_rows = not row_indices
    #     all_cols = not col_indices
    #
    #     if all_rows and all_cols:
    #         return self.private_outputs_month_end[:, available_cols]
    #     elif all_rows and not all_cols:
    #         return self.private_outputs_month_end[:, [available_cols[i] for i in col_indices]]
    #     elif not all_rows and all_cols:
    #         return self.private_outputs_month_end[row_indices, available_cols]
    #     else:
    #         return self.private_outputs_month_end[row_indices, [available_cols[i] for i in col_indices]]


    def get_outputs_month_start(self, month_index):
        col_size = len(self.sim.sim_store.crop_store[self.crop_name].outputs[0,:])
        return self.sim.sim_store.crop_store[self.crop_name].outputs[month_index, :col_size//2]

    def get_outputs_month_end(self, month_index):
        col_size = len(self.sim.sim_store.crop_store[self.crop_name].outputs[0,:])
        return self.sim.sim_store.crop_store[self.crop_name].outputs[month_index, col_size//2:]

    def process_events(self, sim, fake_out=False):
        ocs = []
        event_group_names = ['regular', 'gm_financial', 'crop_financial']
        for group_name in event_group_names:
            ocs.extend(self._process_event_group(group_name, sim, fake_out))
        return ocs

    def _process_event_group(self, group_name, sim, fake_out=False):
        ocs = []
        eg = self.event_triggers[group_name]
        for event in eg.events:
            trig = eg.triggers[event.name]
            if trig.is_triggered(sim, self):
                print(f"Triggered: {self.crop_name} {event.name}")
#                print(trig.get_longhand())
                oc = self.process_event(event, sim, fake_out)
                if fake_out:
                    ocs.append(oc)
        return ocs

    def check_for_destruction(self, sim):
        # tf = False
        ocs = self._process_event_group('destruction', sim)
        return len(ocs) > 0
        # for i in range(len(self.destruction_triggers)):
        #     if sim.is_triggered(self.destruction_triggers[i]):
        #         tf = True
        #         im_event = self.crop_object.growth_model.growth_model_destruction_events[i]
        #         self.process_event(im_event, sim)
        # return tf

    def propagate_state(self, sim):
        new_state, product_rates = self.crop_object.growth_model.propagate_state(self, sim)
        # if any(pr.number != 0 for pr in product_rates):
        if product_rates:
            product_amounts = []
            for r in product_rates:
                product_amounts.append(r * self.get_amount(r.denominator_unit))
            oc = Occurrence("Monthly Propagation", product_amounts, [], self, sim)
            self.add_occurrence(oc)
        return new_state

    # This function transfers the current end state for the month to the start state for the next month.
    # It takes an optional argument monthEndState which sets the months's end state after the transfer.
    # This is because in the simulation, we do the harvest etc at the end of the month, and this changes
    # the state which becomes the next months' state, but we want to maintain the post-propagation state
    # (before harvest) as the month end state.
    def transfer_state_to_next_month(self, month_end_state=None):
        if self.month_day == 30:
            # col is relative to the planted month
            col = self.month_index - self.planted_month + 1
            if len(self.states[0]) == col:
                self.states[0].append(deepcopy(self.state))
            else:
                raise ValueError("Transfer to next month called when the length of PlantedCrop.states doesn't match "
                                 "the expected length based on month index.")
            # else:
            #     self.states[0][col] = deepcopy(self.state)
            outputs_column = self.crop_object.growth_model.calculate_outputs(self.state)
            self.month_start_outputs(self.month_index+1)[:] = outputs_column
#            self.set_outputs_month_start_column(self.month_index - self.planted_month + 1, outputs_column)
            if month_end_state is not None:
                self.state = month_end_state
        else:
            raise ValueError('Tried to transfer the state between months before the end of the month.')

    def add_occurrence(self, oc):
        # if self.occurrence_count == len(self.private_occurrences):
        #     self.private_occurrences.extend([Occurrence() for _ in range(self.occurrence_count * 2 + 5)])
        # self.occurrence_count += 1
        # self.private_occurrences[self.occurrence_count - 1] = oc
        self.occurrences.append(oc)

        # Recent products is a list that keeps the most recent product produced of each type (as determined by unit).
        if oc.products:
            for product in oc.products:
                ix = next((i for i, p in enumerate(self.recent_products_list)
                           if p.quantity.unit.measurable == product.quantity.unit.measurable), None)
                if ix is None:
                    self.recent_products_list.append(product)
                else:
                    self.recent_products_list[ix] = product

    def process_event(self, im_event, sim, fake_out=False):
        event_output_amounts = []
        product_amounts = []

        if im_event.status.origin == 'core':
            # fake_out means to call the transition function, but don't keep the changes it makes to it's state.
            if fake_out:
                temp_state = deepcopy(self.state)
            product_rates, event_output_rates = self.crop_object.growth_model.event_transition(im_event.name, self, sim)
            if fake_out:
                self.state = temp_state

            for r in product_rates:
                product_amounts.append(r * self.get_amount(r.denominator_unit))

            for r in event_output_rates:
                denominator_amount = self.get_amount(r.denominator_unit)
                if not denominator_amount:
                    for pa in product_amounts:
                        if pa.unit == r.denominator_unit:
                            denominator_amount = pa
                            break
                event_output_amounts.append(r * denominator_amount)
        elif im_event.status.origin == 'cropNew':
            pass
        elif im_event.status.origin == 'regimeNew':
            pass
        elif im_event.status.origin == 'growthModelFinancial':
            pass

        oc = Occurrence(im_event.name, product_amounts, event_output_amounts, self, sim)
        if not fake_out:
            self.add_occurrence(oc)
        return oc

    def _setup_triggers(self):

        from imagine.crop.crop_manager import CropManager
        crop_manager = CropManager.get_instance()
        all_events = self.crop_object.get_events()
        # regular_events = self.crop_object.growth_model.growth_model_regular_events
        # destruction_events = self.crop_object.growth_model.growth_model_destruction_events
        # gm_financial_events = self.crop_object.growth_model.growth_model_financial_events
        # crop_financial_events = self.crop_object.financial_events

        self.event_triggers = DotWiz()
        # event_triggers.events : [List of ImagineEvents]
        # event_triggers.triggers: {dict of ImagineConditions, indexed by event name}
        self.event_triggers.regular = {'events': all_events.regular_events, "triggers": {}}
        self.event_triggers.destruction = {'events': all_events.destruction_events, "triggers": {}}
        self.event_triggers.gm_financial = {'events': all_events.gm_financial_events, "triggers": {}}
        self.event_triggers.crop_financial = {'events': all_events.crop_financial_events, "triggers": {}}

        for event_type, d in self.event_triggers.items():
            for event in d.events:
                trig = event.trigger
                if event.status.deferred_to_regime or event.status.regime_redefinable:
                    trig = self.parent_regime.regime_object.get_regime_trigger(self.crop_object.name, event.name)
                if not trig:
                    trig = event.trigger
                d.triggers[event.name] = trig


