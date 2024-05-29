% My very own insert command that will use the JDBC connection and a batch
% update to insert a bunch of rows at once.
function generatedKeys = myInsertInto(conn, tableName, fields, types, rows)


if (length(types) ~= size(rows, 2) || length(types) ~= length(fields))
    error('Field and Type lists must match number of columns.');
end

fieldsStr = '(';
for i = 1:length(fields) - 1
   fieldsStr = [fieldsStr, fields{i}, ', ']; 
end
fieldsStr = [fieldsStr, fields{end}, ')'];

sqlQueryStr = ['INSERT INTO ', tableName, ' ', fieldsStr, ' VALUES(', repmat('?, ', 1, length(types) - 1), '?)'];


fastTypes = zeros(1, length(types));
knownTypes = {'int', 'string', 'float'};

% Prepare the types based on entries in types.
for i = 1:length(types)
    
    ix = find(strcmp(types{i}, knownTypes), 1, 'first');
    if isempty(ix)
        error('Passed in unknown type.');
    end
    fastTypes(i) = ix;
end

if isnumeric(rows)
    rows = num2cell(rows);
end

try
    % Use a statement with wildcards ('?')
    % to make this general.
    stmt = conn.prepareStatement(sqlQueryStr);
   
    if size(rows, 1) == 1005200
        for rowIndex = 1:size(rows, 1)
            rowIndex = rowIndex
            for i = 1:length(fastTypes)
                switch fastTypes(i)
                    case 1
                        stmt.setInt(i, rows{rowIndex, i});
                    case 2
                        stmt.setString(i, rows{rowIndex, i});
                    case 3
                        stmt.setFloat(i, rows{rowIndex, i});
                end
            end
            stmt.executeBatch();
        end
    else
        for rowIndex = 1:size(rows, 1)
            for i = 1:length(fastTypes)

                switch fastTypes(i)
                    case 1
                        stmt.setInt(i, rows{rowIndex, i});
                    case 2
                        stmt.setString(i, rows{rowIndex, i});
                    case 3
                        stmt.setFloat(i, rows{rowIndex, i});
                end
            end
            stmt.addBatch();
        end
        
        successfulPreparedStatements = stmt.executeBatch();
    end        
    
    
    if size(successfulPreparedStatements, 1) == size(rows, 1) && all(successfulPreparedStatements == 1)
       disp(['Successfully added ', num2str(size(rows, 1)), ' rows to table ', tableName, '.']); 
       try
           
           % Want to work out the ids of the generated keys.
           % If we get the last entry in the table and assume that it's the
           % last key added and all were sequential beforehand...
           % Dodgy, but we have to use it if we don't want a speed penalty
           % of doing each insert row by row.
           query = ['SELECT TOP 1 ID FROM ', tableName, ' ORDER BY ID DESC'];
           stmt2 = conn.createStatement();
           rs = stmt2.executeQuery(query);
           rs.next;
           lastRowID = rs.getInt(1);
           
           generatedKeys = lastRowID - size(successfulPreparedStatements, 1) + 1 : lastRowID;
           
       catch e
           disp(e.message);
       end
    else
        error(['Failed to successfully add all rows to table ', tableName]);
    end
    
catch e
    disp(e.message)
   error(['Insert into table ', tableName, ' failed.']); 
end