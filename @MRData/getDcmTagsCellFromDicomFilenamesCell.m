function dcmTags = getDcmTagsCellFromDicomFilenamesCell(dcmFilenamesCell)

fprintf('Getting dicom metadata cell')
mytic=tic;
for iFile = 1:length(dcmFilenamesCell)
    try
        if iFile == 1
            tempDcmTags = orderfields(dicominfo(dcmFilenamesCell{iFile}));
        else
            temp = orderfields(dicominfo(dcmFilenamesCell{iFile}));
            
            %%% check if structures have the same fields
            tempfieldnames = fieldnames(temp);
            tempDcmTagsfieldnames = fieldnames(tempDcmTags);
            idxDiffFields1 = find(~ismember(tempfieldnames,tempDcmTagsfieldnames));
            idxDiffFields2 = find(~ismember(tempDcmTagsfieldnames,tempfieldnames));
            missingfields1 = getfield(tempfieldnames,{idxDiffFields1});
            missingfields2 = getfield(tempDcmTagsfieldnames,{idxDiffFields2});
            for n=1:length(idxDiffFields1)
                [tempDcmTags.(missingfields1{n})]=deal([]);
            end
            for n=1:length(idxDiffFields2)
                [temp.(missingfields2{n})]=deal([]);
            end
            tempDcmTags = orderfields(tempDcmTags);
            temp = orderfields(temp);
            %%% now we can add those dicom tags to our structure
            tempDcmTags(iFile) = temp;
            
            if mod(iFile,round(length(dcmFilenamesCell)/10))==0
                fprintf('.')
            end
        end
    catch ex
        %disp(ex)
        continue
    end 
end
mytoc=toc(mytic);
fprintf(' Done in %.2f sec.',mytoc)
dcmTags=tempDcmTags;
fprintf('\n')
