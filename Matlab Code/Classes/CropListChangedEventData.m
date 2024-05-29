classdef CropListChangedEventData < event.EventData
   
    properties
                   
        % The resulting list of cropNames. 
        cropList
       
        % previousName only relevant for editted or removed. If new this
        % will be empty
        previousName
        
        % newName only relevant for editted and new. If removed this will be
        % empty.
        newName
                
       % Regimes to remove
        regimesToRemove = {};
        
        % Force regime removal
        forceRegimeRemoval = false;

    end
    
    methods
       
        function evtData = CropListChangedEventData(cropList, previousName, newName)
            evtData.cropList = cropList;
            evtData.previousName = previousName;
            evtData.newName = newName;
        end
         
    end
    
end