clear
close all
user = char(java.lang.System.getProperty('user.name'));
switch user
    case 'konrad'
        dcmDir = '/Volumes/Seagate/DCM/unitTesting/MICCAI2009';
        matDir = '/Volumes/Seagate/MAT/playground/';
        conDir = '/Volumes/Seagate/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart1/OnlineDataContours/SC-HF-NI-14/contours-manual/IRCCI-expert';
    case 'kwer040'
        dcmDir = 'C:\Konrad\DCM\MICCAI2009\challenge_online\challenge_online\SC-HF-I-9';
        matDir = 'C:\Konrad\MAT\MICCAI2009';
        conDir = 'C:\Konrad\DCM\MICCAI2009\Sunnybrook Cardiac MR Database ContoursPart1\OnlineDataContours\SC-HF-I-09\contours-manual\IRCCI-expert';
end
%%
M = MRDataCINE(dcmDir,matDir);
%M.calcbreathingCorrection;
M.miccaiInDir = conDir;
M.importRoisMICCAI2009;
%%
M = MRDataCINE.load(fullfile(matDir,'SC-HF-NI-14','NonameStudy'));
M.dispField.update(M,'DFbspline2Dcons_DJK'); 
V = MRV(M);

beep,pause(.2),beep,pause(.1),beep,pause(.1),beep