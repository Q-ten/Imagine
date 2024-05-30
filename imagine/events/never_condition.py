from imagine.events.imagine_condition import ImagineCondition


class NeverCondition(ImagineCondition):

    def __init__(self, shorthand=""):
        super().__init__(shorthand)
    
    @property
    def condition_type(self):
        return 'Never'

    def get_longhand(self):
        return 'False'

    def is_triggered(self, sim, planted_crop):
        return False
    
