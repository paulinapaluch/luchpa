classdef (Abstract) MRData < matlab.mixin.SetGet
    %MRData is an abstract class, main purpose of its children is to store
    %   data imported from dicoms.
    %
    % Konrad Werys, Feb 2016
    % mrkonrad.github.io
    
    properties (Abstract)
        savePath;  % where the object will be saved. Updated on load, may be freely changed
    end
    
    properties (GetAccess = public, SetAccess = protected)
        loadPath = '';	% updated on loading previously saved matlab data
        dcmsPath = '';	% updated in loading new data from dicoms
        
        data     = [];  % modified, currently used data. Modified for example for breathing motion corrected
        dataIso  = [];  % istropic data calculated based on data
        dataRaw  = [];  % data from dicoms
        dcmTags         % dicoms tags, kept here in case they are needed one day
        
        %%% properties taken from dcmTags
        patientName
        studyName
        UID
        imageOrientationPatient     % orientation of the data, taken from dicom
        imagePositionPatient        % postion is space of the corner of the volume, taken from dicom
        aspectRatio                 % pixel spacing X, pixel spacing Y, slice spacing Z
        sliceDistances              % calculated from dicom postions
        timesT                      % averaged (over slices) time vector, size=nTimes
        timesST                     % full time points information, size=nSlices x nTimes
        breathShifts                % shifts calculated from breathing motion correction
    end
    
    properties (Dependent)          % 'Data on Demand'
        nXs                         % size
        nYs                         % size
        nSlices                     % size
        nTimes                      % size
        nDims                       % size
        loadDirPath                 % when just dir name is needed
        saveDirPath                 % when just dir name is needed
    end
    
    methods
        function setDefaults(obj)
                obj.dcmTags = [];
                obj.imageOrientationPatient = zeros(1,6);
                obj.imagePositionPatient = zeros(1,3);
                obj.aspectRatio = ones(1,3);
                obj.breathShifts = zeros(1,size(obj.data,3));
        end
        
%         function savePath = get.savePath(obj)
%             if strcmp(obj.savePath,'')
%                 savePath = obj.loadPath;
%             end
%         end
        
        function nXs     = get.nXs(obj),nXs=size(obj.data,1);end         % size
        function nYs     = get.nYs(obj),nYs=size(obj.data,2);end         % size
        function nSlices = get.nSlices(obj),nSlices=size(obj.data,3);end % size
        function nTimes  = get.nTimes(obj),nTimes=size(obj.data,4);end   % size
        function nDims   = get.nDims(obj),nDims=size(obj.dataRaw,5);end  % size
        
        function loadPath   = get.loadPath(obj)
            loadPath = obj.loadPath;
            if strcmp(loadPath,'')
                loadPath = obj.savePath;
            end
        end
        
        function loadDirPath   = get.loadDirPath(obj)
            [loadDirPath,~,ext]=fileparts(obj.loadPath);
            if isempty(ext),loadDirPath=obj.loadPath;end
        end 
        
        function saveDirPath   = get.saveDirPath(obj)
            [saveDirPath,~,ext]=fileparts(obj.savePath);
            if isempty(ext),saveDirPath=obj.savePath;end
        end
 
        function sliceDistances = get.sliceDistances(obj)
            sliceDistances = calcSliceDistances(obj);
        end
        
        function dataIso = get.dataIso(obj)
            if isempty(obj.dataIso)
                obj.dataIso = calcIsoTropicData(obj);
            else
                dataIso = obj.dataIso;
            end  
        end
        
        isoData = calcIsoTropicData(obj);
        [timesT,timesST] = calcTimes(obj);
        sliceDistances = calcSliceDistances(obj,flags);
        breathShifts = calcbreathingCorrection(obj);
        data = shiftRawData(obj);
    end
    
    methods (Static)
        dcmFilenamesCell = getDicomFilenamesCell(dcmDir);
        dcmTags = getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);
        
        function obj = load(mypath)
            %%% a dummy variable used in loadobj method
            dummyvariable694828623=0; %#ok
            
            try
                temp = load(mypath);
                tempfieldname = fieldnames(temp);
                if length(tempfieldname)>1
                    error('More then one object in a given file');
                end
                obj = temp.(tempfieldname{1});
                obj.loadPath = mypath;
            catch ex
                disp(ex);
            end
        end
        
        function obj = loadobj(obj)
            %%% I do not know how to get path from where the object is
            %%% loaded (by calling load('path')). So I implemened 
            %%% obj.load method where I have stupid name for a variable. I
            %%% check if this variable exist in the worspace that is
            %%% calling the load object. If no, there is a warning.
            
            if ~evalin('caller','exist(''dummyvariable694828623'',''var'')')
                warning('Please use MRData.load(''path'') not this function. This way of loading data may cause problems using MRData-like classes. Some of the variable (paths) needed for some advanced operations are not set.');
            end
        end
    end
    
    
    
end

