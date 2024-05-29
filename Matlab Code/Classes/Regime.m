classdef Regime < handle
   
%     A regime object defines a period of time in which a particular crop
%     growing pattern will be implemented. Fundamental to the regime is the
%     start and end year in which it is effective. However, there will be
%     several different types of regime, which will be applicable to crops
%     of different categories.
% 
%     A regime will be responsible for defining events within the
%     lifecycles of the crops that are used in it's scope. So for example,
%     it will define when the planting and the harvesting events for crops
%     occur. It may also define other intermediary events, and it may also
%     cover several crops within the same regime. For example, the Annual
%     regime will define a crop rotation pattern. The regime will specify
%     the event triggers for planting and harvesting of crops within the
%     rotation.
% 
%     A regime also defines the spatial layout of the crops. Regimes may
%     either be 'primary' or 'secondary' or 'exclusive'. A primary regime
%     covers the entire paddock, except for the parts that a used by a
%     secondary regime, in the same year. In a given year, a primary regime
%     may well coexist with a secondary regime, but only one primary and
%     one secondary regime can exist in a given year. An exclusive regime
%     requires that no other regime can coexist with it.
% 
%     The Annual regime is an example of a primary regime.
%     Belts and Borders is an example of a secondary regime.
%     Block Forestry is an example of an exclusive regime.
% 
%     These distinctions are really only necessary to calculate the area
%     taken up by the regime.
%     A primary regime's area will be the paddock area - the secondary
%     regime's area. So it's dependant on any secondary regime, if it
%     exists.
% 
%     So the task of providing the area of a regime, or the number of
%     trees, etc (The multiplying unit) will be up to the RegimeManager,
%     since the area of a primary regime may change if a coexisting
%     secondary regime changes.
    
    properties
              
        % Regime delegate object
        % The delegate object is responsible for the implementation of the
        % regime. It will be a concrete implementation of the Abstract 
        % class RegimeDelegate. We do this so that we can maintain an array
        % of Regimes. If we subclassed an Abstract Regime class, the
        % subclasses could not coexist in the same array.
        % The delegate will contain a function that brings up the regime
        % specification dialogue. It will also define events for the
        % regime.
        % All the relevant parameters for the regime will be properties of
        % the concrete subclass of RegimeDelgate.
        delegate = [];
        
        % delegateClass is simply the name of the class. Basically, the
        % class(delegate) should return delegateClass.
        delegateClass = '';
        
    end
    
    properties(Dependent)
       
        % Regime category. Something like 'Annual' or 'Belt'
        regimeCategory
        
        % Type of the regime. Should be 'primary', 'secondary', or
        % 'exclusive'
        type
        
        % The name of the regime.
        regimeLabel
        
        % Start and final year for the regime.
        startYear
        finalYear
        
        % Colour for the timeline in the ImagineWindow.
        timelineColour
        
        % This will be a list of the names of the crops that are used in
        % this regime.
        cropNameList
        
        % cropEventTriggers
        % This will be a struct array with (cropName, eventTriggers) the fields.
        % eventTriggers will be a struct array with (eventName, trigger) the
        % fields.
        % It's the responsibility of the Regime to provide triggers for
        % certain events. This is where those are kept.
        cropEventTriggers
        
    end
    
    methods (Static)
        
        function TF = isValid(r)
            % Checks that the regime's elements are correct and that the
            % delegate is also valid.
            TF = ~isempty(r);
            if(~TF)
                return;
            end
            
            TF = ~isempty(r.regimeLabel);
            if(~TF)
                return;
            end
            
            TF = ~isempty(r.timelineColour);
            
        end
    end
    
    methods
       
        % Constructor
        function r = Regime(delegateClass)
            r.delegate = eval(delegateClass);
            r.delegateClass = delegateClass;           
%            r.category = regimeCategory;
%            r.type = regimeType;
        end
        
        % Wrap delegate methods
        function r = setupRegime(r)
           r.delegate = r.delegate.setupRegime;
        end
        
        function type = get.type(r)
           type = r.delegate.type; 
        end
        
        function regCat = get.regimeCategory(r)
           regCat = r.delegate.regimeCategory; 
        end
        
        function rlabel = get.regimeLabel(r)
           rlabel = r.delegate.regimeLabel; 
        end
        
        function sy = get.startYear(r)
           sy = r.delegate.startYear; 
        end
        
        function fy = get.finalYear(r)
           fy = r.delegate.finalYear; 
        end
        
        function tlc = get.timelineColour(r)
           tlc = r.delegate.timelineColour; 
        end
        
        function cnl = get.cropNameList(r)
           cnl = {r.delegate.cropEventTriggers.cropName}; 
        end        
        
        function cETs = get.cropEventTriggers(r)
           cETs = r.delegate.cropEventTriggers; 
        end
        
        % Returns a cell array of strings containing the names of the crops
        % planted in the given year. It could be more than one crop in the
        % case of a primary regime that has a companion crop, which is why
        % a cell array of strings is required.
        function cns = getCropsPlantedInYear(r, year)
           cns =  r.delegate.getCropsPlantedInYear(year);
        end
        
        % Returns a PaddockLayout object which contains information on how
        % the regime causes the paddock to be drawn in the requested year.
        % The PaddockLayout doens't have to specify how the entire paddock
        % is laid out, as more than one regime may influence this.
        % PaddockLayouts can be combined from more than one regime so thatus
        % later when the layout is drawn in the main Imagine window all the
        % data to draw the paddock in the requested year is available.
        function pl = getPaddockLayoutInYear(r, year)
           pl =  r.delegate.getPaddockLayoutInYear(year);
        end
        
        function outputsColumn = calculateOutputs(r, sim)
           outputsColumn = r.delegate.calculateOutputs(sim); 
        end
        
        function exclusionZoneWidth = getExclusionZoneWidth(r)
           exclusionZoneWidth = r.delegate.getExclusionZoneWidth;
        end
        
        function p = getRegimeParameter(r, pname)
            p = r.delegate.getRegimeParameter(pname);
        end
        
        function cropNameWasChanged(r, previousName, newName)
           r.delegate.cropNameHasChanged(previousName, newName); 
        end
        
    end
    
end