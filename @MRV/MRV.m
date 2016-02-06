classdef MRV < MRViewer3Dt
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MRData      = [];
    end
    
    properties (SetAccess = private, Hidden = true)             % These properties are private.
        overDims     = [];
        currentDim   = [];
    end
    
    methods
        function obj = MRV(varargin)
            
            %%%% MRData
            if isa(varargin{1},'MRData')
                M = varargin{1};
                backVol = M.(M.allowedImages{1,1});
                if ~isempty(M.(M.mrconfig{2,2}))
                    overVol = M.(M.mrconfig{2,2}).(M.allowedOverlays{1,1})(:,:,:,:,1);
                    overDims = M.allowedOverlays{1,3};
                end
            else
                error('Wrong input')
            end
            
            obj@MRViewer3Dt(backVol,overVol);
            obj.setAspectRatio(M.aspectRatio);
            obj.MRData = M;
            obj.overDims = overDims;
            obj.currentDim = 1;
            
            obj.updateMenus;
            
        end
        
        function obj = updateMenus(obj)
            M = obj.MRData;
            set(obj.figHandle,'MenuBar','none');
            set(obj.figHandle,'Toolbar','figure');
            h0=uimenu(obj.figHandle,'Label','Menu');
            uimenu(h0,'Label','Open folder with MAT data','callback',@why);
            uimenu(h0,'Label','Create folder with MAT from DICOM folder','callback',@why);
            uimenu(h0,'Label','Set WL & WW','callback',@setWLWW);
            uimenu(h0,'Label','Set some parameters (s)','callback',@setParams);
            uimenu(h0,'Label','Import qmass contours','callback',@importQmass,'Separator','on');
            uimenu(h0,'Label','Import MICCAI 2009 contours','callback',@importMICCAI2009);
            uimenu(h0,'Label','Export qmass contours','callback',@exportQmass,'Enable','Off');
            uimenu(h0,'Label','Export MICCAI 2009 contours','callback',@exportMICCAI2009);
            uimenu(h0,'Label','Quit and save','callback',@closeSaveAll,'Separator','on');
            uimenu(h0,'Label','Quit (do not save)','callback',@closeNOsave);
            h1 = uimenu(obj.figHandle,'Label','Background');
            for i=1:size(M.allowedImages,1)
                uimenu(h1,'Label',M.allowedImages{i,2},'callback',{@obj.setBackVolumeCLB,M.(M.allowedImages{i,1})})
            end
            h1a = uimenu(obj.figHandle,'Label','Overlay');
            for i=1:size(M.allowedOverlays,1)
                if M.allowedOverlays{i,3}>1
                    h11(i)=uimenu(h1a,'Label',M.allowedOverlays{i,2});
                    for j=1:M.allowedOverlays{i,3}
                        uimenu(h11(i),'Label',num2str(j),'callback',{@obj.setOverVolumeCLB,M.(M.mrconfig{2,2}).(M.allowedOverlays{i,1})(:,:,:,:,j)})
                    end
                else
                    h11(i)=uimenu(h1a,'Label',M.allowedOverlays{i,2},'callback',{@obj.setOverVolumeCLB,M.(M.mrconfig{2,2}).(M.allowedOverlays{i,1})});
                end
            end
            h2=uimenu(obj.figHandle,'Label','Manual operations');
            uimenu(h2,'Label','endoMan','callback',{@correctContour,'endoMan','endoAuto'});
            uimenu(h2,'Label','epiMan','callback',{@correctContour,'epiMan','epiAuto'});
            uimenu(h2,'Label','RVendoMan','callback',{@correctContour,'RVendoMan','RVendoAuto'});
            uimenu(h2,'Label','ROI1Man','callback',{@correctContour,'ROI1Man','ROI1Auto'});
            uimenu(h2,'Label','ROI2Man','callback',{@correctContour,'ROI2Man','ROI2Auto'});
            uimenu(h2,'Label','ROI3Man','callback',{@correctContour,'ROI3Man','ROI3Auto'});
            uimenu(h2,'Label','Define RVLV point(SA)/Axis(LA) (x)','callback',@defineCenterRVLV,'Separator','on');
            uimenu(h2,'Label','Delete current endoMan','callback',{@deleteOneContour,'endoMan'});
            uimenu(h2,'Label','Delete current epiMan','callback',{@deleteOneContour,'epiMan'});
            uimenu(h2,'Label','Delete current RVendoMan','callback',{@deleteOneContour,'RVendoMan'});
            uimenu(h2,'Label','Delete current ROI1Man','callback',{@deleteOneContour,'ROI1Man'});
            uimenu(h2,'Label','Delete current ROI2Man','callback',{@deleteOneContour,'ROI2Man'});
            uimenu(h2,'Label','Delete current ROI3Man','callback',{@deleteOneContour,'ROI3Man'});
            uimenu(h2,'Label','Delete ALL current contours','callback',@deleteCurrent);
            uimenu(h2,'Label','Delete EVERYTHING','callback',@setDefaults);
            h3=uimenu(obj.figHandle,'Label','Auto operations');
            uimenu(h3,'Label','Make contours spline','callback',@mycontour2Spline); %!!!!!
            uimenu(h3,'Label','Auto (approximation) LV ALL','callback',@mycontourApproximationAll);
            uimenu(h3,'Label','Auto (approximation) LV edno','callback',{@mycontourApproximation,'endoMan','endoAuto'});
            uimenu(h3,'Label','Auto (approximation) LV epi','callback',{@mycontourApproximation,'epiMan','epiAuto'});
            uimenu(h3,'Label','Auto (approximation) RV endo','callback',{@mycontourApproximation,'RVendoMan','RVendoAuto'});
            uimenu(h3,'Label','Auto (approximation) ROI1','callback',{@mycontourApproximation,'ROI1Man','ROI1Auto'});
            uimenu(h3,'Label','Auto (approximation) ROI2','callback',{@mycontourApproximation,'ROI2Man','ROI2Auto'});
            uimenu(h3,'Label','Auto (approximation) ROI3','callback',{@mycontourApproximation,'ROI3Man','ROI3Auto'});
            if exist('dispF','var')
                uimenu(h3,'Label','Auto (track based on displacement field)','callback',@mycontourTracking);
                uimenu(h3,'Label','Auto (register based on displacement field)','callback',@mycontourRegistration);
            else
                uimenu(h3,'Label','Auto (displacement field)','callback',@mycontourTracking,'Enable','Off');
                uimenu(h3,'Label','Auto (register based on displacement field)','callback',@mycontourRegistration,'Enable','Off');
            end
            
        end
        
        function obj = setBackVolumeCLB(obj,varargin)
            %%% TODO if iso change stuff
            obj.setBackVolume(varargin{3});
        end
        
        function obj = setOverVolumeCLB(obj,varargin)
            %%% TODO if iso change stuff
            obj.setOverVolume(varargin{3});
        end
        
        function obj = mrCloseRequestFcn(obj)
        end
    end
    
end

