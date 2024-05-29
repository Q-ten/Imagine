classdef CropNameChangedEventData < event.EventData
   
    properties
                   
        % The resulting list of cropNames. 
        cropList
       
        % previousName only relevant for editted or removed. If new this
        % will be empty
        previousName
        
        % newName only relevant for editted and new. If removed this will be
        % empty.
        newName
               
        
    end
    
    methods
       
        function evtData = CropNameChangedEventData(previousName, newName)
            evtData.previousName = previousName;
            evtData.newName = newName;
        end
         
    end
    
end