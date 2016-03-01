clear

inFile = '/Users/konrad/Data/MAT/Tag_Volunteer_006/CINE_retro_SAALL_pen3_ref3/mrData.mat';
outPath = '/Users/konrad/Dropbox/Apps/ShareLaTeX/PHD_image_registration_review/pic/raw/';

load(inFile)

[nX,nY,nS,nT]=size(mrData);
I1 = mrData(:,:,5,1);
I2 = mrData(:,:,5,9);

% BSPLINES
dfopts=struct(...
    'Similarity',[],...
    'Registration','NonRigid',...
    'Penalty',1e-3,...
    'MaxRef',2,...
    'Grid',[],...
    'Spacing',[],...
    'MaskMoving',[],...
    'MaskStatic',[],...
    'Verbose',2,...
    'Points1',[],...
    'Points2',[],...
    'PStrength',[],...
    'Interpolation','Linear',...
    'Scaling',[1 1]);
[Ireg0,O_trans0,Spacing0,M0,B0,F0] = image_registration(I1,I2,dfopts);
[grid_tran_plot0,grid_init0]=correctGrid(O_trans0,Spacing0,I1);

myoptions = dfopts;
myoptions.Spacing = [64 64];
myoptions.MaxRef = 0;

myparam = 'Spacing';
vals = {[8 8]; [4 4]; [2 2]};
% myparam = 'MaxRef';
% vals = {5, 4, 3, 2};
nvals = length(vals);

for i = 1:nvals    
    myoptions.(myparam)=vals{i};
    [Ireg(:,:,i),O_trans{i},Spacing(i,:),~,B(:,:,:,i),F(:,:,:,i)] = image_registration(I1,I2,myoptions);
    [grid_tran_plot{i},grid_init{i}]=correctGrid(O_trans{i},Spacing(i,:),I1);
end
%
Bx_temp = reshape(B(:,:,1,:),[nX,nY*nvals]);
By_temp = reshape(B(:,:,2,:),[nX,nY*nvals]);
figure(1)
imshow([B0(:,:,1),Bx_temp;B0(:,:,2),By_temp],[])
title(vals)
ylabel('x/y')
% %% show pics
% close all
% myclim = [0 350];
% 
% hFig1=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax1=subplot('Position',[0 0 1 1]);
% imshow(I1,myclim)
% 
% hFig2=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(I2,myclim)
% 
% hFig3=figure('position',[800 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(Ireg,myclim)
% 
% hFig4=figure('position',[0 400 500 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax4=subplot('Position',[.15 .15 .8 .85],'clim',myclim);
% surf(I1,'EdgeColor','none');colormap gray
% set(ax4,'YDir','reverse'),view([-35,60])
% set(ax4,'xlim',[1 nX]),set(ax4,'ylim',[1 nY]),set(ax4,'zlim',[1 500])
% xlabel('x_2'),ylabel('x_1'),zlabel('signal')
% makePretty(hFig4)
% 
% print(hFig1,'-dpng',fullfile(outPath,'M.png'))
% print(hFig2,'-dpng',fullfile(outPath,'S.png'))
% print(hFig3,'-dpng',fullfile(outPath,'MT.png'))
% print(hFig4,'-dpng',fullfile(outPath,'M_mesh.png'))
% 
% %% show pics with grid
% close all
% hFig1=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(I1,myclim),hold on
% % oy=grid_init(:,:,1);ox=grid_init(:,:,2);
% % plot(ox(:),oy(:),'.'),hold off
% plotGrid(grid_init)
% 
% hFig2=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(I2,myclim),hold on
% % oy=grid_tran_plot(:,:,1);ox=grid_tran_plot(:,:,2);
% % plot(ox(:),oy(:),'.'),hold off
% plotGrid(grid_tran_plot)
% 
% hFig3=figure('position',[800 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(Ireg,myclim),hold on
% %oy=grid_tran_plot(:,:,1);ox=grid_tran_plot(:,:,2);
% %plot(ox(:),oy(:),'.'),hold off
% plotGrid(grid_tran_plot)
% 
% %% show BX BY
% close all
% myclim=[-5 5];
% hFig1=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(-B(:,:,2),myclim)
% text(5,5,'u_1','VerticalAlignment','top')
% makePretty(hFig1),set(findall(hFig1,'type','text'),'Color',[0 0 0])
% 
% hFig2=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(-B(:,:,1),myclim)
% text(5,5,'u_2','VerticalAlignment','top')
% makePretty(hFig2),set(findall(hFig2,'type','text'),'Color',[0 0 0])
% 
% hFig3=figure('position',[0 400 500 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax3=subplot('Position',[.15 .15 .8 .85],'clim',myclim);
% surf(-B(:,:,2),'EdgeColor','none');colormap gray
% set(ax3,'YDir','reverse'),view([-35,60])
% set(ax3,'xlim',[1 nX]),set(ax3,'ylim',[1 nY]),set(ax3,'zlim',[-5 5])
% xlabel('x_2'),ylabel('x_1'),zlabel('u_1')
% makePretty(hFig3)
% 
% hFig4=figure('position',[500 400 500 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax4=subplot('Position',[.15 .15 .8 .85],'clim',myclim);
% surf(-B(:,:,1),'EdgeColor','none');colormap gray
% set(ax4,'YDir','reverse'),view([-35,60])
% set(ax4,'xlim',[1 nX]),set(ax4,'ylim',[1 nY]),set(ax4,'zlim',[-5 5])
% xlabel('x_2'),ylabel('x_1'),zlabel('u_2')
% makePretty(hFig4)
% 
% hFig5=figure('position',[800 0 20 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% colormap gray
% axis off
% colorbar([0.1 0.05  0.5  0.9]);
% set(gca,'CLim',myclim)
% makePretty(hFig5),set(findall(hFig5,'type','axes'),'YGrid','off','XColor',[.1 .1 .1],'YColor',[.1 .1 .1],'Box','on')
% 
% print(hFig1,'-dpng',fullfile(outPath,'ux_image.png'))
% print(hFig2,'-dpng',fullfile(outPath,'uy_image.png'))
% print(hFig3,'-dpng',fullfile(outPath,'ux_mesh.png'))
% print(hFig4,'-dpng',fullfile(outPath,'uy_mesh.png'))
% print(hFig5,'-dpng',fullfile(outPath,'uxy_colorbar.png'))
% %% quiver
% close all
% myclim=[0 350];
% space=5;
% xrange = 1:space:nX; yrange = 1:space:nY; 
% [x,y]=ndgrid(xrange,yrange);
% u=-B(xrange,yrange,2);
% v=-B(xrange,yrange,1);
% hFig1=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax1=subplot('Position',[0 0 1 1]);
% imshow(I1,myclim),hold on
% quiver(y,x,-B(xrange,yrange,2),-B(xrange,yrange,1),1.5,'markersize',30);hold off
% 
% space=5;
% xrange = 1:space:nX; yrange = 1:space:nY; 
% [x,y]=ndgrid(xrange,yrange);
% u=-B(xrange,yrange,2);
% v=-B(xrange,yrange,1);
% hFig2=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax2=subplot('Position',[0 0 1 1]);
% quiverc(y,x,-B(xrange,yrange,2),-B(xrange,yrange,1),1.5)
% axis([1 128 1 128])
% 
% space=10;
% xrange = 1:space:nX; yrange = 1:space:nY; 
% [x,y]=ndgrid(xrange,yrange);
% u=-B(xrange,yrange,2);
% v=-B(xrange,yrange,1);
% hFig3=figure('position',[0 400 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax3=subplot('Position',[0 0 1 1]);
% quiverc(y,x,-B(xrange,yrange,2),-B(xrange,yrange,1),2)
% axis([1 128 1 128])
% 
% space=10;
% xrange = 1:space:nX; yrange = 1:space:nY; 
% [x,y]=ndgrid(xrange,yrange);
% u=-B(xrange,yrange,2);
% v=-B(xrange,yrange,1);
% hFig4=figure('position',[400 400 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax4=subplot('Position',[0 0 1 1]);
% quiverc(y,x,-B(xrange,yrange,2),-B(xrange,yrange,1),8)
% axis([1 128 1 128])
% 
% print(hFig1,'-dpng',fullfile(outPath,'uxy_quiver.png'))
% print(hFig2,'-dpng',fullfile(outPath,'uxy_quiver2.png'))
% print(hFig3,'-dpng',fullfile(outPath,'T_ok.png'))
% print(hFig4,'-dpng',fullfile(outPath,'T_nok.png'))
% %% show TX TY
% close all
% myclim=[0 128];
% [x,y]=ndgrid(1:nX,1:nY);
% TX = x-3*B(:,:,1);
% TY = y-3*B(:,:,2);
% 
% hFig1=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(TX,myclim)
% text(5,5,'T_1','VerticalAlignment','top')
% makePretty(hFig1),set(findall(hFig1,'type','text'),'Color',[1 1 1])
% 
% hFig2=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% subplot('Position',[0 0 1 1]);
% imshow(TY,myclim)
% text(5,5,'T_2','VerticalAlignment','top')
% makePretty(hFig2),set(findall(hFig2,'type','text'),'Color',[1 1 1])
% 
% hFig3=figure('position',[0 400 500 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax3=subplot('Position',[.17 .15 .75 .85],'clim',myclim);
% surf(TX,'EdgeColor','none');colormap gray
% set(ax3,'YDir','reverse'),view([-35,60])
% set(ax3,'xlim',[1 nX]),set(ax3,'ylim',[1 nY]),set(ax3,'zlim',[-10 nY])
% xlabel('x_2'),ylabel('x_1'),zlabel('T_1')
% makePretty(hFig3)
% 
% hFig4=figure('position',[500 400 500 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% ax4=subplot('Position',[.17 .15 .75 .85],'clim',myclim);
% surf(TY,'EdgeColor','none');colormap gray
% set(ax4,'YDir','reverse'),view([-35,60])
% set(ax4,'xlim',[1 nX]),set(ax4,'ylim',[1 nY]),set(ax4,'zlim',[-10 nY])
% xlabel('x_2'),ylabel('x_1'),zlabel('T_2')
% makePretty(hFig4)
% 
% hFig5=figure('position',[800 0 20 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
% colormap gray
% axis off
% colorbar([0.1 0.05  0.5  0.9]);
% set(gca,'CLim',myclim)
% makePretty(hFig5),set(findall(hFig5,'type','axes'),'YGrid','off','XColor',[.1 .1 .1],'YColor',[.1 .1 .1],'Box','on')
% 
% print(hFig1,'-dpng',fullfile(outPath,'Tx_image.png'))
% print(hFig2,'-dpng',fullfile(outPath,'Ty_image.png'))
% print(hFig3,'-dpng',fullfile(outPath,'Tx_mesh.png'))
% print(hFig4,'-dpng',fullfile(outPath,'Ty_mesh.png'))
% print(hFig5,'-dpng',fullfile(outPath,'Txy_colorbar.png'))

%% show pics with different grid spacing
close all
myclim=[0 350];
hFig1=figure('position',[0 400 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(I1,myclim)

hFig2=figure('position',[400 400 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(I2,myclim)

hFig3=figure('position',[800 400 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(Ireg0,myclim),hold on
plotGrid(grid_tran_plot0)

hFig4=figure('position',[0 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(Ireg(:,:,1),myclim),hold on
plotGrid(grid_tran_plot{1})

hFig5=figure('position',[400 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(Ireg(:,:,2),myclim),hold on
plotGrid(grid_tran_plot{2})

hFig6=figure('position',[800 0 400 400],'Color',[1 1 1],'PaperPositionMode', 'auto');
subplot('Position',[0 0 1 1]);
imshow(Ireg(:,:,3),myclim),hold on
plotGrid(grid_tran_plot{3})


% print(hFig1,'-dpng',fullfile(outPath,'refinement_S.png'))
% print(hFig2,'-dpng',fullfile(outPath,'refinement_M1.png'))
% print(hFig3,'-dpng',fullfile(outPath,'refinement_M2.png'))
% print(hFig4,'-dpng',fullfile(outPath,'refinement_M3.png'))
