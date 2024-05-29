% ManualAnnualGM
% 
% Provides based yield for annual crops based on rainfall in relevant
% months within a given year. Uses a quadratic function to map the total
% rain in relevant months to a yield.

classdef ManualAnnualGM < handle
   
    properties
        trend           % a Trend object.
    end

    properties (Access = private)
        currentData     % the data last set by the sampleDistribution method.    
    end
    
    methods
        % Constructor
        function obj = ManualAnnualGM
            obj.trend = Trend;
            obj.trend.varType = 'Yearly Data';
            obj.trend.trendType = 'Yearly Data';
            obj.trend.trendData = 0;
            obj.trend.varData = 0;
        end
    end
    
    methods

        % Launches its dialog and sets its data accordingly.
        function setup(obj, HIData)
            newTrend = ManualAnnualGMDialog(obj.trend, HIData);
            if isempty(newTrend)
                return
            end            
            obj.trend = newTrend;
        end
       
        function setTrend(obj, newTrend)
           obj.trend = newTrend;
           obj.currentData = [];
        end
        
        % Returns the yield based on the trend for the current year.
        function yield = calculateYearlyYield(obj, sim)
            if isempty(obj.currentData)
                yield = 0;
            else
               yield = obj.currentData(sim.year); 
            end
        end
        
        % Populates a summary panel to show the current parameter settings.
        function populateSummaryPanel(obj, panel, HIData)
            
        end
        
        % Populates a gui axes to show the trend data.
        % The optional HarvestIndexData is used to determine the
        % axis labels / key
        function populateSummaryGraph(obj, ax, HIData)
            
            axes(ax);
            cla

            if isempty(obj.trend)
                return
            end
            
            [m, v, s] = obj.trend.createTrendSeries(50);
            hold on
            t = 1:length(s);
            
            bar(s, 'FaceColor', [0.5 0.5 1], 'EdgeColor', [0.4 0.4 0.6], 'BarWidth', 0.9);
            plot(t, m, 'r-', t, m + v, 'g--', t, m - v, 'g--', 'LineWidth', 2);
            axis auto
            set(ax, 'XLim', [0 length(s) + 1]);
       
            xlabel('Year');
            ylabel([HIData.units, ' (t/Ha)']);
       
 %           set(ax, 'YLim', []);
        end
        
        % Samples the trend to determine an entire series of data.
        % Should be called once from the planting function.
        function sampleDistribution(obj)
            [~, ~, obj.currentData] = obj.trend.createTrendSeries;
        end
               
    end
    
end

