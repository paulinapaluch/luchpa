%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%
%%% validate %%%
%%%%%%%%%%%%%%%%

clear
user = char(java.lang.System.getProperty('user.name'));
switch user
    case 'kwer040'
        matDir  = 'C:\Konrad\MAT\Kaggle\validate';
        outDir = fullfile('C:\Users\kwer040\Desktop\kaggle',char(datetime('now','format','yyyy_MM_dd')));
    case 'konrad'
        matDir='';
        outDir='';
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
    %M.calcbreathingCorrection;
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

%% getting volumes and putting the into kaggle file
nPats = length(names);
volES=zeros(1,nPats);
volED=zeros(1,nPats);
mycdf = zeros(nPats*2,600);
myname = cell(1,nPats*2);

%% Get volumes
tic
for iname=find(~cellfun(@isempty,names'))
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    volES(iname) = M.getESVolume;
    volED(iname) = M.getEDVolume;
end
toc
%% calculate cdf
mystd = 25;
volED(volED>600-mystd)=600-mystd;
volED(volED<mystd)=mystd;
volES(volES>600-mystd)=600-mystd;
volES(volES<mystd)=mystd;
for iname=find(~cellfun(@isempty,names'))
    mycdf((iname-1)*2+1,:) = normcdf(1:600,volED(iname),mystd);
    mycdf((iname-1)*2+2,:) = normcdf(1:600,volES(iname),mystd);
    myname{(iname-1)*2+1} = sprintf('%d_Diastole',iname+500);
    myname{(iname-1)*2+2} = sprintf('%d_Systole',iname+500);
end

%% write file
fid = fopen([outDir,'.csv'],'w');
fprintf(fid,['Id,',sprintf('P%d,',0:599),'\n']);
for iname=1:size(mycdf,1)
    fprintf(fid,[myname{iname},',']);
    fprintf(fid,'%f,',mycdf(iname,:));
    fprintf(fid,'\n');
end
fclose(fid);
