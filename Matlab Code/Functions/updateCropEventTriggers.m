% When we open up a regime dialog, we load up the regime's cropEventTrigger
% struct. We then manipulate that structure throughout. The problem is that
% the crops' events could have changed since the last time we saved the
% regime.
% For example, we could have added or removed a financial event.
% This function saves the day by creating a new cropEventTriggers struct,
% then importing into it what it can from the previously saved regime.
function cets = updateCropEventTriggers(crops, cetsIn)

    cropMgr = CropManager.getInstance();
    
    for i = 1:length(crops)
        cropName = crops{i};
        ces = cropMgr.getCropsEvents(cropName);
        
        % Get the index of cropName in the cetsIn
        ix1 = find(strcmp(cropName, {cetsIn.cropName}), 1, 'first'); 
        
        if isempty(ix1)
           % Then we haven't got any events for this crop. Maybe its a new crop to the regime.
           % Create a place for it in cetsIn.
           cetsIn(end + 1) = struct('cropName', cropName, 'eventTriggers', RegimeEventTrigger.empty(1, 0));
        end
        
        etsIn = cetsIn(ix1).eventTriggers;
        
        % For each crop, we want to go through that crop's events and make
        % sure that the events are represented in the regime's
        % cropEventTriggers struct.
        for j = 1:length(ces)
            
            eventName = ces(j).name;

            retNew = RegimeEventTrigger(ces(j).name, ces(j).trigger, ces(j).status.regimeRedefinable); %#ok<AGROW>
      
            
            % get the index of the event in etsIn if it exists.
            if isempty(etsIn)
                ix2 = [];
            else
                ix2 = find(strcmp(eventName , {etsIn.eventName}), 1, 'first');
            end        
            
            
            if isempty(ix2)
               % Then the event is unknown in the regime's
               % cropEventTriggers struct. Just as well we checked!
               % Add it in.
               etsIn(end+1) = retNew;
            else
               % Otherwise we should work out which one should be kept.
               % We keep the existing one if the crop says that it's to be
               % defferred to regime, or if it's redefinable.
               
               %if ces(j).status.regimeRedefinable || ces(j).status.deferredToRegime
               if ces(j).status.deferredToRegime
                    % Then keep the existing one.
               elseif etsIn(ix2).regimeRedefined 
                    % If it's been redefined, we want to keep the
                    % redefinedTrigger, but update the reverted trigger.
                    % We'll swap etsIn(ix2) back to not being redefined so
                    % we can set the privateTrigger, not the
                    % redefinedTrigger. This is a bit awkward I guess but
                    % it will work.
                    etsIn(ix2).regimeRedefined = false;
                    etsIn(ix2).trigger = ces(j).trigger;
                    etsIn(ix2).regimeRedefined = true;
               else
                   % Otherwise we use the new one from the crop.
                   etsIn(ix2) = retNew;
               end
               % Note - this part seems to be working nicely.
                
            end
            
        end

        % Save the updated event triggers into the struct.
        cetsIn(ix1).eventTriggers = etsIn;
        
    end
    
    cets = cetsIn;
end