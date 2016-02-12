function [Exy Erc]=strain2(Ux,Uy,pcenter)
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

[X,Y] = meshgrid(1:size(Ux,1),1:size(Ux,2));
XR = X - pcenter(1);     YR = pcenter(2)-Y;

% Loop through all pixel locations
for i=1:size(Ux,1)
    for j=1:size(Ux,2)
        % The displacement gradient
        Ugrad=[Uxx(i,j) Uxy(i,j); Uyx(i,j) Uyy(i,j)];
        % The (inverse) deformation gradient
        Finv=[1 0;0 1]-Ugrad;  %F=inv(Finv);
        % the 2-D Eulerian strain tensor in cartesian coordinates
        exy=(1/2)*([1 0;0 1]-Finv*Finv');
        % the 2-D Eulerian strain tensor in radial coordinates
        Q = [XR(i,j), YR(i,j); -YR(i,j), XR(i,j)]/norm([XR(i,j),YR(i,j)]);
        erc=Q*exy*Q';
        % Store tensor in the output matrix
        Exy(i,j,:,:)=exy;
        Erc(i,j,:,:)=-erc;
    end
end


 
