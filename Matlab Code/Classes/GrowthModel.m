classdef GrowthModel < handle
    
    % GrowthModel is an Abstract class which will be an interface for the
    % GrowthModels that are used in Imagine.
    % It will be responsible for modelling the growth of a crop, and so
    % will have it's state, a state propagation function and output
    % functions. 
    % The GrowthModel will also need to respond to Events (ImagineEvents,
    % not MATLAB object events. These events may or may not alter the state
    % and may or may not produce saleable products.
    % A GrowthModel will also need to inform other objects what 
    % ImagineEvents and Products are supported. So while the productNames
    % will be and imagineEventNames will be protected, we need to let other
    % objects get them.
    
    properties (SetAccess = protected)
        
        % An instance of a concrete subclass of the GrowthModelDelegate
        % class. The delegate actually contains all the information about
        % the growth model. This class merely acts as a standard wrapper so
        % that we can have arrays of GrowthModels, even while the models
        % may be very different.
        delegate
        
        % A string with the name of the class of the GrowthModel's delegate. 
        delegateClass
        
    end
    
    properties (Constant)
       transitionFunctionPrefix = 'transitionFunction_'; 
    end
    
    properties (Dependent)

        % These are dependent properties because they will end up coming
        % from the delegate. They have the same comments in the Abstract
        % GrowthModelDelegate class.
        
        % A String that gives the name of this growth model. It will be set
        % to the delegate's name, so is dependent.
        name
                
        % A list of ImagineEvents, which will come from the delegate.
        % It's comprised of the initial, regular and destruction events
        % that are stored in the growthModelDelegate.
        growthModelEvents
        growthModelInitialEvents
        growthModelRegularEvents
        growthModelDestructionEvents
        growthModelFinancialEvents
        
                
        % A list of strings with the names of ImagineEvents that have
        % transition functions defined in the delegate. That is, the
        % transitionFunction(eventName, ...) will have defined behaviour
        % for the given eventName.
        supportedImagineEvents
        
        % A list of strings with the names of the CropCategories that this
        % GrowthModel will be appropriate to model.
        supportedCategories
        
        % productPriceModels - a PriceModel for each product that can be
        % produced by this growthModel. The Units of the products are found
        % as the denominator of the PriceModels. 
        % When a product is produced, the Amount's unit can be used to work
        % out which price to use. It will match the denominator unit. (The
        % numerator will be in currency, probably $).
        productPriceModels
        
        % productUnits - matches the productPriceModels denominatorUnits.
        productUnits
        
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
        % So when a rate is just 500 somethings per 1, that's just 500
        % somethings. This will be appropriate if we want to make 'rainfall
        % that's fallen in the last 3 months' an output. It's not 'per'
        % anything. It just is.
        growthModelOutputRates
        
       
        % This will be a string cell array with descriptions of each
        % element of the state.
        % Comes from the delegate.
%?
        stateDescription
        
        % Number of elements in the state.
        % Comes from the delegate.
% ?
        stateSize

    end
    
    methods
        % Concrete subclasses of GrowthModelDelegate should register
        % themselves in this constructor as a simple way of creating a
        % GrowthModel with the appropriate delgate.
        function gm = GrowthModel(gmName)
            if nargin >= 1
               if ischar(gmName)
                    
                   switch gmName
                       
                       case 'Rainfall Based'
                           gm.delegate = RainfallBasedGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);

                       case 'Annual'
                           gm.delegate = AnnualGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);
                           
                       case 'AB-Gompertz'
                           gm.delegate = ABGompertzGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);  
                           
                       case 'Fixed Yield'
                           gm.delegate = FixedYieldGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);  
                       
                       case 'Simple Pasture'
                           gm.delegate = SimplePastureGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);  
                           
                       case 'Imported GrassGro Data Model'
                           gm.delegate = GrassGroGrowthModelDelegate();
                           gm.delegateClass = class(gm.delegate);  

                       otherwise
                           error('GrowthModel name provided is not supported in constructor.');
                   end
                   
               end
            end         
        end
    end
    
    methods (Static)
        % checks that the growthModel is a ValidGrowthModel. It needn't
        % have valid parameters to be a valid object.
        function valid = isValid(gm)
            valid = isa(gm, 'GrowthModel') && ~isempty(gm);
            if valid && ~isempty(gm.delegate)
                valid = GrowthModelDelegate.isValid(gm.delegate);
            end
        end
        
        % checks that the parameters are ok. 
        function ready = isReady(gm)
            ready = GrowthModel.isValid(gm);
            if ready
               ready = GrowthModelDelegate.isReady(gm.delegate); 
            end
        end
        
        % Need to convert old RainfallBasedGrowthModels to
        % AnnualGrowthModels.
        function obj = loadobj(obj)

            if strcmp(obj.delegateClass, 'RainfallBasedGrowthModelDelegate')
                obj.delegateClass = 'AnnualGrowthModelDelegate';
                pPMs = obj.productPriceModels;
                gmEs = obj.growthModelEvents;
                obj.delegate = AnnualGrowthModelDelegate.convertFromRainfallBasedGMDelegate(obj.delegate);
                obj.productPriceModels = pPMs;
                obj.growthModelEvents = gmEs;
            end
        end
    end
    
    methods
       % These methods are simply the get and set methods for the delegate variables
       % that wrap to the main GrowthModel class.
       
       function name = get.name(gm)
           disp(gm.delegate)
           if ~isempty(gm.delegate)
               name = gm.delegate.modelName; 
               disp(name)
           else
               name = '';
           end
           disp(name)
       end       
       function sIEs = get.supportedImagineEvents(gm)
           if ~isempty(gm.delegate)
               sIEs = gm.delegate.supportedImagineEvents;
           else
               sIEs = {};
           end     
       end
       
       function sCs = get.supportedCategories(gm)        
           if ~isempty(gm.delegate)
               sCs = gm.delegate.supportedCategories;    
           else
               sCs = {};
           end              
       end
           
       function stSize = get.stateSize(gm)
           if ~isempty(gm.delegate)
               stSize = gm.delegate.stateSize;
           else
               stSize = 0;
           end
       end
       
       function stDes = get.stateDescription(gm)
           if ~isempty(gm.delegate)
               stDes = gm.delegate.stateDescription;
           else
               stDes = {};
           end
       end
       
       function gmEvts = get.growthModelInitialEvents(gm)
           if ~isempty(gm.delegate)
               gmEvts = gm.delegate.growthModelInitialEvents;
           else
               gmEvts = ImagineEvent.empty(1, 0);
           end
       end
       
       function gmEvts = get.growthModelRegularEvents(gm)
           if ~isempty(gm.delegate)
               gmEvts = gm.delegate.growthModelRegularEvents;
           else
               gmEvts = ImagineEvent.empty(1, 0);
           end
       end
       
       function gmEvts = get.growthModelDestructionEvents(gm)
           if ~isempty(gm.delegate)
               gmEvts = gm.delegate.growthModelDestructionEvents;
           else
               gmEvts = ImagineEvent.empty(1, 0);
           end
       end
       
       
       function gmEvts = get.growthModelFinancialEvents(gm)
           if ~isempty(gm.delegate)
               gmEvts = gm.delegate.growthModelFinancialEvents;
           else
               gmEvts = ImagineEvent.empty(1, 0);
           end
       end
       
       
       function gmEvts = get.growthModelEvents(gm)
           if ~isempty(gm.delegate)
               gmEvts = [gm.delegate.growthModelInitialEvents, ...
                         gm.delegate.growthModelRegularEvents, ...
                         gm.delegate.growthModelDestructionEvents, ...
                         gm.delegate.growthModelFinancialEvents];
           else
               gmEvts = ImagineEvent.empty(1, 0);
           end
       end
       
       function set.growthModelEvents(gm, evts)
                  
           % If we set the long growthModelEvents list, we need to find the
           % corresonding events in the sub lists and set them.
           for i = 1:length(evts)
              
               ix = find(strcmp(evts(i).name, {gm.delegate.growthModelInitialEvents.name}), 1, 'first');
               if ~isempty(ix)
                   gm.delegate.growthModelInitialEvents(ix) = evts(i);
               else
                   ix = find(strcmp(evts(i).name, {gm.delegate.growthModelRegularEvents.name}), 1, 'first');
                   if ~isempty(ix)
                        gm.delegate.growthModelRegularEvents(ix) = evts(i);
                   else
                        ix = find(strcmp(evts(i).name, {gm.delegate.growthModelDestructionEvents.name}), 1, 'first');
                        if ~isempty(ix)
                            gm.delegate.growthModelDestructionEvents(ix) = evts(i);
                        end
                   end
               end
               
           end
           
       end
           
       function pPMs = get.productPriceModels(gm)
          if ~isempty(gm.delegate)
              pPMs = gm.delegate.productPriceModels;
          else
              pPMs = PriceModel.empty(1, 0);
          end
       end
       
       function set.productPriceModels(gm, pPMs)
          if ~isempty(gm.delegate)
               gm.delegate.productPriceModels = pPMs;
          end
       end
       
       function pUs = get.productUnits(gm)
          pUs = [gm.productPriceModels.denominatorUnit]; 
       end

       function gMOUs = get.growthModelOutputUnits(gm)
          if ~isempty(gm.delegate)
              gMOUs = gm.delegate.growthModelOutputUnits;
          else
              gMOUs = Unit.empty(1, 0);
          end
       end
       
       function gMORs = get.growthModelOutputRates(gm)
          if ~isempty(gm.delegate)
              gMORs = gm.delegate.growthModelOutputRates;
          else
              gMORs = Rate.empty(1, 0);
          end
       end       
       
    end
    
    methods
           
       % These concrete methods simply wrap the methods of the delegate.
        
        function [newState, productRates] = propagateState(gm, plantedCrop, sim)
            % Propagates state over one month.
            [newState, productRates] = gm.delegate.propagateState(plantedCrop, sim);
        end
        
        function gm = setupGrowthModel(gm, cropName)
            % This should be implemented as a GUI that asks the user for input
            % that determines the growthModel's parameters.
            gm.delegate = gm.delegate.setupGrowthModel(cropName);
        end
        
        function renderGrowthModel(gm, ax)
            % This method should render a summary of the growth model on the
            % axes ax. This will be called within the cropWizard and should be
            % a fixed size.
            gm.delegate.renderGrowthModel(ax);
        end

        function [productAmounts, eventOutputs] = eventTransition(gm, eventName, plantedCrop, sim)
            % Wraps to the delegate's method that deals with an event.
            % transition functions in the delegate should be of the form 
            % transitionFunction_EVENT_NAME(gmdel, plantedCrop, sim) 
            % where eventName = 'EVENT NAME'
            % 
            % The transition functions update (transition) the state inside
            % plantedCrop and return a list of Amounts, which are the
            % Amounts of product harvested in the event.
            eventName = strrep(eventName, ' ', '_');
            [productAmounts, eventOutputs] = gm.delegate.([gm.transitionFunctionPrefix, eventName])(plantedCrop, sim);    
        end
        
        function outputsColumn = calculateOutputs(gm, state)
            % Wraps to the delegate's method that calculates the outputs
            % based on a PlantedCrop's state.
            outputsColumn = gm.delegate.calculateOutputs(state);
        end
        
        function cropNameHasChanged(gm, previousName, newName)
            gm.delegate.cropNameHasChanged(previousName, newName);
        end
    end
    
    methods
       
        function [productRates, outputRates] = getProductAndOutputRatesForEvent(gm, eventName)
            productRates = Rate.empty(1, 0);
            outputRates = Rate.empty(1, 0);
            try
                [productRates, outputRates] = gm.delegate.([gm.transitionFunctionPrefix, underscore(eventName)])([], []);
            catch ME %#ok<NASGU>
                return
            end
        end
        
        function productRates = getPropagationProductRates(gm)
            [~, productRates] = gm.delegate.propagateState([], []);
        end
    end
          
end
