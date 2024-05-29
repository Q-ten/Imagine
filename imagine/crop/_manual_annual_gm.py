# ManualAnnualGM
#
# Provides based yield for annual crops based on rainfall in relevant
# months within a given year. Uses a quadratic function to map the total
# rain in relevant months to a yield.
from imagine.core.trend import Trend


class ManualAnnualGM:
    def __init__(self,  category, d=None):
        super().__init__()
        self.trend = Trend()
        self.current_data = None
        self.trend.var_type = 'Yearly Data'
        self.trend.trend_type = 'Yearly Data'
        self.trend.trend_data = 0
        self.trend.var_data = 0

    # # Launches its dialog and sets its data accordingly.
    # def setup(self, hi_data):
    #     new_trend = ManualAnnualGMDialog(self.trend, hi_data)
    #     if new_trend is None:
    #         return
    #     self.trend = new_trend

    def set_trend(self, new_trend):
        self.trend = new_trend
        self.current_data = None

    # Returns the yield based on the trend for the current year.
    def calculate_yearly_yield(self, sim):
        if self.current_data is None:
            yield_val = 0
        else:
            yield_val = self.current_data[sim.year]
        return yield_val

    # Populates a summary panel to show the current parameter settings.
    def populate_summary_panel(self, panel, hi_data):
        pass

    # Populates a gui axes to show the trend data.
    # The optional HarvestIndexData is used to determine the
    # axis labels / key
    def populate_summary_graph(self, ax, hi_data):
        if self.trend is None:
            return

        m, v, s = self.trend.create_trend_series(50)
        t = list(range(len(s)))

        ax.bar(s, color=[0.5, 0.5, 1], edgecolor=[0.4, 0.4, 0.6], width=0.9)
        ax.plot(t, m, 'r-', t, m + v, 'g--', t, m - v, 'g--', linewidth=2)
        ax.set_xlim([0, len(s) + 1])
        ax.set_xlabel('Year')
        ax.set_ylabel(hi_data.units + ' (t/Ha)')

    # Samples the trend to determine an entire series of data.
    # Should be called once from the planting function.
    def sample_distribution(self):
        _, _, self.current_data = self.trend.create_trend_series
