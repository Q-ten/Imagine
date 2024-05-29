from dotwiz import DotWiz
from pyjson5 import pyjson5

from imagine.core import ImagineObject
from imagine.core.norm_dist import NormDist
from imagine.core.rate import Rate
from imagine.core.trend import Trend
from imagine.crop import Crop
from imagine.crop.planted_crop import PlantedCrop
from typing import List, Optional
from pathlib import Path
from imagine.util.absorb_fields import absorb_fields
from imagine.util.always import always
from imagine.util.load_series_data import resolve_series


class CropListChangedEventData:
    def __init__(self, crop_names, previous_name, new_name):
        self.crop_names = crop_names
        self.previous_name = previous_name
        self.new_name = new_name
        self.force_regime_removal = False
        self.regimes_to_remove = []


class CropCategoryChangedEventData:
    def __init__(self, previous_name, new_name, previous_category, new_category):
        self.previous_name = previous_name
        self.new_name = new_name
        self.previous_category = previous_category
        self.new_category = new_category


class CropColourChangedEventData:
    def __init__(self, previous_name, new_name, previous_colour, new_colour):
        self.previous_name = previous_name
        self.new_name = new_name
        self.previous_colour = previous_colour
        self.new_colour = new_colour


class CropNameChangedEventData:
    def __init__(self, previous_name, new_name):
        self.previous_name = previous_name
        self.new_name = new_name


class CropManager:
    _instance = None

    def __init__(self):
        if always():
            # Merely a hack. __init__ shouldn't be called.
            # But by placing fields in the init, no complaints.
            # And by placing them after the always(), IDEs will accept the possibility the code is reachable.
            raise RuntimeError('Call get_instance() instead')
        self.crops = []  # List to store Crop objects

    @classmethod
    def get_instance(cls, loaded_obj=None):
        if loaded_obj and isinstance(loaded_obj, CropManager) and cls._instance != loaded_obj:
            cls._instance = loaded_obj
            print('Set CropMgr to loadedCropMgr.')
        elif not cls._instance:
            cls._instance = cls.__new__(cls)
            cls._instance._crop_manager_constructor()
        return cls._instance

    def _crop_manager_constructor(self):
        self.crops = []  # List to store Crop objects

    def add_crop_object(self, new_crop):
        self.crops.append(new_crop)
        self.sort_crops()
        # Broadcast the event
        evt_data = CropListChangedEventData(self.get_crop_names(), '', new_crop.name)
        self.notify('CropAdded', evt_data)

    def replace_crop(self, original_crop_name, replacement_crop):
        original_crop = next((crop for crop in self.crops if crop.name == original_crop_name), None)
        if original_crop:
            # Replace the crop
            original_index = self.crops.index(original_crop)
            self.crops[original_index] = replacement_crop
            self.sort_crops()
            # Broadcast the event
            evt_data = CropListChangedEventData(self.get_crop_names(), original_crop_name, replacement_crop.name)
            self.notify('CropEditted', evt_data)
        else:
            print(f"Cannot find crop with name '{original_crop_name}' to replace.")

    def sort_crops(self):
        self.crops.sort(key=lambda x: x.name)

    def remove_crop(self, crop_name, force=False):
        crop_obj = next((crop for crop in self.crops if crop.name == crop_name), None)
        if crop_obj:
            # Check if the crop is used in any of the regimes.
            from imagine.regime.regime_manager import RegimeManager
            regime_mgr = RegimeManager.get_instance()  # Assuming there's a RegimeManager class
            used_regime_definitions = regime_mgr.regimes_that_use_crop(crop_name)
            regimes_with_crop = []

            if used_regime_definitions:
                regimes_with_crop = [definition.regime_label for definition in used_regime_definitions]
                regimes_with_crop.sort()

                if not force:
                    qstring = [
                        f"The selected crop ({crop_name}) is used in the following regime(s):",
                        "",
                        *regimes_with_crop,
                        "",
                        "Removing this crop will ALSO REMOVE THESE REGIMES!",
                        "",
                        "Are you sure you want to continue?",
                    ]
                    button = input("\n".join(qstring) + "\n(Type 'Yes' or 'No'): ")
                    if button.lower() != 'yes':
                        return
                    else:
                        # Remove all the regimes with this crop and force it since we've already asked.
                        for regime_definition in used_regime_definitions:
                            regime_mgr.remove_regime(regime_definition.regime_label, True)

            if force or input(f"This action will remove the {crop_name} crop from Imagine. "
                              "Are you sure you want to continue? (Type 'Yes' or 'No'): ").lower() == 'yes':
                self.crops.remove(crop_obj)
                # Notify that the crop has been deleted.
                evt_data = CropListChangedEventData(self.get_crop_names(), crop_name, '')
                evt_data.force_regime_removal = True
                evt_data.regimes_to_remove = regimes_with_crop
                self.notify('CropRemoved', evt_data)
        else:
            print(f"Cannot find crop with name '{crop_name}' to remove.")

    def get_crop_names(self):
        return [crop.name for crop in self.crops]

    # def edit_crop(self, crop):
    #     # Implementation...

    def load_crop(self, path, file):
        pass
        # Implementation...

    def save_crop(self, crop_name, path, file):
        # Implementation...
        pass

    def get_crop(self, crop_name):
        crop = next((crop for crop in self.crops if crop.name == crop_name), None)
        if crop:
            return crop
        return

    def get_crop_category(self, crop_name):
        crop = self.get_crop(crop_name)
        return crop.category_choice if crop else None

    def get_crop_definitions(self):
        names = self.get_crop_names()
        category_names = [crop.category_choice for crop in self.crops]
        colours = [crop.colour for crop in self.crops]
        # NOTE - Need to sort out the full list of events.
        # imagine_events = [crop.growth_model_events for crop in self.crops]

        crop_defs = [{'name': name, 'categoryName': category_name,
                     'colour': colour} for name, category_name, colour in zip(names, category_names, colours)]
        return crop_defs

    # This function returns a PlantedCrop as requested.
    # It is intended to be called from InstalledRegime when a crop's
    # initialisation trigger has been triggered.
    def get_planted_crop(self, crop_name, installed_regime, sim, initial_event):
        crop = self.get_crop(crop_name)
        return PlantedCrop(crop, installed_regime, sim, initial_event) if crop else None

    # Returns a list of the ImagineEvents listed as the
    # initialisationEvents for the given crop.
    def get_crops_initial_events(self, crop_name):
        crop = self.get_crop(crop_name)
        return crop.growth_model.growth_model_initial_events if crop else None

    # This function returns the full list of events for a given crop.
    # It includes the growthModel events and the extra financial
    # events.
    def get_crops_events(self, crop_name):
        crop = self.get_crop(crop_name)
        return crop.growth_model_events + crop.financial_events if crop else None

    # Function returns a list with entries corresponding to the
    # crop names provided. Each entry contains the units of the products
    # the crop can produce. crop_names can either be a single name (a string) or a
    # list of crop name strings.
    def get_crops_product_units(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        product_units = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                product_units.append(self.crops[crop_index].growth_model.product_units)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return product_units

        # Function returns a list with entries corresponding to the
        # crop names provided. Each entry contains the units of the outputs
        # the crop can produce. crop_names can either be a single name (a string) or a
        # list of crop name strings.

    def get_crops_output_units(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        output_units = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                output_units.append(self.crops[crop_index].growth_model.growth_model_output_units)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return output_units

        # Function returns a list with entries corresponding to the
        # crop names provided. Each entry contains the rates of the outputs
        # the crop can produce. crop_names can either be a single name (a string) or a
        # list of crop name strings.

    def get_crops_output_rates(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        output_rates = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                output_rates.append(self.crops[crop_index].growth_model.growth_model_output_rates)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return output_rates

        # Function returns a list with entries corresponding to the
        # crop names provided. Each entry contains the rates of the outputs
        # the crop can produce. crop_names can either be a single name (a string) or a
        # list of crop name strings.

    def get_crops_regime_units(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        regime_units = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                regime_units.append(self.crops[crop_index].category.regime_output_units)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return regime_units

    def get_crops_product_and_output_rates_for_event(self, crop_names, event_name):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        products = []
        rates = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                crop_products, crop_rates = self.crops[crop_index].growth_model.get_product_and_output_rates_for_event(
                    event_name)
                products.append(crop_products)
                rates.append(crop_rates)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return products, rates

    def get_crops_propagation_product_rates(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        rates = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                rates.append(self.crops[crop_index].growth_model.get_propagation_product_rates())
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return rates

    def get_crops_event_output_units(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        units = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                event_names = self.crops[crop_index].growth_model.supported_imagine_events
                all_event_output_rates = []
                for event_name in event_names:
                    _, event_output_rates = self.crops[crop_index].growth_model.event_transition(event_name, [], [])
                    all_event_output_rates.extend(event_output_rates)
                units.append([rate.unit for rate in all_event_output_rates])
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return units

    def get_crops_event_output_rates(self, crop_names):
        if isinstance(crop_names, str):
            crop_names = [crop_names]

        rates = []
        for crop_name in crop_names:
            crop_index = next((i for i, crop in enumerate(self.crops) if crop.name == crop_name), None)
            if crop_index is not None:
                event_names = self.crops[crop_index].growth_model.supported_imagine_events
                all_event_output_rates = []
                for event_name in event_names:
                    _, event_output_rates = self.crops[crop_index].growth_model.event_transition(event_name, [], [])
                    all_event_output_rates.extend(event_output_rates)
                rates.append(all_event_output_rates)
            else:
                raise ValueError(f"Can't find the crop name '{crop_name}' in the list of crops.")
        return rates

    def generate_prices(self):
        # The format for both is
        # price_table[crop_name][event_name/product_name] and that will
        # be an array of prices for each year.
        product_price_table = {}
        cost_price_table = {}
        product_price_model_table = {}
        cost_price_model_table = {}
        im_ob = ImagineObject.get_instance()

        for crop in self.crops:
            # For each crop create the entry in product_price_table and
            # cost_price_table.
            crop_name = crop.name.replace(' ', '_')
            product_price_table[crop_name] = {}
            cost_price_table[crop_name] = {}
            product_price_model_table[crop_name] = {}
            cost_price_model_table[crop_name] = {}

            gm_events = crop.growth_model.growth_model_events
            all_events = gm_events + crop.financial_events
            for event in all_events:
                event_name = event.name
                cost_price_model = crop.get_cost_price_model(event.name)
                if cost_price_model is None:
                    raise ValueError(f"Expecting price model {event.name} in {crop.name} crop")
                m, v, s = cost_price_model.trend.create_trend_series(im_ob.simulation_length)

                # There's a better way to do this, but for now, we'll
                # copy everything into the cost_price_table. Ideally, we
                # would not be storing the units every time.
                yearly_prices = Rate.array(s, cost_price_model.unit, cost_price_model.denominator_unit)
                # TODO: replace this access model with dict access.
                cost_price_table[crop_name][event_name.replace(' ', '_')] = yearly_prices

                # The cost price model table gives a list of NormDists
                # that the costs in the cost price table have been
                # sampled from.
                # TODO: replace this access model with dict access.
                cost_price_model_table[crop_name][event_name.replace(' ', '_')] = NormDist.init(m, v)

            # Get the product_price_models for this crop.
            # TODO: Remove these notes on gm_product_price_models.
            # I've moved product_price_models into crop. The prices must be defined for the chosen products for the
            # growth model. But the price models are crop specific not growth model specific.
            # I'm renaming gm_product_price_models to product_price_models. And it's accessed from crop not
            # crop.growth_model. I'm going to remove price_models from GrowthModel.
#            gm_product_price_models = crop.growth_model.product_price_models
            product_price_models = crop.product_price_models

            # For products, preallocate the pxm array of rates...
            product_rates = [Rate() for _ in range(len(product_price_models))]

            # The plan is to work out one row of rates, then set that
            # row in the product_rates array.
            product_rate_models = [NormDist() for _ in range(len(product_price_models))]

            for j, product_price_model in enumerate(product_price_models):
                m, v, s = product_price_model.trend.create_trend_series(im_ob.simulation_length)

                yearly_prices = Rate.array(s, product_price_model.unit, product_price_model.denominator_unit)
                product_rates[j] = yearly_prices

                product_rate_models[j] = NormDist.init(m, v)

            product_price_table[crop_name] = product_rates
            product_price_model_table[crop_name] = product_rate_models

        return cost_price_table, product_price_table, cost_price_model_table, product_price_model_table

    def load_scenario(self, scenario_folder):

        crop_sub_folder = scenario_folder / 'Crops'
        if not crop_sub_folder.is_dir():
            raise ValueError(f'Scenario crop folder does not exist: {str(crop_sub_folder)}')

        self.crops = []
        for file_path in crop_sub_folder.iterdir():
            if file_path.is_file():
                if file_path.suffix == '.json5' and file_path.name[0] != '_':
                    with open(file_path, 'r') as file:

                        data = pyjson5.load(file)
                        data = resolve_series(data)
                        data = DotWiz(data)

                        c = Crop(data)
                        self.crops.append(c)

