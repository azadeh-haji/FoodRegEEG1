function logData(datafile, trial, varargin)
%--------------------------------------------------------------------------
% USAGE: logData(datafile, trial, [recordedVariables],...)
%
% Creates a Data struct with each field representing a variable that has
% been specified to be saved.
%
% datafile: Path and name of subject's datafile. Should be a .mat file, 
% containing a Data structure for that subject.
% 
% trial: Trial number for recording. If variable is a single instance (e.g.
% group membership, date run, etc., trial = 1
%
% recordedVariables:
%
% USAGE 1: logData(datafile, [trial], var1, var2, var3)
%
% This usage will write the variables var1 etc. into the Data structure, 
% using the names 'var1', etc.
%
% USAGE 2: logData(datafile, [trial], Struct)
%
% This usage is a more compact way of logging the data. Struct contains all
% the variables for that trial, each with its own field (e.g. Struct.var1,
% Struct.var2 etc.). Each field in Struct will be appended to the Data
% struct.
%--------------------------------------------------------------------------


% If requested datafile doesn't exist, create a default to save data to.
if exist(datafile,'file')
    
    load(datafile); % loads the Data structure into memory for appending
    
else
    
    warning(['Requested datafile (', datafile, ') does not exist!', ...
             'The file will be creasted in the current directory.']);
    
end

% Save requested variables
for var = 1:nargin - 2
    
    if ~isstruct(varargin{var})
        % USAGE 1
        Data.(inputname(var + 2)){trial} = varargin{var};
    else
        
        % USAGE 2
        TempStruct = varargin{var};
        varnames = fieldnames(TempStruct);
        
        for field = 1:length(varnames)            
            Data.(varnames{field}){trial} = TempStruct.(varnames{field});
        end
        
    end
        
end

save(datafile,'Data');
    