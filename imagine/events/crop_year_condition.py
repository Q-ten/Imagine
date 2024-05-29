from imagine.events.imagine_condition import ImagineCondition
from imagine.util.number_to_placing import number_to_placing


# True if the crop is in it's (crop_year)th calendar year. It's not how old it is, which might reasonably start at
# 0 and only get to 1 after 12 months. It's also by the calendar year.
# If it's planted in Dec, then next Jan it's year 2.
class CropYearCondition(ImagineCondition):

    # Implement the abstract properties from ImagineCondition
    @property
    def condition_type(self):
        return 'Crop Year'

    # Define the properties for the CropYearCondition
    def __init__(self, crop_year, shorthand=""):
        super().__init__(shorthand)
        if not isinstance(crop_year, int):
            raise ValueError("CropYearCondition failed to construct. crop_year should be a positive int.")
        self.crop_year = crop_year

    def crop_name_has_changed(self, previous_name, new_name):
        pass

    def get_longhand(self):
        from imagine.core import ImagineObject
        imob = ImagineObject.get_instance()
        if 0 <= self.crop_year <= imob.simulation_length:
            return f"Crop is in it's {number_to_placing(self.crop_year)} calendar year."
        else:
            return 'Invalid crop_year definition.'

    # A general method for determining if the condition is true.
    def is_triggered(self, sim, planted_crop):  # *args):
        return sim.month_index // 12 + 1 == self.crop_year

    @staticmethod
    def is_valid(cond):
        valid = ImagineCondition.is_valid(cond)
        valid = valid and isinstance(cond, CropYearCondition)
        valid = valid and isinstance(cond.crop_year, int)
        if valid:
            from imagine.core import ImagineObject
            imob = ImagineObject.get_instance()
            valid = valid and 0 <= cond.month_index <= imob.simulation_length
        return valid
