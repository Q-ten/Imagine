from imagine.events.imagine_condition import ImagineCondition


class MonthBasedCondition(ImagineCondition):

    MONTH_STRINGS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    # Implement the abstract properties from ImagineCondition
    @property
    def condition_type(self):
        return 'Month Based'

    @property
    def handles_field(self):
        return 'MonthBasedHandles'

    # Define the properties for the MonthBasedCondition
    def __init__(self, month_index, shorthand=""):
        super().__init__(shorthand)
        if not 0 <= month_index <= 11:
            raise ValueError("MonthBasedCondition failed to construct. month_index should be in [0, 11]")
        self.month_index = month_index

    def crop_name_has_changed(self, previous_name, new_name):
        pass

    def get_longhand(self):
        if 0 <= self.month_index <= 11:
            return f"Month is {MonthBasedCondition.MONTH_STRINGS[self.month_index]}"
        else:
            return 'Invalid month definition.'

    def is_triggered(self, sim, planted_crop):
        return sim.month_index % 12 == self.month_index

    @staticmethod
    def is_valid(cond):
        valid = ImagineCondition.is_valid(cond)
        valid = valid and isinstance(cond, MonthBasedCondition)
        valid = valid and isinstance(cond.month_index, int)
        valid = valid and len([cond.month_index]) == 1
        if valid:
            valid = valid and 0 <= cond.month_index <= 11
        return valid
