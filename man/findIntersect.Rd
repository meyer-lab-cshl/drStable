% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Stability.R
\name{findIntersect}
\alias{findIntersect}
\title{Find intersecting samples between two sets and order according to first}
\usage{
findIntersect(set1, set2)
}
\arguments{
\item{set1}{M1 x D [matrix] with M1 samples and D dimensionality reduced
data P.}

\item{set2}{M2 x D [matrix] with M2 samples and D dimensionality reduced
data P.}
}
\value{
[list] with set1 and set2 filtered for overlapping samples and
ordered to the order of set1.
}
\description{
Find intersecting samples between two sets and order according to first
}
