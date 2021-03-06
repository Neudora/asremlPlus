\name{print.asrtests}
\alias{print.asrtests}
\title{Prints the values in an \code{\link{asrtests}} object}
\description{Prints a \code{summary} of the asreml object and the test.summary 
  \code{data.frame} that are stored in the \code{\link{asrtests}} object.}
\usage{\method{print}{asrtests}(x, which = "all", ...)}
\arguments{
 \item{x}{An \code{asrtests} object.}
 \item{which}{Which elements of the \code{\link{asrtests}} object to print. Possible
             values are some combination of \code{asremlsummary}, \code{pseudoanova}, 
             \code{testsummary} and \code{all}.}
 \item{\dots}{further arguments passed to \code{print}.}
}
\value{No value is returned, but the elements of the list in \code{x} are 
       printed.}


\author{Chris Brien}
\seealso{\code{\link{asrtests}}, \code{\link{asremlPlus-package}}}
\examples{\dontrun{
data(Wheat.dat)
current.asr <- asreml(yield ~ Rep + WithinColPairs + Variety, 
                      random = ~ Row + Column + units,
                      residual = ~ ar1(Row):ar1(Column), 
                      data=Wheat.dat)
current.asrt <- asrtests(current.asr, NULL, NULL)
current.asrt <- rmboundary.asrtests(current.asrt)
# Test Row autocorrelation
current.asrt <- testresidual(current.asrt, , "~ Row:ar1(Column)", 
                             label="Row autocorrelation", simpler=TRUE)
print(current.asrt)
}}
\keyword{asreml}
\keyword{htest}