% The RegimeDelegate class defines what a regime really _is_. The Regime is
% really just a wrapper for some concrete subclass of the RegimeDelegate.
% All a regime's data is stored within a concrete subclass of
% RegimeDelegate, and therefore the RegimeDelegate serves as an interface
% between the Regime and all the possible implementations of a regime. The
% Regime will wrap the properties and methods found in this class.
classdef RegimeDelegate < handle
    
   % This Abstract class defines the interface that all regime delegate 
   % objects should adhere to.
    
   properties (Abstract, SetAccess = protected)
           
       % Regime category. Something like 'Annual' or 'Belt'
        regimeCategory
        
        % Type of the regime. Should be 'primary', 'secondary', or
        % 'exclusive'
        type
        
   end
       
   properties (Abstract)
       
        % The name of the regime.
        regimeLabel
        
        % Start and final year for the regime.
        startYear
        finalYear
        
        % Colour for the timeline in the ImagineWindow.
        timelineColour
        
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
        
        % cropEventTriggers
        % This will be a struct array with (cropName, eventTriggers) the fields.
        % eventTriggers will be a struct array with (eventName, trigger) the
        % fields.
        % It's the responsibility of the Regime to provide triggers for
        % certain events. This is where those are kept.
        cropEventTriggers
       
   end
   
   methods (Abstract)
   
       % The implementation of this method should bring up a GUI in which
       % the user details all the relevant parameters for this regime. The
       % GUI should return a valid regime or an empty
       % array. It should take a valid regime parameters in the case
       % where we are editting the regime. These will be used to populate
       % the GUI.
       % The validity of a regime requires the validity of its delegate
       % object.
       regDel = setupRegime(regDel)
       
       % Returns a column of regime outputs based on the simulation.
       outputsColumn = calculateOutputs(regDel, sim);
               
       % Returns a cell array of strings containing the names of the crops
       % planted in the given year. It could be more than one crop in the
       % case of a primary regime that has a companion crop, which is why
       % a cell array of strings is required.
       cns = getCropsPlantedInYear(r, year)

        % Returns a PaddockLayout object which contains information on how
        % the regime causes the paddock to be drawn in the requested year.
        % The PaddockLayout doens't have to specify how the entire paddock
        % is laid out, as more than one regime may influence this.
        % PaddockLayouts can be combined from more than one regime so that
        % later when the layout is drawn in the main Imagine window all the
        % data to draw the paddock in the requested year is available.
       getPaddockLayoutInYear(year)
       
       % Checks that the parameters of the regime delegate are ok.
       % Implementation is entirely up to the concrete regime delegate
       % class.
       % In this case the isValid method is not static, since we don't know
       % beforehand what the names of the subclassed RegimeDelegates will
       % be.
       valid = isValid(regDel)
       
       % Returns the exclusion zone width if it exists, or 0.
       exclusionZoneWidth = getExclusionZoneWidth(regDel)
       
       % Used to switch names of crops when they are editted. The
       % RegimeManager calls cropNameHasChanged on all the delegates
       % whenever it's listener is notified of a change.
       cropNameHasChanged(regDel, previousName, newName)
       
       p = getRegimeParameter(regDel, pname)
   end
   
end