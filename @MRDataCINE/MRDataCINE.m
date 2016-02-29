classdef MRDataCINE < MRData
    %MRDataCINE stores the data and allows for displacement field
    %   calculations using MRRegistration methods
    %   
    %   There are three ways to get a MRDataCINE object:
    %   - providing dicom dir path (study) - its contents will be analysed 
    %   to get desired data
    %   - providing cell of dicom dir paths (multiple series) - its 
    %   contents will be analysed to get desired data
    %   - loading previously saved MRDataCINE object
    %
    % Konrad Werys, Feb 2016
    % konradwerys@gmail.com
    % <mrkonrad.github.io>
    
    properties (Constant)
        % this is visible from class, >> MRDispField.roiList
        className   = 'MRDataCINE';
        roiList = {...
            'endo', 'red';...
            'epi',  'green';...
            };
    end
    
    properties
        tEndSystole  = [];      % end systole per slice
        tEndDiastole = [];      % end diastole per slice
        miccaiInDir  = [];      % in case miccai 2009 import is needed
        miccaiOutDir = [];      % in case miccai 2009 export is needed
        qmassInFile  = [];      % in case qmass import is needed
        qmassOutFile = [];      % in case qmass export is needed
        autoSegMask  = [];
    end
    
    properties (GetAccess = public, SetAccess = protected, Transient)
        dispField    = [];      % MRDispField object
        rois         = [];      % vector with rois
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
                g(@self.dispField.empty), 'empty', 1        ;...
                g(@self.dispField.back),  'back',  3        ;...
                g(@self.dispField.forw),  'forw',  3        ;...
                g(@self.dispField.magBack), 'magBack', 1    ;...
                g(@self.dispField.magForw), 'magForw', 1    ;...
                };
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj=MRDataCINE(varargin)
            if nargin==2
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                if iscell(varargin{1})  % from dicom dirs cell
                    disp(varargin{1})
                    obj = getCineDataFromSeriesCell(obj,varargin{1});
                elseif exist(varargin{1},'dir') % from one dicom dir
                    disp(varargin{1})
                    obj = getCineDataFromStudyDir(obj,varargin{1});
                end
            elseif nargin==4 % from one dicom dir with conditions
                disp(varargin{1})
                obj.dcmsPath = varargin{1};
                obj.savePath = varargin{2};
                obj = getCineDataFromStudyDirWithCondition(obj,varargin{1},varargin{3},varargin{4});
            else
                error('Wrong input data')
            end
            getObjParamsFromDcmTags(obj);
            obj.calcSliceDistances;
            obj.calcTimes;
            obj.dispField = MRDispField(obj);
            %%% ready the rois
            rl = obj.roiList;
            for iroi=1:size(rl,1)
                temp(iroi) = MRRoi(obj.nSlices,obj.nTimes,rl{iroi,1},rl{iroi,2});
            end
            obj.rois = temp;

            obj.dupaSave;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% --------------------- OTHER METHODS --------------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function sobj = saveobj(obj)
            %%% it is called 2 times, because http://stackoverflow.com/questions/6677486/why-does-matlab-save-call-saveobj-twice
            if isempty(obj.savePath)
                warning('Probably saving to the wrong path %s',pwd)
            else
                fprintf('Saving to %s\n',obj.getFullSavePath)
            end
            
            % save DispField separately
            if ~isempty(obj.dispField) && ~isempty(obj.dispField.type) 
                obj.dispField.savePath = obj.getFullSavePath;
                obj.dispField.saveDispField;
            end
            sobj = obj;
        end
        
        function dispField = get.dispField(obj)
            if isempty(obj.dispField)
                obj.dispField = MRDispField(obj);
                obj.dispField.savePath = obj.getFullSavePath;
                obj.dispField.loadPath = obj.loadPath;
            end
            dispField = obj.dispField;
        end
        
        function myroi = getROI(obj,val)
            % returns roi object
            % val can be roi number or roi name from MRDataCine.roiList
            myroi = [];
            if isnumeric(val) && length(val)==1
                myroi = obj.rois(val);
            elseif ischar(val)
                idx = find(strcmp(MRDataCINE.roiList(:,1),val),1,'first');
                myroi = obj.rois(idx);
            end
        end
        
        function mymask = getRoiMask(obj,roi)
            % val can be roi number or roi name from MRDataCine.roiList
            myroi = getROI(obj,roi);
            mymask = myroi.getMask(size(obj.dataRaw));
        end
        
        function myoMask = getMyoMask(obj)
%             epiMask  = obj.epi.getMask(size(obj.dataRaw));
%             endoMask = obj.endo.getMask(size(obj.dataRaw));
            epiMask = obj.getRoiMask('epi');
            endoMask = obj.getRoiMask('endo');
            myoMask = epiMask & ~endoMask;
        end
        
        function volumes = getVolumes(obj)
            volumes = squeeze(sum(sum(sum(obj.autoSegMask,1),2),3));
            volumes = volumes.*obj.aspectRatio(1)*obj.aspectRatio(2)*obj.aspectRatio(3)/1000;
        end
        
        function [volES,tES] = getESVolume(obj)
            volumes = obj.getVolumes;
            [volES,tES] = min(volumes);
        end
        
        function [volED,tED] = getEDVolume(obj)
            volumes = obj.getVolumes;
            [volED,tED] = max(volumes);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% --------------- Methods is separate files --------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        obj = getCineDataFromStudyDir(obj,dcmDir);
        obj = getCineDataFromSeriesCell(obj,dcmDirs);
        obj = importRoisMICCAI2009(obj);
        obj = exportRoisMICCAI2009(obj);
        obj = exportRoisQmass(obj);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ---------------------- Static Methods  ---------------------- %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Static)
        
        % provide class name (by calling mfilename) to MRData load method
        function obj = load(mypath)
            obj = load@MRData(mypath,mfilename);
            obj.dispField.loadPath = obj.getFullLoadPath;
        end
    end
    
end

