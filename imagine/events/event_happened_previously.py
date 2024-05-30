from imagine.events.imagine_condition import ImagineCondition
from imagine.util.helper_tests import is_int, is_list_like


class EventHappenedPreviouslyCondition(ImagineCondition):
    comparator_options = ['=', '<', '>', '<=', '>=']
    max_month_index = 600 - 1

    def __init__(self, event_name, months_prior, comparator="=", shorthand=""):
        super().__init__(shorthand)
        self.event_name = event_name
        self.comparator = comparator
        if isinstance(months_prior, str) and months_prior.isnumeric():
            try:
                mp = int(months_prior)
            except ValueError:
                mp = None  # Return None if the parsing fails
            if mp:
                self.months_prior = mp
        else:
            self.months_prior = months_prior

    @property
    def condition_type(self):
        return 'Event Happened Previously'

    def get_longhand(self):
        if not self.event_name:
            return '[No event chosen]'

        if not self.is_valid():
            return '[EventHappenedPreviously invalid configuration]'

        comp_string = {
            '=': 'exactly ',
            '<': 'less than ',
            '<=': 'less than or exactly ',
            '>=': 'more than or exactly ',
            '>': 'more than '
        }.get(self.comparator, 'Compstring not recognised')

        one_of_string = ""
        if is_list_like(self.months_prior):
            one_of_string = "one of "

        return f"{self.event_name} event occurred {comp_string}{one_of_string}{self.months_prior} months prior"

    def is_triggered(self, sim, planted_crop):
        sim_month_index = sim.month_index
        occurrences = planted_crop.occurrences

        if sim_month_index is None or occurrences is None:
            raise ValueError(
                "isTriggered expects 2 arguments other than itself - the sim's monthIndex and the plantedCrop's occurrences.")

        if self.comparator == '=':
            month_indices_to_check = [sim_month_index - self.months_prior]
        elif self.comparator == '<=':
            month_indices_to_check = list(range(1, sim_month_index - self.months_prior + 1))
        elif self.comparator == '>=':
            month_indices_to_check = list(range(sim_month_index - self.months_prior, sim_month_index + 1))
        elif self.comparator == '<':
            month_indices_to_check = list(range(sim_month_index - self.months_prior + 1, sim_month_index + 1))
        elif self.comparator == '>':
            month_indices_to_check = list(range(1, sim_month_index - self.months_prior))
        else:
            raise ValueError("Error in Simulation.isTriggered, Event Happened Previously. Unrecognized comparator.")

        for occurrence in occurrences:
            if occurrence.event_name == self.event_name:
                if occurrence.month_index in month_indices_to_check:
                    return True

        return False

    @classmethod
    def _valid_int(cls, x):
        return is_int(x) and 0 <= x <= cls.max_month_index

    def is_valid(self, event_names=None, this_event=None):
        valid = super().is_valid()
        valid = valid and isinstance(self.event_name, str) and len(self.event_name) > 0
        valid = valid and self.comparator in self.comparator_options

        valid = valid and self._valid_int(self.months_prior) or (is_list_like(self.months_prior, self._valid_int)
                                                                 and self.comparator == "=")
        if not valid:
            return False

        if event_names is not None and this_event is not None:
            if self.months_prior == 0:
                this_event_index = event_names.index(this_event)
                previous_event_index = event_names.index(self.event_name)
                if previous_event_index is None:
                    raise ValueError(
                        "You've passed in a list of event names that doesn't contain the previous event name.")
                valid = valid and previous_event_index < this_event_index
            valid = valid and self.event_name in event_names

        return valid
