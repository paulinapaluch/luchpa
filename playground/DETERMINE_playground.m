%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Konrad Werys, Feb 2016   %
%   konradwerys@gmail.com    %
%   <mrkonrad.github.io>     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
user = char(java.lang.System.getProperty('user.name'));

switch user
    case 'kwer040'
        dcmDir = '';
        matDir = '';
    case 'konrad'
        dcmDir = '/Volumes/Seagate/DCM/DETERMINE/IMAGES';
        matDir = '/Volumes/Seagate/MAT/DETERMINE';
end

load('DETERMINEmassGT.mat')

nameSeries{ 1} = {'DET0000101','SeriesNumber',num2cell(26:2:46)};
nameSeries{ 2} = {'DET0000201','SeriesNumber',{1701}};
nameSeries{ 3} = {'DET0000301','SeriesNumber',num2cell(60:2:90)};
%%%% nameSeries{ 4} = {'DET0000401','SeriesNumber',num2cell(26:2:46)}; % change of phase encoding direction
nameSeries{ 5} = {'DET0000501','SeriesNumber',num2cell(30:2:48)};
nameSeries{ 6} = {'DET0000601','SeriesInstanceUID',{'2.16.124.113543.6006.99.3422451652952475038'}};
nameSeries{ 7} = {'DET0000701','SeriesNumber',{29}};
nameSeries{ 8} = {'DET0000801','SeriesNumber',{22}};
nameSeries{ 9} = {'DET0000901','SeriesNumber',{23}};
nameSeries{10} = {'DET0001001','SeriesNumber',{23}};
nameSeries{11} = {'DET0001101','SeriesNumber',{3101}};
nameSeries{12} = {'DET0001201','SeriesNumber',{2201}};
nameSeries{13} = {'DET0001301','SeriesNumber',{3101}};
nameSeries{14} = {'DET0001401','SeriesNumber',{3201}};
nameSeries{15} = {'DET0001501','SeriesNumber',{4101}};
nameSeries{16} = {'DET0001601','SeriesNumber',{11}};
nameSeries{17} = {'DET0001701','SeriesNumber',num2cell(79:2:91)};
nameSeries{18} = {'DET0001801','SeriesNumber',num2cell(73:2:85)};
nameSeries{19} = {'DET0001901','SeriesNumber',{1201}}; % mag and phase in one series 
nameSeries{20} = {'DET0002001','SeriesNumber',{1101}}; % mag and phase in one series 
nameSeries{21} = {'DET0002101','SeriesNumber',{1201}}; % mag and phase in one series 
nameSeries{22} = {'DET0002201','SeriesNumber',{1101}}; % mag and phase in one series 
nameSeries{23} = {'DET0002301','SeriesNumber',{1301}}; % mag and phase in one series 
nameSeries{24} = {'DET0002401','SeriesNumber',{20}};
nameSeries{25} = {'DET0002501','SeriesNumber',{25}};
nameSeries{26} = {'DET0002601','SeriesNumber',{19}};
nameSeries{27} = {'DET0002701','SeriesNumber',{25}};
nameSeries{28} = {'DET0002801','SeriesNumber',{2101}};
nameSeries{29} = {'DET0002901','SeriesNumber',{1801}};


%% GET DATA FROM DICOMS
for iname=1%find(~cellfun(@isempty,nameSeries))
    dcmDir_temp = fullfile(dcmDir,nameSeries{iname}{1});
    matDir_temp = fullfile(matDir);
    
    M = MRDataLGE(dcmDir_temp,matDir_temp,nameSeries{iname}{2},nameSeries{iname}{3});
end

%% CALCULATE SCAR
for iname=1%find(~cellfun(@isempty,nameSeries))
    mypath = fullfile(matDir,nameSeries{iname}{1},'NonameStudy');
    M = MRDataLGE.load(mypath);
    M.data;
    M.calcScar;
    scarVolume(iname) = M.scarMass;
    close all, V=MRV(M);V.overMap = hsv;V.alpha = .8;V.maskRange = [0 .5];V.updateImages;
    %keyboard
end

% %% CALCULATE SCAR2
% for iname=find(~cellfun(@isempty,nameSeries))
%     mypath = fullfile(matDir,nameSeries{iname}{1},'NonameStudy');
%     M = MRDataLGE.load(mypath);
%     M.data;
%     M.calcScar;
%     scarVolume(iname) = M.scarMass;
% end
% %
% figure
% labels.title = 'LGE';
% labels.x = 'Determine ground truth';
% labels.y = 'KW';
% options.parametric = 1;
% options.markersize = 10;
% scarVolume(scarVolume==0)=nan;
% myscatter(DETERMINEmassGT,scarVolume','scatter',labels,options)
