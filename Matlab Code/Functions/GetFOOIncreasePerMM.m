function increasePerMM = GetFOOIncreasePerMM(peakFOOPerMMMonth, peakFOOPerMM, minFOOPerMMMonth, minFOOPerMM, month)
         

%          ____
%         /    \
%        |      \
%       /        \
%   .../          \...
%
% This is what the 'FOO per mm of rain' chart looks like over the course of
% a year. In summer you get more FOO per mm. In winter, you get less.
% This function defines this cycle with two half sine curves. 
% It's parameterised simply by setting the max growth rate, the min growth
% rate and the months in which these occur.
% To evaluate the rate for a month m (m could be a number of years in so we
% mod it.) we figure out where in the cycle we are and scale it all to
% work. It all gets scaled into a 0 to 2pi scale before a simple
% evaluation in a cos function. (Cos goes max to min to max over 2 pi).


    amp = (peakFOOPerMM - minFOOPerMM) / 2;
    C = minFOOPerMM + amp;

    maxToMinMonths = mod(minFOOPerMMMonth - peakFOOPerMMMonth, 12);
    minToMaxMonths = mod(peakFOOPerMMMonth - minFOOPerMMMonth, 12);
    increasePerMM = zeros(length(month), 1);
    for i = 1:length(month)
    
        m = month(i);
        
        % Which are we in? the max to min period or the min to max
        % period?            
        if (mod(m - peakFOOPerMMMonth, 12) < maxToMinMonths)
            % then we're in the period after the max.
            t = mod(m - peakFOOPerMMMonth, 12);
            increasePerMM(i) = cos(t / maxToMinMonths * pi) * amp + C;
        else
           % We're in the period after the min.
            t = mod(m - minFOOPerMMMonth, 12);
            increasePerMM(i) = cos(t / minToMaxMonths * pi + pi) * amp + C; 
        end
        
    end
    