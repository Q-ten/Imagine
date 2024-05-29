function [pa, incomes, costs] = simToProfitArray(sim)

% We want to go through all the costs and incomes and look at the crop
% definition and check if the trend is using a standard deviation. If so,
% we want the mean and standard deviation to populate a NormDist and use
% that as our 'price', then multiply it through to get a bunch of incomes
% and costs for a year, and then we add them up etc.

costs = NormDist.init(zeros(1, 50), zeros(1, 50));
incomes = costs;

for irIX = 1:length(sim.installedRegimes)
    % For each installedRegime
    ir = sim.installedRegimes(irIX);
    for pcIX = 1:length(ir.plantedCrops)
       % For each plantedCrop
       pc = ir.plantedCrops(pcIX);
       cropName = pc.cropObject.name;
       for ocIX = 1:length(pc.occurrences)
          % For each occurrence
          oc = pc.occurrences(ocIX);
          year = floor((oc.monthIndex - 1) / 12) + 1;
          for ciIX = 1:length(oc.costItems)
             % For each costItem
             nd = sim.costPriceModelTable.(cropName).(underscore(oc.costItems(ciIX).costName))(year);
             cost = oc.costItems(ciIX).quantity.number * nd;
             costs(year) = costs(year) + cost;
          end
          
          for pIX = 1:length(oc.products)
             % For each product
             
             % We have to figure out the index of the product based on the
             % unit.
             cropProductIX = find([pc.cropObject.growthModel.productPriceModels.denominatorUnit] == oc.products(pIX).quantity.unit, 1,'first');
             % .occurrences(20).products.quantity.unit
             % .plantedCrops(1).cropObject.growthModel.productPriceModels(IX).denominatorUnit
             nd = sim.productPriceModelTable.(cropName)(cropProductIX, year);
             income = oc.products(pIX).quantity.number * nd;
             incomes(year) = incomes(year) + income;
          end
        
       end       
    end
end

pa = incomes - costs;