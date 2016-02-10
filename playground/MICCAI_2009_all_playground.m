clear

user = char(java.lang.System.getProperty('user.name'));

switch user
    case 'KonradPC'
        dcmDir = 'E:\DCM\Challenges\MICCAI 2009 LV SEG\konrad_online';
        matDir = 'C:\Users\Konrad\Documents\MAT\test\online';
    case 'konrad'
        dcmDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_online/challenge_online';
        matDir = '/Volumes/My Passport/MAT/Challenges/MICCAI2009v3';
        conDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart1/OnlineDataContours/';
    case 'Paulina'
        dcmDir = 'E:\inzynierka\dane_dicom\konrad_online';
        matDir = 'E:\inzynierka\dane_matlab\online5';
end

% names{ 1} = 'SC-HF-I-9';
names{ 2} = 'SC-HF-I-10'; 
% names{ 3} = 'SC-HF-I-11';
% names{ 4} = 'SC-HF-I-12';
% names{ 5} = 'SC-HF-NI-12';
% names{ 6} = 'SC-HF-NI-13';
% names{ 7} = 'SC-HF-NI-14';
% names{ 8} = 'SC-HF-NI-15';
% names{ 9} = 'SC-HYP-9';
% names{10} = 'SC-HYP-10';
% names{11} = 'SC-HYP-11';
% names{12} = 'SC-HYP-12';
% names{13} = 'SC-N-9';
% names{14} = 'SC-N-10';
% names{15} = 'SC-N-11';

%%

for iname=find(~cellfun(@isempty,names))
    dcmDir_temp = fullfile(dcmDir,names{iname});
    matDir_temp = fullfile(matDir);
    conDir_temp = fullfile(conDir,names{iname},'contours-manual','IRCCI-expert');
    disp(dcmDir)
    M = MRDataCINE(dcmDir_temp,matDir_temp);
%     M.calcbreathingCorrection;
%     M.miccaiInDir=conDir_temp;
%     M.importMICCAI2009;
%     M.dispField.update(M,'DFbspline2Dcons_DJK');
end

%%
% close all
% clear M C
% iname=2;
% dcmDir_temp = fullfile(dcmDir,names{iname});
% matDir_temp = fullfile(matDir,names{iname});
% conDir_temp = fullfile(conDir,names{iname},'contours-manual','IRCCI-expert');
% disp(dcmDir)
% M = MRDataCINE.load([matDir_temp,'/MRDataCINE.mat']);
% % M = MRDataCINE(dcmDir_temp,matDir_temp);
% % M.calcbreathingCorrection;
% M.miccaiInDir=conDir_temp;
% M.importMICCAI2009;
% M.dispField.update(M,'DFbspline2Dcons_DJK');
% V=MRV(M)