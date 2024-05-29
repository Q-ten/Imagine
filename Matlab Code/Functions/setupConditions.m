%
%
% setupConditions contains information on the types of conditions, how to
% layout the controls for these conditions and how to evaluate the
% conditions.

function conditionTypeInfo = setupConditions()

conditionTypeInfo.samples = {TimeIndexedCondition(''), MonthBasedCondition(''), EventHappenedPreviouslyCondition(''), QuantityBasedCondition(''), AndOrNotCondition(''), NeverCondition('')};
conditionTypeInfo.types = {};
for i = 1:length(conditionTypeInfo.samples)
   conditionTypeInfo.types{i} = conditionTypeInfo.samples{i}.conditionType; 
end
%conditionTypeInfo.types = {'Time Indexed', 'Month Based', 'Event Happened Previously', 'Quantity Based', 'And / Or / Not', 'Never'};
conditionTypeInfo.classNames = {'TimeIndexedCondition', 'MonthBasedCondition', 'EventHappenedPreviouslyCondition', 'QuantityBasedCondition', 'AndOrNotCondition', 'NeverCondition'};
conditionTypeInfo.constructors = {@TimeIndexedCondition, @MonthBasedCondition, @EventHappenedPreviouslyCondition, @QuantityBasedCondition, @AndOrNotCondition, @NeverCondition};
              
           h1 =  ['The Time Based condition determines whether the year or month index match given values.', ...
               ' For example, it can check whether it''s the third year from the beginning of the regime,', ...
               ' or whether it''s the 18th month since the beginning of the regime.', ...
               ' If you select ''='' you can also specify a list of numbers from which it can match the year or month index.'];

           h2 = 'The Month Based condition determines whether a month matches the selected month.';
 
           h3 = ['This condition allows you to specify whether another event happened earlier and by how long. ', ...
               'You select the event that you care about and then enter then number of months after that event that you wish this ', ...
               'condition to be true.'];

           h4 =['This condition allows you to specify whether another event happened earlier and by how long. ', ...
               'You select the event that you care about and then enter then number of months after that event that you wish this ', ...
               'condition to be true.'];

           h5 = 'Choose the conditions from the list that you want AND''ed or OR''ed together. For example, an AND with ''1, 2'' would AND the first two conditions in the list.';
           
           h6 = 'The Never condition is never true.';
           
conditionTypeInfo.helpText = {h1, h2, h3, h4, h5, h6};

           % 
% % returns a structure containing the types of condition and how to layout
% % the controls.
% 
% c1.name = 'Time Index Based';
% c1.control1Style = 'popupmenu';
% c1.control1String = {'Year', 'Month'};
% c1.comparatorStyle = 'popupmenu';
% c1.comparatorString = {'=', '<', '>', '<=', '>='};
% c1.control2Style = 'edit';
% c1.control2String = '';
% c1.label1 = 'Index by';
% c1.label2 = 'Indices';
% c1.control1Width = 140;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c1.control2Width = 140;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% 
% %c1.control1Callback = '';
% c1.helpText = ['The Time Based condition determines whether the year or month index match given values.', ...
%                ' For example, it can check whether it''s the third year from the beginning of the regime,', ...
%                ' or whether it''s the 18th month since the beginning of the regime.', ...
%                ' If you select ''='' you can also specify a list of numbers from which it can match the year or month index.'];
% c1.parameters1Visible = 'No';
% c1.parameters2Visible = 'No';
% c1.parameters1Style = 'edit';
% c1.parameters2Style = 'edit';
% c1.parameters1String = {''};
% c1.parameters2String = {''};
% 
%            
%            
%   
% c2.name = 'Month Based';
% c2.control1Style = 'text';
% c2.control1String = '';
% c2.comparatorStyle = 'text';
% c2.comparatorString = 'Month is';
% c2.control2Style = 'popupmenu';
% c2.control2String = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
% c2.label1 = '';
% c2.label2 = '';
% c2.control1Width = 140;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c2.control2Width = 140;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% c2.helpText = 'The Month Based condition determines whether a month matches the selected month.';
% c2.parameters1Visible = 'No';
% c2.parameters2Visible = 'No';
% c2.parameters1Style = 'edit';
% c2.parameters2Style = 'edit';
% c2.parameters1String = {''};
% c2.parameters2String = {''};
% 
% 
% c3.name = 'Event Happened Previously';
% c3.control1Style = 'popupmenu';
% c3.control1String = '';
% c3.comparatorStyle = 'popupmenu';
% c3.comparatorString = {'=', '<', '>', '<=', '>='};
% c3.control2Style = 'edit';
% c3.control2String = '';
% c3.label1 = 'Event';
% c3.label2 = 'months ago';
% c3.control1Width = 140;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c3.control2Width = 140;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% c3.helpText = ['This condition allows you to specify whether another event happened earlier and by how long. ', ...
%               'You select the event that you care about and then enter then number of months after that event that you wish this ', ...
%               'condition to be true.'];
% c3.parameters1Visible = 'No';
% c3.parameters2Visible = 'No';
% c3.parameters1Style = 'edit';
% c3.parameters2Style = 'edit';
% c3.parameters1String = {''};
% c3.parameters2String = {''};
% 
% 
% c4.name = 'Quantity Based';
% c4.control1Style = 'popupmenu';
% % Need to get the available function names.
% %c4.control1String = {'Above ground biomass', 'Below ground biomass', 'Total biomass', 'Rainfall over period'};
% c4.control1String = {''};
% c4.comparatorStyle = 'popupmenu';
% c4.comparatorString = {'=', '<', '>', '<=', '>='};
% c4.control2Style = 'edit';
% c4.control2String = '';
% c4.label1 = 'Quantity';
% c4.label2 = 'Amount';
% c4.control1Width = 140;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c4.control2Width = 140;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% %c4.parameters1EditVisible = 'Yes';
% %c4.parameters2EditVisible = 'Yes';
% 
% c4.helpText = ['This condition allows you to specify whether another event happened earlier and by how long. ', ...
%               'You select the event that you care about and then enter then number of months after that event that you wish this ', ...
%               'condition to be true.'];
% c4.parameters1Visible = 'Yes';
% c4.parameters2Visible = 'Yes';
% c4.parameters1Style = 'popupmenu';
% c4.parameters2Style = 'text';
% c4.parameters1String = {''};
% c4.parameters2String = {''};
% 
% c5.name = 'AND / OR / NOT';
% c5.control1Style = 'popupmenu';
% c5.control1String = {'AND', 'OR', 'NOT'};
% c5.comparatorStyle = 'text';
% c5.comparatorString = '';
% c5.control2Style = 'edit';
% c5.control2String = '';
% c5.label1 = '';
% c5.label2 = 'Indices of conditions to be joined';
% c5.control1Width = 80;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c5.control2Width = 230;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% c5.helpText = 'Choose the conditions from the list that you want AND''ed or OR''ed together. For example, an AND with ''1, 2'' would AND the first two conditions in the list.';
% 
% c5.parameters1Visible = 'No';
% c5.parameters2Visible = 'No';
% c5.parameters1Style = 'edit';
% c5.parameters2Style = 'edit';
% c5.parameters1String = {''};
% c5.parameters2String = {''};
% 
% c6.name = 'Never';
% c6.control1Style = 'text';
% c6.control1String = '';
% c6.comparatorStyle = 'text';
% c6.comparatorString = '';
% c6.control2Style = 'text';
% c6.control2String = '';
% c6.label1 = '';
% c6.label2 = '';
% c6.control1Width = 140;     % total width of panel is 380. spacing of 15 between controls and edges gives 4 spaces of
% c6.control2Width = 140;     % 15 = 60px. So 320 px left to divide up between control1, control2 and comp. Only need
%                             % to define width of controls. width of comp is
%                             % what is left.
%                             % These widths set widths of labels too.
% c6.helpText = 'The Never condition is never true.';
% 
% c6.parameters1Visible = 'No';
% c6.parameters2Visible = 'No';
% c6.parameters1Style = 'edit';
% c6.parameters2Style = 'edit';
% c6.parameters1String = {''};
% c6.parameters2String = {''};
% 
% conditionTypeInfo = [c1, c2, c3, c4, c5, c6];
% 






































