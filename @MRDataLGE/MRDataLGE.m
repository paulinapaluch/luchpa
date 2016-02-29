classdef MRDataLGE < MRData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        % this is visible from class, >> MRDispField.allowedImages
        className   = 'MRDataLGE';
        
        roiList = {...
            'endo',     'red',      'cpoly';...
            'epi',      'green',    'cpoly';...
            'healthy',  'magenta',  'cpoly';...
            'scar',     'cyan',     'point';...
            };
        
    end
    
    properties
        rois         = [];
        emptyMask    = [];
        scarMask     = [];
        scarMass     = [];
        qmassInFile  = [];      % in case qmass import is needed
        qmassOutFile = [];      % in case qmass export is needed
    end
    
    methods
        function ai = allowedImages(self)
            ai = {...
                g(@self.data),   'Corrected data',          'useAspectRatio';...
                g(@self.dataRaw),'Data from dicom',         'useAspectRatio';...
                g(@self.dataIso),'Corrected data isotropic',''              ;...
                };
        end
        
        function ao = allowedOverlays(self)
            % % I think I should add 'mother data' to allowed overlays. backDF
            % % calculated on dataRaw should not be used on shifted data
            ao = {...
                g(@self.infarctMask), 'Empty', 1        ;...
                g(@self.scarMask), 'Thresholded', 1  ;...
                };
        end
        
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
            obj.emptyMask = [];
            obj.scarMask = ones(size(obj.dataRaw));
            obj.initRois;
            obj.dupaSave;
        end
        
        function initRois(obj)
            %%% ready the rois
            rl = obj.roiList;
            for iroi=1:size(rl,1)
                temp(iroi) = MRRoi(obj.nSlices,obj.nTimes,rl{iroi,1},rl{iroi,2},rl{iroi,3});
            end
            obj.rois = temp;
        end
        
        function myroi = getROI(obj,val)
            % returns roi object
            % val can be roi number or roi name from MRData.roiList
            myroi = [];
            if isnumeric(val) && length(val)==1
                myroi = obj.rois(val);
            elseif ischar(val)
                idx = find(strcmp(obj.roiList(:,1),val),1,'first');
                myroi = obj.rois(idx);
            end
        end
        
        function mymask = getRoiMask(obj,roi)
            % val can be roi number or roi name from MRData.roiList
            myroi = getROI(obj,roi);
            mymask = myroi.getMask(size(obj.dataRaw));
        end
        
        function myoMask = getMyoMask(obj)
            epiMask = obj.getRoiMask('epi');
            endoMask = obj.getRoiMask('endo');
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

