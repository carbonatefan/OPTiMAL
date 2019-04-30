%%%% This script is published in conjunction with Eley et al., 2019.
%%%% OPTiMAL: A new machine learning approach for GDGT-based
%%%% palaeothermometry. Climates of the Past. Code and README housed at:
%%%% https://github.com/carbonatefan/OPTiMAL

%%%% This file:
    %%%% Reads in a modern calibration dataset, and an ancient GDGT dataset.
    %%%% Returns a csv file with Nearest Neighbour distances and
    %%%% temperature predictions from the GPR.
    %%%% Returns a plot of the predicted error (1 standard deviation) vs.
    %%%% the nearest neighbour distances for the ancient dataset.
    %%%% Returns a plot of the predicted temperature with error bars (1
    %%%% standard deviation) vs. sample number.

%%%% The expected file format is the following columns in order: 
    %%%% Modern Calibration Dataset: GDGT0 GDGT1 GDGT2 GDGT3 Cren Cren' Temp
    %%%% Ancient Dataset: GDGT0 GDGT1 GDGT2 GDGT3 Cren Cren'
    %%%% GDGT data must be formatted as fractional abundances (summing to 1)

clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%User Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Read in datasets
%Demo dataset provided: Subset of Sluijs et al., 2011. doi:10.5194/cp-7-47-2011 
ancient=csvread('Demo.csv',1,0); %If your csv does not contain a header row, remove ,1,0 leaving only the filename (in single quotes) in the parentheses
%Modern calibration dataset provided: Tierney and Tingley, 2015, doi:10.1038/sdata.2015.29
modern=csvread('ModernCalibration.csv',1,0);

%Set filenames for outputs
OPTiMAL_Results='OPTiMAL_Demo.csv'; % csv file containing original GDGT data plus Nearest Neighbour distance, SST prediction, and 1 StDev
Plot1='OPTiMALNearestNeighbour_Demo.png'; % Plot of 1 St Dev for temperature predictions vs. nearest neighbour distances for ancient dataset
Plot2='OPTiMALReconstructedSST_Demo.png'; % Plot of Reconstructed SST (+ 1StDev) vs. Sample Number (row) for the ancient dataset

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%End user Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Calibrate GP regression on full modern data set
gprMdl = fitrgp(modern(:,1:6),modern(:,7),...
        'KernelFunction','ardsquaredexponential',...
        'KernelParameters',std(modern(:,[1:6,7])),'Sigma',std(modern(:,7)));
gprMdl.KernelInformation.KernelParameters./(std(modern(:,[1:6,7])))';   
[tempmodern,tempmodernstd,tempmodern95]=predict(gprMdl,modern(:,1:6));
sigmaL = gprMdl.KernelInformation.KernelParameters(1:end-1); % Learned length scales
weights = exp(-sigmaL); % Predictor weights
weights = weights/sum(weights);

%Apply GP regression to ancient data set
[tempancient,tempancientstd,tempancient95]=predict(gprMdl,ancient(:,1:6),'Alpha',0.05);

%Determine weighted nearest neighbour distances
for(i=1:length(ancient)),
    for(j=1:length(modern)),
            dist=(modern(j,1:6)-ancient(i,1:6))./sigmaL';
            distsq(j)=sqrt(sum(dist.^2));
    end;
    [distmin(i),index(i)]=min(distsq);
end;

%Create figure - Standard error vs. DNearest
figure
set(gca, 'FontSize', 12); 
semilogx(distmin,tempancientstd,'.', 'MarkerSize', 16); hold on;
plot(0.5*ones(size([3:9])),[3:9],'k:', 'LineWidth', 2); hold off;
grid on
xlabel('$D_\mathrm{nearest}$','Interpreter', 'latex')
ylabel('St. Dev. Reconstructed Temp. (°C)')
saveas(gcf,Plot1)

%Create figure - OPTiMAL temperature vs. sample number
figure
SampleNumber=1:length(tempancient);
set(gca, 'FontSize', 12);
hold on
for (j=1:length(SampleNumber)),
    if (distmin(j)<0.5),
        plot([SampleNumber(j),SampleNumber(j)], [tempancient(j)-tempancientstd(j),tempancient(j)+tempancientstd(j)],'-k','LineWidth',1),
    else
        plot([SampleNumber(j),SampleNumber(j)], [tempancient(j)-tempancientstd(j),tempancient(j)+tempancientstd(j)],'-','color', [0.8 0.8 0.8], 'LineWidth',0.5),
    end
end
scatter(SampleNumber(distmin>=0.5),tempancient(distmin>=0.5), 15, [0.8 0.8 0.8], 'filled');
scatter(SampleNumber(distmin<0.5),tempancient(distmin<0.5), 25, (distmin(distmin<0.5)), 'filled');
c = colorbar;
xlabel('Sample Number'),
ylabel('Reconstructed SST (°C)');
c.Label.String = 'D_{nearest}';
saveas(gcf,Plot2)

%Output csv file with results
output=[ancient distmin' tempancient tempancientstd];
col_header={'GDGT.0', 'GDGT.1', 'GDGT.2', 'GDGT.3', 'Crenarchaeol', 'Cren.', 'D_nearest', 'SST', 'StDev'}; 
fileID=fopen(OPTiMAL_Results, 'w');
fprintf(fileID, '%s, ', col_header {:});
fprintf(fileID, '\n');
fprintf(fileID, '%f, %f, %f, %f, %f, %f, %f, %f, %f \n', output');
fclose(fileID);
