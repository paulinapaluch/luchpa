classdef overlayVolume < handle
    %OVERLAYVOLUME displays a 3D volume in slices with optional overlay.
    %
    % Usage: 
    % - OVERLAYVOLUME(VOL1, VOL2); displays a 3D datasets VOL1, and an
    %   overlay dataset VOL2, with default display settings.
    % - OVERLAYVOLUME(VOL1); displays one 3D dataset VOL1
    % - OVERLAYVOLUME(VOL1,VOL2,optionalparameters); displays 3D datasets
    %   VOL1 and VOL2 with addional user specified display settings.
    %   Settings should be provided as parameter name - value pairs.
    % - After initialization, many settings can be changed using the
    %   setPROPERTY functions, see below.
    % - showColorBar shows the colorbars, see example below.
    %
    % Optional parameters:
    % - backRange:   display range of background data as [lower, upper]
    %                default: [lowest value in data, highest value]
    % - backMap:     colormap of the background as Nx3 matrix
    %                default: gray(256)
    % - overRange:   display range of overlay data as [lower, upper]
    %                default: [lowest value in data, highest value]
    % - overMap:     colormap of the overlay as Nx3 matrix
    %                default: hot(256)
    % - alpha:       transparency of the overlay as scalar between 0 and 1
    %                default: 0.4
    % - maskRange:   range of values in the overlay that will not be
    %                displayed as [lower, upper]
    %                default: []
    % - aspectRatio: aspect ratio of the three dimensions as [x,y,z]
    %                default: [1 1 1]
    %
    % Available setPROPERTY functions:
    % - setBackVolume:  set the background volume, should be the same size.
    % - setBackRange:   set the background display range.
    % - setBackMap:     set the background colormap
    % - setOverVolume:  set the overlay volume
    % - setOverRange:   set the overlay display range
    % - setOverMap:     set the overlay colormap
    % - setAlpha:       set the overlay transparency
    % - setMaskRange:   set the overlay mask range
    % - setAspectRatio: set the aspect ratio of the volumes
    % 
    % Examples:
    % load('mri'); VOL1 = double(squeeze(D)); % load matlab sample data
    % VOL2 = (VOL1>20).*rand(size(VOL1));     % create a random overlay
    % OVERLAYVOLUME(VOL1,VOL2,'alpha',0.2);   % show volumes, alpha=0.2
    % OVERLAYVOLUME(VOL1,VOL2,'backMap',bone(256),'overMap',hot(64));
    % OVERLAYVOLUME(VOL1,[],'aspectRatio',[1 1 5]);
    % OV = OVERLAYVOLUME(VOL1,VOL2);          % start with default settings
    % OV.showColorBar;                        % show the colorbars.
    % OV.setOverMap(jet(256));                % set the overlay color map
    % OV.setAspectRatio([1 1 5]);             % set the aspect ratio
    % OV.setOverVolume([]);                   % remove the overlay volume
    % 
    % Acknowledgement:
    % - "ct3"        by "tripp",      FileExchange ID: #32173
    % - "OverlayImg" by "Jochen Rau", FileExchange ID: #26790
    %
    % J.A. Disselhorst, December 2012
    % Werner Siemens Imaging Center, http://www.preclinicalimaging.org/
    % University of Tuebingen, Germany.
    
    properties                                                  % These properties are public.
        aspectRatio = [];                                       % data aspect ratio.
        backVol     = [];                                       % Background volume
        backMap     = [];                                       % Color map for the background 
        backRange   = [];                                       % background image range [min, max]
        overVol     = [];                                       % Overlay volume
        overMap     = [];                                       % Color map for the overlay
        overRange   = [];                                       % Overlay image range [min, max]
        maskRange   = [];                                       % Overlay will not be shown for values in the maskRange [lower, upper]
        alpha       = [];                                       % Transparency value [0<=alpha<=1]
    end 
    properties (SetAccess = private, Hidden = true)             % These properties are private.
        volumeSize   = [];                                      % size of the volume
        currentPoint = [];                                      % current point shown
        currentTime  = [];
        figsHandles  = [];                                      % handles to the figures.
        imgsHandles  = [];                                      % handles to the images
        lineHandles  = [];                                      % handles to the lines
        cursHandles  = [];                                      % handles to the cursor tool tips.
        colorBarFig  = [];                                      % handle to the optional colorbar figure.
    end
    methods(Static)
        function range = getRange(volume)                       % Provides display range for a volume
            volume(isnan(volume) | isinf(volume)) = [];         % Remove the Inf's and NaN's
            range = [min(volume(:)), max(volume(:))];           % Set the range to minimum to maximum value.
            if diff(range)==0                                   % When the numbers are equal
                range(2) = range(2)*1.01;                       % Add one percent to the upper limit.
            end
        end
        function figureScroll(fig,evnt,obj)                     % When the mousewheel is scrolled with one of the figures selected.
            CP = obj.currentPoint;                              % The current point
            VS = obj.volumeSize;                                % The size of the volume.
            if fig==obj.figsHandles(1)                          % For figure 1.
                temp = CP(1);                                   % The x coordinate of the current position.
                CP(1) = CP(1)+evnt.VerticalScrollCount;         % Add the scroll count (this number can also be negative)
                CP(1) = min([VS(1), max([1, CP(1)])]);          % The new position should be in correct range (>0 and <image size).
                obj.currentPoint = CP;                          % Set the new position.
                if temp~=CP(1)                                  % When the position has changed
                    updateImages(obj,fig);                      % Update the images.
                end
            elseif fig==obj.figsHandles(2)                      % For figure 2.
                temp = CP(2);                                   % y coordinate.
                CP(2) = CP(2)+evnt.VerticalScrollCount;         % Add the scroll count (this number can also be negative)
                CP(2) = min([VS(2), max([1, CP(2)])]);          % The new position should be in correct range (>0 and <image size).
                obj.currentPoint = CP;                          % Set the new position.
                if temp~=CP(2)                                  % When the position has changed
                    updateImages(obj,fig);                      % Update the images.
                end
            else                                                % For figure 3.
                temp = CP(3);                                   % z coordinate.
                CP(3) = CP(3)+evnt.VerticalScrollCount;         % Add the scroll count (this number can also be negative)
                CP(3) = min([VS(3), max([1, CP(3)])]);          % The new position should be in correct range (>0 and <image size).
                obj.currentPoint = CP;                          % Set the new position.
                if temp~=CP(3)                                  % When the position has changed
                    updateImages(obj,fig);                      % Update the images.
                end
            end
        end
        function figureKey(~,evnt,obj)                          % When the keyboard is used in one of the figures.
            switch evnt.Key
                case {'rightarrow','uparrow'}                   % right or up arrow
                    obj.currentTime = mod(obj.currentTime,obj.volumeSize(4))+1;
                case {'leftarrow','downarrow'}                  % left or down arrow 
                    obj.currentTime = mod(obj.currentTime-2,obj.volumeSize(4))+1;
            end
            updateImages(obj);     % Update the images of the all figures.
        end
        function figureClick(fig,~,obj)                         % When the mouse is clicked in one of the figures.   
            CP = obj.currentPoint;                              % The current coordinates.
            VS = obj.volumeSize;                                % The size of the volume.
            p = get(findall(fig,'tag','IMG'),'CurrentPoint');   % Get the currentpoint in the correct image. 
            if fig==obj.figsHandles(1)                          % In figure 1.
                CP(3) = max([1 min([VS(3), round(p(1,2))])]);   % calculate the new positions
                CP(2) = max([1 min([VS(2), round(p(1,1))])]);   % calculate the new positions
            elseif fig==obj.figsHandles(2)                      % In figure 2
                CP(3) = max([1 min([VS(3), round(p(1,2))])]);   % calculate the new positions
                CP(1) = max([1 min([VS(1), round(p(1,1))])]);   % calculate the new positions
            else                                                % In figure 3
                CP(1) = max([1 min([VS(1), round(p(1,2))])]);   % calculate the new positions
                CP(2) = max([1 min([VS(2), round(p(1,1))])]);   % calculate the new positions
            end
            obj.currentPoint = CP;                              % update the position in the class.
            updateImages(obj,setdiff(obj.figsHandles,fig));     % Update the images of the other figures.
        end
        function IMG = provideImage(fig,obj)                    % Create an image from the volumes, using current display settings.
            CP = obj.currentPoint;                              % The current coordinates.
            CT = obj.currentTime;
            if fig==obj.figsHandles(1)                          % Figure 1.
                IMG1 = permute(obj.backVol(CP(1),:,:,CT),[3 2 1]); % Get the image of the background.
            elseif fig==obj.figsHandles(2)                      % Figure 2.
                IMG1 = permute(obj.backVol(:,CP(2),:,CT),[3 1 2]); % Get the image of the background.
            else                                                % Figure 3.
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
                if fig==obj.figsHandles(1)                      % If figure 1.
                    IMG2 = permute(obj.overVol(CP(1),:,:,CT),...   % Get the image from the overlay volume
                        [3 2 1]);                               % ...
                elseif fig==obj.figsHandles(2)                  % If figure 2.
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
            p.addParamValue('backRange',overlayVolume.getRange(obj.backVol),@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('overRange',overlayVolume.getRange(obj.overVol),@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('backMap',gray(256),@(x)ismatrix(x)&size(x,2)==3)
            p.addParamValue('overMap',hot(256),@(x)ismatrix(x)&size(x,2)==3)
            p.addParamValue('maskRange',[],@(x)length(x)==2&x(1)<x(2));
            p.addParamValue('alpha',0.4,@(x)x>=0&x<=1);
            p.addParamValue('aspectRatio',[1 1 1],@(x)length(x)==3);
            p.addParamValue('colorBar',1,@isscalar)
            p.parse(input{:});                                  % Parse the input, given parameters set above. If a parameter is not provided, use the default.
            obj.backRange   = p.Results.backRange;              % Set all the parameters.
            obj.overRange   = p.Results.overRange;              % ...
            obj.maskRange   = p.Results.maskRange;              % ...
            obj.alpha       = p.Results.alpha;                  % ...
            obj.backMap     = p.Results.backMap;                % ...
            obj.overMap     = p.Results.overMap;                % ...
            obj.aspectRatio = p.Results.aspectRatio;            % ...
            if p.Results.colorBar, showColorBar(obj); end       % When the user wants a colorbar, show it.
        end
    end
    methods
    	function obj = overlayVolume(backVol,overVol,varargin)  % Initial start of this function, show the images, provide the class handle.
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
                overlayVolume.parseInputs({},obj);              % Set default parameters for the display settings
            else                                                % Otherwise...
                overlayVolume.parseInputs(varargin,obj);        % parse the additional input.
            end
            
            obj.figsHandles(1) = figure;                        % Make a figure, and save its handle.
            obj.imgsHandles(1) = imshow(zeros(vS(3),vS(2)));    % Initialize the image.
            set(gca,'position',[0 0 1 1],'DataAspectRatio',...  % Image should be full size, The correct
                [obj.aspectRatio(3) obj.aspectRatio(2) 1],...   % ... data aspect ratio, and 
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(1) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            set(obj.figsHandles(1),'units','normalized','outerposition',[0 0 .5 .5]); %KW
            obj.cursHandles=datacursormode(obj.figsHandles(1)); % Get the data cursor mode handle
            
            obj.figsHandles(2) = figure;
            obj.imgsHandles(2) = imshow(zeros(vS(3),vS(1)));    % Initialize image
            set(gca,'position',[0 0 1 1],'DataAspectRatio',...  % Image should be full size, The correct
                [obj.aspectRatio(3) obj.aspectRatio(1) 1],...   % ... data aspect ratio, and 
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(2) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            set(obj.figsHandles(2),'units','normalized','outerposition',[.5 .5 .5 .5]); %KW
            obj.cursHandles(2)=datacursormode(obj.figsHandles(2));% Get the data cursor mode handle
            
            obj.figsHandles(3) = figure;
            obj.imgsHandles(3) = imshow(zeros(vS(1),vS(2)));    % Initialize image
            set(gca,'position',[0 0 1 1],'DataAspectRatio',...  % Image should be full size, The correct ...
                [obj.aspectRatio(1) obj.aspectRatio(2) 1],...   % ... data aspect ratio, and 
                'Tag', 'IMG');                                  % ... can be identified by a the tag 'IMG'
            hold on                                             % Hold, to initialize lines
            obj.lineHandles(3) = ...                            % The handle for the line
                plot(0,1,'Color',[0.8,0.8,0.8]);                % The correct coordinates are not necessary at this stage.
            hold off
            set(obj.figsHandles(3),'units','normalized','outerposition',[0 .5 .5 .5]); %KW
            obj.cursHandles(3)=datacursormode(obj.figsHandles(3));% Get the data cursor mode handle
           
            set(obj.figsHandles, 'WindowScrollWheelFcn',...     % For each figure, ....
                {@overlayVolume.figureScroll,obj},...           % set the scroll wheel 
                'WindowButtonDownFcn',...                       % and mouse click functions
                {@overlayVolume.figureClick,obj},...
                'WindowKeyPressFcn',...
                {@overlayVolume.figureKey,obj});                % ...
            set(obj.cursHandles, 'UpdateFcn', @obj.dataTip);    % Set the data cursor mode to a custom function.
            updateImages(obj);                                  % Update the images. 
        end
        function tiptext = dataTip(obj, ~, event)               % Function to show something meaningful when the data cursor is used.
            CP = obj.currentPoint;                              % Get the current coordinates.
            Pos = event.Position;                               % Get the position of the click.
            fig = get(event.Target,'Parent');                   % Get where the click occured.
            while ~strcmp('figure', get(fig,'type'))            % Get its parent until the we have the handle to the figure in which was clicked.
                fig = get(fig,'Parent');                        % ...
            end  
            if fig==obj.figsHandles(1)                          % It was in figure 1.
                X=CP(1); Y=Pos(1); Z=Pos(2);                    % Get the 'real' position.
            elseif fig==obj.figsHandles(2)                      % Figure 2.
                X=Pos(1); Y=CP(2); Z=Pos(2);                    % Get the 'real' position.
            else                                                % Figure 3.
                X=Pos(2); Y=Pos(1); Z=CP(3);                    % Get the 'real' position.
            end
            back = obj.backVol(X,Y,Z);                          % The value of the background volume at this position.
            tiptext = sprintf('X: %1.0f, Y: %1.0f, Z: = %1.0f\nBackground: %2.2f',X,Y,Z,back); % Show some text.
            if ~isempty(obj.overVol)                            % If the overlay exists, 
                over = obj.overVol(X,Y,Z);                      % get the value of the overlay at this position. 
                tiptext = sprintf('%s\nOverlay: %2.2f',tiptext,over); % and add it to the tiptext.
            end  
        end
        function updateImages(obj,figs)                         % Function to update the images
            if nargin==1                                        % If no specific figure is requested, 
                figs = obj.figsHandles;                         % update them all.
            end
            for loop = 1:length(figs)                           % Loop through the figure handles that should be updated.
                IMG=overlayVolume.provideImage(figs(loop),obj); % Get the right image,
                try set(obj.imgsHandles(figs(loop) == ...       % And try to show it
                        obj.figsHandles),'CData',IMG); end      % ... (The 'try' is there in case a window was closed by the user)
            end
            updateMarkers(obj);                                 % Set the line markers correctly.
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
                obj.overRange = overlayVolume.getRange(Value);  % Get the defaults.
                showColorBar(obj,'UpdateIfExist');              % If there is a colorbar, update it.
            end
            updateImages(obj);                                  % Update the images.
        end
        function setBackMap(obj, Value)                         % Change the colormap of the background
            try iptcheckmap(Value)                              % Check the validity of the provided colormap
                obj.backMap = Value;                            % Set the colormap
                updateImages(obj);                              % Update the images.
                showColorBar(obj,'UpdateIfExist');              % If it exists, update the colorbar.
            catch                                     %#ok<CTCH>  We do not need the error message.
                warning('Colormap should be X*3');              % It did not work, throw error.
            end
        end
        function setOverMap(obj, Value)                         % Change the colormap of the overlay
            try iptcheckmap(Value)                              % Check the validity of the provided colormap
                obj.overMap = Value;                            % Set the colormap
                updateImages(obj);                              % Update the images.
                showColorBar(obj,'UpdateIfExist');              % If it exists, update the colorbar.
            catch                                     %#ok<CTCH>  We do not need the error message.
                warning('Colormap should be X*3');              % It did not work, trow error.
            end
        end
        function setBackRange(obj, Value)                       % Set the background color range
            if length(Value) == 2                               % It should be two numbers.
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    obj.backRange = Value;                      % Set the values.
                    updateImages(obj);                          % Update the images.
                    showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                end
            end
        end
        function setOverRange(obj, Value)                       % Set the overlay color range
            if length(Value) == 2                               % It should be two numbers.
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    obj.overRange = Value;                      % Set the values.
                    updateImages(obj);                          % Update the images.
                    showColorBar(obj,'UpdateIfExist');          % Update the colorbar if it exists.
                end
            end
        end
        function setMaskRange(obj, Value)                       % Set range that is invisible in the overlay
            if length(Value) == 2                               % It should be two numbers.
                if Value(1)<Value(2)                            % The first should be smaller than the second
                    obj.maskRange = Value;                      % Set the values.
                    updateImages(obj);                          % Update the images.
                end
            end
        end
        function setAlpha(obj, Value)                           % Set the transparency of the overlay
            if length(Value)==1                                 % It should be one value
                if Value>=0 && Value<=1                         % It should be between zero and one
                    obj.alpha = Value;                          % Set the value.
                    updateImages(obj);                          % Update the images.
                end
            end
        end
        function setAspectRatio(obj, Value)                     % Set the aspect ratio
            if length(Value)==2,Value = [1 Values]; end         % In this case it is probably a 2D image, make it three values.
            if length(Value)==3                                 % It should be three values.
                obj.aspectRatio = Value;                        % Set the aspect ratio in the object.
                set(findall(obj.figsHandles(1),...              % Find all objects in figure 1 ...
                    'type','axes'),'position',[0 0 1 1],...     % that are axes, ...
                    'DataAspectRatio',[Value(3) Value(2) 1]);   % and set the aspect ratio.
                set(findall(obj.figsHandles(2),...              % Find all objects in figure 2
                    'type','axes'),'position',[0 0 1 1],...     % that are axes, 
                    'DataAspectRatio',[Value(3) Value(1) 1]);   % and set the aspect ratio.
                set(findall(obj.figsHandles(3),...              % Find all objects in figure 3
                    'type','axes'),'position',[0 0 1 1],...     % that are axes,
                    'DataAspectRatio',[Value(1) Value(2) 1]);   % and set the aspect ratio.
            end
        end
        
        function showColorBar(obj,varargin)                     % Show an additional figure with the colorbars.
            X = 1/256;                                          % constant for one pixel in the colorbar;
            if isempty(obj.overVol)                             % When there is no overlay volume, ...
                N = 25;                                         % The full width of the bar is for the background volume.
                over = [];                                      % No overlay bar.
                line = [];                                      % And no line to separate the two.
            else                                                % If there is an overlay....
                N = 12;                                         % this is the width of each bar.
                over = ceil((1:-X:X)*size(obj.overMap,1))';     % Make a 256 pixel high image.
                over = repmat(over,[1,N]);                      % Repeat for the width of the bar.
                over = reshape(obj.overMap(over,:),256,N,3);    % Make it the correct color (overlay)
                line = zeros(256,1,3);                          % The separation line is black.
            end
            back = ceil((1:-X:X)*size(obj.backMap,1))';         % Make the bar for the background, 256 pixel high.
            back = repmat(back,[1,N]);                          % repeat for the width of the bar
            back = reshape(obj.backMap(back,:),256,N,3);        % Make it the correct color
            linelr = zeros(256,1,3); linebt = zeros(1,27,3);    % The lines left/right and bottom/top
            colors = [linelr,back,line,over,linelr];            % The colorbar + vertical lines.
            colors = [linebt;colors;linebt];                    % Add horizontal lines.
            if ~isempty(obj.colorBarFig) && ...                 % Does the figure already exist?
                    ishandle(obj.colorBarFig)                   % ...
                figure(obj.colorBarFig)                         % Make it active. 
            else                                                % If there is no window yet 
                if nargin>1                                     % Check if this function call was from the user (nargin==1) or from a setPROPERTY function (nargin~=1) 
                    return                                      % If it was from the setPROPERTY and there is no window, don't make one.
                end                                             % Otherwise,
                obj.colorBarFig = figure('Menubar','none','units','normalized','outerposition',[.5 0 .5 .5]);     % ... make one KW
            end
            imshow(colors);                                     % Show the colorbar(s)
            hold on;                                            % Start drawing lines and writing text.
            plot([1 27 NaN 1 27 NaN 1 27],[129.5 129.5 NaN 64.25 64.25 NaN 192.75 192.75],'k'); % The horizontal lines.
            br = obj.backRange;                                 % The background range.
            text(1,2,sprintf('%2.3f  ',br(2)),...               % Display some background range values.
                'HorizontalAlignment','right');                 % ...
            text(1,257,sprintf('%2.3f  ',br(1)),...             % ...
                'HorizontalAlignment','right');                 % ...
            text(1,129.5,sprintf('%2.3f  ',mean(br)),...        % ...
                'HorizontalAlignment','right');                 % ...
            text(1,64.25,sprintf('%2.3f  ',br(2)-diff(br)/4),...% ...
                'HorizontalAlignment','right');                 % ...
            text(1,192.75,sprintf('%2.3f  ',br(1)+diff(br)/4),...%...
                'HorizontalAlignment','right');                 % ...
            if ~isempty(obj.overVol)                            % When a overlay volume is available
                or = obj.overRange;                             % use its range
                text(27,2,sprintf('  %2.3f',or(2)));            % and display some values.
                text(27,257,sprintf('  %2.3f',or(1)));          % ...
                text(27,129.5,sprintf('  %2.3f',mean(or)));     % ...
                text(27,64.25,sprintf('  %2.3f',...             % ...
                    or(2)-diff(or)/4));                         % ...
                text(27,192.75,sprintf('  %2.3f',...            % ...
                    or(1)+diff(or)/4));                         % ...
            end
            hold off                                            % End writing lines and text.
        end
    end
end