from dotwiz import DotWiz

from imagine.core import ImagineObject
from imagine.core.amount import Amount
from imagine.core.unit import Unit
from imagine.crop.crop_manager import CropManager
from imagine.events.condition_syntax import condition_helpers
from imagine.regime import Regime
from imagine.util.absorb_fields import absorb_fields
import imagine.core.global_helpers as gh
from imagine.util.get_month_index_from_month import get_month_index_from_month


# The BeltRegimeDelegate is the concrete subclass of RegimeDelegate that
# provides the implementation of the 'Belt' regime category. It is a
# 'secondary' regime - that is it covers part of the paddock and takes
# space away from the primary regime.
#
# The Belt regime defines a layout for a woody crop plantation, where crops
# are planted in rows and the rows appear in 'belts' spaced equally through
# the paddock and also 'borders' which flank the four edges of the paddock.
# The user can choose whether to include belts or borders, but the regime
# must contains at least one type.
#
# Planting is a unique event, with the crop surviving thereafter. The
# harvests are 'coppice' harvests where the Above ground biomass is
# harvested and sold, but the crops grow back from the stump.
#
# The user has a choice as to how the harvest dates are specified. There
# may be a fixed schedule defined by the user, or perhaps the crop is
# harvested when it reaches a particualr level, or the user can define a
# more complicated scheme.


class BeltRegime(Regime):

    def __init__(self, d=None):
        self.fixed_outputs = None
        self.belt_regime_parameters = DotWiz({
            'use_belts': None,
            'use_borders': None,
            'crop': None,
            'harvest_years': None,
            'plant_month': None,
            'harvest_month': None,
            'rows_per_belt': None,
            'row_spacing': None,
            'exclusion_zone': None,
            'plant_spacing': None,
            'headland': None,
            'belt_num': None,
            'biomass_threshold': None,
            'biomass_threshold_unit': None,
        })
        if isinstance(d, dict):
            self.load_regime(d)
        super().__init__(d)
        self.regime_category = 'Belt'
        self.type = 'secondary'


    def get_exclusion_zone_width(self):
        return self.belt_regime_parameters['exclusion_zone']

    ### Not using gui.
    # def setup_regime(self):
    #     regime_mgr = RegimeManager.get_instance()
    #     crop_mgr = CropManager.get_instance()
    #     regime_arguments = {
    #         'regime_definitions': regime_mgr.regime_definitions,
    #         'crop_definitions': crop_mgr.crop_definitions
    #     }
    #
    #     if self.crop_event_triggers:
    #         passed_regime_parameters = {
    #             'regime_label': self.regime_label,
    #             'start_year': self.start_year,
    #             'final_year': self.final_year,
    #             'timeline_colour': self.timeline_colour,
    #             'crop_event_triggers': self.crop_event_triggers,
    #             'belt_regime_parameters': self.belt_regime_parameters
    #         }
    #         regime_arguments['regime_parameters'] = passed_regime_parameters
    #
    #     reg_out = BeltRegimeDialog(regime_arguments)
    #
    #     if reg_out:
    #         self.regime_label = reg_out.regime_label
    #         self.start_year = reg_out.start_year
    #         self.final_year = reg_out.final_year
    #         self.timeline_colour = reg_out.timeline_colour
    #         self.belt_regime_parameters = reg_out.parameters
    #         self.crop_event_triggers = reg_out.crop_event_triggers

    def calculate_outputs(self, sim=None):
        # Outputs returned by this regime:
        # Paddock
        # Area
        # Tree
        # Belt length
        # Row length
        if self.fixed_outputs is None:

            im_ob = ImagineObject.get_instance()
            paddock_length = im_ob.paddock_length
            paddock_width = im_ob.paddock_width
            params = self.belt_regime_parameters

            # Paddock
            # unit = Unit('', 'Paddock', 'Unit')
            outputs_column = [Amount(1, gh.paddock)]

            # Area
            # To work out the area we have to get the area of the
            # secondary regime, if one's installed. So we need to look
            # up the sim.
            # unit = Unit('', 'Area', 'Hectare')

            border_area = 0
            belt_area = 0
            belt_width = 0
            border_width = 0

            if params['use_belts']:
                belt_width = (params['rows_per_belt'] - 1) * params['row_spacing'] + params['exclusion_zone'] * 2
                belt_length = paddock_length - 2 * params['headland']
                belt_num = params['belt_num']

                belt_area = belt_width * belt_length * belt_num

            # We use only one side having the exclusion zone.
            if params['use_borders']:
                border_width = (params['rows_per_belt'] - 1) * params['row_spacing'] + params['exclusion_zone'] * 2
                border_length = (paddock_length + paddock_width) * 2 - 8 * params['gap_length_at_corners']
                border_area = border_width * border_length

            am = Amount((belt_area + border_area) / 10000, gh.ha)
            outputs_column.append(am)

            self.belt_regime_parameters.belt_width = belt_width

            # Trees
            # unit = Unit('', 'Tree', 'Unit')

            belt_trees = 0
            if params['use_belts']:
                belt_length = (paddock_length - 2 * params['headland'])
                rows_per_belt = params['rows_per_belt']
                plant_spacing = params['plant_spacing']

                belt_trees = ((belt_length // plant_spacing + 1) * rows_per_belt) * params['belt_num']

            # We use only one side having the exclusion zone.
            border_trees = 0
            if params['use_borders']:
                side1 = paddock_length - 2 * params['gap_length_at_corners']
                side2 = paddock_width - 2 * params['gap_length_at_corners']
                rows_per_belt = params['rows_per_belt']
                plant_spacing = params['plant_spacing']

                border_trees = ((side1 // plant_spacing + 1 + side2 // plant_spacing + 1) * rows_per_belt * 2)

            am = Amount(border_trees + belt_trees, gh.trees)
            outputs_column.append(am)

            # Km of Belts
            # unit = Unit('', 'Belts', 'Km')

            belt_length = 0
            border_length = 0
            belt_num = params['belt_num']
            if params['use_belts']:
                belt_length = (paddock_length - 2 * params['headland']) * belt_num
            if params['use_borders']:
                border_length = (paddock_length + paddock_width) * 2 - 8 * params['gap_length_at_corners']
            rows_per_belt = params['rows_per_belt']

            am = Amount((belt_length + border_length) / 1000, gh.km_of_belts)
            outputs_column.append(am)

            # And Km of Rows
            # unit = Unit('', 'Rows', 'Km')
            am = Amount(((belt_length + border_length) * rows_per_belt) / 1000, gh.km_of_rows)
            outputs_column.append(am)

            # Might need a cropInterface Amount too.
            # unit = Unit('', 'Crop Interface Length', 'm')
            am = Amount(belt_length * 2 + belt_width * belt_num * 2 + border_length + 8 * border_width,
                        gh.crop_interface_length)
            outputs_column.append(am)

            self.fixed_outputs = outputs_column

        return self.fixed_outputs

    def get_regime_parameter(self, pname):
        try:
            return self.belt_regime_parameters[pname]
        except KeyError:
            return None

    def get_crops_planted_in_year(self, year):
        return [self.belt_regime_parameters['crop']]

    # Not needed in pimagine. paddock layout is a GUI thing.
    # def get_paddock_layout_in_year(self, year):
    #     # Implementation for getting paddock layout in Python
    #     pass

    def is_valid(self):
        return True

    def crop_name_has_changed(self, previous_name, new_name):
        if self.belt_regime_parameters['crop'] == previous_name:
            self.belt_regime_parameters['crop'] = new_name
        for trigger in self.crop_event_triggers:
            if trigger['crop_name'] == previous_name:
                trigger['crop_name'] = new_name
            for event_trigger in trigger['event_triggers']:
                event_trigger.crop_name_has_changed(previous_name, new_name)

    def load_regime(self, d):
        simple_fields = ["crop",
                         "use_belts",
                         "use_borders",
                         "belt_num",
                         "rows_per_belt",
                         "row_spacing",
                         "plant_spacing",
                         "headland",
                         "exclusion_zone",
                         "coppice_trigger_type",
                         "harvest_month",
                         "plant_month",
                         "harvest_years"
                         ]
        absorb_fields(self.belt_regime_parameters, d.belt_regime_parameters, simple_fields)

    def create_events(self):

        # crop_event_triggers is a dict indexed by crop name and event name.
        self.crop_event_triggers = DotWiz()

        plant_event_name = 'Planting'
        harvest_event_name = 'Destructive Harvesting'

        plant_year_cond = condition_helpers.year_index_is(self.start_year - 1)
        plant_month_cond = condition_helpers.month_is(self.belt_regime_parameters.plant_month)
        harvest_year_cond = condition_helpers.year_index_is(self.final_year - 1)
        harvest_month_cond = condition_helpers.month_is(self.belt_regime_parameters.harvest_month)

        crop_name = self.belt_regime_parameters.crop
        self.crop_event_triggers[crop_name] = {}
        self.crop_event_triggers[crop_name][plant_event_name] = plant_year_cond & plant_month_cond
        self.crop_event_triggers[crop_name][harvest_event_name] = harvest_year_cond & harvest_month_cond

