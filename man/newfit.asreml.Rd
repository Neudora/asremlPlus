\name{newfit.asreml}
\alias{newfit.asreml}
\alias{newfit}
\title{Refits an asreml model with modified model formula using either 
       a call to \code{update.asreml} or a direct call to \code{asreml}.}
\description{Extracts the call from the \code{asreml.obj} and 
             evaluates that call, replacing any arguments with changed values. 
             If \code{update} is \code{TRUE} and \code{set.terms} is not set, 
             the call is evaluated using \code{update.asreml}; otherwise, 
             it is evaluated using a direct call to \code{asreml}. 
             The principal difference is that the latter does not enforce the 
             use of previous values of the variance parameters as initial 
             values; it sets \code{G.param} and \code{R.param} to \code{NULL} 
             or to values as specified for \code{set.terms}. 
             The \code{\dots} argument can be used to pass \code{G.param} 
             and/or \code{R.param}, provided \code{update} is \code{FALSE} 
             and \code{set.terms} is not set.}
\usage{
\method{newfit}{asreml}(asreml.obj, fixed., random., sparse., 
       residual., rcov., update = TRUE, 
       allow.unconverged = TRUE, keep.order = TRUE, 
       set.terms = NULL, ignore.suffices = TRUE, bounds = "P", 
       initial.values = NA, ...)}
\arguments{
 \item{asreml.obj}{a valid \code{asreml} object with with 
                   a component named \code{call} (from a previous 
                   call to either \code{asreml} or \code{update.asreml}).}
 \item{fixed.}{a character or formula specifying changes to the fixed 
               formula. This is a two-sided formula 
               where "." is substituted for existing components in the 
               fixed component of \code{asreml.obj$call}.}
 \item{random.}{a character or formula specifying changes to the random 
                formula. This is a one-sided formula 
                where "." is substituted for existing components in the 
                random component of \code{asreml.obj$call}.}
 \item{sparse.}{a character or formula specifying changes to the sparse 
                formula. This is a one-sided formula 
                where "." is substituted for existing components in the 
                sparse component of \code{asreml.obj$call}.}
 \item{residual.}{a character or formula specifying changes to the error 
                formula, used when version 4 or later of ASReml-R is loaded.
                This is a one-sided formula 
                where "." is substituted for existing components in the 
                residual component of \code{asreml.obj$call}.}
 \item{rcov.}{a character or formula specifying changes to the error 
                formula, used when version 3 of ASReml-R is loaded. 
                This is a one-sided formula 
                where "." is substituted for existing components in the 
                residual component of \code{asreml.obj$call}.}
 \item{update}{a logical indicated whether to use \code{update.asreml} or 
               \code{asreml} to evaluate the modified call. 
               If \code{TRUE},  use \code{update.asreml} to evaluate the 
               modified \code{call}. In doing this the arguments 
               \code{R.param} and \code{G.param} are set to those in the 
               \code{asreml.obj} so that the values from the previous 
               model are used as starting values. If \code{FALSE} then a 
               call is made to \code{asreml} itself, in which the only 
               changes from the previous call are those specified in the 
               arguments to \code{newfit.asreml}.}
 \item{allow.unconverged}{A \code{logical} indicating whether to accept a new model 
                      even when it does not converge. If \code{FALSE} and the fit does not 
                      converge, the supplied \code{asreml} object is returned.}
 \item{keep.order}{a logical value indicating whether the terms should keep 
               their positions. If \code{FALSE} the terms are reordered so 
               that main effects come first, followed by the interactions, 
               all second-order, all third-order and so on. Effects of a 
               given order are kept in the order specified.}
 \item{set.terms}{a character vector specifying the terms that are to have 
                  bounds and/or initial values set prior to fitting.}
 \item{ignore.suffices}{a logical vector specifying whether the suffices of the 
                    \code{asreml}-assigned names of the variance terms (i.e. the 
                    information to the right of an "!", other than "R!") is to 
                    be ignored in matching elements of \code{terms}. 
                    If \code{TRUE} for an element of \code{terms}, the suffices 
                    are stripped from the \code{asreml}-assigned names. 
                    If \code{FALSE} for an element of \code{terms}, the element 
                    must exactly match an \code{asreml}-assigned name for a 
                    variance term. This vector must be of length one or the 
                    same length as \code{terms}. If it is of length one then 
                    the same action is applied to the \code{asreml}-assigned 
                    suffices for all the terms in \code{terms}.}
 \item{bounds}{a \code{\link{character}} vector specifying the bounds to be applied 
                    to the terms specified in \code{set.terms}. This vector 
                    must be of length one or the same length as \code{set.terms}. 
                    If it is of length one then the same constraint is 
                    applied to all the terms in \code{set.terms}. 
                    If any of the bounds are equal to NA then they are 
                    left unchanged for those terms.}
 \item{initial.values}{a character vector specifying the initial values for  
                    the terms specified in \code{terms}. This vector 
                    must be of length one or the same length as \code{terms}. 
                    If it is of length one then the same initial value is 
                    applied to all the terms in \code{terms}. 
                    If any of the initial.values are equal to NA then they are 
                    left unchanged for those terms.}
 \item{\dots}{additional arguments to the call, or arguments with changed 
            values.}
}
\value{An \code{asreml} object.}


\references{Butler, D. G., Cullis, B. R., Gilmour, A. R., Gogel, B. J. and 
            Thompson, R. (2017). \emph{{ASReml-R} User Guide Version 4.}  
            VSN International Ltd, \url{http://www.vsni.co.uk/software/asreml/}.}

\author{Chris Brien}
\seealso{\code{update.asreml}, \code{\link{setvarianceterms.call}}}
\examples{\dontrun{
    m2.asreml <- newfit(m1.asreml, random. = "~ . - Blocks:Plots", maxiter=75)
}}
\keyword{asreml}