function data=shiftRawData(obj)

if isempty(obj.dataRaw)
    obj.dataRaw = obj.data;
end

for iSlice = 1:obj.nSlices
    M=eye(3);
    M(1,3)=obj.breathShifts(iSlice,1);
    M(2,3)=obj.breathShifts(iSlice,2);
    for iTime=1:obj.nTimes
        data(:,:,iSlice,iTime)=affine_transform(obj.dataRaw(:,:,iSlice,iTime),M,3);
    end
end

obj.data = data;