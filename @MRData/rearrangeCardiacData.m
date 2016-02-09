function [dcmData_out,dcmTags_out]=rearrangeCardiacData(dcmData,dcmTags)


seriesNumbers=[dcmTags(1,:).SeriesNumber];
sliceLocations = [dcmTags(1,:).SliceLocation];
imagePositionPatient=[dcmTags(1,:).ImagePositionPatient];

triggerTimes = [dcmTags(1,:).TriggerTime];
uSeriesNumbers = unique(seriesNumbers);

[uSliceLocations,idx] = unique(sliceLocations);
if imagePositionPatient(3,idx(1))<imagePositionPatient(3,idx(end))
    uSliceLocations=fliplr(uSliceLocations);
end

nSlices = length(uSliceLocations);

for iSN=1:length(uSliceLocations)
    idx = find(sliceLocations==uSliceLocations(iSN));
    mytimes(iSN,1:length(idx)) = sort(triggerTimes(idx));
end

nTimes = size(mytimes,2);

%%% in case of duplicate siemens slices
if size(dcmData,4) ~= nSlices*nTimes
    clear mytimes
    for iSN=1:length(uSeriesNumbers)
        idx = find(seriesNumbers==uSeriesNumbers(iSN));
        mytimes(iSN,1:length(idx)) = sort(triggerTimes(idx));
    end
end

dcmData_out = zeros(size(dcmData,1),size(dcmData,2),nSlices,nTimes);
%dcmTags_out = cell(nSlices,nTimes);
myTime_out  = zeros(nSlices,nTimes);

for iPic=1:size(dcmData,4)
    iSlice = find(uSliceLocations==sliceLocations(iPic),1,'first');
    iTime = find(mytimes(iSlice,:)==triggerTimes(iPic),1,'first');
    
    if ~isempty(iTime)
        dcmData_out(:,:,iSlice,iTime)=dcmData(:,:,1,iPic);
        dcmTags_out(iSlice,iTime)=dcmTags(1,iPic);
        myTime_out(iSlice,iTime) = triggerTimes(iPic);
    else
        disp('Do poprawy!!!')
    end
end
end