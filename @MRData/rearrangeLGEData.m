function [dcmData_out,dcmTags_out]=rearrangeLGEData(dcmData,dcmTags)

mytol = 1e-2;

seriesNumbers=[dcmTags(1,:).SeriesNumber];
sliceLocations = [dcmTags(1,:).SliceLocation];
imagePositionPatient=[dcmTags(1,:).ImagePositionPatient];

[uSliceLocations,idx] = unique(round(sliceLocations/mytol)*mytol);
[uSliceLocations,idx2] = sort(uSliceLocations);
idx = idx(idx2);
if imagePositionPatient(3,idx(1))<imagePositionPatient(3,idx(end))
    uSliceLocations=fliplr(uSliceLocations);
end

nSlices = length(uSliceLocations);

for iPic=1:size(dcmData,4)
    iSlice = find(abs(uSliceLocations-sliceLocations(iPic))<mytol,1,'first');
    mycoors(iSlice) = iPic;
end
fprintf('\n')

dcmData_out = zeros(size(dcmData,1),size(dcmData,2),nSlices,1);
%dcmTags_out = cell(nSlices,nTimes);
%myTime_out  = zeros(nSlices,nTimes);
for s=1:nSlices
    if mycoors(s)>0
        dcmData_out(:,:,s,1)=dcmData(:,:,1,mycoors(s));
        dcmTags_out(s,1)=dcmTags(1,mycoors(s));
        %myTime_out(iSlice,iTime) = triggerTimes(iPic);
    end
end