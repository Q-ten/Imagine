import warnings

import numpy as np
from dotwiz import DotWiz
from pyjson5 import pyjson5

from imagine.core.trend import Trend
from imagine.core import ImagineObject
from imagine.util.helper_tests import is_numeric_array

from imagine.util.dist_sampling import sample_from_gaussians, sample_from_gamma_distributions
from imagine.util.load_series_data import resolve_series


class ClimateManager:
    _instance = None

    def __init__(self):
        raise RuntimeError('Call get_instance() instead')

    @classmethod
    def get_instance(cls, loaded_obj=None):
        if loaded_obj and isinstance(loaded_obj, ClimateManager) and cls._instance != loaded_obj:
            cls._instance = loaded_obj
            print('Set ClimateMgr to loadedClimateMgr.')
        elif not cls._instance:
            cls._instance = cls.__new__(cls)
            cls._instance._climate_manager_constructor()
        return cls._instance

    def _climate_manager_constructor(self):
        #        self.rainfall_axis_handle = None
        # TODO: remove the field climate_model. We're replacing it with climate_series_models.
        # TODO: remove monthly_rainfall_trend_parameters.
#        self.monthly_rainfall_trend_parameters = {}
#        self.climate_model = None
        self.required_series = ["monthly rainfall"]
        self.climate_series_models = DotWiz()
        # climate_series_models[series_name] is a dict.
        # Must have a field get_series that is a function that returns series data for use in a sim.

    # def generate_monthly_rainfall(self):
    #     params = self.monthly_rainfall_trend_parameters
    #     use_yearly_data = params.get('useYearlyData', False)
    #     use_zero_variance = params.get('useZeroVariance', False)
    #
    #     im_ob = ImagineObject.get_instance()
    #     sim_length = im_ob.simulation_length
    #
    #     if use_yearly_data:
    #         monthly_rain = np.transpose(params['yearlyRainMeans'])
    #         if not use_zero_variance:
    #             monthly_rain += np.multiply(
    #                 np.transpose(params['yearlyRainSDs']),
    #                 np.random.randn(len(params['yearlyRainSDs']), len(params['yearlyRainSDs'][0]))
    #             )
    #     else:
    #         monthly_rain = np.zeros((12, sim_length))
    #
    #         for i in range(12):
    #             rain_sd = 0 if use_zero_variance else params['rainSDs'][i]
    #             t = Trend('Polynomial', params['rainMeans'][i], 'Polynomial', rain_sd)
    #             _, _, s = t.create_trend_series(sim_length)
    #             monthly_rain[i, :] = s
    #
    #     monthly_rain_min = np.zeros((12, sim_length))
    #     monthly_rain = np.maximum(monthly_rain, monthly_rain_min)
    #
    #     return monthly_rain

    def get_monthly_average_rainfall(self):
        return self.climate_series_models['monthly rainfall'].means

    # def edit_monthly_rainfall_parameters(self):
    #     self.climate_model = MonthlyRainfallDialogue(self.monthly_rainfall_trend_parameters)
    #     if self.climate_model:
    #         self.monthly_rainfall_trend_parameters = self.climate_model
    #         iwm = ImagineWindowManager.get_instance()
    #         iwm.draw_climate_axes(self.climate_model)

    def is_ready_for_simulation(self):
        im_ob = ImagineObject.get_instance()
        sim_length = im_ob.simulation_length

        if not (self.climate_model and self.monthly_rainfall_trend_parameters):
            return False

        return (
                len(self.monthly_rainfall_trend_parameters['rain_means']) == 12 and
                len(self.monthly_rainfall_trend_parameters['rain_sds']) == 12 and
                all(isinstance(val, (int, float)) for val in self.monthly_rainfall_trend_parameters['rain_means']) and
                all(isinstance(val, (int, float)) and val >= 0 for val in
                    self.monthly_rainfall_trend_parameters['rain_sds'])
        )

    def get_series(self, series_name):
        im_ob = ImagineObject.get_instance()
        if series_name in self.climate_series_models:
            return self.climate_series_models[series_name].get_series(im_ob.simulation_length)
        return None

    def load_scenario(self, scenario_folder):
        climate_sub_folder = scenario_folder / 'Climate'
        if not climate_sub_folder.is_dir():
            raise ValueError(f'Scenario climate folder does not exist: {str(climate_sub_folder)}')

        for file_path in climate_sub_folder.iterdir():

            if file_path.is_file():
                if file_path.suffix == '.json5' and file_path.name[0] != '_':
                    with open(file_path, 'r') as file:
                        data = pyjson5.load(file)
                        data = resolve_series(data)
                        data = DotWiz(data)

                        self.parse_climate_data(data)

                        # Stop after the first matching file. There ought to be only one non-hidden file in the folder.
                        return

        raise ValueError(f'No valid climate file found in: {str(climate_sub_folder)}.')

    def parse_climate_data(self, d):
        # Note: The climate manager could be expanded to a module that supports different types of data
        # and different models for storing or generating the data and over potentially different timeframes.
        # For now, only monthly rainfall is required. It is foreseeable that temperature, humidity, wind, CO2, ...
        # and potentially other factors could be provided as a time series for consumption by the simulation.
        #
        # But for now, it's just monthly rainfall, so we'll deal with it inside the ClimateManager.
        # However, the format of the climate data file will be required to follow a more general structure:
        #
        # {
        #    climate_series_models: [
        #       {
        #           series_name: "monthly rainfall",
        #           series_model: "gaussian"
        #           ... parameters suitable for the given model.
        #       },
        #      ...
        #   ]
        # }

        if not isinstance(d, dict):
            raise ValueError("A dictionary is expected when parsing the climate data.")

        if "climate_series_models" not in d:
            raise ValueError("Expected climate_series_models field in climate configuration data.")

        if isinstance(d['climate_series_models'], dict):
            self._parse_climate_series_models(d['climate_series_models'])
        elif isinstance(d['climate_series_models'], list):
            for series_item in d['climate_series_models']:
                self._parse_climate_series_models(series_item)

        # Check that every required series is present.
        for series_name in self.required_series:
            if series_name not in self.climate_series_models:
                raise ValueError(f"Required climate series '{series_name}' not found in climate configuration data.")

        # Monthly rainfall is requied and we need the means for rainfall.from
        # If the rainfall model is not gaussian, calculate means from a large sample.from
        if "means" not in self.climate_series_models['monthly rainfall']:
            means = np.mean(self.climate_series_models['monthly rainfall'].get_series(1000), axis=0)
            self.climate_series_models['monthly rainfall'].means = means

    def _parse_climate_series_models(self, d):
        # d is a dictionary containing the name and model of the series as well as required parameters.
        # Should add the series to climate manager's climate_series_models dictionary.
        # The climate series should be a dict that includes get_series, a function that should return the climate
        # series for use in a simulation.

        if "series_name" not in d:
            return
        if not isinstance(d["series_name"], str):
            return
        if "series_model" not in d:
            return

        valid_models = ["gaussian", 'gamma', 'fixed']
        if d["series_model"].lower() not in valid_models:
            return

        if d["series_model"] == "gaussian":
            required_fields = [('means', is_numeric_array((12))),
                               ('sds', is_numeric_array((12)))]

            for field_name, test in required_fields:
                if field_name not in d or not test(d[field_name]):
                    return

            # After checking that the parameters are present and valid, create the series model.
            gaussian_model = DotWiz()
            gaussian_model["means"] = d["means"]
            gaussian_model["sds"] = d["sds"]
            gaussian_model.get_series = lambda n: sample_from_gaussians(gaussian_model["means"],
                                                                        gaussian_model["sds"], n)
            self.climate_series_models[d["series_name"]] = gaussian_model

        if d["series_model"] == "gamma":
            required_fields = [('alphas', is_numeric_array(12)),
                               ('betas', is_numeric_array(12))]

            for field_name, test in required_fields:
                if field_name not in d or not test(d[field_name]):
                    return

            # After checking that the parameters are present and valid, create the series model.
            gamma_model = DotWiz()
            gamma_model["alphas"] = d["alphas"]
            gamma_model["betas"] = d["betas"]
            gamma_model.get_series = lambda n: sample_from_gamma_distributions(gamma_model["alphas"],
                                                                               gamma_model["betas"], n)
            self.climate_series_models[d["series_name"]] = gamma_model

        if d["series_model"] == "fixed":
            # required_fields = [('series', is_numeric_array((12, 50)))]
            #
            # for field_name, test in required_fields:
            #     if field_name not in d or not test(d[field_name]):
            #         return
            data = d["series"]
            data = np.array(data)
            data = np.reshape(data, (50, 12))


            # After checking that the parameters are present and valid, create the series model.
            fixed_model = DotWiz()
            # fixed_model["monthly_data"] = np.array(d["series"])
            fixed_model["monthly_data"] = data
            fixed_model.get_series = lambda n: np.copy(fixed_model["monthly_data"][:n])

            self.climate_series_models[d["series_name"]] = fixed_model

