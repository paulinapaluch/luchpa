classdef MRDataCINE < MRData
    %MRDataCINE stores the data and allows for displacement field
    %   calculations using MRRegistration methods
    %   
    %   There are two ways to get a MRDataCINE object:
    %   - analysing dicom directory of single study
    %   - loading previously saved MRDataCINE object
    %
    % Konrad Werys, Feb 2016
    % konradwerys@gmail.com
    % <mrkonrad.github.io>
    
    properties (Constant)
        % this is visible from class, >>MRDispField.allowedImages
        mrconfig = {'className','MRDataCINE';...
                    'overlayClass','dispField'};
        allowedImages = {...   % working on MRDataCINE object, fe. M.(allowedImages(1,1))
            'data',   'Data with corrections';...
            'dataRaw','Data from dicom';...
            'dataIso','Data with corrections isotropic (interpolated)'};
        allowedOverlays = {... % working on MRDispField object within MRDataCINE object, fe. M.dispField.(allowedImages(1,1))
            'back','back',3;...
            'forw','forw',3;...
            ...%'comb','comb',3;...
            'magBack','magBack',1;...
            'magForw','magForw',1};...
            %'magComb','magComb',1}
    end
    
    properties
        savePath        % path where the object is stored 
        epi             % epicardial ROI
        endo            % endocardial ROI
    end
    
    properties (GetAccess = public, SetAccess = protected)
        dispField = [];
    end
    
    methods 
        
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        
        function obj=MRDataCINE(varargin)
            if nargin<2
                error('Wrong input data')
            elseif nargin==2 && exist(varargin{1},'dir') % from dicom dirs path
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                obj = getCineDataFromStudyDir(obj,varargin{1});
            end
            obj.calcSliceDistances;
            obj.calcTimes;
            obj.dispField = MRDispField(obj);
            obj.epi  = MRRoi(obj.nSlices,obj.nTimes,'Epi','green');
            obj.endo = MRRoi(obj.nSlices,obj.nTimes,'Endo','red');
        end
        
        %%% --------------------- OTHER METHODS --------------------- %%%
        
        function obj = set.savePath(obj,savePath)
            
            obj.savePath = savePath;
            
            if ~exist(obj.saveDirPath,'dir')
                success = mkdir(obj.saveDirPath);
                if ~success, warning('Not able to create a directory');end
            end
            if ~isempty(obj.dispField)
                obj.dispField.saveDirPath = obj.saveDirPath;
            end
        end
        
        function save(obj)
            save(obj.savePath,'obj');
        end
        
        function obj = saveobj(obj)
            %%% TODO find out why this one is called 2 times
            if strcmp(obj.savePath,'')
                warning('Probably saving to the wrong path %s',pwd)
            else
                fprintf('Saving to %s\n',obj.savePath)
            end
            
            % save DispField separately
            if ~isempty(obj.dispField) 
                obj.dispField.saveDirPath = obj.saveDirPath;
                obj.dispField.saveDispField;
                obj.dispField = MRDispField(obj);
            end
        end
        
        %%% --------------- Methods is separate files --------------- %%%
        obj = getCineDataFromStudyDir(obj,dcmDir);
    end
    
    
    methods (Static)
        
        %%% --------------- Methods is separate files --------------- %%%
        [dcmData,dcmTags] = rearrangeData(dcmData,dcmTags); % static couse it is called in the constructor

    end
    
end

