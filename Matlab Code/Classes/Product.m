% A product contains the data needed to record a product that's been
% produced as a result of an event taking place - probably a harvest event.
%
% There will be a quantity of product, and there will be the price it was
% sold for and the income generated.
classdef Product < handle
    
    properties
       
        % A string with the name of the product
        % Do we really need this? Isn't it in quantity under species name?
%        productName
        
        % quantity - An Amount, the quantity of stuff produced that the price should be applied to.
        % The quantity here is a little different to the quantity in
        % CostItem because the units of this quantity really specify what
        % the product is and where the income comes from. ProductName is
        % not needed as the quantity defines the Unit of what is produced.
        quantity
        
        % A price Rate, usually in dollars, that will be applied to the quantity.
        price
        
    end
    
    properties (Dependent)
        income
    end
    
    % Constructor
    methods
       
        function obj = Product(cropName, amount, sim)
           
            if nargin == 0
                return
            elseif nargin == 3
                
                obj.quantity = amount;
                obj.price = sim.getProductPrice(cropName, amount.unit);
                
            else
               error('Product class requires 0 or 3 arguments to the constructor.'); 
            end
            
        end
        
    end
    
    % Get methods
    methods 
        function in = get.income(obj)
            
            % Multiply the quantity Amount by the price Rate.
            % Amount has times defined, so it's simple!
            in = obj.quantity * obj.price;            
            
        end
    end
    
end