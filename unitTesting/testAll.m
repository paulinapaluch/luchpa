clear
close all

results{1} = runtests('MRDataCineReadDicoms');
results{2} = runtests('MRDataCineLoad');
% results{3} = runtests('MRDataCineCalcDispField');
% results{4} = runtests('MRDataCineLoadSave');

for i=1:length(results)
    disp(results{i}.table);
end