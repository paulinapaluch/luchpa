classdef MRViewer3Dt < handle
    %MRViewer3Dt
    %
    % Konrad Werys, Feb 2016
    % konradwerys@gmail.com
    % <mrkonrad.github.io>
    %
    % Acknowledgement:
    % - "overlayVolume" by "J.A. Disselhorst", FileExchange ID: #39460
    % - "ct3"           by "tripp",            FileExchange ID: #32173
    % - "OverlayImg"    by "Jochen Rau",       FileExchange ID: #26790
    
    properties                                                  % These properties are public
        aspectRatio = [];                                       % data aspect ratio
        backVol     = [];                                       % Background volume
        backMap     = [];                                       % Color map for the background
        backRange   = [];                                       % background image range [min, max]
        overVol     = [];                                       % Overlay volume
        overMap     = [];                                       % Color map for the overlay
        overRange   = [];                                       % Overlay image range [min, max]
        maskRange   = [];                                       % Overlay will not be shown for values in the maskRange [lower, upper]
        alpha       = [];                                       % Transparency value [0<=alpha<=1]
    end
    properties (SetAccess = protected, Hidden = true)
        volumeSize   = [];                                      % size of the volume
    end
    properties (SetAccess = private, Hidden = true)             % These properties are private.
        currentPoint = [];                                      % current point shown
        currentTime  = [];
        figHandle    = [];
        axesHandles  = [];                                      % handles to the axes
        imgsHandles  = [];                                      % handles to the images
        lineHandles  = [];                                      % handles to the lines
        cursHandles  = [];                                      % handles to the cursor tool tips
        textHandles  = [];
        colorBarFig  = [];                                      % handle to the optional colorbar figure
        
    end
    
    methods(Static)
        function range = getRange(volume)                       % Provides display range for a volume
            volume(isnan(volume) | isinf(volume)) = [];         % Remove the Inf's and NaN's
            range = [min(volume(:)), max(volume(:))];           % Set the range to minimum to maximum value.
            if diff(range)==0                                   % When the numbers are equal
                range(2) = range(2)*1.01;                       % Add one percent to the upper limit.
            end
        end
        
        function figureKey(~,evnt,obj)                          % When the keyboard is used in one of the figures.
            switch evnt.Key
                case {'rightarrow'}                             % right - next time
                    obj.currentTime = mod(obj.currentTime,obj.volumeSize(4))+1;
                case {'leftarrow'}                              % left - prev time
                    obj.currentTime = mod(obj.currentTime-2,obj.volumeSize(4))+1;
                case {'downarrow'}                              % up - up z
                    obj.currentPoint(3) = mod(obj.currentPoint(3),obj.volumeSize(3))+1;
                case {'uparrow'}                                % down - down z
                    obj.currentPoint(3) = mod(obj.currentPoint(3)-2,obj.volumeSize(3))+1;
            end
            set(obj.textHandles,'string',sprintf('%d/%d',obj.currentTime,obj.volumeSize(4)))
            updateImages(obj);     % Update the images of the all figures.
        end
        
        function figureClick(~,~,obj)% When the keyboard is used in one of the figures.
            ax = gca;
            CP = obj.currentPoint;                              % The current coordinates.
            VS = obj.volumeSize;                                % The size of the volume.
            p = get(ax, 'CurrentPoint');
            if ax==obj.axesHandles(1)                           % In figure 1.
                CP(3) = max([1 min([VS(3), round(p(1,2))])]);   % calculate the new positions
                CP(2) = max([1 min([VS(2), round(p(1,1))])]);   % calculate the new positions
            elseif ax==obj.axesHandles(2)                       % In figure 2
                CP(3) = max([1 min([VS(3), round(p(1,2))])]);   % calculate the new positions
                CP(1) = max([1 min([VS(1), round(p(1,1))])]);   % calculate the new positions
            else                                                % In figure 3
                CP(1) = max([1 min([VS(1), round(p(1,2))])]);   % calculate the new positions
                CP(2) = max([1 min([VS(2), round(p(1,1))])]);   % calculate the new positions
            end
            obj.currentPoint = CP;                              % update the position in the class.
            updateImages(obj,setdiff(obj.axesHandles,ax));     % Update the images of the other figures.
        end
        
        function IMG = provideImage(ax,obj)                    % Create an image from the volumes, using current display settings.
            CP = obj.currentPoint;                              % The current coordinates.
            CT = obj.currentTime;
            if ax==obj.axesHandles(1)                          % Axes 1.
                IMG1 = permute(obj.backVol(CP(1),:,:,CT),[3 2 1]); % Get the image of the background.
            elseif ax==obj.axesHandles(2)                      % Axes 2.
                IMG1 = permute(obj.backVol(:,CP(2),:,CT),[3 1 2]); % Get the image of the background.
            else                                                % Axes 3.
                IMG1 = obj.backVol(:,:,CP(3),CT);                  % Get the image of the background.
            end
            
            IMG1 = IMG1-obj.backRange(1);                       % Subtract the lower display limit.
            IMG1 = IMG1./(obj.backRange(2)-obj.backRange(1));   % Calculate image including the upper display limit.
            IMG1(IMG1<0) = 0;                                   % Everything below the lower limit is set to the lower limit.
            IMG1(IMG1>1) = 1;                                   % Everything above the upper limit is set to the upper limit.
            IMG1 = round(IMG1*(size(obj.backMap,1)-1))+1;       % Multiply by the size of the colormap, and make it integers to get a color index.
            IMG1(isnan(IMG1)) = 1;                              % remove NaNs -> these will be shown as the lower limit.
            IMG1 = reshape(obj.backMap(IMG1,:),...              % Get the correct color from the colormap using the index calculated above.
                [size(IMG1,1),size(IMG1,2),3]);                 % ...
            
            if ~isempty(obj.overVol);                           % Do this only when there is actually an overlay image.
                if ax==obj.axesHandles(1)                      % If figure 1.
                    IMG2 = permute(obj.overVol(CP(1),:,:,CT),...   % Get the image from the overlay volume
                        [3 2 1]);                               % ...
                elseif ax==obj.axesHandles(2)                  % If figure 2.
                    IMG2 = permute(obj.overVol(:,CP(2),:,CT),...   % Get the image from the overlay volume
                        [3 1 2]);                               % ...
                else                                            % If figure 3.
                    IMG2 = obj.overVol(:,:,CP(3),CT);              % Get the image from the overlay volume
                end
                if ~isempty(obj.maskRange)                      % Do this only when a mask range is available.
                    mask = ones(size(IMG2));                    % Set mask to one (everything is shown).
                    mask(IMG2>=obj.maskRange(1) & ...           % Set the mask to zero (not shown) for values within the mask range.
                        IMG2<=obj.maskRange(2)) = 0;           % ...
                    mask = repmat(mask,[1 1 3]);                % Repeat for Red, Green and Blue.
                else                                            % Otherwise, if no mask range is available
                    mask = repmat(ones(size(IMG2)),[1 1 3]);    % Set mask to one (everything is shown) for R,G, and B.
                end
                IMG2=IMG2-obj.overRange(1);                     % Subtract the lower display limit.
                IMG2=IMG2./(obj.overRange(2)-obj.overRange(1)); % Use the upper display limit.
                IMG2(IMG2<0) = 0;                               % Everything below the lower limit is set to the lower limit.
                IMG2(IMG2>1) = 1;                               % Everything above the upper limit is set to the upper limit.
                IMG2 = round(IMG2*(size(obj.overMap,1)-1))+1;   % Multiply by the size of the colormap, and make it integers to get a color index.
                mask(isnan(IMG2)) = 0;                          % NaNs in the overlay will not be shown.
                IMG2(isnan(IMG2)) = 1;                          % remove NaNs
                IMG2 = reshape(obj.overMap(IMG2,:),...          % Get the correct color from the colormap using the index calculated above.
                    [size(IMG2,1),size(IMG2,2),3]);             % ...
                
                IMG = IMG1*(1-obj.alpha)+mask.*IMG2*obj.alpha;  % Combine background and overlay, using alpha and mask.
            else
                IMG = IMG1;                                     % Simple case, only a background is available.
            end
        end
        
        function parseInputs(input,obj)                         % Parse the inputs given by the user.
            p = inputParser;                                    % Matlabs input parser, see "help inputparser"
            if ismethod(p,'addParameter'),myaddParFun = @p.addParameter; % for new Matlab versions
            else myaddParFun = @p.addParamValue;end             % for old Matlab versions
            myaddParFun('backRange',MRViewer3Dt.getRange(obj.backVol),@(x)length(x)==2&x(1)<x(2));
            myaddParFun('overRange',MRViewer3Dt.getRange(obj.overVol),@(x)length(x)==2&x(1)<x(2));
            myaddParFun('backMap',gray(256),@(x)ismatrix(x)&size(x,2)==3)
            myaddParFun('overMap',jet(256),@(x)ismatrix(x)&size(x,2)==3)
            myaddParFun('maskRange',[],@(x)length(x)==2&x(1)<x(2));
            myaddParFun('alpha',0.4,@(x)x>=0&x<=1);
            myaddParFun('aspectRatio',[1 1 1],@(x)length(x)==3);
            myaddParFun('colorBar',1,@isscalar)
            p.parse(input{:});                                  % Parse the input, given parameters set above. If a parameter is not provided, use the default.
            obj.backRange   = p.Results.backRange;              % Set all the parameters.
            obj.overRange   = p.Results.overRange;              % ...
            obj.maskRange   = p.Results.maskRange;              % ...
            obj.alpha       = p.Results.alpha;                  % ...
            obj.backMap     = p.Results.backMap;                % ...
            obj.overMap     = p.Results.overMap;                % ...
            obj.aspectRatio = p.Results.aspectRatio;            % ...
            %             if p.Results.colorBar, showColorBar(obj); end       % When the user wants a colorbar, show it.
        end
    end
    
    methods
        function obj = MRViewer3Dt(backVol,overVol,varargin)    % Initial start of this function, show the images, provide the class handle.
            if nargin==1, overVol = []; end                     % Only one input variable? -> overVol is empty.
            if isscalar(backVol)                                % If the provided input is not an image, but a scalar.
                error('Images should be 2- or 3-Dimensional');  % Error.
            end
            if ismatrix(backVol)                                % If an image (2D) is provided,
                backVol = permute(backVol,[3,1,2]);             % make it a volume (3D)
            end
            if ismatrix(overVol)==2                             % If an image (2D) is provided,
                overVol = permute(overVol,[3,1,2]);             % make it a volume (3D)
            end
            vS = size(backVol);                                 % The size of the volume.
            obj.currentPoint = round(vS/2);                     % Current point is in the center of the volume.
            if ~isempty(overVol)                                % The overlay volume may be empty,
                if ~all(vS == size(overVol))                    % Otherwise it should be the same size as the background.
                    error('Overlay must be the same size');     % Throw error if not.
                end
            end
            if length(vS)==3, vS(4)=1;end
            
            obj.volumeSize = vS;                                % Set the the volume size, this is from now on read only.
            obj.backVol = backVol;                              % Set the background volume
            obj.overVol = overVol;                              % Set the overlay volume.
            obj.currentTime = 1;
            
            if nargin <= 2                                      % If only the volume(s) are given,
                MRViewer3Dt.parseInputs({},obj);                % Set default parameters for the display settings
            else                                                % Otherwise...
                MRViewer3Dt.parseInputs(varargin,obj);          % parse the additional input.
            end
            
            obj.figHandle = figure;                             % Make a figure, and save its handle.
            set(obj.figHandle,'units','normalized',...
                'outerposition',[0 0 1 1]);                     % Fullscreen position of the figure
            obj.cursHandles=datacursormode(obj.figHandle);      % Get the data cursor mode handle
            
            obj.axesHandles(1) = axes;                          % Make an axis, and save its handle.
            set(obj.axesHandles(1),'position',[0 0 .5 .5],...   % Image should be full size, The correct
                'DataAspectRatio',...
                [obj.aspectRatio(3) obj.aspectRatio(2) 1],...   % ... data aspect ratio, and
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            obj.imgsHandles(1) = imshow(zeros(vS(3),vS(2)));    % Initialize the image.
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(1) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            obj.textHandles(1) = text(1,1,'text1');
            
            obj.axesHandles(2) = axes;
            set(obj.axesHandles(2),'position',[.5 .5 .5 .5],...
                'DataAspectRatio',...                           % Image should be full size, The correct
                [obj.aspectRatio(3) obj.aspectRatio(1) 1],...   % ... data aspect ratio, and
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            obj.imgsHandles(2) = imshow(zeros(vS(3),vS(1)));    % Initialize image
            set(obj.axesHandles(2),'view',[-90 90])
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(2) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            obj.textHandles(2) = text(vS(1),1,'text2');
            
            obj.axesHandles(3) = axes;
            set(obj.axesHandles(3),'position',[0 .5 .5 .5],...
                'DataAspectRatio',...                           % Image should be full size, The correct ...
                [obj.aspectRatio(1) obj.aspectRatio(2) 1],...   % ... data aspect ratio, and
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            obj.imgsHandles(3) = imshow(zeros(vS(1),vS(2)));    % Initialize image
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(3) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            obj.textHandles(3) = text(1,1,'text3');
            
            set(obj.textHandles,'VerticalAlignment','top','color','red')
            
            set(obj.figHandle,'WindowButtonDownFcn',...         % set kryboard control
                {@MRViewer3Dt.figureClick,obj});
            set(obj.figHandle,'WindowKeyPressFcn',...           % set kryboard control
                {@MRViewer3Dt.figureKey,obj});
            updateAxesPostion(obj,1);
            setAspectRatio(obj);
            updateImages(obj);                                  % Update the images.
        end
        
        function updateImages(obj,axIdx)                        % Function to update the images
            if nargin==1 || isempty(axIdx)                      % If no specific axes is requested,
                axIdx = obj.axesHandles;                        % update them all.
            end
            for loop = 1:length(axIdx)                          % Loop through the figure handles that should be updated.
                IMG=MRViewer3Dt.provideImage(axIdx(loop),obj);  % Get the right image,
                try set(obj.imgsHandles(axIdx(loop) == ...      % And try to show it
                        obj.axesHandles),'CData',IMG); end      % ... (The 'try' is there in case a window was closed by the user)
            end 
            updateMarkers(obj);                                 % Set the line markers correctly.
        end
        
        function updateAxesPostion(obj,flagfig)
            vS = size(obj.backVol);
            vSar = vS(1:3).*obj.aspectRatio;
            ss = get(0,'screensize');
            scale = [vSar(2)+vSar(3),vSar(1)+vSar(3),vSar(2)+vSar(3),vSar(1)+vSar(3)];
            set(obj.axesHandles(1),'position',[0  0 vSar(2) vSar(3)]./scale);
            set(obj.axesHandles(2),'position',[vSar(2)+1 vSar(3)+1 vSar(3) vSar(1)]./scale);
            set(obj.axesHandles(3),'position',[0  vSar(3)+1 vSar(2) vSar(1)]./scale);
            if exist('flagfig','var') && flagfig
                dd = [0 0 scale(3)*ss(4),scale(4)*ss(3)];dd = dd./max(dd);
                set(obj.figHandle,'outerposition',dd);
            end
        end
        
        function updateMarkers(obj)                             % Function to set the line markers.
            CP = obj.currentPoint;                              % The current coordinates
            vS = obj.volumeSize;                                % The size of the volume
            LL = vS/15; LL2 = LL-0.5;                           % Length of the helper lines depends on the size of the volume.
            try                                                 % Set the lines in figure 1.
                set(obj.lineHandles(1),'XData',[0.5 0.5+LL(2) NaN vS(2)-LL2(2) vS(2)+0.5 NaN CP(2) CP(2) NaN CP(2) CP(2)]);
                set(obj.lineHandles(1),'YData',[CP(3) CP(3) NaN CP(3) CP(3) NaN 0.5 0.5+LL(3) NaN vS(3)-LL2(3) vS(3)+0.5]);
            end
            try                                                 % Set the lines in figure 2.
                set(obj.lineHandles(2),'XData',[0.5 0.5+LL(1) NaN vS(1)-LL2(1) vS(1)+0.5 NaN CP(1) CP(1) NaN CP(1) CP(1)]);
                set(obj.lineHandles(2),'YData',[CP(3) CP(3) NaN CP(3) CP(3) NaN 0.5 0.5+LL(3) NaN vS(3)-LL2(3) vS(3)+0.5]);
            end
            try                                                 % Set the lines if figure 3.
                set(obj.lineHandles(3),'XData',[0.5 0.5+LL(2) NaN vS(2)-LL2(2) vS(2)+0.5 NaN CP(2) CP(2) NaN CP(2) CP(2)]);
                set(obj.lineHandles(3),'YData',[CP(1) CP(1) NaN CP(1) CP(1) NaN 0.5 0.5+LL(1) NaN vS(1)-LL2(1) vS(1)+0.5]);
            end
        end
        
        function setBackVolume(obj, Value)                      % Change the background volume
            if ~isequal(size(Value), size(obj.backVol))         % Size of the background data should match the old size.
                warning('Background image should have the same dimensions!');
            end;
            obj.backVol = Value;                                % Set the volume.
            updateAxesPostion(obj);
            updateImages(obj);                                  % Update the images.
        end
        
        function setOverVolume(obj, Value)                      % Change the overlay volume.
            if ~isempty(Value)                                  % Overlay may be empty.
                if ~isequal(size(Value), size(obj.backVol))     % If not, it should match the size of the background.
                    warning('Overlay image should have the same dimensions as the background!');
                end
            end
            obj.overVol = Value;                                % Set the overlay
            if isempty(obj.overRange)                           % If the overlay range was previously empty, ...
                obj.overRange = MRViewer3Dt.getRange(Value);  % Get the defaults.
                %showColorBar(obj,'UpdateIfExist');              % If there is a colorbar, update it.
            end
            updateImages(obj);                                  % Update the images.
        end
        
        function setAspectRatio(obj, Value)                     % Set the aspect ratio
            if exist('Value','var')
                if length(Value)==2
                    Value = [1 Values];
                end         % In this case it is probably a 2D image, make it three values.
                if length(Value)==3
                    obj.aspectRatio = Value;                        % Set the aspect ratio in the object.
                end
            else
                Value = obj.aspectRatio;
            end
            
            vS = size(obj.backVol);
            set(obj.axesHandles(1),...              % Find all objects in figure 1 ...
                'DataAspectRatio',[Value(3) Value(2) 1],...   % and set the aspect ratio.
                'Ylim',[1 vS(3)],...
                'XLim',[1 vS(2)]);
            
            set(obj.axesHandles(2),...              % Find all objects in figure 2
                'DataAspectRatio',[Value(3) Value(1) 1],...   % and set the aspect ratio.
                'Ylim',[1 vS(3)],...
                'XLim',[1 vS(1)]);
            set(obj.axesHandles(3),...              % Find all objects in figure 3
                'DataAspectRatio',[Value(1) Value(2) 1],...   % and set the aspect ratio.
                'Ylim',[1 vS(1)],...
                'XLim',[1 vS(2)]);
            updateAxesPostion(obj);
        end
        
        function setBackRange(obj, Value)                       % Set the background color range
            if length(Value) == 2                               % It should be two numbers.
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    obj.backRange = Value;                      % Set the values.
                    updateImages(obj);                          % Update the images.
                    %showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                end
            end
        end
        
        function setOverRange(obj, Value)                       % Set the overlay color range
            if length(Value) == 2                               % It should be two numbers.
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    obj.overRange = Value;                      % Set the values.
                    updateImages(obj);                          % Update the images.
                    %showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                end
            end
        end
    end
    
end

