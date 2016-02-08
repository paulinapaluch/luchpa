function importQMassFile(obj)

%filename = '/Users/konrad/Data/DCM/Cont_test/Cont_test.con';
%filename = '/Users/konrad/Data/DCM/Cont_test_002/Cont_test_002.con';
%filename = '/Users/konrad/Data/DCM/Cont_test_003/Cont_test_003.con';

try
    qmassFile = obj.MRData.qmassInFile;
    if exist(qmassFile,'file')
        dirname = uigetdir(qmassFile);
    else
        dirname = uigetdir;
    end
    if dirname==0
        beep
        return
    end
    


try
    fid=fopen(fullfile(pathname,filename));
    nLines = 1;
    tline{nLines} = fgetl(fid);
    while ischar(tline{nLines})
        nLines = nLines+1;
        tline{nLines} = fgetl(fid);
    end
    fclose(fid);
catch ex
    disp(ex)
end

for iLine = 1:nLines
    if strcmp(tline{iLine},'[XYCONTOUR]')
        %%% get sline number, time number
        temp = str2num(tline{iLine+1});
        iSlice = par.nSlices-temp(1);
        iTime = temp(2)+1;
        iROI = temp(3);
        nPoints = str2num(tline{iLine+2});
        points=zeros(nPoints,2);
        for iPoint = 1:nPoints
            temp = str2num(tline{iLine+2+iPoint});
            points(iPoint,1)=temp(1);
            points(iPoint,2)=temp(2);
        end
        try
            if iROI == 0
                par.endoMan{iSlice,iTime} = points';
            elseif iROI == 1
                par.epiMan{iSlice,iTime} = points';
            elseif iROI == 6
                par.ROI1Man{iSlice,iTime} = points';
            elseif iROI == 7
                par.ROI2Man{iSlice,iTime} = points';
            end
        catch ex
            disp(ex);
        end
    end
end





