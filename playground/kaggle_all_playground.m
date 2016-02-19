%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
close all

%%%%%%%%%%%%%
%%% train %%%
%%%%%%%%%%%%%
user = char(java.lang.System.getProperty('user.name'));
switch user
    case 'kwer040'
        mainDcmDir = 'C:\Konrad\DCM\Kaggle\train';
        matDir  = 'C:\Konrad\MAT\Kaggle\train';
    case 'konrad'
        mainDcmDir = '/Volumes/My Passport/DCM/Kaggle/train';
        matDir  = '/Volumes/My Passport/MAT/Kaggle/train';
end

for i = 1:500
    dcmDir = fullfile(mainDcmDir,num2str(i));
    M = MRDataCINE(dcmDir,matDir);
    disp(size(M.dataRaw))
end

%%%%%%%%%%%%%%%%
%%% validate %%%
%%%%%%%%%%%%%%%%

% user = char(java.lang.System.getProperty('user.name'));
% switch user
%     case 'kwer040'
%         mainDcmDir = 'C:\Konrad\DCM\Kaggle\validate';
%         matDir  = 'C:\Konrad\MAT\Kaggle\validate';
%     case 'konrad'
%         mainDcmDir = '/Volumes/My Passport/DCM/Kaggle/validate';
%         matDir  = '/Volumes/My Passport/MAT/Kaggle/validate';
% end
% 
% for i = 500:700
%     dcmDir = fullfile(mainDcmDir,num2str(i));
%     M = MRDataCINE(dcmDir,matDir);
%     [cent,harm1mt,mask,maskTh,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);  
%     M.autoSegMask = mask;
%     M.endo.pointsAut = mypoly;
%     M.dupaSave;
%     disp(size(M.dataRaw))
% end
