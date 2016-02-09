function [DF_forw,DF_back,regoptions] = emptyDF(MRData)
ticAll = tic;
DF_forw = zeros(MRData.nXs,MRData.nYs,MRData.nSlices,MRData.nTimes,3);
DF_back = zeros(MRData.nXs,MRData.nYs,MRData.nSlices,MRData.nTimes,3);
regoptions.calcTime = toc(ticAll);
end