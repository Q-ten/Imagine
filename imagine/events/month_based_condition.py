from imagine.events.imagine_condition import ImagineCondition


class MonthBasedCondition(ImagineCondition):

    MONTH_STRINGS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    # Implement the abstract properties from ImagineCondition
    @property
    def condition_type(self):
        return 'Month Based'
    
    """
    This method is not required in the python version.
    @property
    def figure_name(self):
        return 'conditionPanel_MonthBased.fig'
    """        
    
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

    """
    These methods are not required in the python version.

    # Loads a set of controls into the panel and returns the handles to
    # them as subHandles.
    def load_condition(self, panel):

        # First find our controls in handles.
        # If they're not there, there's an error.
        handles = panel.guidata()

        if hasattr(handles, self.handles_field):
            new_controls = getattr(handles, self.handles_field)
        else:
            raise ValueError('The panel provided lives in a figure that '
                             'doesn\'t have the requisite controls to load '
                             'the condition data into.')

        # Now to start populating the controls.
        new_controls.popupmenuMonthChoice.setStrings(MonthBasedCondition.MONTH_STRINGS)
        new_controls.popupmenuMonthChoice.setValue(self.month_index)

    # Uses the controls in subHandles to extract the parameters that
    # define this condition.
    def save_condition(self, panel):

        # First find our controls in handles.
        # If they're not there, there's an error.
        handles = panel.guidata()

        if hasattr(handles, self.handles_field):
            new_controls = getattr(handles, self.handles_field)
        else:
            raise ValueError('The panel provided lives in a figure that '
                             'doesn\'t have the requisite controls to load '
                             'the condition data into.')

        self.month_index = new_controls.popupmenuMonthChoice.getValue()

    """

    # A general method for determining if the condition is true.
    def is_triggered(self, sim, planted_crop):#*args):
        return sim.month_index % 12 == self.month_index

        # # Initialise all trigger checks with nan to indicate that it
        # # can't be found at this point.
        # TF = float('nan')
        # # Expect in the current monthIndex.
        # if len(args) == 1:
        #     sim_month_index = args[0]
        #     try:
        #         TF = sim_month_index % 12 == self.month_index
        #     except TypeError:
        #         pass
        # else:
        #     raise ValueError('MonthBasedCondition: isTriggered expects 1 argument '
        #                      'other than itself - the sim\'s monthIndex.')
        # return TF

    """ 
    This method is not required in the python version.
    @staticmethod
    def setup_from_old_structure(obj, s):
        obj.month_index = s.value2
    """

    @staticmethod
    def is_valid(cond):
        valid = ImagineCondition.is_valid(cond)
        valid = valid and isinstance(cond, MonthBasedCondition)
        valid = valid and isinstance(cond.month_index, int)
        valid = valid and len([cond.month_index]) == 1
        if valid:
            valid = valid and 0 <= cond.month_index <= 11
        return valid
