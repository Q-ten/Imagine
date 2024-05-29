%
% SpatialInteractions object contains parameters to model water logging, competition
% and their impact at various rainfall levels.
%
classdef SpatialInteractions < handle

    properties
    
        useCompetition
 %       compReachFactor
        compYieldFactor
        compZeroImpactRainfall
        compMaxRainfallForFullImpact        
        % We're changing compReachFactor into 3 parameters
        % Root density
        % Row spacing
        % and relative radii.
        % The row spacing comes from the regime. We'll pass in the row
        % spacing in as a parameter as it's hard for the sis to be expected
        % to calculate it.
        
        rootDensity
        relativeRadii
        
        % We should not have a separate reach factor for the waterlogging
        % if we have the same roots.
        
        useWaterlogging
%        waterReachFactor
        waterYieldFactor
        waterZeroImpactRainfall
        waterMinRainfallForFullImpact
        
        useNCZ
        NCZChoice
        NCZFixedWidth
        NCZOptimisedParameters
        
        % Do we want include test area parameters?
        % Would include rainfall, agbm, bgbm.
        editParameters
        
        notes
    end
    
    methods (Static = true)

        function obj = loadobj(s)
            if isstruct(s)
                % Then s contains our fields. Need to copy across what is
                % there.
                % If it still contains the compReachFactor or
                % waterReachFactor, then we need to adjsut for the new
                % factors. We can estimate the parameters but print a
                % warning indicating the assumptions being made.
                obj = SpatialInteractions;
                fnames = fieldnames(s);
                for i = 1:length(fnames)
                   if (isprop(obj, fnames{i}))
                       obj.(fnames{i}) = s.(fnames{i});
                   else
                       warning(['Deprecated Property:', ' Property no longer supported in SpatialInteractions object: ', fnames{i}]);
                   end
                end
                
                if (isfield(s, 'compReachFactor') || isfield(s, 'waterReachFactor'))
                   % assume row spacing of 2m.
                   % assume rr of 0.4 (should be less than 1)
                   % calculate the assumed root density.
                   obj.relativeRadii = 0.4;
                   if (compReachFactor > 0)                       
                       obj.rootDensity = 4 / (pi * 2 * s.compReachFactor^2 * 0.4);
                   else
                       obj.rootDensity = 0.2;
                   end
                   warning(['Estimating Properties: ', ' compReachFactor and waterReachFactor no longer supported. Estimating relativeRadii as 0.4, and rootDensity as %f based on rowSpacing of 2m.'], obj.rootDensity);
                end
                
            else
                obj = s;
            end            
        end
 
    end
    
    methods
        
        % This method returns the percentage of full impact of the competition and
        % waterlogging effects.
        function [compImpact, waterImpact] = getImpact(sis, gsr)
            
            if sis.useCompetition
               if gsr <= sis.compMaxRainfallForFullImpact
                   compImpact = 1;
               elseif gsr >= sis.compZeroImpactRainfall
                   compImpact = 0;
               else
                   compImpact = 1 - ((gsr - sis.compMaxRainfallForFullImpact) / ...
                        (sis.compZeroImpactRainfall - sis.compMaxRainfallForFullImpact));
               end
            else
                compImpact = 0;
            end
   
            if sis.useWaterlogging
              if gsr >= sis.waterMinRainfallForFullImpact
                   waterImpact = 1;
               elseif gsr <= sis.waterZeroImpactRainfall
                   waterImpact = 0;
               else
                   waterImpact = (gsr - sis.waterZeroImpactRainfall) / ...
                        (sis.waterMinRainfallForFullImpact - sis.waterZeroImpactRainfall);
              end
            else
                waterImpact = 0;
            end
            if length(compImpact) > 1 || length(waterImpact) > 1
               a = 1; 
            end
            
        end
    
        % Calculates the y-int and x-int of the competition and
        % waterlogging spatial interaction curves, before clipping occurs.
        function [compExtent, compYieldLoss, waterExtent, waterYieldGain] = getRawSIBounds(sis, AGBM, BGBM, rowSpacing)        
            
            if sis.useCompetition                                
                %compExtent = sqrt(BGBM) * sis.compReachFactor;
                %compYieldLoss = AGBM / compExtent * sis.compYieldFactor;
                
                % New calculation
                compExtent = 2 * sqrt(BGBM / (pi * rowSpacing * sis.rootDensity * sis.relativeRadii));
                compYieldLoss = AGBM * sis.compYieldFactor;                
            else
                compExtent = 0;
                compYieldLoss = 0;
            end
            
            if sis.useWaterlogging
%                waterExtent = sqrt(BGBM) * sis.waterReachFactor;
%                waterYieldGain = AGBM / waterExtent * sis.waterYieldFactor;

                % New calculation
                waterExtent = 2 * sqrt(BGBM / (pi * rowSpacing * sis.rootDensity * sis.relativeRadii));
                waterYieldGain = AGBM * sis.waterYieldFactor;
            else
               waterExtent = 0;
               waterYieldGain = 0;
            end
        end
        
        % Uses the results from getImpact and getRawSIBounds, along with
        % the cost:income ratio to work out the optimal distance from the
        % stem that crops start breaking even. 
        %
        % Currently only based on the competition
        function breakEvenCroppingDist = calculateBreakEvenCroppingDistance(sis, compExtent, compRawYieldLoss, compImpact, ratio)
            
            if (ratio > 1)
               % In the case where expected costs are greater than income
               % (ratio > 1) then we're predicting that we should leave the
               % whole paddock fallow. 
               % We can indicate that by returning infinite or nan here.
                breakEvenCroppingDist = NaN;
                return
            end
            
            yint = compImpact * compRawYieldLoss;
            if (yint > ratio)
                breakEvenCroppingDist = (yint-ratio) / yint * compExtent;
            else
                breakEvenCroppingDist = 0;
            end
        end
        
    end
    
end