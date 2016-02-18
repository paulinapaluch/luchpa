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

% %% calculating masks
% mytic = tic;
% for iname=find(~cellfun(@isempty,names'))
%     mytic2 = tic;
%     disp(names{iname})
%     mypath = fullfile(matDir,names{iname},'NonameStudy');
%     M = MRDataCINE.load(mypath);
%     [cent,harm1mt,mask,maskTh,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);  
%     M.autoSegMask = mask;
%     M.endo.pointsAut = mypoly;
%     M.dupaSave;
%     %volES(iname) = M.getESVolume;
%     %volED(iname) = M.getEDVolume;
%     disp(size(M.dataRaw))
% end
% toc(mytic)

%% getting volumes and putting the into kaggle file
tic
nrows = length(names)*2;
mycdf = zeros(nrows,600);
myname = cell(1,nrows);
volES=zeros(1,nrows);
volED=zeros(1,nrows);
%%
for iname=find(~cellfun(@isempty,names'))
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    volES(iname) = M.getESVolume;
    volED(iname) = M.getEDVolume;
    if volED>550,volED=550;end
    if volES<50,volED=50;end
    mycdf((iname-1)*2+1,:) = normcdf(1:600,volED(iname),50);
    mycdf((iname-1)*2+2,:) = normcdf(1:600,volES(iname),50);
    myname{(iname-1)*2+1} = sprintf('%d_Diastole',iname+500);
    myname{(iname-1)*2+2} = sprintf('%d_Systole',iname+500);
end
toc

fid = fopen([outDir,'.csv'],'w');
fprintf(fid,['Id,',sprintf('P%d,',0:599),'\n']);
for iname=1:size(mycdf,1)
    fprintf(fid,[myname{iname},',']);
    fprintf(fid,'%f,',mycdf(iname,:));
    fprintf(fid,'\n');
end
fclose(fid);
