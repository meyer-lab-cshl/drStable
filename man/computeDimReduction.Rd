% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DimReduction.R
\name{computeDimReduction}
\alias{computeDimReduction}
\title{Compute dimensionality reduction}
\usage{
computeDimReduction(Y, method, optN = NULL, ndim = NULL, kmin = 1,
  kmax = 40, verbose = FALSE, parallel = FALSE,
  is.list.ellipsis = FALSE, ...)
}
\arguments{
\item{Y}{\[N x P\] data matrix for which the dimensionality of P should be
reduced}

\item{method}{Dimensionality reduction method [character] to be applied; one
of DiffusionsMaps, DRR, ICA, LLE, Isomap, LaplacianEigenmap, MDS, PCA, kPCA,
nMDS, tSNE and UMAP.}

\item{optN}{optimal number [integer] of neighbours to consider for
dimensionality reduction; relevant for methods LLE, LaplacianEigenmaps,
Isomap and tSNE. If not provided, will be estimated via
\code{\link[lle]{calc_k}}.}

\item{ndim}{maximum dimensionality [integer] to retain in the data; large
values can cause long computation times; if not provided max(P,N) is chosen.}

\item{kmin}{if optN is not provided, kmin [integer] specifies the minimum
number of neighbours supplied to  \code{\link[lle]{calc_k}}.}

\item{kmax}{if optN is not provided, kmax [integer] specifies the maximum
number of neighbours supplied to  \code{\link[lle]{calc_k}}.}

\item{verbose}{[logical] If set, progress messages are printed to standard
out.}

\item{parallel}{[logical] if optN is not provided and parallel TRUE, parallel
computation on multiple cpu cores is used with \code{\link[lle]{calc_k}}.}

\item{is.list.ellipsis}{[logical] if ... arguments are provided as list, set
TRUE.}

\item{...}{Additional arguments passed to dimensionality reduction methods.
For possible arguments, check function decomentation. See details for 
relevant packages and functions.}
}
\value{
named list of results from dimensionality reduction:
Y_red:  named list with dimensionality reduced phenotypes (reducedY) and
object returned by specified dimensionality reduction method (results) with
additional output
M: vector [double] with Trustworthiness and Continuity estimates for the
dimensionality reduction
}
\description{
Compute low-dimensional representation of dataset.
}
\examples{
# Generate some data
x <- matrix(rnorm(10000), nrow=10, ncol=100)
y <- x \%*\% diag(nrow=100) * rnorm(100)
dr <- computeDimReduction(y, method="MDS")
}
