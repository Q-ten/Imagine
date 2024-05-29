from imagine.core.unit_converter import UnitConverter
from imagine.core.unit import Unit


class Amount:
    def __init__(self, number=None, unit=None):
        if number is None:
            self.number = 0
            self.unit = Unit()
        elif unit is None:
            raise ValueError('Must pass a valid Unit object as second argument to the Amount constructor.')
        elif not isinstance(number, (int, float)):
            raise TypeError('Must pass a number as first argument to Amount constructor')
        elif not Unit.is_valid(unit):
            raise ValueError('Must pass a valid Unit object as second argument to the Amount constructor.')
        else:
            self.number = number
            self.unit = unit

    def copy(self):
        return Amount(self.number, self.unit)

    def __add__(self, other):
        if self._assert_addable(other):
            amt = self.copy()
            amt.number = self.number + other.number
            return amt

    def _assert_addable(self, other):
        from imagine.core.rate import Rate

        if not isinstance(other, Amount):
            raise TypeError('Both inputs to Amount.plus/minus must be members of the Amount Class or a subclass such as Rate.')
        elif self.unit != other.unit:
            raise ValueError('Both inputs to Amount.plus/minus must have identical units.')
        elif isinstance(self, Rate) or isinstance(other, Rate):
            if not (isinstance(self, Rate) and isinstance(other, Rate)):
                raise TypeError('If one of the inputs to Amount.plus/minus is a Rate, then both inputs must be.')
            elif self.denominator_unit != other.denominator_unit:
                raise ValueError('Both inputs to Amount.plus/minus must have identical denominatorUnits.')
        return True

    def __sub__(self, other):
        if self._assert_addable(other):
            amt = self.copy()
            amt.number = self.number - other.number
            return amt

    
    def __mul__(self, other):
        if isinstance(other, (int, float)):
            self.number *= other
            return self

        if not isinstance(other, Amount):
            raise TypeError('Both inputs to Amount.times must be members of the Amount Class or a subclass such as Rate.')
        from imagine.core.rate import Rate
        if not isinstance(self, Rate) and not isinstance(other, Rate):
            raise ValueError('At least one of the inputs to Amount.times must be a member of the Rate Class')

        if isinstance(self, Rate):
            temp = self
            self = other
            other = temp

        if self.unit == other.denominator_unit:
            # then it's fine.
            pass
        elif self.unit == other.unit:
            # then invert a2
            a2 = other.copy()
            a2.invert()
            other = a2
        elif isinstance(self, Rate):
            if self.denominator_unit == other.unit:
                # then we swap the variables.
                temp = self
                self = other
                other = temp
            elif self.denominator_unit == other.denominator_unit:
                # then we should invert the first one.
                a1 = self.copy()
                a1.invert()
                self = a1
            else:
                # Then there's a problem.
                raise ValueError('Problem in Amount.times. Cannot find a common unit to cancel in inputs.')

        ucm = UnitConverter.get_unit_conversion_multiplier(self.unit.unit_name, other.denominator_unit.unit_name)

        if isinstance(self, Rate):
            amt = Rate(self.number * other.number * ucm, other.unit, self.denominator_unit)
        else:
            amt = Amount(self.number * other.number * ucm, other.unit)

        return amt

    def __eq__(self, other):
        from imagine.core.rate import Rate

        if isinstance(self, Rate) and isinstance(other, Rate):
            return all([self.number == other.number, self.unit == other.unit, self.denominator_unit == other.denominator_unit])
        if isinstance(self, Rate) and not isinstance(other, Rate):
            return False
        if not isinstance(self, Rate) and isinstance(other, Rate):
            return False
        if not isinstance(self, Rate) and not isinstance(other, Rate):
            return all([self.number == other.number, self.unit == other.unit])

    def __ne__(self, other):
        return not self.__eq__(other)

    def __rmul__(self, other):
        if isinstance(other, (int, float)):
            self.number *= other
            return self

    @property
    def amount_name(self):
        return self.unit.measurable

    @property
    def amount_unit_symbol(self):
        from imagine.core.rate import Rate
        if isinstance(self, Rate):
            if self.denominator_unit.unit_symbol:
                return self.unit.unit_symbol + "/" + self.denominator_unit.unit_symbol
        return self.unit.unit_symbol

    @property
    def amount_unit_longhand(self):
        from imagine.core.rate import Rate
        out = self.unit.unit_longhand
        if isinstance(self, Rate) and self.denominator_unit.unit_name:
            out += f" / {self.denominator_unit.unit_longhand}"
        return out

