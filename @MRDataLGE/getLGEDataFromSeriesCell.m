function obj = getCineDataFromSeriesCell(obj,dcmDirCell)

dcmFilenamesCell = MRData.getDicomFilenamesCell(dcmDirCell);
dcmTagsOK = MRData.getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);
nSlices = 0;
for i = 1:length(dcmFilenamesCell)
    try
        nSlices = nSlices+1;
        dcmTags(1,nSlices) = dcmTagsOK(1,i);
        dataRaw(:,:,1,nSlices) = double(dicomread(dcmFilenamesCell{i}));
    catch ex
        keyboard
        nSlices = nSlices-1;
        disp(ex)
    end
end

[dataRaw,dcmTags] = MRDataCINE.rearrangeLGEData(dataRaw,dcmTags);

obj.dataRaw = dataRaw;
obj.dcmTags = dcmTags;

end