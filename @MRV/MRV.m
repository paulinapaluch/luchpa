classdef MRV < MRViewer3Dt
    %MRV Summary of this class goes here
    %   Detailed explanation goes here
    %
    % Konrad Werys, Feb 2016
    % konradwerys@gmail.com
    % <mrkonrad.github.io>
    
    properties
        MRData      = [];
    end
    
    properties (SetAccess = private, Hidden = true)             % These properties are private.
        overDims       = [];
        currentDim     = [];
        currentBackIdx =  1;
        currentOverIdx =  1;
        endoManHandles = [];
        epiManHandles  = [];
        endoAutHandles = [];
        epiAutHandles  = [];
        endo           = [];
        epi            = [];
        shifts         = [];        % rois (epi and endo) are defined for the raw data. If there were corrections, shifts are needed
        menuHandles    = [];
    end
    
    methods
        function obj = MRV(varargin)
            
            %%%% MRData
            if ~isa(varargin{1},'MRData')
                error('Wrong input')
            end
            
            M = varargin{1};
            backVol = M.(M.allowedImages{1,1});
            overVol = [];
            overDims=0;
            if ~isempty(M.(M.numClassName))
                temp = M.(M.numClassName).(M.allowedOverlays{1,1})(:,:,:,:,1);
                if ~isempty(temp) && all(size(temp)==size(backVol)) 
                    overVol = temp;
                    overDims = M.allowedOverlays{1,3};
                end
            end
            obj@MRViewer3Dt(backVol,overVol);
            obj.MRData = M;
            obj.setAspectRatio(M.aspectRatio);
            obj.epi  = obj.MRData.epi;      % 'pointers'
            obj.endo = obj.MRData.endo;     % 'pointers'
            obj.shifts = M.breathShifts;
            obj.overDims = overDims;
            obj.currentDim = 1;
            obj.updateMenus;
            obj.initROIs;
            obj.updateROIs;
        end
        
        function obj = updateMenus(obj)
            M = obj.MRData;
            %set(obj.figHandle,'MenuBar','none'); % does not work for some reason
            delete(findall(obj.figHandle,'type','uimenu'))
            set(obj.figHandle,'Toolbar','figure');
            
            
            h.menu=uimenu(obj.figHandle,'Label','Menu');
            uimenu(h.menu,'Label','Open folder with MAT data','callback',@why);
            uimenu(h.menu,'Label','Create folder with MAT from DICOM folder','callback',@why);
            uimenu(h.menu,'Label','Set WL & WW','callback',@setWLWW);
            uimenu(h.menu,'Label','Set some parameters (s)','callback',@setParams);
            uimenu(h.menu,'Label','Import qmass contours','callback',@importQmass,'Separator','on');
            uimenu(h.menu,'Label','Import MICCAI 2009 contours','callback',@obj.importMICCAI2009CLB);
            uimenu(h.menu,'Label','Export qmass contours','callback',@exportQmass,'Enable','Off');
            uimenu(h.menu,'Label','Export MICCAI 2009 contours','callback',@exportMICCAI2009);
            uimenu(h.menu,'Label','Quit and save','callback',@closeSaveAll,'Separator','on');
            uimenu(h.menu,'Label','Quit (do not save)','callback',@closeNOsave);
            h.back = uimenu(obj.figHandle,'Label','Background image');
            for i=1:size(M.allowedImages,1)
                uimenu(h.back,'Label',M.allowedImages{i,2},'callback',{@obj.setBackVolumeCLB,i});
            end
            h.over = uimenu(obj.figHandle,'Label','Overlay image');
            for i=1:size(M.allowedOverlays,1)
                if M.allowedOverlays{i,3}==1
                    h.over(i+1)=uimenu(h.over(1),'Label',M.allowedOverlays{i,2},'callback',{@obj.setOverVolumeCLB,i,[]});
                else
                    h.over(i+1)=uimenu(h.over(1),'Label',M.allowedOverlays{i,2});
                    for j=1:M.allowedOverlays{i,3}
                        uimenu(h.over(i+1),'Label',num2str(j),'callback',{@obj.setOverVolumeCLB,i,j});
                    end
                end
            end
            if strcmp(M.allowedImages{obj.currentBackIdx,1},'dataRaw')
                set(h.over(2:end),'enable','off')
            end
            h.manu=uimenu(obj.figHandle,'Label','Manual operations');
            uimenu(h.manu,'Label','Draw endo','callback',{@obj.drawContour,'endo'},'Accelerator','1');
            uimenu(h.manu,'Label','Draw epi','callback',{@obj.drawContour,'epi'},'Accelerator','2');
            uimenu(h.manu,'Label','Define RVLV point(SA)/Axis(LA) (x)','callback',@defineCenterRVLV,'Separator','on');
            uimenu(h.manu,'Label','Delete current endoMan','callback',{@obj.deleteOneContour,'endo'});
            uimenu(h.manu,'Label','Delete current epiMan','callback',{@obj.deleteOneContour,'epi'});
            uimenu(h.manu,'Label','Delete current','callback',@obj.deleteOneContour,'Accelerator','d');
            uimenu(h.manu,'Label','Delete EVERYTHING','callback',{@obj.deleteAllCountours});
            h.auto=uimenu(obj.figHandle,'Label','Auto operations');
            uimenu(h.auto,'Label','Make contours spline','callback',@mycontour2Spline); %!!!!!
            uimenu(h.auto,'Label','Auto (approximation) LV ALL','callback',@mycontourApproximationAll);
            uimenu(h.auto,'Label','Auto (approximation) LV edno','callback',{@mycontourApproximation,'endoMan','endoAuto'});
            uimenu(h.auto,'Label','Auto (approximation) LV epi','callback',{@mycontourApproximation,'epiMan','epiAuto'});
            if exist('dispF','var')
                uimenu(h.auto,'Label','Auto (track based on displacement field)','callback',@mycontourTracking);
                uimenu(h.auto,'Label','Auto (register based on displacement field)','callback',@mycontourRegistration);
            else
                uimenu(h.auto,'Label','Auto (displacement field)','callback',@mycontourTracking,'Enable','Off');
                uimenu(h.auto,'Label','Auto (register based on displacement field)','callback',@mycontourRegistration,'Enable','Off');
            end
            obj.menuHandles = h;
        end
        
        function initROIs(obj)
            axes(obj.axesHandles(1))
            hold on                                                 % Hold, to initialize rois
            obj.epiManHandles(1)  = plot(0,0,'.','Color',obj.epi.color);
            obj.endoManHandles(1) = plot(0,0,'.','Color',obj.endo.color);
            hold off
            axes(obj.axesHandles(2))
            hold on                                                 % Hold, to initialize rois
            obj.epiManHandles(2)  = plot(0,0,'.','Color',obj.epi.color);
            obj.endoManHandles(2) = plot(0,0,'.','Color',obj.endo.color);
            hold off
            axes(obj.axesHandles(3))
            hold on                                                 % Hold, to initialize rois
            obj.epiManHandles(3)  = plot(0,0,'.','Color',obj.epi.color);
            obj.endoManHandles(3) = plot(0,0,'.','Color',obj.endo.color);
            hold off   
        end
        
        function updateImages(obj,axIdx)                         % Function to update the images
            if ~exist('myaxes','var'),axIdx=[];end
            updateImages@MRViewer3Dt(obj,axIdx);
            updateROIs(obj)
        end
        
        function updateROIs(obj)
            if isempty(obj.epi) || isempty(obj.endo) % in constructor
                return
            end
            
            if all(obj.aspectRatio == [1 1 1])
                sidx = obj.MRData.slicesIdxIso;
                sliceIdx=round(sidx(obj.currentPoint(3)));
            else
                sliceIdx=obj.currentPoint(3);
            end
            
            epi_temp = obj.epi.pointsMan{sliceIdx,obj.currentTime};
            endo_temp = obj.endo.pointsMan{sliceIdx,obj.currentTime};
            shift_temp = obj.shifts(sliceIdx,:);
            try
                if ~isempty(epi_temp)
                    
                    set(obj.epiManHandles(3),'XData',[epi_temp(:,1);epi_temp(1,1)]-shift_temp(2))
                    set(obj.epiManHandles(3),'YData',[epi_temp(:,2);epi_temp(1,2)]-shift_temp(1))
                else
                    set(obj.epiManHandles(3),'XData',0)
                    set(obj.epiManHandles(3),'YData',0)
                end
                if ~isempty(endo_temp)
                    set(obj.endoManHandles(3),'XData',[endo_temp(:,1);endo_temp(1,1)]-shift_temp(2))
                    set(obj.endoManHandles(3),'YData',[endo_temp(:,2);endo_temp(1,2)]-shift_temp(1))
                else
                    set(obj.endoManHandles(3),'XData',0)
                    set(obj.endoManHandles(3),'YData',0)
                end
            catch ex
                ex
            end
        end
        
        function drawContour(obj,varargin)
            if all(obj.aspectRatio == [1 1 1])
                disp('Not allowed on iso data')
                return
            end
            
            contName = varargin{3};
            try
                pos = obj.(contName).pointsMan{obj.currentPoint(3),obj.currentTime};
                h = impoly(obj.axesHandles(3),pos);
                if ~isempty(pos),wait(h);end
                pos = h.getPosition;
                pos(:,1)=pos(:,1)+obj.shifts(2);
                pos(:,2)=pos(:,2)+obj.shifts(1);
                obj.(contName).pointsMan{obj.currentPoint(3),obj.currentTime} = pos;
                delete(h)
                updateImages(obj)
            catch ex
                ex
            end
        end
        
        function deleteOneContour(obj,varargin)
            if all(obj.aspectRatio == [1 1 1])
                disp('Not allowed on iso data')
                return
            end
            if nargin<4
                obj.epi.pointsMan{obj.currentPoint(3),obj.currentTime} = [];
                obj.endo.pointsMan{obj.currentPoint(3),obj.currentTime} = [];
            else
                contName = varargin{3};
                obj.(contName).pointsMan{obj.currentPoint(3),obj.currentTime} = [];
            end
            updateImages(obj)
        end
        
        function deleteAllCountours(obj,varargin)
            % add warning
            obj.epi.pointsMan = cell(obj.volumeSize(3),obj.volumeSize(4));
            obj.endo.pointsMan = cell(obj.volumeSize(3),obj.volumeSize(4));
            updateImages(obj)
        end
  
        function obj = setBackVolumeCLB(obj,varargin)
            backIdx = varargin{3};
            M = obj.MRData;
            backVol = M.(M.allowedImages{backIdx,1});
            if isempty(obj.overVol) || ~all(size(backVol)==size(obj.overVol))
                disp('Different size of back and over volumes')
                obj.setOverVolume([]);
            end
            
            obj.setBackVolume(backVol);
            obj.volumeSize = size(backVol);
            
            obj.shifts=M.breathShifts;
            if strcmp(M.allowedImages{backIdx,1},'dataRaw')
                disp('Raw data - no disp fileds available, because they were calculated for corrected data.')
                obj.setOverVolume([]);
                obj.shifts = zeros(M.nSlices,2);
            end
            
            if strcmp(M.allowedImages{backIdx,3},'useAspectRatio')
                setAspectRatio(obj,M.aspectRatio);
            else
                setAspectRatio(obj,[1,1,1]);
            end
            
            obj.currentBackIdx = backIdx;
            obj.updateImages;
            obj.updateMenus;
        end
        
        function importMICCAI2009CLB(obj,varargin)
            obj.MRData.importMICCAI2009;
        end
        
        function obj = setOverVolumeCLB(obj,varargin)
            overIdx = varargin{3};
            dimIdx = varargin{4};
            M = obj.MRData;
            if isempty(dimIdx)
                overVol = M.(M.numClassName).(M.allowedOverlays{overIdx,1});
            else
                overVol = M.(M.numClassName).(M.allowedOverlays{overIdx,1})(:,:,:,:,dimIdx);
            end
            if ~isempty(overVol) && all(size(overVol)==size(obj.backVol))
                obj.setOverVolume(overVol);
            else
                disp('Different size of back and over volumes')
            end
            obj.currentOverIdx = overIdx;
        end
        
        function obj = mrCloseRequestFcn(obj)
        end
    end
    
end

