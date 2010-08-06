function db = connectToSAGE(varargin)
    %% connectToSAGE(paramsPath) connect to SAGE using the parameters in the indicated file
    % The file's content should look like:
    % host: db-dev
    % database: sage
    % username: sageRead
    % password: <...>
    %
    % connectToSAGE(host, dbName, userName, password) connect to SAGE
    
    if nargin == 1
        sage_params_path = varargin{1};
        fid = fopen(sage_params_path);
        try
            params = strtrim(textscan(fid, '%s %s'));
            host = params{2}{strmatch('host:', params{1})};
            dbName = params{2}{strmatch('database:', params{1})};
            userName = params{2}{strmatch('username:', params{1})};
            password = params{2}{strmatch('password:', params{1})};
            fclose(fid);
        catch ME
            fclose(fid);
            rethrow(ME);
        end
    elseif nargin == 4
        host = varargin{1};
        dbName = varargin{2};
        userName = varargin{3};
        password = varargin{4};
    else
        error('Wrong number of arguments')
    end
    
    %% Make sure the MySQL client JAR can be found.
    warning off MATLAB:javaclasspath:jarAlreadySpecified
    classpath = getenv('CLASSPATH');
    for path = regexp(classpath, pathsep, 'split')
        javaaddpath(path);
    end

    %% Connect to SAGE
    db = database(dbName, userName, password, 'com.mysql.jdbc.Driver', ['jdbc:mysql://' host '/' dbName]);

    if ~isempty(db.Message)
        if strcmp(db.Message, 'JDBC Driver Error: com.mysql.jdbc.Driver. Driver Not Found/Loaded.')
            message = [db.Message char(10) char(10) 'Make sure you the path to the MySQL Connector JAR file is in the CLASSPATH.'];
        else
            message = db.Message;
        end
        error(['Could not create database connection: ' message]);
    end
end   
