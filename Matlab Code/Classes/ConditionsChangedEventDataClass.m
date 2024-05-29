classdef ConditionsChangedEventDataClass < event.EventData
   properties
      OrgValue = 0;
   end
   methods
      function eventData = SpecialEventDataClass(value)
            eventData.OrgValue = value;
      end
   end
end