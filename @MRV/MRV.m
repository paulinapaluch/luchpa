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
        overDims            = [];
        currentDim          = [];
        currentBackIdx      =  1;
        currentOverIdx      =  1;
        currentOverDimIdx   = [];
        rois                = [];
        roisManHandles      = [];
        roisAutHandles      = [];
        myoMask             = [];
        shifts              = [];        % rois (epi and endo) are defined for the raw data. If there were corrections, shifts are needed
        menuHandles         = [];
    end
    
    methods
        function obj = MRV(varargin)
            
            %%%% MRData
            if ~isa(varargin{1},'MRData')
                error('Wrong input')
            end
            
            M = varargin{1};
            backVol = M.allowedImages{1,1}();
            overVol = [];
            overDims=0;
            %             if ~isempty(M.numClassName) && ~isempty(M.(M.numClassName))
            %                 temp = M.(M.numClassName).(M.allowedOverlays{1,1})(:,:,:,:,1);
            %                 if ~isempty(temp) && all(size(temp)==size(backVol))
            %                     overVol = temp;
            %                     overDims = M.allowedOverlays{1,3};
            %                 end
            %             end
            obj@MRViewer3Dt(backVol,overVol);
            obj.MRData = M;
            wc=M.dcmTags(1).WindowCenter;ww=M.dcmTags(1).WindowWidth;
            obj.setBackRange([wc-ww/2, wc+ww/2]);
            obj.setAspectRatio(M.aspectRatio);
            obj.rois = M.rois;
            obj.shifts = M.breathShifts;
            obj.overDims = overDims;
            obj.currentDim = 1;
            obj.updateMenus;
            obj.initROIs;
            obj.updateROIs;
            obj.flags.hasChanged = 0;
            set(obj.figHandle,'CloseRequestFcn',@obj.mrCloseRequestFcn);
        end
        
        function obj = updateMenus(obj)
            M = obj.MRData;
            %set(obj.figHandle,'MenuBar','none'); % does not work for some reason
            delete(findall(obj.figHandle,'type','uimenu'))
            set(obj.figHandle,'Toolbar','figure');
            
            ai = M.allowedImages;
            ao = M.allowedOverlays;
            
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
            for i=1:size(ai,1)
                uimenu(h.back,'Label',ai{i,2},'callback',{@obj.setBackVolumeCLB,i});
            end
            
            h.over = uimenu(obj.figHandle,'Label','Overlay image');
            for i=1:size(ao,1)
                if ao{i,3}==1
                    h.over(i+1)=uimenu(h.over(1),'Label',ao{i,2},'callback',{@obj.setOverVolumeCLB2,i,[]});
                else
                    h.over(i+1)=uimenu(h.over(1),'Label',ao{i,2});
                    for j=1:ao{i,3}
                        uimenu(h.over(i+1),'Label',num2str(j),'callback',{@obj.setOverVolumeCLB2,i,j});
                    end
                end
            end
            if strcmp(ai{obj.currentBackIdx,1},'dataRaw')
                set(h.over(2:end),'enable','off')
            end
            
            h.manu=uimenu(obj.figHandle,'Label','Manual operations');
            for iroi = 1:size(M.roiList,1)
                roiname = M.roiList{iroi,1};
                uimenu(h.manu,'Label',['Draw manual ',roiname],'callback',{@obj.drawRoi,roiname},'Accelerator',num2str(iroi));
            end
            uimenu(h.manu,'Label','Define RVLV point(SA)/Axis(LA) (x)','callback',@defineCenterRVLV,'Separator','on');
            for iroi = 1:size(M.roiList,1)
                roiname = M.roiList{iroi,1};
                uimenu(h.manu,'Label',['Delete current ',roiname],'callback',{@obj.deleteOneContour,roiname});
            end
            uimenu(h.manu,'Label','Delete current rois','callback',@obj.deleteOneContour,'Accelerator','d');
            uimenu(h.manu,'Label','Delete EVERYTHING','callback',{@obj.deleteAllCountours});
            h.mask=uimenu(obj.figHandle,'Label','Mask');
            uimenu(h.mask,'Label','Mask overlay volume','callback',{@obj.maskOnOff},'Checked','off');
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
        
        function myroi = getROI(obj,val)
            % returns roi object
            % val can be roi number or roi name from MRDataCine.roiList
            myroi = [];
            if isnumeric(val) && length(val)==1
                myroi = obj.rois(val);
            elseif ischar(val)
                idx = find(strcmp(obj.MRData.roiList(:,1),val),1,'first');
                myroi = obj.rois(idx);
            end
        end
        
        function initROIs(obj)
            % all axes, though I use only axes 3 ATM
            for iax = 1:size(obj.axesHandles,2)
                axes(obj.axesHandles(iax)); %#ok
                hold on                                                 % Hold, to initialize rois
                for iroi = 1:size(obj.rois,2)
                    if strcmp(obj.getROI(iroi).type,'point')
                        obj.roisManHandles(iroi,iax) = plot(0,0,'x','color',obj.getROI(iroi).color);
                        obj.roisAutHandles(iroi,iax) = plot(0,0,'o', 'color',obj.getROI(iroi).color);
                    else
                        obj.roisManHandles(iroi,iax) = plot(0,0,'--','color',obj.getROI(iroi).color);
                        obj.roisAutHandles(iroi,iax) = plot(0,0,'-', 'color',obj.getROI(iroi).color);
                    end
                end
                hold off
            end
        end
        
        function updateImages(obj,axIdx)                         % Function to update the images
            if ~exist('myaxes','var'),axIdx=[];end
            updateImages@MRViewer3Dt(obj,axIdx);
            updateROIs(obj)
        end
        
        function updateROIs(obj)
            if isempty(obj.rois),return,end % constructor
            
            if all(obj.aspectRatio == [1 1 1])
                sidx = obj.MRData.slicesIdxIso;
                sliceIdx=round(sidx(obj.currentPoint(3)));
            else
                sliceIdx=obj.currentPoint(3);
            end
            
            shift_temp = obj.shifts(sliceIdx,:);
            for iroi = 1:size(obj.rois,2)
                myroiManP = obj.getROI(iroi).pointsMan{sliceIdx,obj.currentTime};
                myroiAutP = obj.getROI(iroi).pointsAut{sliceIdx,obj.currentTime};
                
                %%% manual
                if ~isempty(myroiManP)
                    set(obj.roisManHandles(iroi,3),'XData',[myroiManP(:,1);myroiManP(1,1)]-shift_temp(2))
                    set(obj.roisManHandles(iroi,3),'YData',[myroiManP(:,2);myroiManP(1,2)]-shift_temp(1))
                else
                    set(obj.roisManHandles(iroi,3),'XData',0)
                    set(obj.roisManHandles(iroi,3),'YData',0)
                end
                
                %%% automatic
                if ~isempty(myroiAutP)
                    set(obj.roisAutHandles(iroi,3),'XData',[myroiAutP(:,1);myroiAutP(1,1)]-shift_temp(2))
                    set(obj.roisAutHandles(iroi,3),'YData',[myroiAutP(:,2);myroiAutP(1,2)]-shift_temp(1))
                else
                    set(obj.roisAutHandles(iroi,3),'XData',0)
                    set(obj.roisAutHandles(iroi,3),'YData',0)
                end
            end
        end
        
        function drawCPoly(obj,myroi)
            try
                pos = myroi.pointsMan{obj.currentPoint(3),obj.currentTime};
                h = impoly(obj.axesHandles(3),pos);
                
                if ~isempty(pos),wait(h);end
                pos = h.getPosition;
                pos(:,1)=pos(:,1)+obj.shifts(2);
                pos(:,2)=pos(:,2)+obj.shifts(1);
                myroi.pointsMan{obj.currentPoint(3),obj.currentTime} = pos;
                delete(h)
                updateImages(obj)
            catch ex
                obj.flags.controls = 1;
                ex
            end
        end
        
        function drawPoint(obj,myroi)
            try
                pos = myroi.pointsMan{obj.currentPoint(3),obj.currentTime};
                h = impoint(obj.axesHandles(3),pos);
                
                if ~isempty(pos),wait(h);end
                pos = h.getPosition;
                pos(:,1)=pos(:,1)+obj.shifts(2);
                pos(:,2)=pos(:,2)+obj.shifts(1);
                myroi.pointsMan{obj.currentPoint(3),obj.currentTime} = pos;
                delete(h)
                updateImages(obj)
            catch ex
                obj.flags.controls = 1;
                ex
            end
        end
        
        
        function drawRoi(obj,varargin)
            if all(obj.aspectRatio == [1 1 1])
                disp('Not allowed on iso data')
                return
            end
            obj.flags.controls = 0;
            obj.flags.hasChanged = 1;
            contName = varargin{3};
            myroi = obj.getROI(contName);
            switch myroi.type
                case 'cpoly'
                    drawCPoly(obj,myroi)
                case 'point'
                    drawPoint(obj,myroi)
            end
            obj.flags.controls = 1;
        end
        
        function myoMask = get.myoMask(obj)
            epiMask  = obj.epi.getMask(obj.volumeSize);
            endoMask = obj.endo.getMask(obj.volumeSize);
            myoMask = epiMask & ~endoMask;
        end
        
        function deleteOneContour(obj,varargin)
            if all(obj.aspectRatio == [1 1 1])
                disp('Not allowed on iso data')
                return
            end
            if nargin<4
                for iroi = 1:size(obj.rois,2)
                    obj.getROI(iroi).pointsMan{obj.currentPoint(3),obj.currentTime} = [];
                end
            else
                contName = varargin{3};
                obj.getROI(contName).pointsMan{obj.currentPoint(3),obj.currentTime} = [];
            end
            updateImages(obj)
        end
        
        function deleteAllCountours(obj,varargin)
            % add warning
            for iroi = 1:size(obj.rois,2)
                obj.getROI(iroi).pointsMan = cell(obj.volumeSize(3),obj.volumeSize(4));
            end
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
            obj.currentOverDimIdx = dimIdx;
        end
        
        function obj = setOverVolumeCLB2(obj,varargin)
            overIdx = varargin{3};
            dimIdx = varargin{4};
            M = obj.MRData;
            ao = M.allowedOverlays{overIdx,1}();
            if isempty(dimIdx)
                overVol =  ao;
            else
                overVol =  ao(:,:,:,:,dimIdx);
            end
            if ~isempty(overVol) && all(size(overVol)==size(obj.backVol))
                obj.setOverVolume(overVol);
            else
                disp('Different size of back and over volumes')
            end
            obj.currentOverIdx = overIdx;
            obj.currentOverDimIdx = dimIdx;
        end
        
        function obj = maskOnOff(obj,varargin)
            if ~isempty(obj.overVol)
                overVol = [];
                if strcmp(obj.menuHandles.mask.Checked,'off')
                    obj.menuHandles.mask.Checked = 'on';
                    overVol = obj.overVol.*obj.myoMask;
                elseif strcmp(obj.menuHandles.mask.Checked,'on')
                    obj.menuHandles.mask.Checked = 'off';
                    overIdx = obj.currentOverIdx;
                    dimIdx = obj.currentOverDimIdx;
                    M = obj.MRData;
                    if isempty(dimIdx)
                        overVol = M.(M.numClassName).(M.allowedOverlays{overIdx,1});
                    else
                        overVol = M.(M.numClassName).(M.allowedOverlays{overIdx,1})(:,:,:,:,dimIdx);
                    end
                end
                if ~isempty(overVol) && all(size(overVol)==size(obj.backVol))
                    obj.setOverVolume(overVol);
                    obj.setOverRange(obj.getRange(overVol));
                    %updateImages(obj)
                else
                    disp('Different size of back and over volumes')
                end
            end
        end
        
        function importMICCAI2009CLB(obj,varargin)
            obj.MRData.importMICCAI2009;
        end
        
        function obj = mrCloseRequestFcn(obj,varargin)
            try
                if obj.flags.hasChanged
                    answer = questdlg('Save changes?','Save changes','Yes','No','Cancel','Yes');
                    switch answer
                        case 'Yes'
                            obj.MRData.dupaSave;
                            delete(obj.figHandle);
                        case 'No'
                            delete(obj.figHandle);
                        case 'Cancel'
                            return
                    end
                else
                    delete(obj.figHandle);
                end
            catch ex
                disp(ex)
            end
        end
    end
    
end

