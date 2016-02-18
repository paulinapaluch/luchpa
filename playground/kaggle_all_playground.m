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

mainDcmDir = 'C:\Konrad\DCM\Kaggle\train';
matDir  = 'C:\Konrad\MAT\Kaggle\train';
for i = 1:500
    dcmDir = fullfile(mainDcmDir,num2str(i));
    M = MRDataCINE(dcmDir,matDir);
    disp(size(M.dataRaw))
end

%%%%%%%%%%%%%%%%
%%% validate %%%
%%%%%%%%%%%%%%%%

mainDcmDir = 'C:\Konrad\DCM\Kaggle\validate';
matDir  = 'C:\Konrad\MAT\Kaggle\validate';
for i = 500:700
    dcmDir = fullfile(mainDcmDir,num2str(i));
    M = MRDataCINE(dcmDir,matDir);
    [cent,harm1mt,mask,maskTh,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);  
    M.autoSegMask = mask;
    M.endo.pointsAut = mypoly;
    M.dupaSave;
    disp(size(M.dataRaw))
end
