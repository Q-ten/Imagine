% A Trend is responsible for providing yearly data that follows a given
% distribution. The trend works by calculating the mean for each year and
% then adding in the variance.
% 

classdef Trend < handle
    
    properties
          
        trendType
        varType        
    end
    
    properties(Dependent)
        trendData
        varData
    end
    
    properties(Hidden)               
       trendImportDataLocation
       varImportDataLocation       
    end
    
    properties(Access = private)
        privateTrendDataYearly
        privateTrendDataPoly
        privateVarDataYearly
        privateVarDataPoly
    end
    
    methods
       
        % Constructor populates Trend from arguments or creates an Zero
        % trend.
        function t = Trend(trendType, trendData, varType, varData)
        
            if nargin == 0
                t.trendType = 'Polynomial';
                t.varType = 'Polynomial';
            elseif nargin == 4
                t.trendType = trendType;
                t.trendData = trendData;
                t.varType = varType;
                t.varData = varData;                
            else
                error('Must pass 0 or 4 arguments to the Trend constructor');
            end
                    
        end   % end constructor
        
        % This function returns a series of sampled data from the Trend
        % over n years.
        function [m,v,s] = createTrendSeries(trend, n)
           
            if nargin <= 1
               n = 50; 
            end

            if isempty(trend)
               error('Trying to createTrendSeries from empty Trend.'); 
               m = 0;
               v = 0;
               s = 0;
               return
            end
            
            meanSeries = zeros(1, n);

            if(strcmp(trend.trendType, 'Polynomial'))
               meanSeries = polyval(trend.trendData, 1:n); 
            end

            if(strcmp(trend.trendType, 'Yearly Data'))
                if length(trend.trendData) >= n
                   meanSeries = trend.trendData(1:n);
                else
                   meanSeries = repmat(trend.trendData, 1, floor(n / length(trend.trendData) + 1));
                   meanSeries = meanSeries(1:n);
                end
            end

            varSeries = zeros(1, n);

            if(strcmp(trend.varType, 'Polynomial'))
               varSeries = polyval(trend.varData, 1:n); 
            end

            if(strcmp(trend.varType, 'Yearly Data'))
                if length(trend.varData) >= n
                   varSeries = trend.varData(1:n);
                else
                   varSeries = repmat(trend.varData, 1, floor(n / length(trend.varData) + 1));
                   varSeries = varSeries(1:n);
                end
            end

            s = meanSeries + varSeries .* randn(1, length(varSeries));
            m = meanSeries;
            v = varSeries;
            
        end % end createTrendSeries
        
        % Launches a Gui to import data.
        function obj = importTrendData(obj)
            obj = importData(obj, 'trend');
        end
        
        function obj = importVarData(obj)
            obj = importData(obj, 'var');
        end
        
        function obj = set.trendData(obj, data)
            data = transpose(shiftdim(squeeze(data)));
            switch obj.trendType
                case 'Yearly Data'
                    obj.privateTrendDataYearly = data;
                case 'Polynomial'
                    obj.privateTrendDataPoly = data;
            end
        end
        
        function obj = set.varData(obj, data)
                        
            data = transpose(shiftdim(squeeze(data)));
            switch obj.varType
                case 'Yearly Data'
                    obj.privateVarDataYearly = data;
                case 'Polynomial'
                    obj.privateVarDataPoly = data;
            end
        end 
        
        function data = get.trendData(obj)
            switch obj.trendType
                case 'Yearly Data'
                     data = obj.privateTrendDataYearly;
                case 'Polynomial'
                     data = obj.privateTrendDataPoly;
            end
        end
        
        function data = get.varData(obj)
            switch obj.varType
                case 'Yearly Data'
                    data = obj.privateVarDataYearly;
                case 'Polynomial'
                    data = obj.privateVarDataPoly;
            end
        end
        
    end % end methods
    
    methods(Access = private)
        function obj = importData(obj, type)
            imobj = ImagineObject.getInstance();
            simLength = imobj.simulationLength;
            
            switch type
                case 'trend'
                    len = length(obj.trendData);
                    if len > simLength
                        obj.trendData = obj.trendData(1:simLength);
                    elseif len < simLength
                        obj.trendData(len+1:50) = zeros(simLength - len, 1);
                    end
                    data = SeriesImportTool(obj.trendData', 'Yearly Mean Data');
                    if (~isempty(data))
                        obj.trendData = data';
                    end
                    obj.trendType = 'Yearly Data';
                case 'var'
                    len = length(obj.varData);
                    if len > simLength
                        obj.varData = obj.varData(1:simLength);
                    elseif len < simLength
                        obj.varData(len+1:50) = zeros(simLength - len, 1);
                    end
                    data = SeriesImportTool(obj.varData', 'Yearly Variance Data');
                    if (~isempty(data))
                        obj.varData = data';
                    end
                    obj.varType = 'Yearly Data';
            end
                    
        assignin('base', 't', obj);
            
        end
    end
    
    methods (Static)
        % Checks to make sure the object is a valid Trend struct.
        function valid = isValid(trend)
            
            valid = isa(trend, 'Trend') && ~isempty(trend);

            if(~valid)
                return
            end

            valid = all([valid ischar(trend.trendType), isnumeric(trend.trendData), ...
                ischar(trend.varType), isnumeric(trend.varData), ...
                ~isempty(trend.trendData), ~isempty(trend.varData)]);

            valid = valid && (strcmp(trend.trendType, 'Yearly Data') || strcmp(trend.trendType, 'Polynomial')) && (strcmp(trend.varType, 'Yearly Data') || strcmp(trend.varType, 'Polynomial'));

        end % end Trend.isValid(trend)
        
    end % end methods(Static)
    
end