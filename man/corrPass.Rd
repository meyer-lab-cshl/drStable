% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Stability.R
\name{corrPass}
\alias{corrPass}
\title{Filter correlations based on sequence of thresholds}
\usage{
corrPass(corrmat, threshold)
}
\arguments{
\item{corrmat}{[M x D] correlation matrix}

\item{threshold}{stability threshold [double]}
}
\value{
vector with number of stable components depending on threshold
}
\description{
Filter correlations based on sequence of thresholds
}
