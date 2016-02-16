function [cent,harm1mt,maskSeg,mypoly] = calcFinalCentroid3d(data,aspectRatio)
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
maxArea = sum(sum(maskCirc(:,:,s,1)))/3;
maskedDataS=data(:,:,s,1).*maskCirc(:,:,s);
maskedDataSvec = maskedDataS(find(maskedDataS));
obj = fitgmdist(maskedDataSvec,3);
[maxmu,idxmaxmu] = max(obj.mu);
sigma = obj.Sigma(1,1,idxmaxmu);
threshold = maxmu*.75;

maskCirc = repmat(maskCirc,[1,1,1,size(data,4)]); % fill maskCirc in temporal direction
maskTh = data.*maskCirc>threshold;

maskTh = imfill(maskTh,'holes');

[maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosestTo(maskTh(:,:,s,1),cent(iter,1:2),maxArea);

islicesdown = flip(1:s-1);
islicesup = s+1:size(data,3);
for s=islicesdown
    [maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosestTo(maskTh(:,:,s,1),newcent{s+1,1},maxArea);
end
for s=islicesup
    [maskSeg(:,:,s,1),newcent{s,1},mypoly{s,1}] = chooseRegClosestTo(maskTh(:,:,s,1),newcent{s-1,1},maxArea);
end

for t=2:size(data,4)
    s = round(cent(iter,3));
    
    [maskSeg(:,:,s,t),newcent{s,t},mypoly{s,t}] = chooseRegClosestTo(maskTh(:,:,s,t),cent(iter,1:2),maxArea);
    islicesdown = flip(1:s-1);
    islicesup = s+1:size(data,3);
    for s=islicesdown
        [maskSeg(:,:,s,t),newcent{s,t},mypoly{s,t}] = chooseRegClosestTo(maskTh(:,:,s,t),newcent{s+1,t},maxArea);
    end
    for s=islicesup
        [maskSeg(:,:,s,t),newcent{s,t},mypoly{s,t}] = chooseRegClosestTo(maskTh(:,:,s,t),newcent{s-1,t},maxArea);
    end
end

end

function [maskConvHull,cent,mypoly] = chooseRegClosestTo(BW,pos,maxArea)
maskConvHull = zeros(size(BW));
cent = pos;
mypoly=[];

regs = regionprops(BW,'Centroid','ConvexHull','Area');
BW = bwmorph(BW,'clean');
if ~isempty(regs)
    regsCents = cell2mat({regs.Centroid}');
    dist=zeros(1,length(regs));
    for ireg = 1:length(regs)
        dist(ireg) = sqrt(sum((regsCents(ireg,:)-pos).^2));
    end
    [~,idx] = min(dist);
    
    if regs(idx).Area>maxArea
        return
    end
    
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
