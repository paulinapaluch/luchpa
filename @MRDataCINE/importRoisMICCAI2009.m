function obj = importRoisMICCAI2009(obj)
try
    MICCAIdir = obj.miccaiInDir;
    if ~exist(MICCAIdir,'dir')
        MICCAIdir = uigetdir;
    end
    if MICCAIdir==0
        beep
        return
    end
    allfiles = dir(MICCAIdir);
    for iDir = 1:length(allfiles)
        if ~ismember(allfiles(iDir).name,{'.','..'}) && ~strcmp(allfiles(iDir).name(1:2),'._')
            if ~isempty(strfind(allfiles(iDir).name,'IM-0001-'))
                conNum = str2num(allfiles(iDir).name(10:12)); %#ok
                s = ceil(conNum/obj.nTimes);
                t = mod(conNum,obj.nTimes);
                if t==0, t=obj.nTimes;end
                
                temp = load(fullfile(MICCAIdir,allfiles(iDir).name));
                
                %endo
                if ~isempty(strfind(allfiles(iDir).name,'icontour'))
                    obj.endo.pointsMan{s,t} = temp;
                end
                %epi
                if ~isempty(strfind(allfiles(iDir).name,'ocontour'))
                    obj.epi.pointsMan{s,t} = temp;
                end
            end
        end
    end
    howmanyendos=sum(~cellfun(@isempty,obj.endo.pointsMan));
    howmanyepis=sum(~cellfun(@isempty,obj.epi.pointsMan));
    endosIDX = find(howmanyendos);
    episIDX = find(howmanyepis);
    if length(endosIDX)==2 && length(episIDX)==1
        obj.tEndDiastole = episIDX;
        obj.tEndSystole = endosIDX(endosIDX~=episIDX);
    end
    beep,pause(.1),beep,pause(.1),beep,pause(.1),beep
catch ex
    disp(ex)
    keyboard
end

disp('MICCAI2009 contours imported')
end