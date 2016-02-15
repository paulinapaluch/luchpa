classdef klasaJakas < matlab.mixin.SetGet
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        fileName = 'klasaJakas';
    end
    
    properties        
        savePath = '';
        loadPath = '';
        sameOtherVariable = 'abc';
    end
    
    methods
        function obj = klasaJakas(savePath)
            obj.savePath = savePath;
            obj.loadPath = savePath;
            obj = update(obj);
        end
            
        function save(obj)
            save(fullfile(obj.savePath,[obj.fileName,'.mat']));
        end
        function obj = update(obj)
            fullPath = fullfile(obj.loadPath,obj.fileName);
            try
                temp = load(fullPath);
                obj.sameOtherVariable = temp.sameOtherVariable;
            catch ex
                disp(ex)
            end
        end
    end
end

