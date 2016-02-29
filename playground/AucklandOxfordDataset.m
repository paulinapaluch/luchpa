clear
close all

matFile = '/Volumes/Seagate/MAT/Auckland/ModelFittinfOxford/dataset.mat';
load(matFile)

iSlice = 3;
imshow(img_heart(:,:,iSlice),[])
hold on
plot(XY_A_heart{iSlice}(:,1),XY_A_heart{iSlice}(:,2),'-r')
%plot(XY_B_heart{iSlice}(:,2),XY_B_heart{iSlice}(:,1),'-g')
hold off

%V = MRViewer3Dt(img_heart); V.setAspectRatio([1 1 15])