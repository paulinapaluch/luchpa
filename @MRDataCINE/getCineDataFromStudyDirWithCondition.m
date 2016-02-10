function obj = getCineDataFromStudyDirWithCondition(obj,dcmDir,condFieldName,condValueCell)
%getCineDataFromStudyDirWithCondition
% obj.getCineDataFromStudyDirWithCondition(dcmDir,condFieldName,condValueCell)
%
% INPUT:
%   dcmDir - directory with dicoms from a study (one patient)
%   condFieldName - string with name of the field in a structure returned
%         by dicominfo, dor wxample 'SeriesNumber'
%   condValueCell - cell with acceptable values of the condFieldName, has
%         to be in the same form as returned by dicominfo
%
% Konrad Werys, Feb 2016
% mrkonrad.github.io

if    ~iscell(condValueCell) ...
   || ~ischar(condFieldName) ...
   || ~exist(dcmDir,'dir')
    error('Wrong input data')
end

dcmFilenamesCell = MRData.getDicomFilenamesCell(dcmDir);
dcmTagsTemp = MRData.getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);

idxsOK2 = ~cellfun(@isempty,{dcmTagsTemp(1,:).ImageOrientationPatient});
idxsOK3 = ~cellfun(@isempty,{dcmTagsTemp(1,:).ImagePositionPatient});
idxOK = idxsOK2 & idxsOK3;

%%% apply ok indexes
dcmFilenamesCellOK=dcmFilenamesCell(idxOK);
dcmTagsOK=dcmTagsTemp(1,idxOK);

imageOrientationPatient=[dcmTagsOK.(condFieldName)];

tableToCheck = [dcmTagsOK.(condFieldName)];
for icond = 1:length(condValueCell)
    condition(icond,:) = tableToCheck==condValueCell{icond};
end

conditionAll = all(condition,1);

saxCineIdx = find(conditionAll);

fprintf('Getting data from dicoms\n')

nCines = 0;
for i = saxCineIdx
    try
        nCines = nCines+1;
        dcmTags(1,nCines) = dcmTagsOK(1,i);
        dataRaw(:,:,1,nCines) = double(dicomread(dcmFilenamesCellOK{i}));
    catch ex
        keyboard
        nCines = nCines-1;
        disp(ex)
    end
end

[dataRaw,dcmTags] = MRDataCINE.rearrangeCardiacData(dataRaw,dcmTags);

obj.dataRaw = dataRaw;
obj.dcmTags = dcmTags;

end
