%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getting data from dicom and getting the contours is done in unit testing
% classes (see unitTesting folder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
user = char(java.lang.System.getProperty('user.name'));

switch user
    case 'kwer040'
        dcmDir = '';
        matDir = '';
    case 'konrad'
        dcmDir = '/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_online/challenge_online';
        matDir = '/Volumes/My Passport/MAT/unitTesting/Miccai2009';
        outDir = fullfile('/Users/konrad/Desktop/miccai2009/',char(datetime('now','format','yyyy_MM_dd')));
end

d=dir(matDir);
names = {d.name}';
names(ismember(names,{'.','..'}))=[];

%%
mytic = tic;

allnames = flip(find(~cellfun(@isempty,names')));
for iname=allnames
    mytic2 = tic;
    disp(names{iname})
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    [cent,harm1mt,mask,maskTh,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);
    
    M.autoSegMask = mask;
    M.endo.pointsAut = mypoly;
    kagglePlot(M,harm1mt,maskTh,cent,[names{iname}])
    
    M.dupaSave;
    
    
    
%     s = ptt(3);
%     harm0= MRSegmentation.calcHarmonicsOne(M.data(:,:,ptt(3),:),1);
%     harm1= MRSegmentation.calcHarmonicsOne(M.data(:,:,ptt(3),:),2);
%     data_temp = sum(M.data(:,:,ptt(3),:),4);
%     myfun2 = @(p,myimage)-interp2(myimage,p(2),p(1));
%     p2=fminsearch(@(p)myfun2(p,data_temp),[cent(end,1),cent(end,2)]);
%     p2(3) = ptt(3);p2(4) = 1;ptt2 = round(p2);

    
    if ~exist(outDir,'dir'),mkdir(outDir);end
    outfile = fullfile(outDir,names{iname});
    print('-dpng',outfile)
    toc(mytic2)
end
toc(mytic)
% find(ismember(names,'SC-HF-I-6'))

% %%
% iname=7;
% mypath = fullfile(matDir,names{iname},'NonameStudy');
% M = MRDataCINE.load(mypath);
% [cent,harm1mt,mask,line1coors,line2coors] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);
% %V=MRV(M);
% %V=MRViewer3Dt(M.data,M.autoSegMask)

