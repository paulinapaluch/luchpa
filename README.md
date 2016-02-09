# MRHeart

# File structure

{% highlight bash %}
Dicom files directory 
??? Research study 1
??? Research study 2
|   ??? Patient 1 
|   ??? Patient 2
|       ??? Study 1 (dcmsStudDir)
|       ??? Study 2
|           ??? Series 1 (dcmSerDir{1})
|           ??? Series 2 (dcmSerDir{2})
|           ??? Series 3 (dcmSerDir{3})
|           ??? Series 4
|               ??? dicom file 1
|               ...
|               ??? dicom file n
...               
{% endhighlight %}

{% highlight bash %}
Matlab files directory
??? Research study 1
??? Research study 2 (matSaveSerDir)
|   ??? Patient 1
|   ??? Patient 2
|       ??? Study 1
|       ??? Study 2
|           ??? Series 1
|           ??? Series 2 (matLoadSerDir)
|           |   ??? MRDataCine.mat
|           |   ??? MRDispField_type1.mat
|           |   ??? MRDispField_type2.mat
|           ??? Series 3
|           |   ??? MRDataTI.mat
|           |   ??? MRMap_type1.mat
|           |   ??? MRMap_type2.mat
|           ??? Series 3
|               ??? MRDataLGE.mat

...               
{% endhighlight %}

# How to use 

## How to get matlab data
1. Generate matlab file(s) based on dicoms in the study dir - dcmsStudDir. The process takes long time and may be buggy.
{% highlight matlab %}
dcmsStudDir = '???';
matSaveSerDir = '???';
M = MRDataCINE(dcmsStudDir,matSaveSerDir);
{% endhighlight %}
2. Generate matlab file(s) based on dicoms in the series dirs - dcmsSerDir. The process is more complicated for the used, but faster and less buggy.
{% highlight matlab %}
dcmsSerDirs{1} = '???';
dcmsSerDirs{2} = '???';
...
matSaveSerDir = '???';
M = MRDataCINE(dcmsSerDirs,matSaveSerDir);
{% endhighlight %}
3. Load previously generated matlab file
{% highlight matlab %}
matLoadSerDir = '???';
M = MRDataCINE.load(matLoadSerDir);
{% endhighlight %}

## How to visualise data
{% highlight matlab %}
MRV(M)
{% endhighlight %}

## How to calculate diplacament field / T1 maps /others


# Contact
Konrad Werys
mrkonrad.github.io
konradwerys2@gmail.com