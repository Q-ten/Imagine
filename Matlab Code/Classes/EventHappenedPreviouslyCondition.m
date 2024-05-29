% The Event Happened Previously Condition defines an event which, if it was
% triggered at a certain time previously will cause this condition to be true.

classdef EventHappenedPreviouslyCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType 
       figureName
       handlesField
   end
   
   properties (Constant)
      comparatorOptions = {'=', '<', '>', '<=', '>='};
   end

   % Define the properties for the EventHappenedPreviouslyCondition
   properties
       % eventName to check against
       eventName

       % The months prior that the event happening should be checked against.
       monthsPrior
       
       % A string that will be one of {'<', '>', '<=', '>=', '='}
       % Allows for at least X months prior, or exactly X months prior,
       % or less than X months prior.
       comparator
   end
    
   methods
      
       function type = get.conditionType(obj)
          type = 'Event Happened Previously'; 
       end
                     
       function fn = get.figureName(obj)
          fn = 'conditionPanel_EventHappenedPreviously.fig'; 
       end
       
       function fn = get.handlesField(obj)
          fn = 'PreviousEventHandles'; 
       end
       
       function obj = EventHappenedPreviouslyCondition(shorthand)                     
              obj = obj@ImagineCondition(shorthand);
              
              obj.eventName = '';
              obj.comparator = '=';
              obj.monthsPrior = 0;
       end
       
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end

       function lh = getLonghand(obj)
            
            if isempty(obj.eventName)
                lh = '[No event chosen]';
                return
            end
            
            switch obj.comparator
                
                case '='
                    compString = 'exactly ';
                case '<'
                    compString = 'less than ';
                case '<='
                    compString = 'less than or exactly ';
                case '>='
                    compString = 'more than or exactly ';
                case '>'
                    compString = 'more than ';
                otherwise
                    compString = 'Compstring not recognised';
            end
            
            if isempty(obj.monthsPrior)
                numString = '?';
            else
               numString = num2str(obj.monthsPrior);
            end
            
            lh = [obj.eventName, ' event occurred ', compString,  numString, ' months prior'];
       end
       
       % Loads a set of controls into the panel and returns the handles to
       % them as subHandles.
       function loadCondition(obj, panel, varargin)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           if nargin == 3
                eventNames = varargin{1};
           else
               error('Need to pass in the list of event names.');
           end
          
           
           % Now to start populating the controls.

           set(newControls.popupmenuEventChoice, 'String', eventNames);
           ix = find(strcmp(obj.eventName, eventNames), 1, 'first');
           if isempty(ix)
               ix = 1;
           end           
           set(newControls.popupmenuEventChoice, 'Value', ix);
           
           set(newControls.popupmenuComparator, 'String', obj.comparatorOptions);
           ix = find(strcmp(obj.comparator, obj.comparatorOptions), 1, 'first');
           if isempty(ix)
               ix = 1;
           end           
           set(newControls.popupmenuComparator, 'Value', ix);
           
           set(newControls.editMonthsPrior, 'String', num2str(obj.monthsPrior));
           
           handles.(obj.handlesField).data.monthsPrior = obj.monthsPrior;
           guidata(panel, handles);

       end
       
        % Uses the controls in subHandles to extract the parameters that
        % define this condition.
       function saveCondition(obj, panel)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           eventNames = get(newControls.popupmenuEventChoice, 'String');
           if isempty(eventNames)
                obj.eventName = '';
           else
               obj.eventName = eventNames{get(newControls.popupmenuEventChoice, 'Value')};
           end
           obj.comparator = obj.comparatorOptions{get(newControls.popupmenuComparator, 'Value')};
           obj.monthsPrior = str2num(get(newControls.editMonthsPrior, 'String'));
           
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
           % Initialise all trigger checks with nan to indicate that it
           % can't be found at this point.
           TF = nan;
           
           % Expect in the current monthIndex.
           if nargin == 3
               simMonthIndex = varargin{1};
               occurrences = varargin{2};
               % We assume the occurences are ordered. So we wont find an
               % occurrence later in the list if it's month is less than
               % one we've already seen.

               switch obj.comparator

                case '='
                    % Can have multiple months. The others can only
                    % have one and be valid.
                    monthIndiciesToCheck = simMonthIndex - obj.monthsPrior;

                case '<='
                    % Ok
                    monthIndiciesToCheck = [1: simMonthIndex - obj.monthsPrior];

                case '>='
                    % OK.
                    monthIndiciesToCheck = [simMonthIndex - obj.monthsPrior:simMonthIndex];                        

                 case '<'
                    % OK. If it happened less than one month ago, it could
                    % only have happened in this month. -1 + 1 cancel
                    % out.
                    monthIndiciesToCheck = [simMonthIndex - obj.monthsPrior + 1:simMonthIndex];     

                case '>'
                     % OK. If it happened more than one month ago, (2
                     % months ago or earlier) we'd have current - 1 -1.
                     monthIndiciesToCheck = [1: simMonthIndex - obj.monthsPrior - 1];

                 otherwise
                     error('Error in Simulation.isTriggered, Event Happened Previously. Unrecognised comparator.');

               end

                % Check all previous events for matching the required
                % criteria.
                TF = false;
                for i = 1:length(occurrences)
                     oc = occurrences(i);
                     ocMonthIndex = oc.monthIndex;
                     if any(ocMonthIndex == monthIndiciesToCheck)
                         if strcmp(obj.eventName, oc.eventName)
                            TF = true;
                            break;
                         end
                     end 
                end                   
           else
               error('EventhappenedPreviouslyCondition: isTriggered expects 2 arguments other than itself - the sim''s monthIndex and the plantedCrop''s occurrences.');
           end           
       end
       
   end
   
   methods
              
       function setupFromOldStructure(obj, s)
          obj.comparator = s.stringComp{s.valueComp};
          obj.eventName = s.string1{s.value1};
          obj.monthsPrior = str2num(s.string2);
       end

       function valid = isValid(cond, varargin)
            valid = isValid@ImagineCondition(cond);
            valid = valid && isa(cond, 'EventHappenedPreviouslyCondition');
            valid = valid && ischar(cond.eventName);
            valid = valid && isnumeric(cond.monthsPrior);
            if ~valid
                return
            end
            valid = valid && ~isempty(cond.eventName);
            valid = valid && ~isempty(cond.monthsPrior);
            valid = valid && length(cond.monthsPrior) == 1;
            valid = valid && all(cond.monthsPrior >= 0);
            if ~valid
                return
            end
            
            % Accepts in an optional list of eventNames to check against.
            if nargin == 3
               eventNames = varargin{1}; 
               thisEvent = varargin{2};
               if (cond.monthsPrior == 0)
                   thisEventIndex = find(strcmp(thisEvent, eventNames), 1, 'first');
                   if isempty(thisEventIndex)
                       error('You''ve passed in a list of event names that doesn''t contain the event name for this event.');
                   end
                   previousEventIndex = find(strcmp(cond.eventName, eventNames), 1, 'first');
                   if isempty(previousEventIndex)
                       error('You''ve passed in a list of event names that doesn''t contain the previous event name.');
                   end
                   % If the monthsPrior is 0, then the check will be on
                   % events this month. We're not that sophisticated yet,
                   % so we're only checking for events that have come
                   % before.
                   % So, the event's index has to be less than our own.
                   % In furture we might do something cleverer so we can
                   % check for events that come further down the list.
                   valid = valid && previousEventIndex < thisEventIndex;
               end
               valid = valid && any(strcmp(cond.eventName, eventNames));
            end

       end % end isValid

   end
    
end