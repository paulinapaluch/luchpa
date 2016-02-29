classdef MRRegistration <  matlab.mixin.SetGet
    %MRRegistration - non-rigid (deformable) image registration
    %   Based on DJK image_registration function #20057 (matlabcentral)
    %
    % Konrad Werys, Feb 2016
    % mrkonrad.github.io
    
    properties (Constant)
        allowedSims = {'sd','mi','d','gd','gc','cc','pi','ld'};
        allowedPreRegs = {'Rigid','Affine'};
        allowedInterps = {'Linear','Cubic'};
        defOptim2d = struct('GradObj','on','GoalsExactAchieve',0,'StoreN',10,'HessUpdate','lbfgs','Display','off','MaxIter',100,'DiffMinChange',0.001,'DiffMaxChange',1,'MaxFunEvals',1000,'TolX',0.005,'TolFun',1e-8);
        defOptim3d = struct('GradObj','on','GoalsExactAchieve',0,'StoreN',10,'HessUpdate','lbfgs','Display','off','MaxIter',100,'DiffMinChange',0.03,'DiffMaxChange',1,'MaxFunEvals',1000,'TolX',0.05,'TolFun',1e-8);
    end
    
    properties (GetAccess = public, SetAccess = private)
        Im          = [];
        Is          = [];
        Dims        = []; % 2 or 3
        Iclass      = [];
        
        Imn         = []; % normalized and resized
        Isn         = []; % normalized
    end
    
    properties
        %%% INPUT
        Interpolation = 'Linear';
        Similarity  = []; % sd, mu itp
        PreReg      = []; % Rigid/Affine
        Penalty     = 1e-3; % weigh of regularization term
        nRef        = []; % number of grid refinemets
        SpacingInit = []; % SpacingInit of initial grid; must be powers of 2
        MaskMoving  = [];
        MaskStatic  = [];
        Verbose     = 2;
        Points1     = [];
        Points2     = [];
        PStrength   = [];
        Scaling     = [1 1];
        optimPars   = MRRegistration.defOptim2d;
        %%% OUTPUT
        M           = [];
        B           = [];
        Imt         = [];
        DispField   = [];
        SpacingFin  = []; % Output spacing
        BSGrid      = []; % Output grid
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = MRRegistration(Im,Is,varargin)
            
            if(size(Im,3)>3), obj.Dims=3; else obj.Dims=2; end         % get number of dimensions
            if obj.Dims==3, obj.Penalty = 1e-5; obj.Scaling = [1 1 1]; obj.optimPars = defOptim3d; end  % if 3d adjust default options
            obj.Im = Im;
            obj.Is = Is;
            
            parseInputs(obj,varargin);
            obj.normalizeImages;  % normalize intesities of the images and change them to double
            images2samesize(obj); % resize moving image to fit static image
            makeInitialGrid(obj); % make initial grid
            
        end
        
        function normalizeImages(obj)
            obj.Iclass=class(obj.Im);
            
            obj.Im=double(obj.Im);
            obj.Is=double(obj.Is);
            
            Imin=min(min(obj.Is(:)),min(obj.Im(:)));
            Imax=max(max(obj.Is(:)),max(obj.Is(:)));
            obj.Imn=(obj.Im-Imin)/(Imax-Imin);
            obj.Isn=(obj.Is-Imin)/(Imax-Imin);
        end
        
        function makeInitialGrid(obj)
            % Make the Initial b-spline registration grid
            obj.BSGrid=obj.makeInitGridKW(obj.SpacingInit, size(obj.Im), obj.BSGrid, obj.M);
        end
        
        function images2samesize(obj)
            % Resize the moving image to fit the static image
            if(sum(size(obj.Isn)-size(obj.Im))~=0)
                % Resize the moving image to fit the static image
                if obj.Dims==3
                    obj.Imn=imresize3d(obj.Imn,[],size(obj.Isn),'cubic');
                    if(~isempty(obj.MaskMoving))
                        obj.MaskMoving=imresize3d(obj.MaskMoving,[],size(obj.Isn),'cubic');
                    end
                else
                    obj.Imn = imresize(obj.Imn,[size(obj.Isn,1) size(obj.Isn,2)],'bicubic');
                    if(~isempty(obj.MaskMoving))
                        obj.MaskMoving = imresize(obj.MaskMoving,[size(obj.Isn,1) size(obj.Isn,2)],'bicubic');
                    end
                end
            end
        end
        
        function parseInputs(obj,input)
            p = inputParser;                    % inputparser
            p.addParameter('Interpolation', obj.Interpolation, @(x) any(validatestring(x,obj.allowedInterps)));
            p.addParameter('Similarity', obj.check_image_modalities, @(x) any(validatestring(x,obj.allowedSims)));
            p.addParameter('PreReg', obj.PreReg, @(x) any(validatestring(x,obj.allowedPreRegs)));
            p.addParameter('Penalty', obj.Penalty, @isnumeric);
            p.addParameter('Verbose', obj.Verbose, @(x) isinteger(x) & x>=0 & x<3);
            p.addParameter('SpacingInit', obj.calcSpacingInit, @(x) isnumeric(x) & length(x)==obj.Dims & all(mod(log2(x),1)==0) & all(x>0)); % is numeric; is of power of 2; is bigger then 0; size == nDims
            p.addParameter('nRef', obj.calcMaxNRef-2, @(x) isnumeric(x) & x>=0); % -2, cause usually there is no need for registration with [1 1] nad [2 2] spacing
            p.addParameter('BSGrid', obj.BSGrid,@isnumeric); % TODO check sizes & calculate initial grid
            p.addParameter('MaskMoving', obj.MaskMoving, @(x) all(size(x)==size(obj.Im)));
            p.addParameter('MaskStatic', obj.MaskStatic, @(x) all(size(x)==size(obj.Is)));
            p.addParameter('Points1', obj.Points1);
            p.addParameter('Points2', obj.Points2);
            p.addParameter('PStrength', obj.PStrength);
            p.addParameter('Scaling', obj.Scaling, @(x)isnumeric & length(x)==obj.Dims);
            p.parse(input{:});
            fn = fieldnames(p.Results);
            for i=1:length(fn)
                obj.(fn{i}) = p.Results.(fn{i});
            end
            %%% nRef is checked after SpacingInit is calculated
            obj.checkNRef;
        end
        
        function maxNRef = calcMaxNRef(obj)
            maxNRef = min(floor(log2(size(obj.Im)/4)));
        end
        
        function SpacingInit = calcSpacingInit(obj)
            maxNRef = calcMaxNRef(obj);
            SpacingInit = ones(1,obj.Dims);
            SpacingInit = SpacingInit .* 2^maxNRef;
        end
        
        function checkNRef(obj)
            maxNRef = min(log2(obj.SpacingInit));
            if maxNRef<obj.nRef
                myerrtxt = ['With Spacing: [',num2str(obj.SpacingInit),...
                    '], maximum allowed nRef is: ',num2str(maxNRef)];
                error(myerrtxt)
            end
        end
        
        function type=check_image_modalities(obj)
            % Detect if the mutual information or pixel distance can be used as
            % similarity measure. By comparing the histograms.
            Hmoving = hist(obj.Im(:),(1/60)*[0.5:60])./numel(obj.Im);
            Hstatic = hist(obj.Is(:),(1/60)*[0.5:60])./numel(obj.Is);
            if(sum(abs(Hmoving(:)-Hstatic(:)))>0.25),
                type = 'mi';
                if(obj.Verbose>0), disp('Multi Modalities, Mutual information is used'); drawnow; end
            else
                type = 'sd';
                if(obj.Verbose>0), disp('Same Modalities, Pixel Distance is used'); drawnow; end
            end
        end
        
        function doRegistration(obj)
            % 1 pre registration
            obj.doPreRegistration;
            % 2 deformable registration
            obj.doDefRegistration;
        end
        
        function doPreRegistration(obj)
            if ~isempty(obj.PreReg)
                warning('doPreRegistration not calculated, TBI')
            end
        end
        
        function doDefRegistration(obj)
            if(obj.Verbose>0), disp('Start non-rigid b-spline grid registration'); drawnow; end
            
            % set registration options (used in bspline_registration_gradient)
            options.type = obj.Similarity;
            options.penaltypercentage = obj.Penalty;
            options.interpolation = obj.Interpolation;
            options.scaling = obj.Scaling;
            options.verbose = false;

            % get some parameters from the object
            O_trans = obj.BSGrid;
            Spacing = obj.SpacingInit;
            optim = obj.optimPars;
            
            if(obj.Verbose>0), optim.Display='iter'; end
            
            % Enable forward instead of central gradient incase of error measure is pixel distance
            if(strcmpi(obj.Similarity,'sd')), options.centralgrad=false; end 
                                   
            % at least one iteration, in first iteration no refinement
            nIters = obj.nRef + 1; 
            
            for iIter = 1:nIters
                
                % Refine the b-spline grid
                if iIter>1 % no refinement in first iteration
                    [O_trans,Spacing] = refine_grid(O_trans,Spacing,size(obj.Imn));
                    if(obj.Verbose>0), disp('Grid refinement'); drawnow; end
                end
                
                % display
                if(obj.Verbose>0), disp(['Current Grid size: ',num2str(size(O_trans)),' SpacingInit: ',num2str(Spacing)]); drawnow; end
                
                % Make smooth images for fast registration without local minimums
                % here because we use the grid size for calculation of
                % smoothing params
                [ISmoving,ISstatic] = obj.smoothImages(obj.Imn, obj.Isn, O_trans);
                
                % Uncomment following line to repeat an error in DJK code. 
                % Smoothing kernel in first iteration is calculated based 
                % on wrong BSGrid size O_trans(:)
                if iIter==1, [ISmoving,ISstatic] = obj.smoothImages(obj.Imn,obj.Isn,O_trans(:)); end
                
                % calc scale
                resize_per = 2^(nIters-iIter-1); % on last level it is .5, but it is handled below
                
                % no smoothing, no resizing in last iteration
                if iIter == nIters 
                    ISmoving = obj.Imn; 
                    ISstatic = obj.Isn; 
                    resize_per = 1; 
                    if (obj.Dims==3),optim.TolX = 0.05;  
                    else             optim.TolX = 0.03; end
                end

                % Resize everything, apply scale
                [ISmoving_small,ISstatic_small,MASKmovingsmall,MASKstaticsmall,...
                    SpacingInit_small,Points1_small,Points2_small,PStrength_small] ...
                    = obj.resizeAll(resize_per,obj.Dims==3,Spacing,ISmoving,ISstatic,obj.MaskMoving,obj.MaskStatic,...
                    obj.Points1,obj.Points2,obj.PStrength);

                % Reshape BSGrid from a matrix to a vector.
                sizes = size(O_trans); O_trans = O_trans(:);
                
                options
                
                % THE CORE PART
                O_trans = resize_per * fminlbfgs(...
                    @(x)bspline_registration_gradient(x,sizes,SpacingInit_small,ISmoving_small,ISstatic_small,...
                    options,MASKmovingsmall,MASKstaticsmall,Points1_small,Points2_small,PStrength_small),O_trans/resize_per,optim);
                
                % back to old size of otrans
                O_trans=reshape(O_trans,sizes);
            end
            
            % save results
            obj.BSGrid = O_trans;
            obj.SpacingFin = Spacing;
            [obj.Imt,obj.B]=bspline_transform(O_trans,obj.Im,Spacing,3);
        end
    end
    
    methods (Static)
        
        function [ISmoving,ISstatic] = smoothImages(Imoving,Istatic,BSGrid)
            try
            if size(BSGrid,3)==3 % 3d
                Hsize=ceil(0.1667*(size(Istatic,1)/size(BSGrid,1)+size(Istatic,2)/size(BSGrid,2)+size(Istatic,3)/size(BSGrid,3)));
                ISmoving=imgaussian(Imoving,Hsize/5,[Hsize Hsize Hsize]);
                ISstatic=imgaussian(Istatic,Hsize/5,[Hsize Hsize Hsize]);
            else % 2d
                Hsize=ceil(0.25*(size(Imoving,1)/size(BSGrid,1)+size(Istatic,2)/size(BSGrid,2)));
                ISmoving=imfilter(Imoving,fspecial('gaussian',[Hsize Hsize],Hsize/5));
                ISstatic=imfilter(Istatic,fspecial('gaussian',[Hsize Hsize],Hsize/5));
            end
                    catch
            disp('a')
        end
        end

        function [ISmoving_small,ISstatic_small,MASKmovingsmall,MASKstaticsmall,...
                SpacingInit_small,Points1_small,Points2_small,PStrength_small] ...
                = resizeAll(resize_per, IS3D, SpacingInit, ISmoving, ISstatic,...
                MASKmoving, MASKstatic, Points1, Points2, PStrength)

            if(IS3D)
                if(~isempty(MASKmoving)), MASKmovingsmall=imresize3d(MASKmoving,1/resize_per);  else MASKmovingsmall=[]; end
                if(~isempty(MASKstatic)), MASKstaticsmall=imresize3d(MASKstatic,1/resize_per);  else MASKstaticsmall=[]; end
            else
                if(~isempty(MASKmoving)), MASKmovingsmall=imresize(MASKmoving,1/resize_per);  else MASKmovingsmall=[]; end
                if(~isempty(MASKstatic)), MASKstaticsmall=imresize(MASKstatic,1/resize_per);  else MASKstaticsmall=[]; end
            end
            if(IS3D)
                ISmoving_small=imresize3d(ISmoving,1/resize_per,[],'linear');
                ISstatic_small=imresize3d(ISstatic,1/resize_per,[],'linear');
            else
                ISmoving_small=imresize(ISmoving,1/resize_per);
                ISstatic_small=imresize(ISstatic,1/resize_per);
            end
            SpacingInit_small=SpacingInit/resize_per;
            Points1_small=Points1/resize_per;
            Points2_small=Points2/resize_per;
            PStrength_small=PStrength;
        end
        
        BSGrid=makeInitGridKW(SpacingInit,sizeI,Grid,M);
        
        [DF_forw,DF_back,regoptions] = emptyDF(MRData);
        [DF_forw,DF_back,regoptions] = groundTruthDF(MRData);
        [DF_forw,DF_back,regoptions] = register2DconsBspline_DJK(MRData); % cons - consecutive frames
        [DF_forw,DF_back,regoptions] = register3DconsBspline_DJK(MRData);
        [DF_forw,DF_back,regoptions] = register3DconsBspline_DJK_p9(MRData);
        [DF_forw,DF_back,regoptions] = register3DconsBspline_DJK_p0(MRData);
        [DF_forw,DF_back,regoptions] = register2DconsDemon_mat(MRData);
        [DF_forw,DF_back,regoptions] = register3DconsDemon_mat(MRData);
        [DF_forw,DF_back,regoptions] = register2DconsNPar_fair(MRData);
        [DF_forw,DF_back,regoptions] = register3DconsNPar_fair(MRData);
    end
    
end

