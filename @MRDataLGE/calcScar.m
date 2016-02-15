function obj = calcScar(obj)

myoMask = obj.myoMask;
data = obj.data;
maskScar = zeros(size(data));

idx = find(myoMask);
mymax = max(data(idx));
mymin = min(data(idx));
mymean = mean(data(idx));
threshold = (mymax+mymin)/2;
%threshold = mymax/2;
%threshold = mymean;
if ~isempty(threshold)
    maskScar = (data>threshold).*myoMask;
end

obj.masks.scar = maskScar;

sd = obj.sliceDistances;
sd = [sd(1) sd sd(end)];

v=zeros(1,size(data,3));
for s = 1:size(data,3)
    st = .5*sd(s) + .5*sd(s+1);
    px = obj.aspectRatio(1:2);
    
    v(s) =  sum(sum(maskScar(:,:,s))) * st * px(1) *px(2); 
end

obj.scarMass = sum(v)*1.05/1000;

