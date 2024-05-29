% A Unit starts to abstract the idea of units that go with amounts.
% A unit has a specificName, a speciesName and a unitName.
% For example if we wanted to represent the unit part of 
% '50 tonnes of wheat' we would use the following unit:
% specificName: Wheat
% speciesName: Grain
% unitName: Tonne
%
% Units are to be used as components in Amounts and Rates.
%
classdef Unit < handle
 
    properties
        specificName
        speciesName
        unitName
    end
    
    properties(Dependent)
       readableDenominatorUnit 
       readableUnit
    end
    
    methods
       
        function u = Unit(specificName, speciesName, unitName)
           
            if nargin > 0
                
                if nargin ~= 3
                    error('Must pass 0 or 3 string arguments to the Unit constructor.');
                end
            
              if ischar(specificName)
                  u.specificName = specificName;
              else
                  error('Must pass a string as the first argument (specificName) to the Unit constructor.');
              end
              
              if ischar(speciesName)
                  u.speciesName = speciesName;
              else
                  error('Must pass a string as the second argument (speciesName) to the Unit constructor.');
              end
              
              if ischar(unitName)
                  u.unitName = unitName;
              else
                  error('Must pass a string as the third argument (unitName) to the Unit constructor.');
              end
            else
               u.specificName = '';
               u.speciesName = '';
               u.unitName = 'Unit';
            end
            
        end % end Unit constructor
                
        function TF = handleEq(u1, u2)
           TF = u1.eq(u2, 'handle'); 
        end
        
        % We will say that the units are equivalent if the species and
        % specific name are the same. Ideally, the unitName should be
        % convertible too. Basically, we want them equal if they are units
        % for the same kind of thing.
        function same = eq(u1, u2, compareType)
            
            if (nargin == 3)
                if strcmp(compareType, 'handle')
                   same = eq@handle(u1, u2); 
                   return
                end
            end
            
            if isempty(u1) || isempty(u2)
               same = false;
               return
            end
            
            if length(u1) == 1 && length(u2) == 1
                multi = 0;
            elseif length(u1) > 1 && length(u2) == 1
                multi = 1;
            elseif length(u1) == 1 && length(u2) > 1
                multi = 2;
            else
                error('Cannot check equality between two lists.');
            end
                
            if isa(u1, 'Unit') && isa(u2, 'Unit')

                switch multi
                    case 0                    
                        same = strcmp([u1.specificName, 'pad'], [u2.specificName, 'pad']) && strcmp(u1.speciesName, u2.speciesName);
                    case 1
                        same = and(strcmp({u1.specificName}, u2.specificName),  strcmp({u1.speciesName}, u2.speciesName));
                    case 2
                        same = and(strcmp(u1.specificName, {u2.specificName}), strcmp(u1.speciesName, {u2.speciesName}));
                end
                        
                        
%                if same
%                   % Perhaps ideally we should get Imagine to check that the
%                   % unitNames can be converted into the default unitName
%                   % for the species. That would mean that they are
%                   % measuring the same kind of thing. Since they have the
%                   % same species name, they must both convert to the
%                   % default species unit unless the units are invalid.                   
%                end
                    
            else
                 disp('eq in Unit: arguments passed are not both instances of the Unit class or subclass.');
            end
        end
        
        function diff = neq(u1, u2)
           diff = ~eq(u1, u2); 
        end
        
        function s = get.readableDenominatorUnit(obj)
            if strcmp(obj.unitName, 'Unit')
                if isempty(obj.speciesName)
                    s = '';
                else
                   s = ['per ', obj.speciesName]; 
                end
            else
               s = ['per ', obj.unitName, ' of ', obj.speciesName];
            end            
        end
        
        function s = get.readableUnit(obj)
            if strcmp(obj.unitName, 'Unit')
                if isempty(obj.speciesName)
                    s = '';
                else
                   if strcmp({'Percentage', 'Percent', 'percentage', 'percent', '%'},  obj.speciesName)
                       s = '%';
                       return
                   end
                   s = [obj.speciesName, 's']; 
                end
            else
               s = [obj.unitName, 's of ', obj.speciesName];
            end
            if strcmp(obj.unitName, 'Dollar')
                s = '$';
            end
        end
    end
    
    methods (Static)
       
        function valid = isValid(u)
            if ~isa(u, 'Unit')
               disp('Invalid Unit passed:'); 
               disp('Not an instance of the Unit class or subclass.'); 
               valid = 0;
               return
            end
        
            valid = 1;
            msg = {};
            if ~ischar(u.specificName)
               valid = 0;
               msg = {msg, 'specificName not a string.'};
            end
            if ~ischar(u.speciesName)
               valid = 0;
               msg = {msg, 'speciesName not a string.'};
            end
            if ~ischar(u.unitName)
               valid = 0;
               msg = {msg, 'unitName not a string.'};
            end
            
            if(~isempty(msg))
                disp('Invalid Unit passed.');
            end
            for i = 1:length(msg)
               disp(msg{i}); 
            end
        end
    end
end