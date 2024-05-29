classdef RegimeEventTrigger
    %RegimeEventTrigger Provides a standard data structure to manage
    %triggers defined through the regime.
    %
    %   Detailed explanation goes here

    properties (Dependent)
       trigger 
       regimeRedefined
       name
    end
    
    properties
        eventName                
    end
    
    properties (Access = private)
        privateTrigger
        privateRedefinedTrigger
        regimeRedefinable        
        privateRegimeRedefined
    end
    
    methods
       
        function obj = RegimeEventTrigger(eventName, trigger, redefinable)
           if nargin < 3 
               error('RegimeEventTrigger constructor requires 3 arguments.');
           end
           obj.privateTrigger = trigger;
           obj.eventName = eventName;
           obj.regimeRedefinable = redefinable;
           obj.privateRegimeRedefined = false;
         end
        
        % Get one of the private triggers depending on the regimeRedefined
        % flag.
        function t = get.trigger(obj)
            if obj.regimeRedefined
                t = obj.privateRedefinedTrigger;
            else
                t = obj.privateTrigger;
            end
        end
        
        function obj = setPrivateTrigger(obj, privateTrigger)
           obj.privateTrigger = privateTrigger; 
        end
        
        function obj = setPrivateRedefinedTrigger(obj, privateRedefinedTrigger)
            obj.privateRedefinedTrigger = privateRedefinedTrigger;
        end
        
        function obj = set.regimeRedefined(obj, redefinedFlag)
            if obj.regimeRedefinable
               obj.privateRegimeRedefined = redefinedFlag; 
            end
        end
        
        function redefinedFlag = get.regimeRedefined(obj)
            redefinedFlag = obj.privateRegimeRedefined;
        end
        
        function name = get.name(obj)
            name = obj.eventName;
        end
        
        function obj = set.trigger(obj, t)
           if obj.regimeRedefined
              obj.privateRedefinedTrigger = t; 
           else
              obj.privateTrigger = t;               
           end
        end
                
        % status should come directly from the crop.
        % In the regime, we need to maintain, and overwrite the
        % regimeRedefined flag.
        function ev = convertToEvent(obj, status)
           
            % Want to set both private triggers.
            ev = ImagineEvent(obj.name, status);
            
            if status.regimeRedefinable
                ev.status.regimeRedefined = false;
                ev.trigger = obj.privateTrigger;
                ev.status.regimeRedefined = true;
                ev.trigger = obj.privateRedefinedTrigger;
                ev.status.regimeRedefined = obj.regimeRedefined;
            else
                ev.trigger = obj.trigger;
            end        
        end
       
        % Absorbs the event's data into this object.
        function obj = convertFromEvent(obj, ev)

            obj.eventName = ev.name;
            
            obj.regimeRedefinable = ev.status.regimeRedefinable;
            if obj.regimeRedefinable
                obj.regimeRedefined = ev.status.regimeRedefined;
                ev.status.regimeRedefined = false;
                obj.privateTrigger = ev.trigger;
                ev.status.regimeRedefined = true;
                obj.privateRedefinedTrigger = ev.trigger;   
                ev.status.regimeRedefined = obj.regimeRedefined; % Should not be necessary, but seems polite.
            else
                obj.privateTrigger = ev.trigger;
            end
            
        end
        
        function cropNameHasChanged(obj, previousName, newName)
            if ~isempty(obj.privateTrigger)
               obj.privateTrigger.cropNameHasChanged(previousName, newName);               
            end
            if ~isempty(obj.privateRedefinedTrigger)
               obj.privateRedefinedTrigger.cropNameHasChanged(previousName, newName);               
            end                
        end
    end
    
end

