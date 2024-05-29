% Changed by removing incomePriceModels and extraCostPriceModels.
% Haven't gone through the comments to see if it needs updating yet.

classdef ImagineEvent < handle
    
   % An ImagineEvent defines when in the lifecycle of a crop some event 
   % should occur, and what happens when it does.
   
   % An event will be associated with a crop of some category. The crop's
   % category will define the names of some 'core events'. The crop must
   % support these events to be a valid member of that category.
   
   % An event is 'triggered' when a set of conditions is satisfied. The
   % trigger forms part of the event.
   
   % When the event is triggered, the state of the crop may need to change,
   % some saleable products may be produced, and some costs may be
   % incurred.
   
   % Therefore an event should have the following:
   % A trigger
   % A transitionFunction, which takes in the state of a crop, and returns
   % the new state and any saleable products
   % A costItem model, which is used to generate costs for the event.
   
   % Now, some events will be defined for the crop regardless of the regime. For
   % example, we might want to say that 'Fertilizing' is an event for a
   % 'Fertilized Annual Crop' perhaps. The user may want to define the
   % conditions to be met for fertilizer to be applied. It may have
   % something to do with sufficient rainfall perhaps. So the user could
   % set up those conditions while in the crop wizard. Maybe we want to add
   % a 'spraying' cost, and set up the conditions for this event. These
   % will be set up in the crop wizard.
   
   % Other events are entirely based on the regime. For example, planting
   % and harvesting events. The regime is what defines when a crop is
   % planted. And usually it has conditons for the crop to be harvested
   % too.
   
   % So some events are crop-defined (independent of the regime they are
   % grown in) and other events cannot be defined in the crop, but must
   % wait until they are defined in the regime.
   
   % However, we need to maintain crops as seperate to regimes. So when we
   % come to the simulation, we need to combine the events defined in the
   % crops with the events defined for certain crops within a regime. The
   % precedence should go, if defined in a regime, use that definition, if
   % it is not in the regime, use the crop's definition. If it is not
   % defined at all, then we have an error.
  
   % When we generate the crop in the crop wizard, we will know what the
   % events are. There are the core events defined via the crop's category,
   % and there will be other user defined events to trigger costs. The
   % triggers need not be defined at this stage, but the existence of the
   % events is. So we will have full knowledge of all costs when we
   % complete the Crop object in the cropWiazrd.

   % We need to keep track of the different facets of an event:
   % It's origin: Is it a core event, defined in the crop's category, or is
   % it a user-defined event so that we incur costs?
   % Is it regime dependent or independent, or flexible? If flexible, it
   % means that it can be overwritten if desired in the regime, but must be defined in
   % the crop. If it is deffered to the regime in the cropWizard, then it
   % is a regime-dependent event.
   % Also, for core events, do we want to force the user to defer, or to
   % define in the cropWizard?
   
   % Clearly for user-defined events, the options are open in the
   % cropWizard. It can be deffered, defined, and defined with 'flexible'.
   
   % Do we want core events that are left up to the user to define? Some
   % core events like planting _must_ be regime based. But others like
   % Fertilize might be regime based but they might be crop based. And they
   % might be overwritten by the regime. So it's core, but it could be any
   % of the three types: regime dependent, regime independent, or flexible.
   % So it's deffered to regime (yes/no)
   % Deffered to regime locked (yes/no)
   % Overwriteable in regime (yes/no)
   % Overwriteable in regime locked (yes/no)
   
    % For user-defined events, there is no lock.
    % For core events, the locks are defined and the deffered and
    % overwritable are defined.
    
    % Now, a deffered, core event will be defined internally via a regime's
    % dialog. However, a regime will have a button 'Redefine Event
    % Triggers'. This will open a window where the user can view the
    % internal formulation of the regime's triggers. If the
    % regimeRedefinable tag is true, then the user can mess about in here
    % and change what they like. They should have a revert button as an
    % option to change it back to the regime's parameter-based trigger.
  
    % If the event is a user-defined event, then it is redefineable in the
    % regime trigger dialog if the check-box was checked in the wizardCrop
    % for 'Allow trigger to be redefined in regime'. If it wasn't checked,
    % this trigger wont be redefinable.
    
    % There are situations where these are dependent (such as deffered and
    % overwritable) They dont make sense together. Lets call overwritable
    % regime-definable. Obviously, if deffered is true then
    % regime-defineable is true. But if it's not deffered, then it may or
    % may not also be regime-definable.
    % If a trigger has been redefined, we don't want to replace it with
    % parameter based triggers, so we need to have a tag that checks this.
    % On revert, the regimeRedefined would be set back to false.
    
    % Ok. So we have these five properties:
    % origin
    % defferedToRegime
    % defferedToRegimeLocked
    % regimeRedefinable
    % regimeRedefinableLocked
    % regimeRedefined
    
    % The origin and the locked items are not changable. The other two
    % items are changeable depending on the lock items.
    
    % The category must define these for their core events. User-defined events
    % will have origin set to 'user-defined' and the locked elements set to
    % false.
    
    % A regime delegate's dialog will have controls that end up defining
    % what the triggers for deffered, core events are. 
    
    properties
       
        % name of the event
        name
        
        % status, and ImagineEventStatus object. Keeps track of how the
        % trigger can be defined.
        status
                       
        % costPriceModel, a PriceModel to work out the cost of the Event.
        % The PriceModel's Rate should have a denominatorUnit that can be
        % provided directly from the regime.
        costPriceModel = PriceModel.empty(1, 0);
        
        % extraCostPriceModels, an array of PriceModels detailing extra
        % costs. Not yet implemented. Intended to provide a way to define
        % things like $ / Tonne of Fertilizer, if we allow Tonnes of
        % Fertilizer used in a Fertilizing Event. The Fertilizing act
        % (event) will have its own costs for fuel etc...
        % These PriceModels will have Rates with denominatorUnits that will
        % reference an outputted Rate from the event. That will then need
        % to be combined with a Regime amount to work out the final amount.
        %extraCostPriceModels = PriceModel.empty(1,0);
               
    end
    
    properties(Dependent)

        % The trigger for the event. It is a set of Conditions.
        % We make it dependent because we may wish to use a 'redefined'
        % trigger. We keep both copies so that we can 'revert' from the
        % redefined trigger.
        % The trigger that is actually returned depends on the status. If
        % status says it's a redefined event, we return the redefined
        % trigger.
        trigger
        
    end
    
    properties (Access = private)
        privateTrigger
        privateRedefinedTrigger
    end
    
    
    methods
       
        % ImagineEvent constructor
        function ie = ImagineEvent(name, status, costPriceModel)
            if nargin >=2
                if ischar(name)
                    ie.name = name;
                else
                    error('First argument to ImagineEvent constructor must be a string.');
                end
                if isa(status, 'ImagineEventStatus')
                    ie.status = status;
                else
                    error('Second argument to ImagineEvent constructor must be an ImagineEventStatus object.'); 
                end
                if nargin >=3
                    ie.costPriceModel = costPriceModel;
                end
                ie.trigger = Trigger();
            else
                error('Must pass at least 2 arguments to the ImagineEvent constructor.');
            end
        end
        
        % Return the appropriate trigger depending on the status.
        function trig = get.trigger(obj)
            if obj.status.regimeRedefined
               % If the redefined trigger hasn't been set yet, use the
               % existing one.
               if isempty(obj.privateRedefinedTrigger)
                   trig = obj.privateTrigger;
               else
                   trig = obj.privateRedefinedTrigger;
               end
            else
               trig = obj.privateTrigger;
            end            
        end
   
        % Set the appropriate trigger depending on the status.
        function obj = set.trigger(obj, trig)
            if obj.status.regimeRedefined
               obj.privateRedefinedTrigger = trig; 
            else
               obj.privateTrigger = trig;
            end   
        end
        
    end
    

    
end