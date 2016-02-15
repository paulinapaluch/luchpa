classdef MRDataLGE < MRData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        % this is visible from class, >> MRDispField.allowedImages
        className   = 'MRDataLGE';
        numClassName = 'masks';
        
        allowedImages = {...   % working on MRDataCINE object, fe. M.(allowedImages(1,1))
            'data',   'Data with corrections','useAspectRatio';...
            'dataRaw','Data from dicom','useAspectRatio';...
            'dataIso','Data with corrections isotropic (interpolated)',''};
        allowedOverlays = {... 
            'empty',  'None',  1;...
            'scar',  'Scar',   1};
    end
    
    properties
        epi          = [];      % epicardial MRRoi object
        endo         = [];      % endocardial MRRoi object
        myoMask      = [];
        masks        = [];
        scarMass     = [];
        qmassInFile  = [];      % in case qmass import is needed
        qmassOutFile = [];      % in case qmass export is needed
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj=MRDataLGE(varargin)
            if nargin==2
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                if iscell(varargin{1})  % from dicom dirs cell
                    disp(varargin{1})
                    obj = getLGEDataFromSeriesCell(obj,varargin{1});
%                 elseif exist(varargin{1},'dir') % from one dicom dir
%                     disp(varargin{1})
%                     obj = getCineDataFromStudyDir(obj,varargin{1});
                end
            elseif nargin==4 % from one dicom dir with conditions
                disp(varargin{1})
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                obj = getLGEDataFromStudyDirWithCondition(obj,varargin{1},varargin{3},varargin{4});
            else
                error('Wrong input data')
            end
            getObjParamsFromDcmTags(obj);
            obj.calcSliceDistances;
            obj.epi  = MRRoi(obj.nSlices,obj.nTimes,'Epi','green');
            obj.endo = MRRoi(obj.nSlices,obj.nTimes,'Endo','red');
            obj.masks.empty = [];
            obj.masks.scar = ones(size(obj.dataRaw));
            obj.dupaSave;
        end
        
        function myoMask = get.myoMask(obj)
            epiMask  = obj.epi.getMask(size(obj.dataRaw));
            endoMask = obj.endo.getMask(size(obj.dataRaw));
            myoMask = epiMask & ~endoMask;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% --------------- Methods is separate files --------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        obj = getLGEDataFromSeriesCell(obj,dcmDirs);
        scarVolume = calcScar(obj);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ---------------------- Static Methods  ---------------------- %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Static)
        
        % provide class name (by calling mfilename) to MRData load method
        function obj = load(mypath)
            obj = load@MRData(mypath,mfilename);
        end
    end
    
end

