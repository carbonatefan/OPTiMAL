# OPTiMAL

This directory contains code to predict sea surface temperatures from the relative abundances of GDGTs using two methodologies (GPR model and FWD model) as described in:
OPTiMAL: A new machine learning approach for GDGT-based palaeothermometry
by Yvette Eley, Will Thomson, Sarah Greene, Ilya Mandel, Kirsty Edgar, James Bendle, and Tom Dunkley Jones
Submitted to Climates of the Past.
doi:

## Getting Started

This repository contains all of the code and files you will need to run both the GPR model and the FWD model. Start by downloading this repository in its entirety. The contents are as follows:

CONTENTS???

### Prerequisites

Running the GPR model will require MATLAB. Running the FWD model requires R (RStudio recommended).

* [MATLAB](https://mathworks.com/products/matlab.html)
* [R](https://www.r-project.org/)
* [RStudio](https://www.rstudio.com/)

### GPR model

To run the GPR model, start by simply running OPTiMAL.m. This will load the provided modern calibration dataset: 

```
ModernCalibrations.xlsx
```

And the provided sample dataset (citation):

```
SampleDataset.xlsx
```
and will return

```
1) A new spreadsheet containing the GDGT data from the sample dataset, the nearest neighbour distances to the modern calibration dataset, predicted SST, and 1 standard deviation on the SST prediction (error is Gaussian)
2) A plot of the predicted error (1 standard deviation vs. the nearest neighbour distances for the sample dataset
3) A plot of the predicted temperature (with 1 standard deviation error bars) vs. sample number. Samples failing the nearest neighbour screening (>0.5) are plotted in grey; samples passing the screening test are coloured according to their nearest neighbour distance
```
To run a new dataset, simply format your dataset like the sample spreadsheet and save it in the same folder. Then open OPTiMAL.m and change the spreadsheet name and output file names in lines xxx and run the script.

### FWD model

Explain what these tests test and why

```
Give an example
```

## Publishing outputs from this code

Publications using this code should cite Eley et al., 2019. In addition, the following data are required to ensure your work is reproducible:
1) Full relative abundance data for all 6 GDGT compounds
2) Citation of modern calibration dataset used
3) Publication of full calibration dataset if it has not been previously published elsewhere

## Authors

* **Ilya Mandel**
* **Will Thomson**
* **Sarah Greene**

## Citation

* Put DOI here.
