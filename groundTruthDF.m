function [DF_forw,DF_back,regoptions] = groundTruthDF(MRData)
% work in progress
symoptions.rad_percent = .5;
symoptions.phi = -.33;
symoptions.epsilon = 9.2;
symoptions.lambda = 1;
symoptions.nSysTimes = 10;
symoptions.dims = '2D'; % cahnge it to number?

mytic = tic;
     
%%% prepare motion parameters
phi_max = symoptions.phi * pi/180;
epsilon_max = symoptions.epsilon * pi/180;
rad_percent_max = symoptions.rad_percent;
lambda_max = symoptions.lambda;
nTimes = symoptions.nSysTimes*2;

phi_all         = linspace(0,phi_max,nTimes/2);
epsilon_all     = linspace(0,epsilon_max,nTimes/2);
rad_percent_all = linspace(1,rad_percent_max,nTimes/2);
lambda_all      = linspace(1,lambda_max,nTimes/2);

phi_all         = [phi_all,fliplr(phi_all)];
epsilon_all     = [epsilon_all,fliplr(epsilon_all)];
rad_percent_all = [rad_percent_all,fliplr(rad_percent_all)];
lambda_all      = [lambda_all,fliplr(lambda_all)];

if ismember(symoptions.dims,{'3d','3D'})

%%%   for faster calculation in testing   
%     nhooodSize1=[1 1 1];
%     nhooodSize2=[1 1 1];
%     sigma1=1;
%     sigma2=1;
    nhooodSize1=[23,23,23];
    nhooodSize2=[9,9,9];
    sigma1=15;
    sigma2=7;

    [ Vin, par] = mrmoveImages2sameCenter( Vin,dcmTags,par );
    [ V, epi, endo, pCall, pRVLV, ~, minRendo ] = mrmakeVolumeIsoMetric(Vin,dcmTags,par);
    
    [nX,nY,nZ] = size(V);
    myspacing = [1 1 1];
    
    temp = cell2mat(pCall')';
    pCx  = temp(:,1);
    pCy  = temp(:,2);
    pC   = [mean(pCx)*ones(1,length(pCx));mean(pCy)*ones(1,length(pCy))]';

    %maxRepi=cell2mat(maxRepi);
    minRendo=cell2mat(minRendo);
else
    nhooodSize1=[23,23,2];
    nhooodSize2=[9,9,2];
    sigma1=15;
    sigma2=7;
    
    [V,par] = mrmoveImages2sameCenter( Vin, par );
    [nX,nY,nZ] = size(V);
    zspacing = mean(mrcalcSliceDistances(dcmTags));
    myspacing = [1 1 zspacing*par.pixelSpacing(1)];
    
    pC = cell2mat(par.pC(:,1)')';
    pRVLV = par.pRVLV(:,1);
    pCx = pC(:,1)+par.FOVcoor(1);
    pCy = pC(:,2)+par.FOVcoor(2);
    epi = par.epiAuto(:,1);
    endo = par.endoAuto(:,1);
    minRendo=zeros(1,nZ);
    for iSlice=1:nZ
        if ~isempty(endo{iSlice})
            epi{iSlice} = epi{iSlice}+repmat(par.FOVcoor(1:2)'-1,1,length(epi{iSlice}));
            endo{iSlice} = endo{iSlice}+repmat(par.FOVcoor(1:2)'-1,1,length(endo{iSlice}));
            minRendo(iSlice) = min(sqrt((endo{iSlice}(1,:)-pCx(iSlice)).^2+(endo{iSlice}(2,:)-pCy(iSlice)).^2));
        end
    end

end

% init and zeros some values
Erc = zeros(nX,nY,nZ,nTimes,3,3);
F0  = zeros(nX,nY,nZ,nTimes,3);
Vq  = zeros(nX,nY,nZ,nTimes);
epiOut  = cell(nZ,nTimes);
endoOut = cell(nZ,nTimes);


figure
iTime = 1;
for iSlice=1:nZ
    hold on
    if ~isempty(epi{iSlice,iTime})
        nPoints = length(epi{iSlice,iTime}(1,:));
        plot3(epi{iSlice,iTime}(1,:),epi{iSlice,iTime}(2,:),iSlice*ones(nPoints,1),'g');
        plot3(endo{iSlice,iTime}(1,:),endo{iSlice,iTime}(2,:),iSlice*ones(nPoints,1),'r');     
    end
    plot3(pCx(1),pCy(2),iSlice,'xb');
    plot3(pC(1),pC(2),nZ/2,'ob')
    hold off
end
view(3)

mymask = calcMask(epi,endo);

% how to make pc in function of z
% [x,y,z]=meshgrid(1:10,1:11,1:12);
% pcx=linspace(5,6,12);pcy = linspace(6,7,12);
% close all,overlayVolume((x-pcx(z)).^2+(y-pcy(z)).^2)

%%% coordinates
[X0,Y0,Z0] = meshgrid(1:nY,1:nX,1:nZ);

X = X0 - pCx(Z0);
Y = Y0 - pCy(Z0);
Z = Z0 - round(nZ/2);

% to cylindrical
R  = sqrt(X.^2+Y.^2);
Th = atan2(Y,X);
Z  = Z;

%%% loop
for t=1:nTimes
    phi = phi_all(t);
    epsilon = epsilon_all(t);
    rad_percent = rad_percent_all(t);
    lambda = lambda_all(t);
    
    ri = minRendo(Z0)*rad_percent;

    r1  = sqrt(minRendo(Z0).^2+(R.^2-ri.^2));
    th1 = (phi*R+Th+epsilon);
    z1  = lambda*Z;
    
    xq1 = r1.*cos(th1);
    yq1 = r1.*sin(th1);
    zq1 = z1;
    
    for iz = 1:nZ
        if ~isempty(epi{iz,1})
            depi(1,:)  = interp2(X(:,:,iz) - xq1(:,:,iz),epi{iz}(1,:),epi{iz}(2,:));
            depi(2,:)  = interp2(Y(:,:,iz) - yq1(:,:,iz),epi{iz}(1,:),epi{iz}(2,:));
            dendo(1,:) = interp2(X(:,:,iz) - xq1(:,:,iz),endo{iz}(1,:),endo{iz}(2,:));
            dendo(2,:) = interp2(Y(:,:,iz) - yq1(:,:,iz),endo{iz}(1,:),endo{iz}(2,:));
            epiOut{iz,t}  = epi{iz}  + depi;
            endoOut{iz,t} = endo{iz} + dendo;
        end
        pCall{iz,t} = [pCx(iz);pCy(iz)];
        pRVLV{iz,t} = pRVLV{iz,1};
    end
    
%     xq1 = xq1 + pCx(Z0);
%     yq1 = yq1 + pCy(Z0);
%     zq1 = zq1 + round(nZ/2);
    xq1 = xq1 + pCx(Z0);
    yq1 = yq1 + pCy(Z0);
    zq1 = zq1 + round(nZ/2);
    
    mymask(:,:,:,t) = interp3(mymask(:,:,:,1),xq1,yq1,zq1);
    mymask(isnan(mymask))=0;
    r  = r1 .*mymask(:,:,:,t) + R .*(1-mymask(:,:,:,t));
    th = th1.*mymask(:,:,:,t) + Th.*(1-mymask(:,:,:,t));
    z  = z1 .*mymask(:,:,:,t) + Z .*(1-mymask(:,:,:,t));
    
    xq = r.*cos(th);
    yq = r.*sin(th);
    zq = z;

    xq = xq + pCx(Z0);
    yq = yq + pCy(Z0);
    zq = zq + round(nZ/2);
    
    F0(:,:,:,t,1) = Y - yq + pCy(Z0);
    F0(:,:,:,t,2) = X - xq + pCx(Z0);
    F0(:,:,:,t,3) = Z - zq + round(nZ/2);
     
    Vq(:,:,:,t) = interp3(V,xq,yq,zq);
    
    [~, Erc(:,:,:,t,:,:)] = strain4(Y-yq,X-xq,Z-zq,[pCx,pCy],myspacing);
end


Erc = reshape(Erc,[nX,nY,nZ,nTimes,9]);

Erc = 100*Erc;
% if I don't do this, calculation of relative error gives very high results
Erc(Erc<1 & Erc>-1)=0; 

% get rid of NaN values
Erc(isnan(Erc))=0;
Vq(isnan(Vq))=0;

% for t=1:nTimes
%     for iz = 1:nZ
%         Vtags = dcmTags
%     end
% end

    function mymask = calcMask(epi,endo)
        maskEpi  = zeros(nX,nY,nZ);
        maskEndo = zeros(nX,nY,nZ);

        g1 = mygauss(nhooodSize1(1),nhooodSize1(2),nhooodSize1(3),sigma1);
        g2 = mygauss(nhooodSize2(1),nhooodSize2(2),nhooodSize2(3),sigma2);
        
        for iz = 1:nZ
            if ~isempty(epi{iz,1})
                maskEpi(:,:,iz)  = poly2mask(epi{iz,1}(1,:),epi{iz,1}(2,:),nX,nY);
                maskEndo(:,:,iz) = 1-poly2mask(endo{iz,1}(1,:),endo{iz,1}(2,:),nX,nY);
            end
        end
        nhood1 = mynhoodSphere(nhooodSize1);
        nhood2 = mynhoodSphere(nhooodSize2);
        %nhood1 = mynhoodCube(sigma1);
        %nhood2 = mynhoodCube(sigma2);
        maskEpi  = imdilate(maskEpi,nhood1);
        maskEndo = imdilate(maskEndo,nhood2);
        maskEpi  = imfilter(maskEpi,g1);
        maskEndo = imfilter(maskEndo,g2);
        maskEpi  = maskEpi./max(maskEpi(:));
        maskEndo = maskEndo./max(maskEndo(:));
        mymask = min(maskEpi,maskEndo);
        %overlayVolume(maskEpi);
        %overlayVolume(maskEndo);
        %overlayVolume(mymask);
        %overlayVolume(mymask.*~(maskEpi1&~maskEndo1))
    end

    function f=mygauss(nx,ny,nz,sigma)
        [xx,yy,zz]=ndgrid(1:nx,1:ny,1:nz);
        rrr=sqrt(floor(xx-nx/2).^2+floor(yy-ny/2).^2+floor(zz-nz/2).^2);
        f=exp(-(rrr/sigma).^2);
    end

    function nhood=mynhoodSphere(ns)
        ns2 = round(ns/2);
        [xx,yy,zz]=ndgrid(-ns2(1):ns2(1),-ns2(2):ns2(2),-ns2(3):ns2(3));
        nhood = sqrt( (xx/ns2(1)).^2 + (yy/ns2(2)).^2 + (zz/ns2(3)).^2 ) <= 1;
    end

    function nhood=mynhoodCube(sig)
        nhood=ones(2*sig,2*sig,2*sig);
    end
        
disp('Simulation time:')
toc(mytic)
%overlayVolume(Vq)
end
