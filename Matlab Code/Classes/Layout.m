% A Layout contains the handles for the graphics objects related to a 
% single year in Imagine's main window. 
%
%   NOTE - This class should not be confused with a PaddockLayout. A Layout
%   represents a graphic that is drawn in the Imagine window. A
%   PaddockLayout contains the information required to draw the Layout.
%   Perhaps the naming could have been better, but that's how it is.

classdef Layout < handle

    properties
        % patchHandle is the main patch.
        patchHandle = 0;
        
        % textHandle displays the year number
        textHandle = 0;
        
        % beltLines is a list of Lines used to represent the belts on the
        % patch
        beltLines = zeros(1, 10);
        
        % borderLines is a list of Lines used to represent the borders on
        % the patch.
        borderLines = zeros(1,4); 
        
        % The axis on which the layout appears.
        ax
                
    end

    
    methods
        
        function obj = Layout()
        
        end
        
        function setBackgroundColour(obj, colourTriple)
            
           % If the background colour is set, then we should update the patch. 
           if obj.patchHandle ~= 0 && isValidColourTriple(colourTriple)
              try
                   set(obj.patchHandle, 'FaceColor', colourTriple);
              catch exception
                  disp(exception.message);
              end            
           end
           
        end
        
        function setForegroundColour(obj, colourTriple)
            % If the belt colour is set then we should update the belts and
            % the borders.
            if isValidColourTriple(colourTriple)
                    borderLinesToSet =  obj.borderLines(obj.borderLines ~=0);
                    beltLinesToSet =  obj.beltLines(obj.beltLines ~=0);
                    set([borderLinesToSet, beltLinesToSet], 'Color', colourTriple);
            end
        end
        

        % This function takes a string - 'on' or 'offd' and
        % sets the visibility of all the Border lines in the layout accordingly.
        function setBorderVisibility(obj, visString)
            if strcmp(visString, 'on') == 0 || strcmp(visString, 'off') == 0
                if (~isempty(obj.borderLines))
                    borderLinesToSet =  obj.borderLines(obj.borderLines ~=0);
                    if ~isempty(borderLinesToSet)                        
                        set(borderLinesToSet, 'Visible', visString);
                    end
                end
            else
                disp('must pass ''on'' or ''off'' to setBordersVisibility');
            end
        end
        
        % This function takes a string - 'Enabled' or 'Disabled' and
        % sets the visibility of all the Belt lines in the layout accordingly.
        function setBeltVisibility(obj, visString)
            if strcmp(visString, 'on') == 0 || strcmp(visString, 'off') == 0
                if (~isempty(obj.beltLines))
                    beltLinesToSet =  obj.beltLines(obj.beltLines ~=0);
                    if ~isempty(beltLinesToSet)
                        set(beltLinesToSet, 'Visible', visString);
                    end
                end
            else
                disp('must pass ''on'' or ''off'' to setBeltVisibility');
            end
        end
        
    end
end