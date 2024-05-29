% Draws the monthly rainfall model on the axes ax.
% 
function [meanPatches, upperSDLines, lowerSDLines] = drawMonthlyRainfallModel(rainfallModel, ax)

axes(ax);
cla

if(isempty(rainfallModel))
    return
end

if isfield(rainfallModel, 'useYearlyData')
    useYearlyData = rainfallModel.useYearlyData;
else
    useYearlyData = false;
end

if (useYearlyData)
   rainMeans = mean(rainfallModel.yearlyRainMeans); 
   rainSDs = mean(rainfallModel.yearlyRainSDs); 
else
   rainMeans = rainfallModel.rainMeans; 
   rainSDs = rainfallModel.rainSDs;     
end

if isfield(rainfallModel, 'useZeroVariance')
    useZeroVariance = rainfallModel.useZeroVariance;
else
    useZeroVariance = false;
end

if useZeroVariance
    rainSDs = zeros(1, 12);
end

barGap = 6; % 6px
rainBarFaceColour = [0.5 0.5 1];
maxRain = max(rainMeans + rainSDs);
axis([0 600 0 maxRain*1.2]);

set(ax, 'XTick', []);
set(ax, 'XTickLabel', []);

set(ax, 'YTick', 0:100:(floor(maxRain/100)+1)*100);
set(ax, 'YTickLabel', 0:100:(floor(maxRain/100)+1)*100);

meanPatches = zeros(1,12);
upperSDLines = zeros(1,12);
lowerSDLines = zeros(1,12);

for i = 1:12
    
    meanPatches(i) = patch([barGap/2, barGap/2, 50 - barGap/2, 50 - barGap/2] + (i-1)*50, [0 rainMeans(i) rainMeans(i) 0], rainBarFaceColour);
    upperSDLines(i) = line([barGap/2, 50 - barGap/2] + 50*(i-1), (rainMeans(i) + rainSDs(i)) * [1 1], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-');
    lowerSDLines(i) = line([barGap/2, 50 - barGap/2] + 50*(i-1), (rainMeans(i) - rainSDs(i)) * [1 1], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '-');
    
end