function [dcmData_out,dcmTags_out]=rearrangeCardiacData(dcmData,dcmTags)

seriesNumbers=[dcmTags(1,:).SeriesNumber];
sliceLocations = [dcmTags(1,:).SliceLocation];
imagePositionPatient=[dcmTags(1,:).ImagePositionPatient];


mytol = 1e-2;

triggerTimes = [dcmTags(1,:).TriggerTime];
uSeriesNumbers = unique(seriesNumbers);

[uSliceLocations,idx] = unique(round(sliceLocations/mytol)*mytol);
if imagePositionPatient(3,idx(1))<imagePositionPatient(3,idx(end))
    uSliceLocations=fliplr(uSliceLocations);
end

nSlices = length(uSliceLocations);

for iSN=1:length(uSliceLocations)
    idx = find(abs(sliceLocations-uSliceLocations(iSN))<mytol);
    mytimes(iSN,1:length(idx)) = sort(triggerTimes(idx));
end

nTimes = size(mytimes,2);

if size(dcmData,4) ~= nSlices*nTimes
    %%% in case of duplicate Siemens slices (one slice in one series)
    if length(uSeriesNumbers)>nSlices
        for iSN=1:length(uSeriesNumbers)
            idx = find(seriesNumbers==uSeriesNumbers(iSN));
            mytimes2(iSN,1:length(idx)) = sort(triggerTimes(idx));
        end
    else %%% in case of duplicate GE slices (many slices in one series)
        %%% find series with most number of files
        idxRightSeries = 1;
        for iSN=1:length(uSeriesNumbers)
            if sum(seriesNumbers==uSeriesNumbers(iSN))>sum(seriesNumbers==uSeriesNumbers(idxRightSeries))
                idxRightSeries=iSN;
            end
        end
        rightSeriesN = uSeriesNumbers(idxRightSeries);
        triggerTimes_temp = triggerTimes(seriesNumbers==rightSeriesN);
        sliceLocations_temp = sliceLocations(seriesNumbers==rightSeriesN);
        for is=1:nSlices
            idx = find(abs(sliceLocations_temp-uSliceLocations(is))<mytol);
            mytimes2(is,1:length(idx)) = sort(triggerTimes_temp(idx));
        end
        
    end
    mytimes = mytimes2;
end

mytimes = unique(mytimes','rows')';
nTimes = size(mytimes,2);

for iPic=1:size(dcmData,4)
    iSlice = find(abs(uSliceLocations-sliceLocations(iPic))<mytol,1,'first');
    iTime = find(mytimes(iSlice,:)==triggerTimes(iPic),1,'first');
    
    if ~isempty(iTime)
        mycoors(iSlice,iTime) = iPic;
        %dcmData_out(:,:,iSlice,iTime)=dcmData(:,:,1,iPic);
        %dcmTags_out(iSlice,iTime)=dcmTags(1,iPic);
        %myTime_out(iSlice,iTime) = triggerTimes(iPic);
    else
        fprintf('!')
        [~,iTime] = find(mytimes==triggerTimes(iPic),1,'first');
        mycoors(iSlice,iTime) = iPic;
        %dcmData_out(:,:,iSlice,iTime)=dcmData(:,:,1,iPic);
        %dcmTags_out(iSlice,iTime)=dcmTags(1,iPic);
        %myTime_out(iSlice,iTime) = triggerTimes(iPic);
    end
end
fprintf('\n')

dcmData_out = zeros(size(dcmData,1),size(dcmData,2),nSlices,nTimes);
%dcmTags_out = cell(nSlices,nTimes);
%myTime_out  = zeros(nSlices,nTimes);
for s=1:nSlices
    for t=1:nTimes
        if mycoors(s,t)>0 && mycoors(s,t)<=size(dcmData,4)
            dcmData_out(:,:,s,t)=dcmData(:,:,1,mycoors(s,t));
            dcmTags_out(s,t)=dcmTags(1,mycoors(s,t));
            %myTime_out(iSlice,iTime) = triggerTimes(iPic);
        end
    end
end