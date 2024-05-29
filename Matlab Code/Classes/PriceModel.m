% A Pricemodel can represent costs or income. We need a name for the item, so we can put
% it on a balance sheet, then we need a unit for the price to refer to, and
% then we need the price itself, which will be represented by a Trend.
% So we have a name, a denominatorUnit, and a trend. The unit will always
% be a Money type unit, usually Dollars, but possibly cents, or possibly
% foreign currency.
%
% PriceModels should be defined for each income and cost for a given crop.
% The growthModelDelegate will be responsible for the income and costs from
% it's events. The growthModelDelegate constructor should define a list of
% productPriceModels and costPriceModels, such that the name and the Units are defined.
% The trend can be initialised to an empty trend.
% A growthModelDelegate should not be ready until all the priceModels have
% non-empty trends. It's ok if they are specifically the Zero trend.
% 
% We also add in a notes field. This can be set by the developer to send
% messages to the user, but the user can change this at will. It will stay
% with the priceModel though and be shown when the priceModel trend is
% being set. It is saved as a list of paragraphs, each paragraph saved as a
% string in a cell array.
classdef PriceModel
    
    properties       
        name = '';
        trend = Trend.empty(1, 0);
        unit = Unit.empty(1, 0);
        denominatorUnit = Unit.empty(1, 0);
        notesParagraphs = {};
        denominatorUnitIsCurrent = true;
    end
    
    properties(SetAccess = private)
        % Says whether we can change the denominatorUnit in the crop wizard
        % costs page.
        % All extraCostPriceModels should set this to false when
        % constructing the PriceModel.
        allowCostUnitChanges = true; 
    end
    
    properties(Dependent)
         
        % Gives the name in HTML and changes the colour to red if the trend
        % is invalid, or green if it's ready to go.
        markedUpName
        
    end
    
    methods
        % Constuctor for the PriceModel. Doesn't construct the Trend.
        function pm = PriceModel(name, unit, denominatorUnit, allowCostUnitChanges)
           if nargin >= 3
                pm.name = name; 
                pm.unit = unit;
                pm.denominatorUnit = denominatorUnit;
                if nargin == 4
                    pm.allowCostUnitChanges = allowCostUnitChanges;
                end
           end
        end
        
        % Get the markedUpName. Simply colours the name green if trend is
        % valid or red if it isn't.
        function markedUpName = get.markedUpName(obj)
        
            if Trend.isValid(obj.trend) && PriceModel.isValid(obj)
                markedUpName = ['<HTML><FONT color="green">', obj.name, '</FONT></HTML>'];
            else
                if ~obj.denominatorUnitIsCurrent
                    markedUpName = ['<HTML><FONT color="red">', obj.name, ' [Units No Longer Current]</FONT></HTML>'];
                else
                    markedUpName = ['<HTML><FONT color="red">', obj.name, '</FONT></HTML>'];
                end
            end            
        end
        
        function obj = markDenominatorUnitValidity(obj, TF)
            if islogical(TF)
               obj.denominatorUnitIsCurrent = TF; 
            end
        end
    end
    
    methods(Static)
       
        function valid = isValid(pm) 
            valid = isa(pm, 'PriceModel');
            valid = valid && pm.denominatorUnitIsCurrent;
            valid = all([valid ischar(pm.name), Unit.isValid(pm.unit), Unit.isValid(pm.denominatorUnit)]);
            valid = all([valid ~isempty(pm.name), ~isempty(pm.unit), ~isempty(pm.denominatorUnit)]); 
        end
        
        function ready = isReady(pm)
           ready = PriceModel.isValid(pm);
           if ready
              ready = all([Trend.isValid(pm.trend)]); 
           end
           if ready
              ready = all([~isempty(pm.Trend)]); 
           end
        end
        
        % Returns true if the name and units of a and b match.
        % Requires a and b to be priceModels.
        function match = definitionMatches(obja, objb)
            match = isa(obja, 'PriceModel') && isa(objb, 'PriceModel');
            if match 
               match = all([strcmp(obja.name, objb.name), ...
                   strcmp(obja.unit.specificName, objb.unit.specificName), strcmp(obja.denominatorUnit.specificName, objb.denominatorUnit.specificName)]);%, ...
                   %strcmp(obja.unit.speciesName, objb.unit.speciesName), strcmp(obja.denominatorUnit.speciesName, objb.denominatorUnit.speciesName)]);
            end
        end

    end
    
end