% Trigger object is really a list of Conditions.
% The constructor for a Trigger can set up a number of typical triggers
% though.
classdef Trigger < handle
    
    properties
        
        conditions = {}; 
    
    end
    
%     events
%        conditionsChanged 
%     end
%     
    methods
        
        % Can use the constructor to specify a type, but usually this will
        % be the 'emptyTrigger' type, with conditions filled in after the
        % creation of the Trigger. If no type given, you get an
        % emptyTrigger anyway.
        function t = Trigger(type)
        
            if nargin == 0
                t.conditions{1} = NeverCondition('Cond 1');
            elseif ischar(type)
               
                switch type
                    
                    case 'emptyTrigger'
                        t.conditions{1} = NeverCondition('Never', 'Cond 1');
                    
                    case 'Annual Planting Event'
                        t.conditions{1} = MonthBasedCondition('Month Based');
                        t.conditions{1}.monthIndex = 3;
                        t.conditions{2} = TimeIndexedCondition('Is Rotation Year');
                        t.conditions{2}.indexType = 'Year';
                        t.conditions{2}.indices = 1:2:50;
                        t.conditions{3} = AndOrNotCondition('C1 AND C2');
                        t.conditions{3}.logicType = 'And';
                        t.conditions{3}.indices = [1 2];
                        
                    case 'Annual Harvesting Event'
                        t.conditions{1} = MonthBasedCondition('Month Based');
                        t.conditions{1}.monthIndex = 12;
                        t.conditions{2} = EventHappenedPreviouslyCondition('Planting happened this year');
                        t.conditions{2}.eventName = 'Planting';
                        t.conditions{2}.comparator = '<=';                        
                        t.conditions{2}.monthsPrior = 12;
                        t.conditions{3} = AndOrNotCondition('C1 AND C2');
                        t.conditions{3}.logicType = 'And';
                        t.conditions{3}.indices = [1 2];
                        
                end % end switch
                
            else
                error('Trigger constructor takes one string argument.');                
            end            
        end % end constructor
        
        function cropNameHasChanged(obj, previousName, newName)
           for i = 1:length(obj.conditions) 
              obj.conditions{i}.cropNameHasChanged(previousName, newName); 
           end
        end
        
%                 % The refresh method is a necessary hack to get things to load
%         % properly after we saved lots of ImagineConditions. Now,
%         % ImagineCondition is Abstract, and that complicates things.
%         function obj = refresh(obj)
%            if ~isempty(obj.oldData)
%               if all(isfield(obj.oldData, {'conditionType', 'shorthand', 'string1', 'string2', 'value1', 'value2', 'parameters1String', 'parameters2String', 'stringComp', 'valueComp'}));
%                   obj =  ImagineCondition.newCondition(obj.oldData.conditionType, obj.oldData.shorthand);                  
%                   obj.setupFromOldStructure(obj.oldData);
%                   return;          
%               end
%               assignin('base', 'conditionStruct', obj);
%               error('Couldn''t figure out how to load a old version of condition. Assigned loaded object as struct conditionStruct in workspace.');
%            end
%         end
        
    end
    
    properties
        
    end
    
    methods(Static) 
       
        function t = loadobj(s)
            if isa(s.conditions, 'OldImagineCondition')  
               % Then we hope that the loadobj method of the
               % ImagineCondition has secreted the real data away in
               % ImagineCondition's private property 'oldData'.
               % Therefore, refresh should bring it into the light.
               newConds = {};
               for i = 1:length(s.conditions)
                   cond = ImagineCondition.newCondition(s.conditions(i).oldData.conditionType, s.conditions(i).oldData.shorthand);                  
                   cond.setupFromOldStructure(s.conditions(i).oldData);
                   newConds{i} = cond;
               end
               s.conditions = newConds;
               t = s;
               return;
            end
            t = s;
        end
        
        function valid = isValid(trig)
           valid = isa(trig, 'Trigger');
           if valid
              valid = ~isempty(trig.conditions);
              for i = 1:length(trig.conditions)
                  trigValid = trig.conditions{i}.isValid();
                  valid = valid && trigValid;                  
              end
           end
        end % end isValid
        
    end
        
end
