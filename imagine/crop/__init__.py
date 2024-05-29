from .__crop import Crop


# Ensure that when the crop module is loaded, the growth models are also loaded.
def _register_growth_model_subclasses():
    # Simply importing them will trigger the __init_subclass__ method in growth model base class
    # and these will appear as
    from .ab_gompertz_growth_model import ABGompertzGrowthModel
    from .annual_growth_model import AnnualGrowthModel
    from .sheltered_pasture_growth_model import ShelteredPastureGrowthModel
    from .fixed_yield_growth_model import FixedYieldGrowthModel


_register_growth_model_subclasses()

