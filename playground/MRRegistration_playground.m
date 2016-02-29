clear
Is = phantom(128);
Im = zeros(128);
Im(3:end,3:end)=Is(1:end-2,1:end-2);

imshow([Is,Im],[])

opts.Spacing = [8 8];
opts.MaxRef = 0;
opts.Verbose = 2;
opts.Similarity = 'sd';
opts.Registration = 'NonRigid';

%%
%R = MRRegistration(Is,Im);
R = MRRegistration(Is,Im,'SpacingInit',opts.Spacing,'nRef',opts.MaxRef,'Similarity',opts.Similarity);
R.doDefRegistration;

%% Check if results are the same
disp('##########')
[~,grid] = image_registration(Is,Im,opts);

%%
myequal = R.BSGrid == grid;
any(myequal(:))

clf
subplot(121)
plotGrid(R.BSGrid)
subplot(122)
plotGrid(grid)
