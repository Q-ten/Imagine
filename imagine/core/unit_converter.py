class UnitConverter:

    @staticmethod
    def get_unit_conversion_multiplier(a1_num_unit_name, a2_den_unit_name):
        # get_unit_conversion_multiplier Returns a number that works out how many of
        # a2_den_unit_name there are in a1_num_unit_name.
        # For example, if a1_num_unit_name = Km, and a2_den_unit_name = m
        # then ucm = 1000 since there are 1000 m in a Km.

        if a1_num_unit_name == a2_den_unit_name:
            return 1

        base_in_a1 = UnitConverter.get_number_of_base_units_in_unit(a1_num_unit_name)
        base_in_a2 = UnitConverter.get_number_of_base_units_in_unit(a2_den_unit_name)

        return base_in_a1 / base_in_a2

    @staticmethod
    def get_number_of_base_units_in_unit(unit_name):
        base_units = 0

        # Length
        if unit_name == 'Km' or unit_name == 'km' or unit_name == 'm':
            base_units = 1000 if unit_name == 'Km' or unit_name == 'km' else 1

        # Kilo
        elif unit_name == 'Kg' or unit_name == 'Kilo' or unit_name == 'kg' or unit_name == 'Kilogram' or unit_name == 'kilogram':
            base_units = 1000

        # Tonne
        elif unit_name == 'Tonne' or unit_name == 'tonne' or unit_name == 'tn':
            base_units = 1000000

        # Gram
        elif unit_name == 'Gram' or unit_name == 'gm':
            base_units = 1

        # Area
        elif unit_name == 'Hectare' or unit_name == 'hectare' or unit_name == 'Ha':
            base_units = 10000

        elif unit_name == 'Acre' or unit_name == 'acre':
            base_units = 4046.85642

        elif unit_name == 'square m' or unit_name == 'sqm' or unit_name == 'm^2' or unit_name == 'm2' or unit_name == 'square meter':
            base_units = 1

        # Units
        elif unit_name == 'Unit' or unit_name == 'unit':
            base_units = 1

        return base_units
