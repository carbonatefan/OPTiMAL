### This script is published in conjunction with Eley et al., 2019.
### OPTiMAL: A new machine learning approach for GDGT-based
### palaeothermometry. Climates of the Past. Code and README housed at:
### https://github.com/carbonatefan/OPTiMAL

### This file:
  ### - Reads in a sample dataset of GDGT relative abundances and, using functions defined in FWDModelFunctions.R,
  ### - Calculates posterior predictive densities (PPDs) for each sample using the FWD model
  ### - Outputs a csv file containing the inputs and PPDs
  ### - Generates a plot showing PPD distributions for each sample

#######################
#####   WARNING   #####  
#######################

  ###   The FWD model makes temperature predictions for any and all GDGT distributions.
  ###   This includes data with contraindicative Nearest Neighbour Distances from the modern calibration dataset.
  ###   The FWD model will extrapolate to temperatures beyond the modern calibration dataset
  ###   at which point the priors (see line 49) become the primary control on the model predictions.

source("FWDModelFunctions.R")
library("ggplot2")
library("RColorBrewer")

##############################################################################################################################

  ###User Inputs###

###Read in new GDGT dataset (6 csv column GDGT)
###Demo dataset provided: Subset of Sluijs et al., 2011. doi:10.5194/cp-7-47-2011
MyDataset <- read.csv(file="./Demo.csv", header=TRUE, sep=",")

###Set the filename for the FWD model output
OutputFilename='FWDModel_Demo.csv'

###Set the filename for the FWD model output
OutputFilename2='FWDModel_PPD_Demo.png'

  ###End User Inputs###

##############################################################################################################################

  ###Compute mean SST predictions and posterior predictive distributions using the FWD model

#Load the FWD model
modelFWD=fitFWD()

#Set priors for FWD model. Recommended values from on Eley, 2019 are 15,10 (15 mean SST, plus/minus 10 (1SD) with Gaussian distribution).
prior = c(15,10)
PofX=getPofXgivenT(modelFWD)

#Run the FWD prediction
Predict_FWD_Data1=predictFWD(MyDataset, modelFWD,prior = c(15,10), PofXgivenT = PofX, returnFullPosterior = TRUE, transformed = F)

posteriorFWDpred <- posteriorFWD(MyDataset,modelFWD,Z = Predict_FWD_Data1$Z)

##############################################

  ###Export standard outputs to csv file

#Add results (Nearest Neighbour Distance and mean SST from the FWD model) to the data frame for export
MyDataset_OPTiMAL=MyDataset

#Add posteriors to the csv output file

  npoints <- length(MyDataset[,1])
  T <- cbind(MyDataset_OPTiMAL[1,],t(posteriorFWDpred[1,]))
  names(T)[-(1:6)] <- sprintf("Temp%f", seq(-10,60,len = 200))
  write.table(T, file=OutputFilename, append = FALSE, sep =",",row.names = F)
  for(j in 2:npoints){
    T <- cbind(MyDataset_OPTiMAL[j,],t(posteriorFWDpred[j,]))
    write.table(T, file=OutputFilename, append = TRUE, sep =",",col.names = F, row.names = F)
  
}

##############################################

#Plot forward model posterior predictive densities
PlotDF_FWD <- data.frame("Posterior Density"=double(),SST_FWD=double(),Sample=integer())
npoints <- nrow(posteriorFWDpred)
for(j in 1:npoints){
  PlotDF_Temp <- data.frame("Posterior Density"=posteriorFWDpred[j,],"SST_FWD"=seq(-10,60,len = 200))
  PlotDF_Temp$Sample <- j
  PlotDF_FWD <- rbind(PlotDF_FWD,PlotDF_Temp)
  
}

Plot_FWD <- ggplot() + 
  geom_point(data=PlotDF_FWD, aes(x=Sample, y=SST_FWD, color = Posterior.Density ), shape = 15,size=2) + scale_color_gradient(low = "white", high = "blue") +
  ylim(-10, 60)

print(Plot_FWD)
dev.print(png, file=OutputFilename2, width=600)
