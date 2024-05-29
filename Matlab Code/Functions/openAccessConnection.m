function connection = openAccessConnection(fileName)

import java.sql.*

try 

   db_path = 'Imagine.accdb';
   url = ['jdbc:ucanaccess://' db_path ';mirrorFolder=C:/UCanAccess-4.0.4-bin/mirror'];
   connection = java.sql.DriverManager.getConnection(url);
   
catch ME
    disp(ME.message)
    
    error(['UcanAccess Driver ', driverClassName, ' not found.']);
end


