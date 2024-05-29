#from pimagine.crop.planted_crop import PlantedCrop
import numpy as np


class _Trigger:

    # _condition_env is a set of classes and functions that are passed to exec to parse condition definitions.
    # It should contain all the
    _condition_env = {}

    def __init__(self, cond_dict=None):
        if isinstance(cond_dict, dict):
            self.conditions = cond_dict
        else:
            self.conditions = {}

        # if trigger_type is None:
        #     self.conditions.append(NeverCondition("Cond 1"))
        # elif isinstance(trigger_type, str):
        #     if trigger_type == "emptyTrigger":
        #         self.conditions.append(NeverCondition("Never", "Cond 1"))
        #     elif trigger_type == "Annual Planting Event":
        #         condition1 = MonthBasedCondition("Month Based")
        #         condition1.month_index = 3
        #         self.conditions.append(condition1)
        #
        #         condition2 = TimeIndexedCondition("Is Rotation Year")
        #         condition2.index_type = "Year"
        #         condition2.indices = list(range(1, 51, 2))
        #         self.conditions.append(condition2)
        #
        #         condition3 = AndOrNotCondition("C1 AND C2")
        #         condition3.logic_type = "And"
        #         condition3.indices = [1, 2]
        #         self.conditions.append(condition3)
        #     elif trigger_type == "Annual Harvesting Event":
        #         condition1 = MonthBasedCondition("Month Based")
        #         condition1.month_index = 12
        #         self.conditions.append(condition1)
        #
        #         condition2 = EventHappenedPreviouslyCondition("Planting happened this year")
        #         condition2.event_name = "Planting"
        #         condition2.comparator = "<="
        #         condition2.months_prior = 12
        #         self.conditions.append(condition2)
        #
        #         condition3 = AndOrNotCondition("C1 AND C2")
        #         condition3.logic_type = "And"
        #         condition3.indices = [1, 2]
        #         self.conditions.append(condition3)
        #     else:
        #         raise ValueError("Trigger constructor takes one string argument.")
        # else:
        #     raise ValueError("Trigger constructor takes one string argument.")

    # def crop_name_has_changed(self, previous_name, new_name):
    #     for condition in self.conditions:
    #         condition.crop_name_has_changed(previous_name, new_name)

    @staticmethod
    def is_valid(trigger):
        if not isinstance(trigger, Trigger):
            return False
        
        if not trigger.conditions:
            return False

        for condition in trigger.conditions:
            if not condition.is_valid():
                return False
        
        return True

    def get_trigger_condition(self):
        if self.conditions:
            trigger_key = list(self.conditions.keys())[-1]
            return self.conditions[trigger_key]
        return None

    def is_triggered(self, sim, planted_crop=None):
        if planted_crop is None:
            from imagine.crop.planted_crop import PlantedCrop
            planted_crop = PlantedCrop()

        cond = self.get_trigger_condition()
        return cond.is_triggered(sim, planted_crop)


    # def is_triggered(self, sim, planted_crop=None):
    #
    #     if planted_crop is None:
    #         from pimagine.crop.planted_crop import PlantedCrop
    #         planted_crop = PlantedCrop()
    #
    #     # truth dict holds the values of previous evaluated conditions.
    #     # it holds their truth value by name.
    #     # So later conditions have access to the results of previous conditions.
    #     truth_dict = {}
    #
    #     for key, val in self.conditions.items():
    #         cond = self.conditions[key]
    #         truth_val = cond.is_triggered(sim, planted_crop, truth_dict)
    #         truth_dict[key] = truth_val
    #
    #     # Return the last truth val. That is the value of the last condition,
    #     # which is the answer to is_triggered.
    #     return truth_val

    # @classmethod
    # def _register_condition_syntax(cls):
    #     if not cls._condition_env:
    #         from pimagine.events.time_indexed_condition import TimeIndexedCondition
    #         from pimagine.events.and_or_not_condition import AndOrNotCondition
    #         from pimagine.events.quantity_based_condition import QuantityBasedCondition
    #         from pimagine.events.month_based_condition import MonthBasedCondition
    #         from pimagine.events.never_condition import NeverCondition
    #         from pimagine.events.event_happened_previously import EventHappenedPreviouslyCondition
    #         simple_fields = [
    #             TimeIndexedCondition,
    #             AndOrNotCondition,
    #             QuantityBasedCondition,
    #             MonthBasedCondition,
    #             NeverCondition,
    #             EventHappenedPreviouslyCondition
    #          ]
    #         for f in simple_fields:
    #             cls._condition_env[f.__name__] = f
    #
    #         cls._condition_env['month_index_is'] = lambda x: TimeIndexedCondition(x, 'Month')
    #         cls._condition_env['year_index_is'] = lambda x: TimeIndexedCondition(x, 'Year')

