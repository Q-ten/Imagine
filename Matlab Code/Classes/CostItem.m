% A costItem contains the data needed to record a cost that's been
% incurred.
%
% The total cost will be for some amount of something, at some price.
% So for example, the cost of planting a crop is at $X, per Ha. The amount
% is the number of Ha, the price is $X per Ha.

classdef CostItem < handle
    
    properties
       
        
        % A string with the name of the cost - probably an event name
        % In contrast to Products, we need a name of the cost. For example,
        % we have to call the planting cost 'planting' rather than relying
        % on the quantity and price (Ha and $ / Ha
        costName
        
        % quantity - An Amount. It's the quantity that the cost price should be applied to.
        % Eg Hectares or Trees 
        quantity
        
        % A price rate, usually in dollars, that will be applied to the quantity.
        price
        
    end
    
    properties (Dependent)
        cost
    end
    
    % Constructor
    methods
        
        function obj = CostItem(eventName, plantedCrop, sim, eventOutputAmounts, productAmounts)
           
            if nargin == 0
                return
            elseif nargin == 5
                obj.costName = eventName;
                obj.price = sim.getCostPrice(plantedCrop.cropObject.name, eventName);
                % The amount we need for the quantity to multiply the price
                % by might be an eventOutput. Check these first and then
                % check the plantedCrop. The eventOutputs won't show up in
                % plantedCrop yet as they've not been added when the
                % costItem is made.
                gotAmount = false;
                for i = 1:length(eventOutputAmounts)
                    eoa = eventOutputAmounts(i);
                    if(eoa.unit == obj.price.denominatorUnit)
                        obj.quantity = eoa;
                        gotAmount = true;
                        break;
                    end
                end
                % If the amount is not one of the event outputs, maybe it's
                % a product.
                if ~gotAmount
                    for i = 1:length(productAmounts)
                        pa = productAmounts(i);
                        if(pa.unit == obj.price.denominatorUnit)
                            obj.quantity = pa;
                            gotAmount = true;
                            break;
                        end
                    end                                        
                end                
                % If not an event output or a product, let's try to get the
                % amount from the crop (and by inference if that fails,
                % from the crop's regime.
                if ~gotAmount
                    obj.quantity = plantedCrop.getAmount(obj.price.denominatorUnit);                                   
                    if ~isempty(obj.quantity)
                       gotAmount = true; 
                    end
                end
                % If still not found, try previous months production. Maybe
                % we're referring to a product amount that was produced a
                % couple of months ago.
                if ~gotAmount
                    recentProduction = plantedCrop.getMostRecentProduction(obj.price.denominatorUnit.speciesName);
                    if ~isempty(recentProduction)
                        obj.quantity = recentProduction;
                    end
                end
                
                if isempty(obj.quantity)
                    error('CostItem creation failed because the quantity to match the price cannot be found.')
                end                                
            else
                error('CostItem class required 0 or 5 arguments to the Constructor.'); 
            end
        end
        
    end
    
    % Get methods for dependent properties
    methods 
        
        function c = get.cost(obj)
            
            % Multiply the quantity Amount by the price Rate.
            % Amount has times defined, so it's simple!
            c = obj.quantity * obj.price;            
            
        end
    end
    
end