classdef RegimeTimeline < handle
    %RegimeTimeLine Contains handles to graphics objects and the
    %information required to render timelines for regimes on the layouts
    %axes.
    %   RegimeTimeLine has handles to the graphics objects being the
    %   horizontal lines and the end points. There's up to 5 horizontal
    %   lines. And always two end points.
    %   It has a start year and an end year and a colour.
    
    properties
        
        startYear = 0
        finalYear = 0
        colour = [0 0 0];
        regimeLabel = '';
        type = '';
        
        ax
        rowLines
        endLines

        bottomOffset
        lineWidth
        
    end
    
    methods
        
        % Initialise the rowLines and endLines. 
        function obj = RegimeTimeline(regimeLabel, startYear, finalYear, colour, type, ax)
            obj.ax = ax;
            obj.type = type;
            
            if any(strcmp(obj.type , 'primary'))
                obj.bottomOffset = 20;
                obj.lineWidth = 2;
            elseif any(strcmp(obj.type , 'secondary'))
                obj.bottomOffset = 10;
                obj.lineWidth = 2;
            else
                error('Error: drawRegimeLines - Regime type not supported.')
                
            end
            
            if ~iscell(obj.rowLines)
               obj.rowLines = num2cell(obj.rowLines); 
               for i = 1:length(obj.rowLines)
                  if obj.rowLines{i} == 0
                     obj.rowLines{i} = []; 
                  end
               end
            end
            
            if ~iscell(obj.endLines)
               obj.endLines = num2cell(obj.endLines); 
               for i = 1:length(obj.endLines)
                  if obj.endLines{i} == 0
                     obj.endLines{i} = []; 
                  end
               end
            end
            
            obj.update(regimeLabel, startYear, finalYear, colour)
        end
        
        % Clears the lines already drawn if any.
        function clearLines(obj)
           
            for i = length(obj.endLines):-1:1
                if ishandle(obj.endLines{i})
                    disp(obj.endLines{i})
                    delete(obj.endLines{i});
                end
            end
            
            for i = length(obj.rowLines):-1:1
                if ishandle(obj.rowLines{i})
                    disp (obj.rowLines{i})
                    delete(obj.rowLines{i});
                end
            end 
        end
        
        function delete(obj)
           obj.clearLines; 
        end
        
        function update(obj, regimeLabel, startYear, finalYear, colour)
            
            obj.startYear = startYear;
            obj.finalYear = finalYear;
            obj.regimeLabel = regimeLabel;
            obj.colour = colour;

            obj.clearLines;
            

            
            startRow = floor((obj.startYear - 1)/10) +1;
            finishRow = floor((obj.finalYear - 1)/10) +1;
            set(gcf,'CurrentAxes',obj.ax)
            
            for i = 1:5

               startingPoint = -1;
               finishingPoint = -1;

               if(i == startRow)
                  % Then it starts on this row and we can get the starting point 
                   startingPoint = mod(obj.startYear-1, 10) * 70 + 10;
                   obj.endLines{1} = line([startingPoint, startingPoint], (500 - 100*i + obj.bottomOffset) * [1 1] + [-3 3], 'Color', obj.colour); 
               elseif(i > startRow)
                   % Then we must have already started. So come in from the very left.
                   startingPoint = 0;
               end

               if(i == finishRow)
                  % Then this is the last row, but we need to calculate the endpoint.
                   finishingPoint = mod(obj.finalYear -1, 10) * 70 + 60;            
                   obj.endLines{2} = line([finishingPoint, finishingPoint], (500 - 100*i + obj.bottomOffset) * [1 1] + [-3 3], 'Color', obj.colour); 

               elseif(i < finishRow)
                   % Then we are going to continue. So go out the right.
                   finishingPoint = 700;
               end

               if(startingPoint == -1 || finishingPoint == -1)
                   continue
               else
                    obj.rowLines{i} = line([startingPoint, finishingPoint], (500 - 100*i + obj.bottomOffset) * [1 1], 'Color', obj.colour, 'LineWidth', obj.lineWidth); 
               end

            end
            
        end
        
        
    end
    
end

