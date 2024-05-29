% Defines an ImagineCondition.
% Ideally this will be an Abstract class with a delegate
% that takes care of all the settings. That way we can have many types of
% conditions.
% 
% However, for now we are going to make this a concrete class that deals
% with several types in the same object.

classdef ImagineCondition < handle
   
    properties 
%        conditionType
        shorthand
%        string1
%         value1
%         stringComp
%         valueComp
%         string2
%         value2
%         parameters1String
%         parameters2String
    end
    
%     properties %(Access = private)
%         oldData = [];
%     end
        
    properties (Abstract = true, Dependent)
       conditionType           
       
       % The name of the figure that contains the controls that will be
       % used to set up the condition
       figureName
       
       % The name to give the field in handles that will contain the
       % controls loaded from the figure.
       handlesField     
    end

    methods (Abstract)

        % If an imagineCondition ever mentions another crop, then we
        % need to be able to update its name here.
        cropNameHasChanged(obj, previousName, newName);

        % Returns a longhand expression of the condition.
        % Most cases will not require any arguments.
        % The And/Or/Not condition requires inputs of other condition
        % longhands.
        lh = getLonghand(obj, varargin);
        
        % Loads a set of controls into the panel and returns the handles to
        % them as subHandles.
        loadCondition(obj, panel, varargin);
        
        % Uses the controls in subHandles to extract the parameters that
        % define this condition.
        saveCondition(obj, panel);
               
        % A general method for determining if the condition is true.
        TF = isTriggered(obj, varargin);
        
        % The new condition objects will have a method to load their
        % parameters from the fields of old data.
        setupFromOldStructure(obj, s);
        
    end
    
    methods 

        % Pass the type (eg Time Index Based) and the shorthand (eg Cond 1)
        % to the constructor.
        function cond = ImagineCondition(shorthand)
           
%             if nargin == 2
%                 if ischar(type)
%                     
%                     cond.conditionType = type;
%                     
%                     comparatorList = {'=', '<', '>', '<=', '>='};
%                     monthList = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%                     
%                     cond.shorthand = '';
%                     cond.string1 = '';
%                     cond.value1 = 1;
%                     cond.stringComp = '';
%                     cond.valueComp = 1;
%                     cond.string2 = '';
%                     cond.value2 = 1;
%                     cond.parameters1String = '';
%                     cond.parameters2String = '';
% 
%                     switch type
%                     
%                         case 'Time Index Based'
%                            
%                             cond.string1 = {'Year', 'Month'};
%                             cond.stringComp = comparatorList;
%                            
%                         case 'Month Based'
%                             
%                             cond.stringComp = 'Month is';
%                             cond.string2 = monthList;
%                             
%                         case 'Event Happened Previously'
%                             
%                             cond.stringComp = comparatorList;
%                             
%                         case 'Quantity Based'
%                             
%                             cond.string1 = {'Above ground biomass', 'Below ground biomass', 'Total biomass', 'Rainfall over period'};
%                             cond.stringComp = comparatorList;
%                             
%                         case 'AND / OR / NOT'
%                             
%                             cond.shorthand = '';
%                             cond.string1 = {'AND', 'OR', 'NOT'};
%                             cond.value1 = 1;
%                             cond.stringComp = '';
%                             cond.valueComp = 1;
%                             cond.string2 = '';
%                             cond.value2 = 1;
%                             cond.parameters1String = '';
%                             cond.parameters2String = '';
%                             
%                         case 'Never'
%                             
%                             cond.shorthand = '';
%                             cond.string1 = '';
%                             cond.value1 = 1;
%                             cond.stringComp = '';
%                             cond.valueComp = 1;
%                             cond.string2 = '';
%                             cond.value2 = 1;
%                             cond.parameters1String = '';
%                             cond.parameters2String = '';
%                             
%                         otherwise
%                             
%                             error('Condition type not recognised in constructor.');
%                             
%                     end % end switch
%                     
%                 else
%                     error('First argument to ImagineCondition constructor must be a string.'); 
%                 end
%             else
%                error('Must pass in two strings argument to ImagineCondition constructor.'); 
%             end
            
            if ischar(shorthand)
               cond.shorthand = shorthand; 
            else
               error('First argument to ImagineCondition constructor must be a string.'); 
            end
            
        end % end constructor
    

        function newControls = loadConditionControls(obj, panel, offset)
 
           if nargin < 3
               offset = [0,0];
           else
               if length(offset) ~= 2
                   offset = [0,0];
               end
           end
            
           % First load the controls into the panel and add the offset 
           handles = guidata(panel);
           newControls = [];
            % Load the first page fig.
            td = load(obj.figureName, '-MAT');
            if(~isempty(td.hgS_070000.children))
                hs =  struct2handle(td.hgS_070000.children, repmat(panel, length(td.hgS_070000.children), 1), 'convert');
             %   callbackToUseSubHandles(hs, obj.handlesField);
                newControls = grabHandles(hs);
            
                % Set each control's units to pixels and add the position
                % offset.
                for i = 1:length(hs)
                    cb = get(hs(i), 'Callback');
                    set(hs(i), 'Callback', ...
                    @(hObject,eventdata)(cellfun(@(x)feval(x,hObject,eventdata), ...
                   {cb, ...
                    @(hObject,eventdata)triggerPanel('saveCondition', getfield(guidata(hObject), 'subHandles')), ...
                    @(hObject,eventdata)triggerPanel('loadCondition', getfield(guidata(hObject), 'subHandles'))})));
                    
                    set(hs(i), 'Units', 'pixels');
                    pos = get(hs(i), 'Position');                    
                    set(hs(i), 'Position', pos + [offset(1), offset(2), 0, 0]);                    
                end

            end
                        
            % Use combine fields so that all the controls will be removed when we load
            % another step.
%            subHandles = combineFields(subHandles, trendHandles);
            % We don't need to do this. Instead ask the condition to remove
            % its own controls.
            % When whatever is controlling the import of these controls
            % wants them gone - they have but to ask. Pass in the panel
            % again, and we'll get the handles and remove the fields.

            handles.(obj.handlesField) = newControls;            
            guidata(panel, handles);
             
        end
        
        function TF = removeConditionControls(obj, panel)            
            % Get the list of all the handles for the figure containing
            % panel.
            handles = guidata(panel);
            
            % Check that handles actually has the controls in it.
            if ~isfield(handles, obj.handlesField)
                TF = false;
                return
            end
            
            % Pull out the field that has our added controls in it.
            newControls = handles.(obj.handlesField);
            
            % We use a special field called data to store non-handle
            % fields. These fields will be able to take on any value
            % (including values that evaluate to handles, like 0).
            % We remove the data field before calling remveHandles because
            % removeHandles wouldn't be able to tell the difference between
            % a data field of 0 and the root handle, and would try and
            % delete it.
            if isfield(newControls, 'data')
                newControls = rmfield(newControls, 'data');
            end
            
            % Delete all the controls that are child fields of newControls.
            removeHandles(newControls);
            
            % Get rid of the field that listed the new controls from
            % handles. (Puts handles back as it was)
            handles = rmfield(handles, obj.handlesField);
            
            % Save the undone handles struct
            guidata(handles.figure1, handles);
            TF = true;
        end
        
    end
    
    methods
        
        % This method should eventually do a lot more than this. It should
        % check for the validity of the condition parameters based on the
        % conditionType.
        function valid = isValid(cond)
            valid = isa(cond, 'ImagineCondition');            
        end % end isValid
        
    end
    
    methods (Static)
        function cond = loadobj(s) 
            if isstruct(s)
                cond = OldImagineCondition(s);
            else
                cond = s;                
            end
        end
         
        function cond = newCondition(type, shorthand)
           switch type
           
            case 'Time Index Based'
                cond = TimeIndexedCondition(shorthand);
            case 'Month Based'
                cond = MonthBasedCondition(shorthand);    
            case 'Event Happened Previously'
                cond = EventHappenedPreviouslyCondition(shorthand);
            case 'Quantity Based'        
                cond = QuantityBasedCondition(shorthand);    
            case 'AND / OR / NOT'
                cond = AndOrNotCondition(shorthand);    
            case 'AND / OR'
                cond = AndOrNotCondition(shorthand);    
            case 'And / Or / Not'
                cond = AndOrNotCondition(shorthand);    
            case 'And / Or'
                cond = AndOrNotCondition(shorthand);  
            case 'Never'
                cond = NeverCondition(shorthand);
            otherwise
                error('Trying to create a condition with unknown type.');
         
           end
        end
    end
    
end