from dotwiz import DotWiz
from imagine.functions.shelter_productivity_boost_function import shelter_productivity_boost_function


def get_formosa_settings():

    settings = DotWiz()

    # 1.0 to 1.5 kg DM/DSE/day
    settings.daily_consumption_per_dse = 1.2

    # Additional sales if we eliminated ALL deaths each year.
    settings.all_deaths = {}
    settings.all_deaths.ewes = 32
    settings.all_deaths.ewe_hoggets = 12
    settings.all_deaths.ewe_lambs = 60
    settings.all_deaths.rams = 0
    settings.all_deaths.wethers = 0
    settings.all_deaths.wether_hoggets = 0
    settings.all_deaths.wether_lambs = 60

    # 3m before we start preventing deaths.
    settings.shelter_benefit_min_height = 3
    settings.shelter_benefit_max_height = 20
    # 50% of deaths prevented through shelter benefit after 20m.
    settings.shelter_benefit_max = 0.5

    # This gives the growth by rainfall (kg FOO / ha / mm rainfall).
    # Provide 12 monthly values.
    settings.growth_per_mm_rain_by_month = [0.28, 0.112, 0.17, 0.147, 0.113, 0.143, 0.083, 0.1, 0.649, 1.258, 0.665,
                                            0.45]
    settings.expected_daily_eto_by_month = [6.0236559139785, 5.27369308600337, 3.87450076804916, 2.30650793650793,
                                            1.35345622119815, 0.970340356564018, 1.07018095987411, 1.54177812745869,
                                            2.39479674796747, 3.51612903225807, 4.61365853658536, 5.56664044059796]

    # The distances into the paddock for our productivity function, in terms of tree heights (THs).
    settings.model_distances_in_tree_heights = [0.5, 1.5, 5, 8, 12, 20]


    # Give the percentage increase of the productivity per monthly daily ETo, for each TH point into the pasture.
    # DSM20180613 removed the 'byETO' function as there was no justifiable relationship with ETO
    settings.sheltered_bump_factor_by_eto = [-0.204585393635111, 0.274247334084933, 0.303307946847266, 0.22645221705747,
                                             0.137195481826896, 5.84429327412162E-02]

    # Returns the additional FOO that comes from the shelter productivity boost.
    # TH is the current tree height.
    # OPProductivity is the FOO generated at Open Paddock.
    settings.shelter_productivity_boost_function = shelter_productivity_boost_function




    # Below is subject to change, or not used
    settings.runoff_factor = 0.2
    settings.evap_factor = 0.79
    # Because we can have higher ETc than rainfall, to calculate available water, we'll use max(rain-runoff-ETc*.79, (rain-runoff)*.2) <- this last parameter is the minimumUseableRainfallRatio.
    settings.minimum_usable_rainfall_ratio = 0.2

    # Gives percentage of OP evap avoided in shelter zone (by model tree heights)
    settings.sheltered_evap_model_pct_by_tree_heights = [0.45, 0.41, 0.21, 0.13, 0.9, 0]

    settings.kc_by_month = [0.3, 0.3, 0.4, 0.45, 0.5, 0.55, 0.55, 0.65, 0.75, 0.75, 0.5]

    # Gives competition level at x tree heights into paddock.
    settings.competition_model_a = -0.1671
    settings.competition_model_b = 0.53

    return settings


def get_formosa_settings10():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-3.40975656058519E-02, 4.57078890141555E-02, 5.05513244745443E-02, 3.77420361762451E-02, 2.28659136378161E-02, 9.74048879020271E-03]
    return settings


def get_formosa_settings20():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-6.81951312117037E-02, 0.091415778028311, 0.101102648949089, 7.54840723524902E-02, 4.57318272756321E-02, 1.94809775804054E-02]
    return settings


def get_formosa_settings30():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.102292696817556, 0.137123667042466, 0.151653973423633, 0.113226108528735, 6.85977409134482E-02, 2.92214663706081E-02]
    return settings


def get_formosa_settings40():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.136390262423407, 0.182831556056622, 0.202205297898177, 0.15096814470498, 9.14636545512643E-02, 3.89619551608108E-02]
    return settings


def get_formosa_settings50():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.170487828029259, 0.228539445070777, 0.252756622372721, 0.188710180881225, 0.11432956818908, 4.87024439510135E-02]
    return settings


def get_formosa_settings60():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.204585393635111, 0.274247334084933, 0.303307946847266, 0.22645221705747, 0.137195481826896, 5.84429327412162E-02]
    return settings


def get_formosa_settings70():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.238682959240963, 0.319955223099088, 0.35385927132181, 0.264194253233715, 0.160061395464712, 6.81834215314189E-02]
    return settings


def get_formosa_settings80():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.272780524846815, 0.365663112113244, 0.404410595796354, 0.301936289409961, 0.182927309102529, 7.79239103216217E-02]
    return settings


def get_formosa_settings90():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.306878090452667, 0.411371001127399, 0.454961920270899, 0.339678325586206, 0.205793222740345, 8.76643991118244E-02]
    return settings


def get_formosa_settings100():
    settings = get_formosa_settings()
    settings.sheltered_bump_factor_by_eto = [-0.340975656058519, 0.457078890141555, 0.505513244745443, 0.377420361762451, 0.228659136378161, 9.74048879020271E-02]
    return settings
