function yearlyAttributions = attributePaddockProductivity(dates, numbers, MEIntake, paddockNumbers)

% MEIntake is a daily record of the herbage MEIntake for main and young
% flock in columns 1 and 2 respectively. 
% PaddockNumbers contains the paddock that each class is in. If a class has
% no specific paddock number, then it assumed to be in the main paddock in
% the first column. Yearlings and weaners can be in different paddocks, but
% the main flock - the ewes and wethers are in the same paddock.

% We need to work out how much ME Intake can be apportioned to each paddock
% each day, then added up for the year. Then we work out the percentage
% contribution of each paddock for each year.

% MEIntake has the MEIntake for each day in MJ / head - for main flock and
% for young flock.

% This means adults and the yearlings intake per head is the main flock
% number. The weaners are the young flock number. We work out the total for
% each class based on the numbers. We work out the paddock it comes from
% based on the paddock number for that class. Then we have enough to assign
% the MEIntake for that paddock that day.

% Size (rows) of all inputs must match.

sizes = [size(dates, 1), size(numbers, 1), size(MEIntake, 1), size(paddockNumbers, 1)];
if ~all(sizes == sizes(1))
   error('All inputs to apportionPaddockProductivity must have the same number of rows.'); 
end

  [y, ~, ~] = datevec(dates, 'dd/mm/yyyy');

  mainME = MEIntake(:, 1);
  youngME = MEIntake(:, 2);
  dailyMEIntakePerHeadByClass = [mainME, mainME, youngME, mainME, mainME, youngME];
  dailyMEIntakeByClass = dailyMEIntakePerHeadByClass .* numbers;

  paddockCount = max(max(paddockNumbers));
  years = y(end) - y(1) + 1;
  paddockBins = zeros(years, paddockCount);
  
  yearIndex = 1;
  for i = 1:length(y)
     
      if (i > 1)
          if (y(i) ~= y(i-1))
              yearIndex = yearIndex+1;
          end
      end
      
      intakes = dailyMEIntakeByClass(i, :);
      dailyPaddockNumbers = paddockNumbers(i, :);
      
      % for each day, add the MEIntake for the paddock to the paddockBin.
      for j = 1:length(intakes)   
          if ~isnan(intakes(j))
              if (intakes(j) > 0)
                  paddNum = dailyPaddockNumbers(j);
                  if (isnan(paddNum))
                      paddNum = dailyPaddockNumbers(1);
                  end
                  if (paddNum == 0)
                      continue
                  end
                  paddockBins(yearIndex, paddNum) = paddockBins(yearIndex, paddNum) + intakes(j);
              end          
          end
      end      
  end

  
  yearlyAttributions = paddockBins ./ repmat(sum(paddockBins, 2), 1, paddockCount);
