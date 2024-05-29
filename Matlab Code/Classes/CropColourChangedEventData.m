classdef CropColourChangedEventData < event.EventData
   
    properties
                   
        % previousName only relevant for editted or removed. If new this
        % will be empty
        previousName
        
        % newName only relevant for editted and new. If removed this will be
        % empty.
        newName
                
        previousColour
        
        newColour
        
    end
    
    methods
       
        function evtData = CropColourChangedEventData(previousName, newName, previousColour, newColour)
            evtData.previousName = previousName;
            evtData.newName = newName;
            evtData.previousColour = previousColour;
            evtData.newColour = newColour;
        end
         
    end
    
end