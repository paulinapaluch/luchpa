function [DF_forw,DF_back,regoptions] = register3DconsBspline_DJK_p0(MRData)

regoptions=struct(...
    'Similarity','sd',...
    'Registration','NonRigid',...
    'Penalty',0,...
    'MaxRef',5,...
    'Spacing',[2 2 2],...
    'Verbose',0,...
    'Interpolation','Linear',...
    'Scaling',[1 1 1]);

ticAll = tic;

F = zeros([size(MRData.dataIso),3]);
B = zeros([size(MRData.dataIso),3]);

for t=2:MRData.nTimes
    ticOne = tic;
    temp1=MRData.dataIso(:,:,:,t-1);
    temp2=MRData.dataIso(:,:,:,t);
    clear('F_temp')
    try
        [~,~,~,~,B_temp,F_temp] = image_registration(temp1,temp2,regoptions);
    catch ex
        disp(ex)
    end
    
    F(:,:,:,t,1) = F_temp(:,:,:,1);
    F(:,:,:,t,2) = F_temp(:,:,:,2);
    F(:,:,:,t,3) = F_temp(:,:,:,3);
    B(:,:,:,t,1) = B_temp(:,:,:,1);
    B(:,:,:,t,2) = B_temp(:,:,:,2);
    B(:,:,:,t,3) = B_temp(:,:,:,3);
    fprintf('Registration in time frame %d calculated in %.2f sec \n',t,toc(ticOne))
end
fprintf('Calculated in %.2f sec \n',toc(ticAll))

regoptions.calcTime = toc(ticAll);
DF_forw=F;
DF_back=B;

beep,pause(.2),beep,pause(.1),beep,pause(.1),beep
