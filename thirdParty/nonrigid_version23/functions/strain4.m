function [Exy Erc]=strain4(Ux,Uy,Uz,pC,myspacing)
% function [Exy Erc]=strain4(Ux,Uy,Uz,pCx,pCy)
% Calculate the Eulerian strain from displacement images
%
%  E = STRAIN(Ux,Uy)   or (3D)  E = STRAIN(Ux,Uy, Uz)
%
% inputs,
%   Ux,Uy: The displacement vector images in
%           x and y direction (same as registration variables Tx, Ty)
%   Uz: The displacement vector image in z direction.
%
% outputs,
%   E the 3-D Eulerian strain tensor images defined by Lai et al. 1993
%      with dimensions [SizeX SizeY 2 2] or in 3D [SizeX SizeY SizeZ 3 3]
%
% Source used:
%   Khaled Z et al. "Direct Three-Dimensional Myocardial Strain Tensor 
%   Quantification and Tracking using zHARP"
%
% Function is written by D.Kroon University of Twente (February 2009)
% Modified by Konrad Werys (March 2014)

if ~exist('myspacing','var')
    myspacing=[1 1 1];
end

% Initialize output matrix
Exy=zeros([size(Ux) 1 3 3]);
Erc=zeros([size(Ux) 1 3 3]);
% displacement images gradients
[Uxy,Uxx,Uxz] = gradient(Ux,myspacing(1),myspacing(2),myspacing(3));
[Uyy,Uyx,Uyz] = gradient(Uy,myspacing(1),myspacing(2),myspacing(3));
[Uzy,Uzx,Uzz] = gradient(Uz,myspacing(1),myspacing(2),myspacing(3));

% Uzy=zeros(size(Uyx));
% Uzx=Uzy;
% Uzz=Uzy;
% Uxz=Uzy;
% Uyz=Uzy;

[X,Y,Z] = meshgrid(1:size(Ux,2),1:size(Ux,1),1:size(Ux,3));
if (size(pC,1)==1 && size(pC,2)==2) || (size(pC,1)==2 && size(pC,2)==1)
    XR = X - pC(1);     
    YR = pC(2)-Y;
else
    pCx = pC(:,1);
    pCy = pC(:,2);
    XR = X - pCx(Z);     
    YR = pCy(Z)-Y;
    
end

Uxx(isnan(Uxx(:)))=0;
Uxy(isnan(Uxy(:)))=0;
Uxz(isnan(Uxz(:)))=0;
Uyx(isnan(Uyx(:)))=0;
Uyy(isnan(Uyy(:)))=0;
Uyz(isnan(Uyz(:)))=0;
Uzx(isnan(Uzx(:)))=0;
Uzy(isnan(Uzy(:)))=0;
Uzz(isnan(Uzz(:)))=0;

%%% fast way (100x faster then elegant way below) 

Finv11 = 1-Uxx;
Finv12 =  -Uxy;
Finv13 =  -Uxz;
Finv21 =  -Uyx;
Finv22 = 1-Uyy;
Finv23 =  -Uyz;
Finv31 =  -Uzx;
Finv32 =  -Uzy;
Finv33 = 1-Uzz;

exy11 = .5.*( 1 - (Finv11.*Finv11 + Finv12.*Finv12 + Finv13.*Finv13));
exy12 = .5.*(   - (Finv11.*Finv21 + Finv12.*Finv22 + Finv13.*Finv23)); 
exy13 = .5.*(   - (Finv11.*Finv31 + Finv12.*Finv32 + Finv13.*Finv33));
exy21 = .5.*(   - (Finv21.*Finv11 + Finv22.*Finv12 + Finv23.*Finv13)); 
exy22 = .5.*( 1 - (Finv21.*Finv21 + Finv22.*Finv22 + Finv23.*Finv23)); 
exy23 = .5.*(   - (Finv21.*Finv31 + Finv22.*Finv32 + Finv23.*Finv33));
exy31 = .5.*(   - (Finv31.*Finv11 + Finv32.*Finv12 + Finv33.*Finv13)); 
exy32 = .5.*(   - (Finv31.*Finv21 + Finv32.*Finv22 + Finv33.*Finv23)); 
exy33 = .5.*( 1 - (Finv31.*Finv31 + Finv32.*Finv32 + Finv33.*Finv33));

% Q denominator 
Qden = sqrt(XR.^2+YR.^2);
Q11 = XR./Qden;
Q12 = YR./Qden;
Q21 = -YR./Qden;
Q22 = XR./Qden;
Q33 = 1;

% syms f11 f12 f13 f21 f22 f23 f31 f32 f33 q11 q12 q13 q21 q22 q23 q31 q32 q33 real
% F=[f11 f12 f13; f21 f22 f23; f31 f32 f33];
% Q=[q11 q12 0;q21 q22 0; 0 0 q33]
% Q*F*Q'

erc11 = Q11.*(exy11.*Q11 + exy21.*Q12) + Q12.*(exy12.*Q11 + exy22.*Q12);
erc12 = Q21.*(exy11.*Q11 + exy21.*Q12) + Q22.*(exy12.*Q11 + exy22.*Q12);
erc13 = Q33.*(exy13.*Q11 + exy23.*Q12);
erc21 = Q11.*(exy11.*Q21 + exy21.*Q22) + Q12.*(exy12.*Q21 + exy22.*Q22);
erc22 = Q21.*(exy11.*Q21 + exy21.*Q22) + Q22.*(exy12.*Q21 + exy22.*Q22);
erc23 = Q33.*(exy13.*Q21 + exy23.*Q22);
erc31 = exy31.*Q11.*Q33 + exy32.*Q12.*Q33;
erc32 = exy31.*Q21.*Q33 + exy32.*Q22.*Q33;
erc33 = exy33.*Q33.^2;


Exy(:,:,:,1,1,1) = exy11;
Exy(:,:,:,1,1,2) = exy12;
Exy(:,:,:,1,1,3) = exy13;
Exy(:,:,:,1,2,1) = exy21;
Exy(:,:,:,1,2,2) = exy22;
Exy(:,:,:,1,2,3) = exy23;
Exy(:,:,:,1,3,1) = exy31;
Exy(:,:,:,1,3,2) = exy32;
Exy(:,:,:,1,3,3) = exy33;

Erc(:,:,:,1,1,1) = -erc11;
Erc(:,:,:,1,1,2) = -erc12;
Erc(:,:,:,1,1,3) = -erc13;
Erc(:,:,:,1,2,1) = -erc21;
Erc(:,:,:,1,2,2) = -erc22;
Erc(:,:,:,1,2,3) = -erc23;
Erc(:,:,:,1,3,1) = -erc31;
Erc(:,:,:,1,3,2) = -erc32;
Erc(:,:,:,1,3,3) = -erc33;

% %%% elegant way
% % Loop through all pixel locations
% for i=1:size(Ux,1)
%     for j=1:size(Ux,2)
%         % The displacement gradient
%         Ugrad=[Uxx(i,j) Uxy(i,j); Uyx(i,j) Uyy(i,j)];
%         % The (inverse) deformation gradient
%         Finv=[1 0;0 1]-Ugrad;  %F=inv(Finv);
%         % the 2-D Eulerian strain tensor in cartesian coordinates
%         exy=(1/2)*([1 0;0 1]-Finv*Finv');
%         % the 2-D Eulerian strain tensor in radial coordinates
%         Q = [XR(i,j), YR(i,j); -YR(i,j), XR(i,j)]/norm([XR(i,j),YR(i,j)]);
%         erc=Q*exy*Q';
%         % Store tensor in the output matrix
%         Exy(i,j,:,:)=exy;
%         Erc(i,j,:,:)=-erc;
%     end
% end




 
