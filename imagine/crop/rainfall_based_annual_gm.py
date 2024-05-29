# RainfallBasedAnnualGM
#
# Provides based yield for annual crops based on rainfall in relevant
# months within a given year. Uses a quadratic function to map the total
# rain in relevant months to a yield.
import numpy as np

from imagine.crop.growth_model import GrowthModel
from imagine.util.absorb_fields import absorb_fields


class RainfallBasedAnnualGM():
    def __init__(self, params=None):
        super().__init__()
        self.a = 3e-6
        self.b = 0.02
        self.c = 1
        self.first_relevant_month = 1
        self.last_relevant_month = 12

        if params:
            fields = ['a', 'b', 'c', 'first_relevant_month', 'last_relevant_month']
            absorb_fields(self, params, fields)


    # # Launches its dialog and sets its data accordingly.
    # def setup(self, hi_data):
    #     new_gm = RainfallBasedAnnualGMDialog(self.A, self.B, self.C, self.first_relevant_month, self.last_relevant_month, hi_data)
    #     if new_gm is None:
    #         return
    #     self.A = new_gm.A
    #     self.B = new_gm.B
    #     self.C = new_gm.C
    #     self.first_relevant_month = new_gm.first_relevant_month
    #     self.last_relevant_month = new_gm.last_relevant_month

    # Returns the yield based on the rainfall of the current year in
    # the sim. Uses the sim's rainfall to determine.
    def calculate_yearly_yield(self, sim, planted_month):
        year_index = sim.year_index
        # relevant_rain_to_date = sim.monthly_rainfall[(1:12 >= self.first_relevant_month & 1:12 <= self.last_relevant_month & 1:12 >= planted_month % 12 & 1:12 <= sim.month), year]
        month_index_from = max(self.first_relevant_month-1, planted_month % 12)
        month_index_to = min(self.last_relevant_month-1, sim.month)
        relevant_rain_to_date = sim.monthly_rainfall[year_index, month_index_from:month_index_to+1]

        yield_val = max(0, np.polyval([-self.a, self.b, self.c], sum(relevant_rain_to_date)))
        return yield_val

    # # Populates a summary panel to show the current parameter settings.
    # def populate_summary_panel(self, summary_handles, hi_data):
    #     summary_handles.text_a.set('String', str(self.A))
    #     summary_handles.text_b.set('String', str(self.B))
    #     summary_handles.text_c.set('String', str(self.C))
    #
    #     months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
    #     summary_handles.text_first_month.set('String', months[self.first_relevant_month])
    #     summary_handles.text_last_month.set('String', months[self.last_relevant_month])

    # # Populates a gui axes to show the mapping between rainfall and
    # # yield. The optional HarvestIndexData is used to determine the
    # # axis labels / key
    # def populate_summary_graph(self, ax, hi_data):
    #     ax.cla()
    #     p = [-self.A, self.B, self.C]
    #     t = list(range(701))
    #     y = np.polyval(p, t)
    #
    #     ax.plot(t, y)
    #
    #     ax.axis([0, 700, 0, max(y) * 1.2])
    #     ax.set_xlabel('Rainfall (mm)')
    #     ax.set_ylabel(hi_data.units + ' (t/Ha)')
