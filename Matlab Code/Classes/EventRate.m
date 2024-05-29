% A simple data structure class to store the potential products and outputs
% that could be produced by an event.
classdef EventRate
    
   properties
        eventName
        productRates
        outputRates
   end
        
   methods 
       
       function obj = EventRate(eventName, productRates, outputRates)
          obj.eventName = eventName;
          obj.productRates = productRates;
          obj.outputRates = outputRates;
       end
       
       function obj = set.eventName(obj, name)
            if isempty(name)
                obj.eventName = '';
                return
            end
           if ischar(name)
               obj.eventName = name;
           else
               warning('EventRate: Tried to set non-string name as eventName.')
           end
       end
       
        function obj = set.productRates(obj, rates)
            if isempty(rates)
                obj.productRates = Rate.empty(1, 0);
                return
            end
            if isa(rates, 'Rate')
               obj.productRates = rates;
            else
               warning('EventRate: Tried to set non-Rate as productRates.')
            end
        end
        
        function obj = set.outputRates(obj, rates)
            if isempty(rates)
                obj.outputRates = Rate.empty(1, 0);
                return
            end
            if isa(rates, 'Rate')
               obj.outputRates = rates;
            else
               warning('EventRate: Tried to set non-Rate as outputRates.')
            end
        end
   end
end