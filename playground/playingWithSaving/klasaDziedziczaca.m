classdef klasaDziedziczaca < klasaAbstrakcyjna
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        fileName = 'klasaDziedziczaca';
    end
    
    properties
        savePath     = '';
        loadPath     = '';
        sameVariable = 'a';
        sameObject   = [];
    end
    
    methods
        function obj = klasaDziedziczaca(savePath)
            obj.savePath     = savePath;
            obj.loadPath     = savePath;
            obj.sameVariable = 'b';
            obj.sameObject   = klasaJakas(savePath);
            
        end
        
        function save(obj)
            save(fullfile(obj.savePath,[obj.fileName,'.mat']),obj);
        end
        
        function sobj = saveobj(obj)
            sobj = obj;
            sobj.sameObject.save;
            sobj.sameObject=[];
            disp('In saveobj')
        end
    end
    
    methods (Static)
        function obj = load(mypath)
            %%% a dummy variable used in loadobj method
            dummyvariable694828623=0; %#ok
            
            try
                temp = load(mypath);
                tempfieldname = fieldnames(temp);
                if length(tempfieldname)>1
                    error('More then one object in a given file');
                end
                obj = temp.(tempfieldname{1});
                obj.loadPath = mypath;
            catch ex
                disp(ex);
            end
        end
        
        function obj = loadobj(obj)
            %%% I do not know how to get path from where the object is
            %%% loaded (by calling load('path')). So I implemened
            %%% obj.load method where I have stupid name for a variable. I
            %%% check if this variable exist in the worspace that is
            %%% calling the load object. If no, there is a warning.
            
            if ~evalin('caller','exist(''dummyvariable694828623'',''var'')')
                warning('Please use MRData.load(''path'') not this function. This way of loading data may cause problems using MRData-like classes. Some of the variable (paths) needed for some advanced operations are not set.');
            end
        end
    end
    
end

