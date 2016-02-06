classdef MRRegistration
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties   
    end
    
    methods (Static)
        [DF_forw,DF_back] = register2DconsBspline_DJK(MRData); % cons - consecutive frames
        [DF_forw,DF_back] = register3DconsBspline_DJK(MRData);
        [DF_forw,DF_back] = register2DconsDemon_mat(MRData);
        [DF_forw,DF_back] = register3DconsDemon_mat(MRData);
        [DF_forw,DF_back] = register2DconsNPar_fair(MRData);
        [DF_forw,DF_back] = register3DconsNPar_fair(MRData);
    end
    
end

