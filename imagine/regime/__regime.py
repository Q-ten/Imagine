from abc import ABC, abstractmethod

import numpy as np
from dotwiz import DotWiz

from imagine.core import ImagineObject
from imagine.util.absorb_fields import absorb_fields


class Regime(ABC):
    """
    In the matlab version, a Regime had a RegimeDelegate that did all the
    work. This was so that a concrete class (Regime) could be in an array.
    Matlab wouldn't let the type of a matrix be an abstract class.
    RegimeDelegate was abstract, so objects could be of multiple subclassed types.
    In the python version we'll just make the Regime class. Regime will be
    abstract and it's subclasses will implement specific logic.
    """

    def __init__(self, d=None):
        self.regime_category = ''
        self.type = ''
        self.regime_label = ''
        self.start_year = 0
        self.final_year = 0
        self.timeline_colour = ''
        self.crop_event_triggers = DotWiz()

        self.regime_rate_defs = DotWiz({
            'output_rates': []
        })

        if isinstance(d, dict):
            self.load_basic_regime(d)

    # setup_regime calls the GUI. Not needed for pimagine.
    # @abstractmethod
    # def setup_regime(self):
    #     pass

    @abstractmethod
    def calculate_outputs(self, sim):
        pass

    @abstractmethod
    def get_crops_planted_in_year(self, year):
        pass

    """
    PaddockLayout is a gui element from the matlab version.
    Removing this method for now.
    @abstractmethod
    def get_paddock_layout_in_year(self, year):
        pass
    """

    @abstractmethod
    def is_valid(self):
        pass

    @abstractmethod
    def get_exclusion_zone_width(self):
        pass

    @abstractmethod
    def crop_name_has_changed(self, previous_name, new_name):
        pass

    @abstractmethod
    def get_regime_parameter(self, pname):
        pass

    @property
    def crop_name_list(self):
        return self.crop_event_triggers.keys()
#        return [cet.crop_name for cet in self.crop_event_triggers]

    @staticmethod
    def is_valid(r):
        if not r:
            return False

        if not r.regime_label:
            return False

        return bool(r.timeline_color)

    @abstractmethod
    def create_events(self):
        pass

    def load_basic_regime(self, d):
        simple_fields = ['regime_label', 'start_year', 'final_year', 'timeline_colour']
        absorb_fields(self, d, simple_fields)

        self.regime_rate_defs.output_rates = self.calculate_outputs()

    def get_regime_trigger(self, crop_name, event_name):
        try:
            return self.crop_event_triggers[crop_name][event_name]
        except KeyError:
            return None