classdef MRDataCineReadDicoms_Miccai2009training < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        dcmDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/challenge_training'};
        matDir = {'/Volumes/My Passport/MAT/unitTesting/Miccai2009'};
        conDir = {'/Volumes/My Passport/DCM/Challenges/MICCAI 2009 LV SEG/Sunnybrook Cardiac MR Database ContoursPart3/TrainingDataContours'};
    end
    
    methods (Test)
        
        function testMICCAI2009_data1(tc,dcmDir,matDir)
%             %%% namesize( 1,:) = {'SC-HF-I-1',  [256 256 12 20]}; % two other series together have 320 pics
%             %%% namesize( 2,:) = {'SC-HF-I-2',  [256 256 13 20]}; % other cine series with 260 images
%             namesize( 3,:) = {'SC-HF-I-4',  [256 256 10 20]};
%             namesize( 4,:) = {'SC-HF-I-40', [256 256 11 20]};
%             namesize( 5,:) = {'SC-HF-NI-3', [256 256 12 20]};
%             namesize( 6,:) = {'SC-HF-NI-4', [256 256 11 20]};
%             namesize( 7,:) = {'SC-HF-NI-34',[256 256 13 20]}; 
%             namesize( 8,:) = {'SC-HF-NI-36',[256 256 18 20]}; % series 400, 401 and 402 together. Kinda makes sense
%             %%% namesize( 9,:) = {'SC-HYP-1',   [256 256  9 20]}; %series 607 has more slices then sax series
%             %%% namesize(10,:) = {'SC-HYP-3',   [256 256  9 20]}; %catches unneceary series 300 and 301, only 303 is ok
%             %%% namesize(11,:) = {'SC-HYP-38',  [256 256 12 20]}; % series 400 is ok
%             %%% namesize(12,:) = {'SC-HYP-40',  [256 256 16 20]}; % series 404 is ok
%             namesize(13,:) = {'SC-N-2',     [256 256  9 20]};  
            namesize(14,:) = {'SC-N-3',     [256 256 20 20]}; 
            %%% namesize(15,:) = {'SC-N-40',    [256 256 12 20]};
            
            for iname=find(~cellfun(@isempty,namesize(:,1)))'
                dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
                matDir_temp = fullfile(matDir);
                M = MRDataCINE(dcmDir_temp,matDir_temp);
                failText = sprintf('Failed in: %s',namesize{iname,1});
                tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
            end 
        end

        function testMICCAI2009_data2(tc,dcmDir,matDir)
%             namesize( 1,:) = {'SC-HF-I-1',  [256 256 12 20],{300}}; % two other series together have 320 pics
%             namesize( 2,:) = {'SC-HF-I-2',  [256 256 13 20],{300}}; % other cine series with 260 images
%             %%% namesize( 3,:) = {'SC-HF-I-4',  [256 256 10 20]};
%             %%% namesize( 4,:) = {'SC-HF-I-40', [256 256 11 20]};
%             %%% namesize( 5,:) = {'SC-HF-NI-3', [256 256 12 20]};
%             %%% namesize( 6,:) = {'SC-HF-NI-4', [256 256 11 20]};
%             %%% namesize( 7,:) = {'SC-HF-NI-34',[256 256 13 20]}; 
%             %%% namesize( 8,:) = {'SC-HF-NI-36',[256 256 18 20]}; % series 400, 401 and 402 together. Kinda makes sense
%             namesize( 9,:) = {'SC-HYP-1',   [256 256  9 20],{600}}; %series 607 has more slices then sax series
%             namesize(10,:) = {'SC-HYP-3',   [256 256  8 20],{303}}; %catches unneceary series 300 and 301, only 303 is ok
%             namesize(11,:) = {'SC-HYP-38',  [256 256 12 20],{400}};
%             namesize(12,:) = {'SC-HYP-40',  [256 256 16 20],{404}}; % series 404 is ok
%             %%% namesize(13,:) = {'SC-N-2',     [256 256  9 20]};  
%             %%% namesize(14,:) = {'SC-N-3',     [256 256 20 20]}; 
%             namesize(15,:) = {'SC-N-40',    [256 256 12 20],{1100}};
            
            for iname=find(~cellfun(@isempty,namesize(:,1)))'
                dcmDir_temp = fullfile(dcmDir,namesize{iname,1});
                matDir_temp = fullfile(matDir);
                M = MRDataCINE(dcmDir_temp,matDir_temp,'SeriesNumber',namesize{iname,3});
                failText = sprintf('Failed in: %s',namesize{iname,1});
                tc.assertEqual(size(M.dataRaw),namesize{iname,2},failText);
            end
        end
        
        function testMICCAI2009_loadContours(tc,conDir,matDir)
%             names( 1,:) = {'SC-HF-I-1',  'SC-HF-I-01'};
%             names( 2,:) = {'SC-HF-I-2',  'SC-HF-I-02'};
%             names( 3,:) = {'SC-HF-I-4',  'SC-HF-I-04'};
%             names( 4,:) = {'SC-HF-I-40', 'SC-HF-I-40'};
%             names( 5,:) = {'SC-HF-NI-3', 'SC-HF-NI-03'};
%             names( 6,:) = {'SC-HF-NI-4', 'SC-HF-NI-04'};
%             names( 7,:) = {'SC-HF-NI-34','SC-HF-NI-34'}; 
%             names( 8,:) = {'SC-HF-NI-36','SC-HF-NI-36'}; 
%             names( 9,:) = {'SC-HYP-1',   'SC-HYP-01'}; 
%             names(10,:) = {'SC-HYP-3',   'SC-HYP-03'}; 
%             names(11,:) = {'SC-HYP-38',  'SC-HYP-38'};
%             names(12,:) = {'SC-HYP-40',  'SC-HYP-40'};
%             names(13,:) = {'SC-N-2',     'SC-N-02'};  
            names(14,:) = {'SC-N-3',     'SC-N-03'}; 
%             names(15,:) = {'SC-N-40',    'SC-N-40'};
            
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

