classdef (Abstract) MRData < handle 
    %MRData is an abstract class, main purpose of its children is to store
    %   data imported from dicoms.
    %
    % Konrad Werys, Feb 2016
    % mrkonrad.github.io
    
    properties (Abstract, Constant)
        className
        numClassName
    end
    
    properties (GetAccess = public, SetAccess = protected, Transient) % not saved, should be recalculated on load
        data     = [];  % modified, currently used data. Modified for example for breathing motion corrected
        dataIso  = [];  % istropic data calculated based on data
    end
    
    properties (GetAccess = public, SetAccess = protected)
        % core properties
        dataRaw  = [];  % data from dicoms
        dcmTags  = [];  % dicoms tags, kept here in case they are needed one day
        
        % path properties
        savePath = [];  % where the object will be saved. Updated on load, may be freely changed
        loadPath = [];	% updated on loading previously saved matlab data
        dcmsPath = [];	% updated in loading new data from dicoms

        %%% properties taken from dcmTags
        patientName                 % used in saving process, taken dicom
        studyName                   % used in saving process, taken dicom
        UID                         % taken dicom (SeriesInstanceUID)
        imageOrientationPatient     % orientation of the data, taken from dicom
        imagePositionPatient        % postion is space of the corner of the volume, taken from dicom
        aspectRatio                 % pixel spacing X, pixel spacing Y, slice spacing Z
        sliceDistances              % calculated from dicom postions
        timesT                      % averaged (over slices) time vector, size=nTimes
        timesST                     % full time points information, size=nSlices x nTimes
        breathShifts                % shifts calculated from breathing motion correction
        loadDirPath                 % when just dir name is needed
        saveDirPath                 % when just dir name is needed
    end
    
    properties (Dependent)          % 'Data on Demand'
        % dimensions of the core data
        nXs                         % size
        nYs                         % size
        nSlices                     % size
        nTimes                      % size
        nDims                       % size

    end
    
    methods
        % getters for dependent values
        function nXs     = get.nXs(obj),nXs=size(obj.dataRaw,1);end         % size
        function nYs     = get.nYs(obj),nYs=size(obj.dataRaw,2);end         % size
        function nSlices = get.nSlices(obj),nSlices=size(obj.dataRaw,3);end % size
        function nTimes  = get.nTimes(obj),nTimes=size(obj.dataRaw,4);end   % size
        function nDims   = get.nDims(obj),nDims=size(obj.dataRaw,5);end     % size
        
        % construct path with patient name and study name
        function fullSavePath = getFullSavePath(obj)
            fullSavePath = fullfile(obj.savePath,obj.patientName,obj.studyName);
        end
        
        % construct path with patient name and study name
        function fullLoadPath = getFullLoadPath(obj)
            fullLoadPath = fullfile(obj.loadPath,obj.patientName,obj.studyName);
        end
        
        % calculate slice distances using image position patient from dicom
        function sliceDistances = get.sliceDistances(obj)
            if isempty(obj.sliceDistances)
                obj.sliceDistances = calcSliceDistances(obj);
            end
            sliceDistances = obj.sliceDistances;
        end
        
        % when data is not defined (fe after loading), calculate it using
        % breath shifts
        function data = get.data(obj)
            if isempty(obj.data)
                obj.data = shiftRawData(obj);
            end
            data = obj.data; 
        end
        
        % when isotropic data is not defined (fe after loading), calculate it 
        function dataIso = get.dataIso(obj)
            if isempty(obj.dataIso)
                obj.dataIso = calcIsoTropicData(obj);
            end
            dataIso = obj.dataIso;
        end
        
        % when isotropic data is not defined (fe after constructor), 
        % return zeros. Probably this can be put in abstract contructor 
        function breathShifts = get.breathShifts(obj)
            if isempty(obj.breathShifts)
                obj.breathShifts = zeros(size(obj.dataRaw,3),2);
                %obj.breathShifts = calcbreathingCorrection(obj);
            end
            breathShifts = obj.breathShifts;
        end
        
        % raw data slices are numbered 1..nSlices (lenght=nSlices); iso
        % data slices are numbered 1..nSlices*aspectRatio(3). 
        % (lenght = nSlices*aspectRatio(3)). Use this function when index
        % of the nearest raw data slice is needed, it returns vector with
        % numbers 1..nSlices (lenght = nSlices*aspectRatio(3))
        function out = slicesIdxIso(obj)
            minPixSize = min(obj.aspectRatio);
            myscale = minPixSize./obj.aspectRatio;
            out = 1:myscale(3):obj.nSlices;
        end
        
        % name is dupaSave, because if I name is save I have many problems
        function dupaSave(obj)
            dirpath = obj.getFullSavePath;
            filepath = fullfile(dirpath,[obj.className,'.mat']);
            if ~exist(dirpath,'dir'),mkdir(dirpath);end
            save(filepath,'obj');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% --------------- Methods is separate files --------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % calc istropic data using interpolation (linear or spilne)
        dataIso = calcIsoTropicData(obj,interpType);
        
        % timesST is (size = nSlices x nTimes) matrix
        % timesS is timesST averaged over slices, so (size = nTimes) vector
        [timesT,timesST] = calcTimes(obj);
        
        % calculate slice distances using image position patient from dicom
        sliceDistances = calcSliceDistances(obj,flags);
        
        % calculate breathing correction using rigid registration (just
        % translation)
        breathShifts = calcbreathingCorrection(obj);
        
        % shift data based on obj.breathShifts
        data = shiftRawData(obj);
        
        % gets obj.patientName, obj.imageOrientationPatient etc
        % called in constructor
        obj = getObjParamsFromDcmTags(obj);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ---------------------- Static Methods  ---------------------- %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Static)
        
        % load method to be used in children classes. It take a .mat file
        % with one variable saved and loads it 
        function obj = load(mypath,className)
            %disp(mypath)
            %%% a dummy variable used in loadobj method
            dummyvariable694828623=0; %#ok
            obj = [];
            
            filePath = fullfile(mypath,[className,'.mat']);
            if ~exist(filePath,'file')
                fprintf('Could not load the file: %s',filePath)
                return
            end
            try
                fprintf('Loading data from %s\n',filePath)
                temp = load(filePath);
                tempfieldname = fieldnames(temp);
                if length(tempfieldname)>1
                    error('More then one object in a given file');
                end
                obj = temp.(tempfieldname{1});
                obj.loadPath = mypath;
            catch ex
                fprintf('Could not load the file: %s',filePath)
                disp(ex)
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% --------------- Methods is separate files --------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % gets cell with all dicom filenames in given dcmDir
        dcmFilenamesCell = getDicomFilenamesCell(dcmDir);
        
        % gets cell with the dicom tags from dicom files in input cell. It
        % ensures all dcmTags have are structures with the same fields
        dcmTags = getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell);
        
        % organize data, so that third dimension is nSlices and fourth is
        % nTimes. In input third diension lenght =1 and 
        % forth diension lenght = nSlices x nTimes
        [dcmData,dcmTags] = rearrangeCardiacData(dcmData,dcmTags);
        
        [dcmData,dcmTags] = rearrangeLGEData(dcmData,dcmTags);
    end
end

