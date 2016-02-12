clear
close all
user = char(java.lang.System.getProperty('user.name'));
switch user
    case 'konrad'
        dcmDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_online/challenge_online/SC-HF-I-9';
        matDir = '/Volumes/My Passport/MAT/Challenges/MICCAI2009v3';
        contDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart1/OnlineDataContours/SC-HF-I-9/contours-manual/IRCCI-expert';
    case 'kwer040'
        dcmDir = 'C:\Konrad\DCM\MICCAI2009\challenge_online\challenge_online\SC-HF-I-9';
        matDir = 'C:\Konrad\MAT\MICCAI2009';
        contDir = 'C:\Konrad\DCM\MICCAI2009\Sunnybrook Cardiac MR Database ContoursPart1\OnlineDataContours\SC-HF-I-09\contours-manual\IRCCI-expert';
end
%%
M = MRDataCINE(dcmDir,matDir,'SeriesNumber',{4});
M.calcbreathingCorrection;
M.miccaiInDir = contDir;
M.importMICCAI2009;
%%
M = MRDataCINE.load(fullfile(matDir,'SC-HF-I-9','NonameStudy'));
M.dispField.update(M,'DFbspline2Dcons_DJK'); 

beep,pause(.2),beep,pause(.1),beep,pause(.1),beep