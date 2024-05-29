% An Amount is intended to abstract an amount of some real substance. So it
% is a quantity with a unit. This is meant to represent some real amount of
% 'stuff' so there is only one type of unit (albeit it could be something
% like Ha or squareM) but it is not a rate so there are no negative powers
% of things. Just the one positive, singular power like Ha, or Tonne. In
% Imagine, we will treat square meter as a single unit. Maybe we should
% change this later, but for now, we keep units of area seperate to units
% of length. We won't multiply length by lengths to get an area.
classdef Amount
    
   properties
      % The quantity.
      number = nan
      
      % The Unit that provides the type of thing and the unit it is
      % measured in.
      unit 
   end
    
   methods
       
       function amt = Amount(number, unit)
       
           if nargin > 0
              
              if nargin ~= 2
                   error('Must pass 0 or 2 arguments to the Amount constructor');
              end
                   
              if isnumeric(number)
                  amt.number = number;
              else
                  error('Must pass a number as first argument to Amount constructor');
              end
              
              if Unit.isValid(unit)          
                  amt.unit = unit;
              else
                 error('Must pass a valid Unit object as second argument to the Amount constructor.'); 
              end
           else
              amt.number = 0;
              amt.unit = Unit();
           end           
       end % end Amount constructor

       % Copies the Amount. The Rate has it's own copy function, so this
       % function will not be called for any Rates.
       function newAmt = copy(amt)
           newAmt = Amount(amt.number, amt.unit);
       end
       
       %
       % This is where we define the overloaded Matlab operators that are applicible to the Amount.
       %       
       % Use addable to check that we can add the inputs.
       function amt = plus(a1, a2)
           
           if assertAddable(a1, a2)
               amt = a1.copy;
               amt.number = a1.number + a2.number;
           end
           
       end
       
       % Tests that the inputs are 'addable' in that both are rates or both
       % are Amounts, and that the units match.
       % Throws an error if the two are not addable.
       function TF = assertAddable(a1, a2)
           if ~(isa(a1, 'Amount') && isa(a2, 'Amount'))
               error('Both inputs to Amount.plus/minus must be members of the Amount Class or a subclass such as Rate.');
           else
               if ~(a1.unit == a2.unit)
                   % Actually it would be nice if we could convert
                   % convertible units. But that can come later.
                   error('Both inputs to Amount.plus/minus must have identical units.');
               end
           end
           
           if (isa(a1, 'Rate') || isa(a2, 'Rate'))
               if ~(isa(a1, 'Rate') && isa(a2, 'Rate'))
                   error('If one of the inputs to Amount.plus/minus is a Rate, then both inputs must be.');
               else
                   if ~(a1.denominatorUnit == a2.denominatorUnit)
                       error('Both inputs to Amount.plus/minus must have identical denominatorUnits.');
                   end
               end
           end
           
           TF = true;
           
       end
       
       % Use addable to check that we can add the inputs.
       function amt = minus(a1, a2)
           if assertAddable(a1, a2)
               amt = a1.copy;
               amt.number = a1.number - a2.number;
           end
       end
       
       % This function requires that at least one of the amounts should be
       % a rate. The output amount will be a converted amount if one of the
       % amounts is a proper Amount (not a Rate) and in the case where both
       % are Rates, we will try to work out the new rate.
       % Note that the function will produce an error if the output amount
       % cannot be calculated.
       function amt = times(a1, a2)
           
           % We will rearrange the units so that they can be directly
           % multiplied.
           if ~(isa(a1, 'Amount') && isa(a2, 'Amount'))
               error('Both inputs to Amount.times must be members of the Amount Class or a subclass such as Rate.');
           end
           
           if ~(isa(a1, 'Rate') || isa(a2, 'Rate'))
               error('At least one of the inputs to Amount.times must be a member of the Rate Class');
           end

           if length(a1) > 1 || length(a2) > 1
               amt(size(a1)) = Amount();
               if length(a1) == length(a2)
                 % Then we element-wise multiply.
                 % Assume that we have at most two dimensions.
                 for i = 1:size(a1, 1)
                    for j = 1:size(a1, 2)
                       amt(i, j) = a1(i, j) * a2(i, j); 
                    end
                 end
                 return
              else
                  if length(a2) > length(a1)
                       % Then swap them.
                       temp = a1;
                       a1 = a2;
                       a2 = temp;
                  end
                  for i = 1:size(a1, 1)
                      for j = 1:size(a1, 2)
                        amt(i, j) = a1(i, j) * a2;
                      end
                      return
                  end                  
              end
           end
           
           % We want to organise it so that if only one is a Rate then it
           % goes second, and the Amount goes into a1.
           if isa(a1, 'Rate')
               % Then swap them.
               temp = a1;
               a1 = a2;
               a2 = temp;
           end

           % Now we want to make sure that they are around the right way
           % and that we can cancel a1.unit with a2.denominatorUnit
           problem = 0;
           if(a1.unit == a2.denominatorUnit)
               % then it's fine.
           elseif(a1.unit == a2.unit)
               % then invert a2
               a2 = a2.copy;
               a2.invert;
           elseif isa(a1, 'Rate')
               if (a1.denominatorUnit == a2.unit)
                   % then we swap the variables.
                   temp = a1;
                   a1 = a2;
                   a2 = temp;
               elseif (a1.denominatorUnit == a2.denominatorUnit)
                   % then we should invert the first one.
                   a1 = a1.copy;
                   a1.invert
               else
                   % Then there's a problem.
                   problem = 1;
               end
           else
               problem = 1;
               % Then there's a problem.
           end
           
           if problem
              error('Problem in Amount.times. Cannot find a common unit to cancel in inputs.'); 
           end
           
           % Now we should have the numerator of a1 and the denominator of
           % a2 being the same unit, and we can cancel them. We need to get
           % the multiplier though.
           ucm = UnitConvertor.getUnitConversionMultiplier(a1.unit.unitName, a2.denominatorUnit.unitName);
           
           % And now we can go ahead and create the new Amount.
           if isa(a1, 'Rate')
               % Then we know that they are both rates.
               amt = Rate(a1.number * a2.number * ucm, a2.unit, a1.denominatorUnit);
           else
               % Then we know that a1 is an Amount, and a2 is a Rate.
               amt = Amount(a1.number * a2.number * ucm, a2.unit);
           end
           
       end % end times(a1, a2)
       
       function amt = mtimes(a1, a2)
          
           if size(a1, 1) == 1 && size(a1, 2) == 1 && size(a2, 1) == 1 && size(a2, 2) == 1
               amt = times(a1, a2);
           else
               error('Matrix multiplication (''*'') only works on singleton matrices.');
           end
       end
       
       function same = eq(a1, a2)
           % Both rates
           if isa(a1, 'Rate') && isa(a2, 'Rate')
                same = all([a1.number == a2.number, a1.unit == a2.unit, a1.denominatorUnit == a2.denominatorUnit]);
           end
           % Only a1 a rate
           if isa(a1, 'Rate') && (~isa(a2, 'Rate'))
                same = 0;
           end
           % Only a2 a rate
           if (~isa(a1, 'Rate')) && isa(a2, 'Rate')
                same = 0;
           end
           % Neither a rate
           if (~isa(a1, 'Rate')) && (~isa(a2, 'Rate'))
                same = all([a1.number == a2.number, a1.unit == a2.unit]);
           end
           
       end
       
       function diff = neq(a1, a2)
            diff = ~eq(a1, a2);
       end
       
       
      end
   
    
    
end


   