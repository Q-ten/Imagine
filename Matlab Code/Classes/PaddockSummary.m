classdef PaddockSummary
    %PaddockSummary Provides information on the paddock in a particular
    %year.
    %   Combines information from different regimes into the data needed to
    %   work out what is going on in the paddock in the given year.
    
    properties
        
        year = 0;
        
        primaryRegimeCategory = '';
        primaryRegimeLabel = '';
        primaryCropName = '';
        companionCropName = ''; 
                
        secondaryRegimeCategory = '';
        secondaryRegimeLabel = '';
        secondaryCropName = '';
        
        paddockLayout = PaddockLayout.empty(0);
        
    end
    
    methods
        
        
        
    end
    
end

