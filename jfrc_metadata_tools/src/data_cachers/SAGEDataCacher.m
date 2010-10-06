classdef SAGEDataCacher < handle
    
    properties (Constant)
        labs = {'rubin'};
        lineNamesFile = 'linenames.txt';
        effectorsFile = 'effectors.txt';
        dataDir = 'data';
        sourceFileDepth = 2;
    end
    
    methods
        
        function lineNames = readLineNamesFile(self)
            % Read line names file in data directory. 
            filePath = self.getLineNamesFilePath();
            lineNames = cellFromTextFile(filePath);
        end
        
        function effectorNames = readEffectorsFile(self)
           % Reads effector names file in the data directory
           filePath = self.getEffectorsFilePath();
           effectorNames = cellFromTextFile(filePath);
        end
        
        function updateLineNamesFile(self)
            % Update the line names file by downloading new values from
            % SAGE.
            %fprintf('updating line names ...');
            lineNames = getLineNames(self.labs);
            filePath = self.getLineNamesFilePath();
            cellToTextFile(filePath,lineNames);
            %fprintf('done\n');
        end
        
        function updateEffectorsFile(self)
            % Update the effector names by download new values from SAGE
            %fprintf('updating effector names ...');
            effectorNames = getEffectorNames();
            filePath = self.getEffectorsFilePath();
            cellToTextFile(filePath,effectorNames);
            %fprintf('done\n');
        end
        
        function filePath = getEffectorsFilePath(self)
           % Get the full path to the effectors file in the data directory.
           % Note it is assumed that the data directoty is located two 
            % directories up from this file in the top level direcoty of 
            % this project.
            dirPath = self.getDataDirPath();
            filePath = [dirPath,self.effectorsFile];
        end

        function filePath = getLineNamesFilePath(self)
            % Get the full path to the line names file in the data directory. 
            % Note it is assumed that the data directoty is located two 
            % directories up from this file in the top level direcoty of 
            % this project. 
            dirPath = self.getDataDirPath();
            filePath = [dirPath, self.lineNamesFile];
        end
        
        function dirPath = getDataDirPath(self)
            % Get the path to the data directory. Note it is assumed that
            % the data directoty is located two directories up from this
            % file in the top level direcoty of this project. 
            dirPath = getMFileDir();
            for i = 1:self.sourceFileDepth
                dirPath = stripLastDir(dirPath);
            end
            dirPath = [dirPath,self.dataDir,filesep];
        end
        
    end
end

% -------------------------------------------------------------------------
function lineNames = getLineNames(labs)
% Get linenames from SAGE for all lab names in the labs cell array
lineNames = {};
for i = 1:length(labs)
    labname = labs{i};
    try
        lines = SAGE.Lab(labname).lines();    
    catch ME
        error( ...
            'unable to get line names for lab=%s from SAGE: %s', ...
            labname, ...
            ME.message ...
            );
    end
    %labLineNams = {lines.name}; 
    lineNames = {lineNames{:}, lines.name};
end
end

% -------------------------------------------------------------------------
function effectorNames = getEffectorNames()
% Get effector names from SAGE
try
    terms = SAGE.CV('effector').terms();
    effectorNames = {terms.name};
catch ME
    error('unable to get effector names from SAGE: %s', ME.message);
end
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

% -------------------------------------------------------------------------
function cellToTextFile(fileName,cellArray)
% Saves a cell array of strings to a simple text file. The cell array must
% have size = [1,N] and consisit entierly of character arrays (strings).

% Check that cell array has correct format for saving
try 
    checkCellArray(cellArray);
catch ME
    error('unable to write cell array: %s', ME.message);
end
    
% Try and open file.
[fid, msg] = fopen(fileName,'w');
if fid == -1
    error('unable to open file, %s, for writing: %s', fileName, msg);
end

% Write contents of cell array to file and close file when done.
for i = 1:length(cellArray)
    fprintf(fid,'%s\n', cellArray{i});
end
fclose(fid);
end

% -------------------------------------------------------------------------
function checkCellArray(cellArray)
% Check that cell array has the correct format for saving data. It must be
% have size [1,N] and all element must be [1,M] character arrays.

[nrow,ncol] = size(cellArray);
if nrow ~= 1
    error('cell array must have size = [1,N] in order to save');
end

for i = 1:ncol
   string = cellArray{i};
   if ~ischar(string)
       error('cell array elements must be character arrays');
   end
   [n,m] = size(string);
   if n~=1
       error('cell array elements must be [1,N] character arrays');
   end
end
end

% -------------------------------------------------------------------------
function cellArray = cellFromTextFile(fileName)
% Loads cell array of strings, 1xN character arrays, from the given text 
% file.
if exist(fileName, 'file') == 0
    error('unable to read file, %s, does not exist', fileName);
end
try
    cellArray = textread(fileName, '%s');
catch ME
    error('unable to read file, %s: %s', ME.message);
end
% Reshape cell array so that it is 1xN
[nrow,ncol] = size(cellArray);
cellArray = reshape(cellArray,[ncol,nrow]);
end

% -------------------------------------------------------------------------
function fileAge = getFileAge(fileName)
% Returns the age (last modified time) of the file fileName in datenum
% units. 
if exist(fileName, 'file') == 0
    error('file, %s, does not exist', fileName);
end
fileStruct = dir(fileName);
if isempty(fileStruct)
    error('unable to get file information structure for file, %s', ME.message); 
end
% Compute file age as datenum
fileAge = now() - datenum(fileStruct.date);
end