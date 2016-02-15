clear
close all
mainMatDir = '/Volumes/My Passport/MAT/unitTesting/Miccai2009';
temp = dir(mainMatDir);
names = {temp.name}';
istudy = randi(length(names),1);
disp(names{istudy})
mypath = fullfile(mainMatDir,names{istudy},'NonameStudy');

M = MRDataCINE.load(mypath);
M.data;
close all,V = MRV(M); V.setOverVolume(M.autoSegMask);V.backRange=[0,V.backRange(2)/3];V.overMap = hsv;V.alpha = .8; V.maskRange=[0 .5];
% M.calcbreathingCorrection
% %%
% M.epi  = MRRoi(M.nSlices,M.nTimes,'Epi','green');
% M.endo = MRRoi(M.nSlices,M.nTimes,'Endo','red');
% M.importRoisMICCAI2009;
% 
% % V = MRV(M); V.backRange=V.backRange/3;
% endoMask = M.endo.getMask([M.nXs,M.nYs]);
% 
% %MRSegmentation.calcCentroids(M.data);
% 
% point = MRSegmentation.getPoint3d(M.data);
