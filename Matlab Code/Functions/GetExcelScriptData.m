% data contains an array of objects - one object for each row in the Excel
% file. Each object is defined by the headers in the file. The first task
% is to get work out the header objects.
function  data  = GetExcelScriptData( fileName )

    data = [];

    try 
        excelObj = actxserver ('Excel.Application');
        fileObj = excelObj.Workbooks.Open(fileName);

        % Get a handle to the active sheet
        Activesheet = excelObj.Activesheet;       
            
        headers = [];

        CurrentHeaderRange = Activesheet.Range('HeaderAnchor');            
        while (~isnan(CurrentHeaderRange.Value))

            header.range = CurrentHeaderRange.Address;
            header.row = CurrentHeaderRange.Row;
            header.col = CurrentHeaderRange.Column;
            header.name = CurrentHeaderRange.Value;
            header.subHeaders = struct('range', {}, 'row', {}, 'col', {}, 'name', {});

            CurrentSubHeaderRange = get(CurrentHeaderRange, 'Offset', 1, 0);

            while ~isnan(CurrentSubHeaderRange.Value)

                subheader.range = CurrentSubHeaderRange.Address;
                subheader.row = CurrentSubHeaderRange.Row;
                subheader.col = CurrentSubHeaderRange.Column;
                subheader.name = CurrentSubHeaderRange.Value;

                if isempty(header.subHeaders)
                    header.subHeaders = subheader;                    
                else
                    header.subHeaders(end + 1) = subheader;
                end                        

                CurrentSubHeaderRange = get(CurrentSubHeaderRange, 'Offset', 0, 1);
            end

            if isempty(headers)
               headers = header; 
            else
               headers(end + 1) = header;
            end
            CurrentHeaderRange = CurrentHeaderRange.End('xlToRight');

        end    
        
        % Now try to get the data.
        
        DataRowHeader = Activesheet.Range('DataAnchor'); 
        
        % for each header, create a struct with sub headers.
        % for each
        data =[];
        dataHeaderCol = DataRowHeader.Column;
        while ~isnan(DataRowHeader.Value)
            clear rowData;
            for i = 1:length(headers)
                for j = 1:length(headers(i).subHeaders)
                    col = headers(i).subHeaders(j).col - dataHeaderCol;
                    range = get(DataRowHeader, 'Offset', 0, col);
                    rowData.(headers(i).name).(headers(i).subHeaders(j).name) = range.Value;
                end                
            end
            if (isempty(data))
                data = rowData;
            else
                data(end+1) = rowData;
            end

            DataRowHeader = get(DataRowHeader, 'Offset', 1, 0);
        end
    catch e
        disp(e.message)
    end
    
   % data = headers;
end