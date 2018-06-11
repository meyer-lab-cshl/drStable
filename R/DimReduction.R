#' Compute dimensionality reduction
#'
#' @param Y [N x P] data matrix for which the dimensionality of P should be
#' reduced
#' @param method Dimensionality reduction method [string] to be applied; one of
#' DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA, 
#' nMDS, tSNE and PEER  
#' @param optN optimal number [int] of neighbours to consider for dimensionality
#' reduction; relevant for methods LLE, LaplacianEigenmaps, Isomap and tSNE. If 
#' not provided, will be estimated via \code{\link{lle::calc_k}}.
#' @param ndim maximum dimensionality [int] to retain in the data; large values
#' can cause long computation times; if not provided max(P,N) is chosen.
#' @param kmin if optN is not provided, kmin [int] specifies the minimum number
#' of neighbours supplied to  \code{\link{lle::calc_k}}
#' @param kmax if optN is not provided, kmax [int] specifies the maximum number
#' of neighbours supplied to  \code{\link{lle::calc_k}}
#' @param parallel if optN is not provided and parallel TRUE, parallel 
#' computation on multiple cpu cores is used with \code{\link{lle::calc_k}}.
#' @param verbose [logical] If set, progress messages are printed to standard 
#' out
#' @return named list of results from dimensionality reduction; if multiple 
#' methods were specified, each named list entry contains the following:
#' Y_red:  named list with dimensionality reduced phenotypes (reducedY) and 
#' object returned by specified dimensionality reduction method (results) with
#' additional output
#' M: vector [double] with Trustworthiness and Continuity estimates for the
#' dimensionality reduction
#'
#' @export
computeDimReduction <-  function(method, Y, optN=NULL, ndim=NULL, 
                                 kmin=1, kmax=40, verbose=FALSE, 
                                 parallel=FALSE) {
    # phenotype dimensions
    N <- nrow(Y)
    P <- ncol(Y)
    
    # number of dimensions to estimate
    if (is.null(ndim)) {
        if (P < N) {
            ndim <- P
        } else {
            ndim <- N
        }
    }
    if (is.null(optN) && any(method %in% c("LLE", "LaplacianEigenmaps", 
                                           "Isomap", "tSNE"))) {
        nEstimate <- ndim/10
        if (nEstimate > 100) nEstimate = 100 
        # find neighbours
        neighbours <- lle::calc_k(Y, m=nEstimate, kmin=kmin, kmax=kmax, 
                                  parallel=parallel, plotres=FALSE)
        optN <- neighbours$k[which.min(neighbours$rho)]
    }
    tmp <- lapply(method, function(m, Y, optN, ndim) {
        vmessage(c("Running dimensionality reduction:", m), verbose=verbose)
        
        # dimensionalityReduction
        red <- methodsDimReduction(Y=Y, method=m, ndim=ndim, optN=optN)
        rownames(red$reducedY) <- rownames(Y)
        colnames(red$reducedY) <- paste("DR", 1:ncol(red$reducedY), sep="")
        
        # estimate trustworthiness and continuity
        neighbours <- round(1:5 * nrow(Y)/100)
        M <- TandC(original=Y, reduced=red$reducedY, 
                   neighbours=neighbours)
        return(list(Y_red=red, M=M))
    }, Y=Y, optN=optN, ndim=ndim)
    if (length(tmp) == 1) {
        tmp <- tmp[[1]]
    } else {
        names(tmp) <- method
    }
    return(tmp)
}

#' Wrapper function for dimensionality reduction methods
#' 
#' @param Y [N x P] data matrix for which the dimensionality of P should be
#' reduced
#' @param method Dimensionality reduction method [string] to be applied; one of
#' DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA, 
#' nMDS, tSNE and PEER  
#' @param optN optimal number [int] of neighbours to consider for dimensionality
#' reduction; relevant for methods LLE, LaplacianEigenmaps, Isomap and tSNE.
#' @param ndim maximum dimensionality [int] to retain in the data; large values
#' can cause long computation times
#' @return named list with dimensionality reduced phenotypes (reducedY) and 
#' object returned by specified dimensionality reduction method (results) with
#' additional output, see details
methodsDimReduction <- function(Y, ndim, 
                                method=c("DiffusionsMaps", "DRR", "ICA", 
                                         "LLE", "Isomap", "LaplacianEigenmap", 
                                         "MDS", "PCA","kPCA", "nMDS", 
                                         "tSNE", "PEER"),
                                optN=NULL) {
    if (method == "DiffusionsMaps") {
        results <- diffusionMap::diffuse(dist(Y), neigen=ndim)
        reducedY <- results$X
    } else if (method == "DRR") {
        results <- DRR::drr(Y, ndim=ndim)
        reducedY <- results$fitted.data
    }  else if (method == "ICA") {
        results <- fastICA::fastICA(Y, n.comp=ndim, fun= "logcosh", method="C")
        #results <- ica::icajade(Y, nc=ndim)
        reducedY <- results$S
    } else if (method == "LLE") {
        results <- lle::lle(Y, k=optN, m=ndim, id=TRUE)
        reducedY <- results$Y
    } else if (method == "Isomap") {
        results <- vegan::isomap(dist(Y), ndim=100, k=optN, fragmentedOK=TRUE)
        reducedY <- results$points
    } else if (method == "LaplacianEigenmap") {
        library("dimRed")
        y <- as(as.data.frame(Y), "dimRedData")
        results <- dimRed::embed(y, 'LaplacianEigenmaps', ndim=100, knn=optN)
        reducedY <- results@data@data
    } else if (method == "MDS") {
        results <- stats::cmdscale(dist(Y), k=ndim)
        reducedY <- results  
    } else if (method == "PCA") {
        results <- stats::prcomp(Y)
        reducedY <- results$x[,1:ndim]
    } else if (method == "kPCA") {
        results <- kernlab::kpca(Y, features=ndim)
        reducedY <- results@rotated
    } else if (method == "nMDS") {
        results <- vegan::metaMDS(dist(Y), k=ndim)
        reducedY <- results$points
    } else if (method == "tSNE") {
        results <- Rtsne::Rtsne(Y, dims=ndim, initial_dims=ndim, 
                                perplexity=optN)
        reducedY <- results$Y
    } else if (method == "PEER") {
        model = peer::PEER()
        # Set observed data
        peer::PEER_setPhenoMean(model, Y)
        peer::PEER_setAdd_mean(model, TRUE)
        peer::PEER_setNk(model, 100)
        peer::PEER_setNmax_iterations(model, 1000)
        peer::PEER_update(model)
        results <- list(Y=peer::PEER_getX(model)[,-1], W=peer::PEER_getW(model), 
                        precision=peer::PEER_getAlpha(model))
        reducedY <- results$Y
    } else {
        stop("Method: ", method, " does not exist, possible methods are: ",
             "DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS,",
             "PCA,", "kPCA, nMDS, tSNE and PEER")
    }
    return(list(reducedY=reducedY, results=results))
}


