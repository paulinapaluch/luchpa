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
mytable = zeros(1,length(names));
mytable2 = zeros(1,length(names));
for iname=find(~cellfun(@isempty,names'))
    %disp(names{iname})
    mypath = fullfile(matDir,names{iname},'NonameStudy');
    M = MRDataCINE.load(mypath);
    [cent,harm1mt,mask,mypoly] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);
    [harmonics] = MRSegmentation.calcHarmonicsAll(M.data);
    endoMask=M.endo.getManMask(size(M.data));
    ptt = round(cent(end,:));

    s = ptt(3);
    harm0=harmonics(:,:,ptt(3),1);
    data_temp = sum(M.data(:,:,ptt(3),:),4);
    
    volumes = squeeze(sum(sum(sum(mask,1),2),3));
    volumes = volumes.*M.aspectRatio(1)*M.aspectRatio(2)*M.aspectRatio(3)/1000;
    [~,tSys] = min(volumes);
    
    M.autoSegMask = mask;
    M.endo.pointsAut = mypoly;
    M.dupaSave;
    
    myfun2 = @(p,myimage)-interp2(myimage,p(2),p(1));
    p2=fminsearch(@(p)myfun2(p,data_temp),[cent(end,1),cent(end,2)]);
    p2(3) = ptt(3);
    p2(4) = 1;
    ptt2 = round(p2);
    
%     reg_maxdist = max(M.data(:))/10;
%     tic
%     mask4d_temp = MRSegmentation.regionGrowing2Dplus(M.data,p2,reg_maxdist);
%     toc
    
%     if endoMask(ptt(1),ptt(2),ptt(3),M.tEndDiastole)
%         mytable(iname)=1;
%     end
%     if endoMask(ptt2(1),ptt2(2),ptt2(3),M.tEndDiastole)
%         mytable2(iname)=1;
%     end
    
    subplot(241),
    plot(volumes),ylabel('LV volume')
    title([names{iname}])
    %imshow(M.data(:,:,ptt(3),M.tEndDiastole),[]),hold on,
%     imshow(data_temp,[]),hold on
%     plot(cent(:,2),cent(:,1),'o')
%     plot(cent(end,2)',cent(end,1)','go')
%     plot(p2(2)',p2(1)','ro'),hold off
%     title([names{iname},' Image'])
    
    subplot(242),
    %imshow(M.data(:,:,ptt(3),M.tEndDiastole),[]),hold on,
    imshow(abs(harm0),[]),hold on
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('H0')
    
    subplot(245)
    imshow(abs(harmonics(:,:,ptt(3),2)),[]),hold on,
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('H1')
    
    subplot(246)
    imshow(harm1mt(:,:,ptt(3)),[]),hold on
    plot(cent(:,2),cent(:,1),'o')
    plot(cent(end,2)',cent(end,1)','go')
    plot(p2(2)',p2(1)','ro'),hold off
    title('final H1')

    subplot(243)
    temp = repmat(M.data(:,:,s,1)./max(M.data(:))*4,[1,1,3]);
    temp(:,:,2) = temp(:,:,2).*~mask(:,:,s,1);
    temp(:,:,3) = temp(:,:,2).*~mask(:,:,s,1);
    imshow(temp)
    
    subplot(244)
    temp = repmat(M.data(:,:,s,tSys)./max(M.data(:))*3,[1,1,3]);
    temp(:,:,2) = temp(:,:,2).*~mask(:,:,s,tSys);
    temp(:,:,3) = temp(:,:,2).*~mask(:,:,s,tSys);
    imshow(temp)

    subplot(247)
    cla
    p = patch(isosurface(mask(:,:,:,1)));
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    view(3),camlight; lighting gouraud
    
    subplot(248)
    cla
    p = patch(isosurface(mask(:,:,:,tSys)));
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    view(3),camlight; lighting gouraud

    drawnow
    if ~exist(outDir,'dir'),mkdir(outDir);end
    outfile = fullfile(outDir,names{iname});
    print('-dpng',outfile)
    
end
toc(mytic)
sum(mytable)/length(mytable)
sum(mytable2)/length(mytable2)

% %%
% iname=7;
% mypath = fullfile(matDir,names{iname},'NonameStudy');
% M = MRDataCINE.load(mypath);
% [cent,harm1mt,mask,line1coors,line2coors] = MRSegmentation.calcFinalCentroid3d(M.data,M.aspectRatio);
% %V=MRV(M);
% %V=MRViewer3Dt(M.data,M.autoSegMask)

