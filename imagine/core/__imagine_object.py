# ImagineObject
#
# This class is a place to store references to the Manager objects in
# Imagine.
#
# It is a singleton object, and whenever the static method is called, it
# should return the ImagineObject. This makes it act like a global
# variable, but it's actually elegant.
import pathlib
import pickle
import pkgutil
from pathlib import Path

from dotwiz import DotWiz

from imagine.util.always import always


class ImagineObject:
    __instance = None

    def __init__(self):
        if always():
            raise RuntimeError('Call get_instance() instead')

        # Warning - these settings are never called. These fields are set to suppress IDE warnings.
        # Set them in initialise_imagine()
        self.paddock_width = 1000
        self.paddock_length = 1000
        self.paddock_spacing = 1000
        self.simulation_length = 50

        self.climate_manager = None
        self.crop_manager = None
        self.simulation_manager = None
        self.regime_manager = None

        self.folders = None

        self.loadPath = ''
        self.savePath = ''

    @classmethod
    def get_instance(cls, loaded_obj=None):

        if not cls.__instance:
            cls.__instance = cls.__new__(cls)
            cls.__instance.initialise_imagine()

        if loaded_obj is not None:
            if isinstance(loaded_obj, ImagineObject) and cls.__instance != loaded_obj:
                from imagine.crop.crop_manager import CropManager
                from imagine.regime.regime_manager import RegimeManager
                from imagine.climate.climate_manager import ClimateManager

                cls.__instance.crop_manager = CropManager.getInstance(loaded_obj.crop_manager)
                cls.__instance.regime_manager = RegimeManager.getInstance(loaded_obj.regime_manager)
                cls.__instance.climate_manager = ClimateManager.getInstance(loaded_obj.climate_manager)

            else:
                print("Tried passing an object that's not an ImagineObject to ImagineObject.getInstance.")

        return cls.__instance

    def initialise_imagine(self):

        # The init method for the singleton object.
        self.paddock_width = 1000
        self.paddock_length = 1000
        self.paddock_spacing = 1000
        self.simulation_length = 50

        from imagine.crop.crop_manager import CropManager
        from imagine.regime.regime_manager import RegimeManager
        from imagine.simulation.simulation_manager import SimulationManager
        from imagine.climate.climate_manager import ClimateManager

        self.crop_manager = CropManager.get_instance()
        self.regime_manager = RegimeManager.get_instance()
        self.climate_manager = ClimateManager.get_instance()
        self.simulation_manager = SimulationManager.get_instance()
        self.simulation_manager.refresh_manager_pointers()

        self.folders = DotWiz()
        self.set_resources_folder()

    def set_paddock_size(self, width, length):
        self.paddock_width = width
        self.paddock_length = length

    def clear_simulations(self):
        self.simulation_manager.simulations = []

    # The loadObj methods uses the created, but not contructed
    # loadedObj as an argument the singleton ImagineObject absorb
    # function.
    @staticmethod
    def loadobj(loaded_obj):
        return ImagineObject.get_instance(loaded_obj)

    def is_valid(self):
        return self is not None and all(v is not None for v in vars(self).values())

    def __str__(self):
        return f'{self.__class__.__name__}({vars(self)})'

    @staticmethod
    def absorb(singleton_obj, new_obj):
        """
        The absorb method grabs the manager objects from the loaded object and puts them into the singleton ImagineObject. The
        crop, regime and climate managers come from the loaded object, but the imagineWindowManager is reconstructed so that it
        refers to the new managers. absorb is called from the loadObj method and should be the only place that a new ImagineObject
        can be created since the constructor is private. absorb fails if the newOb is not an ImagineObject.
        """
        if singleton_obj == new_obj:
            print('Tried absorbing the ImagineObject into itself.')
            return

        if isinstance(new_obj, ImagineObject):
            temp_cm = singleton_obj.crop_manager
            temp_rm = singleton_obj.regime_manager
            temp_cl_m = singleton_obj.climate_manager

            singleton_obj.crop_manager = new_obj.crop_manager
            singleton_obj.regime_manager = new_obj.regime_manager
            singleton_obj.climate_manager = new_obj.climate_manager

            del temp_cm
            del temp_rm
            del temp_cl_m

        else:
            print('ImagineObject asked to absorb non-ImagineObject.')
            return

    @staticmethod
    def save(singleton_obj, path, file):
        """
        This function saves the ImagineObject to file.
        """
        was_saved = False
        filename = path + file
        with open(filename, 'wb') as f:
            pickle.dump(singleton_obj, f)
            was_saved = True

        singleton_obj.save_path = filename

        return was_saved

    # @staticmethod
    # def load(singleton_obj, path, file):
    #     """
    #     This function loads the ImagineObject from file. Note this is not a static method. An instance of ImagineObject should exist first.
    #     """
    #     # Create this class that stores loaded QuantityCondition, which can't really be properly constructed during the load process.
    #     # Once we've loaded, we'll update all the references that are collected during the load process. This seemed like a less
    #     # intrusive way of solving the problem than added listeners and so on.
    #
    #     ##### Is ConditionUpdater needed in pimagine? Commenting out.
    #     # cond_updater = ConditionUpdater.get_instance()
    #
    #     with open(path + file, 'rb') as f:
    #         new_obj = pickle.load(f)
    #
    #     new_obj.load_path = path + file
    #     # Need to do this indirectly with 'updateLoadedTitle' because newObj is not singletonObj and so the private imagineWindowManager
    #     # is inaccessible.
    #     new_obj.update_loaded_title(new_obj.load_path)
    #
    #     return new_obj

    def load_scenario(self, scenario_folder):

        success = False
        try:
            if isinstance(scenario_folder, str):
                scenario_folder = pathlib.Path(self.folders["$Scenarios"] / scenario_folder)
                self.folders["$Scenario"] = scenario_folder

            if not scenario_folder.is_dir():
                raise ValueError(f'Scenario folder does not exist: {str(scenario_folder)}')

            # Call load_scenario on the other managers.
            self.climate_manager.load_scenario(scenario_folder)
            self.crop_manager.load_scenario(scenario_folder)
            # Regime manager creates initialisation events based on crops. So crops must be loaded first.
            self.regime_manager.load_scenario(scenario_folder)
            success = True
        except ValueError as e:
            print(e)

        return success

    def set_resources_folder(self):
        # Get the path of the top level package
        package_path = Path(pkgutil.get_loader("imagine").path)
        resources_folder = package_path.parents[1] / "Resources"
        scenarios_folder = package_path.parents[1] / "Scenarios"

        if resources_folder.exists():
            self.folders["$Resources"] = resources_folder
        if scenarios_folder.exists():
            self.folders["$Scenarios"] = scenarios_folder
