% The Never Condition defines a set of points in time in a sim
% and the condition is true if the sim is at one of those points.

classdef NeverCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType 
       figureName
       handlesField
   end
   
   methods
      
       function type = get.conditionType(obj)
          type = 'Never'; 
       end
                     
       function fn = get.figureName(obj)
          fn = 'conditionPanel_Never.fig'; 
       end
       
       function fn = get.handlesField(obj)
          fn = 'NeverHandles'; 
       end
       
       function obj = NeverCondition(shorthand)                     
              obj = obj@ImagineCondition(shorthand);          
       end
       
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end
       
       function lh = getLonghand(obj)
           lh = 'False';           
       end
       
       % Loads a set of controls into the panel and returns the handles to
       % them as subHandles.
       function loadCondition(obj, panel)          
           % Nothing to do for Never condition.
       end
       
       % Uses the controls in subHandles to extract the parameters that
       % define this condition.
       function saveCondition(obj, panel)
           % Nothing to do for Never condition.           
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
            % Very simple for the Never condition.
            TF = false;
       end
                   
       function setupFromOldStructure(obj, s)       
       end
   end
    
end