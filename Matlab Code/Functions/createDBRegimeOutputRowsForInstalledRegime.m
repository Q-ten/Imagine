% The regimeOutputs should be straight forward as they are not rates, but
% Amounts.
function rows = createDBRegimeOutputRowsForInstalledRegime(installedRegime, installedRegimeID, units, unitIDs)

outputs = installedRegime.outputs;

if isempty(outputs)
    rows = [];
    return
end

startMonth = installedRegime.installedMonth;

% rows give different outputs, cols give months.
outputCount = size(outputs, 1);
rowCount = size(outputs, 2) * outputCount;

% Columns to go into the DB.
% installedRegimeID, monthIndex, indexInRegimeOutputs, amountUnitID, amountNumber
DBColCount = 5;

rows = zeros(rowCount, DBColCount);
rowIndex = 0;

for i = 1:size(outputs, 1)
    % Get the ID for this output.

    unit = outputs(i, 1).unit;
    amountUnitID = unitIDs(unit == units);
    if isempty(amountUnitID) || length(amountUnitID) ~= 1
       error('Could not find unitID or found too many.'); 
    end

    for j = 1:size(outputs, 2)

       monthIndex = startMonth + j - 1;
       amountNumber = outputs(i, j).number;

       rowIndex = rowIndex + 1;
       rows(rowIndex, :) = [installedRegimeID, monthIndex, i, amountUnitID, amountNumber];        

    end   
end    

