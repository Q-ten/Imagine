% This class represents half of a time-saving hack to get a message from
% the trendDialog to the products and costs dialogs of the cropWizard.
% It's needed simply to update the list of priceModels to reflect the
% validity of their trends.
%
% It's a hack because we should probably make stepData and trendData handle
% structs with proper properties.
classdef saveListener < handle
    
    properties
        figHandle
        listBoxHandle
        lh
    end
    
    methods
        function obj = saveListener(figHandle, listBoxHandle, notifier)
            obj.figHandle = figHandle;
            obj.listBoxHandle = listBoxHandle;
            if nargin == 3
                obj = setNotifyingObject(obj, notifier);
            end
        end
        
        function obj = setNotifyingObject(obj, notifier)
            obj.lh = addlistener(notifier, 'trendWasSaved', @(src,evnt)handleSaveEvent(obj,src,evnt)); 
        end
        
        % Refresh the names of the list.
        function handleSaveEvent(obj, src, evt)            
            handles = guidata(obj.figHandle);
            handles.stepData.priceModels(handles.stepData.priceModelIndex).trend = handles.trendData.trend;
            set(obj.listBoxHandle, 'String', {handles.stepData.priceModels.markedUpName});
            guidata(obj.figHandle, handles);
        end
        
    end
    
end