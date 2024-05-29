% This class contains the 6 parameters that govern how and where a trigger
% may be set for an event. The class takes care of restricting access to
% parameters if the Locked version is set to true.

classdef ImagineEventStatus
   
    properties (Dependent)
        deferredToRegime       
        regimeRedefinable        
        regimeRedefined                
    end
    
    properties (SetAccess = private)
        origin
        cropDefinitionLocked
        deferredToRegimeLocked
        regimeRedefinableLocked
    end
    
    properties (Access = private)
        privateDeferredToRegime
        privateRegimeRedefinable
        privateRegimeRedefined
    end
    
    methods
       
        % Constructor sets up the private properties. When it is created,
        % regimeRedefined will be false.
        function ies = ImagineEventStatus(origin, cropDefinitionLocked, deferredToRegime, deferredToRegimeLocked, regimeRedefinable, regimeRedefinableLocked)
           if nargin == 6
                if ischar(origin)
                    ies.origin = origin;
                else
                    error('First argument to ImagineEventStatus must be a string.');
                end
                
                ies.cropDefinitionLocked = logical(cropDefinitionLocked);
                ies.privateDeferredToRegime = logical(deferredToRegime);
                ies.deferredToRegimeLocked = logical(deferredToRegimeLocked);
                ies.privateRegimeRedefinable = logical(regimeRedefinable);
                ies.regimeRedefinableLocked = logical(regimeRedefinableLocked);
                ies.privateRegimeRedefined = false;
           else
              error('Must pass 6 arguments to the ImagineEventStatus constructor.'); 
           end
        end
        
        % Check that we are allowed to change the deferredToRegime setting
        % before we make the change.
        function ies = set.deferredToRegime(ies, value)
           if ~isnumeric(value) && ~islogical(value)
               error('Cannot set deferredToRegime to non-numeric value.');
           end
            
           if ies.deferredToRegimeLocked
                disp('Attempt made to set locked deferredToRegime status in event.');
           else
               ies.privateDeferredToRegime = value;
           end
        end
        
        function value = get.deferredToRegime(ies)
           value = ies.privateDeferredToRegime; 
        end
        
        
        % Check that we are allowed to change whether an eventt is
        % regimeRedefinable before we set it.
        function ies = set.regimeRedefinable(ies, value)
            if ~isnumeric(value) && ~islogical(value)
                error('Cannot set regimeRedefinable to non-numeric value.');
            end
            
           if ies.regimeRedefinableLocked
                disp('Attempt made to set locked regimeRedefinable status in event.');
           else
               ies.privateRegimeRedefinable = value;
           end
        end
        
        function value = get.regimeRedefinable(ies)
           value = ies.privateRegimeRedefinable; 
        end
        
        
        % If we want to set regimeRedefined to true, we must have that it's
        % regimeRedefinable. We can always set it to false though.
        function ies = set.regimeRedefined(ies, value)
            if ~isnumeric(value) && ~islogical(value)
                error('Cannot set regimeRedefined to non-numeric value.');
            end

            if value 
                if ies.privateRegimeRedefinable
                    ies.privateRegimeRedefined = value;
                else
                   disp('Tried to set event status to regimeRedefined, but it is not regime redefinable.'); 
                end
           else
                ies.privateRegimeRedefined = value;
           end
        end
        
        function value = get.regimeRedefined(ies)
           value = ies.privateRegimeRedefined; 
        end
        
    end % methods end
    
end