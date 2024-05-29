% The Time Index Based Condition defines a set of points in time in a sim
% and the condition is true if the sim is at one of those points.

classdef TimeIndexedCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType 
       figureName
       handlesField
   end
   
   properties (Constant)
      indexChoices = {'Month', 'Year'}; 
   end

   % Define the properties for the TimeIndexedCondition
   properties
       % Should be 'Month' or 'Year'
       indexType

       % The months or years that set this condition to be true.
       indices       
   end
    
   methods
      
       function type = get.conditionType(obj)
          type = 'Time Index Based'; 
       end
              
       function fn = get.figureName(obj)
          fn = 'conditionPanel_TimeIndexBased.fig'; 
       end
       
       function fn = get.handlesField(obj)
          fn = 'TimeIndexBasedHandles'; 
       end
       
       function obj = TimeIndexedCondition(shorthand)                     
              obj = obj@ImagineCondition(shorthand);
              
              obj.indexType = 'Year';
              obj.indices = [];
       end
       
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end

       function lh = getLonghand(obj)
                       
           % Check for year or month.
           switch obj.indexType                
                case 'Year'
                    lh = 'Year Index is ';
                case 'Month'
                    lh = 'Month Index is ';
               otherwise
                   error('Unrecognised indexType.')
           end
                      
           if isempty(obj.indices)
              lh = [lh, '?'];
              return
           end
           
            % Check for uniform spacing.
            obj.indices = sort(unique(obj.indices));
            spacing = length(unique(diff(obj.indices)));
            
            if spacing == 0
                % One element
                lh = [lh, num2str(obj.indices)];
            elseif spacing == 1
                % Spacing is uniform
                if length(unique(obj.indices)) >= 2
                    %Normal uniform
                    lh = [lh, num2str(obj.indices(1)), ', ', num2str(obj.indices(2)), ', ..., ', num2str(obj.indices(end))];
                else
                    % 2 elements
                    lh = [lh, num2str(obj.indices(1)), ' or ', num2str(obj.indices(2))];
                end                
            else
                % Spacing is non-uniform
                lh = [lh, 'one of ', num2str(obj.indices)];
            end
       end
              
       % Loads a set of controls into the panel and returns the handles to
       % them as subHandles.
       function loadCondition(obj, panel)
           
           % First find our controls in handles.
           % If they're not there, there's an error.
           handles = guidata(panel);
           
           if isfield(handles, obj.handlesField)
               newControls = handles.(obj.handlesField);
           else
                error('The panel provided lives in a figure that doesn''t have the requisite controls to load the condition data into.');
           end
           
           set(newControls.popupmenuIndexType, 'String', obj.indexChoices);
           ix = find(strcmp(obj.indexChoices, obj.indexType), 1, 'first');
           if isempty(ix)
               ix = 1;
           end
           set(newControls.popupmenuIndexType, 'Value', ix);
           
           set(newControls.editIndices, 'String', num2str(obj.indices));
           
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
           
           obj.indexType = obj.indexChoices{get(newControls.popupmenuIndexType, 'Value')};
           obj.indices = str2num(get(newControls.editIndices, 'String'));
           
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
           % Initialise all trigger checks with nan to indicate that it
           % can't be found at this point.
           TF = nan;
           
           % Expect in the current monthIndex and year.
           if nargin == 3
               monthIndex = varargin{1};
               yearIndex = varargin{2};
               switch obj.indexType                
                case 'Year'
                    TF = any(obj.indices == yearIndex);
                case 'Month'
                    TF = any(obj.indices == monthIndex);
               end
           else
               error('TimeIndexedCondition: isTriggered expects 2 arguments other than itself - the sim''s monthIndex and yearIndex.');
           end           

       end
       
   end
   
   methods
          %            if all(isfield(s, {'conditionType', 'shorthand', 'string1', 'string2', 'value1', 'value2', 'paraemters1String', 'parameters2String', 'stringComp', 'valueComp'}));

       function setupFromOldStructure(obj, s)
           obj.indexType = s.string1{s.value1};
           obj.indices = str2num(s.string2);
       end
               
       function valid = isValid(cond)
            valid = isValid@ImagineCondition(cond);
            valid = valid && isa(cond, 'TimeIndexedCondition');
            valid = valid && ischar(cond.indexType);
            valid = valid && isnumeric(cond.indices);
            valid = valid && length(cond.indices) >= 1;
            if (valid)
                valid = valid && any(strcmp(cond.indexType, cond.indexChoices));
                valid = valid && all(cond.indices > 0);
            end
       end % end isValid
        
   end
end
    