clear
close all

dcmDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_online/challenge_online/SC-HF-I-9';
matDir = '/Volumes/My Passport/MAT/Challenges/MICCAI2009v3/SC-HF-I-9';

M = MRDataCINE(dcmDir,matDir);
M.calcbreathingCorrection;
M.miccaiInDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart1/OnlineDataContours/SC-HF-I-9/contours-manual/IRCCI-expert';
M.importMICCAI2009;
M.dispField.update(M,'DFbspline2Dcons_DJK'); 

beep,pause(.2),beep,pause(.1),beep,pause(.1),beep