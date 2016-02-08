classdef MRDispField  < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        % this is visible from class, >>MRDispField.allowedDF
        allowedDF = {...
            'DFbspline2Dcons_DJK',@MRRegistration.register2DconsBspline_DJK;...
            'DFbspline3Dcons_DJK',@MRRegistration.register3DconsBspline_DJK;...
            'DFbspline3Dcons_DJK_p9',@MRRegistration.register3DconsBspline_DJK_p9;...
            'DFbspline3Dcons_DJK_p0',@MRRegistration.register3DconsBspline_DJK_p0;...
            'DFdemon2Dcons_DJK',  @myfun;...
            'DFdemon3Dcons_DJK',  @myfun;...
            'DFdemon2Dcons_mat',  @myfun;...
            'DFdemon3Dcons_mat',  @myfun;...
            'DFsomething from fair',@myfun};
    end
    
    properties
        saveDirPath = '';
    end
    
    properties (GetAccess = public, SetAccess = private)
        loadDirPath = '';	% updated on load
        back            % calculated backwad displacement field
        forw            % calculated forward displacement field
        regoptions      % registration options
        type            % name, one of the allowedDF
        MRDataUID       % to check if DF is loaded to the right MRData
        empty = [];     % sometimes empty is needed
    end
    
    methods
        %%% ---------------------- CONSTRUCTOR ---------------------- %%%
        function DF = MRDispField(varargin)
            if nargin==0
                error('Not enough input args')
            elseif nargin==1
                MRDataTemp = varargin{1};
                DF.MRDataUID = MRDataTemp.UID;
                DF.loadDirPath = MRDataTemp.loadDirPath;
                DF.saveDirPath = MRDataTemp.saveDirPath;
            elseif nargin==2
                MRDataTemp = varargin{1};
                DF.MRDataUID = MRDataTemp.UID;
                DF.loadDirPath = MRDataTemp.loadDirPath;
                DF.saveDirPath = MRDataTemp.saveDirPath;
                DF.type = varargin{3};
            end
        end
        
        %%% --------------------- OTHER METHODS --------------------- %%%
        
        function out = magBack(DF),out=sqrt(sum(DF.back.^2,5));end
        function out = magForw(DF),out=sqrt(sum(DF.forw.^2,5));end
        function out = magComb(DF),out=sqrt(sum(DF.getComb.^2,5));end
        
        function DF = calcDispField(DF,MRData,type)
            % calculate and SAVE the displacaement field
            idx = DF.typeIdx(type);
            if strcmp(MRData.UID,DF.MRDataUID) && ~isempty(idx)
                mytic = tic;
                fprintf('Calculating %s\n',type)
                % calulate and save the DF
                myfun = DF.allowedDF{idx,2};
                try
                    [DF.back, DF.forw, DF.regoptions] = myfun(MRData);
                    DF.type = type;
                catch ex
                    disp(ex)
                end
                fprintf('Was calculating %s for %.2f seconds',type,toc(mytic));
            else
                disp('Allowed Disp Field type:')
                disp(DF.allowedDF)
                error('Wrong MRData or Disp Field type (look up)')
            end
            
            saveDispField(DF)
        end
        
        function DF = loadDispField(DF,MRData,type)
            % add checking if UI
            idx = DF.typeIdx(type);
            if ~isempty(idx)
                fullPath = fullfile(DF.loadDirPath,type);
                try
                    temp = load(fullPath);
                    DF.back = temp.back;
                    DF.forw = temp.forw;
                    DF.type = temp.type;
                    DF.MRDataUID = temp.MRDataUID;
                    if ~strcmp(MRData.UID,DF.MRDataUID)
                        error('Wrong MRData')
                    end
                catch ex
                    disp(ex)
                end
            else
                disp('Allowed Disp Field type:')
                disp(DF.allowedDF)
                error('Wrong Disp Field type (look up)')
            end
        end
        
        function DF = saveDispField(DF)
            
            fullPath = fullfile(DF.saveDirPath,DF.type);
            try
                back        = DF.back;
                forw        = DF.forw;
                type        = DF.type;
                regoptions  = DF.regoptions;
                MRDataUID   = DF.MRDataUID;
                save(fullPath,'back','forw','type','MRDataUID','regoptions')
                DF.loadDirPath = DF.saveDirPath;
            catch ex
                disp(ex)
            end
        end
        
        function DF = update(DF,MRData,type)
            fullPath = fullfile(DF.loadDirPath,[type,'.mat']);
            % check if already was calculated. If so, load
            if exist(fullPath,'file')
                fprintf('Loading displacement field: %s\n',type);
                DF=DF.loadDispField(MRData,type);
            else
                fprintf('Calculating displacement field: %s\n?',type);
                DF=DF.calcDispField(MRData,type);
            end
        end
        
%         function back = getDispFieldback(DF,MRData)
%             emptyBack = isempty(DF.back);
%             emptyType = isempty(DF.type);
% 
%             if emptyBack && nargin ==1
%                 error('Not enough args')
%             elseif emptyBack && nargin ==2 && ~emptyType
%                 DF.update();
%             elseif emptyBack && nargin ==2 && emptyType
%             back = DF.back(MRData);
%         end
        
%         function back = getDispFieldforw(DF)
%             if isempty(DF.forw)
%                 DF.update;
%             end
%             back = DF.forw;
%         end
        
        function dfComb = getDispFieldCom(DF)
            disp('TBI')
        end    
        
        function DF = set.type(DF,type)
            % check if it is on the list of allowed types
            if any(ismember(DF.allowedDF(:,1),type))
                DF.type = type;
            else
                disp('Allowed Disp Field type:')
                disp(DF.allowedDF)
                error('Wrong Disp Field type (look up)')
            end
        end
        
%         function saveDirPath = get.saveDirPath(DF)
%             if strcmp(DF.saveDirPath,'')
%                 saveDirPath = DF.loadDirPath;
%                 DF.saveDirPath = saveDirPath;
%             end
%         end
        
        function out = typeIdx(DF,type)
            out = find((ismember(DF.allowedDF(:,1),type)));
        end
        
    end
    
end

