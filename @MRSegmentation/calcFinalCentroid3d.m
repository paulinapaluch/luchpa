function [cent,harm1mt] = calcFinalCentroid3d(data)
[harm1m] = calcFilteredHarmonic(data);
cent(1,:) = calcKMeansCentroid3d(harm1m);
harm1mt=harm1m;

iter=1;
centDist = inf;
while centDist>1 || iter>100
    iter=iter+1;
    cents = calcKMeansCentroids(data);
    lr = calcLRpoints(cents);
    distr = calcDistr(harm1mt,lr);
    [mu,sig] = normfit(distr);
    idx=find(harm1mt);
    idx_toDelete1 = idx(distr>mu+sig/2);
    %idx_toDelete2 = idx(distr<mu-sig);
    harm1mt(idx_toDelete1)=0;
    %harm1mt(idx_toDelete2)=0;
    cent(iter,:) = calcKMeansCentroid3d(harm1mt);
    
    centDist = sqrt(sum((cent(iter,:)-cent(iter-1,:)).^2));
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
    distr_temp = d.*temp1(idx);
    %distr_temp = d;
    distr = [distr;distr_temp];
end
end

% % function [ centroids, mask ] = calcCentroids( data )
% % %UNTITLED6 Summary of this function goes here
% % %   Detailed explanation goes here
% %
% % %options
% % % 1st harm vs all harmonics except first
% % % initial gaussian filtering parameters
% % % percent of zeroed data
% %
% %
% % [harmAll] = calcHarmonicsAll(data); %Fourier
% % [harm1m] = calcFilteredHarmonic(data); % filtered first harmonic - FFH
% % % centroids0 = calcKMeansCentroids(harm1m); % centroids from FFH
% % % lr = calcLRpoints(centroids0); % 'line' fitted to centroids
% %
% % % myscatter(harm1m,centroids0,lr)
% %
% % [ centroids, mask ] = calcMaskAndCentroids(harm1m);
% %
% % MRViewer3Dt(mask.*harmAll(:,:,:,1))
% %
% % end
%
% function [harmAll] = calcHarmonicsAll(data)
% harmAll = abs(fft(data,[],4));
% end
%
% function [harm1m] = calcFilteredHarmonic(data)
% [harmAll] = calcHarmonicsAll(data);
% harm1 = harmAll(:,:,:,2);
%
% harm1m = harm1;
% for s=1:size(harm1,3)
%     harm1m(:,:,s) = imgaussfilt(harm1(:,:,s));
% end
% harm1m(harm1m<max(harm1m(:))*.05)=0;
% end
%
% function lr = calcLRpoints(cent)
% z = 1:size(cent,1);
% [m,p,s] = best_fit_line(cent(:,1),cent(:,2),z');
% t = (z - m(3))/p(3);
% lr(:,1) = m(1) + p(1)*t;
% lr(:,2) = m(2) + p(2)*t;
% end
%
% function cent = calcKMeansCentroids(data)
% % find centroid in each slice
% for s=1:size(data,3)
%     [r,c]=find(data(:,:,s));
%     [~,cent(s,:)]=kmeans([r,c],1);
% end
% end
%
% function cent = calcKMeansCentroid3d(data)
% % find one centroid of the whole 3d volume
%
% [idx] = find(data);
% [x,y,z] = ind2sub(size(data),idx);
% [~,cent] = kmeans([x,y,z],1);
%
% end
%
% function point = getPoint3d(data)
% [harm1m] = calcFilteredHarmonic(data);
% point = calcKMeansCentroid3d(harm1m);
% point(3) = round(point(3));
% end
%
% % function [ centroid, mymask ] = calcMaskAndCentroids(harm1m)
% %
% % centroids = calcKMeansCentroids(harm1m);
% % lr = calcLRpoints(centroids);
% %
% % centroid3d = calcKMeansCentroid3d(harm1m);
% %
% % iter = 0;
% % while  all(sum((lr-centroids).^2,2))>1 && iter<100
% %
% % end
% %
% % end
%
% function [ centroids, mymask ] = calcMaskAndCentroids2(harm1m)
%
% harm1m2 = zeros(size(harm1m));
%
% centroids = calcKMeansCentroids(harm1m); % centroids from FFH
% lr = calcLRpoints(centroids); % 'line' fitted to centroids
%
% iter = 0;
%
% while  all(sum((lr-centroids).^2,2))>1 && iter<100
%     for s=1:size(harm1m,3)
%         temp1 = harm1m(:,:,s);%disp(length(find(temp1)));
%         %temp0 = harm0(:,:,s);
%         [idx] = find(temp1);
%         [x,y] = ind2sub(size(temp1),idx);
%         d=sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
%
%         %dw = d.*temp0(idx);
%         dw = d.*temp1(idx);
%         %dw = d;
%
%         [mu,sig] = normfit(dw);
%
%         %subplot(211),imshow(temp1>0,[])
%         temp1(idx(dw>mu+3*sig))=0;
%         %temp1(idx(dw<mu-sig))=0;
%         %subplot(212),imshow(temp1>0,[])
%
%         harm1m2(:,:,s) = temp1;%disp(length(find(temp1)));
%         [idx] = find(temp1);
%         [x,y] = ind2sub(size(temp1),idx);
%         d=sqrt((x-lr(s,1)).^2+(y-lr(s,2)).^2);
%         mydist(s) = mean(d);
%         iter = iter+1;
%     end
%     centroids = calcKMeansCentroids(harm1m2); % centroids from FFH
%     lr = calcLRpoints(centroids); % 'line' fitted to centroids
% end
%
% mymask = zeros(size(harm1m));
% [xx,yy]=ndgrid(1:size(harm1m,1),1:size(harm1m,2));
% for s=1:size(harm1m,3)
%     tempMask = zeros(size(harm1m));
%     tempMask((xx-lr(s,1)).^2+(yy-lr(s,2)).^2<mydist(s).^2)=1;
%     mymask(:,:,s)=tempMask;
% end
% end
%
% function myscatter(data,cent,lr)
% [idx] = find(data);
% v = data(idx);
% [x,y,z] = ind2sub(size(data),idx);
% scatter3(x,y,z,1,v),hold on
%
% z = 1:size(cent,1);
% plot3(cent(:,1),cent(:,2),z,'o')
% plot3(lr(:,1),lr(:,2),z,'o')
% hold off
%
% end

