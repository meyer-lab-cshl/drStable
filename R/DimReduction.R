#' Compute dimensionality reduction
#'
#' Compute low-dimensional representation of dataset.
#'
#' @param Y \[N x P\] data matrix for which the dimensionality of P should be
#' reduced
#' @param method Dimensionality reduction method [character] to be applied; one
#' of DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA,
#' nMDS, tSNE and UMAP.
#' @param optN optimal number [integer] of neighbours to consider for
#' dimensionality reduction; relevant for methods LLE, LaplacianEigenmaps,
#' Isomap and tSNE. If not provided, will be estimated via
#' \code{\link[lle]{calc_k}}.
#' @param ndim maximum dimensionality [integer] to retain in the data; large
#' values can cause long computation times; if not provided max(P,N) is chosen.
#' @param kmin if optN is not provided, kmin [integer] specifies the minimum
#' number of neighbours supplied to  \code{\link[lle]{calc_k}}.
#' @param kmax if optN is not provided, kmax [integer] specifies the maximum
#' number of neighbours supplied to  \code{\link[lle]{calc_k}}.
#' @param parallel [logical] if optN is not provided and parallel TRUE, parallel
#' computation on multiple cpu cores is used with \code{\link[lle]{calc_k}}.
#' @param verbose [logical] If set, progress messages are printed to standard
#' out.
#' @param is.list.ellipsis [logical] if ... arguments are provided as list, set
#' TRUE.
#' @param ... Additional arguments passed to dimensionality reduction methods.
#' For possible arguments, check function decomentation. See details for 
#' relevant packages and functions.
#' @return named list of results from dimensionality reduction:
#' Y_red:  named list with dimensionality reduced phenotypes (reducedY) and
#' object returned by specified dimensionality reduction method (results) with
#' additional output
#' M: vector [double] with Trustworthiness and Continuity estimates for the
#' dimensionality reduction
#'
#' @export
#' @examples
#' # Generate some data
#' x <- matrix(rnorm(10000), nrow=10, ncol=100)
#' y <- x %*% diag(nrow=100) * rnorm(100)
#' dr <- computeDimReduction(y, method="MDS")
computeDimReduction <-  function(Y, method, optN=NULL, ndim=NULL,
                                 kmin=1, kmax=40, verbose=FALSE,
                                 parallel=FALSE, is.list.ellipsis=FALSE,...) {
    params <- list(...)
    if (length(params) == 0) {
        params <- NULL
    } else {
        if (is.list.ellipsis) params <- params[[1]]
    }

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
        if (method == "MDS") {
            ndim <- ndim -1
        }
    }

    if (ndim > P) {
        stop("ndim has to less than or equal to original column dimension")
    }

    if (is.null(optN) && any(method %in% c("LLE", "LaplacianEigenmap",
                                           "Isomap", "tSNE"))) {
        vmessage(c("Estimating number of neighbours for", method),
                 verbose=verbose)
        nEstimate <- ndim/10
        if (nEstimate > 100) nEstimate = 100
        # find neighbours
        neighbours <- lle::calc_k(Y, m=nEstimate, kmin=kmin, kmax=kmax,
                                  parallel=parallel, plotres=FALSE)
        optN <- neighbours$k[which.min(neighbours$rho)]
    }
    if (any(method %in% c("LLE", "LaplacianEigenmaps", "Isomap", "tSNE"))) {
        vmessage(c("Number of neighbours for ", method, ":", optN),
                sep="", verbose=verbose)
    }

    vmessage(c("Running dimensionality reduction:", method), verbose=verbose)

    # dimensionalityReduction
    red <- methodsDimReduction(Y=Y, method=method, ndim=ndim, optN=optN,
        params=params)
    rownames(red$reducedY) <- rownames(Y)
    colnames(red$reducedY) <- paste("DR", 1:ncol(red$reducedY), sep="")

    # estimate trustworthiness and continuity
    neighbours <- round(1:5 * nrow(Y)/100)
    M <- TandC(original=Y, reduced=red$reducedY,
               neighbours=neighbours)
    return(list(Yred=red$reducedY, M=M, additionalResults=red$results))
}

#' Check optional dimensionaloty reduction method parameters
#'
#' Checks if optional parameters passed to dimensionality reduction method are
#' valid and returns a list of all default and optinally set parameters.
#'
#' @param params [list] of parameters to check; list names must be identical
#' to argument names of chosen dimensionality reduction method.
#' @param method Dimensionality reduction method [character] to be applied; one
#' of DiffusionMap, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA,
#' nMDS, tSNE and UMAP.
#' @export
#' @return named list with default and specified parameters taken by specified
#' dimensionality reduction method
#' @examples
#' params_DRR <- checkParams(list(cv.folds=10), method="DRR")
#' params_ICA <- checkParams(list(fun="logcosh", maxit=500), method="ICA")
#' @details checkParams checks if specified parameters are valid parameters of
#' the underlying dimensionality reduction methods. A list of the methods is
#' provided below:
#' * Diffusion Map: \code{\link[diffusionMap]{diffuse}}
#' * Dimensionality reduction by regression (DRR): \code{\link[DRR]{drr}}
#' * Independent component analysis (ICA): \code{\link[fastICA]{fastICA}}
#' * Local liner embedding (LLE): \code{\link[lle]{lle}}
#' * Isomap: \code{\link[vegan]{isomap}}
#' * Laplacian Eigenmap: \code{\link[loe]{spec.emb}} and
#'   \code{\link[loe]{make.kNNG}}
#' * Multi-dimensional scaling (MDS) : \code{\link[stats]{cmdscale}}
#' * Principal component analysis (PCA): \code{\link[stats]{prcomp}}
#' * Kernel PCA (kPCA): \code{\link[kernlab]{kpca}}
#' * non-metrix MDS (nMDS): \code{\link[vegan]{metaMDS}}
#' * t- stochastic neighbourhood embedding (tSNE): \code{\link[Rtsne]{Rtsne}}
#' * Uniform manifold approximation and projection (umap):
#'    \code{\link[umap]{umap}}
#' @md
checkParams <- function(params, method) {
    if (method == "DiffusionMap") {
        optionalParams <- list(eps.val="epsilonCompute(D)", neigen=NULL, t=0,
            maxdim=50, delta=10^-5)
    } else if (method == "DRR") {
        optionalParams <- list(lambda=c(0, 10^(-3:2)), kernel="rbfdot",
            kernel.pars=list(sigma = 10^(-3:4)), pca=TRUE, pca.center=TRUE,
            pca.scale=FALSE, fastcv=FALSE, cv.folds=5, fastcv.test=NULL,
            fastkrr.nblocks=4)
    } else if (method == "ICA") {
        optionalParams <- list(alg.typ=c("parallel", "deflation"),
            fun=c("logcosh", "exp"), alpha=1, method=c("R", "C"), row.norm=FALSE,
            maxit=200, tol=1e-04, w.init=NULL)
    } else if (method == "LaplacianEigenmap") {
        optionalParams <- list(k='as.integer(2 * log(nrow(DM)))', sym=FALSE,
            weight=FALSE, p=NULL, norm=FALSE)
    } else if (method == "LLE") {
        optionalParams <- list(reg=2, ss=FALSE,p= 0.5, id=FALSE, nnk=TRUE,
            eps=1, iLLE=FALSE, v=0.99)
    } else if (method == "Isomap") {
        optionalParams <- list(epsilon=NULL, path="shortest")
    } else if (method == "MDS") {
        optionalParams <- list(eig=FALSE, add=FALSE, x.ret=FALSE,
            list.="eig || add || x.ret")
    } else if (method == "PCA") {
        optionalParams <- list(retx=TRUE, center=TRUE, scale.=FALSE, tol=NULL,
            rank=NULL)
    } else if (method == "kPCA") {
        optionalParams <- list(kernel="rbfdot", kpar=list(sigma = 0.1), th=1e-4,
            na.action=na.omit)
    } else if (method == "nMDS") {
        optionalParams <- list( distance="bray", k=2, try=20, trymax=20,
            engine=c("monoMDS", "isoMDS"), autotransform=TRUE,
            noshare='(engine == "isoMDS")', wascores=TRUE, expand=TRUE, trace=1,
            plot=FALSE)
    } else if (method == "tSNE") {
        optionalParams <- list(theta=0.5, check_duplicates=TRUE, pca=TRUE,
            max_iter=1000, is_distance=FALSE, pca_center=TRUE, pca_scale=FALSE,
            stop_lying_iter="ifelse(is.null(Y_init), 250L, 0L)",
            max_switch_iter="ifelse(is.null(Y_init), 250L, 0L)", momentum=0.5,
            final_momentum=0.8, eta=200, exaggeration_factor=12, Y_init=NULL)
    } else if (method == "UMAP") {
        optionalParams <- umap::umap.defaults
    } else {
         stop("Method: ", method, " does not exist, possible methods are: ",
             "DiffusionMap, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS,",
             "PCA,", "kPCA, nMDS, tSNE and UMAP")
            # "PCA,", "kPCA, nMDS, tSNE, UMAP and PEER")
    }
    if (!is.null(params)) {
        params <-  ifelse(params=="TRUE", TRUE, params)
        params <-  ifelse(params=="FALSE", FALSE, params)
        unusedParams <- setdiff(names(params), names(optionalParams))
        if(length(unusedParams)) {
            stop('Method is ', method, ' and non-method parameters provided: ',
                paste(unusedParams, collapse = ', '))
        }
        usedParams <- optionalParams[order(names(optionalParams))]
        params <- params[order(names(params))]
        usedParams[names(usedParams) %in%  names(params)] <- params
        usedParams <- usedParams[match(names(optionalParams), names(usedParams))]
        if(method == "UMAP") {
            class(usedParams) <- class(umap::umap.defaults)
        }
    } else {
        usedParams <- optionalParams
    }
    return(usedParams)
}

#' Wrapper function for dimensionality reduction methods
#'
#' @param Y \[N x P\] data matrix for which the dimensionality of P should be
#' reduced
#' @param distY [dist] object of class dist containing pairwise distances of Y
#' used for methods DiffusionMap, Isomap, MDS and nMDS; if non specified,
#' stats::dist with Euclidean distance applied to supplied Y.
#' @param dist.method [character] method for computing the distance matrix; one of
#' euclidean, maximum, manhattan, canberra, binary or minkowski; see
#' \code{\link[stats]{dist}} for details.
#' @param method Dimensionality reduction method [character] to be applied; one
#' of DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA,
#' nMDS and tSNE.
#' @param optN optimal number [integer] of neighbours to consider for
#' dimensionality reduction; relevant for methods LLE, LaplacianEigenmaps,
#' Isomap and tSNE.
#' @param ndim maximum dimensionality [integer] to retain in the data; large
#' values can cause long computation times.
#' @param verbose [logical] If set, progress messages are printed to standard
#' out.
#' @param params [list] optional additional parameters for dimensionality
#' reduction methods; see details.
#' @return named list with dimensionality reduced phenotypes (reducedY) and
#' object returned by specified dimensionality reduction method (results) with
#' additional output, see details.
#' @details methodsDimReduction wraps around the following implementations of
#' the dimensionality reduction methods it provides:
#' * Diffusion Map: \code{\link[diffusionMap]{diffuse}}
#' * Dimensionality reduction by regression (DRR): \code{\link[DRR]{drr}}
#' * Independent component analysis (ICA): \code{\link[fastICA]{fastICA}}
#' * Local liner embedding (LLE): \code{\link[lle]{lle}}
#' * Isomap: \code{\link[vegan]{isomap}}
#' * Laplacian Eigenmap: \code{\link[loe]{spec.emb}} and
#'   \code{\link[loe]{make.kNNG}}
#' * Multi-dimensional scaling (MDS) : \code{\link[stats]{cmdscale}}
#' * Principal component analysis (PCA): \code{\link[stats]{prcomp}}
#' * Kernel PCA (kPCA): \code{\link[kernlab]{kpca}}
#' * non-metrix MDS (nMDS): \code{\link[vegan]{metaMDS}}
#' * t- stochastic neighbourhood embedding (tSNE): \code{\link[Rtsne]{Rtsne}}
#' * Uniform manifold approximation and projection (umap):
#'    \code{\link[umap]{umap}}
methodsDimReduction <- function(Y, ndim, distY=dist(Y, method=dist.method),
                                dist.method="euclidean",
                                method=c("DiffusionMap", "DRR", "ICA",
                                         "LLE", "Isomap", "LaplacianEigenmap",
                                         "MDS", "PCA","kPCA", "nMDS",
                                         "tSNE", "UMAP"),
                                optN=NULL, verbose=FALSE, params=NULL){


    usedParams <- checkParams(params=params, method=method)

    if (is.null(optN) && any(method %in% c("LLE", "LaplacianEigenmap",
                                           "Isomap", "tSNE"))) {
        if (method == "tSNE" && !is.null(usedParams$perplexity)) {
            optN <- usedParams$perplexity
        } else {
            stop("For ", method, ", optN or perplexity have to specified")
        }
        if (method == "LLE" && !is.null(usedParams$k)) {
            optN <- usedParams$k
        } else {
            stop("For" , method, ", optN or k have to specified")
        }
        if (method == "LaplacianEigenmaps" && !is.null(usedParams$k)) {
            optN <- usedParams$k
        } else {
            stop("For ", method, ", either optN or k have to specified")
        }
        if (method == "Isomap") {
            if (!is.null(usedParams$k)) {
                optN <- usedParams$k
            } else if (!is.null(usedParams$epsilon)) {
                optN <- NULL
            } else {
                stop("For ", method, ", either optN, k, or epsilon have to",
                     " specified")
            }
        }
    }


    if (method == "DiffusionMap") {
        if (usedParams$eps.val  == "epsilonCompute(D)") {
            usedParams$eps.val <- diffusionMap::epsilonCompute(dist(Y))
        }
        results <- diffusionMap::diffuse(D=distY, neigen=ndim,
            eps.val=usedParams$eps.val, t=usedParams$t, delta=usedParams$delta)
        reducedY <- results$X
    } else if (method == "DRR") {
        results <- DRR::drr(Y, ndim=ndim, verbose=verbose,
            lambda=usedParams$lambda, kernel=usedParams$kernel,
            kernel.pars=usedParams$kernel.pars, pca=usedParams$pca,
            pca.center=usedParams$pca.center, pca.scale=usedParams$pca.scale,
            fastc=usedParams$fastcv, cv.folds=usedParams$cv.folds,
            fastcv.test=usedParams$fastcv.text,
            fastkrr.nblocks=usedParams$fastkrr.nblocks)
        reducedY <- results$fitted.data
    }  else if (method == "ICA") {
        if (length(usedParams$fun) == 2) {
            usedParams$fun="logcosh"
        }
        if (length(usedParams$methods) ==2) {
           usedParams$methods="C"
        }
        results <- fastICA::fastICA(Y, n.comp=ndim, fun=usedParams$fun,
             method=usedParams$method, alg.typ=usedParams$alg.typ,
             alpha=usedParams$alpha, row.norm=usedParams$row.norm,
             maxit=usedParams$maxit, tol=usedParams$tol,
             w.init=usedParams$w.init, verbose=verbose)
        reducedY <- results$S
    } else if (method == "LLE") {
        results <- lle::lle(Y, k=optN, m=ndim, reg=usedParams$reg,
            ss=usedParams$ss, p=usedParams$p, id=TRUE, nnk=usedParams$nnk,
            eps=usedParams$eps, iLLE=usedParams$iLLE, v=usedParams$v)
        reducedY <- results$Y
    } else if (method == "Isomap") {
        results <- vegan::isomap(dist=distY, ndim=ndim, k=optN,
            epsilon=usedParams$epsilon, path=usedParams$path, fragmentedOK=TRUE)
        reducedY <- results$points
    } else if (method == "LaplacianEigenmap") {
        DM <- as.matrix(distY)
        if (optN  == 'as.integer(2 * log(nrow(DM)))') {
            optN <- as.integer(2 * log(nrow(DM)))
        }
        ADM <- loe::make.kNNG(DM, k=optN)
        results <- Re(loe::spec.emb(A=ADM, p=ndim, norm=usedParams$norm))
        reducedY <- results
    } else if (method == "MDS") {
        if (usedParams$list. == "eig || add || x.ret") {
            usedParams$list. <-
                usedParams$eig || usedParams$add || usedParams$x.ret
        }
        results <- stats::cmdscale(d=distY, k=ndim, eig=usedParams$eig,
            add=usedParams$add, x.ret=usedParams$x.ret, list.=usedParams$list.)
        reducedY <- results
    } else if (method == "PCA") {
        results <- stats::prcomp(Y, retx=usedParams$retx,
        center=usedParams$center, scale.=usedParams$scale., tol=usedParams$tol,
        rank=usedParams$rank)
        reducedY <- results$x[,1:ndim]
    } else if (method == "kPCA") {
        results <- kernlab::kpca(Y, features=ndim, kernel=usedParams$kernel,
        kpar=usedParams$kpar, th=usedParams$th, na.action=usedParams$na.action)
        reducedY <- results@rotated
    } else if (method == "nMDS") {
        if (usedParams$noshare == '(engine == "isoMDS")') {
            usedParams$noshare <- usedParams$engine == "isoMDS"
        }
        results <- vegan::metaMDS(distY, k=ndim, distance=usedParams$distance,
            try=usedParams$try, trymax=usedParams$trymax,
            engine=usedParams$engine, autotransform=usedParams$autotransform,
            noshare=usedParams$noshare, wascores=usedParams$wascroes,
            expand=usedParams$expand, trace=usedParams$trace,
            plot=usedParams$plot, previous.best=usedParams$previos.best)
        reducedY <- results$points
    } else if (method == "tSNE") {
        if (usedParams$stop_lying_iter == "ifelse(is.null(Y_init), 250L, 0L)") {
            usedParams$stop_lying_iter <-
                ifelse(is.null(usedParams$Y_init), 250L, 0L)
        }
        if (usedParams$max_switch_iter == "ifelse(is.null(Y_init), 250L, 0L)") {
            usedParams$max_switch_iter <-
                ifelse(is.null(usedParams$Y_init), 250L, 0L)
        }
        results <- Rtsne::Rtsne(X=Y, dims=ndim, initial_dims=ndim,
            perplexity=optN, verbose=verbose, theta=usedParams$theta,
            check_duplicates=usedParams$check_duplicates, pca=usedParams$pca,
            max_iter=usedParams$max_iter, is_distance=usedParams$is_distance,
            pca_center=usedParams$pca_center, pca_scale=usedParams$pca_scale,
            stop_lying_iter=usedParams$stop_lying_iter,
            max_switch_iter=usedParams$max_switch_iter,
            momentum=usedParams$momentum, eta=usedParams$eta,
            final_momentum=usedParams$final_momentum,
            exaggeration_factor=usedParams$exaggeration_factor,
            Y_init=usedParams$Y_init)
        reducedY <- results$Y
    } else if (method == "UMAP") {
        results <- umap::umap(Y, usedParams)
        #n_neighbors=optN, n_components=ndim, verbose=verbose)
        reducedY <- results$layout
    # While PEER is not available on CRAN, this part cannot be supported
    #} else if (method == "PEER") {
    #    model = peer::PEER()
    #    # Set observed data
    #    peer::PEER_setPhenoMean(model, Y)
    #    peer::PEER_setAdd_mean(model, TRUE)
    #    peer::PEER_setNk(model, 100)
    #    peer::PEER_setNmax_iterations(model, 1000)
    #    peer::PEER_update(model)
    #    results <- list(Y=peer::PEER_getX(model)[,-1], W=peer::PEER_getW(model), 
    #                    precision=peer::PEER_getAlpha(model))
    #    reducedY <- results$Y
    } else {
        stop("Method: ", method, " does not exist, possible methods are: ",
             "DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS,",
             "PCA,", "kPCA, nMDS, tSNE and UMAP")
    #         "PCA,", "kPCA, nMDS, tSNE, UMAP and PEER")
    }
    return(list(reducedY=reducedY, results=results))
}

#' Compute dimensionality reduction for subsets of the input data
#'
#'
#' @param Y \[N x P\] data matrix for which the dimensionality of P should be
#' reduced,
#' @param seed [integer] seed to initialise random number generator for drawing
#' subsets of Y.
#' @param size [double] proportion of samples from total number of samples to
#' to choose for each subset.
#' @param nrSubsets [integer] number of subsets to generate and apply dimensionality
#' reduction to.
#' @param method dimensionality reduction method [character] to be applied; one of
#' DiffusionMap, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA,
#' nMDS, tSNE and PEER.
#' @param optN optimal number [integer] of neighbours to consider for dimensionality
#' reduction; relevant for methods LLE, LaplacianEigenmaps, Isomap and tSNE. If
#' not provided, will be estimated via \code{\link[lle]{calc_k}}.
#' @param ndim maximum dimensionality [int] to retain in the data; large values
#' can cause long computation times; if not provided max(P,N) is chosen.
#' @param kmin if optN is not provided, kmin [int] specifies the minimum number
#' of neighbours supplied to  \code{\link[lle]{calc_k}}.
#' @param kmax if optN is not provided, kmax [int] specifies the maximum number
#' of neighbours supplied to  \code{\link[lle]{calc_k}}.
#' @param parallel if optN is not provided and parallel TRUE, parallel
#' computation on multiple cpu cores is used with \code{\link[lle]{calc_k}}.
#' @param verbose [logical] If set, progress messages are printed to standard
#' out.
#' @param is.list.ellipsis [logical] if ... arguments are provided as list, set
#' TRUE.
#' @param ... Additional arguments passed to dimensionality reduction methods.
#' For possible arguments, check function decomentation. See details for 
#' relevant packages and functions.
#' @return list of size nrSubsets, containing at each entry a named list of
#' results from \code{\link{computeDimReduction}}:
#' Y_red:  named list with dimensionality reduced phenotypes (reducedY) and
#' object returned by specified dimensionality reduction method (results) with
#' additional output
#' M: vector [double] with Trustworthiness and Continuity estimates for the
#' dimensionality reduction
#' @details subsetDimReduction wraps around the following implementations of
#' the dimensionality reduction methods it provides:
#' * Diffusion Map: \code{\link[diffusionMap]{diffuse}}
#' * Dimensionality reduction by regression (DRR): \code{\link[DRR]{drr}}
#' * Independent component analysis (ICA): \code{\link[fastICA]{fastICA}}
#' * Local liner embedding (LLE): \code{\link[lle]{lle}}
#' * Isomap: \code{\link[vegan]{isomap}}
#' * Laplacian Eigenmap: \code{\link[loe]{spec.emb}} and 
#'   \code{\link[loe]{make.kNNG}}
#' * Multi-dimensional scaling (MDS) : \code{\link[stats]{cmdscale}}
#' * Principal component analysis (PCA): \code{\link[stats]{prcomp}}
#' * Kernel PCA (kPCA): \code{\link[kernlab]{kpca}}
#' * non-metrix MDS (nMDS): \code{\link[vegan]{metaMDS}}
#' * t- stochastic neighbourhood embedding (tSNE): \code{\link[Rtsne]{Rtsne}}
#' * Uniform manifold approximation and projection (umap):
#'    \code{\link[umap]{umap}}
#' * PEER: \href{https://github.com/PMBio/peer/wiki/Installation-instructions}{PEER}
#' @export
subsetDimReduction <- function(Y, seed, size=0.8, nrSubsets=10, method,
                               optN=NULL, ndim=NULL,
                               kmin=1, kmax=40, verbose=FALSE,
                               parallel=FALSE, is.list.ellipsis=FALSE, ...) {
    set.seed(seed)
    sample_matrix <- sapply(1:nrSubsets, function(x) sample(nrow(Y),
                                                            size * nrow(Y)))
    dr <- lapply(1:ncol(sample_matrix), function(x){
        y_cv <- Y[sample_matrix[,x],]
        vmessage(c("Crossvalidation:", x), verbose=verbose)
        dimRed <- computeDimReduction(Y=y_cv, ndim=ndim, method=method,
                                  kmin=kmin, kmax=kmax, optN=optN,
                                  verbose=verbose, parallel=parallel,
                                  is.list.ellipsis=FALSE, ...)
        return(dimRed)
    })
    return(dr)
}
