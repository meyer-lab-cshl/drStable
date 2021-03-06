% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Stability.R
\name{compareSets}
\alias{compareSets}
\title{Compare dimensionality reduction across subsets}
\usage{
compareSets(set1, set2, verbose = FALSE, procrustes = FALSE)
}
\arguments{
\item{set1}{M1 x D [matrix] with M1 samples and D dimensionality reduced
data P.}

\item{set2}{M2 x D [matrix] with M2 samples and D dimensionality reduced
data P.}

\item{verbose}{[logical] If set, progress messages are printed to standard
out.}

\item{procrustes}{[logical] indication whether a procrustes transformation
to match the lower dimensional representations of common samples between
set1 and set2 should be performed.}
}
\value{
named list
}
\description{
Compare dimensionality reduction across subsets
}
