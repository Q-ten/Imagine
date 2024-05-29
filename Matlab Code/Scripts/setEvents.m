function setEvents(crop, costsToUse)

% Assumes Test event exists in crop.
% TODO: create our own event with no need to use test event.

costNames = fieldnames(costsToUse);
finEventNames = {crop.financialEvents.name};
ix = find(strcmp(finEventNames, 'Test'), 1, 'first');
if isempty(ix)
   error('For now we need a sample financial event in the default crop named Test.'); 
end
testEvent = crop.financialEvents(ix);
for i = 1:length(costNames)
   
    costName = costNames{i};
    if strcmp(costName, 'Planting') || strcmp(costName, 'Harvesting')
        continue
    end
    
    cost = costsToUse.(costName);
    ie = ImagineEvent(costName, testEvent.status, testEvent.costPriceModel);
    ie.costPriceModel.trend.trendData = cost.mean;
    ie.costPriceModel.trend.varData = cost.sd;
    
    ie.trigger.conditions = {ImagineCondition.newCondition('Month Based', 'Month Based')};
    ie.trigger.conditions{1}.monthIndex = cost.month;
    crop.financialEvents(end+1) = ie;
end

crop.financialEvents = [crop.financialEvents(1:ix-1), crop.financialEvents(ix+1:end)];
end