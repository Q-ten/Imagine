from abc import ABC, abstractmethod


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

    @abstractmethod
    def is_triggered(self, sim, planted_crop):
        pass

    @abstractmethod
    def get_longhand(self, *args):
        pass

    def is_valid(self):
        return isinstance(self, ImagineCondition)


