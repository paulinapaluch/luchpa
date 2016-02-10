function [dcmFilenamesCell] = getDicomFilenamesCell(dcmDir)
%getDicomFilesCell gets list of all dicom files in the given dicom
%directory and its subdirectories
%
%   author: Konrad Werys (konradwerys@gmail.com)

if iscell(dcmDir)
    dcmFilenamesCell=[];
    for i = 1:length(dcmDir)
        temp = MRData.getDicomFilenamesCell(dcmDir{i});
        dcmFilenamesCell = [dcmFilenamesCell,temp];
    end
elseif ischar(dcmDir)
    myFiles = get_all_files(dcmDir);
    dcmFilenamesCell = cell(0);
    nDicomFiles = 0;
    fprintf('Looking for dicom files, %d files to check',length(myFiles))
    for iFile = 1:length(myFiles)
        if isDICOM(myFiles{iFile})
            nDicomFiles = nDicomFiles+1;
            dcmFilenamesCell{nDicomFiles} = myFiles{iFile};
        end
        if mod(iFile,round(length(myFiles)/10))==0
            fprintf('.')
        end
    end
    fprintf('%d dicom files found\n',nDicomFiles)
end

dcmFilenamesCell = unique(dcmFilenamesCell);