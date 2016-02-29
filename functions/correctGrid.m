function [grid_tran_plot,grid_init]=correctGrid(O_trans,Spacing,I1)

grid_init=make_init_grid(Spacing,size(I1));
[x,y]=ndgrid(grid_init(1,1,1):Spacing(1):grid_init(end,1,1),grid_init(1,1,2):Spacing(2):grid_init(1,end,2));
grid_tran_plot(:,:,1) = -(O_trans(:,:,1)-x)+x;
grid_tran_plot(:,:,2) = -(O_trans(:,:,2)-y)+y;