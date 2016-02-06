classdef MRDataCineReadDicoms < matlab.unittest.TestCase
    
    properties (TestParameter)
        dcmDir = {'/Volumes/My Passport/DCM/unitTesting'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting'};
    end
     
    methods (Test)
         
        function testMICCAI2009_data(tc,dcmDir,matDir)
            dcmDir_temp = fullfile(dcmDir,'MICCAI2009');
            matDir_temp = fullfile(matDir,'MICCAI2009');
            M = MRDataCINE(dcmDir_temp,matDir_temp);
            tc.assertEqual(M.nXs,256);
            tc.assertEqual(M.nYs,256);
            tc.assertEqual(M.nSlices,14);
            tc.assertEqual(M.nTimes,20);
            %postion orientation etc
        end
         
        function testMICCAI2011_data(tc,dcmDir,matDir)
            dcmDir_temp = fullfile(dcmDir,'MICCAI2011');
            matDir_temp = fullfile(matDir,'MICCAI2011');
            M = MRDataCINE(dcmDir_temp,matDir_temp);
            tc.assertEqual(M.nXs,256);
            tc.assertEqual(M.nYs,256);
            tc.assertEqual(M.nSlices,14);
            tc.assertEqual(M.nTimes,30);
            %postion orientation etc
        end
        
        function testIKARD_CINE_data(tc,dcmDir,matDir)
            dcmDir_temp = fullfile(dcmDir,'IKARD_CINE');
            matDir_temp = fullfile(matDir,'IKARD_CINE');
            M = MRDataCINE(dcmDir_temp,matDir_temp);
            tc.assertEqual(M.nXs,256);
            tc.assertEqual(M.nYs,208);
            tc.assertEqual(M.nSlices,12);
            tc.assertEqual(M.nTimes,25);
            %postion orientation etc
        end
     
    end
     
end

