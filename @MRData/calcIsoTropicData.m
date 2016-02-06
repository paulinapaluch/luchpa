function isoData = calcIsoTropicData(obj,interpType)

if ~exist('interpType','var')
    %interpType = 'linear';
    interpType = 'spline';
end

minPixSize = min(obj.aspectRatio);
myscale = minPixSize./obj.aspectRatio;
[oldx,oldy,oldz] = meshgrid(1:obj.nXs,1:obj.nYs,1:obj.nSlices);
[newx,newy,newz] = meshgrid(...
    1:myscale(1):obj.nYs,...
    1:myscale(2):obj.nXs,...
    1:myscale(3):obj.nSlices);

fprintf('Interpolation (%s)',interpType)
mytic = tic;
isoData = zeros(size(newx));
for iTime = 1:obj.nTimes
    for iDim = 1:obj.nDims
    isoData(:,:,:,iTime,iDim) = interp3(...
        obj.data(:,:,:,iTime,iDim),...
        newx,newy,newz,interpType);
    end
    fprintf('.')
end

fprintf(' in %.2f sec.\n',toc(mytic))

obj.dataIso=isoData;
save(obj.savePath,'obj');