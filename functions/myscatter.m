function mystring3=myscatter(data1,data2,plottype,labels,options)
%myscatter - function that concquers the world. Be carefull.
%
%   Konrad Werys, Feb 2016   
%   konradwerys@gmail.com    
%   <mrkonrad.github.io>     

if ~exist('plottype','var')
    plottype = 'scatter';
end

if ~exist('labels','var')
    labels.title = '';
    labels.x = 'data1';
    labels.y = 'data2';
end
if ~isfield(labels,'stats')
    labels.stats = 'y';
end

if ~exist('options','var')
    options.markersize=3;
    options.parametric=0;
    options.symaxis=0;
end

data12isnan = isnan(data1)|isnan(data2);
data1(data12isnan)=[];
data2(data12isnan)=[];

qdata1=quantile(data1,[.5,.25,.75]);
qdata2=quantile(data2,[.5,.25,.75]);

[h_norm1,p_norm1] = swtest(data1);
[h_norm2,p_norm2] = swtest(data2);

myICC = ICC([data1,data2],'A-1');
[R_pearson,P_pearson]=corr(data1,data2,'type','Pearson','rows','complete');
[R_spearman,P_spearman]=corr(data1,data2,'type','Spearman','rows','complete');

mymean = nanmean(data1-data2);
mystd = nanstd(data1-data2);
mystd1 = mymean-mystd*1.96;
mystd2 = mymean+mystd*1.96;

mystring1=sprintf('%s',labels.title);

if options.parametric
    mystring4=sprintf('R=%.2f',R_pearson);
else
    mystring4=sprintf('rho=%.2f',R_spearman);
end

mystring2=sprintf('%s',labels.title);
if strfind(labels.stats,'y')
    mystring1 = sprintf('%s\n ICC=%.2f R=%.2f rho=%.2f\n p_R=%.4f p_{rho}=%.4f',labels.title,myICC,R_pearson,R_spearman,P_pearson,P_spearman);
    mystring2 = sprintf('%s\nmean difference: %.2f \nstd difference %.2f',labels.title,mymean,mystd);
end

if nanmedian(data1)<10
    format1 = '%1.2f (%1.2f -- %1.2f)';
    format2 = '%1.2f $\\pm$ %1.2f';
else
    format1 = '%2.1f (%2.1f -- %2.1f)';
    format2 = '%2.1f $\\pm$ %2.1f';
end
mystring3=sprintf([format1,' & ', format1,' & %5.2f $\\pm$% 5.2f & %6.2f '],...
    quantile(data1,[.5 .25 .75]),quantile(data2,[.5 .25 .75]),abs(mymean),mystd,myICC);


p=polyfit(data1,data2,1);
yfit=polyval(p,data1);
[r2 rmse] = rsquare(data2,yfit);

if p(2)>=0
mystring5 = sprintf('y=%.2fx+%.2f',p(1),p(2));
else
    mystring5 = sprintf('y=%.2fx%.2f',p(1),p(2));
end

switch plottype
    case {'scatter','S','s'}
        hold on
        %scatter(data1,data2,.1,'MarkerFaceColor',[.1 .5 .9],'MarkerEdgeColor',[.1 .5 .8])
        plot(data1,data2,'o','MarkerSize',options.markersize,'MarkerFaceColor',[.1 .5 .9],'MarkerEdgeColor',[.1 .5 .8])
        %scatter(data1,data2,40,'MarkerFaceColor',[.9 .9 .9])
%         ylim([min([data1;data2]),max([data1;data2])]);
%         xlim([min([data1;data2]),max([data1;data2])]);
        myylim=ylim;
        myxlim=xlim;


        if isfield(options,'axis')
            axis(options.axis);
        end
        if isfield(options,'symaxis') && options.symaxis
            xlim([min(myylim(1),myxlim(1)),max(max(data1),max(data2))*1.1]);
            ylim([min(myylim(1),myxlim(1)),max(max(data1),max(data2))*1.1])
        end
        if isfield(options,'zeroaxis') && options.zeroaxis
            xlim([0,myxlim(2)]);
            ylim([0,myylim(2)*1.25])
        end
        if options.parametric
            plot(xlim,polyval(p,xlim),'linewidth',1,'Color',[.3 .3 .3])
        end
        hold off   
        myylim=ylim;
        myxlim=xlim;
        title(mystring1,'Tag','title','FontWeight','bold')
        text(myxlim(1)+diff(myxlim)*.05,myylim(2)-diff(myylim)*.05,mystring4,'tag','corr')
        text(myxlim(1)+diff(myxlim)*.05,myylim(2)-diff(myylim)*.15,mystring5,'tag','corr')
        xlabel(labels.x)
        ylabel(labels.y)
    case {'Bland-Altman','BA','ba'}
        plot((data1+data2)/2,data1-data2,'o')
        xxx = xlim;
        hold on
        plot([xxx(1) xxx(2)],[mymean mymean],'r');
        plot([xxx(1) xxx(2)],[mystd1 mystd1],'--m');
        plot([xxx(1) xxx(2)],[mystd2 mystd2],'--m');
        hold off
        title(mystring2,'tag','title')
        xlabel('Average')
        ylabel('Difference')
end

if ~strcmp(plottype,'')
    fprintf('Data1 (0=normal) %d p=%.4f\n',h_norm1,p_norm1)
    fprintf('Data2 (0=normal) %d p=%.4f\n',h_norm2,p_norm2)
    fprintf('%s %s %.1f ( %.1f - %.1f)\n',labels.title,labels.x,qdata1)
    fprintf('%s %s %.1f ( %.1f - %.1f)\n',labels.title,labels.y,qdata2)
    fprintf(' data1                  & data2                   & mean diff+SD & CV    & rho    &   ICC\n')
    fprintf('%s\n',mystring3)
    clipboard('copy', mystring3);
end





