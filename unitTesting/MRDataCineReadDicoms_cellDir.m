classdef MRDataCineReadDicoms_cellDir < matlab.unittest.TestCase
    
    properties (TestParameter)
        dcmDir = {'/Volumes/My Passport/DCM/unitTesting'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting/cellDir'};
    end
     
    methods (Test)
         
%         function testMICCAI2009_data(tc,dcmDir,matDir)
%             dcmDir_temp = fullfile(dcmDir,'MICCAI2009');
%             matDir_temp = fullfile(matDir,'MICCAI2009');
%             allDcmDirsCell = get_all_dirs(dcmDir_temp);
%             M = MRDataCINE(allDcmDirsCell,matDir_temp);
%             tc.assertEqual(size(M.dataRaw),[256 256 14 20]);
%         end
         
        function testMICCAI2011_data(tc,dcmDir,matDir)
            dcmDir_temp = fullfile(dcmDir,'MICCAI2011');
            matDir_temp = fullfile(matDir,'MICCAI2011');
            allDcmDirsCell = get_all_dirs(dcmDir_temp);
            M = MRDataCINE(allDcmDirsCell,matDir_temp);
            tc.assertEqual(size(M.dataRaw),[256 256 14 30]);
        end
        
        function testIKARD_CINE_data(tc,dcmDir,matDir)
            dcmDir_temp = fullfile(dcmDir,'IKARD_CINE');
            matDir_temp = fullfile(matDir,'IKARD_CINE');
            allDcmDirsCell = get_all_dirs(dcmDir_temp);
            M = MRDataCINE(allDcmDirsCell,matDir_temp);
            tc.assertEqual(size(M.dataRaw),[256 208 12 25]);
        end
     
    end
     
end

