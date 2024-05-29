from imagine.events.imagine_condition import ImagineCondition


class AndOrNotCondition(ImagineCondition):
    logic_choices = ['And', 'Or', 'Not', 'Any', 'All']

    def __init__(self, logic_type, conditions, shorthand=""):
        super().__init__(shorthand)
        self.logic_type = logic_type
        self.conditions = conditions
#        self.indices = []

    @property
    def condition_type(self):
        return 'And / Or / Not'

    """
    Not required for the python version.
    @property
    def figure_name(self):
        return 'conditionPanel_AndOrNot.fig'
    
    @property
    def handles_field(self):
        return 'AndOrNotHandles'
    """

    # def crop_name_has_changed(self, previous_name, new_name):
    #     pass

    def get_longhand(self):
        if self.logic_type in ['And', 'Or']:
            lh = ['(']
            for i, cond in enumerate(self.conditions):
                if i > 0:
                    lh.append(' {} '.format(self.logic_type))
                lh.append(f'"{cond.get_longhand()}"')
            lh.append(')')
            return ''.join(lh)

        if self.logic_type in ['Any', 'All']:
            lh = [self.logic_type, '(']
            for i, cond in enumerate(self.conditions):
                if i > 0:
                    lh.append(', ')
                lh.append(f'"{cond.get_longhand()}"')
            lh.append(')')
            return ''.join(lh)

        elif self.logic_type == 'Not':
            if len(self.conditions) < 1:
                lh = 'NOT [No condition provided.]'
            elif len(self.conditions) == 1:
                lh = 'NOT {}'.format(f'"{self.conditions[0].get_longhand()}"')
            else:
                lh = 'NOT [Too many conditions entered. Choose 1.]'
            return lh

        else:
            raise ValueError(
                "Shouldn't get here as obj.logic_type should always be one of [And, Or, Not, Any, All]. "
                "If you get here, check the capitalization or other logic.")

    # You will need to implement the following methods based on your specific UI implementation:
    # - load_condition()
    # - save_condition()

    def is_triggered(self, sim, planted_crop): #condition_index=None, condition_truths=None):

        if self.logic_type in ['And', 'All']:
            truth_list = [cond.is_triggered(sim, planted_crop) for cond in self.conditions]
            return all(truth_list)
        elif self.logic_type in ['Any', 'Or']:
            # Implement lazy evaluation for Any/Or
            for cond in self.conditions:
                if cond.is_triggered(sim, planted_crop):
                    return True
            return False
        elif self.logic_type == 'Not':
            return not self.conditions[0].is_triggered(sim, planted_crop)
        else:
            raise ValueError(
                "Shouldn't get here as obj.logic_type should always be one of [And, Or, Not, Any, All]. "
                "If you get here, check the capitalization or other logic.")

        #
        # if condition_index is None or condition_truths is None:
        #     raise ValueError("isTriggered expects 2 arguments other than itself - the conditions's 1-based index and the list of condition truths of the previous conditions.")
        #
        # ranged_indices = [index for index in self.indices if 0 < index < condition_index]
        #
        # if len(condition_truths) < condition_index:
        #     raise ValueError("Must pass in the condition truths of all previous conditions in the list.")
        #
        # if self.logic_type == 'And':
        #     tf = True
        #     for ix in ranged_indices:
        #         tf = tf and condition_truths[ix]
        # elif self.logic_type == 'Or':
        #     tf = False
        #     for ix in ranged_indices:
        #         tf = tf or condition_truths[ix]
        # elif self.logic_type == 'Not':
        #     tf = not condition_truths[ranged_indices[0]]
        # else:
        #     tf = float('nan')
        #
        # return tf

    def is_valid(self, condition_index=None):
        valid = super().is_valid()
        valid = valid and isinstance(self.logic_type, str) and isinstance(self.indices, list)
        if not valid:
            return False

        valid = valid and self.logic_type in self.logic_choices and len(self.indices) > 0
        if self.logic_type == 'Not':
            valid = valid and len(self.indices) == 1

        if condition_index is not None:
            valid = valid and all(index < condition_index for index in self.indices)
            valid = valid and all(index >= 1 for index in self.indices)
            valid = valid and condition_index > 1

        return valid
