"""
This file is intended to provide easy to use variables for often used but awkward constructs like Units or raw Rates.
They can be used in expressions within config files.
"""
from imagine.core.rate import Rate
from imagine.core.unit import Unit

# Units
_unit = Unit()
unity = _unit

ha = Unit('area', 'hectare')
paddock = Unit('', 'paddock', 'paddock')
dollar = Unit('', 'dollar')
dollars = dollar
tree = Unit('', 'tree', 'tree')
trees = tree

tonne_of_yield = Unit('yield', 'tonne')
tonne_of_grain = Unit('grain', 'tonne')
tonnes_of_yield = tonne_of_yield
tonnes_of_grain = tonne_of_grain

tonne_of_bm = Unit('biomass', 'tonne')
tonne_of_agbm = Unit('above-ground biomass', 'tonne')
tonne_of_bgbm = Unit('below-ground biomass', 'tonne')
tonnes_of_bm = tonne_of_bm
tonnes_of_agbm = tonne_of_agbm
tonnes_of_bgbm = tonne_of_bgbm
stumpage = Unit('stumpage', 'cubic metre', 'm^3')
stumpage_thinning = Unit('stumpage (thinning)', 'cubic metre', 'm^3')
tree_height = Unit('tree height', 'metre')
co2e = Unit('CO2e', 'tonne')
amenity_increase = Unit('amenity increase', 'dollar')
biodiversity_index = Unit('biodiversity index', 'habitat index', 'habitat index', 'hab. ha/ha')
biodiversity = Unit('biodiversity', 'habitat hectare', 'hab. ha')

# Pasture units
dse = Unit('stocking rate', 'DSE')
foo = Unit('FOO', 'kilogram', 'kg')
foo_shortfall = Unit('FOO Shortfall', 'percent', '%', '%')
shelter_productivity_bump = Unit('Shelter Productivity Bump', 'percent', '%', '%')
wool_income = Unit('Wool Income', 'dollar')
meat_income = Unit('Meat Income', 'dollar')
fodder = Unit("Fodder", "tonne")


# Spatial interactions units
root_mass_extent = Unit('root mass extent', 'metre')
competition_scale_factor = Unit('competition scale factor', 'percent', unit_plural="percent")
competition_at_tree_raw_dl = Unit('competition at tree (raw) (dl)', 'percent', unit_plural="percent")
competition_at_tree_scaled_sl = Unit('competition at tree (scaled) (sl)', 'percent', unit_plural="percent")
wlm_scale_factor = Unit('WLM scale factor', 'percent', unit_plural="percent")
wlm_at_tree_raw_dl = Unit('WLM at tree (raw) (dl)', 'percent', unit_plural="percent")
wlm_at_tree_scaled_sl = Unit('WLM at tree (scaled) (sl)', 'percent', unit_plural="percent")
ncz_width = Unit('NCZ width', 'metre')
exclusion_zone_width = Unit('exclusion zone width', 'metre')
base_yield = Unit('base yield', 'tonne')
temporally_modified_yield = Unit('temporally modified yield', 'tonne')

competition_income_loss = Unit("competition income loss", "dollar")
ncz_area = Unit("NCZ area", "hectare")
belt_opportunity_cost = Unit("belt opportunity cost", "dollar")

crop_interface_length = Unit('crop interface length', 'metre')
km_of_rows = Unit('total row length', 'kilometre', 'km')
km_of_belts = Unit('total belt length', 'kilometre', 'km')



# Rates
tonnes_of_yield_per_ha = Rate(0, tonne_of_yield, ha)
tonnes_of_grain_per_ha = Rate(0, tonne_of_grain, ha)
tonnes_of_bm_per_ha = Rate(0, tonne_of_bm, ha)

dollars_per_ha = Rate(0, dollar, ha)
dollars_per_tonne_of_grain = Rate(0, dollar, tonne_of_grain)
dollars_per_tonne_of_yield = Rate(0, dollar, tonne_of_yield)
dollars_per_tonne_of_bm = Rate(0, dollar, tonne_of_bm)

# FOO based self replacing flock model
foo_per_ha = Rate(0, foo, ha)
dollars_per_dollar_of_wool_income = Rate(0, dollar, wool_income)
dollars_per_dollar_of_meat_income = Rate(0, dollar, meat_income)
dollars_per_tonne_of_fodder = Rate(0, dollar, fodder)
dollars_per_dse = Rate(0, dollar, dse)

dollars_per_m3_of_stumpage = Rate(0, dollar, stumpage)
dollars_per_m3_of_stumpage_thinning = Rate(0, dollar, stumpage_thinning)
dollars_per_tonne_of_co2e = Rate(0, dollar, co2e)
dollars_per_m_of_crop_interface_length = Rate(0, dollar, crop_interface_length)
dollars_per_tree = Rate(0, dollar, tree)
dollars_per_dollar_of_amenity_increase = Rate(0, dollar, amenity_increase)
dollars_per_habitat_ha = Rate(0, dollar, biodiversity)



