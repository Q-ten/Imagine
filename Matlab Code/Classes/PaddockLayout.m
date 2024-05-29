classdef PaddockLayout 
    %PaddockLayout Contains information used to display the layout of a paddock.
    %   A regime defines the layout of a paddock over a number of years.
    %   The PaddockLayout class is used to describe how a paddock should be
    %   displayed visually. This could change from year to year. It is
    %   intended that a PaddockLayout should be returned by a regime when
    %   the layout for a particular year is requested. The RegimeDelegate
    %   is responsible for implementing the method that returns the layout.
    %   
    %   The paddockLayout has information on the foreground colour and
    %   the background colour, as well as whether borders, belts,
    %   woodlands and contours are to be drawn. This information
    %   ultimately comes from the regimes that are defined over the given
    %   year, but is combined by the regimeManager into the paddockLayout
    %   object, ultimately for the ImagineWindowManager to use.
    % 
    %   NOTE - This class should not be confused with a Layout. The Layout
    %   represents the graphic that is drawn in the Imagine window. A
    %   PaddockLayout contains the information required to draw the Layout.
    %   Perhaps the naming could have been better, but that's how it is.
    
    properties
        
        % The colours are optional. Foreground elements will be shown only
        % if a foregroundColour is defined. Similarly a background will
        % only be drawn if a backgroundColour is defined.
        backgroundColour = [];
        foregroundColour = [];
        
        % All foreground elements will be not be drawn by default. A
        % regimeDelegate must set one of these properties to true, and a
        % foregroundColour must be set for any foreground item to be drawn.
        shouldShowBelts = false;
        shouldShowBorders = false;
        shouldShowWoodlands = false; 
        shouldShowContours = false;
        
        % The data field is a general Matlab struct and can be accessed to
        % provide further information. Any regimeDelegate that creates a
        % PaddockLayout and adds information to this data property should
        % add its data under a field bearing the regimeLabel for the delegate.
        % This ensures that when merging the fields between different
        % regimes, we can support multiple regimes adding data in an
        % independent way. This behaviour cannot be enforced, but can be
        % tested for and these tests should be set up.
        data = [];
        
    end
    
    methods
        
        % This function merges the information from two paddockLayouts. pl2
        % is the second PaddockLayout and should have it's information
        % merged into pl.
        function pl = mergeWithPaddockLayout(pl, pl2)
            
            if ~isempty(pl.backgroundColour) && ~isempty(pl2.backgroundColour)
                print('PaddockLayout tried to merge with multiple backgroundColours.');
            else
                if ~isempty(pl2.backgroundColour)
                   pl.backgroundColour = pl2.backgroundColour;
                end
            end
       
            if ~isempty(pl.foregroundColour) && ~isempty(pl2.foregroundColour)
                print('PaddockLayout tried to merge with multiple backgroundColours.');
            else
                if ~isempty(pl2.foregroundColour)
                   pl.foregroundColour = pl2.foregroundColour;
                end
            end
      
            % If either PaddockLayout believes a forground item should be
            % shown, then show it.
            pl.shouldShowBelts = pl.shouldShowBelts || pl2.shouldShowBelts;
            pl.shouldShowBorders = pl.shouldShowBorders || pl2.shouldShowBorders;
            pl.shouldShowWoodlands = pl.shouldShowWoodlands || pl2.shouldShowWoodlands;
            pl.shouldShowContours = pl.shouldShowContours || pl2.shouldShowContours;
            
            % Combine the data objects.
            if ~isempty(pl2.data)
                secondFields = fieldnames(pl2.data);
                for i = 1:length(secondFields)
                    
                    % Use dynamic field names to copy the fields across.
                    pl.data.(secondFields{i}) = pl2.data.(secondFields{i}); 
                    
                end
            end
        end
        
        % Returns true if any of the shouldShow* properties are true.
        function TF = shouldShowForegroundElements(pl)
            TF = (pl.shouldShowBelts || pl.shouldShowBorders || pl.shouldShowWoodlands || pl.shouldShowContours);            
        end
        
    end
    
end

