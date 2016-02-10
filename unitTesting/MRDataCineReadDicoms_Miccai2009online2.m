classdef MRDataCineReadDicoms_Miccai2009online2 < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        dcmDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_online/challenge_online'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting/Miccai2009'};
    end
    
    methods (Test)
        
        function testMICCAI2009_data(tc,dcmDir,matDir)
            %%% namesize( 1,:) = {'SC-HF-I-9',   [256 256 14 20]};
            %%% namesize( 2,:) = {'SC-HF-I-10',  [256 256 13 20]};
            %%% namesize( 3,:) = {'SC-HF-I-11',  [256 256 12 20]};
            %%% namesize( 4,:) = {'SC-HF-I-12',  [256 256 12 20]};
            %%% namesize( 5,:) = {'SC-HF-NI-12', [256 256 14 20]};
            %%% namesize( 6,:) = {'SC-HF-NI-13', [256 256 11 20]};
            namesize( 7,:) = {'SC-HF-NI-14', [256 256 14 20], {303}}; % has other cine series with 380 images
            %%% namesize( 8,:) = {'SC-HF-NI-15', [256 256 11 20]};
            %%% namesize( 9,:) = {'SC-HYP-9',    [256 256 12 20]};
            %%% namesize(10,:) = {'SC-HYP-10',   [256 256  9 20]};
            %%% namesize(11,:) = {'SC-HYP-11',   [256 256 14 20]};
            %%% namesize(12,:) = {'SC-HYP-12',   [256 256  9 20]};
            namesize(13,:) = {'SC-N-9',      [256 256 10 20], {302}}; % has other cine series with 239 images
            namesize(14,:) = {'SC-N-10',     [256 256 12 20], {300}}; % has phase contrast 5*60 images
            %%% namesize(15,:) = {'SC-N-11',     [256 256  9 20]};
            
            for iname=find(~cellfun(@isempty,namesize(:,1)))'
                dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
                matDir_temp = fullfile(matDir);
                M = MRDataCINE(dcmDir_temp,matDir_temp,'SeriesNumber',namesize{iname,3});
                failText = sprintf('Failed in: %s',namesize{iname,1});
                tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
            end
            
        end
    end
end

