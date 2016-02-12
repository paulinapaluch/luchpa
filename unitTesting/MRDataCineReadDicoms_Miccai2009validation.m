classdef MRDataCineReadDicoms_Miccai2009validation < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        dcmDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_validation'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting/Miccai2009'};
    end
    
    methods (Test)
        
        function testMICCAI2009_data(tc,dcmDir,matDir)
%             namesize( 1,:) = {'SC-HF-I-5',  [256 256 11 20]};
%             namesize( 2,:) = {'SC-HF-I-6',  [256 256 11 20]};
%             namesize( 3,:) = {'SC-HF-I-7',  [256 256  8 20]};
%             namesize( 4,:) = {'SC-HF-I-8',  [256 256 12 20]};
%             namesize( 5,:) = {'SC-HF-NI-7', [256 256 13 20]};
%             namesize( 6,:) = {'SC-HF-NI-11',[256 256 12 20]};
%             namesize( 7,:) = {'SC-HF-NI-31',[256 256 14 20]}; 
%             namesize( 8,:) = {'SC-HF-NI-33',[256 256 12 20]};
%             %%% namesize( 9,:) = {'SC-HYP-6',   [256 256 10 20]}; % has other cine series with 280 images
%             namesize(10,:) = {'SC-HYP-7',   [256 256 12 20]};
%             namesize(11,:) = {'SC-HYP-8',   [256 256 12 20]};
            namesize(12,:) = {'SC-HYP-37',  [256 256 11 20]}; % 218 pics? sth is wrong here
            namesize(13,:) = {'SC-N-5',     [256 256  8 20]};  
            %%% namesize(14,:) = {'SC-N-6',     [256 256 10 20]}; % two cine series with 200 pics
            namesize(15,:) = {'SC-N-7',     [256 256 12 20]};
            
            for iname=find(~cellfun(@isempty,namesize(:,1)))'
                dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
                matDir_temp = fullfile(matDir);
                M = MRDataCINE(dcmDir_temp,matDir_temp);
                failText = sprintf('Failed in: %s',namesize{iname,1});
                tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
            end
            
        end
    end
end

