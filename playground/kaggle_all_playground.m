%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
close all

mainDcmDir = 'C:\Konrad\DCM\Kaggle\train';
matDir  = 'C:\Konrad\MAT\Kaggle';
for i = 279%1:500
    dcmDir = fullfile(mainDcmDir,num2str(i));
    M=MRDataCINE(dcmDir,matDir);
    disp(size(M.dataRaw))
end