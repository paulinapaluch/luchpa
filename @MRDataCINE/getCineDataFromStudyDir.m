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
[N,~,bins]=histcounts(ic,length(uniqueImageOrientationPatientStr));

conditionAll = zeros(size(condition1));
for n=1:length(N)
    condition2=(bins==n)'; % most images with the same orientation
    if sum(conditionAll)<sum(condition1 & condition2 & condition3);
        conditionAll=condition1 & condition2 & condition3;
    end
end

saxCineIdx = find(conditionAll);

fprintf('Getting data from dicoms\n')

nCines = 0;
for i = saxCineIdx
    try
        nCines = nCines+1;
        dcmTags(1,nCines) = dcmTagsOK(1,i);
        dataRaw(:,:,1,nCines) = double(dicomread(dcmFilenamesCellOK{i}));
    catch ex
        keyboard
        nCines = nCines-1;
        disp(ex)
    end
end

[dataRaw,dcmTags] = MRDataCINE.rearrangeCardiacData(dataRaw,dcmTags);

obj.dataRaw = dataRaw;
obj.dcmTags = dcmTags;

obj.imageOrientationPatient = dcmTags(1,1).ImageOrientationPatient';
obj.imagePositionPatient = dcmTags(1,1).ImagePositionPatient'; 
obj.aspectRatio = [dcmTags(1,1).PixelSpacing',mean(obj.sliceDistances)];

% some dicom fields checking
if isfield(dcmTags(1,1),'StudyName'),obj.studyName = strtrim(dcmTags(1,1).StudyName);else obj.studyName='NonameStudy';end
if isfield(dcmTags(1,1),'SeriesInstanceUID'),obj.UID = dcmTags(1,1).SeriesInstanceUID;else obj.UID=0;end
fn=[];if isfield(dcmTags(1,1).PatientName,'FamilyName'),fn = [strtrim(dcmTags(1,1).PatientName.FamilyName),' '];end
gn=[];if isfield(dcmTags(1,1).PatientName,'GivenName'),gn = strtrim(dcmTags(1,1).PatientName.GivenName);end
obj.patientName = strtrim([fn,gn]);

end
