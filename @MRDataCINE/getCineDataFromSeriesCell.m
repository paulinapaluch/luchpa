function obj = getCineDataFromSeriesCell(obj,dcmDirCell)

dcmFilenamesCell = MRData.getDicomFilenamesCell(dcmDirCell);
dcmTagsOK = MRData.getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);
nCines = 0;
for i = 1:length(dcmFilenamesCell)
    try
        nCines = nCines+1;
        dcmTags(1,nCines) = dcmTagsOK(1,i);
        dataRaw(:,:,1,nCines) = double(dicomread(dcmFilenamesCell{i}));
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