classdef (Sealed = true) ConditionUpdater < handle
    
    properties (Access = private)
       quantityConditions = QuantityBasedCondition.empty(1, 0);
       oldQuantityConditionStructs
    end

    
    % Private constructor
    methods (Access = private)
        function obj = ConditionUpdater
            
        end
    end
    
    methods
        function addQuantityCondition(obj, c, s)
            obj.quantityConditions(end+1) = c;
            if isempty(obj.oldQuantityConditionStructs)
                obj.oldQuantityConditionStructs = s;
            else
                obj.oldQuantityConditionStructs(end+1) = s; 
            end
        end
        
        function updateAllQuantityConditions(obj, varargin)
 %          imo = ImagineObject.getInstance();
           for i = 1:length(obj.quantityConditions)
               cond = obj.quantityConditions(i);
               s = obj.oldQuantityConditionStructs(i);
               
%                cond.quantityType = 'Output';
%                cond.eventName = QuantityBasedCondition.nullEventName;
%                cond.comparator = '>=';
%                cond.rate = Rate(0, Unit, Unit);

                % For each quantity, it would be nice if we could find the
                % quantities that are appropriate to it.
                % We could go through each crop and each event and each
                % condition of the trigger in these events, until we find
                % where they match. And then we would have the quantities
                % from the growth models. Because we would have found the
                % crops.
            
                % That's going to take forever to write and it doesn't seem
                % like much of a problem right now - noone was using
                % QuantityBased conditions. So just give a message.
           end
            if length(obj.quantityConditions) >= 1
                msgbox('There are some quantity conditions that have been loaded from old versions. You need to run through the crops and regimes again, making sure that any Quantity Based conditions are set up correctly.');
            end
        end
        
    end
    
    methods (Static)
        function singleObj = getInstance()
            persistent localObj

            if isempty(localObj) || ~isvalid(localObj)                
                localObj = ConditionUpdater;                
            end
            singleObj = localObj;
        end
        
    end
    
end