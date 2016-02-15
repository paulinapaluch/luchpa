%matDir = '/Volumes/My Passport/MAT/CRT4/Tag_CRT_001/NonameStudy';
matDir = '/Volumes/My Passport/MAT/unitTesting/Miccai2009/SC-HF-I-5/NonameStudy';

M = MRDataCINE.load(matDir);
M.calcbreathingCorrection;

%%
MRSegmentation.calcCentroids(M.data);