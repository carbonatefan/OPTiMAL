# OPTiMAL

This directory contains code to predict sea surface temperatures from the relative abundances of GDGTs using two methodologies (GPR model and FWD model) as described in:

*OPTiMAL: A new machine learning approach for GDGT-based palaeothermometry\
Yvette Eley, Will Thomson, Sarah Greene, Ilya Mandel, Kirsty Edgar, James Bendle, and Tom Dunkley Jones\
Climate of the Past Discussions.*\
[doi:10.5194/cp-2019-60](https://doi.org/10.5194/cp-2019-60)

The GPR model, with its built-in nearest neighbour distance screening (together called 'OPTiMAL'), is recommended as the default method for predicting SSTs from GDGT distributions. The FWD model is provided as an avenue for potential future development. See manuscript for further details.

## Getting Started

This repository contains all of the code and files you will need to run both the GPR model and the FWD model. Start by downloading or cloning this repository in its entirety. The contents are as follows:

**README.md**: The readme you are currently reading.\
**OPTiMAL.m**: Calculates Nearest Neighbour Distances and temperatures using the GPR model.\
**FWDModel.R**: Calculates temperatures (posterior predictive density distributions) using the FWD model.\
**FWDModelFunctions.R**: Contains the functions necessary to execute the FWD Model.\
**CalibrationOp1.csv**: Recommended modern calibration dataset (default setting), combining the full core-top data of Tierney & Tingley (2015) [doi.org/10.1038/sdata.2015.29](https://doi.org/10.1038/sdata.2015.29) with additional data from Seki et al. (2014) [doi.org/10.1016/j.pocean.2014.04.013](https://doi.org/10.1016/j.pocean.2014.04.013). See **Note 1**.\
**CalibrationOp2.csv**: Same as Op1 but excludes data from Seki et al. (2014).\
**CalibrationOp3.csv**: Same as Op1 but excludes Arctic locations with observed SSTs below 3ºC.\
**Demo.csv**: Demo GDGT dataset. (Subset of Sluijs et al., 2011, [doi:10.5194/cp-7-47-2011](https://doi.org/10.5194/cp-7-47-2011)).\
**mf6.npy**: FWD model (built in python) using the modern calibration dataset. See **Note 2**.\
**ghWeightsNodes.csv**: Weighting file required by the FWD model.

**Notes**:
1. Default calibration data is based on the compiled dataset of Tierney & Tingley 2015 [Global TEX86 Surface Sediment Database v.1.0](https://www.ncdc.noaa.gov/paleo-search/study/18615)). Only sampling locations with full abundance records of GDGT-0 to GDGT-3, Crenarchaeol and the isomer of Crenarchaeol, could be used for the calibration of OPTiMAL. The data from Seki et al. (2014) is included in Tierney and Tingley 2015, but not with the abundances of GDGT compounds. These primary data were obtained directly from Osamu Seki for the purposes of this study and are included in the OPTiMAL calibration dataset.
2. If downloading the entire repository as a zipped file, the file mf6.npy will need to be downloaded separately and added to your OPTiMAL directory manually. It is a large file (~600 MB) and so it is stored remotely and will not be captured by a zipped download.


## Prerequisites
### GPR model ('OPTiMAL')
Running the GPR model will require MATLAB (back compatible to version 2015b). 

* [MATLAB](https://mathworks.com/products/matlab.html)

### FWD model
Running the FWD model requires R (RStudio recommended) and Python or Anaconda (directions provided for installing the required packages with or without Anaconda are provided).

* [R](https://www.r-project.org/)
* [RStudio](https://www.rstudio.com/)
* [Python](https://www.python.org/) or [Anaconda](https://www.anaconda.com/), which includes a python download

The FWD model requires the Python [GPy library](https://sheffieldml.github.io/GPy/). This only needs to be installed once. To install via anaconda, open the anaconda prompt and at the command line enter:

	conda update scipy

followed by:

	conda install -c conda-forge gpy

Or, without anaconda, by first installing [pip](https://pypi.org/project/pip/) and then entering:

	!pip install GPy

at the python command line.

The FWD model also requires the R packages reticulate, robCompositions, ggplot2, and RColorBrewer. These only need to be installed once. At the RStudio command line enter: 
	
	install.packages("reticulate")
	install.packages("robCompositions")
	install.packages("ggplot2")
	install.packages("RColorBrewer")

Lastly, you will need to direct R to your python path. Open the R script FWDModelFunctions.R, set this path on line 15 and save.

## Running the Models
### GPR model ('OPTiMAL')

To run the GPR model on the demo dataset, simply open and run OPTiMAL.m. This will load the provided modern calibration dataset: 

```
CalibrationOp1.csv
```

and the provided demo dataset:

```
demo.csv
```
and will return:

1) A new csv file containing the GDGT data from the demo dataset, the nearest neighbour distances to the modern calibration dataset, predicted SST, and 1 standard deviation on the SST prediction (error is Gaussian).
2) A plot of the predicted error (1 standard deviation) vs. the nearest neighbour distances for the demo dataset.
3) A plot of the predicted temperature with error bars (1 standard deviation) vs. sample number. Samples failing the nearest neighbour screening (>0.5) are plotted in grey; samples passing the screening test are coloured according to their nearest neighbour distance.

To predict temperatures from a new dataset, format your GDGT fractional abundance dataset using the demo dataset as a guide and save it as a csv file in the same directory. Then open OPTiMAL.m, change the filename loaded in line 28, set your desired output file names in lines 37-39, and run the script. You can also change the modern calibration dataset in line 34; CalibrationOp1 is recommended and set as the default.

### FWD model

To run the FWD model on the demo dataset, set the correct working directory and execute the script FWDModel in RStudio. This will load

```
ghWeightsNodes.csv
```
and
```
mf6.npy
```
as well as the demo dataset
```
Demo.csv
```
and, using functions contained in

```
FWDModelFunctions.R,
```

will return:

1) A spreadsheet containing the raw GDGT data from the sample dataset plus the posterior predicted density distribution (non-Gaussian error) for each sample.
2) A plot of predicted temperature vs. sample number, with the posterior predictied density shaded in blue.

To predict temperatures from a new dataset, format your GDGT fractional abundance dataset using the demo dataset as a guide and save it in the same directory. Then open FWDModeL.R, change the file name loaded in line 31, set your desired output file names in lines 34 and 37, and run the script.

NOTE: The FWD model will make temperature predictions for samples with contraindicative Nearest Neighbour Distances. Screening your data by nearest neighbour distance using the MATLAB code OPTiMAL.m is recommended. It will also extrapolate to temperatures beyond the modern calibration dataset, at which point the priors (see line 49 in FWDModel.R) become the primary control on the posterior predictive density distributions. 

## Publishing outputs from this code

Publications using this code should cite Eley et al., 2019 and this github repository. In addition, the following data are required to ensure your work is reproducible:
1) Full relative abundance data for all 6 GDGT compounds
2) Citation of modern calibration dataset used
3) Publication of full calibration dataset if it has not been previously published elsewhere

## Authors

* Ilya Mandel
* Will Thomson
* Sarah Greene
