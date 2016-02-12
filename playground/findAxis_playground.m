matDir = '/Volumes/My Passport/MAT/CRT4/Tag_CRT_001/NonameStudy';

M = MRDataCINE.load(matDir);
M.calcbreathingCorrection;
%%
data = M.data;

Fdata = fft(data,[],4);
harm0 = abs(Fdata(:,:,:,1));
harm1 = abs(Fdata(:,:,:,2));
harm1end = abs(sum(Fdata(:,:,1,2:end),4));

harm1m = harm1;
for s=1:size(harm1,3)
    harm1m(:,:,s) = imgaussfilt(harm1(:,:,s));
end
harm1m(harm1m<max(harm1m(:))*.05)=0;

%%
z = 1:size(harm1,3);
for s=1:size(harm1,3)
    [r,c]=find(harm1(:,:,s));
    [~,cent(s,:)]=kmeans([r,c],1);
end
hold on
plot3(cent(:,1),cent(:,2),z','o')
hold off

%% linear regression
z = 1:size(harm1,3);
[m,p,s] = best_fit_line(cent(:,1),cent(:,2),z');
t = (z - m(3))/p(3);
lr(:,1) = m(1) + p(1)*t;
lr(:,2) = m(2) + p(2)*t;
hold on
plot3(lr(:,1),lr(:,2),z,'o')
hold off

%%
mymask = zeros(size(harm1m));
harm1m2 = zeros(size(harm1m));
for s=1:size(harm1,3)
    temp1 = harm1m(:,:,s);disp(length(find(temp1)));
    temp0 = harm0(:,:,s);
    [idx] = find(temp1);
    [x,y] = ind2sub(size(temp1),idx);
    d=sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
    %dw = d.*temp0(idx); % weighting does not do well
    %dw = d.*temp1(idx); % weighting does not do well
    dw = d;
    
    [mu,sig] = normfit(dw);
    
    subplot(211),imshow(temp1>0,[])
    temp1(idx(dw>mu+1.2*sig))=0;
    %temp1(idx(dw<mu-sig))=0;
    subplot(212),imshow(temp1>0,[])
    harm1m2(:,:,s) = temp1;disp(length(find(temp1)));
    
    [idx] = find(temp1);
    [x,y] = ind2sub(size(temp1),idx);
    d=sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
    mydist(s) = mean(d);
    [xx,yy]=ndgrid(1:size(temp1,1),1:size(temp1,2));
    tempMask = zeros(size(temp1));
    tempMask((xx-lr(s,1)).^2+(yy-lr(s,2)).^2<mydist(s).^2)=1;
    mymask(:,:,s)=tempMask;
end

%% pca?
clf
[idx] = find(harm1m2);
v = harm1(idx);
[x,y,z] = ind2sub(size(harm1m),idx);
a = pca([x,y,z,v/10]);
%plot3(x,y,z,'.'),hold on
scatter3(x,y,z,1,v),hold on
quiver3([0 0 0],[0 0 0],[0 0 0],3*a(1:3,1)',3*a(1:3,2)',a(1:3,3)',10),hold off

%% plot harmonic
s=4;
subplot(121)
imshow(harm1(:,:,s),[]),colorbar
subplot(122)
imshow(harm1m(:,:,s),[]),colorbar
title('with gauss filter and cut of lowest 5%')

%% plot harmonic and
s=8;
imshow(harm1(:,:,s),[]),colorbar,hold on
plot(cent(s,2),cent(s,1),'o');hold off

 

