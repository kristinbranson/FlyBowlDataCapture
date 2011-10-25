function stm = InitializeFlyBoy()

thisPath = mfilename('fullpath');
parentDir = fileparts(thisPath);
jarpath = fullfile(parentDir, 'mysql-connector-java-5.0.8-bin.jar');
if ~ismember(jarpath,javaclasspath)
  javaaddpath(jarpath, '-end');
end
% also connect to the database
drv = com.mysql.jdbc.Driver;
url = 'jdbc:mysql://10.40.11.14:3306/flyboy?user=flyfRead&password=flyfRead';
%url = 'jdbc:mysql://mysql2.int.janelia.org:3306/flyboy?user=flyfRead&password=flyfRead';
con = drv.connect(url,'');
stm = con.createStatement;
