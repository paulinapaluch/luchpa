classdef MRDataCineReadDicoms_Miccai2009validation < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        dcmDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_validation'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting/Miccai2009'};
        conDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart2/ValidationDataContours'};
    end
    
    methods (Test)
        
%         function testMICCAI2009_data1(tc,dcmDir,matDir)
%             namesize( 1,:) = {'SC-HF-I-5',  [256 256 11 20]};
%             namesize( 2,:) = {'SC-HF-I-6',  [256 256 11 20]};
%             namesize( 3,:) = {'SC-HF-I-7',  [256 256  8 20]};
%             namesize( 4,:) = {'SC-HF-I-8',  [256 256 12 20]};
%             namesize( 5,:) = {'SC-HF-NI-7', [256 256 13 20]};
%             namesize( 6,:) = {'SC-HF-NI-11',[256 256 12 20]};
%             namesize( 7,:) = {'SC-HF-NI-31',[256 256 14 20]}; 
%             namesize( 8,:) = {'SC-HF-NI-33',[256 256 12 20]};
%             %%% namesize( 9,:) = {'SC-HYP-6',   [256 256 10 20], {1000}}; % has other cine series with 280 images
%             namesize(10,:) = {'SC-HYP-7',   [256 256 12 20]};
%             %%% namesize(11,:) = {'SC-HYP-8',   [256 256 12 20]}; % has two cine series with 12 slices
%             namesize(12,:) = {'SC-HYP-37',  [256 256 11 20]}; % 218 pics? sth is wrong here
%             namesize(13,:) = {'SC-N-5',     [256 256  8 20]};  
%             %%% namesize(14,:) = {'SC-N-6',     [256 256 10 20], {303}}; % two cine series with 200 pics
%             namesize(15,:) = {'SC-N-7',     [256 256 12 20]};
%             
%             for iname=find(~cellfun(@isempty,namesize(:,1)))'
%                 dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
%                 matDir_temp = fullfile(matDir);
%                 M = MRDataCINE(dcmDir_temp,matDir_temp,'SeriesNumber',namesize{iname,3});
%                 failText = sprintf('Failed in: %s',namesize{iname,1});
%                 tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
%             end
%         end

        function testMICCAI2009_data2(tc,dcmDir,matDir)
%             %%% namesize( 1,:) = {'SC-HF-I-5',  [256 256 11 20]};
%             %%% namesize( 2,:) = {'SC-HF-I-6',  [256 256 11 20]};
%             %%% namesize( 3,:) = {'SC-HF-I-7',  [256 256  8 20]};
%             %%% namesize( 4,:) = {'SC-HF-I-8',  [256 256 12 20]};
%             %%% namesize( 5,:) = {'SC-HF-NI-7', [256 256 13 20]};
%             %%% namesize( 6,:) = {'SC-HF-NI-11',[256 256 12 20]};
%             %%% namesize( 7,:) = {'SC-HF-NI-31',[256 256 14 20]}; 
%             %%% namesize( 8,:) = {'SC-HF-NI-33',[256 256 12 20]};
%             namesize( 9,:) = {'SC-HYP-6',   [256 256 10 20], {1000}}; % has other cine series with 280 images
%             namesize(10,:) = {'SC-HYP-7',   [256 256 12 20], {1200}}; % has two cine series with 12 slices
            namesize(11,:) = {'SC-HYP-8',   [256 256 12 20], {1200}}; % has two cine series with 12 slices
%             %%% namesize(12,:) = {'SC-HYP-37',  [256 256 11 20]}; % 218 pics? sth is wrong here
%             %%% namesize(13,:) = {'SC-N-5',     [256 256  8 20]};  
%             namesize(14,:) = {'SC-N-6',     [256 256 10 20], {303}}; % two cine series with 200 pics
%             %%%namesize(15,:) = {'SC-N-7',     [256 256 12 20]};
            
            for iname=find(~cellfun(@isempty,namesize(:,1)))'
                dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
                matDir_temp = fullfile(matDir);
                M = MRDataCINE(dcmDir_temp,matDir_temp,'SeriesNumber',namesize{iname,3});
                failText = sprintf('Failed in: %s',namesize{iname,1});
                tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
            end
        end
        
        function testMICCAI2009_loadContours(tc,conDir,matDir)
%             names( 1,:) = {'SC-HF-I-5',  'SC-HF-I-05'};
%             names( 2,:) = {'SC-HF-I-6',  'SC-HF-I-06'};
%             names( 3,:) = {'SC-HF-I-7',  'SC-HF-I-07'};
%             names( 4,:) = {'SC-HF-I-8',  'SC-HF-I-08'};
%             names( 5,:) = {'SC-HF-NI-7', 'SC-HF-NI-07'};
%             names( 6,:) = {'SC-HF-NI-11','SC-HF-NI-11'};
%             names( 7,:) = {'SC-HF-NI-31','SC-HF-NI-31'}; 
%             names( 8,:) = {'SC-HF-NI-33','SC-HF-NI-33'};
%             names( 9,:) = {'SC-HYP-6',   'SC-HYP-06'};
%             names(10,:) = {'SC-HYP-7',   'SC-HYP-07'};
            names(11,:) = {'SC-HYP-8',   'SC-HYP-08'};
%             names(12,:) = {'SC-HYP-37',  'SC-HYP-37'};
%             names(13,:) = {'SC-N-5',     'SC-N-05'};  
%             names(14,:) = {'SC-N-6',     'SC-N-06'};
%             names(15,:) = {'SC-N-7',     'SC-N-07'};
            
            for iname=find(~cellfun(@isempty,names(:,1)))'
                conDir_temp = fullfile(conDir,names{iname,2},'contours-manual','IRCCI-expert');
                matDir_temp = fullfile(matDir,names{iname,1},'NonameStudy');
                M = MRDataCINE.load(matDir_temp);
                M.miccaiInDir = conDir_temp;
                M.importRoisMICCAI2009;
                M.calcbreathingCorrection;
                M.dupaSave;
                
                isemptyEpi = cellfun(@isempty,M.epi.pointsMan);
                isemptyEndo = cellfun(@isempty,M.endo.pointsMan);
                
                failText = sprintf('Failed in: %s',names{iname,1});
                tc.verifyGreaterThan(sum(~isemptyEpi(:)),0,failText);
                tc.verifyGreaterThan(sum(~isemptyEndo(:)),0,failText);
            end
        end
    end
end

