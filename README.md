# MRHeart

# File structure
```
Dicom files directory 
├── Research study 1
├── Research study 2
|   ├── Patient 1 
|   ├── Patient 2
|       ├── Study 1 (dcmsStudDir)
|       ├── Study 2
|           ├── Series 1 (dcmSerDir{1})
|           ├── Series 2 (dcmSerDir{2})
|           ├── Series 3 (dcmSerDir{3})
|           ├── Series 4
|               ├── dicom file 1
|               ...
|               ├── dicom file n
...   
```

```
Matlab files directory
├── Research study 1
├── Research study 2 (matSaveSerDir)
|   ├── Patient 1
|   ├── Patient 2
|       ├── Study 1
|       ├── Study 2
|           ├── Series 1
|           ├── Series 2 (matLoadSerDir)
|              ├── MRDataCine.mat
|              ├── MRDispField_type1.mat
|               ├── MRDispField_type2.mat
|           ├── Series 3
|               ├── MRDataTI.mat
|               ├── MRMap_type1.mat
|               ├── MRMap_type2.mat
|           ├── Series 3
|               ├── MRDataLGE.mat

...               
```

# How to use 

## How to get matlab data
1. Generate matlab file(s) based on dicoms in the study dir - dcmsStudDir. The process takes long time and may be buggy.
``` matlab
dcmsStudDir = '???';
matSaveSerDir = '???';
M = MRDataCINE(dcmsStudDir,matSaveSerDir);
```
2. Generate matlab file(s) based on dicoms in the series dirs - dcmsSerDir. The process is more complicated for the used, but faster and less buggy.
``` matlab
dcmsSerDirs{1} = '???';
dcmsSerDirs{2} = '???';
...
matSaveSerDir = '???';
M = MRDataCINE(dcmsSerDirs,matSaveSerDir);
```
3. Load previously generated matlab file
``` matlab
matLoadSerDir = '???';
M = MRDataCINE.load(matLoadSerDir);
```

## How to visualise data
``` matlab
MRV(M)
```

## How to calculate diplacament field / T1 maps /others


# Contact
Konrad Werys

[mrkonrad.github.io](mrkonrad.github.io)

konradwerys2@gmail.com
