clear
Is = phantom(128);
Im = zeros(128);
Im(3:end,3:end)=Is(1:end-2,1:end-2);

imshow([Is,Im],[])

opts.Spacing = [8 8];
opts.MaxRef = 1;
opts.Verbose = 2;
opts.Similarity = 'sd';
opts.Registration = 'NonRigid';

%%
%R = MRRegistration(Is,Im);
R = MRRegistration(Is,Im,'SpacingInit',opts.Spacing,'nRef',opts.MaxRef,'Similarity',opts.Similarity);
R.doDefRegistration;

%% Check if results are the same
disp('##########')
[Ireg,grid] = image_registration(Is,Im,opts);

%%
myequal = R.BSGrid == grid;
any(myequal(:))

clf
subplot(121)
imshow(R.Imt,[]),hold on
plotGrid(correctGrid(R.BSGrid,R.SpacingFin,Im)),hold off,title('KW')
subplot(122)
imshow(Ireg,[]),hold on
plotGrid(correctGrid(grid,R.SpacingFin,Im)),hold off,title('DJK')
