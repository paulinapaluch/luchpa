classdef MRSegmentation
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        [centroids, mask] = calcCentroids(data);
        [centr,harm1mt,mask,line1coors,line2coors] = calcFinalCentroid3d(data, aspectRatio);
        
        function [harmAll] = calcHarmonicsAll(data)
            harmAll = abs(fft(data,[],4));
        end
        
        function [mask4d] = regionGrowing2Dplus(data4d,seed0,reg_maxdist)
            mask4d = zeros(size(data4d));
            [nX,nY,nSlices,nTimes] = size(data4d);
            seed = cell(nSlices,nTimes);
            % over slices
            seed0R = round(seed0);
            iSlice = seed0R(3);
            iTime = seed0R(4);
            temp = data4d(:,:,iSlice,iTime);
            seed{iSlice,iTime} = seed0(1:2);
            mask4d(:,:,iSlice,iTime)=regiongrowing(temp,seed0R(1),seed0R(2),reg_maxdist);
            islicesdown = flip(1:iSlice-1);
            islicesup = iSlice+1:nSlices;
            for iSlice=islicesup
                temp = data4d(:,:,iSlice,iTime);
                seed_temp = round(seed{iSlice-1,iTime});
                mask_temp=regiongrowing(temp,seed_temp(1),seed_temp(2),reg_maxdist);
                
                if sum(mask_temp(:))>nX*nY/2
                    seed{iSlice,iTime} = seed{iSlice-1,iTime};
                    continue
                end
                s = regionprops(mask_temp,'centroid');
                seed{iSlice,iTime} = [s.Centroid(2),s.Centroid(1)];
                mask4d(:,:,iSlice,iTime) = mask_temp;
            end
            for iSlice=islicesdown
                temp = data4d(:,:,iSlice,iTime);
                seed_temp = round(seed{iSlice+1,iTime});
                mask_temp=regiongrowing(temp,seed_temp(1),seed_temp(2),reg_maxdist);
                
                if sum(mask_temp(:))>nX*nY/2
                    seed{iSlice,iTime} = seed{iSlice+1,iTime};
                    continue
                end
                s = regionprops(mask_temp,'centroid');
                seed{iSlice,iTime} = [s.Centroid(2),s.Centroid(1)];
                mask4d(:,:,iSlice,iTime) = mask_temp;
            end
            itimesback = flip(1:iTime-1);
            itimesforw = iTime+1:nTimes;
            for iSlice = 1:nSlices
                for iTime=itimesback
                    temp = data4d(:,:,iSlice,iTime);
                    seed_temp = round(seed{iSlice,iTime+1});
                    mask_temp=regiongrowing(temp,seed_temp(1),seed_temp(2),reg_maxdist);
                    
                    if sum(mask_temp(:))>nX*nY/2
                        seed{iSlice,iTime} = seed{iSlice,iTime+1};
                        continue
                    end
                    s = regionprops(mask_temp,'centroid');
                    seed{iSlice,iTime} = [s.Centroid(2),s.Centroid(1)];
                    mask4d(:,:,iSlice,iTime) = mask_temp;
                end
                for iTime=itimesforw
                    temp = data4d(:,:,iSlice,iTime);
                    seed_temp = round(seed{iSlice,iTime-1});
                    mask_temp=regiongrowing(temp,seed_temp(1),seed_temp(2),reg_maxdist);
                    
                    if sum(mask_temp(:))>nX*nY/2
                        seed{iSlice,iTime} = seed{iSlice,iTime-1};
                        continue
                    end
                    s = regionprops(mask_temp,'centroid');
                    seed{iSlice,iTime} = [s.Centroid(2),s.Centroid(1)];
                    mask4d(:,:,iSlice,iTime) = mask_temp;
                end
                fprintf('.')
            end
            fprintf('\n')
        end
        
    end
    
end

