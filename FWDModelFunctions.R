### This script is published in conjunction with Eley et al., 2019.
### OPTiMAL: A new machine learning approach for GDGT-based
### palaeothermometry. Climates of the Past. Code and readme housed at:
### https://github.com/carbonatefan/OPTiMAL

### This script is called by FWDModel.R and contains functions to:
  ### - fit the forward model (fitFWD)
  ### - make predictions from the forward model (predictFWD)
  ### - extract full posterior predictive distributions (posteriorFWD)

### You will need to install Python and also the GPy library for Python 
### This code is based on Python 3.6.

### Point to your Python distribution
Sys.setenv(RETICULATE_PYTHON = "C:\\Anaconda3\\python.exe")

require(reticulate)

np <- import("numpy")

### import weights and nodes for 500-point Gauss-Hermite quadrature

weightsAndNodes <- read.csv("ghWeightsNodes.csv")[,2:3]


### This function loads a pre-exiting forward model (Tierney and Tingley, 2015, https://doi.org/10.1038/sdata.2015.29)

fitFWD <- function(){
  
    message('Loading MOGP model object based on all 6 GDGTs')
    mf <- np$load('mf6.npy')[[1]]
  
  return(mf)
  
}

### make predictions from the forward model
### inputs: newX :- a matrix or data.frame of GDGT values
###         model :- a model object obtained via fitFWD()
###         prior :- a 2-vector containing the mean and sd of the Gaussian prior on
###                  temperature. Defaults to (15,10)
###         PofXgivenT :- a list containing means, invcovs, dets of p(X|T_j) for each
###                       Gauss-Hermite node T_j
###         returnFullPosterior :- one of:
###                       - FALSE (default): only return means and variances
###                       - A vector of indices for which full posterior should be computed
###                       - TRUE: return full posterior for every new point
###         transformed :- logical value indicating whether the data in newX has been ilr transformed.

predictFWD <- function(newX,
                       model,
                       prior = c(15,10),
                       PofXgivenT = NULL,
                       returnFullPosterior = FALSE,
                       transformed = F){
  
  dd <- max(model$Y_metadata[[1]]) + 1
  npred <- nrow(newX)
  
  
  if(ncol(newX) != (dd + 1)){
    stop("newX has the wrong number of columns")
  }
  
  if(returnFullPosterior){
    returnFullPosterior <- 1:npred
  }
  
  whichzerorows <- NULL
  
  if(!transformed){
    if(npred > 2*dd){
      message("Loading required package robCompositions")
      require(robCompositions)
      message("Imputing zeros")
      newX[newX == 0] <- NA
      newX <- impCoda(newX)$xImp
    } else{
      message("Not enough data points to impute zeros; removing rows containing zeros")
      whichzerorows <- which(apply(newX,1,function(x) any(x == 0)))
    }
    message("ilr transforming the data")
    newX <- as.matrix(pivotCoord(newX))
    
  }
  
  
  ## 500 node Gauss-Hermite quadrature (straightforward to use fastGHquad package to
  ## change this if desired)
  
  n_nodes <- 500
  
  xx <- sqrt(2) * prior[2] *weightsAndNodes$x + prior[1]
  
  if(!is.null(returnFullPosterior)){
    priorAtNodes <- dnorm(xx,prior[1],prior[2])
  }
  ww <- weightsAndNodes$w
  
  if(is.null(PofXgivenT)){
    warning("For speed on repeated runs, it is recommended to provide PofXgivenT, 
            which can be obtained via getPofXgivenT()")
  
  inds <- as.integer(0:(dd-1))
  noise_dict <- dict(list(output_index = matrix(inds,dd,1)))
  
  message("Computing p(X|T) at each quadrature node...")
  pb <- txtProgressBar(0,n_nodes)
  
  means <- matrix(NA,n_nodes,dd)
  invcovs <- array(NA,c(n_nodes,dd,dd))
  dets <- rep(NA,n_nodes)
  for(j in 1:n_nodes){
    X <- rep(xx[j],5)
    X <- cbind(X,inds)
    tmpp <- model$predict(X,Y_metadata=noise_dict,full_cov = TRUE)
    means[j,] <- tmpp[[1]]
    cholInvCov <- chol(tmpp[[2]])
    invtmp = chol2inv(cholInvCov)
    invcovs[j,,] = invtmp
    dets[j] = prod(diag(cholInvCov)^2)
    setTxtProgressBar(pb,j)
  }
  
  message("DONE")
  } else{
    means = PofXgivenT$means
    invcovs = PofXgivenT$invcovs
    dets = PofXgivenT$dets
  }
  
  posterior_means <- rep(NA,npred)
  posterior_vars <- rep(NA,npred)
  full_posteriors <- list()
  Zout <- rep(NA,npred)
  
  message("Computing p(T|X) for new data...")
  pb <- txtProgressBar(0,npred)
  
  for(i in which(!((1:npred)%in%whichzerorows))){
    ff <- rep(NA,n_nodes)
    xi <- newX[i,]
    for (j in 1:n_nodes){
      ### evaluate multivariate Gaussian density at i-th  ######################
      ### composition, at j-th temperature node, p(x_i|T_j) ####################
      ##########################################################################
      qf <- t(xi - means[j,])%*%invcovs[j,,]%*%(xi - means[j,])   ##############
      ff[j] <- exp(-0.5 * qf) / sqrt((2 * pi)^dd * dets[j])       ##############
      ##########################################################################
    }
      
    ## compute normalising factor, int p(t) dt, by Gauss-Hermite quadrature
    Z <- t(ww)%*%ff
      
    mu <- t(ww)%*%(ff*xx) / Z ## Gauss-Hermite quadrature again
    posterior_means[i] <- mu
    posterior_vars[i] <- t(ww)%*%(ff * (xx - rep(mu,n_nodes))^2) / Z
    Zout[i] <- Z
    if(i %in% returnFullPosterior){
      full_posteriors[[i]] <- data.frame(xx = xx,posterior = (ff * priorAtNodes) / rep(Z,n_nodes))
    }
    setTxtProgressBar(pb,i)
  }
  message("DONE")
  
  if(!is.null(whichzerorows)){
    message(paste("Predictions not made for points",whichzerorows,
                  "because they contained zero entries"))
  }
  
  return(list(variance = posterior_vars,
              full_posteriors = full_posteriors,
              Z = Zout,
              transformedData = newX))
  
}

#### Function to obtain densities p(X|T) at the quadrature nodes 

getPofXgivenT <- function(model){
  dd <- max(model$Y_metadata[[1]]) + 1
  
  ## 500 node Gauss-Hermite quadrature (straightforward to use fastGHquad package to
  ## change this if desired)
  
  n_nodes <- 500
  
  xx <- sqrt(2) * prior[2] *weightsAndNodes$x + prior[1]
  ww <- weightsAndNodes$w
  
  inds <- as.integer(0:(dd-1))
  noise_dict <- dict(list(output_index = matrix(inds,dd,1)))
  
  message("Computing p(X|T) at each quadrature node...")
  pb <- txtProgressBar(0,n_nodes)
  
  means <- matrix(NA,n_nodes,dd)
  invcovs <- array(NA,c(n_nodes,dd,dd))
  dets <- rep(NA,n_nodes)
  for(j in 1:n_nodes){
    X <- rep(xx[j],5)
    X <- cbind(X,inds)
    tmpp <- model$predict(X,Y_metadata=noise_dict,full_cov = TRUE)
    means[j,] <- tmpp[[1]]
    cholInvCov <- chol(tmpp[[2]])
    invtmp = chol2inv(cholInvCov)
    invcovs[j,,] = invtmp
    dets[j] = prod(diag(cholInvCov)^2)
    setTxtProgressBar(pb,j)
  }
  
  return(list(means = means,invcovs = invcovs,dets = dets))

}


#### Compute the (unnormalised) posterior predictive density at the specified
#### points for the data points in newX.
#### Z is a vector of normalising constants (which can be obtained via predictFWD()).
#### transformed is a logical input indicating whether newX contains transformed data.

posteriorFWD <- function(newX,model,points = seq(-10,60,len = 200),
                                     prior = c(15,10),Z = NULL, transformed = FALSE){
  dd <- max(model$Y_metadata[[1]]) + 1
  
  npoints <- length(points)
  npred <- nrow(newX)
  
  priorAtPoints <- dnorm(points,prior[1],prior[2])
  
  inds <- as.integer(0:(dd-1))
  noise_dict <- dict(list(output_index = matrix(inds,dd,1)))
  whichzerorows <- NULL
  
  if(!transformed){
    if(npred > 2*dd){
      message("Loading required package robCompositions")
      require(robCompositions)
      message("Imputing zeros")
      newX[newX == 0] <- NA
      newX <- impCoda(newX)$xImp
      } else{
        whichzerorows <- which(apply(newX,1,function(x) any(x == 0)))
      }
      message("ilr transforming the data")
      newX <- as.matrix(pivotCoord(newX))
  
  }
  
  
  means <- matrix(NA,npoints,dd)
  invcovs <- array(NA,c(npoints,dd,dd))
  dets <- rep(NA,npoints)
  for(j in 1:npoints){
    X <- rep(points[j],5)
    X <- cbind(X,inds)
    tmpp <- model$predict(X,Y_metadata=noise_dict,full_cov = TRUE)
    means[j,] <- tmpp[[1]]
    cholInvCov <- chol(tmpp[[2]])
    invtmp = chol2inv(cholInvCov)
    invcovs[j,,] = invtmp
    dets[j] = prod(diag(cholInvCov)^2)
  }
  
  PPD <- matrix(NA,npred,npoints)
  
  for(i in which(!((1:npred)%in%whichzerorows))){
    ff <- rep(NA,npoints)
    xi <- newX[i,]
    for (j in 1:npoints){
      ### evaluate multivariate Gaussian density at i-th  ######################
      ### composition, at j-th temperature node, p(x_i|T_j) ####################
      ##########################################################################
      qf <- t(xi - means[j,])%*%invcovs[j,,]%*%(xi - means[j,])   ##############
      ff[j] <- exp(-0.5 * qf) / sqrt((2 * pi)^dd * dets[j])       ##############
      ##########################################################################
    }
    PPD[i,] <- ff*priorAtPoints / (ifelse(!is.null(Z),Z[i],1))
  }
  
  if(!is.null(whichzerorows)){
    message(paste("Predictions not made for points",whichzerorows,
                  "because they contained zero entries"))
  }
  return(PPD)
}
