% Once getInstance is called during an instance of Matlab, an Excel
% Application will exist inside Matlab. It will be closed when Matlab
% closes.

classdef ExcelApp < handle

    properties (Access = private)
       private_excelObj 
       sessions
    end
    
    % Implement a singleton class.
    methods (Access = private)
        function excelApp = ExcelApp()
            excelApp.sessions = {};
        end
        
        % Put code that would normally appear in the constructor in here.
        function excelAppConstructor(obj)
            try
                %Check if an Excel server is running
                obj.private_excelObj = actxGetRunningServer('Excel.Application');
            catch ME
                % If not, open a new application.
                obj.private_excelObj = actxserver ('Excel.Application');
            end
        end
        
    end
    
    methods 
        function delete(obj)
           if ~isempty(obj.private_excelObj) && iscom(obj.private_excelObj)
              release(obj.private_excelObj);              
           end
        end
        
        function excelObj = getExcelObj(obj)
           if isempty(obj.private_excelObj) || ~iscom(obj.private_excelObj)
              obj.excelAppConstructor; 
           end
           excelObj = obj.private_excelObj;
           try 
               excelObj.Name;
           catch
               obj.excelAppConstructor;
           end
        end
        
        function workbook = getExcelFile(obj, path)
           % If the file at path is already open, return the workbook object. Otherwise try to 
           % open it and return the workbook object. workbook will be empty
           % if the path cannot be opened.
           excelObj = obj.getExcelObj;
           
           % Check if file is open in Excel
           isopen = false;
           for i = 1:get(excelObj.Workbooks, 'Count')
                wb = get(excelObj, 'Workbooks', i);
                wbpath = [get(wb, 'Path'), '/', get(wb, 'Name')];
                wbpath = regexprep(wbpath, '\\', '/');
                path = regexprep(path, '\\', '/');
                if strcmp(path, wbpath)
                   isopen = true;
                   workbook = wb;
                   break;
                end
           end
           if ~isopen
               try
                  workbook = excelObj.Workbooks.Open(path);
                  if ~isempty(obj.sessions)
                    obj.sessions{end} = [obj.sessions{end}, path];
                  end
               catch
                  workbook = [];
               end
           end
        end
        
        function startSession(obj)
           % Creates a new session on the 'session stack' 
           % Every file that is opened through this ExcelApp will be listed
           % in the latest session. When closeSession is called, all the
           % files in the current session will be closed. By default,
           % changes will not be saved. (Changes can be saved on specific files before
           % closing the session)
           %
           % Note - files Saved As will not be found when a session is
           % closed.
           obj.sessions{end + 1} = {};
        end
        
        function closeSession(obj)
            % Closes all the files opened in the last session and removes
            % the session from the session stack.
            if isempty(obj.sessions)
                return
            end
            session = obj.sessions{end};
            excelObj = obj.getExcelObj;
            
            dispAlerts = get(excelObj, 'DisplayAlerts');
            set(excelObj, 'DisplayAlerts', false);
            for i = 1:length(session)
                path = regexprep(session{i}, '\\', '/');  
                for j = 1:excelObj.Workbooks.Count
                    wb = excelObj.Workbook.Item(j);
                    wbpath = regexprep([wb.Path, '/', wb.Name], '\\', '/');
                    if strcmp(wbpath, path)
                        invoke(wb, 'Close');
                        break;
                    end                    
                end
            end
            obj.sessions = obj.sessions(1:end-1);
            set(excelObj, 'DisplayAlerts', dispAlerts);
        end
    end
    
    methods (Static)
        function singleObj = getInstance()
            persistent localObj
            
             if isempty(localObj) || ~isvalid(localObj)
                localObj = ExcelApp;
                localObj.excelAppConstructor;                
             else
             end            
             
             singleObj = localObj;
        end
    end
    
end