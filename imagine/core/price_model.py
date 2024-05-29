import imagine.core.global_helpers as global_helpers
from .amount import Amount
import copy
from .rate import Rate
from .trend import Trend
from .unit import Unit
from imagine.util.absorb_fields import absorb_fields


class PriceModel:
    def __init__(self, name: str = "", unit: Unit = Unit(),
                 denominator_unit: Unit = Unit(), allow_cost_unit_changes: bool = True):
        if isinstance(name, dict):
            # In case we pass a dictionary as first arg, load fields from that.
            d = name
            self.load_price_model(d)
        else:
            self.event_name = name
            self.name = self.event_name + " cost"
            self.unit = unit
            self.trend = Trend()
            self.denominator_unit = denominator_unit
            self.allow_cost_unit_changes = allow_cost_unit_changes
            if not unit.measurable:
                unit = copy.deepcopy(unit)
                unit.measurable = self.name
            self.rate = Rate(0, unit, denominator_unit)

        self.notes_paragraphs = []
        self.denominator_unit_is_current = True

    # @property
    # def marked_up_name(self) -> str:
    #     if Trend.is_valid(self.trend) and self.is_valid():
    #         return f'<HTML><FONT color="green">{self.name}</FONT></HTML>'
    #     elif not self.denominator_unit_is_current:
    #         return f'<HTML><FONT color="red">{self.name} [Units No Longer Current]</FONT></HTML>'
    #     else:
    #         return f'<HTML><FONT color="red">{self.name}</FONT></HTML>'

    def mark_denominator_unit_validity(self, is_current: bool):
        if isinstance(is_current, bool):
            self.denominator_unit_is_current = is_current

    def is_valid(self) -> bool:
        return isinstance(self.name, str) and Unit.is_valid(self.unit) and Unit.is_valid(self.denominator_unit)

    @staticmethod
    def is_ready(pm) -> bool:
        return PriceModel.is_valid(pm) and Trend.is_valid(pm.trend)

    # @staticmethod
    # def definition_matches(a, b) -> bool:
    #     if isinstance(a, PriceModel) and isinstance(b, PriceModel):
    #         return (a.name == b.name and a.unit.specific_name == b.unit.specific_name and
    #                 a.denominator_unit.specific_name == b.denominator_unit.specific_name)
    #     return False

    def load_price_model(self, d):
        self.allow_cost_unit_changes = True
        simple_fields = ["name", "event_name", "unit", "denominator_unit", "allow_cost_unit_changes"]
        absorb_fields(self, d, simple_fields)

        if "units" in d:
            r = d["units"]
            if isinstance(r, str):
                r = getattr(global_helpers, r, None)
            if not isinstance(r, Rate):
                if isinstance(r, Unit):
                    r = Rate(0, r, global_helpers._unit)
                else:
                    raise ValueError(f"Unable to parse rate from price model definition: {d['units']}")
            self.rate = r
            self.unit = r.unit
            self.denominator_unit = r.denominator_unit
        if not self.rate.unit.measurable:
            self.rate = copy.deepcopy(self.rate)
            self.rate.unit.measurable = self.name

        if "trend" in d:
            t = d['trend']
            if isinstance(t, dict):
                t = Trend(t)
            if isinstance(t, Trend):
                self.trend = t
            else:
                raise ValueError(f"Can't parse trend in price model configuration: {t}")

