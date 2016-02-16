function [cent,harm1mt,maskSeg,line1coors,line2coors] = calcFinalCentroid3d(data,aspectRatio)
line1coors=[];
line2coors=[];

[harm1m] = calcFilteredHarmonic(data);
cent(1,:) = calcKMeansCentroid3d(harm1m);
harm1mt=harm1m;

iter=1;
centDist = inf;
mydistmm = inf;
mymulti0 = 2;
mymulti = mymulti0;

while (centDist>1 || mydistmm>70) && iter<100
    iter=iter+1;
    cents = calcKMeansCentroids(data);
    lr = calcLRpoints(cents);
    for s=1:size(data,3)
        [x,y]=ndgrid(1:size(data,1),1:size(data,2));
        distPic(:,:,s) = sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
    end
    distr = calcDistr(harm1mt,lr);
    [mu,sig] = normfit(distr);
    idx=find(harm1mt);
    mydist = mu+mymulti*sig;
    mydistmm = mydist*aspectRatio(1);
    idx_toDelete1 = idx(distr>mydist);
    %idx_toDelete2 = idx(distr<mu-sig);
    harm1mt(idx_toDelete1)=0;
    %harm1mt(idx_toDelete2)=0;
    
    maskCirc = distPic<mydist;
    cent(iter,:) = calcKMeansCentroid3d(harm1mt);
    
    centDist = sqrt(sum((cent(iter,:)-cent(iter-1,:)).^2));
    if centDist<1
        mymulti=mymulti*0.9;
    end
    if centDist>2
        mymulti=mymulti*1.1;
    end
end
fprintf('Iterations %d, distance %.2f\n',iter, mydistmm)

%[vecs] = calcPCA3d(harm1m,data(:,:,:,1));

s = round(cent(iter,3));

%%% GMM
maskSeg = zeros(size(data));
maskedDataS=data(:,:,s,1).*maskCirc(:,:,s);
maskedDataSvec = maskedDataS(find(maskedDataS));
obj = fitgmdist(maskedDataSvec,3);
[maxmu,idxmaxmu] = max(obj.mu);
sigma = obj.Sigma(1,1,idxmaxmu);
threshold = maxmu*.75;

maskCirc = repmat(maskCirc,[1,1,1,size(data,4)]); % fill maskCirc in temporal direction
maskTh = data.*maskCirc>threshold;

% 3d region props, kinda shitty results
% regs = regionprops(maskTh,'Centroid','PixelIdxList','Area');
% regsCents = cell2mat({regs.Centroid}');
% for ireg = 1:length(regs)
%     dist(ireg) = sqrt(sum((regsCents(ireg,:).*aspectRatio-cent(iter,:).*aspectRatio).^2));
% end
% [~,idx] = min(dist);
% regs(idx)

%mask = bwmorph(mask,'clean');

maskTh = imfill(maskTh,'holes');

[maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosesTo(maskTh(:,:,s),cent(iter,1:2));

islicesdown = flip(1:s-1);
islicesup = s+1:size(data,3);
for s=islicesdown
    [maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosesTo(maskTh(:,:,s),newcent{s+1,1});
end
for s=islicesup
    [maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosesTo(maskTh(:,:,s),newcent{s-1,1});
end
%     
% regs = regionprops(maskTh(:,:,s),'Centroid','ConvexHull');
% regsCents = cell2mat({regs.Centroid}');
% dist=zeros(1,length(regs));
% for ireg = 1:length(regs)
%     dist(ireg) = sqrt(sum((regsCents(ireg,:)-cent(iter,1:2)).^2));
% end
% 
% [~,idx] = min(dist);
% newcent{s,1} = regsCents(idx,:);
% ch = regs(idx).ConvexHull;
% mask2d = poly2mask(ch(:,1),ch(:,2),size(data,1),size(data,2));
% %imshow(mask2d,[])
% maskSeg(:,:,s,1) = mask2d;
% 
% islicesdown = flip(1:s-1);
% islicesup = s+1:size(data,3);
% for s=islicesdown
%     regs = regionprops(maskTh(:,:,s),'Centroid','ConvexHull');
%     if length(regs)>0
%         regsCents = cell2mat({regs.Centroid}');
%         dist=zeros(1,length(regs));
%         for ireg = 1:length(regs)
%             dist(ireg) = sqrt(sum((regsCents(ireg,:)-newcent{s+1,1}).^2));
%         end
%         [~,idx] = min(dist);
%         newcent{s,1} = regsCents(idx,:);
%         ch = regs(idx).ConvexHull;
%         mask2d = poly2mask(ch(:,1),ch(:,2),size(data,1),size(data,2));
%         maskSeg(:,:,s,1) = mask2d;
%     end
% end
% for s=islicesup
%     regs = regionprops(maskTh(:,:,s),'Centroid','ConvexHull');
%     if length(regs)>0
%         regsCents = cell2mat({regs.Centroid}');
%         dist=zeros(1,length(regs));
%         for ireg = 1:length(regs)
%             dist(ireg) = sqrt(sum((regsCents(ireg,:)-newcent{s-1,1}).^2));
%         end
%         [~,idx] = min(dist);
%         newcent{s,1} = regsCents(idx,:);
%         ch = regs(idx).ConvexHull;
%         mask2d = poly2mask(ch(:,1),ch(:,2),size(data,1),size(data,2));
%         maskSeg(:,:,s,1) = mask2d;
%     end
% end


% %%% morphological orientation of the biggest region - not working
% BW = harm1mt>0;
% stats = regionprops(imfill(BW(:,:,s),'holes'),'Orientation','Area');
% [~,idx]=max(cell2mat({stats.Area}'));
% stats(idx).Orientation;
% 
% %%% 3d or 2d PCA - not working
% [vecs] = calcPCA2d(data(:,:,s,1).*maskTh(:,:,s));
% for s=1:size(data,3)
%     p=cents(s,1:2);
%     %%% line1
%     p1 = p-vecs(1,1:2)*mydist;
%     p2 = p+vecs(1,1:2)*mydist;
%     line1coors{s}(:,1) = linspace(p1(1),p2(1),100);
%     line1coors{s}(:,2) = linspace(p1(2),p2(2),100);
%     %%% line2
%     p1 = p-vecs(2,1:2)*mydist;
%     p2 = p+vecs(2,1:2)*mydist;
%     line2coors{s}(:,1) = linspace(p1(1),p2(1),100);
%     line2coors{s}(:,2) = linspace(p1(2),p2(2),100);
% end

% clf
% s = round(cent(iter,3));
% subplot(121)
% imshow(data(:,:,s,1),[]),hold on
% plot(line1coors{s}(:,1),line1coors{s}(:,2),line2coors{s}(:,1),line2coors{s}(:,2),'-'),hold off
% subplot(122)
% plot(interp2(data(:,:,s,1),line1coors{s}(:,1),line1coors{s}(:,2))),hold on
% plot(interp2(data(:,:,s,1),line2coors{s}(:,1),line2coors{s}(:,2))),hold off


% vecs(1:3,1:3)
% sqrt(sum(vecs(:,1:2).^2))
end

function [maskConvHull,cent,mypoly] = chooseRegClosesTo(BW,pos)
maskConvHull = zeros(size(BW));
cent = pos;
mypoly=[];

regs = regionprops(BW,'Centroid','ConvexHull');
if ~isempty(regs)
    regsCents = cell2mat({regs.Centroid}');
    dist=zeros(1,length(regs));
    for ireg = 1:length(regs)
        dist(ireg) = sqrt(sum((regsCents(ireg,:)-pos).^2));
    end
    [~,idx] = min(dist);
    cent = regsCents(idx,:);
    mypoly = regs(idx).ConvexHull;
    maskConvHull = poly2mask(mypoly(:,1),mypoly(:,2),size(BW,1),size(BW,2));
end
end


function cent = calcKMeansCentroid3d(data)
% find one centroid of the whole 3d volume
[idx] = find(data);
[x,y,z] = ind2sub(size(data),idx);
[~,cent] = kmeans([x,y,z],1);
end

function cents = calcKMeansCentroids(data)
% find centroid in each slice
for s=1:size(data,3)
    [r,c]=find(data(:,:,s));
    [~,cents(s,:)]=kmeans([r,c],1);
end
end

function lr = calcLRpoints(cent)
z = 1:size(cent,1);
[m,p,s] = best_fit_line(cent(:,1),cent(:,2),z');
t = (z - m(3))/p(3);
lr(:,1) = m(1) + p(1)*t;
lr(:,2) = m(2) + p(2)*t;
end

function [harm1m] = calcFilteredHarmonic(data)
[harmAll] = MRSegmentation.calcHarmonicsAll(data);
harm1 = harmAll(:,:,:,2);

harm1m = harm1;
for s=1:size(harm1,3)
    harm1m(:,:,s) = imgaussfilt(harm1(:,:,s));
end
harm1m(harm1m<max(harm1m(:))*.05)=0;
end

function distr = calcDistr(data,lr)
distr =[];
for s=1:size(data,3)
    temp1 = data(:,:,s);
    [idx] = find(temp1);
    [x,y] = ind2sub(size(temp1),idx);
    d=sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
    %distr_temp = d.*temp1(idx);
    distr_temp = d;
    distr = [distr;distr_temp];
end
end

function [vecs] = calcPCA3d(data,data2)
    [idx] = find(data);
    [x,y,z] = ind2sub(size(data),idx);
    v=data2(idx)/max(data(:));
    %vecs = pca([x,y,z,v]);
    vecs = pca([x,y,z]);
end

function [vecs] = calcPCA2d(data)
for s=1:size(data,3)
    temp = data(:,:,s);
    [idx] = find(temp);
    [x,y] = ind2sub(size(temp),idx);
    v=100*temp(idx)/max(data(:));
    mypca = pca([x,y,v]);
    vecs1(s,:) = mypca(1,1:2);
    vecs2(s,:) = mypca(2,1:2);
end
vecs1 = mean(vecs1,1);
vecs2 = mean(vecs2,1);
vecs = [vecs1;vecs2];
end
