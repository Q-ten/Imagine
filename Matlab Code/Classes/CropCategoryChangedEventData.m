classdef CropCategoryChangedEventData < event.EventData
   
    properties
                   
        % previousName only relevant for editted or removed. If new this
        % will be empty
        previousName
        
        % newName only relevant for editted and new. If removed this will be
        % empty.
        newName
                
        previousCategory
        
        newCategory
        
    end
    
    methods
       
        function evtData = CropCategoryChangedEventData(previousName, newName, previousCategory, newCategory)
            evtData.previousName = previousName;
            evtData.newName = newName;
            evtData.previousCategory = previousCategory;
            evtData.newCategory = newCategory;
        end
         
    end
    
end