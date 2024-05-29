import numpy as np
from datetime import datetime
from imagine.core import ImagineObject
from imagine.core.rate import Rate
from imagine.crop.planted_crop import PlantedCrop
from imagine.simulation.sim_store import SimStore
import imagine.core.global_helpers as gh


class Simulation:
    """
    Represents a single Imagine Simulation.
    A Simulation contains the data generated. It will maintain the
    probabilistic climate data, the price data, and other data.
    It will maintain the results of the simulation as it progresses.
    In other words, it holds the state.
    Results include various regime amounts, harvested amounts, prices, costs, profit, etc.
    """

    def __init__(self):
        self.month_index = 0
        self.year_index = 0
        self.month_day = 0
        self.installed_regimes = []
        self.primary_regime_index = -1
        self.secondary_regime_index = -1
        self.sim_name = None
        # self.product_price_table = None
        # self.cost_price_table = None
        # self.product_price_model_table = None
        # self.cost_price_model_table = None
        self._timestamp = datetime.now().strftime('%m-%d-%Y %H:%M:%S')
        # Set the rainfall chart to NaNs to start with
        im_ob = ImagineObject.get_instance()
        simulation_length = im_ob.simulation_length
        self.monthly_rainfall = np.full((12, simulation_length), np.nan)

        self.sim_store = SimStore(self)
        # price_table_lookup[price_model] gives a view into the numpy array holding the prices.
        # I.e. get the actual prices for this sim given the price model.
        self.price_table_lookup = self.sim_store.generate_prices()

    @property
    def timestamp(self):
        return self._timestamp

    @property
    def current_primary_installed_regime(self):
        if self.primary_regime_index >= 0:
            return self.installed_regimes[self.primary_regime_index]
        else:
            return None

    @property
    def current_secondary_installed_regime(self):
        if self.secondary_regime_index >= 0:
            return self.installed_regimes[self.secondary_regime_index]
        else:
            return None

    @property
    def current_primary_planted_crop(self):
        if self.primary_regime_index >= 0:
            return self.current_primary_installed_regime.current_planted_crop
        else:
            return None

    @property
    def current_secondary_planted_crop(self):
        if self.secondary_regime_index >= 0:
            return self.current_secondary_installed_regime.current_planted_crop
        else:
            return None

    @property
    def year(self):
        return (self.month_index - 1) // 12 + 1

    @property
    def month(self):
        return (self.month_index - 1) % 12 + 1

    def installed_regime(self, zone):
        if zone == 1:
            return self.current_primary_installed_regime
        elif zone == 2:
            return self.current_secondary_installed_regime
        else:
            return None

    def planted_crop(self, zone):
        if zone == 1:
            return self.current_primary_planted_crop
        elif zone == 2:
            return self.current_secondary_planted_crop
        else:
            return None

    def costs(self, first_month, last_month, as_list):
        if last_month < first_month:
            return [] if as_list else 0

        if last_month > self.month_index:
            last_month = self.month_index

        if first_month < 1:
            first_month = 1

        if as_list:
            cs = np.zeros(last_month - first_month + 1)
#            cs = [0] * (last_month - first_month + 1)
        else:
            cs = 0

        # TODO: make this actually work as intended.
        for i in range(len(self.installed_regimes)):
            ir_costs = self.installed_regimes[i].costs(first_month, last_month, as_list)
            cs = [sum(x) for x in zip(cs, ir_costs)] if as_list else cs + ir_costs

        return cs

    def income(self, first_month, last_month, as_list):
        if last_month < first_month:
            return [] if as_list else 0

        if last_month > self.month_index:
            last_month = self.month_index

        if first_month < 1:
            first_month = 1

        if as_list:
            ins = [0] * (last_month - first_month + 1)
        else:
            ins = 0

        for ir in self.installed_regimes:
            ins += ir.income(first_month, last_month, as_list)

        return ins

    def profit(self, first_month, last_month, as_list):
        return self.income(first_month, last_month, as_list) - self.costs(first_month, last_month, as_list)

    @property
    def costs_to_date(self):
        return self.costs(1, self.month_index, False)

    @property
    def income_to_date(self):
        return self.income(1, self.month_index, False)

    @property
    def profit_to_date(self):
        return self.profit(1, self.month_index, False)

#     def get_product_price(self, crop_name, product_unit, year=None):
#         if year is None:
#             year = self.year
#
# #        crop_name = crop_name.replace(' ', '_')
#         price_column = self.product_price_table[crop_name][:, year-1]
#         price_column =
#         ix = price_column.index(product_unit)
#         ix =
#         crop_store[crop_name].product_price_table[year, col]
#
#         if ix is None:
#             return None
#         else:
#             return price_column[ix]

    # def get_cost_price(self, crop_name, event_name, year=None):
    #     if year is None:
    #         year = self.year
    #
    #     crop_name = crop_name.replace(' ', '_')
    #     event_name = event_name.replace(' ', '_')
    #
    #     try:
    #         p = self.cost_price_table[crop_name][event_name][year-1]
    #     except Exception as e:
    #         print(f"Call to Simulation.get_cost_price failed. cost_prices.{crop_name}.{event_name}({year}) throws an exception. Returned None instead.")
    #         raise e
    #
    #     return p


    def get_price(self, price_model, year=None):
        if year is None:
            year = self.year_index
        try:
            price = Rate(self.price_table_lookup[price_model][year], gh.dollars, price_model.denominator_unit)
            return price
        except Exception as e:
            print(f"Price Model {price_model.name}, not found in cost price model table.")

    def install_regime_if_possible(self, zone):
        from imagine.regime.regime_manager import RegimeManager

        reg_mgr = RegimeManager.get_instance()

        if zone == 'primary':
            if self.current_primary_installed_regime is not None:
                return
            else:
                in_reg = reg_mgr.request_regime_installation(zone, self)
                if in_reg:
                    self.primary_regime_index = len(self.installed_regimes)
                    self.installed_regimes.append(in_reg)
        elif zone == 'secondary':
            if self.current_secondary_installed_regime is not None:
                return
            else:
                in_reg = reg_mgr.request_regime_installation(zone, self)
                if in_reg:
                    self.secondary_regime_index = len(self.installed_regimes)
                    self.installed_regimes.append(in_reg)

    def is_triggered(self, trig, planted_crop=None):
        if planted_crop is None:
            planted_crop = PlantedCrop()

        return trig.conditions[-1].is_triggered(self, planted_crop)

    # TODO: finish this off or remove it. (Not yet implemented in sim_store.)
    # def get_amount(self, rate, crop_name, regime_label, month_index=None, month_start=None):
    #     return self.sim_store.get_amount(rate, crop_name, regime_label, month_index, month_start)


        # cond_truths = [False] * len(trig.conditions)
        #
        # for j, cond in enumerate(trig.conditions):
        #     if cond.condition_type == 'Time Index Based':
        #         cond_truths[j] = cond.is_triggered(self.month_index, self.year)
        #     elif cond.condition_type == 'Month Based':
        #         cond_truths[j] = cond.is_triggered(self.month_index)
        #     elif cond.condition_type == 'Event Happened Previously':
        #         if not planted_crop.occurrences:
        #             cond_truths[j] = False
        #         else:
        #             cond_truths[j] = cond.is_triggered(self.month_index, planted_crop.occurrences)
        #     elif cond.condition_type == 'Quantity Based':
        #         if self.month_day == 1:
        #             outputs = planted_crop.get_outputs_month_start(self.month_index - planted_crop.planted_month + 1)
        #         else:
        #             outputs = planted_crop.get_outputs_month_end(self.month_index - planted_crop.planted_month + 1)
        #         cond_truths[j] = cond.is_triggered(outputs, planted_crop.occurrences, planted_crop.parent_regime.outputs[:, self.month_index])
        #     elif cond.condition_type in ['And / Or / Not', 'And / Or']:
        #         cond_truths[j] = cond.is_triggered(j, cond_truths)
        #     elif cond.condition_type == 'Never':
        #         cond_truths[j] = cond.is_triggered()
        #     else:
        #         raise ValueError('Trying to create a condition with unknown type.')
        #
        # return cond_truths[-1]


