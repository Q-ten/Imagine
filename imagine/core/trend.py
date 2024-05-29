# A Trend is responsible for providing yearly data that follows a given
# distribution. The trend works by calculating the mean for each year and
# then adding in the variance.
import numpy as np

from imagine.util.absorb_fields import absorb_fields


class Trend:

    _default_type = "Polynomial"

    def __init__(self, trend_type=None, trend_data=None, var_type=None, var_data=None):
        self.private_trend_data_yearly = None
        self.private_trend_data_poly = None
        self.private_var_data_yearly = None
        self.private_var_data_poly = None
        self.trend_import_data_location = None
        self.var_import_data_location = None

        if isinstance(trend_type, dict):
            d = trend_type
            self.load_trend(d)
        else:
            self.trend_type = self._default_type if trend_type is None else trend_type
            self.var_type = self._default_type if var_type is None else var_type

            if trend_data is not None:
                self.trend_data = trend_data
            if var_data is not None:
                self.var_data = var_data

    def create_trend_series(self, n=50):
        if self is None:
            raise ValueError('Trying to createTrendSeries from empty Trend.')
        mean_series = np.zeros(n)
        if self.trend_type == 'Polynomial':
            mean_series = np.polyval(self.trend_data, np.arange(1, n + 1))
        if self.trend_type == 'Yearly Data':
            if len(self.trend_data) >= n:
                mean_series = self.trend_data[:n]
            else:
                mean_series = np.tile(self.trend_data, int(np.floor(n / len(self.trend_data)) + 1))[:n]
        var_series = np.zeros(n)
        if self.var_type == 'Polynomial':
            var_series = np.polyval(self.var_data, np.arange(1, n + 1))
        if self.var_type == 'Yearly Data':
            if len(self.var_data) >= n:
                var_series = self.var_data[:n]
            else:
                var_series = np.tile(self.var_data, int(np.floor(n / len(self.var_data)) + 1))[:n]
        s = mean_series + var_series * np.random.randn(len(var_series))
        m = mean_series
        v = var_series
        return m, v, s

    def import_trend_data(self):
        raise NotImplementedError

    #        self.import_data('trend')

    def import_var_data(self):
        raise NotImplementedError

    #        self.import_data('var')

    @property
    def trend_data(self):
        if self.trend_type == 'Yearly Data':
            return self.private_trend_data_yearly
        elif self.trend_type == 'Polynomial':
            return self.private_trend_data_poly

    @trend_data.setter
    def trend_data(self, data):
        data = np.array(data).T
        if self.trend_type == 'Yearly Data':
            self.private_trend_data_yearly = data
        elif self.trend_type == 'Polynomial':
            self.private_trend_data_poly = data

    @property
    def var_data(self):
        if self.var_type == 'Yearly Data':
            return self.private_var_data_yearly
        elif self.var_type == 'Polynomial':
            return self.private_var_data_poly

    @var_data.setter
    def var_data(self, data):
        data = np.array(data).T
        if self.var_type == 'Yearly Data':
            self.private_var_data_yearly = data
        elif self.var_type == 'Polynomial':
            self.private_var_data_poly = data

    """
    # To be used if we import data. But the SeriesImportTool was a GUI tool.
    # So this will need modification if we want to call this method.
    def import_data(self, type):
        imobj = ImagineObject.getInstance()
        self.sim_length = imobj.simulation_length

        if type == 'trend':
            len = len(self.trend_data)
            if len > self.sim_length:
                self.trend_data = self.trend_data[:self.sim_length]
            elif len < self.sim_length:
                self.trend_data[len+1:50] = np.zeros((self.sim_length - len, 1))
            data = SeriesImportTool(self.trend_data.T, 'Yearly Mean Data')
            if data.size != 0:
                self.trend_data = data.T
            self.trend_type = 'Yearly Data'
        elif type == 'var':
            len = len(self.var_data)
            if len > self.sim_length:
                self.var_data = self.var_data[:self.sim_length]
            elif len < self.sim_length:
                self.var_data[len+1:50] = np.zeros((self.sim_length - len, 1))
            data = SeriesImportTool(self.var_data.T, 'Yearly Variance Data')
            if data.size != 0:
                self.var_data = data.T
            self.var_type = 'Yearly Data'
        else:
            return

        globals()['t'] = self
    """

    @staticmethod
    def is_valid(trend):
        valid = isinstance(trend, Trend) and trend is not None

        if not valid:
            return False

        valid = all([valid, isinstance(trend.trend_type, str), np.issubdtype(trend.trend_data.dtype, np.number),
                     isinstance(trend.var_type, str), np.issubdtype(trend.var_data.dtype, np.number),
                     trend.trend_data is not None, trend.var_data is not None])

        valid = valid and (trend.trend_type == 'Yearly Data' or trend.trend_type == 'Polynomial')
        valid = valid and (trend.var_type == 'Yearly Data' or trend.var_type == 'Polynomial')

        return valid

    def load_trend(self, d):
        self.trend_type = self._default_type
        self.var_type = self._default_type

        simple_fields = ['trend_type', 'var_type']
        absorb_fields(self, d, simple_fields)

        if 'trend_data' in d:
            self.trend_data = d['trend_data']
        if 'var_data' in d:
            self.var_data = d['var_data']

