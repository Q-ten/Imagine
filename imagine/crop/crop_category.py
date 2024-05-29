from imagine.core.unit import Unit
from imagine.crop.growth_model import GrowthModel
from imagine.core.price_model import PriceModel
import sys


class CropCategory:
    _cats = []

    def __init__(self):
        raise RuntimeError('Call get_category() instead')

    @classmethod
    def _setup_crop_categories(cls):
        if len(cls._cats) == 0:
            cat_obj = CropCategory._create_category('Annual',
                                                    ['Planting', 'Harvesting'],
                                                    ['FixedYieldGrowthModel',
                                                     'AnnualGrowthModel'])
            units = [Unit('', 'Paddock', 'Unit'), Unit('', 'Area', 'Hectare')]
            cat_obj.core_crop_output_units = []
            cat_obj.regime_output_units = units
            cls._cats.append(cat_obj)

            cat_obj = CropCategory._create_category('Coppice Tree Crop',
                                                    ['Planting', 'Coppice Harvesting', 'Destructive Harvesting'],
                                                    ['ABGompertzGrowthModel', 'FixedYieldGrowthModel'])
            units = [Unit('', 'Paddock', 'Unit'), Unit('', 'Area', 'Hectare'), Unit('', 'Tree', 'Unit'),
                     Unit('', 'Belts', 'Km'), Unit('', 'Rows', 'Km'), Unit('', 'Crop Interface Length', 'm')]
            cat_obj.regime_output_units = units
            units = [Unit('', 'Above-ground Biomass', 'Tonne'), Unit('', 'Below-ground Biomass', 'Tonne')]
            cat_obj.core_crop_output_units = units
            cls._cats.append(cat_obj)

            cat_obj = CropCategory._create_category('Pasture',
                                                    ['Establishment', 'Shearing', 'Sheep Sales', 'Destruction'],
                                                    ['SimplePastureGrowthModel', 'GrassGroGrowthModel'])
            units = [Unit('', 'Paddock', 'Unit'), Unit('', 'Area', 'Hectare'), Unit('', 'DSE', 'Unit')]
            cat_obj.regime_output_units = units
            units = [Unit('', 'FOO', 'Tonne')]
            cat_obj.core_crop_output_units = units
            cls._cats.append(cat_obj)

    @classmethod
    def _create_category(cls, name: str = "", core_events: list = None, growth_model_class_names: list = None,
                         #                        growth_models: list, growth_model_index: int,
                         core_crop_output_units: list = None, regime_output_units: list = None,
                         #                        price_models: list
                         ) -> 'CropCategory':
        cat = cls.__new__(cls)
        cat.name = name
        cat.core_events = core_events
        cat.growth_model_class_names = growth_model_class_names
        # cat.growth_models = growth_models
        # cat.growth_model_index = growth_model_index
        cat.core_crop_output_units = core_crop_output_units
        cat.regime_output_units = regime_output_units
        # cat.price_models = price_models
        return cat

    @classmethod
    def get_category(cls, cat_name):
        """ If cat with name==cat_name is in _cats, an exception is raised. Which is fine."""
        if not cls._cats:
            cls._setup_crop_categories()
        cat = next(obj for obj in cls._cats if obj.name == cat_name)
        return cat


"""
    @property
    def growth_model(self):
        if self.growth_model_index:
            return self.growth_models[self.growth_model_index]
        else:
            return None

    @growth_model.setter
    def growth_model(self, gm):
        if not gm:
            return

        # Does a growth model with the same name already exist?
        ix = next((index for index, model in enumerate(self.growth_models) if model.name == gm.name), None)

        if ix is None:
            self.growth_models.append(gm)
            self.growth_model_index = len(self.growth_models) - 1
        else:
            self.growth_models[self.growth_model_index] = gm

    @property
    def growth_model_choice(self):
        if self.growth_model_index:
            return self.growth_models[self.growth_model_index].name
        else:
            return ''

    @growth_model_choice.setter
    def growth_model_choice(self, gm_choice):
        gm = GrowthModel(gm_choice)
        if not gm:
            print("Unable to change growth model. Supplied growth model name is not a valid choice, "
                  "at least for the current category.")
            return

        ix = next((i for i, gm in enumerate(self.growth_models) if gm.name == gm_choice), None)
        
        if ix is not None:
            self.growth_model_index = ix
        else:
            self.growth_model = gm

    @property
    def possible_growth_model_descriptions(self):
        gm_names = [None] * len(self.growth_model_delegate_class_names)
        gm_state_desc = [None] * len(self.growth_model_delegate_class_names)

        for i, gmd_class_name in enumerate(self.growth_model_delegate_class_names):
            gmd_class = getattr(sys.modules[__name__], gmd_class_name)
            gm_names[i] = gmd_class.model_name
            gm_state_desc[i] = gmd_class.state_description
        
        return [{'name': name, 'state_description': desc} for name, desc in zip(gm_names, gm_state_desc)]

    def get_saved_price_models_from_definitions(self, price_models):
        for i, pm in enumerate(price_models):
            for j, obj_pm in enumerate(self.price_models):
                if PriceModel.definition_matches(obj_pm, pm):
                    price_models[i] = obj_pm
                    break
        return price_models

    def set_saved_price_models(self, price_models):
        for pm in price_models:
            match_found = False
            for i, obj_pm in enumerate(self.price_models):
                if PriceModel.definition_matches(obj_pm, pm):
                    self.price_models[i] = pm
                    match_found = True
                    break
            if not match_found:
                self.price_models.append(pm)

    def change_price_model_name(self, orig_name, new_name):
        ix = next((i for i, pm in enumerate(self.price_models) if pm.name == orig_name), None)
        if ix is None:
            print("Warning: Cannot find a priceModel with a matching name.")
            return False
        else:
            self.price_models[ix].name = new_name
            return True

    @property
    def possible_price_units(self):
        reg_units = self.regime_output_units
        crop_units = self.growth_model.growth_model_output_units
        product_units = [pm.denominator_unit for pm in self.growth_model.product_price_models]
        return reg_units + crop_units + product_units

    def get_possible_price_unit_strings(self):
        reg_units = self.regime_output_units
        crop_units = self.growth_model.growth_model_output_units
        product_units = [pm.denominator_unit for pm in self.growth_model.product_price_models]

        product_unit_strings = []
        for i, unit in enumerate(product_units):
            product_name = self.growth_model.product_price_models[i].name
            name_length = len(product_name)
            if name_length >= 7:
                if product_name[(name_length - 6):name_length] == " Income":
                    product_name = product_name[0:(name_length - 7)]
            product_unit_strings.append(f"{unit.readable_denominator_unit} ({product_name})")

        ppus = [unit.readable_denominator_unit for unit in reg_units + crop_units] + product_unit_strings
        return ppus

    @staticmethod
    def setup_categories():
        cats = [
            CropCategory("Annual"),
            CropCategory("Coppice Tree Crop"),
            CropCategory("Pasture"),
        ]
        return cats

    @staticmethod
    def get_current_crop_categories(existing_cats):
        if not all(isinstance(cat, CropCategory) for cat in existing_cats):
            return []

        cats = CropCategory.setup_categories()

        for i, cat in enumerate(cats):
            ix = next((index for index, existing_cat in enumerate(existing_cats)
                       if existing_cat.name == cat.name), None)

            if ix is not None:
                existing_cats[ix].growth_model_delegate_class_names = cat.growth_model_delegate_class_names
                existing_cats[ix].core_events = cat.core_events
                cats[i] = existing_cats[ix]

        return cats

"""
