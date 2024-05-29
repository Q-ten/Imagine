import numpy as np
from imagine.core.amount import Amount
from imagine.core.unit import Unit
from imagine.util.helper_tests import is_numeric_array


# Description: Rate class for the Unit class. A Rate is a number with a numerator and denominator unit.
class Rate(Amount):
    def __init__(self, number=None, numerator_unit=None, denominator_unit=None):
        super().__init__()
        if number is not None and numerator_unit is not None and denominator_unit is not None:
            if isinstance(number, (int, float)):
                self.number = number
            else:
                raise ValueError('Must pass a number as first argument to Amount constructor')

            if Unit.is_valid(numerator_unit):
                self.unit = numerator_unit
            else:
                raise ValueError('Must pass a valid Unit object as second argument to the Amount constructor')
            if Unit.is_valid(denominator_unit):
                self.denominator_unit = denominator_unit
            else:
                raise ValueError('Must pass a valid Unit object as third argument to the Rate constructor')

            # # Make a larger array if an array is passed in.
            # if isinstance(number, np.ndarray):
            #     m, n = number.shape
            #     if m > 1 or n > 1:
            #         # Pre-allocate array, setting the units. Use for loop
            #         # to set the number.
            #         amt = np.empty((m, n), dtype=object)
            #         for i in range(m):
            #             for j in range(n):
            #                 # Set each value
            #                 amt[i, j] = Rate(number[i, j], numerator_unit, denominator_unit)

        elif number is None and numerator_unit is None and denominator_unit is None:
            # Initialise to 1 Unit / Unit if no arguments are given.
            # It's a valid Rate, but gives no inforamtion.
            # Multiplying by this rate should do nothing.
            self.number = 1
            self.unit = Unit()
            self.denominator_unit = Unit()
        else:
            raise ValueError('Must pass 0 or 3 arguments to the Rate constructor: a number, a numerator unit and a denominator unit.')

    def invert(self):
        if self.number == 0:
            raise ValueError('Cannot invert a zero Rate.')
        return Rate(1 / self.number, self.denominator_unit, self.unit)

    def copy(self):
        return Rate(self.number, self.unit, self.denominator_unit)

    @classmethod
    def array(cls, number, numerator_unit, denominator_unit):
        # Make a larger array if an array is passed in.
        if isinstance(number, np.ndarray):
#            m, n = number.shape
            if number.size > 1: #m > 1 or n > 1:
                # Pre-allocate array, setting the units. Use for loop
                # to set the number.
                amts = np.empty(number.shape, dtype=object)
                for i in range(number.size):
                    amts[i] = Rate(number[i], numerator_unit, denominator_unit)
                # for i in range(m):
                #     for j in range(n):
                #         # Set each value
                #         amts[i, j] = Rate(number[i, j], numerator_unit, denominator_unit)

                return amts

        return np.empty(0, dtype=object)

