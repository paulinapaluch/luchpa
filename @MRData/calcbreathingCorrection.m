function breathShifts = calcbreathingCorrection(obj)

myoptions=struct(...
    'Similarity','sd',...
    'Registration','Rigid',...
    'Penalty',1e-3,...
    'MaxRef',3,...
    'Spacing',[1 1],...
    'Verbose',0,...
    'Interpolation','Linear',...
    'Scaling',[1 1]);

t0=1;
u0=zeros(obj.nSlices,2);
u1=zeros(obj.nSlices,2);

%%% Rigid registration by Dirk-Jan Kroon. Probably matlab's version would
%%% work just as good
fprintf('Rigid registration1')
for iSlice=2:obj.nSlices
    I1s=obj.dataRaw(:,:,iSlice,t0);
    I2s=obj.dataRaw(:,:,iSlice-1,t0);
    [~,~,~,M,~,~] = image_registration(I1s,I2s,myoptions);
    u0(iSlice,1)=M(1,3);
    u0(iSlice,2)=M(2,3);
    fprintf('.')
end
fprintf('\n')

fprintf('Rigid registration2')
for iSlice=1:obj.nSlices-1
    I1s=obj.dataRaw(:,:,iSlice,t0);
    I2s=obj.dataRaw(:,:,iSlice+1,t0);
    [~,~,~,M,~,~]  = image_registration(I1s,I2s,myoptions);
    u1(iSlice,1)=M(1,3);
    u1(iSlice,2)=M(2,3);
    fprintf('.')
end
fprintf('\n')

%%% Cordero-Grande_2012  Markov Random Field Approach for
%%% Topology-Preserving Registration: Application to
%%% Object-Based Tomographic Image Interpolation
%%% IEEE TRANSACTIONS ON IMAGE PROCESSING

fprintf('Breathing correction\n')
dcmDataCor=obj.dataRaw;
V=1000;
u0_temp=u0;
u1_temp=u1;
breathShifts=zeros(size(u0));
for v=1:V
    t=0.5*(u0_temp+u1_temp);
    t_mag = sqrt(t(:,1).^2+t(:,2).^2);
    [~,ndash] = max(t_mag(2:end-1));ndash=ndash+1;
    breathShifts(ndash,:)=breathShifts(ndash,:)+t(ndash,:);
    M=eye(3);
    M(1,3)=t(ndash,1);
    M(2,3)=t(ndash,2);
%     for tt=1:obj.nTimes
%         dcmDataCor(:,:,ndash,tt)=affine_transform(dcmDataCor(:,:,ndash,tt),M,3);
%     end
    dcmDataCor(:,:,ndash,t0)=affine_transform(dcmDataCor(:,:,ndash,t0),M,3);
    u0_temp(ndash+1,:) = u0_temp(ndash+1,:) + t(ndash+1,:);
    u1_temp(ndash-1,:) = u1_temp(ndash-1,:) + t(ndash-1,:);
    u0_temp(ndash,:) = u0_temp(ndash,:) - t(ndash,:);
    u1_temp(ndash,:) = u1_temp(ndash,:) - t(ndash,:);
    if all(t_mag(2:end-2)==0)
        break
    end
end

obj.breathShifts=breathShifts;
obj.shiftRawData;
