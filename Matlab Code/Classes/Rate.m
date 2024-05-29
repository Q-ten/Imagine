% This class abstracts the notion of a rate; something in terms of another
% thing. A conversion factor. It subclasses Amount, which already has a
% number and a numerator. The Rate adds a denominator.
classdef Rate < Amount
    
   properties

       % A Unit that extends the Amount class to provide a denominator.
       denominatorUnit
       
   end           
   
   methods
       
       % Returns an array of Rates, as big as number is (up to 2 dimensions), with the units
       % given by numeratorUnit and denominatorUnit.
       function amt = Rate(number, numeratorUnit, denominatorUnit)
                     
              amt = amt@Amount();


              
              if nargin == 3
                  if isnumeric(number)
                      amt.number = number;
                  else
                      error('Must pass a number as first argument to Amount constructor');
                  end

                  if Unit.isValid(numeratorUnit)          
                      amt.unit = numeratorUnit;
                  else
                     error('Must pass a valid Unit object as second argument to the Amount constructor.'); 
                  end

                  if Unit.isValid(denominatorUnit)          
                      amt.denominatorUnit = denominatorUnit;
                  else
                     error('Must pass a valid Unit object as third argument to the Rate constructor.'); 
                  end
                  
                  % Make a larger array if an array is passed in.
                  m = size(number,1);
                  n = size(number,2);
                  if m > 1 || n > 1
                      % Pre-allocate array, setting the units. Use for loop
                      % to set the number.
                      amt = repmat(amt, m, n);
                      for i = 1:m
                         for j = 1:n
                            % Set each value
                            amt(i,j).number = number(i,j);
                         end
                      end
                  end
                  
              elseif nargin == 0
                  % Initialise to 1 Unit / Unit if no arguments are given.
                  % It's a valid Rate, but gives no inforamtion.
                  % Multiplying by this rate should do nothing.
                  amt.number = 1;
                  amt.unit = Unit();
                  amt.denominatorUnit = Unit();
              else
                  error('Must pass 0 or 3 arguments to the Rate constructor: a number, a numerator unit and a denominator unit.');
              end
       end % end Rate constructor
       
       function newAmt = invert(amt)
          
           if (amt.number == 0)
               error('Cannot invert an zero Rate.');
           end
           newAmt = Rate(1 / amt.number, amt.denominatorUnit, amt.unit);
           
       end
       
       % Copies the Rate. 
       function newAmt = copy(amt)
           newAmt = Rate(amt.number, amt.unit, amt.denominatorUnit); 
       end       
   end
   
end