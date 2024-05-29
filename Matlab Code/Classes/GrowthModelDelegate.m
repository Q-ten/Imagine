% This abstract class defines the properties and methods that a concrete
% subclass of should implement. The delegate for a GrowthModel must be a
% subclass of this class.
% 
% Furthermore, a concrete subclass should also include a number of state 
% transitionfunctions to be called when an event for the crop is triggered.
% 
% These functions will have a signature of the form 
% outputProducts = transitonFunction_EVENTNAME(gmDel, ...)
% where EVENTNAME happens to be the name of the event that is supported.
% 
% The function supportedImagineEvents should return a list of event names
% which are supported in this way.

classdef GrowthModelDelegate < handle
    
        
    properties (Access = protected)
        
        % The state does not appear in the GrowthModelDelegate. The
        % GrowthModelDelegate is an object that acts on the state. It is a
        % set of functions and the parameters required to execute those
        % functions. The state does not live here - it lives in the
        % PlantedCrop. However, the GrowthModelDelegate should have a very
        % good idea of what the state will be because it will keep acting
        % on the state. It will initialise it, propagate it, transition it
        % during events, produce products based on it, and calculate the
        % outputs from it. So while the GrowthModelDelegate does not
        % maintain the state itself, it will know all about it.
        %state
               
    end

    properties (Abstract)
        % The ImagineEvents for this growth model. This is where the triggers will be stored, 
        % and the cost PriceModel(s).
        % The functions are to be 'stored' in the growthModelDelegate
        % concrete class.
        % In the concrete class the events list will be broken up into
        % three sections - those that can initialise the crop (plant it),
        % those that update it or produce intermediate products (like
        % fertilising, spraying or coppicing) and those events that end the
        % crop like a harvesting event. Each of these sections can have
        % several events, although it's required that at least one
        % initial event and one destruction event are defined.
        growthModelInitialEvents
        growthModelRegularEvents
        growthModelDestructionEvents
        growthModelFinancialEvents
        
        
        % productPriceModels - a PriceModel for each product that can be
        % produced by this growthModel. The Units of the products are found
        % as the denominator of the PriceModels. 
        % When a product is produced, the Amount's unit can be used to work
        % out which price to use. It will match the denominator unit. (The
        % numerator will be in currency, probably $).
        productPriceModels
        
        % growthModelOutputUnits - a list of Units that provide list of the
        % types of outputs the growthModel provides when passed the state
        % of a PlantedCrop. This list should include the union of all the
        % coreCropOutputUnits provided by the cropCategorys that this
        % growthModel supports.
        growthModelOutputUnits
        
        % growthModelOutputRates - a list of 0 rates that provide the
        % rate units that come out of the calculateOuputs function.
        % The rates can be important if you need to know how the
        % denominator will come out.
        % There is a case where the denominator will be nothing or just
        % 'unit' when it doesn't make sense for the rate to be a rate, but
        % an amount. Eg, height of Wheat. Doesn't make sense to divide by
        % Hectares. Or even more starkly - colour of wheat. This is a
        % weird but possibly useful output, but would be silly for it to be a rate.
        growthModelOutputRates
    end
    
    properties(Abstract)
        % Name of the concrete implementation's model.
        modelName         
        
        % A list of strings with the names of the CropCategories that this
        % GrowthModel will be appropriate to model.
        supportedCategories
     
        % This will be a string cell array with descriptions of each
        % element of the state.
        % Comes from the delegate.
        stateDescription
    end
    
    properties (Constant, Hidden)
        % This is the leading section of the function names that handle
        % events.
        transitionFunctionPrefix = 'transitionFunction_'; 
    end
    
    properties (SetAccess = protected)

        % A list of strings with the names of ImagineEvents that have
        % transition functions defined in the delegate. That is, the
        % transitionFunction(eventName, ...) will have defined behaviour
        % for the given eventName.
        supportedImagineEvents = {};

        % Number of elements in the state.
        stateSize = 0;
    end
    
    methods(Abstract)
       
        valid = gmdIsValid(gmd)
        ready = gmdIsReady(gmd)
    
    end
    
    methods(Abstract)
    
        % These methods will need to be implemented in every concrete
        % subclass.
        [newState, productRates] = propagateState(gmd, plantedCrop, sim)
        
        gmd = setupGrowthModel(gmd, cropName)
        
        renderGrowthModel(gmd, ax)
        
        outputsColumn = calculateOutputs(gmd, state)
        
        % As well as these core methods, you need to implement methods for
        % each supported ImagineEvent of the form
        %
        % productAmounts = transitonFunction_EVENTNAME(gmDel, plantedCrop, sim)
        % where EVENTNAME happens to be the name of the event that is supported.
        %
        % productAmounts are actually Rates, like 20 tonnes per Ha, rather
        % than Amounts like 20 tonnes.
        
        cropNameHasChanged(gmd, previousName, newName)
    end

    methods(Static)
       
        function valid = isValid(gmd)
            if isa(gmd, 'GrowthModelDelegate')
                valid = gmd.gmdIsValid;
            else
                valid = false;
            end
        end
        
        
        function ready = isReady(gmd)
            if isa(gmd, 'GrowthModelDelegate')
                ready = gmd.gmdIsReady;
            else
                ready = false;
            end
        end
        
    end
   
    methods
        
%         % Constructor requires a reference to an existing GrowthModel in
%         % order to create the delegate.
%         % It will probably be appropriate to explicitly define a
%         % constructor in any subclass as well, which will reference this
%         % superclass method.
%         function gmDel = GrowthModelDelegate(gm)
%             if nargin > 0
%                 % Make sure that the passed argument is in fact a GrowthModel
%                 if isa(gm, 'GrowthModel')            
%                     gmDel.gm = gm;
%                 else
%                     error('Must pass the owning GrowthModel object as the first argument to the constructor of the GrowthModelDelegate.');
%                 end
%             end                
%         end % end GrowthModelDelegate constructor
        
        % Returns a list of the events that are supported by functions of
        % the correct signature in the concrete class.
        function sIEs = get.supportedImagineEvents(gmDel)
            
            if isempty(gmDel.supportedImagineEvents)
                
                gmDelMethods = methods(class(gmDel));
                Ix = strncmp(gmDel.transitionFunctionPrefix, gmDelMethods, length(gmDel.transitionFunctionPrefix));
                transFcns = gmDelMethods(Ix);
                for i = 1:length(transFcns)
                    fcn = transFcns{i};
                    fcn = fcn(length(gmDel.transitionFunctionPrefix) + 1: end);
                    fcn = strrep(fcn, '_', ' ');
                    transFcns{i} = fcn;
                end
                sIEs = transFcns;
            else
                sIEs = gmDel.supportedImagineEvents;
            end                
        end % end get.supportedImagineEvents
    
        % Returns the stateSize. Calculated once from the length of the
        % subclass's state vector, once it's been instantiated.
        function stateSize = get.stateSize(gmDel)
            stateSize = length(gmDel.stateDescription);
        end % end get.stateSize
                
        function eventOutputUnits = getEventOutputUnits(gmDel, eventName)
           [~, eos] = gmDel.(['transitionFunction_', underscore(eventName)])([], []);
           eventOutputUnits = [eos.unit];            
        end

        function eventOutputUnits = getOutputProductUnits(gmDel, eventName)
           [ops, ~] = gmDel.(['transitionFunction_', underscore(eventName)])([], []);
           eventOutputUnits = [ops.unit];            
        end

        
    end
    
    
    
    
    
   
end