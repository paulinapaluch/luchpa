function [DF_forw,DF_back] = register2DconsBspline_DJK(MRData)

myoptions=struct(...
    'Similarity','sd',...
    'Registration','Both',...
    'Penalty',1e-3,...
    'MaxRef',2,...
    'Verbose',0,...
    'Interpolation','Linear',...
    'Scaling',[1 1]);

F = zeros(MRData.nXs,MRData.nYs,MRData.nSlices,MRData.nTimes,3);
B = zeros(MRData.nXs,MRData.nYs,MRData.nSlices,MRData.nTimes,3);

warning('Debuging: just one slice!')
myoptions.MaxRef=2;
myoptions.Spacing=[8 8];
for s=round(MRData.nSlices/2)
    
%for s=1:MRData.nSlices
    fprintf('Slice %d ',s)
    for t=2:MRData.nTimes
        temp1=MRData.data(:,:,s,t-1);
        temp2=MRData.data(:,:,s,t);
        clear('F_temp')
        try
            [~,~,~,~,B_temp,F_temp] = image_registration(temp1,temp2,myoptions);
        catch ex
            disp(ex)
        end
        
        F(:,:,s,t,1)=F_temp(:,:,1);
        F(:,:,s,t,2)=F_temp(:,:,2);
        B(:,:,s,t,1)=B_temp(:,:,1);
        B(:,:,s,t,2)=B_temp(:,:,2);
        fprintf('.')
    end
    fprintf('\n')
end

DF_forw=F;
DF_back=B;

% DF_forw = MRDataDF(F,MRData);
% DF_back = MRDataDF(B,MRData);
