% The And/Or/Not Condition defines a set of conditions that should be anded or orred or 
% negated to determine the truth of this condition. The other conditions
% will be provided externally.

classdef AndOrNotCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType  
       figureName
       handlesField
   end
   
   properties (Constant)
      logicChoices = {'And', 'Or', 'Not'}; 
   end
   
   % Define the properties for the AndOrNotCondition
   properties
       % Should be 'And' or 'Or' or 'Not'
       logicType

       % The condition indices that should be anded orred or negated.
       indices       
   end
    
   methods
      
       function type = get.conditionType(obj)
          type = 'And / Or / Not'; 
       end
                     
       function fn = get.figureName(obj)
          fn = 'conditionPanel_AndOrNot.fig'; 
       end
       
       function fn = get.handlesField(obj)
          fn = 'AndOrNotHandles'; 
       end
       
       function obj = AndOrNotCondition(shorthand)                     
              obj = obj@ImagineCondition(shorthand);
              
              obj.logicType = 'And';
              obj.indices = [];
       end
       
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end

       function lh = getLonghand(obj, lhs)
                       
           % For each condition being added or orred, get the condition
           % string, and bracket appropriately.
            
           if any(strcmp(obj.logicType, {'And', 'Or'}))
           
                lh = ['('];                                
                for j = 1:length(obj.indices)
                    if j > 1
                        % Add the 'AND' or 'OR' between conditions.
                        lh = [lh, ' ', obj.logicType, ' ']; 
                    end
                    % Put in the condition.
                    lh = [lh, lhs{obj.indices(j)}];              
                end
                lh = [lh, ')'];
                return
           elseif strcmp(obj.logicType, 'Not')               
               if length(obj.indices) < 1
                   lh = 'NOT [Select condition index]';
               elseif length(obj.indices) == 1
                   lh = ['NOT ' lhs{obj.indices(1)}];
               else
                  lh = 'NOT [Too many conditions entered. Choose 1.]';
               end
               return 
           end
           error('Shouldn''t get here as obj.logicType should always be one of And, Or, or Not. If you get here, check the capitalisation.')
       end
       
       % Loads a set of controls into the panel and returns the handles to
       % them as subHandles.
       function loadCondition(obj, panel, varargin)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           if nargin == 3
               conditionIndex = varargin{1};
           else
               error('AndOrNotCondition: loadCondition expects a third argument - the 1 based index of this condition in the list of conditions.');
           end
                       
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           set(newControls.popupmenuLogicType, 'String', obj.logicChoices);
           ix = find(strcmp(obj.logicChoices, obj.logicType), 1, 'first');
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuLogicType, 'Value', ix);
           
           set(newControls.editIndices, 'String', num2str(obj.indices));

           handles.(obj.handlesField).data.conditionIndex = conditionIndex;           
           handles.(obj.handlesField).data.indices = obj.indices;
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
           
           % If there is no data field in newControls, we must be in a
           % 'saveCondition' call that's been called before load condition.
           % We need to wait until loadCondition is called, then
           % saveCondiiton is called again. (Messy, but this works).
           if ~isfield(newControls, 'data')
               return
           end
           
           obj.logicType = obj.logicChoices{get(newControls.popupmenuLogicType, 'Value')};
           obj.indices = str2num(get(newControls.editIndices, 'String'));
           
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
           % Initialise all trigger checks with nan to indicate that it
           % can't be found at this point.
           TF = nan;         
           
           % Expect in the current monthIndex and year.
           if nargin == 3
               conditionIndex = varargin{1};
               conditionTruths = varargin{2};
               % Make sure all the indices are in a valid range. Just in
               % case they're not.
               rangedIndices = obj.indices(and(obj.indices > 0, obj.indices < conditionIndex));
               
               if length(conditionTruths) < conditionIndex
                   error('Must pass in the condition truths of all previous conditions in the list.');  
               end
               
               % Run through the list of conditions and check each one.
               if strcmp(obj.logicType, 'And')
                    TF = true;
                    for ix = 1:length(rangedIndices)
                        TF = TF && conditionTruths(rangedIndices(ix));
                    end                    
               elseif strcmp(obj.logicType, 'Or')
                    TF = false;
                    for ix = 1:length(rangedIndices)
                        TF = TF || conditionTruths(rangedIndices(ix));
                    end
               elseif strcmp(obj.logicType, 'Not')
                    % if multiple, take the first
                    TF = ~conditionTruths(rangedIndices(1));
               end       
           
           else
               error('TimeIndexedCondition: isTriggered expects 2 arguments other than itself - the conditions''s 1 based index and the list of condition truths of the previous conditions.');
           end           

       end           
       
   end
   
   methods
                    
       function setupFromOldStructure(obj, s)
           obj.logicType = obj.logicChoices{s.value1};
           obj.indices = str2num(s.string2);
       end
       
       function valid = isValid(cond, varargin)
            valid = isValid@ImagineCondition(cond);
            valid = valid && isa(cond, 'AndOrNotCondition');
            valid = valid && ischar(cond.logicType);
            valid = valid && isnumeric(cond.indices);
            if (valid)
                valid = valid && any(strcmp(cond.logicType, cond.logicChoices));
                valid = valid && ~isempty(cond.indices);
            end
            if strcmp(cond.logicType, 'Not')
               valid = valid && length(cond.indices) == 1; 
            end
            if ~valid
                return
            end
            % Accepts in an optional list of eventNames to check against.
            if nargin == 2
               conditionIndex = varargin{1};
               valid = valid && all(cond.indices < conditionIndex);
               valid = valid && all(cond.indices >= 1);  
               valid = valid && conditionIndex > 1;
            end
       end % end isValid
        
   end
end