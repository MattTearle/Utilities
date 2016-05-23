function absname = rel2abs(relname)
% Converts relative path name to absolute path name
%
% ABSPATH = REL2ABS(RELPATH) converts the relative path name (for a file or
% folder) in the string RELPATH to the absolute path name for that
% file/folder.
%
% Copyright 2016 The MathWorks, Inc.

% Flag for form of ouput (char/cellstr)
charout = false;
% Input check
if ischar(relname)
    % char -> cellstr
    relname = cellstr(relname);
    if isscalar(relname)
        charout = true;
    end
end
% Input should now be a cellstr
if ~iscellstr(relname)
    error('Relative path name must be a string or cell array of strings')
end

% Prepare output
n = length(relname);
absname = cell(n,1);
% Loop over file names
for k = 1:n
    thisname = relname{k};
    % Check that input is actually a relative path
    % (doesn't start with / or \ or X:\)
    rnbits = strsplit(thisname,filesep);
    if isempty(thisname) || (thisname(1)=='\') || (thisname(1)=='/') || any(rnbits{1}==':')
        error(['Not a valid relative path name: ',thisname])
    end
    
    % Use fileattrib to get info on input file/folder
    [status,finfo] = fileattrib(thisname);
    
    % Did fileattrib find any such file/folder?
    if status
        % The name returned by fileattrib is absolute :)
        absname{k} = finfo.Name;
    else
        % No such file/folder --> give error
        error(finfo)
    end
end

% Convert cellstr back to char if needed
if charout
    absname = absname{1};
end
