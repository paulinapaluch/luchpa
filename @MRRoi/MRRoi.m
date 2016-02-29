classdef MRRoi < handle % matlab.mixin.SetGet
    %MRRoi stores cells with points positions
    %
    % Konrad Werys, Feb 2016
    % mrkonrad.github.io
    
    properties
        name  = 'ROI'
        color = [0 1 0]
        type = 'cpoly'; % 'point', 'cpoly'
        pointsMan
        pointsAut
        autMethod = '';
        
    end
    
    properties (SetAccess = private, Hidden = true)
        nSlices = 0;
        nTimes = 0;
    end
    
    methods
        function R = MRRoi(nSlices,nTimes,varargin)
            if nargin<2, error('Not enaugh input args');end
            if nargin>2, R.name = varargin{1};end
            if nargin>3, R.color = varargin{2};end
            if nargin>4, R.type = varargin{3};end
            if nargin>5, error('Too many input args');end

            R.nSlices = nSlices;
            R.nTimes = nTimes;
            
            R.pointsMan = cell(nSlices,nTimes);
            R.pointsAut = cell(nSlices,nTimes);
        end
        
        function set.name(R,val)
            if ~isa(val,'char')
                error('Name has to be char');
            end
            R.name = val;
        end
        
        function set.pointsMan(R,val)
            if ~isa(val,'cell')
                error('Points should be in a cell')
            end
            if ~isempty(R.pointsMan) && ~all(size(val)==size(R.pointsMan))
                error('Points has to be in cell with certain size: cell(nSlices,nTimes)')
            end
            R.pointsMan = val;
        end
        
        function set.pointsAut(R,val)
            if ~isa(val,'cell')
                error('Points should be in a cell')
            end
            if ~isempty(R.pointsAut) && ~all(size(val)==size(R.pointsAut))
                error('Points has to be in cell with certain size: cell(nSlices,nTimes)')
            end
            R.pointsAut = val;
        end
        
        function mymask = getMask(R,mysize)
            mymask = zeros(mysize(1),mysize(2),R.nSlices,R.nTimes);
            for s=1:R.nSlices
                for t=1:R.nTimes
                    if ~isempty(R.pointsAut{s,t})
                        x=R.pointsAut{s,t}(:,1);
                        y=R.pointsAut{s,t}(:,2);
                        mymask(:,:,s,t)=poly2mask(x, y, mysize(1), mysize(2));
                    elseif ~isempty(R.pointsMan{s,t})
                        x=R.pointsMan{s,t}(:,1);
                        y=R.pointsMan{s,t}(:,2);
                        mymask(:,:,s,t)=poly2mask(x, y, mysize(1), mysize(2));
                    end
                end
            end
        end
        
        function mymask = getManMask(R,mysize)
            mymask = zeros(mysize(1),mysize(2),R.nSlices,R.nTimes);
            for s=1:R.nSlices
                for t=1:R.nTimes
                    if ~isempty(R.pointsMan{s,t})
                        x=R.pointsMan{s,t}(:,1);
                        y=R.pointsMan{s,t}(:,2);
                        mymask(:,:,s,t)=poly2mask(x, y, mysize(1), mysize(2));
                    end
                end
            end
        end
        
        function R = approxPoints(R)
        end
        
        function R = trackPoints(R,dispField)
        end
    end
    
end

