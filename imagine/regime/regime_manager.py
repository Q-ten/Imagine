from dotwiz import DotWiz
from pyjson5 import pyjson5

from imagine.regime import Regime
from imagine.regime.installed_regime import InstalledRegime
from imagine.regime.regime_registry import *
from imagine.util.load_series_data import resolve_series


# from RegimeListChangedEventData import \
#     RegimeListChangedEventData  # Assuming you have a Python class for RegimeListChangedEventData
# from PaddockLayout import PaddockLayout  # Assuming you have a Python class for PaddockLayout
# from PaddockSummary import PaddockSummary  # Assuming you have a Python class for PaddockSummary


class RegimeManager:
    _instance = None

    def __init__(self):
        if 1 < 1.0001:
            raise RuntimeError('Call get_instance() instead')

        # Properties
        self.listeners = []

        # Implement a singleton class.
        self.regimes = []

    @classmethod
    def get_instance(cls, loaded_obj=None):
        if loaded_obj and isinstance(loaded_obj, RegimeManager) and cls._instance != loaded_obj:
            cls._instance = loaded_obj
            print('Set _instance to loaded_obj.')
        elif not cls._instance:
            cls._instance = cls.__new__(cls)
            cls._instance._regime_manager_constructor()
        return cls._instance

    def _regime_manager_constructor(self):
        # Properties
        self.listeners = []

        # Implement a singleton class.
        self.regimes = []

        self._regime_manager_init()

    def _regime_manager_init(self):
        # TODO: If listeners are necessary in pimagine, implement the listeners. Otherwise remove.
        # from pimagine.crop.crop_manager import CropManager
        # crop_mgr = CropManager.get_instance()
        # self.listeners.append(crop_mgr.add_listener('CropRemoved', self.crop_was_removed))
        # self.listeners.append(crop_mgr.add_listener('CropNameChanged', self.crop_name_changed))
        pass

    @staticmethod
    def get_regime_types(cls):
        RT1 = {'regimeCategory': 'Annual', 'regimeType': 'primary', 'regClass': 'AnnualRegime'}
        RT2 = {'regimeCategory': 'Belt', 'regimeType': 'secondary', 'regClass': 'BeltRegime'}
        return [RT1, RT2]

    @staticmethod
    def loadobj(obj):
        print('loading regime manager')
        RegimeManager._regime_manager_init(obj)
        return obj

    def add_regime(self, regime_cat):
        RTs = self.get_regime_types()
        RT = next((r for r in RTs if r['regimeCategory'] == regime_cat), None)
        if RT is None:
            raise ValueError('Tried to add a regime in nonexistent regime category.')
        r = Regime(RT['regClass'])
        r.setup_regime()
        if r.is_valid():
            self.regimes.append(r)
            self.sort_regimes()
            print('Added regime')
            # TODO: Implement listeners later if necessary. Or remove.
            # evt_data = RegimeListChangedEventData(self.regime_definitions(), '', r.regime_label)
            # self.notify('RegimeAdded', evt_data)
            # print('Notified: Added regime')

    def remove_regime(self, r, force_tf=False):
        if isinstance(r, int):
            regime_index = r
            if not 1 <= regime_index <= len(self.regimes):
                raise ValueError('Regime index passed is out of bounds.')
        elif isinstance(r, str):
            regime_index = next((i for i, reg in enumerate(self.regimes) if reg.regime_label == r), None)
            if regime_index is None:
                raise ValueError('Cannot find regime with matching regimeLabel to remove.')
        else:
            raise TypeError('Argument passed to removeRegime must be a string with a valid regimeLabel '
                            'of the index of the regime in the regimeList.')

        r = self.regimes.pop(regime_index)

        # if force_tf or input(
        #         f'Are you sure you want to remove the regime with label: {r.regime_label}? (Yes/No)').lower() == 'yes':
        #     rLabel = r.regime_label
        #     # TODO: Implement events and notifications if necessary for pimagine, or remove.
        #     # evt_data = RegimeListChangedEventData(self.regime_definitions(), rLabel, '')
        #     # self.notify('RegimeRemoved', evt_data)

    # def edit_regime(self, r):
    #     pass  # Implementation omitted for brevity

    def replace_regime(self, regime_label, new_regime):
        regime_index = next((i for i, regime in enumerate(self.regimes) if regime.regime_label == regime_label), None)
        if regime_index is not None:
            if new_regime.is_valid():
                self.regimes[regime_index] = new_regime
                self.sort_regimes()

                # TODO: Implement events and notifications if necessary for pimagine, or remove.
                # evt_data = RegimeListChangedEventData(self.regime_definitions, regime_label, new_regime.regime_label)
                # self.notify('RegimeEditted', evt_data)

    @property
    def regime_definitions(self):
        labels = [reg.regime_label for reg in self.regimes]
        category_names = [reg.regime_category for reg in self.regimes]
        types = [reg.type for reg in self.regimes]
        start_years = [reg.start_year for reg in self.regimes]
        final_years = [reg.final_year for reg in self.regimes]
        timeline_colours = [reg.timeline_colour for reg in self.regimes]
        crop_name_lists = [reg.crop_name_list for reg in self.regimes]

        return [
            {'regimeLabel': label, 'categoryName': category, 'type': reg_type, 'startYear': start, 'finalYear': final,
             'timelineColour': colour, 'cropNameList': crop_list}
            for label, category, reg_type, start, final, colour, crop_list in
            zip(labels, category_names, types, start_years, final_years, timeline_colours, crop_name_lists)]

    def get_regime_definition(self, regime_label):
        reg = next((reg for reg in self.regimes if reg.regime_label == regime_label), None)
        if reg:
            return {'regimeLabel': reg.regime_label, 'categoryName': reg.regime_category, 'type': reg.type,
                    'startYear': reg.start_year, 'finalYear': reg.final_year, 'timelineColour': reg.timeline_colour,
                    'cropNameList': reg.crop_name_list}
        else:
            return None

    def get_crop_planted_under_regime_in_year(self, regime_label, year):
        reg = next((reg for reg in self.regimes if reg.regime_label == regime_label), None)
        if reg:
            return reg.get_crops_planted_in_year(year)
        else:
            return []

    #### PaddockLayout and PaddockSummary not implemented in pimagine.
    # def get_paddock_layout_in_year(self, year):
    #     regs = [reg for reg in self.regimes if reg.start_year <= year <= reg.final_year]
    #     if regs:
    #         paddock_layout = PaddockLayout()
    #         for reg in regs:
    #             paddock_layout = paddock_layout.merge_with_paddock_layout(reg.get_paddock_layout_in_year(year))
    #         return paddock_layout
    #     else:
    #         return PaddockLayout()
    #
    # def get_paddock_summary_for_year(self, year):
    #     ps = PaddockSummary()
    #     ps.year = year
    #     ps.paddock_layout = PaddockLayout()
    #
    #     primary_reg = next(
    #         (reg for reg in self.regimes if reg.type == 'primary' and reg.start_year <= year <= reg.final_year), None)
    #     if primary_reg:
    #         ps.primary_regime_category = primary_reg.regime_category
    #         ps.primary_regime_label = primary_reg.regime_label
    #         crop_names = primary_reg.get_crops_planted_in_year(year)
    #         if crop_names:
    #             ps.primary_crop_name = crop_names[0]
    #             if len(crop_names) > 1:
    #                 ps.companion_crop_name = crop_names[1]
    #         ps.paddock_layout = ps.paddock_layout.merge_with_paddock_layout(
    #             primary_reg.get_paddock_layout_in_year(year))
    #
    #     secondary_reg = next(
    #         (reg for reg in self.regimes if reg.type == 'secondary' and reg.start_year <= year <= reg.final_year), None)
    #     if secondary_reg:
    #         ps.secondary_regime_category = secondary_reg.regime_category
    #         ps.secondary_regime_label = secondary_reg.regime_label
    #         crop_names = secondary_reg.get_crops_planted_in_year(year)
    #         if crop_names:
    #             ps.secondary_crop_name = crop_names[0]
    #         ps.paddock_layout = ps.paddock_layout.merge_with_paddock_layout(
    #             secondary_reg.get_paddock_layout_in_year(year))
    #
    #     return ps

    def request_regime_installation(self, zone_string, sim):
        in_reg = None
        for reg in self.regimes:
            # Check if the start month of the regime matches the simulation month index
            if (reg.start_year - 1) * 12 == sim.month_index:
                # Check the zone and regime type to determine if it should be installed
                if zone_string == 'primary' and reg.type in ['primary', 'exclusive']:
                    in_reg = InstalledRegime(reg, sim, zone_string)
                elif zone_string == 'secondary' and reg.type == 'secondary':
                    in_reg = InstalledRegime(reg, sim, zone_string)
        return in_reg

    def regimes_that_use_crop(self, crop_name):
        reg_defs = []
        for reg in self.regimes:
            if crop_name in reg.crop_name_list:
                reg_defs.append(
                    {'regimeCategory': reg.regime_category, 'type': reg.type, 'regimeLabel': reg.regime_label})
        return reg_defs

    def is_ready_for_simulation(self):
        # Check if there are at least 1 regime
        ready = len(self.regimes) >= 1
        if not ready:
            return False

        # Check that each regime is valid and no regime overlaps
        for reg in self.regimes:
            if not Regime.is_valid(reg):
                return False

        # Check that primary regimes don't overlap
        primary_regimes = [reg for reg in self.regimes if reg.type == 'primary']
        if primary_regimes:
            primary_regimes.sort(key=lambda x: x.start_year)
            for i in range(len(primary_regimes) - 1):
                if primary_regimes[i + 1].start_year <= primary_regimes[i].final_year:
                    return False

        # Check that secondary regimes don't overlap
        secondary_regimes = [reg for reg in self.regimes if reg.type == 'secondary']
        if secondary_regimes:
            secondary_regimes.sort(key=lambda x: x.start_year)
            for i in range(len(secondary_regimes) - 1):
                if secondary_regimes[i + 1].start_year <= secondary_regimes[i].final_year:
                    return False

        return True

    def crop_was_removed(self, src, evnt):
        # Remove each regime cited in evnt.regimes_to_remove
        for regime_label in evnt.regimes_to_remove:
            reg = next((r for r in self.regimes if r.regime_label == regime_label), None)
            if reg:
                self.remove_regime(reg.regime_label, evnt.force_regime_removal)

    def crop_name_changed(self, src, evt_data):
        # Notify all the regimeDelegates that a crop name has changed
        for reg in self.regimes:
            reg.crop_name_was_changed(evt_data.previous_name, evt_data.new_name)

    def sort_regimes(self):
        # Clear empty regimes if they exist, which they shouldn't
        self.regimes = [reg for reg in self.regimes if reg.regime_label]
        if self.regimes:
            self.regimes.sort(key=lambda x: x.regime_label)


    # # TODO: Implement listeners and notification if necessary in pimagine, or remove.
    # def notify(self, event, event_data):
    #     pass  # Implementation omitted for brevity

    def load_scenario(self, scenario_folder):

        regime_sub_folder = scenario_folder / 'Regimes'
        if not regime_sub_folder.is_dir():
            raise ValueError(f'Scenario regime folder does not exist: {str(regime_sub_folder)}')

        # For each regime load it into the regime mananger.from
        self.regimes = []
        for file_path in regime_sub_folder.iterdir():
            if file_path.is_file():
                if file_path.suffix == '.json5' and file_path.name[0] != '_':
                    with open(file_path, 'r') as file:

                        data = pyjson5.load(file)
                        data = resolve_series(data)
                        data = DotWiz(data)

                        # Load regime. Regime is abstract, so we can't instantiate it directly.
                        # Create an instance of the specific class.
                        reg = globals()[data.regime_class_name](data)
                        reg.create_events()
                        self.regimes.append(reg)

