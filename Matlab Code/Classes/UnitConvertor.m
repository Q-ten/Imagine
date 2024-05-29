
classdef UnitConvertor

    methods (Static)
    
        function ucm = getUnitConversionMultiplier(a1_num_unitName, a2_den_unitName);
        %getUnitConversionMultiplier Returns a number that works out how many of
        %a2_den_unitName there are in a1_num_unitName.
        %   For example, if a1_num_unitName = Km, and a2_den_unitName = m
        %   then ucm = 1000 since there are 1000 m in a Km.

        if strcmp(a1_num_unitName, a2_den_unitName)
            ucm = 1;
            return
        end

        baseInA1 = getNumberOfBaseUnitsInUnit(a1_num_unitName);
        baseInA2 = getNumberOfBaseUnitsInUnit(a2_den_unitName);

        ucm = baseInA1 / baseInA2;

        end

    end
    
    methods (Access = private)
        function baseUnits = getNumberOfBaseUnitsInUnit(unitName)

            baseUnits = 0;

            switch unitName

                % Length
                case 'Km'
                    baseUnits = 1000;

                case 'm'
                    baseUnits = 1;

                case 'km'
                    baseUnits = 1000;

                % Kilo
                case 'Kg'
                    baseUnits = 1000;

                case 'Kilo'
                    baseUnits = 1000;

                case 'kg'
                    baseUnits = 1000;

                case 'Kilogram'
                    baseUnits = 1000;

                case 'kilogram'
                    baseUnits = 1000;

                % Tonne
                case 'Tonne'
                    baseUnits = 1000000;

                case 'tonne'
                    baseUnits = 1000000;

                case 'tn'
                    baseUnits = 1000000;

                % Gram
                case 'Gram'
                    baseUnits = 1;

                case 'gm'
                    baseUnits = 1;

                % Area

                % Hectares
                case 'Hectare'
                    baseUnits = 10000;

                case 'hectare'
                    baseUnits = 10000;

                case 'Ha'
                    baseUnits = 10000;

                % Acres
                case 'Acre'
                    baseUnits = 4046.85642;

                case 'acre'
                    baseUnits = 4046.85642;

                % Square meters
                case 'square m'
                    baseUnits = 1;

                case 'sqm'
                    baseUnits = 1;

                case 'm^2'
                    baseUnits = 1;

                case 'm2'
                    baseUnits = 1;

                case 'square meter'
                    baseUnits = 1;

                % Units
                case 'Unit'
                    baseUnits = 1;

                case 'unit'
                    baseUntis = 1;

            end
        end
        
    end
end

