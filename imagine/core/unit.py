from imagine.core.unit_symbol_registry import usr


# Description: A class for storing unit information.
class Unit:
    
    def __init__(self, measurable='', unit_name='', unit_symbol=None, unit_plural=None):
        
        if not isinstance(measurable, str) or not isinstance(unit_name, str):
            raise ValueError('Must pass two to four string arguments to the Unit constructor.')
        if unit_symbol is None:
            if unit_name == 'unit':
                unit_symbol = usr.get_symbol_from_name(measurable)  # Sometimes we allow just 'dollar' or 'paddock'.
            else:
                unit_symbol = usr.get_symbol_from_name(unit_name)

            unit_symbol = unit_symbol if unit_symbol else ""

        if unit_plural:
            if not isinstance(unit_plural, str):
                raise ValueError('unit_plural must be of type str.')

        self.measurable = measurable
        self.unit_name = unit_name
        self.unit_symbol = unit_symbol
        self.unit_plural = unit_plural if unit_plural else unit_name + 's'

    def __hash__(self):
        print(f"... in Unit.hash   {self.measurable}...", flush=True)
        return hash(self.measurable)

    @property
    def readable_denominator_unit(self):
        if self.unit_name == 'unit':
            if not self.measurable:
                return ''
            else:
                return f'per {self.measurable}'
        else:
            return f'per {self.unit_name} of {self.measurable}'

    @property
    def readable_unit(self):
        if self.unit_name == 'unit':
            if not self.measurable:
                return ''
            else:
                if self.measurable in {'Percentage', 'Percent', 'percentage', 'percent', '%'}:
                    return '%'
                else:
                    return f'{self.measurable}s'
        else:
            if self.unit_name == 'Dollar':
                return '$'
            else:
                return f'{self.unit_name}s of {self.measurable}'

    @property
    def unit_longhand(self):
        symbol = f"({self.unit_symbol})" if self.unit_symbol else ""
        out = f"[{self.measurable} | ({self.unit_plural}) {symbol}]"
        return out

    @staticmethod
    def is_valid(unit):
        if not isinstance(unit, Unit):
            print('Invalid Unit passed:\nNot an instance of the Unit class or subclass.')
            return False
        valid = True
        msg = []
        if not isinstance(unit.measurable, str):
            valid = False
            msg.append('measurable not a string.')
        if not isinstance(unit.unit_name, str):
            valid = False
            msg.append('unit_name not a string.')
        if msg:
            print('Invalid Unit passed.')
            for m in msg:
                print(m)
        return valid
    
    def __eq__(self, other):
        if isinstance(other, Unit):
            if self.measurable == other.measurable and self.unit_name == other.unit_name:
                return True
        return False
    
    def __ne__(self, other):
        return not self.__eq__(other)
    
    # def handle_eq(self, other):
    #     return super().__eq__(other)

