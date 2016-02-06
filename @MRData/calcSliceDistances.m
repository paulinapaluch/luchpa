function sliceDistances = calcSliceDistances(obj,flags)
% sliceDistances = mrcalcSliceDistances(dcmTags,flags)

if ~exist('flags','var') || ~isfield(flags,'disp')
    flags.disp=0;
end

sliceDistances=[];
if obj.nSlices>1
    sliceDistances=zeros(1,obj.nSlices-1);
    if ~isempty(obj.dcmTags)
        for iSlice =1:obj.nSlices-1
            ppos1 = obj.dcmTags(iSlice,1,1).ImagePositionPatient;
            ppos2 = obj.dcmTags(iSlice+1,1,1).ImagePositionPatient;
            porie = obj.dcmTags(iSlice,1,1).ImageOrientationPatient;
            sliceDistances(iSlice) = dot(ppos1-ppos2,cross(porie(1:3),porie(4:6)));
        end
    end
end

obj.sliceDistances=sliceDistances;

if flags.disp
    disp(sliceDistances)
end