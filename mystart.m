codePath = '/Users/konrad/Code/';
mrheartMatlabPath = fullfile(codePath,'MRHeartMat');

addpath(genpath(mrheartMatlabPath));
rmpath(genpath(fullfile(mrheartMatlabPath,'thirdParty','demon_registration_version_8f')))
rmpath(genpath(fullfile(mrheartMatlabPath,'old')))

addpath(genpath(fullfile(codePath,'FAIR')));
addpath(genpath(fullfile(codePath,'Auckland','CodeKW')));

cd(mrheartMatlabPath)