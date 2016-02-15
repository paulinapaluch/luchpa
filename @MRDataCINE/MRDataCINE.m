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
        % this is visible from class, >> MRDispField.allowedImages
        className   = 'MRDataCINE';
        numClassName = 'dispField';

        allowedImages = {...   % working on MRDataCINE object, fe. M.(allowedImages(1,1))
            'data',   'Data with corrections','useAspectRatio';...
            'dataRaw','Data from dicom','useAspectRatio';...
            'dataIso','Data with corrections isotropic (interpolated)',''};
        allowedOverlays = {... % working on MRDispField object within MRDataCINE object, fe. M.dispField.(allowedImages(1,1))
            'empty',  'None',   1;...
            'back',   'back',   3;...
            'forw',   'forw',   3;...
            ...%'comb','comb',3;...
            'magBack','magBack',1;...
            'magForw','magForw',1};...
            %'magComb','magComb',1}
        % I think I should add 'mother data' to allowed overlays. backDF
        % calculated on dataRaw should not be used on shifted data
    end
    
    properties
        epi          = [];      % epicardial MRRoi object
        endo         = [];      % endocardial MRRoi object
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
    end
    
    methods 
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
            obj.epi  = MRRoi(obj.nSlices,obj.nTimes,'Epi','green');
            obj.endo = MRRoi(obj.nSlices,obj.nTimes,'Endo','red');
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
        
        function myoMask = getMyoMask(obj)
            epiMask  = obj.epi.getMask(size(obj.dataRaw));
            endoMask = obj.endo.getMask(size(obj.dataRaw));
            myoMask = epiMask & ~endoMask;
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
        end
    end
    
end

