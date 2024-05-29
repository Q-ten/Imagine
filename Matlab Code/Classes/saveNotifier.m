% This is one half of a hack designed to let a trend dialog notify its 
% parent dialog that the trend has been saved. Its so the parent can update
% its list of priceModels to reflect the validity of the newly saved trend.
%
% It's a hack because we should probably make stepData and trendData handle
% structs with proper properties.
classdef saveNotifier < handle
    
    events
       trendWasSaved 
    end
    
    methods
        function sendSaveNotification(obj)
            disp('Sending');
            notify(obj, 'trendWasSaved');
            disp('Sent');
        end
    end
end