% RainfallBasedAnnualGM
% 
% Provides based yield for annual crops based on rainfall in relevant
% months within a given year. Uses a quadratic function to map the total
% rain in relevant months to a yield.

classdef RainfallBasedAnnualGM < handle
   
    properties% (Access = private)
       
        A
        B
        C
        
        firstRelevantMonth      % Numbers from 1 - 12 indicate the month. 
        lastRelevantMonth
        
    end
    
    methods 
        function obj = RainfallBasedAnnualGM(params)

            if (nargin < 1)
                params = struct([]);
            end
            fields = {'A', 'B', 'C', 'firstRelevantMonth', 'lastRelevantMonth'};

            def.A = (3e-6);
            def.B = 0.02;
            def.C = 1;
            def.firstRelevantMonth = 1;
            def.lastRelevantMonth = 12;            
            
            def = absorbFields(def, params);
            
            for i = 1:length(fields)
                obj.(fields{i}) = def.(fields{i}); 
            end

        end
        
    end
    
    methods

        % Launches its dialog and sets its data accordingly.
        function setup(obj, HIData)

            newGM = RainfallBasedAnnualGMDialog(obj.A, obj.B, obj.C, obj.firstRelevantMonth, obj.lastRelevantMonth, HIData);
            if isempty(newGM)
               return 
            end
            obj.A = newGM.A;
            obj.B = newGM.B;
            obj.C = newGM.C;

            obj.firstRelevantMonth = newGM.firstRelevantMonth;
            obj.lastRelevantMonth = newGM.lastRelevantMonth;
            
        end
       
        % Returns the yield based on the rainfall of the current year in
        % the sim. Uses the sim's rainfall to determine.
        function yield = calculateYearlyYield(obj, sim, plantedMonth)
            
            % Get the rainfall for the relevant months from the sim.
            year = sim.year;
            
            % Calculate the rainfall based on the A, B, C.
            relevantRainToDate = sim.monthlyRainfall((1:12 >= obj.firstRelevantMonth & ...
                                                      1:12 <= obj.lastRelevantMonth & ...
                                                      1:12 >= mod(plantedMonth, 12) & ...
                                                      1:12 <= sim.month), year);
            yield = max(0, polyval([-obj.A, obj.B, obj.C], sum(relevantRainToDate)));
            
         %   if (obj.A > 0)
         %      error('A should be negative. Check the dialog inputs and outputs.'); 
         %   end
        end
        
        % Populates a summary panel to show the current parameter settings.
        function populateSummaryPanel(obj, summaryHandles, HIData)
            
            set(summaryHandles.textA, 'String', num2str(obj.A));
            set(summaryHandles.textB, 'String', num2str(obj.B));
            set(summaryHandles.textC, 'String', num2str(obj.C));

            months = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
            set(summaryHandles.textFirstMonth, 'String', months{obj.firstRelevantMonth});
            set(summaryHandles.textLastMonth, 'String', months{obj.lastRelevantMonth});
            
        end
        
        % Populates a gui axes to show the mapping between rainfall and
        % yield. The optional HarvestIndexData is used to determine the
        % axis labels / key
        function populateSummaryGraph(obj, ax, HIData)
           
            axes(ax);
            cla(ax);
            p = [-obj.A, obj.B, obj.C];
            t = [0:700];
            y = polyval(p, t);

            hold on
            plot(t, y);
            
            axis([0 700 0 max(y) * 1.2])
            xlabel('Rainfall (mm)');
            ylabel([HIData.units, ' (t/Ha)']);
        end
               
    end
    
end