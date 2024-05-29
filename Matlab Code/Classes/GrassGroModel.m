% The GrassGroModel contains the data, and provides convenience methods to
% access the data, relating to everything that has come from GrassGro that
% we require to calculate income and costs in Imagine.
classdef  GrassGroModel < handle
    
    properties (Constant)

        sheepClassNames = {'Ewes', 'Ewe Hoggets', 'Ewe Weaners', 'Wethers', 'Wether Hoggets', 'Wether Weaners'};

        classBasedHeaders = ...
            { 
                'Numbers', ...
                'Sheep Sales', ...
                'Sheep Purchases', ...
                'Condition Score', ...
                'Shorn Clean Wool', ...              
            }
            sheepNumbersCol = 1;
            sheepSalesCol = 2;
            sheepPurchasesCol = 3;
            conditionScoreCol = 4;
            shornWoolCol = 5;
             
%         sheepNumbersCol = 1;
%         paddockNumberCol = 2;
%         sheepSalesCol = 3;
%         sheepPurchasesCol = 4;
%         conditionScoreCol = 5;
%         shornWoolCol = 6;
%                 
%         fodderCostCol = 1;
%         mainFlockMECol = 2;
%         youngFlockMECol = 3;
%         
%         generalDataHeaders = ...
%             { 
%                 'Fodder Cost', ...
%                 'Main Flock ME', ...
%                 'Young Flock ME', ...        
%             }

    end
    
    properties (Dependent)
       classCount 
    end
    
    properties
%       generalDataHeaderMappings
%       classBasedHeaderMappings

       dataByClass     % a 600xnx7 matrix containing the data for various quantities that can be divided up by class. 
 %      generalData     % a 600xm matrix containing the data that doesn't apply per class
       
       % Only the yearly attributions are relevant but we'll store the
       % dailyNumbers, dailyMEIntake, dailyPaddockNumbers, and dailyDates that we use
       % to calculate them.
       dailyNumbers
       dailyMEIntake
       dailyPaddockNumbers
       dailyDates
       yearlyAttributions
       
       monthlySupplementCost
       
       eventSwitches   % a 600 x 4 bool array. Column 1 is for shearing events and column 2 is for sheep sales.
                        % 3 is for sheep purchases and 4 is for fodder
                        % costs.
                        
       paddockNumber % The paddockNumber that corresponds to Imagine's paddock. 
                     % The one we're tryng to simulate. It's up to the user
                     % to make sure that the size and layout etc of the
                     % paddock in GrassGro matches the size and layout in
                     % Imagine.
                     
       paddockSize   % The paddockSize is the size in hectares of the paddock denoted by paddockNumber.
                     % We'll use it to scale the financial results from GrassGro for
                     % our own paddock.
    end
    
    methods 
       
        function ggm = GrassGroModel
            ggm.dataByClass = zeros(600, length(ggm.classBasedHeaders), length(ggm.sheepClassNames));
   %         ggm.generalData = zeros(600, length(ggm.generalDataHeaders));
            ggm.eventSwitches = false(600, 4);
            ggm.paddockNumber = 1;
            ggm.paddockSize = 100;
        end
        
        function ggm = copyFields(ggm, source)
           ggm.dataByClass = source.dataByClass;
           ggm.dailyNumbers = source.dailyNumbers;
           ggm.dailyMEIntake = source.dailyMEIntake;
           ggm.dailyPaddockNumbers = source.dailyPaddockNumbers;
           ggm.dailyDates = source.dailyDates;
           ggm.yearlyAttributions = source.yearlyAttributions;
           ggm.monthlySupplementCost = source.monthlySupplementCost;
           ggm.eventSwitches = source.eventSwitches;
           ggm.paddockNumber = source.paddockNumber;
           ggm.paddockSize = source.paddockSize;
        end
        
        function n = get.classCount(ggm)
           n = length(ggm.sheepClassNames); 
        end
        
        function sheepNumbers = getSheepNumbers(ggm, monthIndex)           
           sheepNumbers = ggm.dataByClass(monthIndex, ggm.sheepNumbersCol, :);
           sheepNumbers = reshape(sheepNumbers, 1, 6);
        end

        function sheepNumbers = getConditionScores(ggm, monthIndex)
           sheepNumbers = ggm.dataByClass(monthIndex, ggm.conditionScoreCol, :);
           sheepNumbers = reshape(sheepNumbers, 1, 6);
        end
        
        function index = getIndexForQuantity(ggm, quantityName)
           ix = find(strcmp(ggm.classBasedHeaders, quantityName), 1, 'first');
           if ~isempty(ix)
              index = ggm.classBasedHeaderMappings(ix); 
           end
        end
        
        function output = getClassQuantityByIndex(ggm, quantityIndex, monthIndex)
            output = ggm.dataByClass(monthIndex, quantityIndex, :);
            output = reshape(output, 1, 6);
        end
        
        function output = getClassQuantity(ggm, quantityName, monthIndex)
            index = ggm.getIndexForQuantity(ggm, quantityName);
            if ~isempty(index)
               output = ggm.getClassQuantityByIndex(index, monthIndex); 
            end
        end
        
        function sheepSold = getSheepSold(ggm, monthIndex)
            % returns a matrix of two rows - the first row a list of sheep
            % sold during the month at CS 2, the next row a list of sheep
            % sold during the month at CS 3.
            sheepNumbers = ggm.getClassQuantityByIndex(ggm.sheepSalesCol, monthIndex);
            condScores = ggm.getConditionScores(monthIndex);
            % Clip the condScores to be between 2 and 3.
            condScores(condScores < 2) = 2;
            condScores(condScores > 3) = 3;
            
            % Note this is non-intuitive. condscores - 2 gets the numbers
            % for CS3, so should go second.
            sheepSold(2, :) = sheepNumbers .* (condScores - 2);
            sheepSold(1, :) = sheepNumbers .* (3 - condScores);            

            nans = isnan(sheepSold);
            zeroVec = zeros(2, 6);
            sheepSold(nans) = zeroVec(nans);
        end
        
        function woolPerClass = getWoolSold(ggm, monthIndex)
            % return the total kg wool produced per class
            woolPerClass = ggm.dataByClass(monthIndex, ggm.shornWoolCol, :);  
            woolPerClass = reshape(woolPerClass, 1, 6);
        end

        function sheepNumbers = getSheepPurchased(ggm, monthIndex)
            sheepNumbers = ggm.dataByClass(monthIndex, ggm.sheepPurchasesCol, :);
            sheepNumbers = reshape(sheepNumbers, 1, 6);
        end
        
        function fodderCost = getFodderCost(ggm, monthIndex)
            fodderCost = ggm.monthlySupplementCost(monthIndex);
        end
       
        function TF = isShearingTriggered(ggm, monthIndex)
           % 1st column for shearing event 
           TF = ggm.eventSwitches(monthIndex, 1); 
        end
        
        function TF = isSheepSalesTriggered(ggm, monthIndex)
            % 2nd column for sheep sales event
            TF = ggm.eventSwitches(monthIndex, 2); 
        end
        
        function TF = isSheepPurchasesTriggered(ggm, monthIndex)
            % 3rd column for sheep purchases event
            TF = ggm.eventSwitches(monthIndex, 3); 
        end
        
        function TF = isFodderCostTriggered(ggm, monthIndex)
            % 3rd column for sheep purchases event
            TF = ggm.eventSwitches(monthIndex, 4); 
        end
        
        function pc = getYearlyAttributionForPaddock(ggm, year, paddock)
            if nargin < 3
                paddock = ggm.paddockNumber;
            end
            pc = ggm.yearlyAttributions(year, paddock);            
        end
        
        function establishEventSwitches(ggm)

            ggm.eventSwitches = false(600, 4);
            for i = 1:600                
                % If any of the wool sales are non-zero in a month, then set
                % the switch.
                woolPerClass = getWoolSold(ggm, i);
                if any(woolPerClass > 0)
                   ggm.eventSwitches(i, 1) = true; 
                end
            
                % The same thing goes with the sheep sales.
                sheepSales = getSheepSold(ggm, i);
                if any(any(sheepSales > 0))
                   ggm.eventSwitches(i, 2) = true; 
                end
                
                % The same thing goes with the sheep sales.
                sheepPurchases = getSheepPurchased(ggm, i);
                if any(sheepPurchases > 0)
                   ggm.eventSwitches(i, 3) = true; 
                end
                
                % Ditto feeding.
                fodderCost = getFodderCost(ggm, i);
                if any(fodderCost > 0)
                   ggm.eventSwitches(i, 4) = true; 
                end            
                               
            end
        end
            
        
%         function attributionPercentage = calculateAttribution(ggm, yearIndex, ourPaddockNumber)
%            % We need to work out the total ME contributed to the flock over
%            % the whole year.
%            % From that we work out the proportion that has been provided by
%            % our paddock.
%            
%            % For each month, look at which paddock each class was in. Then
%            % work out the ME intake from pasture for that class that month. 
%            % Add that amount to that paddock's total.
%            paddockME = [];
%            
%            for m = 1:12
%                
%                monthIndex = (yearIndex - 1) * 12 + m;
%                MEMain = ggm.generalDataHeaders(monthIndex, ggm.mainFlockMECol);
%                MEYoung = ggm.generalDataHeaders(monthIndex, ggm.youngFlockMECol);
%                
%                paddockNumbers = ggm.dataByClass(monthIndex, ggm.paddockNumberCol);
%                sheepNumbers = ggm.getSheepNumbers(monthIndex); 
%                
%                % Young flock are the weaners.
%                youngFlockIndices = [0 0 1 0 0 0 1];
%                mainFlockIndices = ones(1, 7) - youngFlockIndices;
%                
%                for i = 1:length(paddockNumbers)
%                   paddockNumber = paddockNumbers(i);
%                   if paddockNumber > length(paddockME)
%                      paddockME(paddockNumber) = 0; 
%                   end
%                   if youngFlockIndices(i)
%                       paddockME(paddockNumber) = paddockME(paddockNumber) + MEYoung / sum(sheepNumbers(youngFlockIndices)) * sheepNumbers(i);   
%                   else
%                       paddockME(paddockNumber) = paddockME(paddockNumber) + (MEMain - MEYoung) / sum(sheepNumbers(mainFlockIndices)) * sheepNumbers(i);                         
%                   end
%                end               
%            end
%            attributionPercentage = sum(paddockME) / paddockME(ourPaddockNumber);
%         end
        
        function TF = isValid(ggm)
            TF = true;
            sectionNames = [ggm.classBasedHeaders, 'Yearly Attributions', 'Monthly Supplement Cost'];
            for i = 1:length(sectionNames)
               TF = TF && ggm.checkSectionValidity(sectionNames{i}); 
            end            
        end

        % Pass in a string which is either 'non-class' or one of the class
        % based column headers.
        function TF = checkSectionValidity(ggm, section)
    
            % How do we test for valid GrassGro output?
            % There should be a non-zero total of sheep every month.
            % Also there should be a non-zero paddock number each month.
            % Also there should be a non-zero total of sheep sold and wool
            % produced each year.
            % Also a non-zero ME intake each year.
                                   
            if strcmp(section, 'Yearly Attributions')
                TF = all(sum(ggm.yearlyAttributions, 2) >= .99) && all(sum(ggm.yearlyAttributions, 2) <= 1.01);
                return;
            end
            
            if strcmp(section, 'Monthly Supplement Cost')
                TF = all(ggm.monthlySupplementCost >= 0);
                return;
            end
            
            TF = false;
            if strcmp(section, 'non-class')
                TF = true;
                
                if ~all(sum(ggm.yearlyAttributions, 2) == 1)
                    TF = false;                    
                end            
                
                if ~all(ggm.monthlySupplementCost >= 0)
                    TF = false;
                end
            else
                ix = find(strcmp(section, ggm.classBasedHeaders), 1, 'first');
                if isempty(ix)
                    error('Passed in a section to check validity but it is not a class-based quantity or the string ''non-class'', ''Yearly Attributions'', or ''Monthly Supplement Cost''.')                    
                else
                    % Check for sheep numbers, paddock number each month.
                    % Check for sheep and wool production each year.
                    
                    checkType = 'none';
                    if (ix == ggm.sheepNumbersCol)
                        TF = true;
                        checkType = 'monthly'; %#ok<NASGU>
                        sectionArray = ggm.dataByClass(:, ix);
                        TF = TF && all(sectionArray >= 0);             % All non-negative
                        TF = TF && all(sum(section, 2) > 0);   % Some stock at all times.
                        return
                    end
                    
                    if (ix == ggm.sheepSalesCol)
                        checkType = 'yearly';
                    end
                    if (ix == ggm.conditionScoreCol)
                        checkType = 'yearly';                       
                    end
                    if (ix == ggm.shornWoolCol)
                        checkType = 'yearly';
                    end
                    
                    if strcmp(checkType, 'monthly')
                        % Every month must be non-zero.
                        sectionArray = ggm.dataByClass(:, ix);
                        TF = TF && all(sectionArray >= 0);             % All non-negative
                        return
                    elseif strcmp(checkType, 'yearly')
                        % The sum of the items for each year must be
                        % non-zero.
                        for i = 1:size(ggm.dataByClass, 1)/ 12
                            TF = true;
                            startIndex = (i - 1) * 12 + 1;
                            endIndex = startIndex + 11;
                            sectionArray = ggm.dataByClass(startIndex:endIndex, ix);

                            TF = TF && sum(sum(sectionArray)) > 0;
                            if ~TF
                                return
                            end
                        end
                        return
                    else
                       % If no check then it's valid.
                       TF = true;
                       return
                    end
                end
            end
            
        end
        
        function trig = getTriggerForEvent(ggm, eventName)
           
            trig = Trigger();
            
            compString = {'=', '<=', '>=', '<', '>'};
        
            switch eventName
               
                case 'Shearing'
                    % Look up the eventTriggers and pull out the indexes.
                    % eventSwitches   % a 600 x 2 bool array. Column 1 is
                    % for shearing events and column 2 is for sheep sales.
                    months = find(ggm.eventSwitches(:, 1));
                    
                    c1 = ImagineCondition.newCondition('Time Index Based', ['Month produced wool.']);
                    c1.indexType = 'Month';
                    c1.indices = months';
                    
%                     c1.string1 = {'Month', 'Year'};
%                     c1.value1 = 1;
%                     c1.stringComp = compString;
%                     c1.valueComp = 1;
%                     c1.string2 = num2str(months');
%                     c1.value2 = 1;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    trig.conditions = {c1};

                case 'Husbandry'
                    % Husbandry is different - simply happens every month
                    
                    c1 = ImagineCondition.newCondition('Time Index Based', ['Every month.']);                    
                    c1.indexType = 'Month';
                    c1.indices = 1:600;

%                     c1.string1 = {'Month', 'Year'};
%                     c1.value1 = 1;
%                     c1.stringComp = compString;
%                     c1.valueComp = 5;
%                     c1.string2 = num2str(1);
%                     c1.value2 = 1;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    trig.conditions = {c1};
                    
                case 'Sheep Sales'
                    months = find(ggm.eventSwitches(:, 2));
                    
                    c1 = ImagineCondition.newCondition('Time Index Based', ['Month had sheep sales.']);
                    c1.indexType = 'Month';
                    c1.indices = months';
                    
%                     c1.string1 = {'Month', 'Year'};
%                     c1.value1 = 1;
%                     c1.stringComp = compString;
%                     c1.valueComp = 1;
%                     c1.string2 = num2str(months');
%                     c1.value2 = 1;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    trig.conditions = {c1};                    
                                    
                case 'Sheep Purchases'
                    months = find(ggm.eventSwitches(:, 3));
                    
                    c1 = ImagineCondition.newCondition('Time Index Based', ['Month had sheep purchases.']);
                    c1.indexType= 'Month';
                    c1.indices = months';
                    
%                     if ~isempty(months)
%                         c1.string1 = {'Month', 'Year'};
%                         c1.value1 = 1;
%                         c1.stringComp = compString;
%                         c1.valueComp = 1;
%                         c1.string2 = num2str(months');
%                         c1.value2 = 1;
%                         c1.parameters1String = '';
%                         c1.parameters2String = '';
%                     end
                    
                    trig.conditions = {c1};                    
                    
                case 'Supplementary Feeding'
                    months = find(ggm.eventSwitches(:, 4));
                    
                    c1 = ImagineCondition.newCondition('Time Index Based', ['Month required supplementary feeding.']);
                    c1.indexType= 'Month';
                    c1.indices = months';
                    
%                     c1.string1 = {'Month', 'Year'};
%                     c1.value1 = 1;
%                     c1.stringComp = compString;
%                     c1.valueComp = 1;
%                     c1.string2 = num2str(months');
%                     c1.value2 = 1;
%                     c1.parameters1String = '';
%                     c1.parameters2String = '';

                    trig.conditions = {c1};                          
            end
            
        end
        
        function importFile(ggm, fileName)
            
            wb = waitbar(0, 'Please wait while the GrassGro data is imported.');
            
            try 
                % Get headers, work out where the columns are, break into months and paste their
                % contents into out matrices.

                waitbar(0.01, wb);
                excelObj = actxserver ('Excel.Application');
                waitbar(0.06, wb);
                fileObj = excelObj.Workbooks.Open(fileName);

                waitbar(0.1, wb);


                % Get a handle to the active sheet
                Activesheet = excelObj.Activesheet;

                % Need to figure these out somehow.
                DateRow = 10;
                gapRows = 2;
                LastColumn = 10;
           %     LastRow = 14987;            % <- this one is crucial to pull from spreadsheet.
                LastRow = 34;

                try                    
    %                Activesheet.Cells(DateRow + gapRows, 1).End(1);
                    LastRow = Activesheet.Range(['A', num2str(DateRow + gapRows + 1)]).End('xldown').Row % find last row
                catch e
                    disp(e.message)
                end
                try                    
    %                Activesheet.Cells(DateRow + gapRows, 1).End(1);
                    LastColumn = Activesheet.Range(['A', num2str(DateRow)]).End('xlToRight').Column % find last col
                catch e
                    disp(e.message)
                end

                headerRange = get(Activesheet, 'Rows', DateRow);
                headers = headerRange.Value;
                headers = headers(1:LastColumn);
                headers = strtrim(headers(2:end));

                waitbar(0.15, wb);
                
              %  dataRange = get(Activesheet, 'Range', 'A11:AZ14987');
                abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                if (LastColumn <= 26)
                   colAlpha = abc(LastColumn); 
                else
                    al1 = floor((LastColumn - 1) / 26);
                    al2 = mod((LastColumn - 1), 26)+1;
                   colAlpha = [abc(al1), abc(al2)];
                end
                dataRangeName = ['B', num2str(DateRow + gapRows + 1), ':', colAlpha, num2str(LastRow)] % 'B13:AZ14987'
                data = xlsread(fileName, dataRangeName);

                waitbar(0.3, wb);

                datesRangeName = ['A', num2str(DateRow + gapRows + 1), ':', 'A', num2str(LastRow)] % 'B13:AZ14987'            
                dataRange = get(Activesheet, 'Range', datesRangeName);
                dates = dataRange.Value;

                waitbar(0.45, wb);

                % Quit Excel
                invoke(excelObj, 'Quit');

                % End process
                delete(excelObj);

                waitbar(0.5, wb);

                
                % Search for Numbers headers.
                [~, dailyNumbers, monthlyNumbers] = SearchHeadersForNumbers(headers, dates, data); %#ok<PROP>
                waitbar(0.55, wb);

                % Search for various classes within headers.
                [~, monthlySold] = SearchHeadersForSold(headers, dates, data);
                waitbar(0.6, wb);
                [~, monthlyBought] = SearchHeadersForBought(headers, dates, data);
                waitbar(0.65, wb);
                [~, monthlyConditionScores] = SearchHeadersForConditionScore(headers, dates, data);
                waitbar(0.7, wb);
                [~, monthlyWoolCut] = SearchHeadersForWoolCut(headers, dates, data);
                waitbar(0.75, wb);

                [~, dailyPaddockNumbers] = SearchHeadersForPaddockNumber(headers, data); %#ok<PROP>
                waitbar(0.8, wb);

                [~, ~, ~, monthlySupplementCost] = SearchHeadersForSupplements(headers, dates, data);  %#ok<PROP>
                waitbar(0.85, wb);

                [~, dailyMEIntake] = SearchHeadersForHerbageMEIntake(headers, data); %#ok<PROP>
                waitbar(0.9, wb);

                ggm.dailyNumbers = dailyNumbers; %#ok<PROP>
                ggm.dailyMEIntake = dailyMEIntake; %#ok<PROP>
                ggm.dailyPaddockNumbers = dailyPaddockNumbers; %#ok<PROP>
                ggm.dailyDates = dates;

                yearlyAttributions = attributePaddockProductivity(dates, dailyNumbers, dailyMEIntake, dailyPaddockNumbers);  %#ok<PROP>
                waitbar(0.95, wb);

                startIndex = 1;
                endIndex = size(monthlyNumbers, 1);
                if endIndex > 600
                    endIndex = 600;
                end

                % 600 x n x 7 (now 6)
    %             ggm.dataByClass(startIndex:endIndex, ggm.sheepNumbersCol, :) = monthlyNumbers(startIndex:endIndex, :);
    %             ggm.dataByClass(startIndex:endIndex, ggm.sheepSalesCol, :) = monthlySold(startIndex:endIndex, :);
    %             ggm.dataByClass(startIndex:endIndex, ggm.sheepPurchasesCol, :) = monthlyBought(startIndex:endIndex, :);
    %             ggm.dataByClass(startIndex:endIndex, ggm.conditionScoreCol, :) = monthlyConditionScores(startIndex:endIndex, :);
    %             ggm.dataByClass(startIndex:endIndex, ggm.shornWoolCol, :) = monthlyWoolCut(startIndex:endIndex, :);
    %                       
    %             ggm.monthlySupplementCost = monthlySupplementCost(startIndex:endIndex); %#ok<PROP>
    %             ggm.yearlyAttributions = yearlyAttributions; \

                if ~all([size(monthlySold, 1), size(monthlyBought, 1), size(monthlyConditionScores, 1), size(monthlyWoolCut, 1), size(monthlySupplementCost, 1)] == size(monthlyNumbers, 1)) %#ok<PROP>
                    error('Not all the imported arrays have the same length.');
                end

                ggm.dataByClass(startIndex:endIndex, ggm.sheepNumbersCol, :) = monthlyNumbers;
                ggm.dataByClass(startIndex:endIndex, ggm.sheepSalesCol, :) = monthlySold;
                ggm.dataByClass(startIndex:endIndex, ggm.sheepPurchasesCol, :) = monthlyBought;
                ggm.dataByClass(startIndex:endIndex, ggm.conditionScoreCol, :) = monthlyConditionScores;
                ggm.dataByClass(startIndex:endIndex, ggm.shornWoolCol, :) = monthlyWoolCut;

                ggm.monthlySupplementCost(startIndex:endIndex, :) = monthlySupplementCost; %#ok<PROP>
                ggm.yearlyAttributions = yearlyAttributions; %#ok<PROP>
                waitbar(0.98, wb);

                if size(ggm.dataByClass, 1) == 0
                   error('GrassGroModel - tried to import data from spreadsheet, but there''s no data.'); 
                else
                    % Pad it out to fill the 50 year season.
                    multiplier = ceil(600 / endIndex);
                    ggm.dataByClass = repmat(ggm.dataByClass(1:endIndex, :, :), [multiplier, 1, 1]);
                    ggm.dataByClass = ggm.dataByClass(1:600, :, :);

                    % Do the same for monthly fodder costs and yearly
                    % attributions.
                    multiplier = ceil(50 / size(ggm.yearlyAttributions, 1));
                    ggm.yearlyAttributions = repmat(ggm.yearlyAttributions, multiplier, 1);
                    ggm.yearlyAttributions = ggm.yearlyAttributions(1:50, :);

                    multiplier = ceil(600 / endIndex);
                    ggm.monthlySupplementCost = repmat(ggm.monthlySupplementCost(1:endIndex, :), multiplier, 1);
                    ggm.monthlySupplementCost = ggm.monthlySupplementCost(1:600, :);
                end
                waitbar(1, wb);

                msgbox('GrassGro Excel spreadsheet imported successfully.');
            catch e
                disp(e.message);               
            end
            delete(wb);
        end
        
    end
    
end




