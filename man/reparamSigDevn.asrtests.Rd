\name{reparamSigDevn.asrtests}
\alias{reparamSigDevn.asrtests}
\alias{reparamSigDevn}
\title{Reparamterizes each random (deviations) term involving 
       \code{devn.fac} to a fixed term and ensures that the same term, with 
       \code{trend.num} replacing \code{devn.fac}, is included if any 
       other term with \code{trend.num} is included in \code{terms}.}
\description{This function reparamterizes each random (deviations) term involving
       \code{devn.fac} to a fixed term and ensures that the same term with 
       \code{trend.num} replacing \code{devn.fac} is included if any 
       other term with \code{trend.num} is included in \code{terms}. It also 
       ansures that any term with \code{spl{trend.num}} replacing 
       \code{devn.fac} in a term being reparameterized is removed from the model.}
\usage{
\method{reparamSigDevn}{asrtests}(asrtests.obj,terms = NULL, 
               trend.num = NULL, devn.fac = NULL, 
               allow.unconverged = TRUE, checkboundaryonly = FALSE, 
               denDF = "numeric", trace = FALSE, update = TRUE, 
               set.terms = NULL, ignore.suffices = TRUE,
               bounds = "P", initial.values = NA,...)
}
\arguments{
 \item{asrtests.obj}{an \code{\link{asrtests}} object for a fitted model that is a list 
                containing an \code{asreml} object, a \code{wald.tab} 
                \code{data.frame} with 4 columns, and a \code{data.frame} with 
                5 columns that records any previous changes and tests in the 
                fitted model.}
 \item{terms}{a character string vector giving the terms that are to be reparameterized.}
 \item{trend.num}{A character string giving the name of the numeric covariate that 
              corresponds to \code{devn.fac} and is potentially included in terms 
              in the fitted model.}
 \item{devn.fac}{A character string giving the name of the factor that corresponds to 
              \code{trend.num} and is included in terms in the fitted model.}
 \item{allow.unconverged}{A \code{logical} indicating whether to accept a new model 
                      even when it does not converge. Initially all changes are made with 
                      \code{allow.unconverged} set to \code{TRUE}. If 
                      \code{allow.unconverged} has been set to \code{FALSE} in the call and 
                      the final fit does not converge, an attempt is made to achieve 
                      convergence by removing any boundary terms. If this is unsuccessful, 
                      the supplied \code{asrtsts} object is returned.}
 \item{checkboundaryonly}{if \code{TRUE} then boundary and singular terms are not removed by 
              \code{\link{rmboundary.asrtests}}; a warning is issued instead.}
 \item{denDF}{Specifies the enthod to use in computing approximate denominator 
              degrees of freedom when \code{wald.asreml} is called. Can be \code{none} 
              to suppress the computations, \code{numeric} for numerical methods,
              \code{algebraic} for algebraic methods or \code{default}, the default, 
              to autommatically choose numeric or algebraic computations depending 
              on problem size. The denominator degrees of freedom are calculated 
              according to Kenward and Roger (1997) for fixed terms in the dense 
              part of the model.}
 \item{trace}{if TRUE then partial iteration details are displayed when ASReml-R 
              functions are invoked; if FALSE then no output is displayed.}
\item{update}{if \code{TRUE }then \code{update.asreml} is called in removing and 
              adding terms to the model. In doing this the arguments \code{R.param} 
              and \code{G.param} are set to those in the \code{asreml} object stored 
              in the supplied \code{asrtests.obj} so that the values from the previous 
              model are used as starting values. If \code{FALSE} then calls are made to 
              \code{asreml} in which the only changes from the previous call are 
              (i) that the models are updated and (ii) modifications 
              specified via \code{\dots} are made.}
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
 \item{\dots}{further arguments passed to \code{asreml} via 
            \code{\link{changeTerms.asrtests}} and \code{\link{asrtests}}.}
}
\value{An \code{\link{asrtests}} object, which is a list containing:
       \enumerate{
         \item \code{asreml.obj}: an \code{asreml} object containing the fit 
               of the model after all boundary and singular terms have been removed;
         \item \code{wald.tab}: a 4-column \code{data.frame} containing a 
               pseudo-anova table for the fixed terms produced by \code{wald.asreml};
         \item \code{test.summary}: a \code{data.frame} with columns \code{term}, 
                \code{DF}, \code{denDF}, \code{p} and \code{action}. It contains a row for each term
                that is dropped, added or tested or a note that several terms have been
                added or removed.}
}

\author{Chris Brien}
\seealso{\code{\link{asrtests}}, \code{\link{changeTerms.asrtests}}, 
         \code{\link{testranfix.asrtests}}, \code{\link{testresidual.asrtests}},  \cr
         \code{\link{newfit.asreml}}, \code{\link{chooseModel.asrtests}}}
\examples{\dontrun{
  data(WaterRunoff.dat)
  asreml.options(keep.order = TRUE) #required for asreml4 only
  current.asr <- asreml(fixed = log.Turbidity ~ Benches + Sources + Type + Species + 
                            Sources:Type + Sources:Species + Sources:Species:xDay + 
                            Sources:Species:Date, 
                        data = WaterRunoff.dat, keep.order = TRUE)
  current.asrt <- asrtests(current.asr, NULL, NULL)

  #Examine terms that describe just the interactions of Date and the treatment factors
  terms.treat <- c("Sources", "Type", "Species", "Sources:Type", "Sources:Species")
  date.terms <- sapply(terms.treat, 
                       FUN=function(term){paste("Date:",term,sep="")}, 
                       simplify=TRUE)
  date.terms <- c("Date", date.terms)
  date.terms <- unname(date.terms)
  treat.marginality <-  matrix(c(1,0,0,0,0,0, 1,1,0,0,0,0,  1,0,1,0,0,0, 
                                 1,0,1,1,0,0, 1,1,1,0,1,0, 1,1,1,1,1,1), nrow=6)
  rownames(treat.marginality) <- date.terms
  colnames(treat.marginality) <- date.terms
  choose <- chooseModel(current.asrt, treat.marginality, denDF="algebraic")
  current.asrt <- choose$asrtests.obj
  current.asr <- current.asrt$asreml.obj
  sig.date.terms <- choose$sig.terms

  #Remove all Date terms left in the fixed model
  terms <- "(Date/(Sources * (Type + Species)))"
  current.asrt <- changeTerms(current.asrt, dropFixed = terms)
  #if there are significant date terms, reparameterize to xDays + spl(xDays) + Date
  if (length(sig.date.terms) != 0)
  { #add lin + spl + devn for each to fixed and random models
    trend.date.terms <- sapply(sig.date.terms, 
                               FUN=function(term){sub("Date","xDay",term)}, 
                               simplify=TRUE)
    trend.date.terms <- paste(trend.date.terms,  collapse=" + ")
    current.asrt <- changeTerms(current.asrt, addFixed=trend.date.terms)
    trend.date.terms <- sapply(sig.date.terms, 
                               FUN=function(term){sub("Date","spl(xDay)",term)}, 
                               simplify=TRUE)
    trend.date.terms <- c(trend.date.terms, sig.date.terms)
    trend.date.terms <- paste(trend.date.terms,  collapse=" + ")
    current.asrt <- changeTerms(current.asrt, addRandom = trend.date.terms)
    current.asrt <- rmboundary(current.asrt)
  }
  
  #Now test terms for sig date terms
  spl.terms <- sapply(terms.treat, 
                      FUN=function(term){paste("spl(xDay):",term,sep="")}, 
                      simplify=TRUE)
  spl.terms <- c("spl(xDay)",spl.terms)
  lin.terms <- sapply(terms.treat, 
                      FUN=function(term){paste(term,":xDay",sep="")}, 
                      simplify=TRUE)
  lin.terms <- c("xDay",lin.terms)
  systematic.terms <- c(terms.treat, lin.terms, spl.terms, date.terms)
  systematic.terms <- unname(systematic.terms)
  treat.marginality <-  matrix(c(1,0,0,0,0,0, 1,1,0,0,0,0,  1,0,1,0,0,0, 
                                 1,0,1,1,0,0, 1,1,1,1,1,0, 1,1,1,1,1,1), nrow=6)
  systematic.marginality <- kronecker(matrix(c(1,0,0,0, 1,1,0,0, 
                                               1,1,1,0, 1,1,1,1), nrow=4), 
                                      treat.marginality)
  systematic.marginality <- systematic.marginality[-1, -1]
  rownames(systematic.marginality) <- systematic.terms
  colnames(systematic.marginality) <- systematic.terms
  choose <- chooseModel(current.asrt, systematic.marginality, 
                         denDF="algebraic", pos=TRUE)
  current.asrt <- choose$asrtests.obj

  #Check if any deviations are significant and, for those that are, go back to 
  #fixed dates
  current.asrt <- reparamSigDevn(current.asrt, choose$sig.terms, 
                                 trend.num = "xDay", devn.fac = "Date", 
                                 denDF = "algebraic")
}}
\keyword{asreml}