%
% NCZOptimisedParameters is a struct class containing parameters to model
% the NCZ for a particular crop. To optimise the NCZ we need to know the
% yield, price and costs of the crop. But the width of the NCZ must be
% known before seeding so we need to estimate the yield based on
% pre-seeding rainfall and the long-term average. That's what is set up
% here.
% The class also has a function to check if it is valid.
% Perhaps it should also know about the editor dialog and be able to open it statically.
classdef NCZOptimisedParameters
   
    properties
        
        % user to specify the number of months to include in the pre
        % seeding rainfall.
        preSeedingRainfallMonths
        
        % the parameters of the polynomial to describe the yield to pre
        % seeding rainfall curve. yield = a.x^2 + b.x + c where x is PSR.
        polyA
        polyB
        polyC
        
        % Predictive capacity of the polynomial to get yield. How much
        % depends on the PSR?
        % Should be a percentage so between 0 and 1.
        polynomialPredictiveCapacity
        
        % The long term average yield of the crop.
        longTermAverageYield        
        
        % The long term average annual costs for this crop (includes overheads).
        longTermAverageCosts
        
        % The actual predicted yield for the crop will be based partly on
        % the PSR yield curve and partly on the long term average. How much
        % depends on the polynomialPredictiveCapacity.
        
    end
    
    methods (Static = true)
        function obj = loadobj(inobj)
           if ~isfield(inobj, 'longTermAverageCosts')
            inobj.longTermAverageCosts = 200;
           end           
           obj = inobj;
        end
    end
    
    methods
    
        function obj = NCZOptimisedParameters()
            obj.preSeedingRainfallMonths = 4;
            obj.polyA = 0;
            obj.polyB = 0;
            obj.polyC = 0;            
            obj.polynomialPredictiveCapacity = 0.6;
            obj.longTermAverageYield = 2;
            obj.longTermAverageCosts = 200;
        end
        
        
        % returns true of the NCZOptimisedParameters object is valid.
        function TF = isValid(obj)
            
            TF = true;
            if isempty(obj)
                TF = false;
                return;
            end
            if ~isnumeric(obj.preSeedingRainfallMonths)
                TF = false;
                return;
            end
            if ~isnumeric(obj.polyA)
                TF = false;
                return;
            end
            if ~isnumeric(obj.polyB)
                TF = false;
                return;
            end
            if ~isnumeric(obj.polyC)
                TF = false;
                return;
            end
            if ~isnumeric(obj.polynomialPredictiveCapacity)
                TF = false;
                return;
            end
            if ~isnumeric(obj.longTermAverageYield)
                TF = false;
                return;
            end
            
            if ~(obj.preSeedingRainfallMonths >= 1 && obj.preSeedingRainfallMonths <= 12)
                TF = false;
                return
            end
            if ~(obj.polynomialPredictiveCapacity >= 0 && obj.polynomialPredictiveCapacity <= 1)
                TF = false;
                return
            end
            if ~(obj.longTermAverageYield >= 0)
                TF = false;
                return
            end
                        
        end
        
    end
    
end