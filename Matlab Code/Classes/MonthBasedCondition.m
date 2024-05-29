% The Month Based Condition will be true whenever the sim is in the selected month.

classdef MonthBasedCondition < ImagineCondition
    
   % Implement the abstract properties from ImagineCondition
   properties (Dependent)      
       conditionType  
       figureName
       handlesField
   end
   
   % Define the properties for the MonthBasedCondition
   properties
       % The monthIndex for which this condition is true.
       monthIndex
   end
   
   properties (Constant)
       monthStrings = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
   end
    
   methods
      
       function type = get.conditionType(obj)
          type = 'Month Based'; 
       end
                     
       function fn = get.figureName(obj)
          fn = 'conditionPanel_MonthBased.fig'; 
       end
     
       function fn = get.handlesField(obj)
          fn = 'MonthBasedHandles'; 
       end
       
       function obj = MonthBasedCondition(shorthand)                     
              obj = obj@ImagineCondition(shorthand);
              
              obj.monthIndex = [];
       end
       
       % If an imagineCondition ever mentions another crop, then we
       % need to be able to update its name here.
       function cropNameHasChanged(obj, previousName, newName)
       end

       function lh = getLonghand(obj)
            if (obj.monthIndex >= 1 && obj.monthIndex <= 12)
                lh = ['Month is ', obj.monthStrings{obj.monthIndex}];           
            else
                lh = 'Invalid month definition.';
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
           
           % Now to start populating the controls.
           
           set(newControls.popupmenuMonthChoice, 'String', obj.monthStrings);
           set(newControls.popupmenuMonthChoice, 'Value', obj.monthIndex);
                      
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
           
           obj.monthIndex = get(newControls.popupmenuMonthChoice, 'Value');
       end
       
       % A general method for determining if the condition is true.
       function TF = isTriggered(obj, varargin)
           % Initialise all trigger checks with nan to indicate that it
           % can't be found at this point.
           TF = nan;
           
           % Expect in the current monthIndex.
           if nargin == 2
               simMonthIndex = varargin{1};
               try
                  TF = mod(simMonthIndex - 1, 12) == (obj.monthIndex - 1);
               end    
           else
               error('MonthBasedCondition: isTriggered expects 1 argument other than itself - the sim''s monthIndex.');
           end           
       end

   end
   
   methods%(Static)
                    
       function setupFromOldStructure(obj, s)
           obj.monthIndex = s.value2;
       end
       
       function valid = isValid(cond)
            valid = isValid@ImagineCondition(cond);
            valid = valid && isa(cond, 'MonthBasedCondition');
            valid = valid && isnumeric(cond.monthIndex);
            valid = valid && length(cond.monthIndex) == 1;
            if (valid)
                valid = valid && (cond.monthIndex >= 1 && cond.monthIndex <= 12);
            end
       end % end isValid
        
   end

end