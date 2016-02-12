function [Exy Erc]=strain3(Ux,Uy,pcenter)
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

% Initialize output matrix
Exy=zeros([size(Ux) 2 2]);
Erc=zeros([size(Ux) 2 2]);
% displacement images gradients
[Uxy,Uxx] = gradient(Ux);
[Uyy,Uyx] = gradient(Uy);

[X,Y] = meshgrid(1:size(Ux,2),1:size(Ux,1));
XR = X - pcenter(1);     YR = pcenter(2)-Y;

Uxx(isnan(Uxx(:)))=0;
Uxy(isnan(Uxy(:)))=0;
Uyx(isnan(Uyx(:)))=0;
Uyy(isnan(Uyy(:)))=0;

%%% fast way (100x faster then elegant way below) 

Finv11 = 1-Uxx;
Finv12 = -Uxy;
Finv21 = -Uyx;
Finv22 = 1-Uyy;

exy11 = .5*(1-(Finv11.^2+Finv12.^2));
exy12 = -.5*(Finv11.*Finv21+Finv12.*Finv22);
exy21 = exy12;
exy22 = .5*(1-(Finv21.^2+Finv22.^2));

% Q denominator 
Qden = sqrt(XR.^2+YR.^2);
Q11 = XR./Qden;
Q12 = YR./Qden;
Q21 = -YR./Qden;
Q22 = XR./Qden;

erc11 = Q11.*(exy11.*Q11 + exy21.*Q12) + Q12.*(exy12.*Q11 + exy22.*Q12);
erc12 = Q21.*(exy11.*Q11 + exy21.*Q12) + Q22.*(exy12.*Q11 + exy22.*Q12);
erc21 = Q11.*(exy11.*Q21 + exy21.*Q22) + Q12.*(exy12.*Q21 + exy22.*Q22);
erc22 = Q21.*(exy11.*Q21 + exy21.*Q22) + Q22.*(exy12.*Q21 + exy22.*Q22);

Exy(:,:,1,1) = exy11;
Exy(:,:,1,2) = exy12;
Exy(:,:,2,1) = exy21;
Exy(:,:,2,2) = exy22;

Erc(:,:,1,1) = -erc11;
Erc(:,:,1,2) = -erc12;
Erc(:,:,2,1) = -erc21;
Erc(:,:,2,2) = -erc22;

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




 
