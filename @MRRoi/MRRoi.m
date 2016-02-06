classdef MRRoi < matlab.mixin.SetGet
    %MRRoi stores cells with points positions
    %
    % Konrad Werys, Feb 2016
    % mrkonrad.github.io
    
    properties
        name  = 'ROI'
        color = [0 1 0]
        pointsMan
        pointsAut
        autMethod = '';
    end
    
    methods
        function obj = MRRoi(nSlices,nTimes,varargin)
            obj.pointsMan = cell(nSlices,nTimes);
            obj.pointsAut = cell(nSlices,nTimes);
            if nargin>2, obj.name = varargin{3};end
            if nargin>3, obj.color = varargin{4};end
            if nargin>4, error('Too many imput args');end
        end
        
        function obj = set.name(obj,val)
            if ~isa(val,'char')
                error('Name has to be char');
            end
            obj.name = val;
        end
        
        function obj = set.pointsMan(obj,val)
            if ~isa(val,'cell') || all(size(val)==size(obj.pointsMan))
                error('Points has to be in cell with certain size - cell(nSlices,nTimes)');
            end
            obj.pointsMan = val;
        end
        
        function obj = set.pointsAut(obj,val)
            if ~isa(val,'cell') || all(size(val)==size(obj.pointsMan))
                error('Points has to be in cell with certain size - cell(nSlices,nTimes)');
            end
            obj.pointsAut = val;
        end
        
        function obj = approxPoints(obj)
        end
        
        function obj = trackPoints(obj,dispField)
        end
    end
    
end

