from collections.abc import Iterable
import re

from imagine.events.crop_year_condition import CropYearCondition
from imagine.events.imagine_condition import ImagineCondition
from imagine.events.time_indexed_condition import TimeIndexedCondition
from imagine.events.and_or_not_condition import AndOrNotCondition
from imagine.events.quantity_based_condition import QuantityBasedCondition
from imagine.events.month_based_condition import MonthBasedCondition
from imagine.events.never_condition import NeverCondition
from imagine.events.event_happened_previously import EventHappenedPreviouslyCondition
from imagine.core.unit import Unit
from imagine.core.rate import Rate
import imagine.core.global_helpers as pimagine_definitions
from imagine.util.read_only_union_dict import ReadOnlyUnionDict, get_deep_union_dict
from dotwiz import DotWiz

""" _condition_defs is a dict that holds the syntax of config based conditions.
    It's then provided via a read only view when requested.
    There are the raw Condition classes that can be created from scratch.
    But there is also a useful syntax of helper functions that is intended to be more expressive and
    readily read/understood/composed in the config file.
    
"""

_condition_defs = {}

simple_fields = [
    TimeIndexedCondition,
    AndOrNotCondition,
    QuantityBasedCondition,
    MonthBasedCondition,
    NeverCondition,
    EventHappenedPreviouslyCondition
]
for f in simple_fields:
    _condition_defs[f.__name__] = f

# Time indexed helpers.
# One based indexing.
# Examples:
#
#   "month_index_is(10)"
#   "year_index_is(15)"
#   "year_index_is([10, 11, 12, 13])"
#   "month_index_is(range(1, 20, 5))"
_condition_defs['month_index_is'] = lambda x, sh="": TimeIndexedCondition('Month', x, shorthand=sh)
_condition_defs['year_index_is'] = lambda x, sh="": TimeIndexedCondition('Year', x, shorthand=sh)


# Quantity Based helpers
#
#   "event_product_comparator('Harvesting', yield_in_tonnes_per_ha, '>=', 4)"
#   where yield_in_tonnes_per_ha has been provided as a 'raw_rate' and can be used in config expressions.
#   "propagation_product_comparator(ncz_width_in_m, '>=', 5)"
#   "output_comparator(tree_height_in_m, '>=', 10)"
#   "event_output_comparator('Feeding', fodder_in_tonnes_per_DSE, '>', 0.01)"
#
def _event_product_comparator(event, raw_rate, comparator, number, sh=""):
    rate = raw_rate.copy()
    rate.number = number
    cond = QuantityBasedCondition('Product', event, comparator, rate, shorthand=sh)
    return cond


def _event_output_comparator(event, raw_rate, comparator, number, sh=""):
    rate = raw_rate.copy()
    rate.number = number
    cond = QuantityBasedCondition('Output', event, comparator, rate, shorthand=sh)
    return cond


def _output_comparator(raw_rate, comparator, number, sh=""):
    rate = raw_rate.copy()
    rate.number = number
    cond = QuantityBasedCondition('Output', 'Monthly Propagation', comparator, rate, shorthand=sh)
    return cond


def _propagation_product_comparator(raw_rate, comparator, number, sh=""):
    rate = raw_rate.copy()
    rate.number = number
    cond = QuantityBasedCondition('Product', 'Monthly Propagation', comparator, rate, shorthand=sh)
    return cond


_condition_defs['event_product_comparator'] = _event_product_comparator
_condition_defs['event_output_comparator'] = _event_output_comparator
_condition_defs['output_comparator'] = _output_comparator
_condition_defs['propagation_product_comparator'] = _propagation_product_comparator

# Month based helper
#
# Example:
#   "month_is("Jan")
#   "month_is(12)
#
# Crop year helper
#
# Example:
#    "crop_year_is(1)"          Means it's in the crop's first calendar year. (Doesn't mean it's 1 year old)
#    "crop_year_is(15)"         Means it's in its 15th calendar year.
_short_months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
_long_months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER',
                'NOVEMBER', 'DECEMBER']


def _month_is(month, sh=""):
    if isinstance(month, str):
        month_index = [index for index, value in enumerate(_short_months) if value == month.upper()]
        if len(month_index) == 0:
            month_index = [index for index, value in enumerate(_long_months) if value == month.upper()]

        if len(month_index) == 1:
            # Convert from natural numbers to 0 indexed. Month 1 is Jan. Month 12 is Dec.
            month_index = month_index[0]
        else:
            raise ValueError(f"Can't parse month: {month}")
    elif isinstance(month, int):
        month_index = month - 1

    if 0 <= month_index <= 11:
        cond = MonthBasedCondition(month_index, shorthand=sh)
        return cond
    else:
        raise ValueError(f"Can't parse month: {month}")


def _crop_year_is(crop_year, sh=""):
    try:
        crop_year = int(crop_year)
    except ValueError:
        raise ValueError(f"Attempt to parse int from input to crop_year_is failed: {crop_year}.")

    cond = CropYearCondition(crop_year, shorthand=sh)
    return cond


_condition_defs['month_is'] = _month_is
_condition_defs['crop_year_is'] = _crop_year_is


# Event happened previously helpers

def _event_happened_x_months_ago(event_name, arg1, arg2=None, sh=""):
    if isinstance(arg1, str) and isinstance(arg2, int):
        comparator = arg1
        months_prior = arg2
    elif isinstance(arg1, int):
        comparator = "="
        months_prior = arg1
    elif isinstance(arg1, Iterable) and hasattr(arg1, '__len__') and hasattr(arg1, '__getitem__'):
        comparator = "="
        months_prior = arg1
    else:
        raise ValueError("Arguments to event_happened_x_months_ago must be "
                         "(event: str, comparator: str, months_prior: int) or "
                         "(event: str, months_prior: int). Arguments provided:"
                         f"{type(event_name).__name__(), type(arg1).__name__(), type(arg2).__name__()}")

    cond = EventHappenedPreviouslyCondition(event_name, months_prior, comparator, shorthand=sh)
    return cond


_condition_defs['event_happened_x_months_ago'] = _event_happened_x_months_ago

# Never helper.
_condition_defs['never'] = lambda sh="": NeverCondition(shorthand=sh)


# Example:
#
#  "never"
#  "event_happened_x_months_ago('Harvesting', ">", 10) and never

# Example:
#
# "event_happened_x_months_ago('Coppice Harvesting', ">", 10)
# "event_happened_x_months_ago('Coppice Harvesting', 10)
# "event_happened_x_months_ago('Coppice Harvesting', [10, 20, 34])

# Useful helper to combine instances or lists of instances into a single list.
def _process_args(cls, *args):
    result = []
    for arg in args:
        if isinstance(arg, cls):
            result.append(arg)
        elif isinstance(arg, list):
            result.extend(item for item in arg if isinstance(item, cls))
    return result


# Any? All?
def _any(*args, sh=""):
    cond_list = _process_args(ImagineCondition, *args)
    if len(cond_list) == 1:
        return cond_list[0]
    else:
        return AndOrNotCondition('Any', cond_list, shorthand=sh)


def _all(*args, sh=""):
    cond_list = _process_args(ImagineCondition, *args)
    if len(cond_list) == 1:
        return cond_list[0]
    else:
        return AndOrNotCondition('All', cond_list, shorthand=sh)


_condition_defs['any'] = _any
_condition_defs['all'] = _all

# Examples:
#
#   "any(c1, c2, c3)

# Construct the globals dictionary of tokens that can be used inside condition expressions:
_condition_env = get_deep_union_dict(_condition_defs, pimagine_definitions.__dict__)

# Expose a dictionary of helper functions for use in code.
# condition_helpers is exported from this module. It is a DotWiz which means that access can be via
# . or ['']
condition_helpers = DotWiz(_condition_defs)


def replace_logical_operators(input_string):
    replaced_string = re.sub(r'\bnot\b', '~', input_string)
    replaced_string = re.sub(r'\band\b', '&', replaced_string)
    replaced_string = re.sub(r'\bor\b', '|', replaced_string)
    replaced_string = re.sub(r'\bnever\b(?!(\(\)))', 'never()', replaced_string)
    return replaced_string


# Evaluates the condition string, but replaces certain keywords with overloaded operators.
# Also assumes the presence of _condition_defs which has been pieced together in this module.
def eval_condition_syntax(condition_str, eval_locals_dict):
    condition_str = replace_logical_operators(condition_str)
    return eval(condition_str, _condition_env, eval_locals_dict)


def eval_condition_dictionary(d):
    keys = d.keys()
    locals_dict = {}
    for key in keys:
        cond = eval_condition_syntax(d[key], locals_dict)
        locals_dict[key] = cond
    return cond


if __name__ == "__main__":
    numerator_unit = Unit("", "Yield", "Tonnes")
    denominator_unit = Unit("", "Area", "Hectares")
    yield_in_tonnes_per_ha = Rate(0, numerator_unit, denominator_unit)
    eval_locals = {"yield_in_tonnes_per_ha": yield_in_tonnes_per_ha}

    cond_str = "month_index_is(56)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "month_index_is([20, 34, 56])"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "month_index_is(range(1, 500, 12))"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "event_product_comparator('Harvesting', yield_in_tonnes_per_ha, '>=', 4)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "month_is('Jan')"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "month_is(12)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "crop_year_is(12)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "event_happened_x_months_ago('Harvesting', '<', 10)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "event_happened_x_months_ago('Harvesting', 100)"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "event_happened_x_months_ago('Harvesting', [10, 20, 34])"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str = "event_happened_x_months_ago('Harvesting', '<', [10, 20, 34])"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    cond_str_1 = "event_happened_x_months_ago('Harvesting', 100)"
    out_1 = eval(cond_str_1, _condition_env, eval_locals)
    cond_str_2 = "month_is(12)"
    out_2 = eval(cond_str_2, _condition_env, eval_locals)
    cond_str_2 = "month_is(10)"
    out_3 = eval(cond_str_2, _condition_env, eval_locals)
    eval_locals['c1'] = out_1
    eval_locals['c2'] = out_2
    eval_locals['c3'] = out_3
    cond_str = "c1 & c2"
    cond_str = "c1 | c2"
    cond_str = "~c1"
    cond_str = "c1 & c2"
    cond_str = "(c1 | c2) & c3"
    out = eval(cond_str, _condition_env, eval_locals)
    print(out.get_longhand())

    print("\n\n")
    print(out_1.get_longhand())
    print(out_2.get_longhand())
    print(out_3.get_longhand())
    cond_str = "c1 and c2 or c3"
    out = eval_condition_syntax(cond_str, eval_locals)
    print(out.get_longhand())

    cond_str = "not c1 and c2 or c3"
    out = eval_condition_syntax(cond_str, eval_locals)
    print(out.get_longhand())

    print("\n\n")
    cond_str = "never"
    cond_str = "event_happened_x_months_ago('Harvesting', [10, 20, 34]) or never"
    out = eval_condition_syntax(cond_str, eval_locals)
    print(out.get_longhand())

    cond_str = "any(c1, c2, c3)"
    out = eval_condition_syntax(cond_str, eval_locals)
    print(out.get_longhand())

    print("\n\n")
    cond_str = "'Harvesting'"
    out_1 = eval_condition_syntax(cond_str, eval_locals)
    eval_locals['harvesting_event_name'] = out_1
    cond_str = "event_happened_x_months_ago('Harvesting', '=', 0, 'Harvesting happened this month.')"
    out_2 = eval_condition_syntax(cond_str, eval_locals)
    print(out_2.get_longhand())
    print(out_2.get_shorthand())
