from imagine.events.imagine_condition import ImagineCondition


class NeverCondition(ImagineCondition):

    def __init__(self, shorthand=""):
        super().__init__(shorthand)
    
    @property
    def condition_type(self):
        return 'Never'
    
    """ 
    This property is not needed in the python version.
    @property
    def figureName(self):
        return 'conditionPanel_Never.fig'
    """
    
    # @property
    # def handles_field(self):
    #     return 'NeverHandles'
    
    # def crop_name_has_changed(self, previous_name, new_name):
    #     pass
    #
    def get_longhand(self):
        return 'False'
    #
    # def load_condition(self, panel):
    #     pass
    #
    # def save_condition(self, panel):
    #     pass
    
    def is_triggered(self, sim, planted_crop):#*args):
        return False
    
    """
    This method is not needed in the python version.
    def setupFromOldStructure(self, s):
        pass
    """
