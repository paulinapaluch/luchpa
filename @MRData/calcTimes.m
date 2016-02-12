function [timesT,timesST] = calcTimes(obj)

if ~isempty(obj.dcmTags)
    emptyTTidx = cellfun(@isempty,{obj.dcmTags.TriggerTime});
    [obj.dcmTags(emptyTTidx).TriggerTime]=deal(0);
    timesST = reshape([obj.dcmTags.TriggerTime],size(obj.dcmTags));
    timesT = mean(timesST,1);
else
    timesT = 1:obj.nTimes;
    timesST = repmat(timesT,obj.nSlices,1);
end
    
obj.timesT=timesT;
obj.timesST=timesST;