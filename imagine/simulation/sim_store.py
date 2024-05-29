import numpy as np
from dotwiz import DotWiz

from imagine.climate.climate_manager import ClimateManager
from imagine.core import ImagineObject
from imagine.core.amount import Amount
from imagine.core.rate import Rate
from imagine.core.unit import Unit
from imagine.regime.regime_manager import RegimeManager
from imagine.crop.crop_manager import CropManager


class SimStore:

    def __init__(self, sim):

        self.sim = sim
        self.crop_store = DotWiz()
        self.regime_store = DotWiz()
        self.climate_store = DotWiz()
        self._price_model_lookup = None

        self._initialise_store()

    def _initialise_store(self):

        crop_mgr = CropManager.get_instance()
        regime_mgr = RegimeManager.get_instance()
        climate_mgr = ClimateManager.get_instance()
        im_ob = ImagineObject.get_instance()
        sim_length = im_ob.simulation_length
        series_length = sim_length * 12

        for crop in crop_mgr.crops:
            outputs_len = len(crop.crop_rate_defs.output_rates)
            prop_prods_len = len(crop.crop_rate_defs.propagation_product_rates)
            product_prices_len = len(crop.price_config.product_price_models)
            cost_prices_len = len(crop.price_config.cost_price_models)

            self.crop_store[crop.name] = {
                'events': {},
                'propagation_products': np.empty((series_length, prop_prods_len), dtype=object),
                # Use double the output count to make space for month start and month end.
                'outputs': np.empty((series_length, outputs_len * 2), dtype=object),
                # For now, price tables are implemented as only 1 price per year.
                'product_price_table': np.zeros((sim_length, product_prices_len)),
                'cost_price_table': np.zeros((sim_length, cost_prices_len)),
                'events_triggered': np.empty((series_length,), dtype=object)
            }
            for i in range(series_length):
                self.crop_store[crop.name].events_triggered[i] = []

            # As we construct the structure, we'll keep track and store the indices into the structure too.
            for event_name, event_rate_defs in crop.crop_rate_defs.events.items():
                products_array = np.empty((series_length, len(event_rate_defs.product_rates)), dtype=object)
                cost_items_array = np.empty((series_length, len(event_rate_defs.cost_item_units)), dtype=object)
                event_outputs_array = np.empty((series_length, len(event_rate_defs.event_output_rates)), dtype=object)
                self.crop_store[crop.name].events[event_name] = {
                    'products': products_array,
                    'event_outputs': event_outputs_array,
                    'cost_items': cost_items_array
                }

        # Regimes are simpler. Just a single column of outputs per month.
        for regime in regime_mgr.regimes:
            outputs_len = len(regime.regime_rate_defs.output_rates)
            # Regime outputs are calculated once per year.

            self.regime_store[regime.regime_label] = {
                'outputs': np.empty((series_length, outputs_len), dtype=object)
            }

        # Filling in climate data is event easier.
        for series_name in climate_mgr.climate_series_models.keys():
            self.climate_store[series_name] = climate_mgr.get_series(series_name)
            
            

    def generate_prices(self):
        crop_mgr = CropManager.get_instance()
        self._price_model_lookup = {}
        for crop in crop_mgr.crops:
            self._generate_prices(crop.price_config.product_price_models,
                                  self.crop_store[crop.name].product_price_table, self._price_model_lookup)

            self._generate_prices(crop.price_config.cost_price_models,
                                  self.crop_store[crop.name].cost_price_table, self._price_model_lookup)
        # Return the lookup table as it will be useful to the sim to haev direct access.
        return self._price_model_lookup

    def _generate_prices(self, price_models, dest, _price_model_lookup):
        series_len = dest.shape[0]
        for ix, price_model in enumerate(price_models):
            m, v, s = price_model.trend.create_trend_series(series_len)
            dest[:, ix] = s
            # Include a view into the price table given the price model.
            _price_model_lookup[price_model] = dest[:, ix]

    # NOTE Price lookup is available through the sim directly.

    def add_occurrence_to_crop(self, oc, crop_name):
        self.crop_store[crop_name].events_triggered[oc.month_index].append(oc.event_name)

        if oc.event_name == "Monthly Propagation":
            self.crop_store[crop_name].propagation_products[oc.month_index, :] = oc.products
            return

        if oc.event_outputs:
            self.crop_store[crop_name].events[oc.event_name].event_outputs[oc.month_index, :] = oc.event_outputs

        if oc.cost_items:
            self.crop_store[crop_name].events[oc.event_name].cost_items[oc.month_index, :] = oc.cost_items

        if oc.products:
            self.crop_store[crop_name].events[oc.event_name].products[oc.month_index, :] = oc.products


