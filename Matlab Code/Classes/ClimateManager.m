% The Climate Manager maintains the climate model or possibly a list of climate models. 
% It will be responsible for setting up rainfall data and providing that
% rainfall data in the simulation.
% It is called a climate manager rather than rainfall manager because we
% may want to get other kinds of climate data out. Like temperature,
% humidity, etc. Also, rainfall can be provided in different formats.
%
% We may want to implement a climate model in a similar way to how we do
% growth models, in that there is a list of supported outputs, and growth
% models can declare which types of information it is interested in, and
% therefore what kind of climate model will be required. If we model
% rainfall in higher detail, we can use this to go back to lower detail
% models. For example if we had rainevents and mm / event, we could turn
% this into monthly rainfall. Easy.
classdef (Sealed = true) ClimateManager < handle
    
        
    % Implement a singleton class.
    methods (Access = private)
        function obj = ClimateManager()
        end
        
        % Put code that would normally appear in the constructor in here.
        function climateManagerConstructor(obj)
            obj.monthlyRainfallTrendParameters = {};
        end
    end
    
    properties
       % Each way of doing the climate can have it's own parameters.
       monthlyRainfallTrendParameters
       rainfallAxisHandle
       
       climateModel
    end
    
    methods (Static)
        function singleObj = getInstance(loadedObj)
            persistent localObj
                        
            % If a ClimateManager is passed in and is not the localObj,
            % then set it as the localObj.
            if nargin >= 1
                if isa(loadedObj, 'ClimateManager') && localObj ~= loadedObj
                    localObj = loadedObj;
                    disp('Set ClimateMgr to loadedClimateMgr.');                    
                else
                    disp('Tried passing an object that''s not a ClimateManager to ClimateManager.getInstance.');
                end
            end
            
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClimateManager;
                localObj.climateManagerConstructor;
            end
                singleObj = localObj;
        end
    end
    
    % Simulation methods
    methods
        
        % Generates a 12 x m array of monthly rainfall for m years.
        function monthlyRain = generateMonthlyRainfall(climateMgr)

            params = climateMgr.monthlyRainfallTrendParameters;
            if isfield(params, 'useYearlyData')
                useYearlyData = params.useYearlyData;
            else
                useYearlyData = false;
            end
            
            if isfield(params, 'useZeroVariance')
                useZeroVariance = params.useZeroVariance;
            else
                useZeroVariance = false;
            end
            
            imOb = ImagineObject.getInstance;
            simLength = imOb.simulationLength;
            
            if (useYearlyData)
                monthlyRain = params.yearlyRainMeans';
                if (~useZeroVariance)                    
                   monthlyRain = monthlyRain + params.yearlyRainSDs' .* randn(size(params.yearlyRainSDs, 2), size(params.yearlyRainSDs, 1)); 
                end                
            else
                monthlyRain = zeros(12, simLength);
                
                for i = 1:12
                    
                    if (useZeroVariance)
                       rainSD = 0;
                    else
                       rainSD = params.rainSDs(i); 
                    end
                    
                    t = Trend('Polynomial', climateMgr.monthlyRainfallTrendParameters.rainMeans(i), ...
                                'Polynomial', rainSD);
                    [~,~,s] = t.createTrendSeries(simLength);
                    
                    monthlyRain(i, :) = s;                
                end    
            end
            monthlyRainMin = zeros(12, simLength);
            monthlyRain = max(monthlyRain, monthlyRainMin);
            
        end
        
        % Returns the average rainfall for each month.
        function monthAvs = getMonthlyAverageRainfall(climateMgr)
            params = climateMgr.monthlyRainfallTrendParameters;
            if isfield(params, 'useYearlyData')
                useYearlyData = params.useYearlyData;
            else
                useYearlyData = false;
            end
            
            if (useYearlyData)
                monthAvs = mean(params.yearlyRainMeans);
            else
                monthAvs = params.rainMeans;
            end
        end
        
        % Launches the MonthlyRainfallDialogue which should return
        % a struct that can be interpreted by the climate manager.
        function editMonthlyRainfallParameters(climateMgr)
            climateMgr.climateModel = MonthlyRainfallDialogue(climateMgr.monthlyRainfallTrendParameters);
            if ~isempty(climateMgr.climateModel)
               climateMgr.monthlyRainfallTrendParameters = climateMgr.climateModel; 
               iwm = ImagineWindowManager.getInstance;
               iwm.drawClimateAxes(climateMgr.climateModel);
            end
        end
        
        % Checks that the climateManager is capcable of supplying
        % sufficient data for a simulation.
        function TF = isReadyForSimulation(climateMgr)
            
            % Check that the rainfall model is defined, and can cater for
            % the length of the simulation.
            imOb = ImagineObject.getInstance;
            simLength = imOb.simulationLength;
            
            if (isempty(climateMgr.climateModel) || isempty(climateMgr.monthlyRainfallTrendParameters))
                TF = false;
                return
            end
            
            % At this stage there is only the monthly rainfall option.
            % So we simply check that there are 12 valid trend parameters defined.
            TF = length(climateMgr.monthlyRainfallTrendParameters.rainMeans) == 12 && length(climateMgr.monthlyRainfallTrendParameters.rainSDs) == 12;
            if ~TF
                return
            end
            
            for i=1:12
               rainMean = climateMgr.monthlyRainfallTrendParameters.rainMeans(i);
               rainSD = climateMgr.monthlyRainfallTrendParameters.rainSDs(i);
               TF = TF && isnumeric(rainMean) && isnumeric(rainSD);
               if ~TF 
                   return
               end
               TF = TF && rainMean >= 0 && rainSD > 0;
               if ~TF 
                   return
               end
            end
            
        end
        
    end
end




