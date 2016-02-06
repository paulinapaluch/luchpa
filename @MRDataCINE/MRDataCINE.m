classdef MRDataCINE < MRData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        savePath
    end
    
    properties (GetAccess = public, SetAccess = protected)
        dispField = [];
    end
    
    methods 
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        function obj=MRDataCINE(varargin)
            if nargin<2
                error('Wrong input data')
            % from dicom dirs path
            elseif nargin==2 && exist(varargin{1},'dir')
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                obj = getCineDataFromStudyDir(obj,varargin{1});
            %%% TBI from 4d matrix 
%             elseif nargin==1
%                 obj.data = varargin{1};
%                 obj.dcmTags = [];
%                 obj.imageOrientationPatient = zeros(1,6);
%                 obj.imagePositionPatient = zeros(1,3);
%                 obj.aspectRatio = ones(1,3);
%                 obj.breathShifts = zeros(1,size(obj.data,3));
%             % from object
%             elseif nargin==2
%                 obj = varargin{2};
%                 obj.data = varargin{1};
%                 obj.dcmTags = [];
            end
            obj.calcSliceDistances;
            obj.calcTimes;
            obj.dispField = MRDispField(obj);
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
        
%         function load(obj,mypath) % call mrdata save with mypath as file path
%             obj = load(mypath);
%         end
        
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

