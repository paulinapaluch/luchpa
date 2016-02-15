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
        outDir = '/Users/konrad/Desktop/miccai2009/20160215';
end

d=dir(matDir);
names = {d.name}';
names(ismember(names,{'.','..'}))=[];

%%
mytable = zeros(1,length(names));
mytable2 = zeros(1,length(names));
for iname=find(~cellfun(@isempty,names'))
    %disp(names{iname})
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    [cent,harm1mt] = MRSegmentation.calcFinalCentroid3d(M.data);
    [harmonics] = MRSegmentation.calcHarmonicsAll(M.data);
    endoMask=M.endo.getMask(size(M.data));
    ptt = round(cent(end,:));

    
    harm0=harmonics(:,:,ptt(3),1);
    data_temp = sum(M.data(:,:,ptt(3),:),4);
    
    myfun2 = @(p,myimage)-interp2(myimage,p(2),p(1));
    p2=fminsearch(@(p)myfun2(p,data_temp),[cent(end,1),cent(end,2)]);
    p2(3) = ptt(3);
    p2(4) = 1;
    ptt2 = round(p2);
    
    reg_maxdist = max(M.data(:))/10;
    tic
    mask4d_temp = MRSegmentation.regionGrowing2Dplus(M.data,p2,reg_maxdist);
    toc
    M.autoSegMask = mask4d_temp;
    M.dupaSave;
    
    if endoMask(ptt(1),ptt(2),ptt(3),M.tEndDiastole)
        mytable(iname)=1;
    end
    if endoMask(ptt2(1),ptt2(2),ptt2(3),M.tEndDiastole)
        mytable2(iname)=1;
    end
    
    subplot(221),
    %imshow(M.data(:,:,ptt(3),M.tEndDiastole),[]),hold on,
    imshow(data_temp,[]),hold on
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title([names{iname},' Image'])
    
    subplot(222),
    %imshow(M.data(:,:,ptt(3),M.tEndDiastole),[]),hold on,
    imshow(abs(harm0),[]),hold on
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('H0')
    
    subplot(223)
    imshow(abs(harmonics(:,:,ptt(3),2)),[]),hold on,
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('H1')
    
    subplot(224)
    imshow(harm1mt(:,:,ptt(3)),[]),hold on
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('final H1')
    
    outfile = fullfile(outDir,names{iname});
    print('-dpng',outfile)
    drawnow
end
sum(mytable)/length(mytable)
sum(mytable2)/length(mytable2)
%%


% %%
% iname=41;
% mypath = fullfile(matDir,names{iname},'NonameStudy');
% M = MRDataCINE.load(mypath);
% V=MRV(M);

