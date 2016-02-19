%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%
%%% train %%%
%%%%%%%%%%%%%

clear
user = char(java.lang.System.getProperty('user.name'));
switch user
    case 'kwer040'
        matDir  = 'C:\Konrad\MAT\Kaggle\train';
        outDir = fullfile('C:\Users\kwer040\Desktop\kaggle',char(datetime('now','format','yyyy_MM_dd')));
    case 'konrad'
        matDir='/Volumes/My Passport/DCM/Kaggle/train';
        outDir='/Volumes/My Passport/MAT/Kaggle/train';
end

d=dir(matDir);
names = {d.name}';
names(ismember(names,{'.','..'}))=[];

%% calculating masks
mytic = tic;
for iname=find(~cellfun(@isempty,names'))
    mytic2 = tic;
    disp(names{iname})
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    M.calcbreathingCorrection;
    [cent,harm1mt,mask,maskTh,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);  
    M.autoSegMask = mask;
    M.endo.pointsAut = mypoly;
    M.dupaSave;
    volES(iname) = M.getESVolume;
    volED(iname) = M.getEDVolume;
    
    kagglePlot(M,harm1mt,maskTh,cent,[names{iname}])
    
    if ~exist(outDir,'dir'),mkdir(outDir);end
    outfile = fullfile(outDir,names{iname});
    print('-dpng',outfile)
    
    toc(mytic)
end
toc(mytic)

%% calculate cdf
mystd = 25;
volED(volED>600-mystd)=600-mystd;
volED(volED<mystd)=mystd;
volES(volES>600-mystd)=600-mystd;
volES(volES<mystd)=mystd;
for iname=find(~cellfun(@isempty,names'))
    mycdf((iname-1)*2+1,:) = normcdf(1:600,volED(iname),mystd);
    mycdf((iname-1)*2+2,:) = normcdf(1:600,volES(iname),mystd);
    myname{(iname-1)*2+1} = sprintf('%d_Diastole',iname);
    myname{(iname-1)*2+2} = sprintf('%d_Systole',iname);
end

%%
load('kaggleTestGT')
myGT = GT(:);myGT=myGT(1:size(mycdf2,1));
[crps_mean,crps_values]=crps(mycdf,myGT,'ecdf');
disp(crps_mean);
%plot(crps_values)

i=10;a=rand(1,i);for ii=1:i,beep,pause(a(ii)),end