function obj = getObjParamsFromDcmTags(obj)

obj.imageOrientationPatient = obj.dcmTags(1,1).ImageOrientationPatient';
obj.imagePositionPatient = obj.dcmTags(1,1).ImagePositionPatient'; 
obj.aspectRatio = [obj.dcmTags(1,1).PixelSpacing',mean(obj.sliceDistances)];

% some dicom fields checking
if isfield(obj.dcmTags(1,1),'StudyName'),obj.studyName = strtrim(obj.dcmTags(1,1).StudyName);else obj.studyName='NonameStudy';end
if isfield(obj.dcmTags(1,1),'SeriesInstanceUID'),obj.UID = obj.dcmTags(1,1).SeriesInstanceUID;else obj.UID=0;end
fn=[];if isfield(obj.dcmTags(1,1).PatientName,'FamilyName'),fn = [strtrim(obj.dcmTags(1,1).PatientName.FamilyName),' '];end
gn=[];if isfield(obj.dcmTags(1,1).PatientName,'GivenName'),gn = strtrim(obj.dcmTags(1,1).PatientName.GivenName);end
obj.patientName = strtrim([fn,gn]);