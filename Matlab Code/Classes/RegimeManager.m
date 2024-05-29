classdef (Sealed = true) RegimeManager < handle
   
    % This class is responsible for maintaining the list of regimes in
    % Imagine. It should listen to the cropManager for relevant crop changes
    % and update notify the ImagineWindowManager via events when a change
    % to the screen is required.
    
    properties
       listeners = event.listener.empty(1, 0);
    end
    
    % Implement a singleton class.
    methods (Access = private)
        function obj = RegimeManager()
        end        
        
        function regimeManagerConstructor(obj)
            cropMgr = CropManager.getInstance();
            obj.listeners(end + 1) = addlistener(cropMgr, 'CropRemoved', @obj.cropWasRemoved);             
            obj.listeners(end + 1) = addlistener(cropMgr, 'CropNameChanged', @obj.cropNameChanged);             
        end
    end
    
    methods (Static)
        function singleObj = getInstance(loadedObj)
            persistent localObj
            
            % If a RegimeManager is passed in and is not the localObj,
            % then set it as the localObj.
            if nargin >= 1
                if isa(loadedObj, 'RegimeManager') && localObj ~= loadedObj
                    localObj = loadedObj;
                    localObj.regimeManagerConstructor;
                else
                    disp('Tried passing an object that''s not a RegimeManager to RegimeManager.getInstance.');
                    % Or possibly localObj ~= loadedObj because
                    % getInstance() has already been called before
                    % getInstance(loadedObj) has had a chance because some
                    % other getInstance (eg CropManager) calls getInstance
                    % of the RegimeManager.
                    % If this is the case then we should implement a
                    % listener for 'finishedLoading' which is triggered at
                    % the end of the ImagineObject load function and
                    % triggers the work that should be done after the
                    % objects are loaded - the kinds of things that might
                    % call RegimeManager.getInstance() such as redoing the
                    % listeners.
                    % So instead of calling regimeManagerConstructor in
                    % here, we set a listener on the ImagineObject and set
                    % the callback to do the constructing work.
                end
            end
            
%             disp(['RegimeManager is empty: ',  num2str(isempty(localObj))]);
%             if ~isempty(localObj)
%                 disp(['RegimeManager is valid: ',  num2str(isvalid(localObj))]);
%             end
            if isempty(localObj) || ~isvalid(localObj)
                localObj = RegimeManager;
                localObj.regimeManagerConstructor;
            end
            
            singleObj = localObj;
            
        end
    end
    
    properties
       
        regimes = Regime.empty(1, 0);
        
    end
    
    events
       % Many of these events should pass a new regime definitions list in the eventdata.
        
       RegimeAdded % Means we should add a regime to the list.
       RegimeRemoved % Will mean the name should be removed in the window.
              
       % Means that an edit has occured. 
       % This one might just contain a structure that 
       % has relevant editted fields... (Changed to what? From what?)
       RegimeEditted
       
       % In handler for RegimeEditted we may trigger these three events.
       RegimeCategoryChanged  % Will affect any regimes the crop was in.
       RegimeColourChanged % Will mean the ImagineWindow should use different colour.
       RegimeNameChanged % Will mean the regime list should be updated.
    end
    
    properties (Dependent)
        
        % This is a cut-down version of the regimes list. It ony gives
        % those things common to regimes, like the regimeLable, the years,
        % the type, the category, etc.
       regimeDefinitions 
    end
    
    methods (Static)
       
        % Register all the different regime delegate types in this function.
        % They should have a regimeType, and a delegateClass
        function RTs = getRegimeTypes
            
            RT.regimeCategory = 'Annual';
            RT.regimeType = 'primary';
            RT.delegateClass = 'AnnualRegimeDelegate';
            
            RTs(1) = RT;
            
            RT.regimeCategory = 'Belt';
            RT.regimeType = 'secondary';
            RT.delegateClass = 'BeltRegimeDelegate';
            
            RTs(2) = RT;
            
        end
        
        function loaded = loadobj(obj)
            disp('loading regime manager');
            obj.regimeManagerConstructor;
            loaded = obj;
        end
      
        
    end
    
    methods

        
        
        
        % Adds a new regime of the given type
        function addRegime(regimeMgr, regimeCat)            
            
            RTs = RegimeManager.getRegimeTypes;
            RT = RTs(strcmp({RTs.regimeCategory}, regimeCat));
            if isempty(RT)
                error('Tried to add a regime in non-exsitent regime category.'); 
            end
                
            
            
            r = Regime(RT.delegateClass);
            
            r = r.setupRegime;
            
            if Regime.isValid(r)
               % If adding the regime was successful, add it to the list of
               % regimes.
               % We also need to notify other Managers that we've added the
               % regime.
               regimeMgr.regimes(end+1) = r;
               regimeMgr.sortRegimes;
              
               disp('Added regime');
               
                % Broadcast the event
                evtData = RegimeListChangedEventData(regimeMgr.regimeDefinitions, '', r.regimeLabel);
                notify(regimeMgr, 'RegimeAdded', evtData);

               disp('Notified: Added regime');
                
            else
                % Must have cancelled or failed. Either way, we certainly dont update
                % the regime.
            %    error('The regime''s delegate returned an object that the Regime class deemed invalid.');
            end
            
        end
        
        % Removes regime with name r, or if r is a number, at index r.
        function removeRegime(regimeMgr, r, forceTF)
            
            if (nargin < 3)
                forceTF = false;
            end
            
            % Get the regime based on the index or string in r.
            if isnumeric(r)
                if r >= 1 && r <= length(regimeMgr.regimes)
                   regimeIndex = r;
                else
                    error('Regime index passed is out of bounds.');
                end
            elseif ischar(r)
                regimeIndex = find(strcmp({regimeMgr.regimes.regimeLabel}, r), 1, 'first'); 
                if isempty(regimeIndex)
                    error('Cannot find regime with matching regimeLabel to edit.');
                end
            else
                error('Argument passed to editRegime must be a string with a valid regimeLabel of the index of the regime in the regimeList.');
            end
            
            r = regimeMgr.regimes(regimeIndex);
            
            if (forceTF)
                buttons = 'Yes';
            else
                buttons = questdlg(['Are you sure you want to remove the regime with label: ', r.regimeLabel], 'Remove Regime Check');
            end
            
            if strcmp(buttons, 'Yes') 
                rLabel = r.regimeLabel;
                delete(r);
                regimeMgr.regimes = [regimeMgr.regimes(1:regimeIndex - 1), regimeMgr.regimes(regimeIndex + 1: end)];
                                
                % Broadcast the event
                evtData = RegimeListChangedEventData(regimeMgr.regimeDefinitions, rLabel, '');
                notify(regimeMgr, 'RegimeRemoved', evtData);
                
            end
        end
        
        % Edits the regime with name r, or if r is a number, at index r.
        function editRegime(regimeMgr, r)
            
            % Get the regime based on the index or string in r.
            if isnumeric(r)
                if r >= 1 && r <= length(regimeMgr.regimes)
                   regimeIndex = r;
                else
                    error('Regime index passed is out of bounds.');
                end
            elseif ischar(r)
                regimeIndex = find({regimeMgr.regimes.regimeLabel} == r, 1); 
                if isempty(regimeIndex)
                    error('Cannot find regime with matching regimeLabel to edit.');
                end
            else
                error('Argument passed to editRegime must be a string with a valid regimeLabel of the index of the regime in the regimeList.');
            end
            
            r = regimeMgr.regimes(regimeIndex);
            rPrevLabel = r.regimeLabel;
            r = r.setupRegime;
                        
            if Regime.isValid(r)
                regimeMgr.replaceRegime(rPrevLabel, r)
            elseif isempty(r)
                % Must have cancelled. Either way, we certainly dont update
                % the regime.
            else
                error('The regime''s delegate returned an object that the Regime class deemed invalid.');
            end
                        
        end  % end editRegime
        
        % Replaces the regime with name regimeName with newRegime
        function replaceRegime(regimeMgr, regimeLabel, newRegime)

            regimeIndex = find(ismember({regimeMgr.regimes.regimeLabel}, regimeLabel), 1); 
            if isempty(regimeIndex)
                error('Cannot find regime with matching regimeLabel to edit.');
            end
            
            if Regime.isValid(newRegime)
               regimeMgr.regimes(regimeIndex) = newRegime;
               regimeMgr.sortRegimes;
               
                % Broadcast the event
                evtData = RegimeListChangedEventData(regimeMgr.regimeDefinitions, regimeLabel, newRegime.regimeLabel);
                notify(regimeMgr, 'RegimeEditted', evtData);
            end
            
        end
                
        % Constructs an array of regime defintiions.
        function regdefs = get.regimeDefinitions(regMgr)
        
            labels = {regMgr.regimes.regimeLabel};
            categoryNames = {regMgr.regimes.regimeCategory};
            types = {regMgr.regimes.type};
            startYears = {regMgr.regimes.startYear};
            finalYears = {regMgr.regimes.finalYear};
            timelineColours = {regMgr.regimes.timelineColour};
            cropNameLists = {regMgr.regimes.cropNameList};
            
            regdefs = struct('regimeLabel', labels, 'categoryName', categoryNames, 'type', types, 'startYear', startYears, ...
                        'finalYear', finalYears, 'timelineColour', timelineColours, 'cropNameList', cropNameLists);
        end
        
        function regdef = getRegimeDefinition(regMgr, regimeLabel)           
            ix = find(strcmp({regMgr.regimes.regimeLabel}, regimeLabel), 1, 'first');
            if isempty(ix)
                regdef = [];
                return
            end
            reg = regMgr.regimes(ix);
        
            labels = {reg.regimeLabel};
            categoryNames = {reg.regimeCategory};
            types = {reg.type};
            startYears = {reg.startYear};
            finalYears = {reg.finalYear};
            timelineColours = {reg.timelineColour};
            cropNameLists = {reg.cropNameList};
            
            regdef = struct('regimeLabel', labels, 'categoryName', categoryNames, 'type', types, 'startYear', startYears, ...
                        'finalYear', finalYears, 'timelineColour', timelineColours, 'cropNameList', cropNameLists);
            
        end
        
        % Provides access to external objects to query the name of a crop
        % planted in a particular regime in a particular year. Note that a
        % cell array is returned, as there may be more than one crop
        % planted in one year under a regime like a primary annual regime
        % the may specify a companion crop as well as the primary crop.
        function cropNames = getCropPlantedUnderRegimeInYear(regMgr, regimeLabel, year)
        
            % This method looks up the regime and then asks it the name of
            % the crops planted in the given year. There could be more than
            % one in the case of a primary regime that specifies a
            % companion crop in a given year.
            reg = regMgr.regimes(strcmp(regimeLabel, {regMgr.regimes.regimeLabel}));
            if isempty(reg)
                cropNames = {};
            else
                cropNames = reg.getCropsPlantedInYear(year);
            end
        end
        
        
        % This method returns a paddockLayout containing the information required to
        % correctly render the layout for the paddock in the requested
        % year.
        % The paddockLayout has information on the foreground colour and
        % the background colour, as well as whether borders, belts,
        % woodlands and contours are to be drawn. This information
        % ultimately comes from the regimes that are defined over the given
        % year, but is combined by the regimeManager into the paddockLayout
        % object, ultimately for the ImagineWindowManager to use.
        function pl = getPaddockLayoutInYear(regMgr, year)
        
            % This method finds all the regimes that are defined for the 
            % supplied year. It requests the paddockLayouts for those
            % years and combines them into a single paddockLayout which is
            % returned.
            
            % Find all the regimes that cover the supplied year.
            regs = regMgr.regimes([regMgr.regimes.startYear] >= year & [regMgr.regimes.finalYear] <= year);

            if isempty(reg)
                pl = PaddockLayout; % A new, empty PaddockLayout. All properties at default values.
            else
                pl = PaddockLayout; % Start with a new, empty PaddockLayout
                for i = 1:length(regs)
                    pl = pl.mergeWithPaddockLayout(regs(i).getPaddockLayoutInYear(year));                   
                end
                % At the end of the above for loop all regimes covering the supplied year will
                % have had input into the returned PaddockLayout.
            end
        end
        
        % This method creates and returns a PaddockSummary object that
        % contains the information required to know what is being planted
        % under which regimes in a given year. Also contains layout
        % information to assist with drawing the layout for the given year
        % in the main Imagine window.
        % 
        % The RegimeManager can be thought of as a factory for
        % PaddockSummary objects. It maintains a list of seperate regimes,
        % but is able to combine the information from those into
        % PaddockSummarys for each year.
        %
        % The two methods above, getCropsPlantedInYear(regimeLabel, year)
        % and getPaddockLayoutInYear(year) are superceded by this method, 
        % which is meant to be the sole interface to other objects. The two
        % other methods might be removed later.
        function ps = getPaddockSummaryForYear(regMgr, year)
           
            % Create the new, empty PaddockSummary
            ps = PaddockSummary();
            ps.year = year;
            ps.paddockLayout = PaddockLayout;
                        
            % Find all the regimes that cover the supplied year.
            regs = regMgr.regimes([regMgr.regimes.startYear] <= year & [regMgr.regimes.finalYear] >= year);
           
            % Hopefully, there are at most 2 regimes returned in regs; the
            % primary and secondary regimes.
            primReg = regs(strcmp({regs.type}, 'primary'));
            if ~isempty(primReg)
               if length(primReg) > 1 
                  print(['Found more than one primary regime covering year ', year, '.']); 
               else
                  ps.primaryRegimeCategory = primReg.regimeCategory;
                  ps.primaryRegimeLabel = primReg.regimeLabel;
                  cropNames = primReg.getCropsPlantedInYear(year);
         
                  if ~isempty(cropNames)
                      ps.primaryCropName = cropNames{1};
                      if length(cropNames) > 1
                          ps.companionCropName = cropNames{2};
                      end
                  end   
                  % Merge the primary paddockLayout into the
                  % PaddockSummary's paddockLayout
            
                  ps.paddockLayout = ps.paddockLayout.mergeWithPaddockLayout(primReg.getPaddockLayoutInYear(year));     
            
               end
            end
            
            secondReg = regs(strcmp({regs.type}, 'secondary'));
            if ~isempty(secondReg)
               if length(secondReg) > 1 
                  print(['Found more than one primary regime covering year ', year, '.']); 
               else      
                  ps.secondaryRegimeCategory = secondReg.regimeCategory;
                  ps.secondaryRegimeLabel = secondReg.regimeLabel;
                  cropNames = secondReg.getCropsPlantedInYear(year);
                  if ~isempty(cropNames)
                      ps.secondaryCropName = cropNames{1};
                  end
                  % Merge the secondary paddockLayout into the
                  % PaddockSummary's paddockLayout
                  ps.paddockLayout = ps.paddockLayout.mergeWithPaddockLayout(secondReg.getPaddockLayoutInYear(year));
               end
            end
            
        end % end getPaddockSummaryForYear
        
        
        % requestRegimeInstallation returns an InstalledRegime if a regime
        % should start (be installed) in the monthIndex provided.
        % The InstalledRegime has a list of cropNames that exist in the
        % regime, the regimeLabel, and a list of plantingEvents.
        function inReg = requestRegimeInstallation(regMgr, zoneString, sim)
            
            inReg = InstalledRegime.empty(1, 0);
            
            % Go through the list of regimes to see if one matches the
            % zone and should start in the monthIndex provided.
            
            matchFound = false;
            
            for i = 1:length(regMgr.regimes)
                              
                % Check the start month
                if (regMgr.regimes(i).startYear - 1)* 12 + 1 == sim.monthIndex

                   % Check the zone
                   type = regMgr.regimes(i).type;   
                  
                   if strcmp(zoneString, 'primary') 
                       if strcmp(type, 'primary') || strcmp(type, 'exclusive')
                          % Then we've found a match
                          matchFound = true;
                       end
                   elseif strcmp(zoneString, 'secondary')
                       if strcmp(type, 'secondary')
                          % Then we've found a match
                          matchFound = true;
                       end
                   end
                   
                   % If we found a match construct the inReg and return it.
                   if matchFound
                      inReg = InstalledRegime(regMgr.regimes(i), sim, zoneString);
                      return
                  end
                    
                end
                
            end
            
        end
        
        % Returns the regime definitions for the regimes that have this
        % crop in them.
        function regDefs = regimesThatUseCrop(regMgr, cropName)
        
           regDefs = struct('regimeCategory', {}, 'type', {}, 'regimeLabel', {});
            
           for i = 1:length(regMgr.regimes)
               if any(strcmp(regMgr.regimes(i).cropNameList, cropName))
                   regDef.regimeCategory = regMgr.regimes(i).regimeCategory;
                   regDef.type = regMgr.regimes(i).type;
                   regDef.regimeLabel = regMgr.regimes(i).regimeLabel;
                   regDefs(end + 1) = regDef;  %#ok<AGROW>
               end
           end
            
        end
            
        
        % Checks that the regimeManager is capcable of supplying
        % sufficient data for a simulation.
        function TF = isReadyForSimulation(regMgr)
            
            TF = length(regMgr.regimes) >= 1;
            if ~TF
                return
            end
                
            % Checks that each regime is valid, that each crop
            % used is properly defined. This should be the case anyway.
            % Should check that no regimes overlap.
            for i = 1:length(regMgr.regimes)
                TF = Regime.isValid(regMgr.regimes(i));
                if ~TF
                    return
                end                
            end
            
            % Check the primary regimes don't overlap.
            primaryRegimes = regMgr.regimes(strcmp({regMgr.regimes.type}, 'primary'));
            if ~isempty(primaryRegimes)
                [~, sortIx] = sort([primaryRegimes.startYear]);
                primaryRegimes = primaryRegimes(sortIx);
                for i = 1:length(primaryRegimes)-1
                    % if the next start year is before the current final
                    % year we have an overlap.
                    if primaryRegimes(i+1).startYear <= primaryRegimes(i).finalYear
                        TF = false;
                        return
                    end
                end
            end
            
            % Check that secondary regimes don't overlap.
            secondaryRegimes = regMgr.regimes(strcmp({regMgr.regimes.type}, 'secondary'));
            if ~isempty(secondaryRegimes)
                [~, sortIx] = sort([secondaryRegimes.startYear]);
                secondaryRegimes = secondaryRegimes(sortIx);
                for i = 1:length(secondaryRegimes)-1
                    % if the next start year is before the current final
                    % year we have an overlap.
                    if secondaryRegimes(i+1).startYear <= secondaryRegimes(i).finalYear
                        TF = false;
                        return
                    end
                end
            end
            
        end
        
        % When a crop is removed from the list, we have to make sure that
        % we remove all the regimes that might use that crop.
        function cropWasRemoved(singleObj,src,evnt)
          % singleObj - the singleton instance of this class
          % src - object generating event
          % evnt - the event data
          % Remove each regime cited in evnt.regimesToRemove
          for i = 1:length(evnt.regimesToRemove)
            %  {singleObj.regimes.regimeLabel}
            %  evnt.regimesToRemove{i}
              ix = find(strcmp({singleObj.regimes.regimeLabel}, evnt.regimesToRemove{i}), 1, 'first');
              if ~isempty(ix)
                  r = singleObj.regimes(ix);
             %     rlab = r.regimeLabel;
             %     tf = evnt.forceRegimeRemoval;
                  singleObj.removeRegime(r.regimeLabel, evnt.forceRegimeRemoval);
              end
          end
        
        end
        
        function cropNameChanged(singleObj, src, evtData)
           
            % Notify all the regimeDelegates that a crop name has changed.
            for i = 1:length(singleObj.regimes)
                singleObj.regimes(i).cropNameWasChanged(evtData.previousName, evtData.newName);
            end
        end
        
    end % end methods
    
    
    % Private helper functions
    methods (Access = private)
    
        % Sorts the list of regimes by their label.
        function sortRegimes(regMgr)
    
            % Clear empty regimes if they exist, which they shouldn't
           regLabels = {regMgr.regimes.regimeLabel};
           logs = logical(ones(1, length(regLabels)));
           for i = 1:length(regLabels)
              if isempty(regLabels{i})
                 logs(i) = false;
              else
                  logs(i) = true;
              end
           end
           
           regMgr.regimes = regMgr.regimes(logs);
            
            if ~isempty(regMgr.regimes)
                regLabels = {regMgr.regimes.regimeLabel};
                [~, indices] = sort(regLabels);
                regMgr.regimes = regMgr.regimes(indices);
                disp(['regimes sorted?', num2str(issorted({regMgr.regimes.regimeLabel}))])
            end            
        end
    
    end
end