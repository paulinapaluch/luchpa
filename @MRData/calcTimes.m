function [timesT,timesST] = calcTimes(obj)

if ~isempty(obj.dcmTags)
    %%% in case there is data with no trigger time, fill empty spaces with
    %%% zeros
    idxTIempty = cellfun(@isempty,{obj.dcmTags.TriggerTime});  % find
    [obj.dcmTags(idxTIempty).TriggerTime]=deal(0); % fill with 0
    
    %%% simply reshape
    timesST = reshape([obj.dcmTags.TriggerTime],size(obj.dcmTags));
    %%% simply calc mean over slices
    timesT = mean(timesST,1);
else
    timesT = 1:obj.nTimes;
    timesST = repmat(timesT,obj.nSlices,1);
end
    
obj.timesT=timesT;
obj.timesST=timesST;