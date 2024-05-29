from imagine.regime import Regime
from imagine.core import ImagineObject, global_helpers
from imagine.crop.crop_manager import CropManager
from imagine.core.unit import Unit
from imagine.core.amount import Amount
import math
from imagine.events.imagine_condition import ImagineCondition
from imagine.events.regime_event_trigger import RegimeEventTrigger
#from pimagine.events.trigger import Trigger
from imagine.util.number_to_placing import number_to_placing
from dotwiz import DotWiz
import numpy as np
from imagine.events.condition_syntax import condition_helpers


class AnnualRegime(Regime):

    def __init__(self, d=None):
        super().__init__(d)     # Loads basic regime parameters from d
        self.regime_category = "Annual"
        self.type = "primary"
        self.rotation_list = []

        if isinstance(d, dict) and 'rotation_list' in d:
            self.rotation_list = d['rotation_list']

    @staticmethod
    def loadobj(s):
        if "category" not in s["rotation_list"]:
            for rotation in s["rotation_list"]:
                rotation["category"] = "Annual"
                rotation["DSE"] = 0
        return s

    def rotate(self):
        self.rotation_list = [self.rotation_list[-1]] + self.rotation_list[:-1]
        self.create_annual_regime_events()

    def get_exclusion_zone_width(self):
        return 0

    # Not required. This would launch the GUI for setting up the regime.
    # def setup_regime(self, regime_mgr, crop_mgr, regime_arguments):
    #     # Implement this method with the appropriate logic
    #     pass

    def get_crops_planted_in_year(self, year):
        if self.start_year <= year <= self.final_year:
            rot_index = (year - self.start_year) % len(self.rotation_list)
            rot = self.rotation_list[rot_index]
            return [rot["crop"], rot["companionCrop"]] if rot["companionCrop"] else [rot["crop"]]
        else:
            print("Tried to get information from a regime outside of when it is installed.")
            return []

    """
        PaddockLayout is a gui element, so removing this in the python version for now.
    def get_paddock_layout_in_year(self, year):
        if self.start_year <= year <= self.final_year:
            pl = PaddockLayout()

            # Set the foreground colour to the crop's colour.
            crop_mgr = CropManager.getInstance()
            crop_defs = crop_mgr.crop_definitions
            rot_index = (year - self.start_year) % len(self.rotation_list)

            crop_def = next(crop for crop in crop_defs if crop["name"] == self.rotation_list[rot_index]["crop"])
            pl.background_colour = crop_def["colour"]
            pl.should_show_belts = False
            pl.should_show_borders = False
            pl.should_show_woodlands = False
            pl.should_show_contours = False

            return pl
        else:
            print("Tried to get information from a regime outside of when it is installed.")
            return PaddockLayout.empty()
    """

    def calculate_outputs(self, sim=None):
        # Outputs returned by this regime:
        # Paddock
        # Area
        # DSE
        outputs_column = [
            Amount(0, global_helpers.paddock),
            Amount(0, global_helpers.ha),
            Amount(0, global_helpers.dse)
        ]

        if sim is None:
            return outputs_column

        im_ob = ImagineObject.get_instance()

        # Paddock
        # Set number of paddocks to 1.
        outputs_column[0].number = 1

        # Area

        # To work out the area we have to get the area of the
        # secondary regime, if one's installed. So we need to look
        # up the sim.
        secondary_regime = sim.current_secondary_installed_regime
        if secondary_regime is None:
            secondary_regime_area = 0
        else:
            amt = secondary_regime.get_amount(global_helpers.ha)
            if amt is not None:
                secondary_regime_area = amt.number
            else:
                secondary_regime_area = 0

        # Work out if the current planted primary crop has a NCZ
        # Give total area not including NCZ area.
        primary_planted_crop = sim.current_primary_planted_crop

        if primary_planted_crop and secondary_regime:
            ppc_state = primary_planted_crop.state
            if ppc_state:
                fns = ppc_state.keys()
                ix = next((i for i, v in enumerate(fns) if v == 'NCZWidth'), None)
                if ix is None or secondary_regime is None:
                    ncz_area = 0
                else:
                    ncz_width = ppc_state.get('NCZWidth', 0)
                    crop_interface_unit = Unit('', 'Crop Interface Length', 'm')
                    amt = secondary_regime.get_amount(crop_interface_unit)
                    if amt and ncz_width > 0:
                        ncz_area = amt.number * ncz_width / 10000
                    else:
                        ncz_area = 0
            else:
                ncz_area = 0
        else:
            ncz_area = 0

        total_area_ha = im_ob.paddock_width * im_ob.paddock_length / 10000
        primary_area = total_area_ha - secondary_regime_area - ncz_area

        outputs_column[1].number = primary_area

        # Calculate DSE
        year = sim.year
        rot_index = (year - (self.start_year - 1)) % len(self.rotation_list)

        if "DSE" in self.rotation_list[rot_index]:
            dse_per_ha = self.rotation_list[rot_index].DSE
        else:
            dse_per_ha = 0

        outputs_column[2].number = primary_area * dse_per_ha

        return outputs_column

    def get_regime_parameter(self, pname):
        p = []
        try:
            p = self.rotation_list
        except Exception as e:
            print(e)
        return p
    
    def is_valid(self):
        valid = True
        return valid
    
    def crop_name_has_changed(self, previous_name, new_name):
        for rotation in self.rotation_list:
            if rotation.crop == previous_name:
                rotation.crop = new_name
            if rotation.companion_crop == previous_name:
                rotation.companion_crop = new_name
                
        for crop_trigger in self.crop_event_triggers:
            if crop_trigger.crop_name == previous_name:
                crop_trigger.crop_name = new_name
            for event_trigger in crop_trigger.event_triggers:
                event_trigger.crop_name_has_changed(previous_name, new_name)

    # def get_regime_trigger(self, crop_name, event_name):
    #     try:
    #         return self.crop_event_triggers[crop_name][event_name]
    #     except KeyError:
    #         return None

    def create_events(self):
        crop_mgr = CropManager.get_instance()

        # crop_event_triggers is a dict indexed by crop name and event name.
        self.crop_event_triggers = DotWiz()

        rotation_crop_names = [rot_item.crop for rot_item in self.rotation_list]
        used_crop_names = list(set(rotation_crop_names))
        rot_length = len(self.rotation_list)
        start_year_index = self.start_year - 1
        final_year_index = self.final_year - 1

        # Crops may appear multiple times in the rotation. But the planting or harvest month may vary.
        # So the test for a particular crop is whether it passes one of the tests for each rotation slot.
        # (year is and month is) or (year is and month is) or (...)
        # each rotation index has a condition to trigger it for planting and for harvesting.
        rotation_plant_triggers = []
        rotation_harvest_triggers = []
        # We'll join the matching rotation appearances into Or condtions for each crop.
        for rot_index, rot in enumerate(self.rotation_list):
            rot_crop_cat = crop_mgr.get_crop_category(rot.crop)
            if rot_crop_cat == 'Pasture':
                rot.plant_month = 'Jan'
                rot.harvest_month = 'Dec'

            # Start year and final year are not given as indices. -1 to convert to 0 based index.

            step_years = "" if rot_length == 1 else f"{number_to_placing(rot_length)} "
            year_shorthand = f'{number_to_placing(rot_index+1)} year then every {step_years}year.'
            year_cond = condition_helpers.year_index_is(range(start_year_index + rot_index, final_year_index + 1, rot_length),
                                                        year_shorthand)
            plant_month_cond = condition_helpers.month_is(rot.plant_month)
            harvest_month_cond = condition_helpers.month_is(rot.harvest_month)
            rotation_plant_triggers.append(year_cond & plant_month_cond)
            # It might seems that we don't need the year index for the harvest trigger. If the crop is planted,
            # then we just need the harvest month. But the way we do this is to define the trigger for the crop, not
            # the planted crop. So it has to work for each rotation appearance. Because the month may change, we
            # can't end up with Any(month_is('Dec'), month_is('Nov'), month_is('Dec')) for example, for a
            # rotation where the harvest months are Dec, Nov, Dec.
            rotation_harvest_triggers.append(year_cond & harvest_month_cond)

        # Now we collate the indexed conditions into 'Or' conditions for each crop.
        for crop_name in used_crop_names:
            # Get the indices into the rotation list.
            rot_appearances = [i for i, val in enumerate(rotation_crop_names) if val == crop_name]
            rot = self.rotation_list[rot_appearances[0]]
            rot_crop_cat = crop_mgr.get_crop_category(rot.crop)

            plant_event_name = 'Establishment' if rot_crop_cat == 'Pasture' else 'Planting'
            harvest_event_name = 'Destruction' if rot_crop_cat == 'Pasture' else 'Harvesting'

            plant_conds = [rotation_plant_triggers[i] for i in rot_appearances]
            harvest_conds = [rotation_harvest_triggers[i] for i in rot_appearances]

            self.crop_event_triggers[crop_name] = {}
            self.crop_event_triggers[crop_name][plant_event_name] = condition_helpers.any(plant_conds)
            self.crop_event_triggers[crop_name][harvest_event_name] = condition_helpers.any(harvest_conds)
