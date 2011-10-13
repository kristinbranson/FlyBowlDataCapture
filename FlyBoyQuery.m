function output = FlyBoyQuery( barcode, exp, deferrck, stm)
%function output = FlyBoyQuery2Params( barcode, exp, deferrck )
%FLYBOYQUERY Query FlyBoy database for information associated with a barcode
%
%   The second parameter specifies the experiment (AGGR, BOX, DAM, FB, GC,
%   GRAV, OBS, STER). It needs to have single quotes around it.
%   deferrck =1 will return 'olympiad default values', currently hardcoded
%   deferrck =0 or no entry will return what is in the flyboy database
%
%   Following values will be returned: 
%   RobotID, 
%   Stock_Name (=Line_Name), 
%   Reporter (=Effector), 
%   Date_Crossed, 
%   Wish_List (=Set_Number)
%   Handler_Cross
%   Handler_Sorting (e.g. handler_sorting_BOX)
%   Sorting_DateTime (e.g. handler_sorting_GC_DateTime)
%
%   The function accepts one barcode as integer and returns a structure 
%   containing Line_Name, Date_Crossed, Effector, Set_Number, Handler_Cross
%   Handler_Sorting and Sorting_DateTime. The last two values will be
%   dependend on the experiment specified by the second parameter.
%   
%
%   USAGE: To use this function, you need
%   mysql-connector-java-5.08-bin.jar or 
%   mysql-connector-java-5.1.15-bin.jar. You can find it at:
%   http://dev.mysql.com/downloads/connector/j/5.0.htm. You do NOT need all 
%   the extra stuff, you only need mysql-connector-java-5.08-bin.jar. Just 
%   update jarpath to point to the location of the driver. You can also 
%   update your classpath.txt to add the location of 
%   mysql-connector-java-5.08-bin.jar to the static part of the MATLAB Java 
%   path. You still DON'T need the Matlab Database Toolbox. All the 
%   database communication is done over basic Java.
%
%   REMARKS: - This is based on FlyFQuery. The changes are necessary to be
%              able to talk to a MySQL database.
%
%   UPDATES: - DateTimes will be returned in the correct yyyymmddTMMHHSS
%              format now
%             - wk added some default value ouputs and additional input
%             arguement, and example queries.
%
%   Tilman Triphan
%   09/06/2011
%   Thanks to Jonathan for working out how to connect to the FlyBoy
%   database.
%   If you need help or have comments, send me an email.
%   
%% example queries: 
% to return what is in the database for the box and barcode 25190
% FlyBoyQuery(25190, 'BOX')
% ans = 
% 
%            Line_Name: 'EXT_FruM-Dickson-GAL4'
%         Date_Crossed: '20110421T000000'
%             Effector: 'UAS_Shi_ts1_3_0001'
%           Set_Number: '57'
%        Handler_Cross: ''
%      Handler_Sorting: ''
%     Sorting_DateTime: ''

%to return what what is in the database and olympiad default valuse
% FlyBoyQuery(25190,'BOX',1)
% 
% ans = 
% 
%            Line_Name: 'EXT_FruM-Dickson-GAL4'
%         Date_Crossed: '20110421T000000'
%             Effector: 'UAS_Shi_ts1_3_0001'
%           Set_Number: '57'
%        Handler_Cross: 'unknown'
%      Handler_Sorting: 'unknown'
%     Sorting_DateTime: '00000000T000000'
% 

%%     

    bc = int2str(barcode);

    if nargin==2    %if only two input arguments, will return only what is in flyboy
        deferrck=0;
    end
        
%     % Make sure that the MySQL JAR file can be found.
%     thisPath = mfilename('fullpath');
%     parentDir = fileparts(thisPath);
%     jarpath = fullfile(parentDir, 'mysql-connector-java-5.0.8-bin.jar');
%     if ~ismember(jarpath,javaclasspath)
%         javaaddpath(jarpath, '-end');
%     end
    
     didconnect = false;
     if nargin < 4 || ~isa(stm,'com.mysql.jdbc.Statement'),
       didconnect = true;
       drv = com.mysql.jdbc.Driver;
       url = 'jdbc:mysql://mysql2.int.janelia.org:3306/flyboy?user=flyfRead&password=flyfRead';
       con = drv.connect(url,'');
       stm = con.createStatement;
     end

     qry = strcat('select RobotID, Stock_Name, Date_Crossed, Reporter,',...
         ' Wish_list, handler_cross, handler_sorting_',exp,', handler_sorting_',...
         exp,'_DateTime from project_crosses_expanded_vw where Barcode_CrossSerialNumber=',bc);
     try
       res = stm.executeQuery(qry);
     catch ME
       if didconnect,
         error(ME);
       else
         drv = com.mysql.jdbc.Driver;
         url = 'jdbc:mysql://mysql2.int.janelia.org:3306/flyboy?user=flyfRead&password=flyfRead';
         con = drv.connect(url,'');
         stm = con.createStatement;
         res = stm.executeQuery(qry);
       end
     end
     
     output = 0;

     while res.next
         date_crossed = datestr(datenum(char(res.getString('Date_Crossed'))),'yyyymmddTHHMMSS');
         date_sorted = char(res.getString(strcat('handler_sorting_',exp,'_DateTime')));
         if ~strcmp(date_sorted,'')
            date_sorted = datestr(datenum(date_sorted),'yyyymmddTHHMMSS');
         end
         
         output = struct('Line_Name',char(res.getString('Stock_Name')),...
             'Date_Crossed',date_crossed,...
             'Effector',char(res.getString('Reporter')),...
             'Set_Number',char(res.getString('Wish_List')),...
             'Handler_Cross',char(res.getString('handler_cross')),...
             'Handler_Sorting',char(res.getString(strcat('handler_sorting_',exp))),...
             'Sorting_DateTime',date_sorted);             
     end
          
     if ~(isstruct(output))
        error(strcat('Barcode >',bc,'< not found in FlyBoy'));
     end
     
     %%  default value outputs-WK 9/7/11
     if deferrck==1
         if isempty (output.Handler_Cross)      %Crosser
             output.Handler_Cross='unknown';
         end
         
         if isempty (output.Handler_Sorting)   %Sorter
             output.Handler_Sorting='unknown';
         end
         
         if isempty (output.Sorting_DateTime)   %Sorting Time
             output.Sorting_DateTime='00000000T000000';
         end
     end
     
     
   
end
