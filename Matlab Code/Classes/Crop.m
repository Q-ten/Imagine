classdef Crop < handle
   
    % A Crop contains data relevant to a particular crop including the
    % CropCategory, which defines the events in the crops life and the
    % kinds of products. The crop has a colour associated with it which is
    % used for graphs and images. It has a name. It has a growth model,
    % which defines the state of the crop and how the state should change.
    % It has a set of price models for the costs and for the products. Some
    % of these things will be dependent on others. For example, the growth
    % model will depend on the category.
    
    properties
        % the name, a string.
        name = '';
        
        % The colour, an RGB triple
        colour = [1 0 0];

        % FinancialEvents are those that have no transition function
        % because they were added by the user. They are only to define when
        % the farmer should incur costs.
        financialEvents = ImagineEvent.empty(1, 0);
        
    end
    
    properties (Dependent)
        
        % The category. A CropCategory object. Comes from the private
        % categories list.
        category

        % The growth model. A GrowthModel object.
        growthModel
        
        
        % The name of the category. Can set this to swap between saved
        % categories.
        categoryChoice
        
        % A list of products the crop could produce. Array of Products.
  %      products        
        
        % A list of possible costs that could be incurred. Array of
        % CostItems.
   %     costItems
        
    end
    
    properties (Access = private)
        
        categoryIndex = 0;
        categories = CropCategory.setupCategories;

    end
    
    methods (Static)
    
        function obj = loadobj(obj)
            % Just want to update the category. Resetting the choice should
            % do it.
            obj.categoryChoice = obj.categoryChoice;
            
            
            obj.growthModel.name
            
            
        end
    end
    
    methods
       
        function cropObj = Crop(nameIn, gmIn, categoryIn, colourIn, financialEventsIn)
            if nargin > 0
                cropObj.name = nameIn;
             %   cropObj.coreEvents = coreEventsIn;
                cropObj.growthModel = gmIn;
                cropObj.category = categoryIn;
             %   cropObj.products = productsIn;
             %   cropObj.costItems = costItemsIn;
                cropObj.colour = colourIn;
                cropObj.financialEvents = financialEventsIn;
            end
        end % end constructor
           
        % Gets the current category from the saved categories list via the
        % private categoryName
        function cat = get.category(obj)
            
            if obj.categoryIndex
                cat = obj.categories(obj.categoryIndex); 
            else
                cat = CropCategory.empty(1, 0);
            end
        end
 
        % To set the category object, we add it to the list, or replace it
        % if it exists, and set the categoryIndex appropriately.
        function obj = set.category(obj, cat)
            
            % Does the a category with the same name already exist? 
            ix = find(strcmp({obj.categories.name}, cat.name), 1);
            if isempty(ix)
               obj.categories(end + 1) = cat;
               obj.categoryIndex = length(obj.categories);
            else
                obj.categories(obj.categoryIndex) = cat;
            end
        end
        
        % Returns the saved category, or an empty array if it doesn't
        % exist.
        function cat = getSavedCategory(obj, catName)
            ix = find(strcmp({obj.categories.name}, catName));
            if isempty(ix)
                cat = [];
            else
               cat = obj.categories(ix); 
            end            
        end
        
        % Gets the name of the current category.
        function catChoice = get.categoryChoice(obj)
            if obj.categoryIndex
                catChoice = obj.category.name;
            else
               catChoice = ''; 
            end
        end
        
        % Swaps between saved categories if it exists. However, will add
        % from CropCategory constructor if possible.
        function crop = set.categoryChoice(crop, catChoice)
           
            cat = CropCategory(catChoice);
            if isempty(cat)
                disp('Unable to chagne categories in crop. Supplied category is not a valid choice.');
                return
            end
            
            % Find the category in the list if it exists.
            ix = find(strcmp({crop.categories.name}, catChoice), 1);
            
            if ~isempty(ix)
                % Then set the new category
                crop.categoryIndex = ix;
            else
                crop.category = cat;
            end
                        
        end % end set.categoryChoice
        
        % Gets the growthModel from the category.
        function gm = get.growthModel(obj)
            gm = obj.category.growthModel;
        end
                
        % Use the growthModel.growthModelEvents and the financialEvents to
        % get the priceModels for these events. Make sure there are no
        % repeats.
        % type is a string of 'Income' or 'Cost' and determines the type of
        % growthModels returned.
        function pms = getUniquePriceModelDefinitions(obj, type)
    
            pms = PriceModel.empty(1,0);
            
            if strcmp(type, 'Income')

                priceModels = obj.growthModel.productPriceModels;
                
            elseif strcmp(type, 'Cost')
                gmes = obj.growthModel.growthModelEvents;
                costPriceModels = [gmes.costPriceModel];
          %      extraCostPriceModels = PriceModel.empty(1, 0);
          %      for i = 1:length(gmes)
          %          extraCostPriceModels = [extraCostPriceModels gmes(i).extraCostPriceModels ];                
          %      end
                financialPriceModels = [obj.financialEvents.costPriceModel];
                priceModels = [costPriceModels, financialPriceModels];
            else
                error('Must pass a type argument. Valid types are ''Income'' and ''Cost''.');
            end
            
            % For each priceModel, check if it is already in pms.
            % If not, add it.
            for i = 1:length(priceModels)  
                alreadyIn = false;
                for j = 1:length(pms)
                    if PriceModel.definitionMatches(pms(j), priceModels(i))
                       alreadyIn = true;
                       break;
                    end
                end
                if ~alreadyIn
                    pms(end + 1) = priceModels(i);                    
                end
            end
            
            
        end % end getUniquePriceModelDefinitions
       
        % This function merges the properties of newObj into the properties
        % of origObj. The objects must be duplicableHandles and also must
        % be of the same concrete class. Where a property is a
        % duplicableObject, it absorbs newObj's property into the origObj's
        % property.
        %
        % NOTE! This method does not maintain the handles of children
        % objects. Therefore this method helps maintain the Crop's handle,
        % but it does not maintain the handles to growthModel or category
        % etc. Therefore the programmer should maintain references to the
        % sub objects through the Crop, ie store the cropObject, then get
        % it's growthModel. Don't store the handle to the growthModel.
        function absorb(origObj, newObj)
        
            if strcmp(class(newObj), class(origObj))

                mc = metaclass(origObj);
                propertyList = mc.Properties;

                for i = 1:length(propertyList)
                    propName = propertyList{i}.Name;
                    if ~(propertyList{i}.Dependent || propertyList{i}.Abstract || propertyList{i}.Constant || propertyList{i}.Transient)
                        origObj.(propName) = newObj.(propName);
                    end                                            
                end

            else
               error('Absorb method can only be called on objects of exactly the same type.'); 
            end
           
        end 
    end
    

    
    methods (Static)
       
        % checks that the object passed is really a crop.
        % It can also be a list of crops. List of booleans are returned.
        function valid = isValid(crops)
            valid = zeros(1, length(crops));
            for i = 1:length(crops)
                c = crops(i);
                valid(i) = isa(c, 'Crop');
                if valid(i)
                    valid(i) = all([ ischar(c.name), ...
                                    isnumeric(c.colour), ...
                                    size(c.colour) == [3, 1] ]); %...
                                  %  CropCategory.isValid(c.category), ...
                                  %  GrowthModel.isValid(c.growthModel), ...
                                  %  Product.isValid(c.products), ...
                                   % CostItem.isValid(c.costItems)]);
                                  
                end
                
                if ~valid
                    valid = 1
                    disp('Overriding Crop to valid');
                end
                
            end    
            
        end % end Crop.isValid
        
    end


    
    
    
end