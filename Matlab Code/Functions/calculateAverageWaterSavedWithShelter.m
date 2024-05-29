function avWaterSaved = calculateAverageWaterSavedWithShelter(paddockLength, paddockWidth, treeHeight, openPaddockEvap, windDirectionOffBelt)

% windDirectionOffBelt is given in degrees.
% lookupTable gives percentage of open paddock evap as a function of
% distance into paddock.

% The shelter extends into the paddockWidth. If paddock width is less than the 
% open paddock distance, then there will be benefit across the whole
% paddock.
% If not, there's a benefit within the sheltered area and we average across
% the entire paddock.

paddockArea = paddockLength * paddockWidth;

evapTableTreeHeights = [0.5, 1.5, 5, 8, 12, 20];
evapTableDistances = evapTableTreeHeights * treeHeight;

evapDistanceDiffs = diff([0 evapTableDistances]);

evapTablePercentageEvaps = [0.432303615, 0.362054278, 0.178325241, 0.118883494, 0.054037952, 0];

A = [evapTablePercentageEvaps 0];
B = [evapTablePercentageEvaps(1) evapTablePercentageEvaps];
C = (A + B) / 2;

openPaddockDistance = evapTableTreeHeights(end) * treeHeight;

% calculate average over sheltered area
% then calculate average over total area.

nonShelteredArea = 0;
if paddockWidth > openPaddockDistance
    shelteredDistance = openPaddockDistance;
    nonShelteredArea = (paddockWidth - openPaddockDistance) * paddockLength;
else
    shelteredDistance = paddockWidth;
end 
shelteredArea = shelteredDistance * paddockLength;


shelteredAreaTotal = 0;
for i = 1:length(evapTableDistances)
   if ( evapTableDistances(i) < shelteredDistance)
       shelteredAreaTotal = shelteredAreaTotal + C(i) * evapDistanceDiffs(i);
   else
       coverage = shelteredDistance - evapTableDistances(i-1);
       shelteredAreaTotal = shelteredAreaTotal + C(i) * coverage;
   end
end

avPercentageSavedInShelteredArea = shelteredAreaTotal / shelteredDistance;

% shelteredArea as 
avWaterSaved = avPercentageSavedInShelteredArea * shelteredArea / paddockArea * openPaddockEvap;


