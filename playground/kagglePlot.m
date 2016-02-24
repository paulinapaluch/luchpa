function kagglePlot(M,harm1mt,maskTh,cent,mytitle)
clf
ptt = round(cent(end,:));
s = ptt(3);
    
volumes = M.getVolumes;
[~,tSys] = min(volumes);
[~,tDia] = max(volumes);

BW = M.autoSegMask(:,:,s,1);
regs = regionprops(BW,'Centroid');

subplot(241)
imshow(bwlabel(maskTh(:,:,ptt(3),1)),[]),hold on
plot(cent(end,2)',cent(end,1)','kx'),hold off
title(mytitle)

subplot(242)
temp = repmat(M.data(:,:,s,1)./max(M.data(:))*4,[1,1,3]);
temp(:,:,2) = temp(:,:,2).*~M.autoSegMask(:,:,s,1);
temp(:,:,3) = temp(:,:,2).*~M.autoSegMask(:,:,s,1); 
imshow(temp),title('First')
if ~isempty(regs),hold on, plot(regs.Centroid(1),regs.Centroid(2),'gx'),hold off;end

subplot(243)
temp = repmat(M.data(:,:,s,tDia)./max(M.data(:))*4,[1,1,3]);
temp(:,:,2) = temp(:,:,2).*~M.autoSegMask(:,:,s,tDia);
temp(:,:,3) = temp(:,:,2).*~M.autoSegMask(:,:,s,tDia);
imshow(temp),title('ED')

subplot(244)
temp = repmat(M.data(:,:,s,tSys)./max(M.data(:))*3,[1,1,3]);
temp(:,:,2) = temp(:,:,2).*~M.autoSegMask(:,:,s,tSys);
temp(:,:,3) = temp(:,:,2).*~M.autoSegMask(:,:,s,tSys);
imshow(temp),title('Es')

subplot(245),
plot(volumes),hold on
plot(tDia,volumes(tDia),'o')
plot(tSys,volumes(tSys),'o'),hold off
ylabel('LV volume')
title(mytitle)

subplot(246)
imshow(harm1mt(:,:,ptt(3)),[]),hold on
plot(cent(:,2),cent(:,1),'o')
plot(cent(end,2)',cent(end,1)','go'),hold off
title('final H1')

hax(7) = subplot(247);cla
p = patch(isosurface(M.autoSegMask(:,:,:,1)));title('First')
p.FaceColor = 'red';
p.EdgeColor = 'none';
set(gca,'ZDir','reverse');
view(3),l = light;lightangle(l,90,30)
axis('tight')
zlim([1 M.nSlices])

hax(8) = subplot(248);cla
p = patch(isosurface(M.autoSegMask(:,:,:,tSys)));title('ES')
p.FaceColor = 'red';
p.EdgeColor = 'none';
%set(gca,'DataAspectRatio',1./M.aspectRatio)
set(gca,'ZDir','reverse');
view(3),l = light;lightangle(l,90,30)
axis('tight')
zlim([1 M.nSlices])

colormap jet
drawnow
end