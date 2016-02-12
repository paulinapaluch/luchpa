clear
close all

mainDcmDir = 'C:\Konrad\DCM\Kaggle\train';
matDir  = 'C:\Konrad\MAT\Kaggle';
for i = 280:500
    dcmDir = fullfile(mainDcmDir,num2str(i));
    M=MRDataCINE(dcmDir,matDir);
    disp(size(M.dataRaw))
end
    