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

    def is_triggered(self, sim, planted_crop):

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
