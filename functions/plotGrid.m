function plotGrid(grid)

% x = 0:10;
% y = sin(x);
% xx = 0:.25:10;
% yy = spline(x,y,xx);
% plot(x,y,'o',xx,yy)

hold on
for ix=1:size(grid,1)
    plot(grid(:,ix,2),grid(:,ix,1))
end
for iy=1:size(grid,2)
    plot(grid(iy,:,2),grid(iy,:,1))
end
hold off
