function fileList = get_all_files(dirName)
%getAllFiles(dirName) - returns list of all files from the given directory 
%   and its subdirectories
%
%   code: http://stackoverflow.com/questions/2652630/how-to-get-all-files-under-a-specific-directory-in-matlab
%   

    dirData = dir(dirName);      %# Get the data for the current directory
    dirIndex = [dirData.isdir];  %# Find the index for directories
    fileIndex = ~ismember({dirData.name},{'.DS_Store','._.DS_Store'})&~dirIndex;
    fileList = {dirData(fileIndex).name}';  %'# Get a list of the files
    if ~isempty(fileList)
        fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
            fileList,'UniformOutput',false);
    end
    subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
    validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
    %#   that are not '.' or '..'
    for iDir = find(validIndex)                  %# Loop over valid subdirectories
        nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
        fileList = [fileList; get_all_files(nextDir)];  %# Recursively call getAllFiles
    end

end