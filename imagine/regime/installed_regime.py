import numpy as np

from imagine.crop.crop_manager import CropManager
from imagine.core.amount import Amount
from dotwiz import DotWiz


class InstalledRegime:

    def __init__(self, regime_object, parent_sim, zone):
        self.parent_sim = parent_sim
        self.regime_object = regime_object
        self.zone = zone
        self.planted_crops = []
        self.outputs = parent_sim.sim_store.regime_store[self.regime_object.regime_label].outputs
        self.crop_index = -1
        self.crop_names = self.regime_object.crop_name_list
        self.installed_month = parent_sim.month_index
        self.installed_year = int(self.installed_month // 12)
        self.final_month = self.regime_object.final_year * 12 - 1
        self.initial_event_triggers = None

        self._setup_initial_triggers()

    @property
    def month_index(self):
        return self.parent_sim.month_index

    @property
    def month_day(self):
        return self.parent_sim.month_day

    @property
    def current_planted_crop(self):
        if self.planted_crops:
            last_planted_crop = self.planted_crops[-1]
            if last_planted_crop.destroyed_month is None:
                return last_planted_crop

        return None

    @property
    def regime_label(self):
        return self.regime_object.regime_label

    @property
    def regime_output_units(self):
        return [output.unit for output in self.outputs[0]] if self.outputs is not None else []

    def costs(self, first_month, last_month, as_list):
        if last_month < first_month:
            return []

        last_month = min(last_month, self.month_index)
        first_month = max(first_month, 1)

        if as_list:
            costs = [0] * (last_month - first_month + 1)
        else:
            costs = 0

        for planted_crop in self.planted_crops:
            costs += planted_crop.costs(first_month, last_month, as_list)

        return costs

    def income(self, first_month, last_month, as_list):
        if last_month < first_month:
            return []

        last_month = min(last_month, self.month_index)
        first_month = max(first_month, 1)

        if as_list:
            income_values = [0] * (last_month - first_month + 1)
        else:
            income_values = 0

        for planted_crop in self.planted_crops:
            income_values += planted_crop.income(first_month, last_month, as_list)

        return income_values

    def profit(self, first_month, last_month, as_list):
        return self.income(first_month, last_month, as_list) - self.costs(first_month, last_month, as_list)

    def calculate_outputs(self):
        outputs_column = self.regime_object.calculate_outputs(self.parent_sim)

        if self.outputs is not None:
            self.outputs[self.parent_sim.month_index, :] = outputs_column

    def get_regime_parameter(self, pname):
        return self.regime_object.get_regime_parameter(pname)

    def get_amount(self, unit, month_index=None):
        if month_index is None:
            month_index = self.parent_sim.month_index

        if month_index > self.month_index:
            return []

        if unit is None:
            return [Amount(1, None)]

        try:
            output_column = self.outputs[month_index, :]
            # output_column = [output[0] for output in self.outputs[month_index - self.installed_month]]
            output_units = [output.unit for output in output_column]
        except IndexError:
            return []

        try:
            idx = output_units.index(unit)
            return output_column[idx]
#            return [output[idx] for output in output_column]
        except ValueError:
            return []

    def get_amounts(self, unit):
        try:
            idx = [output[0].unit for output in self.outputs].index(unit)
        except ValueError:
            return []

        last_col = min(self.parent_sim.month_index - self.installed_month + 1, self.final_month - self.installed_month + 1)
        return [output[idx] for output in self.outputs[:last_col]]

    def plant_if_possible(self):
        crop_manager = CropManager.get_instance()

        for crop_name, event_triggers in self.initial_event_triggers.items():
            for event in event_triggers.events:
                trig = event_triggers.triggers[event.name]
                if trig.is_triggered(self.parent_sim, self):
                    planted_crop = crop_manager.get_planted_crop(crop_name, self, self.parent_sim, event)

                    # self.crop_index = len(self.planted_crops) + 1
                    self.planted_crops.append(planted_crop)

                    # May need to fix up the units for the planting
                    # cost. Just redo them.
                    # If the cost item quantity returns non-zero as a
                    # regime output, use that value in the quantity.
                    self.calculate_outputs()
                    for ci in planted_crop.occurrences[0].cost_items:
                        ci_quantity_unit = ci.quantity.unit
                        amt = self.get_amount(ci_quantity_unit)
                        if amt:
                            ci.quantity.number = amt.number

                    return

        # for event in eg.events:
        #     trig = eg.triggers[event.name]
        #     if trig.is_triggered(sim, self):
        #         oc = self.process_event(event, sim, fake_out)
        #         if fake_out:
        #             ocs.append(oc)
        # return ocs
        #
        #
        # if self.crop_index != 0:
        #     return
        #
        # crop_manager = CropManager.get_instance()
        #
        # for i in range(len(self.initial_triggers)):
        #     for j in range(len(self.initial_triggers[i])):
        #         for trigger in self.initial_triggers[i][j]:
        #             if self.parent_sim.is_triggered(trigger):
        #                 crop_name = self.crop_names[i]
        #                 initialisation_event_index = j
        #
        #                 planted_crop = crop_manager.get_planted_crop(crop_name, self, self.parent_sim,
        #                                                              initialisation_event_index)
        #
        #                 self.crop_index = len(self.planted_crops) + 1
        #                 self.planted_crops.append(planted_crop)
        #
        #                 # May need to fix up the units for the planting
        #                 # cost. Just redo them.
        #                 # If the cost item quantity returns non-zero as a
        #                 # regime output, use that value in the quantity.
        #                 self.calculate_outputs()
        #                 ci_quantity_unit = planted_crop.occurrences[0].cost_items[0].quantity.unit
        #                 amt = self.get_amount(ci_quantity_unit)
        #                 if amt:
        #                     planted_crop.occurrences[0].cost_items[0].quantity.number = amt[0].number
        #
        #                 return

    def _setup_initial_triggers(self):

        # Implementing event_triggers similar to PlantedCrop.
        # But it's not quite the same. Because we need to organise the initial events for all the regime crops.
        self.initial_event_triggers = DotWiz()

        # initial_event_triggers[crop_name].events is a list of the initial events for that crop.
        # initial_event_triggers[crop_name].triggers[event_name] is the trigger for that event.
        crop_manager = CropManager.get_instance()

        for crop_name in self.crop_names:
            # Each crop has a dict of events.
            # The initial events come from the crops via the crop_manager.
            # The triggers start of empty. We'll fill it in.
            self.initial_event_triggers[crop_name] = {
                'events': crop_manager.get_crops_initial_events(crop_name),
                'triggers': {}
            }

            # If the event permits regime definition, get the regime trigger and use it if not None.
            # The regime has the event configuration and can provide its trigger.
            for event in self.initial_event_triggers[crop_name].events:
                if event.status.deferred_to_regime or event.status.regime_redefinable:
                    trig = self.regime_object.get_regime_trigger(crop_name, event.name)
                    if not trig:
                        trig = event.trigger
                self.initial_event_triggers[crop_name].triggers[event.name] = trig


    # def get_regime_trigger(self, crop_name, event_name):
    #     return self.regime_object.get_regime_trigger(crop_name, event_name)
        # try:
        #
        #     trig = self.regime_object.crop_event_triggers[crop_name][event_name]
        # except KeyError:
        #     trig = None
        # return trig
        #
        # crop_event_triggers = self.regime_object.crop_event_triggers
        #
        # try:
        #     regime_crop_index = [crop_event.crop_name for crop_event in crop_event_triggers].index(crop_name)
        # except ValueError:
        #     return None
        #
        # event_triggers = crop_event_triggers[regime_crop_index].event_triggers
        #
        # try:
        #     event_index = [event_trigger.event_name for event_trigger in event_triggers].index(event_name)
        # except ValueError:
        #     return None
        #
        # return event_triggers[event_index].trigger
        #
