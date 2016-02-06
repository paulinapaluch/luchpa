clear
close all

dcmDir = '/Volumes/My Passport/DCM/CRT_anonym/Tag_CRT_001';
matDir = '/Volumes/My Passport/MAT/CRT4/Tag_CRT_001';

M = MRDataCINE(dcmDir,matDir);
M.calcbreathingCorrection;
% M.dispField.update(M,'DFbspline2Dcons_DJK'); 
% M.dispField.update(M,'DFbspline3Dcons_DJK');
M.dispField.calcDispField(M,'DFbspline2Dcons_DJK'); 
M.dispField.calcDispField(M,'DFbspline3Dcons_DJK');

beep,pause(.2),beep,pause(.1),beep,pause(.1),beep