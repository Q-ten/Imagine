% This class is created solely as a way to transition from the old
% ImagineConditions to the new ones. ImagineConditions are now Abstract, so
% we can't have an array of them, so the array that used to be in Trigger
% gets truncated to one. In ImagineCondition loadobj, we'll turn them all
% into these ones, so that the loadobj method of Trigger can then turn them
% into the new versions. Without doing this it may be impossible.
classdef OldImagineCondition < ImagineCondition
   
    properties
        oldData
    end
    
    methods
        function cond = OldImagineCondition(s)
            cond = cond@ImagineCondition('');
            cond.oldData = s;
        end
    end
    
    properties (Dependent)
       conditionType           
       
       % The name of the figure that contains the controls that will be
       % used to set up the condition
       figureName
       
       % The name to give the field in handles that will contain the
       % controls loaded from the figure.
       handlesField     
    end

    methods
        
      function type = get.conditionType(obj)
          type = 'Old Imagine Condition'; 
       end
                     
       function fn = get.figureName(obj)
          fn = ''; 
       end
       
       function fn = get.handlesField(obj)
          fn = ''; 
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