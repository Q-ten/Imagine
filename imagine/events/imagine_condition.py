from abc import ABC, abstractmethod
#import inspect


class ImagineCondition(ABC):

    _condition_registry = []

    # shorthand is just a string to describe the condition to a user. It is not parsed anywhere.
    # If we print all the shorthand fields of the conditions in a trigger, we should be able to 
    # figure out exactly when the trigger will trigger.
    def __init__(self, shorthand):
        if isinstance(shorthand, str):
            self.shorthand = shorthand
        else:
            raise ValueError("First argument to ImagineCondition constructor must be a string.")

    @property
    @abstractmethod
    def condition_type(self):
        pass

    def __and__(self, ob2):
        from imagine.events.and_or_not_condition import AndOrNotCondition
        if isinstance(self, AndOrNotCondition) and self.logic_type in ['And', 'All']:
            self.conditions.append(ob2)
            return self
        return AndOrNotCondition('And', [self, ob2])

    def __or__(self, ob2):
        from imagine.events.and_or_not_condition import AndOrNotCondition
        if isinstance(self, AndOrNotCondition) and self.logic_type in ['Or', 'Any']:
            self.conditions.append(ob2)
            return self
        return AndOrNotCondition('Or', [self, ob2])

    def __invert__(self):
        from imagine.events.and_or_not_condition import AndOrNotCondition
        return AndOrNotCondition('Not', [self])

    def get_shorthand(self):
        sh = self.shorthand
        if sh == "":
            sh = self.get_longhand()
        return sh


    """
    # These properties were required in matlab. This comment can be removed later.
    @property
    @abstractmethod
    def figure_name(self):
        pass
    
    @property
    @abstractmethod
    def handles_field(self):
        pass
    """

    # @abstractmethod
    # def crop_name_has_changed(self, previous_name, new_name):
    #     pass
    #

    # @abstractmethod
    # def load_condition(self, panel, *args):
    #     pass
    #
    # @abstractmethod
    # def save_condition(self, panel):
    #     pass

    @abstractmethod
    def is_triggered(self, sim, planted_crop):
        pass

    @abstractmethod
    def get_longhand(self, *args):
        pass

    """
        There will be no old structures to load from in the python version.
        This was for backward compatability in the matlab version.
    @abstractmethod
    def setup_from_old_structure(self, s):
        pass
    """

    def is_valid(self):
        return isinstance(self, ImagineCondition)

    # In the translation from matlab to python, I've
    # left out implementations of loadConditionControls and removeConditionControls as these are specific to matlab guis.

    # We import the subclassed conditions inside this method so that we avoid the circular imports.
    @staticmethod
    def new_condition(condition_type, shorthand):
        if condition_type == "Time Index Based":
            from imagine.events.time_indexed_condition import TimeIndexedCondition
            return TimeIndexedCondition(shorthand)
        elif condition_type == "Month Based":
            from imagine.events.month_based_condition import MonthBasedCondition
            return MonthBasedCondition(shorthand)
        elif condition_type == "Event Happened Previously":
            from imagine.events.event_happened_previously import EventHappenedPreviouslyCondition
            return EventHappenedPreviouslyCondition(shorthand)
        elif condition_type == "Quantity Based":
            from imagine.events.quantity_based_condition import QuantityBasedCondition
            return QuantityBasedCondition(shorthand)
        elif condition_type in ("AND / OR / NOT", "AND / OR", "And / Or / Not", "And / Or"):
            from imagine.events.and_or_not_condition import AndOrNotCondition
            return AndOrNotCondition(shorthand)
        elif condition_type == "Never":
            from imagine.events.never_condition import NeverCondition
            return NeverCondition(shorthand)
        else:
            raise ValueError("Trying to create a condition with unknown type.")

    # @classmethod
    # def get_condition_registry(this_cls):
    #
    #     if this_cls._condition_registry is None:
    #
    #         # Finding all the imported subclasses of 'BaseClass'
    #         imported_subclasses = [cls for name, cls in inspect.getmembers(
    #             inspect.getmodule(ImagineCondition), inspect.isclass) if issubclass(cls, ImagineCondition)]
    #
    #         this_cls._condition_registry = imported_subclasses
    #
    #     return this_cls._condition_registry
    #
    #
