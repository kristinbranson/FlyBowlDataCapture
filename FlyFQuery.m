function output = FlyFQuery( barcode )
%FLYFQUERY Query FlyF database for information associated with a barcode
%
%   The Fly Core Filemaker database will return so far: 
%   RobotID, 
%   Stock_Name (=Line_Name), 
%   Reporter (=Effector), 
%   Date_Crossed, 
%   Wish_List (=Set_Number)
%
%   The function accepts one barcode as integer and returns a structure 
%   containing Line_Name, Date_Crossed, Effector and Set_Number.
%   The basic idea is to use the barcode scanners to automatically get some 
%   of the metadata information for a certain cross. The scanners simulate 
%   keyboard input of (in our case) 5 digits followed by return. 
%   You can either use this function as stand-alone (entering the barcode 
%   manually) or in connection with a barcode reader.
%   
%   USAGE: To use this function, you need the SequeLink JDBC client driver 
%   that is shipped with FileMaker. You can find it at:
%   \\jfrc-fs02\Software\FileMaker\Win\zOld Installers\filemakerv10\FMICD\xDBC\JDBC Client Driver Installer
%   You do NOT need to install Filemaker, you only need sljc.jar.
%   Just update jarpath to point to the location of the driver.
%   You can also update your classpath.txt to add the location of sljc.jar
%   to the static part of the MATLAB Java path.
%   You also DON'T need the Matlab Database Toolbox. All the database
%   communication is done over basic Java.
%
%   TODO: - error handling needs some improvement
%         - see if there is other useful information in the database
%         - integrate output in Will's Metadata code
%
%   Tilman Triphan
%   03/09/2011
%   Thanks to Rob for help with building the query and url strings!
%   If you need help or have comments, send me an email
    
    bc = int2str(barcode);
    %jarpath = strcat(pwd,filesep,'sljc.jar'); 
    jarpath = getJarPath();
    
    if isempty(ismember(javaclasspath, jarpath))
        javaaddpath(jarpath, '-end');
    end    
    
     drv = com.ddtek.jdbc.sequelink.SequeLinkDriver;
     url = 'jdbc:sequelink://10.41.4.26:2399;serverDataSource=FLYF_2;user=Janelia;password=read';
     con = drv.connect(url,'');
     stm = con.createStatement;
     qry = strcat('select PC.RobotID,SF.Stock_Name,Date_Crossed,Reporter,Wish_List',...
        ' from Project_Crosses PC,StockFinder SF',...
        ' where PC.RobotID=SF.RobotID and PC.project=''Fly Olympiad''',...
        ' and PC.Barcode_CrossSerialNumber=',bc);
     res = stm.executeQuery(qry);
     
     output = 0;

     while res.next
         output = struct('Line_Name',res.getString('Stock_Name'),...
             'Date_Crossed',res.getString('Date_Crossed'),...
             'Effector',res.getString('Reporter'),...
             'Set_Number',res.getString('Wish_List'));        
     end
          
     if ~(isstruct(output))
        error(strcat('Barcode >',bc,'< not found in FlyF'));
     end
     
     % Convert values to character arrays
     outputFields = fields(output);
     for i = 1:length(outputFields)
        fieldName = outputFields{i};
        output.(fieldName) = char(output.(fieldName));
     end
     
end

% -------------------------------------------------------------------------
function jarPath = getJarPath()
% Returns path to jdbc sljc.jar file. 
dirPath = getMFileDir();
% for i = 1:2
%     dirPath = stripLastDir(dirPath);
% end
jarPath = sprintf('%sjdbc%sdriver%slib%s%s',dirPath,filesep,filesep,filesep,'sljc.jar');
end

% -------------------------------------------------------------------------
function dirPath = getMFileDir()
% Returns the directory of the current mfile.
filePath = mfilename('fullpath');
sepPos = findstr(filePath,filesep);
dirPath = filePath(1:sepPos(end));
end

% -------------------------------------------------------------------------
function newDirPath = stripLastDir(origDirPath)
% Strip the last directory from the given directory path
sepPos = findstr(origDirPath,filesep);
newDirPath = origDirPath(1:sepPos(end-1));
end