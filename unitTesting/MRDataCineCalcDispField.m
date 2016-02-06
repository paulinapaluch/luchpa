classdef MRDataCineCalcDispField < matlab.unittest.TestCase
    
    properties (TestParameter)
        matDir = {'/Volumes/My Passport/MAT/unitTesting'};
    end
     
    methods (Test)
        
        function testIKARD_CINE_data(tc,matDir)
            matDir_temp = fullfile(matDir,'IKARD_CINE');
            M = MRDataCINE.load(matDir_temp);
            M.calcbreathingCorrection;
            
            M.dispField.calcDispField(M,'DFbspline2Dcons_DJK');
            tc.assertEqual(M.dispField.type,'DFbspline2Dcons_DJK');
            
            M.dispField.calcDispField(M,'DFbspline3Dcons_DJK');
            tc.assertEqual(M.dispField.type,'DFbspline2Dcons_DJK');
            
            M.dispField.update(M,'DFbspline2Dcons_DJK');
            tc.assertEqual(M.dispField.type,'DFbspline2Dcons_DJK');
        end
     
    end
     
end

