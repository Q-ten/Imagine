from dotwiz import DotWiz

from imagine.core import global_helpers
from imagine.crop.crop_category import CropCategory
from imagine.crop.growth_model import GrowthModel
from imagine.events.imagine_event import ImagineEvent
from imagine.core.price_model import PriceModel
from imagine.util.absorb_fields import absorb_fields
from imagine.crop.growth_model_registry import *
from imagine.util.numpify_dictionary import numpify_dictionary
import numpy as np


print("loading __crop.py")
class Crop:
    def __init__(self, d=None):

        self.name = ""
        self.colour = [0, 0, 0]
        self.financial_events = []
        self.growth_model = None
        self.category = None
        # Changing price models implementation. Now using 'price_models'.
        # Price models will be included in lists applicable for each event that the price.
        # For Products,
        # self.product_price_models = []
        # self.cost_price_models = []
        self.price_config = None
        self.crop_rate_defs = None
        self.all_events = None

        if isinstance(d, dict):
            self.load_crop(d)
        else:
            self._setup_events()
            self._initialise_price_config()

#        self.colour = colour_in
#        self.financial_events = financial_events_in if financial_events_in is not None else [ImagineEvent.empty(1, 0)]
#        self.category_index = 0
#        self.categories = CropCategory.setup_categories()
#         if gm_in is not None:
#             self.growth_model = gm_in
 #       if category_in is not None:
 #           self.category = category_in

    # @staticmethod
    # def loadobj(obj):
    #     obj.category_choice = obj.category_choice
    #     obj.growth_model.name

    # @property
    # def category(self):
    #     if self.category_index:
    #         return self.categories[self.category_index]
    #     else:
    #         return CropCategory.empty(1, 0)

    # @category.setter
    # def category(self, cat):
    #     ix = next((i for i, c in enumerate(self.categories) if c.name == cat.name), None)
    #     if ix is None:
    #         self.categories.append(cat)
    #         self.category_index = len(self.categories) - 1
    #     else:
    #         self.categories[self.category_index] = cat
    #
    # def get_saved_category(self, cat_name):
    #     ix = next((i for i, c in enumerate(self.categories) if c.name == cat_name), None)
    #     if ix is None:
    #         return []
    #     else:
    #         return self.categories[ix]

    def get_cost_price_models(self, event_name):
        # Use the crop_rate_defs to look up the indices that map
        # the event's price models into the crop price models list.
        if event_name in self.price_config.cost_price_mappings:
            relevant_indices = self.price_config.cost_price_mappings[event_name]
            return self.price_config.cost_price_models[relevant_indices]
        return []

    @property
    def category_choice(self):
        if self.category:
            return self.category.name
        return ""

        # if self.category_index:
        #     return self.category.name
        # else:
        #     return ''

    # @category_choice.setter
    # def category_choice(self, cat_choice):
    #     cat = CropCategory(cat_choice)
    #     if cat.is_empty():
    #         print('Unable to change categories in crop. Supplied category is not a valid choice.')
    #         return
    #     ix = next((i for i, c in enumerate(self.categories) if c.name == cat_choice), None)
    #     if ix is not None:
    #         self.category_index = ix
    #     else:
    #         self.category = cat

    # @property
    # def growth_model(self):
    #     return self.category.growth_model

    def get_events(self):
        return self.all_events

    def get_unique_price_model_definitions(self, type_):
        pms = []
        if type_ == 'Income':
            price_models = self.growth_model.product_price_models
        elif type_ == 'Cost':
            gmes = self.growth_model.growth_model_events
            cost_price_models = [gme.cost_price_model for gme in gmes]
            financial_price_models = [event.cost_price_model for event in self.financial_events]
            price_models = cost_price_models + financial_price_models
        else:
            raise ValueError('Must pass a type argument. Valid types are ''Income'' and ''Cost''.')

        for pm in price_models:
            if not any(pm.definition_matches(p) for p in pms):
                pms.append(pm)

        return pms

    # @staticmethod
    # def absorb(orig_obj, new_obj):
    #     if type(new_obj) == type(orig_obj):
    #         for prop_name in orig_obj.__dict__.keys():
    #             if not prop_name.startswith('_'):
    #                 setattr(orig_obj, prop_name, getattr(new_obj, prop_name))
    #     else:
    #         raise ValueError('Absorb method can only be called on objects of exactly the same type.')

    # @staticmethod
    # def is_valid(crops):
    #     valid = []
    #     for c in crops:
    #         valid

    # Loads general crop information from the dictionary d into the object self.
    def load_crop(self, d):
        if not "name" in d:
            raise ValueError(f"Crop config does not define a name.")

        # Simple fields to load from config.
        simple_fields = [
            'name',
            'colour',
        ]
        absorb_fields(self, d, simple_fields)

        # Load category
        self.category = CropCategory.get_category(d.category_name)

        # Load growth model
        self.growth_model = globals()[d.growth_model_name](self.category, d.growth_model_parameters)

        # Load financial events
        if 'financial_events' in d:
            self.financial_events = [ImagineEvent.load_event(fe) for fe in d.financial_events]

        self._setup_events()
        self._initialise_price_config()
        self._setup_price_config(d)
        self._setup_crop_rate_defs()
        self._build_product_price_mappings()
        # Convert lists in price_config to numpy arrays to provide list based slicing.
        numpify_dictionary(self.price_config)

    def _setup_events(self):

        self.all_events = DotWiz()
        self.all_events.initial_events = self.growth_model.growth_model_initial_events
        self.all_events.regular_events = self.growth_model.growth_model_regular_events
        self.all_events.destruction_events = self.growth_model.growth_model_destruction_events
        self.all_events.gm_financial_events = self.growth_model.growth_model_financial_events
        self.all_events.crop_financial_events = self.financial_events

    # Puts all the columns of units from various growth model outputs into a handy structure we can just look up.
    # Must be called after _setup_events()
    def _initialise_price_config(self):
        self.price_config = DotWiz({
            'product_price_models': [],
            'cost_price_models': [],
            'relevant_product_price_model_indices': {
                'generic': [],
                'default': []
            },
            'cost_price_mappings': {},
            'product_price_mappings': {}
        })
        for event_type, events in self.all_events.items():
            for event in events:
                self.price_config.relevant_product_price_model_indices[event.name] = []
                self.price_config.cost_price_mappings[event.name] = []
                self.product_price_mappings = []

    def _setup_price_config(self, d):
        if 'product_price_models' not in d:
            raise ValueError(f"No product_price_models defined in crop config for {self.name}.")
        for pm_ix, pm_dict in enumerate(d.product_price_models):
            # First part of building the config is to create the list of all price models.
            if "name" not in pm_dict:
                # Add a product name if it's missing. Doesn't apply to costs. Costs require a name. (and event_name(s))
                pm_dict.name = pm_dict.rate.unit.measurable + " Income"
            self.price_config.product_price_models.append(PriceModel(pm_dict))

            # Next we have to record which price models are relevant to which events (via their indices).
            event_names = []
            if "event_name" in pm_dict:
                event_names = [pm_dict.event_name]
            elif "event_names" in pm_dict:
                event_names = pm_dict.event_names

            if event_names:
                for event_name in event_names:
                    if event_name in self.price_config.relevant_product_price_model_indices:
                        self.price_config.relevant_product_price_model_indices[event_name].append(pm_ix)
            else:
                self.price_config.relevant_product_price_model_indices.generic.append(pm_ix)

        if 'cost_price_models' in d:
            #            self.price_config.cost_price_models = [PriceModel(pm_dict) for pm_dict in d.cost_price_models]
            for pm_ix, pm_dict in enumerate(d.cost_price_models):
                if "name" not in pm_dict or ("event_name" not in pm_dict and "event_names" not in pm_dict):
                    # raise ValueError(f"Both 'name' and 'event_name' (or 'event_names') must be present in "
                    #                  f"cost price model config in {self.name}.")
                    print(f"Both 'name' and 'event_name' (or 'event_names') must be present in "
                          f"cost price model config in {self.name}. Not including cost price model.")
                    continue

                self.price_config.cost_price_models.append(PriceModel(pm_dict))
                event_names = []
                if "event_name" in pm_dict:
                    event_names = [pm_dict.event_name]
                elif "event_names" in pm_dict:
                    event_names = pm_dict.event_names
                if event_names:
                    for event_name in event_names:
                        if event_name in self.price_config.cost_price_mappings:
                            self.price_config.cost_price_mappings[event_name].append(pm_ix)
                        else:
                            print(f"Warning: '{event_name}' event referred to in cost "
                                  f"price model config does not exist in {self.name}.")

        if 'financial_events' in d:
            self.price_config
            for fe_ix, fe in enumerate(d.financial_events):
                fe.event_name = fe.name
                pm = PriceModel(fe)
                self.price_config.cost_price_models.append(pm)
                if fe.event_name in self.price_config.cost_price_mappings:
                    self.price_config.cost_price_mappings[fe.event_name].append(
                        len(self.price_config.cost_price_models)-1)
                print(fe.name)

    # Must be called after _setup_events() and _setup_price_config()
    def _setup_crop_rate_defs(self):
        crop_rate_defs = DotWiz()
        crop_rate_defs.output_rates = self.growth_model.get_output_rates()
        crop_rate_defs.propagation_product_rates = self.growth_model.get_propagation_product_rates()
        crop_rate_defs.events = {}
        for event_type, events in self.all_events.items():
            for event in events:
                prs, eors = self.growth_model.get_event_output_rates(event.name)
                cost_item_units = [self.price_config.cost_price_models[ix].denominator_unit
                                   for ix in self.price_config.cost_price_mappings[event.name]]
                crop_rate_defs.events[event.name] = {
                    'product_rates': prs,
                    'event_output_rates': eors,
                    'cost_item_units': cost_item_units
                }

        self.crop_rate_defs = crop_rate_defs

    def _build_product_price_mappings(self):
        # Now build the product price mappings.
        # Need to use the product column to find the best price model.
        for event_type, events in self.all_events.items():
            for event in events:
                if event.name in self.crop_rate_defs.events:
                    product_rates = self.crop_rate_defs.events[event.name].product_rates
                    new_price_mappings = []
                    for pr in product_rates:
                        # Find the index of a product price model that matches the product rate, or create a
                        # zero price model for it in self.price_config.relevant_product_price_model_indices.default
                        # and use that.
                        new_price_mappings.append(self._get_product_price_model_index(event.name, pr))

                    self.price_config.product_price_mappings[event.name] = new_price_mappings
                else:
                    raise ValueError(f"Expecting {event.name} in Crop.crop_rate_defs.events for crop {self.crop.name}")

    def _get_product_price_model_index(self, event_name, pr):
        # Looks up the price_config.relevant_product_price_model_indices to find a matching price model for pr.
        # If one is not found, a zero price model is added and its index is returned.
        rppmis = self.price_config.relevant_product_price_model_indices
        if event_name in rppmis:
            for price_model_index in rppmis[event_name]:
                pm = self.price_config.product_price_models[price_model_index]
                # Each of these pms was defined in the config as relevant to this event.
                # If a pm matches here, use it.
                if pm.denominator_unit == pr.unit:
                    return price_model_index

        # If not returned here, check 'generic'.
        for price_model_index in rppmis.generic:
            pm = self.price_config.product_price_models[price_model_index]
            # Each of these pms was defined in the config as relevant to this event.
            # If a pm matches here, use it.
            if pm.denominator_unit == pr.unit:
                return price_model_index

        # If not returned here, check in default.
        for price_model_index in rppmis.default:
            pm = self.price_config.product_price_models[price_model_index]
            # Each of these pms was defined in the config as relevant to this event.
            # If a pm matches here, use it.
            if pm.denominator_unit == pr.unit:
                return price_model_index

        # If not returned here, add a zero price model and return index.
        pm = PriceModel(pr.unit.measurable + " Income", unit=global_helpers.dollar, denominator_unit=pr.unit)
        price_model_index = len(self.price_config.product_price_models)
        self.price_config.product_price_models.append(pm)
        rppmis.default.append(price_model_index)
        return price_model_index

    def get_cost_price_models(self, event_name):
        event_mapping = self.price_config.cost_price_mappings[event_name]
        if len(event_mapping) == 0:
            return []
        return self.price_config.cost_price_models[event_mapping]

    def get_product_price_model(self, denominator_unit):
        matching_pms = [pm for pm in self.price_config.product_price_models if pm.denominator_unit == denominator_unit]
        if len(matching_pms) == 1:
            return matching_pms[0]
        elif len(matching_pms) == 0:
            return None
        else:
            raise ValueError(f"More than one product price model matches provided" 
                             f"denominator unit: {denominator_unit} for crop {self.name}.")
