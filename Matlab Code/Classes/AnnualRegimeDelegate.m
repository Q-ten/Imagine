% The AnnualRegimeDelegate is the concrete subclass of RegimeDelegate that
% provides the implementation of the 'Annual' regime category. It is a
% 'primary' regime - that is it covers the entire paddock, except when
% there is a secondary regime taking up space.
% 
% The Annual regime defines a rotation of crops, with planting and harvest
% months defined, with an optional companion crop planted and grazed between 
% the harvesting of the primary crop and the planting of the following
% year's crop.
% 
% The rotation is repeated until the end of the regime is reached. No
% companion crops are planted at the ends of the regime.
%
classdef AnnualRegimeDelegate < RegimeDelegate
    
    properties (SetAccess = protected)
               
        % Regime category. Something like 'Annual' or 'Belt'
        regimeCategory
        
        % Type of the regime. Should be 'primary', 'secondary', or
        % 'exclusive'
        type
    end
    
    properties
                
        % The name of the regime.
        regimeLabel
        
        % Start and final year for the regime.
        startYear
        finalYear
        
        % Colour for the timeline in the ImagineWindow.
        timelineColour
        
        % cropEventTriggers
        % This will be a struct array with (cropName, eventTriggers) the fields.
        % eventTriggers will be a struct array with (eventName, trigger) the
        % fields.
        % It's the responsibility of the Regime to provide triggers for
        % certain events. This is where those are kept.
        cropEventTriggers
        
        % Struct array containing the definition of the rotation.
        % Has fields crop, companionCrop, plant and harvest.
        % Also has category and DSE.
        % Moved to public so that we can edit it programatically (externally).
        rotationList

    end

    % This property bracket covers Annual regime specific data.
    properties (Access = private)
       
%         % cropEventData is a struct that the regime delegate uses to
%         % maintain the cropNamesList and the regimeEventsList dependent
%         % properties.
%         % cropNamesList = {cropEventData.name}
%         % regimeEventsList = {cropEventData.events}
%         % This way we're guaranteed that the names match the events.
%         cropEvents
       
        
        
        % Struct array containing the definition of the rotation.
        % Has fields crop, companionCrop, plant and harvest.
        % Also has category and DSE.
%        rotationList
        % MOVED TO PUBLIC
    end
    
    properties (Dependent)
               
%         % This will be a list of the names of the crops that are used in
%         % this regime.
%         cropNameList
%         
%         % This will be a list of cells that correspond to the cropNameList.
%         % Each cell contains an array of ImagineEvents which redefine the
%         % event from the one defined in the Crop.
%         % The way it works is that if an ImagineEvent exists in this list
%         % then it's the one that should be used. If a crop has an event
%         % that is not represented in this list, the Crop's event should be
%         % used.
%         % So for example if cropNamesList{2} = 'Wheat' then
%         % regimeEventsList{2} will be a list of regime-defined events for
%         % Wheat.
%         regimeEventsList
    end
   
   methods
   
       function reg = AnnualRegimeDelegate()
           reg.regimeCategory = 'Annual';
           reg.type = 'primary';
       end
       
   end
   
   % Set / get for dependent properties.
   methods 
       
%        function cNL = get.cropNameList(regDel)
%           cNL = {regDel.cropEvents.name}; 
%        end
%        
%        function rEL = get.regimeEventsList(regDel)
%           rEL =  {regDel.cropEvents.events}; 
%        end       

        function obj = rotate(obj)
            obj.rotationList = [obj.rotationList(end), obj.rotationList(1:end-1)];
            obj = obj.createAnnualRegimeEvents(obj);
        end

   end
   
   methods (Static = true)

       % To help load older versions, need to make sure the rotations have
       % the DSE field and category field.
       function obj = loadobj(s)
           if ~isfield(s.rotationList, 'category')
               for i = 1:length(s.rotationList)
                  s.rotationList(i).category = 'Annual';
                  s.rotationList(i).DSE = 0;
               end
           end
           obj = s;
       end
 
   end
   
   methods
       
       % The annual regime doesn't implement an exclusion zone, so return
       % 0.
       function exclusionZoneWidth = getExclusionZoneWidth(r)
           exclusionZoneWidth = 0;
        end
       
       % The implementation of this method should bring up a GUI in which
       % the user details all the relevant parameters for this regime. The
       % GUI should return a valid regime or an empty
       % array. It should take a valid regime parameters in the case
       % where we are editting the regime. These will be used to populate
       % the GUI.
       % The validity of a regime requires the validity of its delegate
       % object.
       function regDel = setupRegime(regDel)
       
           regimeMgr = RegimeManager.getInstance;
           cropMgr = CropManager.getInstance;
           regimeArguments.regimeDefinitions = regimeMgr.regimeDefinitions;
           regimeArguments.cropDefinitions = cropMgr.cropDefinitions;

           % If this is a new regime, it will have no crops (and therefore
           % cropEvents will be empty), so it won't need regimeParameters
           % to be defined. However, if it's an existing regime, we need to
           % pass the regimeParameters.
           if ~isempty(regDel.cropEventTriggers)
               
               % Else set up regime parameters and add them to the
               % arguments.
               regimeParameters.regimeLabel = regDel.regimeLabel;
               regimeParameters.startYear = regDel.startYear;
               regimeParameters.finalYear = regDel.finalYear;
               regimeParameters.timelineColour = regDel.timelineColour;
               
               regimeParameters.cropEventTriggers = regDel.cropEventTriggers;
               
               regimeParameters.rotationList = regDel.rotationList;
               
               regimeArguments.regimeParameters = regimeParameters;
           end
           
           regOut = AnnualRegimeDialog(regimeArguments);
           
           if ~isempty(regOut)
               % Save each parameter that's particular to this regime.
               regDel.regimeLabel = regOut.regimeLabel;
               regDel.startYear = regOut.startYear;
               regDel.finalYear = regOut.finalYear;
               regDel.timelineColour = regOut.timelineColour;
               regDel.cropEventTriggers = regOut.cropEventTriggers;
               regDel.rotationList = regOut.rotationList;
           end
           
       end
       
       % Returns a cell array of strings containing the names of the crops
       % planted in the given year. It could be more than one crop in the
       % case of a primary regime that has a companion crop, which is why
       % a cell array of strings is required.
       function cns = getCropsPlantedInYear(regDel, year)

           if (year >= regDel.startYear && year <= regDel.finalYear)
               rotIndex = mod(year - regDel.startYear, length(regDel.rotationList)) + 1;           
               rot = regDel.rotationList(rotIndex);
               if isempty(rot.companionCrop)
                  cns = {rot.crop}; 
               else
                  cns = {rot.crop, rot.companionCrop}; 
               end
           else
               disp('Tried to get information from a regime outside of when it is installed.');
               cns = {};
           end
           
       end
        
       % Returns a PaddockLayout object which contains information on how
       % the regime causes the paddock to be drawn in the requested year.
       % The PaddockLayout doens't have to specify how the entire paddock
       % is laid out, as more than one regime may influence this.
       % PaddockLayouts can be combined from more than one regime so that
       % later when the layout is drawn in the main Imagine window all the
       % data to draw the paddock in the requested year is available.
       function pl = getPaddockLayoutInYear(regDel, year)
           if (year >= regDel.startYear && year <= regDel.finalYear)
               pl = PaddockLayout;

               % Set the foreground colour to the crop's colour.
               cropMgr = CropManager.getInstance;
               cropDefs = cropMgr.cropDefinitions;
               rotIndex = mod(year - regDel.startYear, length(regDel.rotationList)) + 1;

               cropDef = cropDefs(strcmp({cropDefs.name}, regDel.rotationList(rotIndex).crop));
               pl.backgroundColour = cropDef.colour;
               pl.shouldShowBelts = false;
               pl.shouldShowBorders = false;
               pl.shouldShowWoodlands = false;
               pl.shouldShowContours = false;
                           
           else
               disp('Tried to get information from a regime outside of when it is installed.');
               pl = PaddockLayout.empty(1, 0);
           end
       end
       
       % Returns a column of regime outputs based on the simulation.
       function outputsColumn = calculateOutputs(regDel, sim)
            % Outputs returned by this regime:
            % Paddock
            % Area
            
            unit    = Unit('', 'Paddock', 'Unit');                
            outputsColumn = Amount(1, unit);
            imOb = ImagineObject.getInstance;

            % To work out the area we have to get the area of the
            % secondary regime, if one's installed. So we need to look
            % up the sim.
            unit = Unit('', 'Area', 'Hectare');
            secondaryRegime = sim.currentSecondaryInstalledRegime;
            if isempty(secondaryRegime)
                secondaryRegimeArea = 0;
            else
                amt = secondaryRegime.getAmount(unit);
                if ~isempty(amt)
                    secondaryRegimeArea = amt.number;
                else
                    secondaryRegimeArea = 0;
                end
            end

            % Work out if the current planted pimary crop has a NCZ
            % Give total area not including NCZ area.
            primaryPlantedCrop = sim.currentPrimaryPlantedCrop;

            if ~isempty(primaryPlantedCrop) && ~isempty(secondaryRegime)
                
                pPCState = primaryPlantedCrop.state;
                if ~isempty(pPCState)
                    fns = fieldnames(pPCState);

                    ix = find(strcmp(fns, 'NCZWidth'), 1, 'first');
                    if isempty(ix) || isempty(secondaryRegime)
                        NCZArea = 0;
                    else
                        NCZWidth = pPCState.NCZWidth;
                        if isempty(NCZWidth)
                            NCZWidth = 0;
                        end
                        cropInterfaceUnit = Unit('', 'Crop Interface Length', 'm');
                        amt = secondaryRegime.getAmount(cropInterfaceUnit);
                        if ~isempty(amt) && NCZWidth > 0
                            NCZArea = amt.number * NCZWidth / 10000;
                        else
                            NCZArea = 0;
                        end
                    end
                else
                    NCZArea = 0;
                end
            else
                NCZArea = 0;
            end
            totalAreaHa = imOb.paddockWidth * imOb.paddockLength / 10000;

            primaryArea = totalAreaHa - secondaryRegimeArea - NCZArea;
            
            if sim.month == 12
                a = 1;
            end
            
            outputsColumn(2) = Amount(primaryArea, unit);


           % cropMgr = CropManager.getInstance;
          %  cropDefs = cropMgr.cropDefinitions;
          year = sim.year;
            rotIndex = mod(year - regDel.startYear, length(regDel.rotationList)) + 1;

            unit = Unit('', 'DSE', 'Unit');
            if isnan(regDel.rotationList(rotIndex).DSE)
                dsePerHa = 0;
            else
                dsePerHa = regDel.rotationList(rotIndex).DSE;
            end
            outputsColumn(3) = Amount(primaryArea * dsePerHa, unit);
            
       end
       
       % Provides read access from outside into the parameters of the
       % regime.
       function p = getRegimeParameter(obj, pname)
           
           p = [];
           try
               p = obj.rotationList;
           catch e
               disp e
           end  
           
       end

       
       % Checks that the parameters of the regime delegate are ok.
       % Implementation is entirely up to the concrete regime delegate
       % class.
       % In this case the isValid method is not static, since we don't know
       % beforehand what the names of the subclassed RegimeDelegates will
       % be.
       function valid = isValid(regDel)
           valid = true;
       end
       
       % We need to find and check all references to cropNames in the
       % delegtae.
       % Need to check the cropName and companionCropName in each
       % rotation.
       % Also need to update all the cropEventTriggers.
       function cropNameHasChanged(regDel, previousName, newName)
           
           for i = 1:length(regDel.rotationList)
               if strcmp(regDel.rotationList(i).crop, previousName)
                   regDel.rotationList(i).crop = newName;
               end
               if strcmp(regDel.rotationList(i).companionCrop, previousName)
                   regDel.rotationList(i).companionCrop = newName;
               end
           end
           
           for i = 1:length(regDel.cropEventTriggers)
                if strcmp(regDel.cropEventTriggers(i).cropName, previousName)
                    regDel.cropEventTriggers(i).cropName = newName;
                end
                for j = 1:length(regDel.cropEventTriggers(i).eventTriggers)
                    % regDel.cropEventTriggers(i).eventTriggers(j) is a RegimeEventTrigger.
                    regDel.cropEventTriggers(i).eventTriggers(j).cropNameHasChanged(previousName, newName);                    
                end
            end
       end
       
   end
   
   methods (Static = true)
       
        % createAnnualRegimeEvents
        %
        % makes the cropEventTriggers list contain entries for the core events in the
        % crop. Sets planting and harvesting events for all crops used.
        function handles = createAnnualRegimeEvents(handles)

            % Get list of crops used in regime.
            % Will need to set planting and harvesting events for them.

            rotationCropNames = {handles.rotationList.crop};
            usedCropNames = unique(rotationCropNames);
            rotLength = length(handles.rotationList);
            startYear = handles.startYear;
            finalYear = handles.finalYear;
            regimeLength = finalYear - startYear + 1;

%            disp('creatingAnnualRegimeEvents');

            if ~isempty(handles.cropEventTriggers)
                % Removes the cropEventTriggers for crops we're not using in the regime
                % any more.
                handles.cropEventTriggers = handles.cropEventTriggers(ismember({handles.cropEventTriggers.cropName}, usedCropNames));
            end

            for i = 1:length(usedCropNames)

                cropName = usedCropNames{i};

                % Make sure that cropEventTriggers has an element for our crop.
                % Get it's index in the array and make it cropIndex.
                % Hereafter we can assume handles.cropEventTriggers(cropIndex) will
                % give us the struct with cropName and an array of eventTriggers in it.

                if isempty(handles.cropEventTriggers)
                    cropIndex = [];
                else
                    cropIndex = find(strcmp({handles.cropEventTriggers.cropName}, cropName));
                end

                if isempty(cropIndex)
                    % If we don't yet have events for the crop, we should load them
                    % from the crop.
                    % But what if the crop changes? Perhaps we should load the events from the crop here every time
                    % but overwrite the crop's event with the regimes event data if it exists, and then, only some fields. 
                    % It should definitely be the crop's growthmodel events and
                    % financial events that are used, not the category's events.

                    % add the events for the crop by accessing the cropManager.

                    cet.cropName = cropName;
                    cropMgr = CropManager.getInstance;
                    cropEvents = cropMgr.getCropsEvents(cropName);

                    % create the eventTriggers, a struct array with eventName, trigger.
                    for k = 1:length(cropEvents)
                        ets(k) = RegimeEventTrigger(cropEvents(k).name, cropEvents(k).trigger, cropEvents(k).status.regimeRedefinable); %#ok<AGROW>
                        dET = ets(k);
                    end
                    cet.eventTriggers = ets;
                    cropIndex = length(handles.cropEventTriggers)+1;

                    handles.cropEventTriggers(cropIndex) = cet;

                end

                rotationAppearances = strcmp(rotationCropNames, cropName);

                % We'll need rotationAppearances x3 conditions + 1 to get it all done.
                % (Unless theres only one appearance.)
                plantConditions = {};
                harvestConditions = {};

                for j = 1:sum(rotationAppearances)

                    % Conditions
                    % 1. Month is
                    % 2. Year index
                    % 3. And 1, 2

                    % Get planting month, harvest month, rotation index.
                    rotIndex = find(cumsum(rotationAppearances) .* rotationAppearances == j);

                    rot = handles.rotationList(rotIndex);
                    if strcmp(rot.category, 'Pasture')
                        rot.plant = 'Jan';
                        rot.harvest = 'Dec';
                    end

                    c1 = ImagineCondition.newCondition('Month Based', ['Month is ', rot.plant]);
                    ix = find(strcmp(c1.monthStrings, rot.plant));
                    c1.monthIndex = ix;

            %         c1.string1 = '';
            %         c1.value1 = 1;
            %         c1.stringComp = 'Month is';
            %         c1.valueComp = 1;
            %         c1.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
            %         c1.value2 = find(strcmp(c1.string2, rot.plant));
            %         c1.parameters1String = '';
            %         c1.parameters2String = '';

                    c1B = ImagineCondition.newCondition('Month Based', ['Month is ', rot.harvest]);
                    ix = find(strcmp(c1B.monthStrings, rot.harvest));
                    c1B.monthIndex = ix;

            %         c1B.string1 = '';
            %         c1B.value1 = 1;
            %         c1B.stringComp = 'Month is';
            %         c1B.valueComp = 1;
            %         c1B.string2 = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
            %         c1B.value2 = find(strcmp(c1B.string2, rot.harvest));
            %         c1B.parameters1String = '';
            %         c1B.parameters2String = '';

                    c2 = ImagineCondition.newCondition('Time Index Based', [number2placing(rotIndex) , ' year then every ', number2placing(rotLength) , ' year.']);
                    c2.indexType = 'Year';
                    c2.indices = (rotIndex + startYear - 1):rotLength:finalYear;

            %         c2.string1 = {'Year', 'Month'};
            %         c2.value1 = 1;
            %         c2.stringComp = {'=', '<', '>', '<=', '>='};
            %         c2.valueComp = 1;
            %         c2.string2 = [num2str(rotIndex + startYear - 1), ':', num2str(rotLength), ':', num2str(finalYear)];
            %         c2.value2 = 1;       
            %         c2.parameters1String = '';
            %         c2.parameters2String = '';

                    c3 = ImagineCondition.newCondition('And / Or / Not', ['C', num2str(j*3 - 2), ' AND C', num2str(j*3 - 1)]);
                    c3.indices = [(j*3 - 2), (j*3 - 1)];
                    c3.logicType = 'And';

            %         c3.string1 = {'AND', 'OR', 'NOT'};
            %         c3.value1 = 1;
            %         c3.stringComp = '';
            %         c3.valueComp = 1;
            %         c3.string2 = [num2str(j*3 - 2), ' ', num2str(j*3 - 1)];
            %         c3.value2 = 1;       
            %         c3.parameters1String = '';
            %         c3.parameters2String = '';

                    if isempty(plantConditions)
                        plantConditions = {c1 c2 c3};
                        harvestConditions = {c1B, c2, c3};
                    else
                        plantConditions(j*3-2:j*3) = {c1, c2, c3};
                        harvestConditions(j*3-2:j*3) = {c1B, c2, c3};    
                    end
                end

                if length(plantConditions) > 3

                    cAll = ImagineCondition.newCondition('AND / OR / NOT', ['Any of these conditions: ', num2str(3*1:sum(rotationAppearances))]);
                    cAll.logicType = 'Or';
                    cAll.indices = cumsum(rotationAppearances) .* 3;
                    cAll.indices = cAll.indices(rotationAppearances);

            %         cAll.string1 = {'AND', 'OR', 'NOT'};
            %         cAll.value1 = 2;
            %         cAll.stringComp = '';
            %         cAll.valueComp = 1;
            %         cAll.string2 = cumsum(rotationAppearances) .* 3;
            %         cAll.string2 = cAll.string2(rotationAppearances);
            %         cAll.string2 = num2str(cAll.string2);
            %         cAll.value2 = 1;       
            %         cAll.parameters1String = '';
            %         cAll.parameters2String = '';

                    harvestConditions{j*3+1} = cAll;       
                    plantConditions{j*3+1} = cAll;
                end

                % Set the triggers to the conditions.

                plantTrigger = Trigger;
                plantTrigger.conditions = plantConditions;
                if strcmp(rot.category, 'Pasture')
                    plantIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Establishment'));
                else        
                    plantIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Planting'));
                end

                ret = handles.cropEventTriggers(cropIndex).eventTriggers(plantIx);
                ret = ret.setPrivateTrigger(plantTrigger);
                handles.cropEventTriggers(cropIndex).eventTriggers(plantIx) = ret;

                harvestTrigger = Trigger;
                harvestTrigger.conditions = harvestConditions;

                if strcmp(rot.category, 'Pasture')
                    harvestIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Destruction'));
                else        
                    harvestIx = find(strcmp({handles.cropEventTriggers(cropIndex).eventTriggers.eventName}, 'Harvesting'));
                end
                ret = handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx);
                ret = ret.setPrivateTrigger(harvestTrigger);
                handles.cropEventTriggers(cropIndex).eventTriggers(harvestIx) = ret; 

                for j = 1:length(handles.cropEventTriggers(cropIndex).eventTriggers)
                    for k = 1:length(handles.cropEventTriggers(cropIndex).eventTriggers(j).trigger.conditions)
                        cond = handles.cropEventTriggers(cropIndex).eventTriggers(j).trigger.conditions{k};
                        disp(['  Condition: ',  cond.shorthand, ', type: ', cond.conditionType]);
                    end
                end

            end

            % Save the cropEventTriggers
       %     guidata(handles.defineTriggersButton, handles);
        end

   end
   
end