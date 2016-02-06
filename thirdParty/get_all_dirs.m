function dirList = get_all_dirs(dirName)
%getAllDirs(dirName) - returns list of all dirs and subdirs in given inpud
%   directory
%
%   code: http://stackoverflow.com/questions/2652630/how-to-get-all-files-under-a-specific-directory-in-matlab
%

dirData = dir(dirName);      %# Get the data for the current directory
dirIndex = [dirData.isdir];  %# Find the index for directories
subDirs = {dirData(dirIndex).name};  %'# Get a list of the dirs
%#   that are not '.' or '..'
validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
%subDir = {dirData(validIndex).name}';  %'# Get a list of the dirs without . and ..
dirList=subDirs(validIndex)';
if ~isempty(subDirs)
    dirList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
        dirList,'UniformOutput',false);
end

for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    dirList = [dirList; get_all_dirs(nextDir)];  %# Recursively call getAllDirs
end



end



