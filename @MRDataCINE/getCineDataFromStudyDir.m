function obj = getCineDataFromStudyDir(obj,dcmDir)
%getCineDataFromStudyDir
% TODO divide this function into three functions: get, arrange, save
%
% Konrad Werys, Feb 2016
% mrkonrad.github.io

dcmFilenamesCell = MRData.getDicomFilenamesCell(dcmDir);
dcmTagsTemp = MRData.getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);

fprintf('Selecting files based on conditions\n')

if isfield(dcmTagsTemp,'CardiacNumberOfImages')
    CardiacNumberOfImagesField = 'CardiacNumberOfImages';
elseif isfield(dcmTagsTemp,'Private_2001_1017')
    CardiacNumberOfImagesField = 'Private_2001_1017';
else
    error('No CINE found')
end

idxsOK1 = ~cellfun(@isempty,{dcmTagsTemp(1,:).(CardiacNumberOfImagesField)});
idxsOK2 = ~cellfun(@isempty,{dcmTagsTemp(1,:).ImageOrientationPatient});
idxsOK3 = ~cellfun(@isempty,{dcmTagsTemp(1,:).ImagePositionPatient});
idxOK = idxsOK1 & idxsOK2 & idxsOK3;

%%% apply ok indexes
dcmFilenamesCellOK=dcmFilenamesCell(idxOK);
dcmTagsOK=dcmTagsTemp(1,idxOK);

%seriesNumbers=[dcmTagsOK.SeriesNumber];
imageOrientationPatient=[dcmTagsOK.ImageOrientationPatient];
%imagePositionPatient=[dcmTagsOK.ImagePositionPatient];?uid
%rows = [dcmTagsOK.Rows];
%columns = [dcmTagsOK.Columns];
cardiacNumberOfImages = [dcmTagsOK.(CardiacNumberOfImagesField)];
%instanceNumbers = [dcmTags(1,idxOK).InstanceNumber];
%triggerTimes = [dcmTags(1,idxOK).TriggerTime];
pixelSpacing = [dcmTagsOK.PixelSpacing]';

if isfield(dcmTagsOK,'InversionTime')
    idxTIempty = cellfun(@isempty,{dcmTagsOK.InversionTime}); % find tags idxs with empty inversion time
    [dcmTagsOK(1,idxTIempty).InversionTime]=deal(0); % and fill them with 0;
    inversionTimes = [dcmTagsOK.InversionTime];
else
    inversionTimes = zeros(1,length(dcmTagsOK));
end

%%% looking for he largest group of images with cardiacNumberOfImages>1 
%%% and having the most slices in the same orientation  
condition1 = cardiacNumberOfImages>1; % has to be cine
condition3 = inversionTimes==0; % cannot have inversion time (to eliminate TI scouts in GE)

roundedImageOrientetionPatient = round(1e3*imageOrientationPatient')/1e3; % allowing precision of the same orientation to be 1e-6
[uniqueImageOrientationPatientStr,~,ic] = unique(roundedImageOrientetionPatient,'rows'); 
[nIOPs,~,binsIOP]=histcounts(ic,length(uniqueImageOrientationPatientStr));

[uniquePixelSpacing,~,ic] = unique(pixelSpacing,'rows'); 
[nPSs,~,binsPS]=histcounts(ic,length(uniquePixelSpacing));
[~,idxPS] = max(nPSs);
condition4 = (binsPS==idxPS)'; % has to have the same pixel spacing. group with most numerous number of pixel spacing is chosen

conditionAll = zeros(size(condition1));
for n=1:length(nIOPs)
    condition2=(binsIOP==n)'; % most images with the same orientation
    
    if sum(conditionAll)<sum(condition1 & condition2 & condition3);
        conditionAll=condition1 & condition2 & condition3 & condition4;
    end
end

saxCineIdx = find(conditionAll);
disp(['Series: ', num2str(unique([dcmTagsOK(saxCineIdx).SeriesNumber]))])

fprintf('Getting data from dicoms\n')

nCines = 0;
for i = saxCineIdx
    try
        nCines = nCines+1;
        dcmTags(1,nCines) = dcmTagsOK(1,i);
        temp = double(dicomread(dcmFilenamesCellOK{i}));
        
        if nCines==1
            dataRaw(:,:,1,nCines) = temp;
        end
        
        if size(dataRaw,1)==size(temp,1) && size(dataRaw,2)==size(temp,2)
            dataRaw(:,:,1,nCines) = temp;
        elseif all(dcmTags(1,nCines).PixelSpacing == dcmTags(1,1).PixelSpacing)
            nX = max(size(dataRaw,1),size(temp,1));
            nY = max(size(dataRaw,2),size(temp,2));
            newDataRaw = zeros(nX,nY,1,nCines);
            newDataRaw(1:size(dataRaw,1),1:size(dataRaw,2),1:size(dataRaw,3),1:size(dataRaw,4))=dataRaw;
            newDataRaw(1:size(temp,1),1:size(temp,2),1,nCines) = temp;
            dataRaw = newDataRaw;
        else
            error('Wrong size')
        end
    catch ex
        keyboard
        nCines = nCines-1;
        disp(ex)
    end
end

[dataRaw,dcmTags] = MRDataCINE.rearrangeCardiacData(dataRaw,dcmTags);

obj.dataRaw = dataRaw;
obj.dcmTags = dcmTags;

end
