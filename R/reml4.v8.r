"asrtests" <- function(asreml.obj, wald.tab = NULL, test.summary = NULL, 
                       denDF = "numeric", ...)
{ 
  if (class(asreml.obj) != "asreml")
    stop("asreml.obj in an asrtests object should be of class asreml")
  if (is.null(test.summary))
  { 
    test.summary <- data.frame(matrix(nrow = 0, ncol=5))
    colnames(test.summary) <- c("terms","DF","denDF","p","action")
  }
  else
   if (!is.data.frame(test.summary) || ncol(test.summary) != 5)
     stop("test.summary in an asrtests object should be a data.frame with 5 columns")
  if (!is.null(wald.tab))
  {  
    if (!is.data.frame(wald.tab) || ncol(wald.tab) != 4)
      stop("wald.tab should be a 4-column data.frame -- perhaps extract Wald component from list")
  }
  else #form wald.tab
  { 
    asr4 <- ("asreml4" %in% loadedNamespaces())
    if (asr4)
      wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = FALSE, ...)
    else
      wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = FALSE, ...)
    if (!is.data.frame(wald.tab))
           wald.tab <- wald.tab$Wald
  }
  test <- list(asreml.obj = asreml.obj, wald.tab=wald.tab, test.summary = test.summary)
  class(test) <- "asrtests"
  test$wald.tab <- recalcWaldTab(test, ...)
  return(test)
}


"print.asrtests" <- function(x, which = "all", ...)
 { 
  asr4 <- ("asreml4" %in% loadedNamespaces())
  options <- c("asremlsummary", "pseudoanova", "testsummary", "all")
   opt <- options[unlist(lapply(which, check.arg.values, options=options))]
   if ("asremlsummary" %in% opt | "all" %in% opt)
#      if (asr4) 
        print(summary(x$asreml.obj), ...)
#   else
#     print(asreml::summary.asreml(x$asreml.obj), ...)
   if ("pseudoanova" %in% opt | "all" %in% opt)
   {
     cat("\n\n  Pseudo-anova table for fixed terms \n\n")
     print(x$wald.tab, ...)
   }
   if ("testsummary" %in% opt | "all" %in% opt)
   {  
     cat("\n\n  Sequence of model terms whose status in the model has been investigated \n\n")
     x$test.summary$p <- round(x$test.summary$p, digits=4)
     print(x$test.summary, digits=4, ...)
   }
   invisible()
}

"recalcWaldTab.asrtests" <- function(asrtests.obj, recalc.wald = FALSE, 
                                     denDF="numeric", dDF.na = "none", 
                                     dDF.values = NULL, trace = FALSE, ...)
{ 
  asr4 <- ("asreml4" %in% loadedNamespaces())
  if (is.null(asrtests.obj) | class(asrtests.obj) != "asrtests")
    stop("Must supply an asrtests object")
  asreml.obj <- asrtests.obj$asreml.obj
  #Call wald.asreml if recalc.wald is TRUE
  if (recalc.wald)
  { 
    if (asr4)
      wald.tab <- asreml4::wald.asreml(asreml.obj, denDf=denDF, trace = trace, ...)
    else
      wald.tab <- asreml::wald.asreml(asreml.obj, denDf=denDF, trace = trace, ...)
    if (!is.data.frame(wald.tab))
      wald.tab <- wald.tab$Wald
  }
  else #extract wald.tab from the asrtests object
    wald.tab <- asrtests.obj$wald.tab
  nofixed <- dim(wald.tab)[1]
  hd <- attr(wald.tab, which = "heading")
  options <- c("none", "residual", "maximum", "supplied")
  opt <- options[check.arg.values(dDF.na, options)]
  if (opt == "supplied" & is.null(dDF.values))
    stop('Need to set dDF.values because have set dDF.na = \"supplied\"')
  if (opt == "supplied")
    if (length(dDF.values) != nofixed)
      stop("Number of  dDF.values must be the same as the number of terms in wald.tab")
  den.df <- NA
  if (!("denDF" %in% colnames(wald.tab))) #no denDF
  { 
    wald.tab <- wald.tab[1:(nofixed-1), c(1,3,4)] #Remove Residual line
    wald.tab$F.inc <- wald.tab$'Wald statistic'/wald.tab$Df
    hd[1] <- "Conservative Wald F tests for fixed effects \n"
    attr(wald.tab, which = "heading") <- hd
    
    #Get denDF
    if (opt == "supplied")
    { wald.tab$denDF <- dDF.values
      warning("Supplied dDF.values used for denDF")
    }
    else
      if (opt == "maximum" | opt == "residual") 
      { 
        wald.tab$denDF <- asreml.obj$nedf
        warning("Residual df used for denDF")
      }
  }
  else #have denom. df
  { 
    den.df.na <- is.na(wald.tab$denDF)
    if (any(den.df.na)) #some denDf are NA and so need to use approximate DF
    { 
      if (opt == "supplied")
      { 
        wald.tab$denDF[den.df.na] <- dDF.values[den.df.na]
        warning("At least some supplied dDF.values used for denDF")
      }
      else
      { 
        if (opt == "maximum") 
        { 
          if (!all(den.df.na))
          { 
            den.df <- max(wald.tab$denDF[-1], na.rm=TRUE) 
            warning("Maximum denDF used for some terms")
          }
          else
          { 
            den.df <- asreml.obj$nedf
            warning("Residual df used for denDF for at least some terms")
          }
        }
        else
        { 
          if (opt == "residual")
          { 
            den.df <- asreml.obj$nedf
            warning("Residual df used for denDF for at least some terms")
          }
        }
        wald.tab$denDF[den.df.na] <- den.df
      }
    }
  }
  attr(wald.tab, which = "heading") <- hd
  if (nrow(wald.tab) == 0)
    warning("Wald.tab is empty - probably the caclulations have failed")
  else
    #Calc Pr
    wald.tab$Pr <- 1 - pf(wald.tab$F.inc, wald.tab$Df, wald.tab$denDF)
  
  return(wald.tab)
}


"powerTransform" <- function(var.name, power = 1, offset = 0, scale = 1, 
                              titles = NULL, data)
#Function to perform a power transformation on a variable whose name is given as 
#a character string in var.name. The transformed variable is stored in data
{ 
  k <- match(var.name, names(data))
  if (!is.null(titles) & !is.na(match(var.name, names(titles))))
    title <- titles[[var.name]]
  else
    title <- names(data)[k]
  #Get current variable and its name and title
  tvar.name <- var.name
  ttitle <- title
  y <- data[[k]]
  #Apply scale transformation
  if (scale != 1)
  { 
    y <- scale * y
    if (scale == -1)
    { 
      tvar.name <- paste("neg.",tvar.name,sep="")
      ttitle <- paste("Negative of ", ttitle,sep="")
    } else
    { 
      tvar.name <- paste("scaled.",tvar.name,sep="")
      ttitle <- paste("Scaled ", ttitle,sep="")
    }
  }
  #Apply offset
  if (offset != 0)
  { 
    y <- offset + y
    tvar.name <- paste("offset.",tvar.name,sep="")
    if (scale != 1)
      ttitle <- paste("and ", ttitle,sep="")
    ttitle <- paste("Offset  ", ttitle,sep="")
  }
  #Apply power transformation
  if (power != 1)
  { 
    if (power == 0)
    { 
      tvar.name <- paste("log.",tvar.name,sep="")
      if (min(y, na.rm = "TRUE") < 1e-04)
        stop("Negative values for log transform - could use offset/scale")
      else
        y <- log(y)
      ttitle <- paste("Logarithm of ", ttitle,sep="")
    } else
    { 
      y <- y^power
      if (power == 0.5)
      { 
        tvar.name <- paste("sqrt.",tvar.name,sep="")
        ttitle <- paste("Square root of ", ttitle,sep="")
      } else
        if (power == -1)
        { 
          tvar.name <- paste("recip.",tvar.name,sep="")
          ttitle <- paste("Reciprocal of ", ttitle,sep="")
        }
        else
        { 
          tvar.name <- paste("power.",tvar.name,sep="")
          ttitle <- paste("Power ",power," of ", ttitle, sep="")
        }
    }
    #Add transformed variable to data
    tk <- match(tvar.name, names(data))
    if (is.na(tk))
      tk <- ncol(data) + 1
    data[[tk]]  <- y
    names(data)[tk] <- tvar.name
    #Add transformed title to titles
    nt <- length(titles)
    titles[[nt+1]] <- ttitle
    names(titles)[nt+1] <- tvar.name
  }
  return(list(data = data, tvar.name = tvar.name, titles = titles))
}

"setvarianceterms.call" <- function(call, terms, ignore.suffices = TRUE, bounds = "P", 
                                      initial.values = NA, ...)
  # call is an unevaluated call to asreml (can create using the call function)
  # terms is a vector of characters with the names of the gammas to be set
  # bounds specifies the bounds to be applied to the terms 
  #asreml codes:
  #  B - fixed at a boundary (!GP)
  #  F - fixed by user
  #  ? - liable to change from P to B    
  #  P - positive definite
  #  C - Constrained by user (!VCC)      
  #  U - unbounded
  #  S - Singular Information matrix
  # initial.values specifies the initial values for the terms
  # - ignore.suffices, bounds and initial.values must be of length 1 or 
  #   the same length as terms
  # - if any of bounds or initial.values is set to NA, then they are 
  #   left unchanged for those terms
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")

  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #test for compatibility of arguments
  nt <- length(terms)
  if (length(ignore.suffices) == 1 & nt != 1)
    ignore.suffices <- rep(ignore.suffices, nt)
  if (length(ignore.suffices) != nt)
    stop("ignore.suffices specification is not consistent with terms")
  if (length(bounds) == 1 & nt != 1)
    bounds <- rep(bounds, nt)
  if (length(bounds) != nt)
    stop("bounds specification is not consistent with terms")
  if (length(initial.values) == 1 & nt != 1)
    initial.values <- rep(initial.values, nt)
  if (length(initial.values) != nt)
    stop("initial.values specification is not consistent with terms")
  if (any(!(bounds %in% c("B", "F", "P", "C", "U"))))
    stop("bounds contains at least one code that is not used by asreml")

  #add start.values to call and apply bounds to the gammas specified by terms
  start.call <- call
  languageEl(start.call, which = "start.values") <- TRUE
  gamma.start <- eval(start.call, sys.parent())
  if (asr4)
  {
    gamma.table <- gamma.start$vparameters.table
    gammas <- gamma.table$Component
  }
  else
  {
    gamma.table <- gamma.start$gammas.table
    gammas <- gamma.table$Gamma
  }
  k <- unlist(lapply(1:nt, 
                     FUN=function(i, terms, termslist, ignore.suffices=TRUE)
                     { k <- findterm(terms[i], termslist, rmDescription=ignore.suffices[i])
                       return(k)
                     }, 
                     terms=terms,
                     termslist=gammas, 
                     ignore.suffices=ignore.suffices))
  if (any(k==0))
    stop(paste("Could not find", paste(terms[k==0], collapse=", ")))
  else
  { 
    if (!all(is.na(bounds)))
    { 
      kk <- k[!is.na(bounds)]
      gamma.table$Constraint[kk] <- bounds[!is.na(bounds)]
    }
    if (!all(is.na(initial.values)))
    { 
      kk <- k[!is.na(initial.values)]
      gamma.table$Value[kk] <- initial.values[!is.na(initial.values)]
    }
  }
  #rerun with the unconstrained parameters, adding parameters in ...
  unconst.call <- call
  languageEl(unconst.call, which = "G.param") <- gamma.table
  languageEl(unconst.call, which = "R.param") <- gamma.table
  
  #deal with args coming via ...
  tempcall <- list(...)
  if (length(tempcall)) 
  { 
    for (z in names(tempcall))
    languageEl(unconst.call, which = z) <- tempcall[[z]]
  }
  #Evaluate the call
  new.reml <- eval(unconst.call, sys.parent())
  new.reml$call <- unconst.call
  invisible(new.reml)
}

"newfit.asreml" <- function(asreml.obj, fixed., random., sparse., 
                            residual., rcov., update = TRUE, 
                            allow.unconverged = TRUE, keep.order = TRUE, 
                            set.terms = NULL, ignore.suffices = TRUE, 
                            bounds = "P", initial.values = NA, ...)
#a function to refit an asreml model with modified model formula
#using either update.asreml or a direct call to asreml
#- the principal difference is that the latter does not enforce the 
#  use of previous values of the variance parameters as initial values.
#- ... is used to pass arguments to asreml.
# set.terms is a vector of characters with the names of the gammas to be set
# bounds specifies the bounds to be applied to the terms 
# initial.values specifies the initial values for the terms
# - ignore.suffices, bounds and initial.values must be of length 1 or 
#   the same length as terms
# - if any of bounds or initial.values is set to NA, then they are 
#   left unchanged for those terms
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  "my.update.formula" <- function(old, new, keep.order = TRUE, ...) 
    #function to update a formula
  { 
    env <- environment(as.formula(old))
    tmp <- update.formula(as.formula(old), as.formula(new))
    out <- formula(terms.formula(tmp, simplify = TRUE, keep.order = keep.order))
    environment(out) <- env
    return(out)
  }
  if (is.null(call <- asreml.obj$call) && 
      is.null(call <- attr(asreml.obj, "call"))) 
    stop("Need an object with call component or attribute")
  #Evaluate formulae in case they are stored in a user-supplied object
  if (!is.null(languageEl(call, which = "fixed")))
    languageEl(call, which = "fixed") <- eval(languageEl(call, which = "fixed"))
  if (!is.null(languageEl(call, which = "random")))
    languageEl(call, which = "random") <- eval(languageEl(call, which = "random"))
  if (!is.null(languageEl(call, which = "sparse")))
    languageEl(call, which = "sparse") <- eval(languageEl(call, which = "sparse"))
  if (asr4)
  {
    if (!is.null(languageEl(call, which = "residual")))
      languageEl(call, which = "residual") <- eval(languageEl(call, which = "residual"))
  } else
  {
    if (!is.null(languageEl(call, which = "rcov")))
      languageEl(call, which = "rcov") <- eval(languageEl(call, which = "rcov"))
  }
  
  #Now update formulae
  if (!missing(fixed.)) 
    languageEl(call, which = "fixed") <- 
    my.update.formula(as.formula(languageEl(call, which = "fixed")), 
                      fixed., keep.order = keep.order)
  if (!missing(random.)) 
  {
    if (is.null(random.))
      languageEl(call, which = "random") <- NULL
    else
      languageEl(call, which = "random") <- 
      { 
        if (!is.null(languageEl(call, which = "random"))) 
          my.update.formula(as.formula(languageEl(call, which = "random")), 
                            random., keep.order = keep.order)
        else 
          random.
      }
  }
  if (!missing(sparse.)) 
    languageEl(call, which = "sparse") <- 
    { if (!is.null(languageEl(call, which = "sparse"))) 
      my.update.formula(as.formula(languageEl(call, which = "sparse")), 
                        sparse., keep.order = keep.order)
      else 
        sparse.
    }
  if (asr4)
  {
    if (!missing(rcov.)) 
      stop("ASReml verson 4 is loaded - residual rather than deprecated rcov should be set")
    if (!missing(residual.)) 
    {
      if (is.null(residual.))
        languageEl(call, which = "residual") <- NULL
      else
        languageEl(call, which = "residual") <- 
        { if (!is.null(languageEl(call, which = "residual"))) 
          my.update.formula(as.formula(languageEl(call, which = "residual")), 
                            residual., keep.order = keep.order)
          else 
            residual.
        }
    }
  } else
  {
    if (!missing(residual.)) 
      stop("ASReml verson 3 is loaded - rcov should be set, rather than residual which requires version 4")
    if (!missing(rcov.)) 
    {
      if (is.null(rcov.))
        languageEl(call, which = "rcov") <- NULL
      else
        languageEl(call, which = "rcov") <- 
        { if (!is.null(languageEl(call, which = "rcov"))) 
          my.update.formula(as.formula(languageEl(call, which = "rcov")), 
                            rcov., keep.order = keep.order)
          else 
            rcov.
        }
    }
  }
  
  if(is.null(set.terms))
  { 
    if (update)
    {
      #If R.param and G.param set in asreml.obj, copy them
      if (!is.null(asreml.obj$R.param))
        languageEl(call, which = "R.param") <- asreml.obj$R.param
      if (!is.null(asreml.obj$G.param))
        languageEl(call, which = "G.param") <- asreml.obj$G.param
    } else
    {
      #If R.param and G.param already set, make them NULL
      if (!is.null(languageEl(call, which = "R.param")))
        languageEl(call, which = "R.param") <- NULL
      if (!is.null(languageEl(call, which = "G.param")))
        languageEl(call, which = "G.param") <- NULL
    }
  }
  else
  { 
    #set variance terms
    #test for compatibility of arguments
    nt <- length(set.terms)
    if (length(ignore.suffices) == 1 & nt != 1)
      ignore.suffices <- rep(ignore.suffices, nt)
    if (length(ignore.suffices) != nt)
      stop("ignore.suffices specification is not consistent with set.terms")
    if (length(bounds) == 1 & nt != 1)
      bounds <- rep(bounds, nt)
    if (length(bounds) != nt)
      stop("bounds specification is not consistent with set.terms")
    if (length(initial.values) == 1 & nt != 1)
      initial.values <- rep(initial.values, nt)
    if (length(initial.values) != nt)
      stop("initial.values specification is not consistent with set.terms")
    
    #add start.values to call and unconstrain the gammas specified by set.terms
    start.call <- call
    languageEl(start.call, which = "start.values") <- TRUE
    gamma.start <- eval(start.call, sys.parent())
    if (asr4)
    {
      gamma.table <- gamma.start$vparameters.table
      gammas <- gamma.table$Component
    }
    else
    {
      gamma.table <- gamma.start$gammas.table
      gammas <- gamma.table$Gamma
    }
    k <- unlist(lapply(1:nt, 
                       FUN=function(i, set.terms, termslist, ignore.suffices=TRUE)
                       { k <- findterm(set.terms[i], termslist, rmDescription=ignore.suffices[i])
                       return(k)
                       }, 
                       set.terms=set.terms,
                       termslist=gammas, 
                       ignore.suffices=ignore.suffices))
    if (any(k==0))
    { 
      warning(paste("Could not find", paste(set.terms[k==0], collapse=", ")))
      bounds <- bounds[k != 0]
      initial.values <- initial.values[k != 0]
      k <- k[k != 0]
    }
    if (!all(is.na(bounds)))
    { 
      kk <- k[!is.na(bounds)]
      gamma.table$Constraint[kk] <- bounds[!is.na(bounds)]
    }
    if (!all(is.na(initial.values)))
    { 
      kk <- k[!is.na(initial.values)]
      gamma.table$Value[kk] <- initial.values[!is.na(initial.values)]
    }
    #modify call to set variance parameters
    languageEl(call, which = "G.param") <- gamma.table
    languageEl(call, which = "R.param") <- gamma.table
  }
  
  #deal with args coming via ...
  tempcall <- list(...)
  if (length(tempcall)) 
  { 
    for (z in names(tempcall))
      languageEl(call, which = z) <- tempcall[[z]]
  }
  #Check whether formulae has been reduced to no terms
  # if (!is.null(languageEl(call, which = "random")) && 
  #     length(attr(terms(as.formula(languageEl(call, which = "random"))), "factors")) == 0) 
  if (!is.null(languageEl(call, which = "random")) && 
      length(attr(terms(as.formula(languageEl(call, which = "random"))), 
                  "factors")) == 0) 
    languageEl(call, which = "random") <- NULL
  if (!is.null(languageEl(call, which = "sparse")) && 
      length(attr(terms(as.formula(languageEl(call, which = "sparse"))), "factors")) == 0) 
    languageEl(call, which = "sparse") <- NULL
  if (asr4)
  {
    if (!is.null(languageEl(call, which = "residual")) &&
        length(attr(terms(as.formula(languageEl(call, which = "residual"))), 
                    "factors")) == 0) 
      languageEl(call, which = "residual") <- NULL
  } else
  {
    if (!is.null(languageEl(call, which = "rcov")) &&
        length(attr(terms(as.formula(languageEl(call, which = "rcov"))), "factors")) == 0) 
      languageEl(call, which = "rcov") <- NULL
  }
  
  #Evaluate the call
  if (asr4 & keep.order)
    asreml4::asreml.options(keep.order = TRUE)
  asreml.new.obj <- eval(call, sys.parent())
  asreml.new.obj$call <- call
  #If not converged, issue warning
  if (!asreml.new.obj$converge)
  {
    warning(asreml.new.obj$last.message)
    if (!allow.unconverged)
      asreml.new.obj <- asreml.obj
  }
  invisible(asreml.new.obj)
}

"rmboundary.asrtests" <- function(asrtests.obj, checkboundaryonly = FALSE, 
                                  trace = FALSE, update = TRUE, 
                                  set.terms = NULL, ignore.suffices = TRUE, 
                                  bounds = "P", initial.values = NA, ...)
#Removes any boundary or singular terms from the fit stored in asreml.obj, 
#one by one from largest to smallest
#For a list of bounds codes see setvarianceterms.call
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #check input arguments
  if (asr4)
    kresp <- asrtests.obj$asreml.obj$formulae$fixed[[2]]
  else
    kresp <- asrtests.obj$asreml.obj$fixed.formula[[2]]    
  if (class(asrtests.obj) != "asrtests")
  {
    stop("In analysing ", kresp, ", must supply an asrtests object")
  }
  asreml.obj <- asrtests.obj$asreml.obj
  reml <- asreml.obj$loglik
  test.summary <- asrtests.obj$test.summary
  no.unremoveable <- 0
  #Loop  until have removed all removable boundary terms
  repeat
  { 
    #Find boundary terms
    if (asr4)
    {
      allvcomp <- data.frame(bound = asreml4::vpc.char(asreml.obj), 
                             component = asreml.obj$vparameters, 
                             stringsAsFactors = FALSE)
      bound.terms <- allvcomp$bound == "B" | allvcomp$bound == "S"
      #                 | bound == "F"
      #bound.terms[grep("?", bound, fixed=TRUE)] <- TRUE
    }
    else
    {
      allvcomp <- data.frame(bound = names(asreml.obj$gammas.con), 
                             component = asreml.obj$gammas,
                             stringsAsFactors = FALSE)
      bound.terms <- allvcomp$bound == "Boundary" | allvcomp$bound == "Singular"
      #                 | bound == "Fixed"
      #bound.terms[grep("?", bound, fixed=TRUE)] <- TRUE
    }
    vcomp <- allvcomp[bound.terms, ]
    nbound <- nrow(vcomp)
    #No boundary terms, so get out
    if (nbound <= 0 | checkboundaryonly) break
    #Reduce bound terms to set of bound terms that can be removed
    k <- 1
    while (k <= nbound)
    { 
      term <- rownames(vcomp)[k]
      ranterms.obj <- as.terms.object(languageEl(asreml.obj$call, which="random"), 
                                      asreml.obj)
      termno <- findterm(term, labels(ranterms.obj))
      if (termno <= 0) #must be an R term or not a recognisable G term
      { 
        vcomp <- vcomp[-k, ]
        k <- k - 1
        nbound <- nbound - 1
        #Store any unremoveable terms
        if (no.unremoveable == 0)
        { 
          terms.unremoveable <- term
          no.unremoveable <- no.unremoveable + 1
        } else
        { 
          if (!(term %in% terms.unremoveable))
          { 
            terms.unremoveable <- c(terms.unremoveable, term)
            no.unremoveable <- no.unremoveable + 1
          }
        }
      }
      k <- k + 1
    }
    #No removeable boundary terms, so get out
    if (nbound <= 0) break
    #If single term, set it as the terms to remove
    if (nbound == 1)
    { 
      term <- rmTermDescription(rownames(vcomp)[1])
    } else #Choose a term to remove
    { 
      #Classify terms as involving random or not because it involves a covariate
      vcomp.vars <- lapply(rownames(vcomp)[1:nbound], getTermVars)
      vcomp.codes <- lapply(vcomp.vars, getVarsCodes, asreml.obj = asreml.obj)
      vcomp <- within(vcomp, {
                          terms.random <- unlist(lapply(vcomp.codes, function(term){all(term == 5)}))
                          varnos <- unlist(lapply(vcomp.codes, length))
                    })
      #Identify terms of the same type that are next to be removed
      max.no.factor <- TRUE
      #Check for terms that involve the dev function
      this.type <- unlist(lapply(vcomp.codes, function(term){any(term == 4 | term == 9)}))
      if (any(this.type))
      { 
        vcomp <- subset(vcomp, this.type)
      } else #Check for random terms (factors only)
      {   
        this.type <- unlist(lapply(vcomp.codes, function(term){all(term == 5)}))
        if (any(this.type))
        { 
          vcomp <- subset(vcomp, this.type)
          max.no.factor <- FALSE
        } else #Check for terms with spl
        { 
          this.type <- unlist(lapply(vcomp.codes, function(term){any(term == 3 | term == 8)}))
          if (any(this.type))
            vcomp <- subset(vcomp, this.type)
          else #Check for terms with pol
          { 
            this.type <- unlist(lapply(vcomp.codes, function(term){any(term == 2 | term == 7)}))
            if (any(this.type))
              vcomp <- subset(vcomp, this.type)
            else #Check for terms with covariate or lin
            { 
              this.type <- unlist(lapply(vcomp.codes, function(term){any(term < 2 | term == 6)}))
              if (any(this.type))
                vcomp <- subset(vcomp, this.type)
            }
            
          }
        }
      }
      #Reduce to subset of terms of the type to be removed and choose a term  
      if (max.no.factor)
      { 
        #Get smallest value term amongst those with the most vars
        vcomp <- subset(vcomp, vcomp$varnos == max(vcomp$varnos))
        vcomp <- with(vcomp, vcomp[order(-component),])
        term <- rmTermDescription(tail(rownames(vcomp), 1))
      } else #Get smallest value term amongst those with the least vars
      { 
        vcomp <- subset(vcomp, vcomp$varnos == min(vcomp$varnos))
        vcomp <- with(vcomp, vcomp[order(-component),])
        term <- rmTermDescription(tail(rownames(vcomp), 1))
      }
    }
    #Remove chosen term
    test.summary <- addtoTestSummary(test.summary, terms = term, DF = 1, denDF = NA, p = NA, 
                                     action = "Boundary")
    mod.ran <- as.formula(paste("~ . - ", term, sep=""))
    asreml.obj <- newfit.asreml(asreml.obj, random. = mod.ran, trace = trace, 
                                update = update, set.terms = set.terms, 
                                ignore.suffices = ignore.suffices, 
                                bounds = bounds, 
                                initial.values = initial.values, ...)
  }
  #Output warning if there are unremovable bound terms
  if (no.unremoveable > 0)
  {
    warning("\nIn analysing ", kresp,
            ", cannot remove the following boundary/singular term(s): ", 
            paste(terms.unremoveable, collapse = "; "), "\n\n")
  } else
  {
    if (checkboundaryonly & nbound > 0)
      warning("In analysing ", kresp,
              ", the following term(s) were boundary/singular, ","
              but not removed because checkboundaryonly = TRUE:\n",
              paste(rownames(vcomp), collapse = "; "), "\n")
  }
  #Check for variance terms that have been fixed and issue warning
  if (length(allvcomp$bound[allvcomp$bound == "Fixed"]) != 0)
  { 
    warning("In analysing ", kresp,
            ", estimates of the following parameter(s) are fixed:\n",
            rownames(allvcomp)[allvcomp$bound == "Fixed"])
  }
  #check for change in log likelihood and if changed issue warning
  change <- abs(reml -asreml.obj$loglik)/reml*100
  if (!is.na(change) & change > 1)
    warning(paste("Removing boundary terms has changed the log likelihood by "),
            change,"%")
  results <- asrtests(asreml.obj = asreml.obj, 
                      wald.tab = asrtests.obj$wald.tab, 
                      test.summary = test.summary)
  invisible(results)
}

"changeTerms.asrtests" <- function(asrtests.obj, 
                                   dropFixed = NULL, addFixed = NULL, 
                                   dropRandom = NULL,  addRandom = NULL, 
                                   newResidual = NULL, label = "Changed terms", 
                                   allow.unconverged = TRUE, checkboundaryonly = FALSE, 
                                   trace = FALSE, update = TRUE, denDF = "numeric", 
                                   set.terms = NULL, ignore.suffices = TRUE, 
                                   bounds = "P", initial.values = NA, ...)
  #Adds or removes sets of terms from one or both of the fixed or random asreml models
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #check input arguments
  if (asr4)
    kresp <- asrtests.obj$asreml.obj$formulae$fixed[[2]]
  else
    kresp <- asrtests.obj$asreml.obj$fixed.formula[[2]]
  all.terms <- c(dropFixed, addFixed, dropRandom, addRandom, newResidual)
  if (all(is.null(all.terms)))
    stop("In analysing ", kresp, ", must supply terms to be removed/added")
  if (any(grepl("~", all.terms, fixed = TRUE)))
    stop("In analysing ", kresp, ", a tilde (~) has been included with the terms")
  if (!is.character(all.terms))
    stop("In analysing ", kresp, ", must supply terms as character")
  if (class(asrtests.obj) != "asrtests")
    stop("In analysing ", kresp, ", must supply an asrtests object")
  
  #initialize
  asreml.obj <- asrtests.obj$asreml.obj
  wald.tab <- asrtests.obj$wald.tab
  test.summary <- asrtests.obj$test.summary
  
  #Form formula with terms to be added and removed
  fix.form <- ". ~ . "
  if (!is.null(dropFixed) | !is.null(addFixed))
  {
    if (!is.null(dropFixed))
      fix.form <- paste(fix.form, " - (", dropFixed, ")", sep = "")
    if (!is.null(addFixed))
      fix.form <- paste(fix.form, " + (", addFixed, ")", sep = "")
    fix.form <- as.formula(fix.form)
  }

  ran.form <-" ~ . "
  if (is.null(asreml.obj$G.param))
    ran.form <-" ~ "
  if (((is.null(dropRandom) & is.null(addRandom)) |
      (!is.null(dropRandom) & is.null(addRandom))) & is.null(asreml.obj$G.param))
  {
    ran.form <- NULL
    if (!is.null(dropRandom))
      warning("No random terms to drop")
  } else
  {
    if (!is.null(dropRandom))
      ran.form <- paste(ran.form, " - (", dropRandom, ")", sep = "")
    if (!is.null(addRandom))
      ran.form <- paste(ran.form , " + (", addRandom, ")", sep = "")
    ran.form <- as.formula(ran.form)
  }

  res.form <- " ~ "
  if (!is.null(newResidual))
    res.form <- as.formula(paste(res.form, newResidual, sep=""))
  else 
  {
    if (asr4)
    {
      if (!is.null(languageEl(asreml.obj$call, which = "residal")))
        res.form <- " ~ . "
      else
        res.form <- NULL
    } else
    {
      if (!is.null(languageEl(asreml.obj$call, which = "rcov")))
        res.form <- " ~ . "
      else
        res.form <- NULL
    }
  }
  
  #Check models to update by determining if they have any terms in the update formula
  forms <- stringr::str_trim(c(fix.form, ran.form, res.form))
  lastch <- stringr::str_sub(forms, start = nchar(forms))
  lastch <- !(lastch == "." | lastch == "~")
  if (is.null(res.form))
    lastch <- c(lastch, FALSE)
  if (is.null(ran.form))
    lastch <- c(lastch[1], FALSE, lastch[2])
  if (!any(lastch))
    action <- "No changes"
  else
  {
    if (sum(lastch) == 1)
      action <- paste("Changed ", c("fixed", "random","residual")[lastch], sep = "")
    else
      action <- paste("Changed ", 
                      paste(c("fixed", "random","residual")[lastch], collapse = ", "), 
                      sep = "")
  }
  
  #Update the models
  if (action == "No changes")
  {
    test.summary <- addtoTestSummary(test.summary, terms = label, DF=NA, denDF = NA, 
                                     p = NA, action = action)
  } else
  {
    if (asr4)
    {
      asreml.new.obj <- newfit.asreml(asreml.obj, 
                                      fixed. = fix.form, random. = ran.form, 
                                      residual. = res.form, 
                                      trace = trace, update = update, 
                                      allow.unconverged = TRUE,
                                      set.terms = set.terms, 
                                      ignore.suffices = ignore.suffices, 
                                      bounds = bounds, 
                                      initial.values = initial.values, ...)
    } else
    {
      asreml.new.obj <- do.call(newfit.asreml,
                                args = list(asreml.obj, 
                                            fixed. = fix.form, random. = ran.form, 
                                            rcov. = res.form, 
                                            trace = trace, update = update, 
                                            allow.unconverged = TRUE,
                                            set.terms = set.terms, 
                                            ignore.suffices = ignore.suffices, 
                                            bounds = bounds, 
                                            initial.values = initial.values, ...))
      
    }
    
    #Update results, checking for convergence
    if (asreml.new.obj$converge | allow.unconverged)
    {
      asreml.obj <- asreml.new.obj
      #Update wald.tab
      if (asr4)
        wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      else
        wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      if (!is.data.frame(wald.tab))
        wald.tab <- wald.tab$Wald
      if (!asreml.obj$converge)
        action <- paste(action, " - old uncoverged", sep="")
      test.summary <- addtoTestSummary(test.summary, terms = label, DF=NA, denDF = NA, 
                                       p = NA, action = action)
      #Check for boundary terms
      temp.asrt <- rmboundary.asrtests(asrtests(asreml.obj, wald.tab, test.summary), 
                                       checkboundaryonly = checkboundaryonly, 
                                       trace = trace, update = update, 
                                       set.terms = set.terms, 
                                       ignore.suffices = ignore.suffices, 
                                       bounds = bounds, 
                                       initial.values = initial.values, ...)
      if (nrow(temp.asrt$test.summary) > nrow(test.summary))
      {
        if (asr4)
          warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                  ", boundary terms removed")
        else
          warning("In analysing ",asreml.obj$fixed.formula[[2]],
                  ", boundary terms removed")
      }
      asreml.obj <- temp.asrt$asreml.obj
      test.summary <- temp.asrt$test.summary
      #Update wald.tab
      if (asr4)
        wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      else
        wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      if (!is.data.frame(wald.tab))
        wald.tab <- wald.tab$Wald
    } else #unconverged and not allowed
    {
      #Check if get convergence with any boundary terms removed
      temp.asrt <- rmboundary.asrtests(asrtests(asreml.new.obj, wald.tab, test.summary), 
                                       checkboundaryonly = checkboundaryonly, 
                                       trace = trace, update = update, 
                                       set.terms = set.terms, 
                                       ignore.suffices = ignore.suffices, 
                                       bounds = bounds, 
                                       initial.values = initial.values, ...)
      if (nrow(temp.asrt$test.summary) > nrow(test.summary))
      {
        if (asr4)
          warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                  ", boundary terms removed")
        else
          warning("In analysing ",asreml.obj$fixed.formula[[2]],
                  ", boundary terms removed")
      }
      if (temp.asrt$asreml.obj$converge)
      {
        asreml.obj <- temp.asrt$asreml.obj
        test.summary <- temp.asrt$test.summary
        #Update wald.tab
        if (asr4)
          wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
        else
          wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
        if (!is.data.frame(wald.tab))
          wald.tab <- wald.tab$Wald
      } else
      {
        p <- NA
        action <- "Unchanged - new unconverged"
      }
      test.summary <- addtoTestSummary(test.summary, terms = label, DF=NA, denDF = NA, 
                                       p = NA, action = action)
    }
  }
  results <- asrtests(asreml.obj = asreml.obj, 
                      wald.tab = wald.tab, 
                      test.summary = test.summary,
                      denDF = denDF, trace = trace, ...)
  invisible(results)
}

"testranfix.asrtests" <- function(asrtests.obj, term=NULL, alpha = 0.05, 
                                  allow.unconverged = TRUE, checkboundaryonly = FALSE, 
                                  drop.ran.ns = TRUE, positive.zero = FALSE, 
                                  bound.test.parameters = "none", 
                                  bound.exclusions = c("F","B","S","C"), REMLDF = NULL, 
                                  drop.fix.ns = FALSE, denDF="numeric", dDF.na = "none", 
                                  dDF.values = NULL, trace = FALSE, update = TRUE, 
                                  set.terms = NULL, ignore.suffices = TRUE, 
                                  bounds = "P", initial.values = NA, ...)
#function to test for a single term, using a REMLRT for a random term or based 
#on Wald statistics for a fixed term. Note that fixed terms are never dropped.
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #check input arguments
  if (class(asrtests.obj) != "asrtests")
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
           ", must supply an asrtests object")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
           ", must supply an asrtests object")
  }
  asreml.obj <- asrtests.obj$asreml.obj
  wald.tab <- asrtests.obj$wald.tab
  test.summary <- asrtests.obj$test.summary
  #Check for multiple terms
  term.form <- as.formula(paste("~ ",term, sep=""))
  term.obj <- as.terms.object(term, asreml.obj)
  if (length(labels(term.obj)) != 1)
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
           ", multiple terms not allowed in testranfix.asrtests")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
           ", multiple terms not allowed in testranfix.asrtests")
  }

    #Test whether term is in random model
  ranterms.obj <- as.terms.object(languageEl(asreml.obj$call, which="random"), asreml.obj)
  termno <- findterm(term, labels(ranterms.obj))
  if (termno == 0)
  #See if in fixed model
  { 
    if (asr4)
      termno <- findterm(term, rownames(asreml.obj$aov))
    else
      termno <- findterm(term, rownames(asreml.obj$aovTbl))
    #Term is not in either model
    if (termno == 0)
      #Term is not in either model
      test.summary <- addtoTestSummary(test.summary, terms = term, DF = NA, denDF = NA, 
                                       p = NA, action = "Absent")
    else
    #Have a fixed term
    { 
      if (asr4)
        wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      else
        wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
      if (!is.data.frame(wald.tab))
             wald.tab <- wald.tab$Wald
      options <- c("none", "residual", "maximum", "supplied")
      opt <- options[check.arg.values(dDF.na, options)]
      if (opt == "supplied" & is.null(dDF.values))
            stop('Need to set dDF.values because have set dDF.na = \"supplied\"')
      #Compute p-value
      p <- wald.tab[termno, 4]
      ndf <- wald.tab$Df[termno]
      den.df <- NA
      if ("denDF" %in% colnames(wald.tab) & !is.na(wald.tab$denDF[termno]))
         den.df <- wald.tab$denDF[termno]
      else
      { 
        if (opt == "supplied")
          den.df <- dDF.values[termno]
        else
        { 
          if (opt == "maximum") 
          { 
            if ("denDF" %in% colnames(wald.tab) & !all(is.na(wald.tab$denDF)))
              den.df <- max(wald.tab$denDF[-1], na.rm=TRUE) 
            else
              den.df <- asreml.obj$nedf
          } else
          { 
            if (opt == "residual")
              den.df <- asreml.obj$nedf
            else
              p <- NA
          }
        }
      }
      #Calc F, if necessary, and p
      if (!is.na(den.df))
      { if ("denDF" %in% colnames(wald.tab))
          test.stat <- wald.tab$F.inc[termno]
        else
          test.stat <- wald.tab$'Wald statistic'[termno]/ndf
        p <- 1 - pf(test.stat, ndf, den.df)
      }

      #Add record for test to test.summary and, if drop.fix.ns is TRUE, remove term
      if (is.na(p))
      {
        test.summary <- addtoTestSummary(test.summary, terms = rownames(wald.tab)[termno], 
                                         DF = ndf, denDF = NA, p = p, action = NA)
        
      } else
      {
        if (p <= alpha)
        {
          if (drop.fix.ns)
            test.summary <- addtoTestSummary(test.summary, terms = rownames(wald.tab)[termno], 
                                             DF = ndf, denDF = den.df, p = p, action = "Retained")
          else
            test.summary <- addtoTestSummary(test.summary, terms = rownames(wald.tab)[termno], 
                                             DF = ndf, denDF = den.df, p = p, action = "Significant")
        } else
        {
          if (drop.fix.ns)
          { 
            term.form <- as.formula(paste(". ~ . - ",term, sep=""))
            asreml.new.obj <- newfit.asreml(asreml.obj, fixed. = term.form, trace = trace, 
                                        update = update, 
                                        allow.unconverged = TRUE,
                                        set.terms = set.terms, 
                                        ignore.suffices = ignore.suffices, 
                                        bounds = bounds, 
                                        initial.values = initial.values, ...)
            if (asreml.new.obj$converge | allow.unconverged)
            {
              action <- "Dropped"
              asreml.obj <- asreml.new.obj
              #Update wald.tab
              if (asr4)
                wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, 
                                                 trace = trace, ...)
              else
                wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, 
                                                 trace = trace, ...)
              if (!is.data.frame(wald.tab))
                wald.tab <- wald.tab$Wald
              if (!asreml.obj$converge)
                action <- paste(action, " - unconverged", sep="")
              test.summary <- addtoTestSummary(test.summary, terms = term, 
                                               DF = ndf, denDF = den.df, 
                                               p = p, action = action)
              
              #Check for boundary terms
              temp.asrt <- rmboundary.asrtests(asrtests(asreml.obj, wald.tab, 
                                                        test.summary), 
                                               checkboundaryonly = checkboundaryonly, 
                                               trace = trace, update = update, 
                                               set.terms = set.terms, 
                                               ignore.suffices = ignore.suffices, 
                                               bounds = bounds, 
                                               initial.values = initial.values, ...)
              if (nrow(temp.asrt$test.summary) > nrow(test.summary))
              {
                if (asr4)
                  warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                       ", Boundary terms removed")
                else
                  warning("In analysing ",asreml.obj$fixed.formula[[2]],
                       ", Boundary terms removed")
              }
              asreml.obj <- temp.asrt$asreml.obj
              test.summary <- temp.asrt$test.summary
            } else #unconverged and not allowed
            {
              #Check for boundary terms
              temp.asrt <- rmboundary.asrtests(asrtests(asreml.new.obj, wald.tab, 
                                                        test.summary), 
                                               checkboundaryonly = checkboundaryonly, 
                                               trace = trace, update = update, 
                                               set.terms = set.terms, 
                                               ignore.suffices = ignore.suffices, 
                                               bounds = bounds, 
                                               initial.values = initial.values, ...)
              if (nrow(temp.asrt$test.summary) > nrow(test.summary))
              {
                if (asr4)
                  warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                          ", Boundary terms removed")
                else
                  warning("In analysing ",asreml.obj$fixed.formula[[2]],
                          ", Boundary terms removed")
              }
              if (temp.asrt$asreml.obj$converge) #have we now got convergence
              {
                asreml.obj <- temp.asrt$asreml.obj
                test.summary <- temp.asrt$test.summary
                action <- "Dropped"
              } else
              {
                p <- NA
                action = "Unchanged - unconverged"
              }
              test.summary <- addtoTestSummary(test.summary, terms = term, 
                                               DF = ndf, denDF = den.df, 
                                               p = p, action = action)
            }
          } else
          {
            test.summary <- addtoTestSummary(test.summary, terms = rownames(wald.tab)[termno], 
                                             DF = ndf, denDF = den.df, 
                                             p = p, action = "Nonsignificant")
          }
        }
      }
    }
  } else
  #Remove random term and test
  { 
    term.form <- as.formula(paste("~ . - ",term, sep=""))
    asreml.new.obj <- newfit.asreml(asreml.obj, random. = term.form, trace = trace, 
                                    update = update, 
                                    allow.unconverged = TRUE,
                                    set.terms = set.terms, 
                                    ignore.suffices = ignore.suffices, 
                                    bounds = bounds, 
                                    initial.values = initial.values, ...)


    
    

    if (!drop.ran.ns)
    {
      #Perform test
      test <- REMLRT.asreml(h1.asreml.obj = asreml.obj, h0.asreml.obj = asreml.new.obj, 
                            positive.zero = positive.zero, 
                            bound.exclusions = bound.exclusions, DF = REMLDF, 
                            bound.test.parameters = bound.test.parameters)
      if (!allow.unconverged && (!asreml.obj$converge | !asreml.new.obj$converge))
      {
        p <- NA
        if (!asreml.obj$converge)
        {
          if (!asreml.new.obj$converge)
          {
            action <- "Both unconverged"
          } else
          {
            action <- "Old unconverged"
          }
        } else
        {
          action <- "New unconverged"
        }
      } else
      { 
        if (test$DF <= 0)
          p <- NA
        else
          p <- test$p
        if (is.na(p) || p <= alpha)
        {
          action <- "Significant"
        } else
        { 
          action <- "Nonsignificant"
        }
        if (!asreml.new.obj$converge)
          action <- paste(action, " - new unconverged", sep="")
      }
    } else #drop.ran.ns
    {
      if (!allow.unconverged && !asreml.new.obj$converge)
      {
        #If new model not converged then see if removing boundary terms will result in convergence
        temp.asrt <- rmboundary.asrtests(asrtests(asreml.new.obj, wald.tab, 
                                                  test.summary), 
                                         checkboundaryonly = checkboundaryonly, 
                                         trace = trace, update = update, 
                                         set.terms = set.terms, 
                                         ignore.suffices = ignore.suffices, 
                                         bounds = bounds, 
                                         initial.values = initial.values, ...)
        if (nrow(temp.asrt$test.summary) > nrow(test.summary))
        {
          if (asr4)
            warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                    ", Boundary terms removed")
          else
            warning("In analysing ",asreml.obj$fixed.formula[[2]],
                    ", Boundary terms removed")
        }
        if (temp.asrt$asreml.obj$converge)
        {
          asreml.obj <- temp.asrt$asreml.obj
          test.summary <- temp.asrt$test.summary
          term.form <- as.formula(paste("~ . + ",term, sep=""))
          asreml.new.obj <- newfit.asreml(asreml.obj, random. = term.form, trace = trace, 
                                          update = update, 
                                          allow.unconverged = TRUE,
                                          set.terms = set.terms, 
                                          ignore.suffices = ignore.suffices, 
                                          bounds = bounds, 
                                          initial.values = initial.values, ...)
        }
      }
      
      #Perform the test
      test <- REMLRT.asreml(h1.asreml.obj = asreml.obj, h0.asreml.obj = asreml.new.obj, 
                            positive.zero = positive.zero, 
                            bound.exclusions = bound.exclusions, DF = REMLDF, 
                            bound.test.parameters = bound.test.parameters)

      #Check convergence and force a converged model, if possible
      if (!allow.unconverged && (!asreml.obj$converge | !asreml.new.obj$converge))
      {
        p <- NA
        if (!asreml.new.obj$converge)
        {
          if (!asreml.obj$converge)
          {
            action <- "Retained - both unconverged"
            change <- FALSE
          } else
          {
            action <- "Retained - new unconverged"
            change <- FALSE
          }
        } else
        {
          action <- "Dropped - old unconverged"
          asreml.obj <- asreml.new.obj
          #Update wald.tab
          if (asr4)
            wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
          else
            wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
          if (!is.data.frame(wald.tab))
            wald.tab <- wald.tab$Wald
        }
      } else #Evaluate test for drop.ran.ns
      {
        if (test$DF <= 0)
          p <- NA
        else
          p <- test$p
        if (is.na(p) || p <= alpha)
        {
          if (drop.ran.ns)
          {
            action <- "Retained"
          } else
          {
            action <- "Significant"
          }
        } else
        { 
            action <- "Dropped"
            asreml.obj <- asreml.new.obj
            #Update wald.tab
            if (asr4)
              wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
            else
              wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
            if (!is.data.frame(wald.tab))
              wald.tab <- wald.tab$Wald
        }
        if (!asreml.new.obj$converge)
          action <- paste(action, " - new unconverged", sep="")
      }
    }
      
    #Update summary
    test.summary <- addtoTestSummary(test.summary, terms = term, DF=test$DF, denDF = NA, 
                                     p = p, action = action)

    #Check for boundary terms
    temp.asrt <- rmboundary.asrtests(asrtests(asreml.obj, wald.tab, test.summary), 
                                     checkboundaryonly = checkboundaryonly, 
                                     trace = trace, update = update, 
                                     set.terms = set.terms, 
                                     ignore.suffices = ignore.suffices, 
                                     bounds = bounds, 
                                     initial.values = initial.values, ...)
    if (nrow(temp.asrt$test.summary) > nrow(test.summary))
    {
      if (asr4)
        warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                ", Boundary terms removed")
      else
        warning("In analysing ",asreml.obj$fixed.formula[[2]],
                ", Boundary terms removed")
    }
    asreml.obj <- temp.asrt$asreml.obj
    test.summary <- temp.asrt$test.summary
  }
  
  
  results <- asrtests(asreml.obj = asreml.obj, 
                      wald.tab = wald.tab, 
                      test.summary = test.summary,
                      denDF = denDF, dDF.na = dDF.na, 
                      dDF.values = dDF.values, trace = trace, ...)
  invisible(results)
}

"testswapran.asrtests" <- function(asrtests.obj, oldterms = NULL, newterms = NULL, 
                                   label = "Swap in random model", simpler = FALSE, 
                                   alpha = 0.05, allow.unconverged = TRUE, 
                                   checkboundaryonly = FALSE, 
                                   positive.zero = FALSE, bound.test.parameters = "none", 
                                   bound.exclusions = c("F","B","S","C"), REMLDF = NULL, 
                                   denDF="numeric", trace = FALSE, update = TRUE, 
                                   set.terms = NULL, ignore.suffices = TRUE, 
                                   bounds = "P", initial.values = NA, ...)
  #function to test difference between current random model and one in which oldterms are dropped 
  #and newterms are added, using a REMLRT.
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())

    #check input arguments
  if (class(asrtests.obj) != "asrtests")
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
              ", must supply an asrtests object")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
              ", must supply an asrtests object")
  }
  asreml.obj <- asrtests.obj$asreml.obj
  wald.tab <- asrtests.obj$wald.tab
  test.summary <- asrtests.obj$test.summary

  #Test whether oldterms are in random model
  oldterms.obj <- as.terms.object(oldterms, asreml.obj)
  ranterms.obj <- as.terms.object(languageEl(asreml.obj$call, which="random"), asreml.obj)
  termno <- findterm(oldterms, labels(ranterms.obj))
  if (any(lapply(labels(oldterms.obj), findterm, termlist=labels(ranterms.obj)) == 0))
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
           ", some random terms in oldterms not in random model")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
           ", some random terms in oldterms not in random model")
  }

  #Remove random oldterms and add random newterms
  new.form <- as.formula(paste("~ . - ",oldterms," + ",newterms, sep=""))
  asreml.new.obj <- newfit.asreml(asreml.obj, random. = new.form, 
                                  trace = trace, update = update, 
                                  allow.unconverged = TRUE,
                                  set.terms = set.terms, 
                                  ignore.suffices = ignore.suffices, 
                                  bounds = bounds, 
                                  initial.values = initial.values, ...)
  change <- FALSE
  #Perform the test
  if (simpler)
  { 
    test <- REMLRT.asreml(h1.asreml.obj = asreml.obj, h0.asreml.obj = asreml.new.obj, 
                          positive.zero = positive.zero,
                          bound.exclusions = bound.exclusions, DF = REMLDF, 
                          bound.test.parameters = bound.test.parameters)
  } else
  {
    test <- REMLRT.asreml(h1.asreml.obj = asreml.new.obj, h0.asreml.obj = asreml.obj, 
                          positive.zero = positive.zero,
                          bound.exclusions = bound.exclusions, DF = REMLDF, 
                          bound.test.parameters = bound.test.parameters)
  }
  
  #check convergence
  if (!allow.unconverged && (!asreml.obj$converge | !asreml.new.obj$converge))
  {
    p <- NA
    if (!asreml.obj$converge)
    {
      if (!asreml.new.obj$converge)
      {
        action <- "Unchanged - both unconverged"
        change <- FALSE
      } else
      {
        action <- "Swapped - old unconverged"
        change <- TRUE
      }
    } else
    {
      action <- "Unchanged - new unconverged"
      change <- FALSE
    }
  } else
  {
    #Evaluate the test
    if (simpler)
    { 
      if (test$DF <= 0)
        p <- NA
      else
        p <- test$p
      if (is.na(p) | p <= alpha)
        action <- "Unswapped"
      else
      { 
        action <- "Swapped"
        change <- TRUE
      }
    }
    else
    { 
      if (test$DF <= 0)
        p <- NA
      else
        p <- test$p
      if (!is.na(p) & p <= alpha)
      { 
        action = "Swapped"
        change <- TRUE
      }
      else
      { 
        action = "Rejected"
      }
    }
    #check convergence, when it is allowed
    if (allow.unconverged)
    {
      if (!asreml.obj$converge & !asreml.new.obj$converge)
      {
        action <- paste(action, " - both unconverged", sep="")
      } else
      {
        if (!asreml.obj$converge)
          action <- paste(action, " - old unconverged", sep="")
        else
        {
          if (!asreml.new.obj$converge)
            action <- paste(action, " - new unconverged", sep="")
        }
      }
    }
  }
  test.summary <- addtoTestSummary(test.summary, terms = label, DF=test$DF, denDF = NA, 
                                   p = p, action = action)
  
  #Update results
  if (change)
  { 
    #Check for boundary terms
    temp.asrt <- rmboundary.asrtests(asrtests(asreml.new.obj, wald.tab, test.summary), 
                                     checkboundaryonly = checkboundaryonly, 
                                     trace = trace, update = update, 
                                     set.terms = set.terms, 
                                     ignore.suffices = ignore.suffices, 
                                     bounds = bounds, 
                                     initial.values = initial.values, ...)
    if (nrow(temp.asrt$test.summary) > nrow(test.summary))
    {
      if (asr4)
        warning("In swapping random terms for ",asreml.obj$formulae$fixed[[2]],
                ", Boundary terms removed")
      else
        warning("In swapping random terms for ",asreml.obj$fixed.formula[[2]],
                ", Boundary terms removed")
    }
    asreml.obj <- temp.asrt$asreml.obj
    test.summary <- temp.asrt$test.summary
    #Update wald.tab
    if (asr4)
      wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
    else
      wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
    if (!is.data.frame(wald.tab))
      wald.tab <- wald.tab$Wald
  }
  results <- asrtests(asreml.obj = asreml.obj, 
                      wald.tab = wald.tab, 
                      test.summary = test.summary, 
                      denDF = denDF, trace = trace, ...)
  invisible(results)
}


"testresidual.asrtests" <- function(asrtests.obj, terms = NULL, label = "R model", 
                                    simpler = FALSE, alpha = 0.05, 
                                    allow.unconverged = TRUE, checkboundaryonly = FALSE, 
                                    positive.zero = FALSE, bound.test.parameters = "none", 
                                    bound.exclusions = c("F","B","S","C"), REMLDF = NULL, 
                                    denDF="numeric", update = TRUE, trace = FALSE, 
                                    set.terms = NULL, ignore.suffices = TRUE, 
                                    bounds = "P", initial.values = NA, ...)
#Fits new residual formula and tests whether the change is significant
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in testresidual.asreml - use bounds")

  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #check input arguments
  if (asr4)
    kresp <- asrtests.obj$asreml.obj$formulae$fixed[[2]]
  else
    kresp <- asrtests.obj$asreml.obj$fixed.formula[[2]]    
  if (is.null(terms))
    stop("In analysing ", kresp, ", must supply terms to be tested")
  else
    if (!is.character(terms))
      stop("In analysing ", kresp, ", must supply terms as character")
  if (class(asrtests.obj) != "asrtests")
    stop("In analysing ", kresp, ", must supply an asrtests object")
  
  #initialize
  asreml.obj <- asrtests.obj$asreml.obj
  wald.tab <- asrtests.obj$wald.tab
  test.summary <- asrtests.obj$test.summary
  term.form <- as.formula(paste("~ ", terms, sep=""))
  #Update the R model
  if (asr4)
    asreml.new.obj <- newfit.asreml(asreml.obj, residual. = term.form, 
                                    trace = trace, update = update, 
                                    allow.unconverged = TRUE,
                                    set.terms = set.terms, 
                                    ignore.suffices = ignore.suffices, 
                                    bounds = bounds, 
                                    initial.values = initial.values, ...)
  else
    asreml.new.obj <- newfit.asreml(asreml.obj, rcov. = term.form, 
                                    trace = trace, update = update, 
                                    allow.unconverged = TRUE,
                                    set.terms = set.terms, 
                                    ignore.suffices = ignore.suffices, 
                                    bounds = bounds, 
                                    initial.values = initial.values, ...)
  
  change <- FALSE
  #Perform the test
  if (simpler)
  { 
    test <- REMLRT.asreml(h1.asreml.obj = asreml.obj, h0.asreml.obj = asreml.new.obj, 
                          positive.zero = positive.zero, 
                          bound.exclusions = bound.exclusions, DF = REMLDF, 
                          bound.test.parameters = bound.test.parameters)
  } else
  {
    test <- REMLRT.asreml(h1.asreml.obj = asreml.new.obj, h0.asreml.obj = asreml.obj, 
                          positive.zero = positive.zero, 
                          bound.exclusions = bound.exclusions, DF = REMLDF, 
                          bound.test.parameters = bound.test.parameters)
  }
  
  #check convergence
  if (!allow.unconverged && (!asreml.obj$converge | !asreml.new.obj$converge))
      {
        p <- NA
        if (!asreml.obj$converge)
        {
          if (!asreml.new.obj$converge)
          {
            action <- "Unchanged - both unconverged"
            change <- FALSE
          } else
          {
            action <- "Swappped - old unconverged"
            change <- TRUE
          }
        } else
        {
          action <- "Unchanged - new unconverged"
          change <- FALSE
        }
  } else
  {
    #Evaluate the test
    if (simpler)
    { 
      if (test$DF <= 0)
        p <- NA
      else
        p <- test$p
      if (!is.na(p) & p <= alpha)
        action <- "Unswapped"
      else
      { 
        action = "Swapped"
        change <- TRUE
      }
    }
    else
    { 
      if (test$DF <= 0)
        p <- NA
      else
        p <- test$p
      if (!is.na(p) & p <= alpha)
      { 
        action = "Swapped"
        change <- TRUE
      }
      else
        action = "Rejected"
    }
    
    #check convergence, when it is allowed
    if (allow.unconverged)
    {
      if (!asreml.obj$converge && !asreml.new.obj$converge)
      {
        action <- paste(action, " - both unconverged", sep="")
      } else
      {
        if (!asreml.obj$converge)
          action <- paste(action, " - old unconverged", sep="")
        else
        {
          if (!asreml.new.obj$converge)
            action <- paste(action, " - new unconverged", sep="")
        }
      }
    }
  }
  test.summary <- addtoTestSummary(test.summary, terms = label, DF=test$DF, denDF = NA, 
                                   p = p, action = action)
  
  #Update results
  if (change)
  { 
    #Check for boundary terms
    temp.asrt <- rmboundary.asrtests(asrtests(asreml.new.obj, wald.tab, test.summary), 
                                     checkboundaryonly = checkboundaryonly, 
                                     trace = trace, update = update, 
                                     set.terms = set.terms, 
                                     ignore.suffices = ignore.suffices, 
                                     bounds = bounds, 
                                     initial.values = initial.values, ...)
    if (nrow(temp.asrt$test.summary) > nrow(test.summary))
    {
      if (asr4)
        warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                ", boundary terms removed")
      else
        warning("In analysing ",asreml.obj$fixed.formula[[2]],
                ", boundary terms removed")
    }
    asreml.obj <- temp.asrt$asreml.obj
    test.summary <- temp.asrt$test.summary
    #Update wald.tab
    if (asr4)
      wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
    else
      wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
    if (!is.data.frame(wald.tab))
      wald.tab <- wald.tab$Wald
  } 
  results <- asrtests(asreml.obj = asreml.obj, 
                      wald.tab = wald.tab, 
                      test.summary = test.summary,
                      denDF = denDF, trace = trace, ...)
  invisible(results)
}


"permute.square" <- function(x, permutation)
{ #function to permute the rows and coluns of a square matrix
  if (!is.matrix(x) || nrow(x) != ncol(x))
    stop("x must be a square matrix")
  permuted <- x[permutation, permutation]
  if (!is.null(rownames(x)))
    rownames(x) <- (rownames(x))[permutation]
  if (!is.null(colnames(x)))
    colnames(x) <- (colnames(x))[permutation]
  return(permuted)
}

"permute.to.zero.lowertri" <- function(x)
{ 
  #function to permute a square matrix until all the lower triangular elements are zero
  if (!is.matrix(x) || nrow(x) != ncol(x))
    stop("x must be a square matrix")
  m <- dim(x)[1]
  noperm <- m*(m-1)/2
  if (length(which(x == 0)) < noperm)
    stop("not enough zero elements to permute to all-zero, lower triangular form")
  x.lt <- matrix(0, nrow=m, ncol=m)
  x.lt[lower.tri(x.lt)] <- x [lower.tri(x)]
  i = 0
  #perform permutations until zero lower triangle 
  #or have done twice the no. of possible permutations
  while (any(x.lt == 1) && i <= noperm*2)
  { 
    #find the non-zero element in rightmost column (c) of the lowest row (r)
    nonzero <- which(x.lt == 1, arr.ind=TRUE)
    nonzero <- nonzero[nonzero[, 1] == max(nonzero[, 1]), ]
    if (!is.null(nrow(nonzero)))
        nonzero <- nonzero[nonzero[, 2] == max(nonzero[, 2]), ]
    #perform the permutation that in interchanges rows r and c and columns r and c
    permtn <- 1:m
    permtn[nonzero[1]] <- nonzero[2]
    permtn[nonzero[2]] <- nonzero[1]
    x <- permute.square(x, permtn)
    #get new lower triangle
    x.lt <- matrix(0, nrow=m, ncol=m)
    x.lt[lower.tri(x.lt)] <- x [lower.tri(x)]
  } 
  if (any(x.lt == 1))
    stop("Unable to form matrix with all zero lower triangular elements")
  return(x)
}

"chooseModel.asrtests" <- function(asrtests.obj, terms.marginality=NULL, alpha = 0.05, 
                                   allow.unconverged = TRUE, checkboundaryonly = FALSE, 
                                   drop.ran.ns=TRUE, positive.zero = FALSE, 
                                   bound.test.parameters = "none", 
                                   drop.fix.ns=FALSE, denDF = "numeric",  dDF.na = "none", 
                                   dDF.values = NULL, trace = FALSE, update = TRUE, 
                                   set.terms = NULL, ignore.suffices = TRUE, 
                                   bounds = "P", initial.values = NA, ...)
#function to determine the set of significant terms taking into account marginality relations
#terms.marginality should be a square matrix of ones and zeroes with row and column names 
#   being the names of the terms. The diagonal elements should be one, indicating 
#   that a term is marginal to itself. Elements should be one if the row term is 
#   marginal to the column term. All other elements should be zero. 
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())

  #check input arguments
  if (class(asrtests.obj) != "asrtests")
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
              ", must supply an asrtests object")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
              ", must supply an asrtests object")
  }

  #check matrix  
  if (!is.matrix(terms.marginality) || 
           nrow(terms.marginality) != ncol(terms.marginality))
  {
    if (asr4)
      stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
           ", must supply an asrtests object")
    else
      stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
           ", must supply an asrtests object")
  }
  else
   if (is.null(rownames(terms.marginality)) || is.null(colnames(terms.marginality)))
   {
     if (asr4)
       stop("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
            ", terms.marginality must have row and column names that are the terms to be tested")
     else
       stop("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
            ", terms.marginality must have row and column names that are the terms to be tested")
   }
   else
     if (det(terms.marginality) == 0)
     {
       if (asr4)
         warning("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
                 ", Suspect marginalities of terms not properly specified - check")
       else
         warning("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
                 ", Suspect marginalities of terms not properly specified - check")
     }
  #make sure have a terms.marginality matrix with lower triangle all zero
  terms.marginality <- permute.to.zero.lowertri(terms.marginality)
  #perform tests
  sig.terms <- vector("list", length = 0)
  noterms <- dim(terms.marginality)[1]
  current.asrt <- asrtests.obj
  j <- noterms
  #traverse the columns of terms.marginality
  while (j > 0)
  { 
    #get p-value for term for column j and, if random, drop if ns and drop.ran.ns=TRUE
    term <- (rownames(terms.marginality))[j]
    current.asrt <- testranfix.asrtests(asrtests.obj = current.asrt, term, 
                                        alpha=alpha, allow.unconverged = allow.unconverged, 
                                        checkboundaryonly = checkboundaryonly,  
                                        drop.ran.ns = drop.ran.ns, 
                                        positive.zero = positive.zero, 
                                        bound.test.parameters = bound.test.parameters, 
                                        drop.fix.ns = drop.fix.ns, 
                                        denDF = denDF, dDF.na = dDF.na, 
                                        dDF.values = dDF.values, trace = trace, 
                                        update = update, set.terms = set.terms, 
                                        ignore.suffices = ignore.suffices, 
                                        bounds = bounds, 
                                        initial.values = initial.values, ...)
    test.summary <- current.asrt$test.summary
    p <- (test.summary[tail(findterm(term, as.character(test.summary$terms)),1), ])$p
    #if significant, add to sig term list and work out which can be tested next
    if (!is.na(p)) 
    { if (p <= alpha)
      { sig.terms <- c(sig.terms, term)
        nonnest <- which(terms.marginality[1:(j-1), j] == 0)
        noterms <- length(nonnest)
        if (noterms == 0)
          j = 0
        else
        { if (noterms == 1)
          { nonnest.name <- rownames(terms.marginality)[nonnest]
            terms.marginality <- terms.marginality[nonnest, nonnest]
            dim(terms.marginality) <- c(1,1)
            rownames(terms.marginality) <- nonnest.name
          }
          else
          { terms.marginality <- terms.marginality[nonnest, nonnest]
          }
          j <- noterms
        }
      }
      #if not significant, proceed to previous column
      else
        j <- j - 1
    }
    else
      j <- j - 1
  }
  invisible(list(asrtests.obj = current.asrt, sig.terms = sig.terms))  
}

"reparamSigDevn.asrtests" <- function(asrtests.obj, terms = NULL, 
                                      trend.num = NULL, devn.fac = NULL, 
                                      allow.unconverged = TRUE, checkboundaryonly = FALSE, 
                                      denDF = "numeric", trace = FALSE, update = TRUE, 
                                      set.terms = NULL, ignore.suffices = TRUE, 
                                      bounds = "P", initial.values = NA, ...)
#reparamterizes a deviations term to a fixed term
#It assumes that the deviations term are deviations from trend in trend.num and 
#  that there is a random deviations term that involves devn.fac
#Also assumes that the same term, but with the devn.fac substitued by trend.num
#   and spl(trend.num), are in the fixed and random models respectively.
#Retains the trend.num term if there are any significant terms involving it.
{ 
  #Deal with deprecated constraints parameter
  tempcall <- list(...)
  if (length(tempcall)) 
    if ("constraints" %in% names(tempcall))
      stop("constraints has been deprecated in setvarianceterms.asreml - use bounds")
  
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  #find out if any terms have either a devn.fac or a trend.num term 
  #  - (marginality implies cannot be both)
  asrtests.old.obj <- asrtests.obj
  term.types <- trend.terms.types(terms = terms, devn.fac = devn.fac, trend.num = trend.num)
  #Check have terms involving devn.fac or trend.num
  if (term.types$has.devn.fac || term.types$has.trend.num)
    #Now reparamaterize deviations terms, the method depending on whether or not have a mixture
  { 
    for (term in terms)
    { 
      factors <- fac.getinTerm(term)
      #Check this term involves a devn fac
      if (!is.null(devn.fac) && any(devn.fac %in%  factors))
      { #Have mixture so convert random deviations to lin(trend.num) + fixed devn.fac deviations
        #form spl(time.num) and random deviation
        spl.term <- sub(devn.fac,paste("spl(",trend.num,")", sep=""),term)
        ran.term <- paste(spl.term, term, sep = " + " )
        if (term.types$has.devn.fac && term.types$has.trend.num)
        { 
          #Add time.num term to be sure - will do nothing if already there
          lin.term <- sub(devn.fac,trend.num,term)
          asrtests.obj <- changeTerms.asrtests(asrtests.obj, 
                                               addFixed = paste(lin.term, term, sep = " + " ), 
                                               dropRandom = ran.term, 
                                               trace = trace, allow.unconverged = TRUE, 
                                               update = update, set.terms = set.terms, 
                                               ignore.suffices = ignore.suffices, 
                                               bounds = bounds, 
                                               initial.values = initial.values, ...)
        } else
        {
          #remove spl(time.num) and random deviation and add devn term to fixed model
          asrtests.obj <- changeTerms.asrtests(asrtests.obj, addFixed = term, 
                                               dropRandom = ran.term, 
                                               trace = trace, allow.unconverged = TRUE, 
                                               update = update, set.terms = set.terms, 
                                               ignore.suffices = ignore.suffices, 
                                               bounds = bounds, 
                                               initial.values = initial.values, ...)
          
        }
      }
    }
  }
  if (!allow.unconverged)
  {
    if (!asrtests.obj$asreml.obj$converge)
    {
      #Check for boundary terms
      temp.asrt <- rmboundary.asrtests(asrtests.obj, 
                                       checkboundaryonly = checkboundaryonly,  
                                       trace = trace, update = update, 
                                       set.terms = set.terms, 
                                       ignore.suffices = ignore.suffices, 
                                       bounds = bounds, 
                                       initial.values = initial.values, ...)
      if (nrow(temp.asrt$test.summary) > nrow(asrtests.obj$test.summary))
      {
        if (asr4)
          warning("In analysing ",asrtests.obj$asreml.obj$formulae$fixed[[2]],
                  ", boundary terms removed")
        else
          warning("In analysing ",asrtests.obj$asreml.obj$fixed.formula[[2]],
                  ", boundary terms removed")
      }
      if (temp.asrt$asreml.obj$converge)
      {
        asrtests.obj <- temp.asrt
        asreml.obj <- asrtests.obj$asreml.obj
        #Update wald.tab
        if (asr4)
          wald.tab <- asreml4::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
        else
          wald.tab <- asreml::wald.asreml(asreml.obj, denDF = denDF, trace = trace, ...)
        if (!is.data.frame(wald.tab))
          wald.tab <- wald.tab$Wald
        asrtests.obj$wald.tab <- wald.tab
      } else
      {
        asrtests.obj <- asrtests.old.obj
      }
    }
  }
  asrtests.obj$wald.tab <- recalcWaldTab(asrtests.obj, denDF = denDF, trace = trace, ...)
  invisible(asrtests.obj)
}

"predictPlus.asreml" <- function(asreml.obj, classify, term = NULL, 
                                 linear.transformation = NULL, 
                                 titles = NULL, x.num = NULL, x.fac = NULL,  
                                 x.pred.values = NULL, x.plot.values = NULL, 
                                 error.intervals = "Confidence", avsed.tolerance = 0.25, 
                                 meanLSD.type = "overall", LSDby = NULL, 
                                 pairwise = TRUE, Vmatrix = FALSE, 
                                 tables = "all", level.length = NA, 
                                 transform.power = 1, offset = 0, scale = 1, 
                                 inestimable.rm = TRUE, 
                                 sortFactor = NULL, sortWithinVals = NULL, 
                                 sortOrder = NULL, decreasing = FALSE, 
                                 wald.tab = NULL, alpha = 0.05, 
                                 dDF.na = "residual", dDF.values = NULL, trace = FALSE, ...)
  #a function to get asreml predictions when there a parallel vector and factor are involved
{ 
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  AvLSD.options <- c("overall", "factor.combinations", "per.prediction")
  avLSD <- AvLSD.options[check.arg.values(meanLSD.type, AvLSD.options)]
  if (!is.null(LSDby) &&  !is.character(LSDby))
    stop("LSDby must be a character")
  
  #Get ... argument so can check for levels argument
  tempcall <- list(...)
  if ("levels.length" %in% names(tempcall))
    stop("levels.length has been deprecated - use level.length")
  if ("vcov" %in% names(tempcall))
    stop("Use Vmatrix to request that the vcov matrix be saved")

  if (!is.null(wald.tab) & (!is.data.frame(wald.tab) || ncol(wald.tab) != 4))
    stop("wald.tab should be a 4-column data.frame -- perhaps extract Wald component from list")
  if (!is.null(x.pred.values) && !is.null(x.plot.values))
    if (length(x.pred.values) != length(x.plot.values))
    {
      if (asr4)
        stop("In analysing ",asreml.obj$formulae$fixed[[2]],
             ", length of x.pred.values and x.plot.values should be equal")
      else
        stop("In analysing ",asreml.obj$fixed.formula[[2]],
             ", length of x.pred.values and x.plot.values should be equal")
    }
  if (!is.na(avsed.tolerance) & (avsed.tolerance <0 | avsed.tolerance > 1))
    stop("avsed.tolerance should be between 0 and 1")
  int.options <- c("none", "Confidence", "StandardError", "halfLeastSignificant")
  int.opt <- int.options[check.arg.values(error.intervals, int.options)]
  #Get table option and  check if must form pairwise differences
  tab.options <- c("none", "predictions", "vcov", "backtransforms", 
                   "differences", "p.differences", "sed", "LSD", "all")
  table.opt <- tab.options[unlist(lapply(tables, check.arg.values, options=tab.options))]
  if ("all" %in% table.opt || "differences" %in% table.opt || 
      int.opt == "halfLeastSignificant")
    pairwise <- TRUE
  #Make sure no functions in classify
  vars <- fac.getinTerm(classify, rmfunction=TRUE)
  classify <- fac.formTerm(vars)
  #Check if need vcov matrix
  if (!is.null(linear.transformation) || Vmatrix)
    get.vcov <- TRUE
  else
    get.vcov <- FALSE

  #Get the predicted values when x.num is not involved in classify
  if (is.null(x.num) || !(x.num %in% vars))
  { 
    if (asr4)
      pred <- predict(asreml.obj, classify=classify, 
                      sed=pairwise, vcov = get.vcov, 
                      trace = trace, ...)
    else
      pred <- predict(asreml.obj, classify=classify, 
                      sed=pairwise, vcov = get.vcov,  
                      trace = trace, ...)$predictions
    if (!is.null(x.fac) && x.fac %in% vars)
    { 
      k <- match(x.fac, names(pred$pvals))
      #Set x values for plotting and table labels in x.fac
      if (is.numeric(pred$pvals[[k]]))
      { 
        if (!is.null(x.plot.values))
          pred$pvals[[k]] <- num.recode(pred$pvals[[k]], x.plot.values)
      }
      else
      { 
        if (is.character(pred$pvals[[k]]))
          pred$pvals[[k]] <- factor(pred$pvals[[k]])
        if (!is.null(x.plot.values))
        { 
          pred$pvals[[k]] <- fac.recode(pred$pvals[[k]], x.plot.values)
          pred$pvals[[k]] <- as.numfac(pred$pvals[[k]])
        }
        else
          if (all(is.na((as.numfac(pred$pvals[[k]])))))
            stop(paste("the levels of ",x.fac, "are not numeric in nature"))
          else
            pred$pvals[[k]] <- as.numfac(pred$pvals[[k]])
      }
    }
    else #make sure all variables are factors
    { 
      pred$pvals[vars] <- lapply(1:length(vars), 
                                 function(k, vars, data){
                                   if (!is.factor(data[[vars[k]]]))
                                     data[vars[k]] <- factor(data[[vars[k]]])
                                   return(data[[vars[k]]])}, 
                                 data=pred$pvals, vars=vars)
    }
  } else
    #Get the predicted values when x.num is involved in classify
  { 
    #if levels in ... ignore x.pred.values
    if ("levels" %in% names(tempcall)) 
      if (asr4)
        pred <- predict(asreml.obj, classify=classify, 
                        sed = pairwise, vcov = get.vcov, 
                        trace = trace, ...)
      else
        pred <- predict(asreml.obj, classify=classify, 
                        sed = pairwise,  vcov = get.vcov, 
                        trace = trace, ...)$predictions
      
      else
    {
      if (is.null(x.pred.values)) 
      {
        if (asr4)
          warning("In analysing ",asreml.obj$formulae$fixed[[2]],
                  ", predictions involve ",x.num,
                  " - you may want to specify x.pred.values or levels")
        else
          warning("In analysing ",asreml.obj$fixed.formula[[2]],
                  ", predictions involve ",x.num,
                  " - you may want to specify x.pred.values or levels")
      }
      x.list <- list(x.pred.values)
      names(x.list) <- x.num
      if (asr4)
        pred <- predict(asreml.obj, classify=classify, levels=x.list, 
                        sed = pairwise, vcov = get.vcov, 
                        trace = trace, ...)
      else
        pred <- predict(asreml.obj, classify=classify, levels=x.list, 
                        sed = pairwise, vcov = get.vcov, 
                        trace = trace, ...)$predictions
    }
    k <- match(x.num, names(pred$pvals))
    #Set x values for plotting and table labels in x.num
    if (!is.null(x.plot.values))
      pred$pvals[[k]] <- num.recode(pred$pvals[[k]], x.plot.values)
  }
  #Check that x.num and x.fac are conformable
  if ((!is.null(x.num) && x.num %in% names(pred$pvals)) && 
      (!is.null(x.fac) && x.fac %in% names(pred$pvals)))
  { 
    kn <- match(x.num, names(pred$pvals))
    kf <- match(x.fac, names(pred$pvals))  
    if (is.factor(pred$pvals[[kf]]))
      if (length(levels(pred$pvals[[kf]])) != length(unique(pred$pvals[[kn]])))
      {
        if (asr4)
          stop("In analysing ",asreml.obj$formulae$fixed[[2]],
               ", length of ",x.num," and the number of levels of ",x.fac," must be equal")
        else
          stop("In analysing ",asreml.obj$fixed.formula[[2]],
               ", length of ",x.num," and the number of levels of ",x.fac," must be equal")
      }
    else
      if (length(unique(pred$pvals[[kf]])) != length(unique(pred$pvals[[kn]])))
      {
        if (asr4)
          stop("In analysing ",asreml.obj$formulae$fixed[[2]],
               ", length of ",x.num," and the number of levels of ",x.fac," must be equal")
        else
          stop("In analysing ",asreml.obj$fixed.formula[[2]],
               ", length of ",x.num," and the number of levels of ",x.fac," must be equal")
      }
  }
  #Get denominator degrees of freedom
  if (is.null(term))
    term <- classify
  denom.df <- NA
  if (!(int.opt %in% c("none", "StandardError")))
  { 
    if (is.null(wald.tab))
      stop("wald.tab needs to be set so that denDF values are available")
    i <- findterm(term, rownames(wald.tab))
    if (i == 0)
    { 
      {
        if (asr4)
          warning("For ",asreml.obj$formulae$fixed[[2]],
                  ", ",term," is not a fixed term that has been fitted")
        else
          warning("For ",asreml.obj$fixed.formula[[2]],
                  ", ",term," is not a fixed term that has been fitted")
      }
      denom.df <- asreml.obj$nedf
    }
    else
    { 
      #Get options for dDF.na
      options <- c("none", "residual", "maximum", "supplied")
      opt <- options[check.arg.values(dDF.na, options)]
      if (opt == "supplied" & is.null(dDF.values))
        stop('Need to set dDF.values because have set dDF.na = \"supplied\"')
      #Compute denom.df
      denom.df <- NA
      if ("denDF" %in% colnames(wald.tab) & !is.na(wald.tab$denDF[i]))
        denom.df <- wald.tab$denDF[i]
      else
      { 
        if (opt == "supplied")
          denom.df <- dDF.values[i]
        else
        { 
          if (opt == "maximum") 
          { 
            if ("denDF" %in% colnames(wald.tab) & !all(is.na(wald.tab$denDF)))
              denom.df <- max(wald.tab$denDF[-1], na.rm=TRUE) 
            else
              denom.df <- asreml.obj$nedf
          }
          else
          { 
            if (opt == "residual")
              denom.df <- asreml.obj$nedf
          }
        }
      }
    }
  }
  
  
  #Initialize for setting up alldiffs object
  if (asr4)
    response <- as.character(asreml.obj$formulae$fixed[[2]])
  else
    response <- as.character(asreml.obj$fixed.formula[[2]])
  if (!is.null(titles) & !is.na(match(response, names(titles))))
    response.title <- titles[[response]]
  else
  {
    response.title <- response
    if (!is.null(linear.transformation))
      response.title <- paste(response.title, "transform(s)", sep = " ")
  }

  #Form alldiffs object for predictions
  if (!get.vcov)
    lintrans.vcov <- NULL
  else
    lintrans.vcov <- pred$vcov
  diffs <- allDifferences(predictions = pred$pvals, vcov = lintrans.vcov, 
                          sed = pred$sed, meanLSD.type = meanLSD.type, LSDby = LSDby, 
                          response = response, response.title =  response.title, 
                          term = term, classify = classify, 
                          tdf = denom.df, 
                          x.num = x.num, x.fac = x.fac,
                          level.length = level.length, 
                          pairwise = pairwise, 
                          inestimable.rm = inestimable.rm, 
                          alpha = alpha)
  
  if (is.null(linear.transformation))
  {
    #Add lower and upper uncertainty limits
    diffs <- redoErrorIntervals.alldiffs(diffs, error.intervals = error.intervals,
                                         alpha = alpha, avsed.tolerance = avsed.tolerance,
                                         meanLSD.type = meanLSD.type, LSDby = LSDby)
    

    #Add backtransforms if there has been a transformation
    diffs <- addBacktransforms.alldiffs(alldiffs.obj = diffs, 
                                        transform.power = transform.power, 
                                        offset = offset, scale = scale)
  } else
  {
    #Linear transformation required
    diffs <- linTransform.alldiffs(alldiffs.obj = diffs, classify = classify,  term = term, 
                                   linear.transformation = linear.transformation, 
                                   Vmatrix = Vmatrix, 
                                   error.intervals = error.intervals, 
                                   avsed.tolerance = avsed.tolerance, 
                                   meanLSD.type = meanLSD.type, LSDby = LSDby, 
                                   response = response, response.title = response.title, 
                                   x.num = x.num, x.fac = x.fac, 
                                   tables = "none", level.length = level.length, 
                                   pairwise = pairwise, alpha = alpha,
                                   transform.power = transform.power, 
                                   offset = offset, scale = scale, 
                                   inestimable.rm = inestimable.rm)
  }

  #Sort alldiffs components, if required
  if (!is.null(sortFactor))
    diffs <- sort(diffs, decreasing = decreasing, sortFactor = sortFactor, 
                  sortWithinVals = sortWithinVals, sortOrder = sortOrder)
  
  #Outut tables according to table.opt and save alldiff object for current term
  if (!("none" %in% table.opt))
    print(diffs, which = table.opt)
  return(diffs)
}



"plotPredictions.data.frame" <- function(data, classify, y, x.num = NULL, x.fac = NULL, 
                                         nonx.fac.order = NULL, colour.scheme = "colour", 
                                         panels = "multiple", graphics.device = NULL,
                                         error.intervals = "Confidence", 
                                         titles = NULL, y.title = NULL, 
                                         filestem = NULL, ggplotFuncs = NULL, ...)
#a function to plot asreml predictions and associated statistics
{ #Check options
  scheme.options <- c("black", "colour")
  scheme.opt <- scheme.options[check.arg.values(colour.scheme, scheme.options)]
  panel.options <- c("single", "multiple")
  panel.opt <- panel.options[check.arg.values(panels, panel.options)]
  int.options <- c("none", "Confidence", "StandardError", "halfLeastSignificant")
  int.opt <- int.options[check.arg.values(error.intervals, int.options)]
  intervals <- !(int.opt == "none")
  #check have some predictions
  if (nrow(data) == 0)
    stop("no rows in object supplied to data argument")
  #check that x.fac is numeric in nature when no x.num
  if (is.null(x.num))
    if (!is.null(x.fac) && all(is.na((as.numfac(data[[x.fac]])))))
      stop(paste("the levels of ",x.fac, "are not numeric in nature"))

  #work out columns for intervals and their names along with labels for them
  if (intervals)
  { 
    klow <- pmatch("lower", names(data))
    kupp <- pmatch("upper", names(data))
    if (klow == 0 || kupp == 0)
      stop(paste("Cannot find a column in data starting with lower ",
                 "and another with upper to plot intervals"))
    ylow <- names(data)[klow]
    yupp <- names(data)[kupp]
    low.parts <- (strsplit(ylow, ".", fixed=TRUE))[[1]]
    upp.parts <- (strsplit(yupp, ".", fixed=TRUE))[[1]]
    if (!setequal(low.parts[-1], upp.parts[-1]))
      stop("Names of columns for lower and upper limits are not consistent")
    if (low.parts[2] == "StandardError")
    { 
      labend <- "+/- standard errors"
      abbrev <- "SE"
    }
    else 
      if (low.parts[2] == "Confidence")
      { 
        labend <- "confidence intervals"    
        abbrev <- "CI"
      }
    else
      if (low.parts[2] == "halfLeastSignificant") 
      { 
        labend <- "+/- half mean LSD"
        abbrev <- "LSI"
      }
    else
      stop("Names for interval limit are not consistent with the types of interval allowed")
  }
  #Do plots
  #Make sure no functions in classify
  vars <- fac.getinTerm(classify, rmfunction = TRUE)
  classify <- fac.formTerm(vars)
  non.x.terms <- setdiff(vars, c(x.fac, x.num))
  n.non.x <- length(non.x.terms)
  if ((length(vars) != n.non.x && n.non.x > 2) || (length(vars) == n.non.x && n.non.x > 3)) 
      stop("Sorry but plotting for prediction terms with more than 3 variables ", 
           "not implemented; \n", 
           "One possibility is to use facCombine.alldiffs to combine some factors.")
  #Determine plotting order of non.x.vars
  if (!is.null(nonx.fac.order)) 
  { 
    if (!setequal(nonx.fac.order, non.x.terms))
      stop("The factors nonx.fac.order are not the same as the set in the term being plotted")
    non.x.terms <- nonx.fac.order
    nos.lev <- sapply(1:n.non.x, 
      FUN=function(k, non.x.terms, data){return(length(levels(data[[non.x.terms[k]]])))},
      non.x.terms = non.x.terms, data = data)
  }
  else
  #Default order - sort non.x.vars according to their numbers of levels 
  { 
    nos.lev <- 1
    if(n.non.x >0)
    { nos.lev <- sapply(1:n.non.x, 
                        FUN=function(k, non.x.terms, data)
                               {return(length(levels(data[[non.x.terms[k]]])))},
                        non.x.terms = non.x.terms, data = data)
      non.x.terms <- non.x.terms[order(nos.lev, decreasing = TRUE)]
      nos.lev <- nos.lev[order(nos.lev, decreasing = TRUE)]
    }
  }
  #Append x.vars 
  if (length(vars) != n.non.x)
  { 
    x.terms <- setdiff(vars, non.x.terms)
    vars <- c(non.x.terms, x.terms)
  }
  else
    vars <- non.x.terms
  meanLSD <- attr(data, which = "meanLSD")
  if (length(meanLSD) > 0)
    meanLSD <- sqrt(mean(meanLSD*meanLSD, na.rm = TRUE))
  #Plot predicted values
  cbPalette <- rep(c("#CC79A7", "#56B4E9", "#009E73", "#E69F00", "#0072B2", "#D55E00", "#000000"), times=2)
  symb <- rep(c(18,17,15,3,13,8,21,9,3,2,11,1,7,5,10,0), times=10)
  if (!is.null(graphics.device) )
      do.call(graphics.device, list(record = FALSE))
  barplot <- FALSE
  if (length(vars) == length(non.x.terms))
  #Do bar chart
  { 
    barplot <- TRUE
    if (!is.null(titles) & !is.na(match(vars[1], names(titles))))
      x.title <- titles[[vars[1]]]
    else
      x.title <- vars[[1]]
    pred.plot <-  ggplot(data=data, ...) + theme_bw() + 
                    scale_x_discrete(x.title) + scale_y_continuous(y.title)
    if (scheme.opt == "black")
      pred.plot <-  pred.plot + theme_bw() +
                         theme(panel.grid.major = element_line(colour = "grey95", 
                                    size = 0.5), 
                               panel.grid.minor = element_line(colour = "grey98", 
                                    size = 0.5))
    if (n.non.x == 1)
    { 
      pred.plot <-  pred.plot + 
                       aes_string(x = vars[1], y = y) + 
                       scale_fill_manual(values=cbPalette) + 
                       theme(axis.text.x=element_text(angle=90, hjust=1))
      if (scheme.opt == "black")
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill="grey50") 
      else
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill=cbPalette[1])
      if (intervals)
      { 
        if (scheme.opt == "black")
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = "black") 
        else
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = cbPalette[5]) 
        pred.plot <- pred.plot + 
                        annotate("text", x=Inf, y=-Inf,  hjust=1, vjust=-0.3, size = 2, 
                                 label = paste("Error bars are ", labend, sep=""))
        if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD))
           pred.plot <- pred.plot + 
                         annotate("text", x=-Inf, y=-Inf,  hjust=-0.01, vjust=-0.3, size = 2, 
                                 label = paste("mean LSD = ",signif(meanLSD, digits=3)))
      }
    } else
    if (n.non.x == 2)
    { 
      pred.plot <-  pred.plot + 
                       aes_string(x = vars[1], y = y) + 
                       scale_fill_manual(values=cbPalette) + 
                       facet_grid(as.formula(paste("~ ",vars[2],sep=""))) + 
                       theme(axis.text.x=element_text(angle=90, hjust=1))
      if (scheme.opt == "black")
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill="grey50") 
      else
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill=cbPalette[1])
      if (intervals)
      { 
        non.x.lev <- levels(data[[vars[2]]])
        annot <- data.frame(Inf, -Inf, 
                             factor(non.x.lev[length(non.x.lev)], levels = non.x.lev))
        names(annot) <- c(vars[1], y, vars[2])
        if (scheme.opt == "black")
          pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                      linetype = "solid", colour = "black") 
        else
          pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = cbPalette[5]) 
        if (nos.lev[2] > 6)
           pred.plot <- pred.plot +
                         theme(strip.text.x = element_text(size = 8))
        pred.plot <- pred.plot + 
                        geom_text(data = annot, label = "Error bars are", 
                                  hjust=1, vjust=-1.3, size = 2) +
                        geom_text(data = annot, label = labend, 
                                  hjust=1, vjust=-0.3, size = 2)
        if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
        { 
          annot <- data.frame(-Inf, -Inf, 
                              factor(non.x.lev[1], levels = non.x.lev))
          names(annot) <- c(vars[1], y, vars[2])
          pred.plot <- pred.plot + 
                        geom_text(data = annot, hjust=-0.01, vjust=-0.3, size = 2, 
                                 label = paste("mean LSD = ",signif(meanLSD, digits=3)))
        }
      }
    } else
    if (n.non.x == 3)
    { 
      pred.plot <-  pred.plot + 
                       aes_string(x = vars[1], y = y) + 
                       scale_fill_manual(values=cbPalette) + 
                       facet_grid(as.formula(paste(vars[3]," ~ ",vars[2],sep=""))) + 
                       theme(axis.text.x=element_text(angle=90, hjust=1))
      if (scheme.opt == "black")
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill="grey50") 
      else
        pred.plot <-  pred.plot + geom_bar(stat="identity", fill=cbPalette[1])
      if (nos.lev[2] > 6 || nos.lev[3] > 6)
         pred.plot <- pred.plot +
                       theme(strip.text.x = element_text(size = 8),
                       strip.text.y = element_text(size = 8, angle = -90))
      if (intervals)
      { 
        non.x.lev1 <- levels(data[[vars[3]]])
        non.x.lev2 <- levels(data[[vars[2]]])
        annot <- data.frame(Inf, -Inf, 
                            factor(non.x.lev1[length(non.x.lev1)], levels = non.x.lev1),
                            factor(non.x.lev2[length(non.x.lev2)], levels = non.x.lev2))
        names(annot) <- c(vars[1], y, vars[c(3,2)])
        if (scheme.opt == "black")
          pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                      linetype = "solid", colour = "black") 
        else
          pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = cbPalette[5]) 
        pred.plot <- pred.plot + 
                        geom_text(data = annot, label = "Error bars are", 
                                  hjust=1, vjust=-2.1, size = 2) +
                        geom_text(data = annot, label = labend, 
                                  hjust=1, vjust=-1.1, size = 2)
        if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
        { 
          annot <- data.frame(-Inf, -Inf, 
                              factor(non.x.lev1[length(non.x.lev1)], levels = non.x.lev1),
                              factor(non.x.lev2[1], levels = non.x.lev2))
          names(annot) <- c(vars[1], y, vars[c(3,2)])
          pred.plot <- pred.plot + 
                        geom_text(data = annot, hjust=-0.01, vjust=-1.1, size = 2, 
                                 label = paste("mean LSD = ",signif(meanLSD, digits=3)))
        }
      }
    }
  }
  else
  #Do line plot
  { 
    if (intervals)
      if (!(is.null(x.num)) && x.num %in% vars)
        int.width <- (max(data[[x.num]]) - min(data[[x.num]]))*0.025
      else
        int.width <- length(levels(data[[x.fac]]))*0.025
    if (!(is.null(x.num)) && x.num %in% vars)
       x.var <- x.num
    else
       x.var <- x.fac
    if (!is.null(titles) & !is.na(match(x.var,names(titles))))
      x.title <- titles[[x.var]]
    else
      x.title <- x.var
    pred.plot <-  ggplot(data=data, ...) + theme_bw() +
                        scale_x_continuous(x.title) + scale_y_continuous(y.title)
    if (scheme.opt == "black")
      pred.plot <-  pred.plot + theme_bw() +
                         theme(panel.grid.major = element_line(colour = "grey95", 
                                    size = 0.5), 
                               panel.grid.minor = element_line(colour = "grey98", 
                                    size = 0.5))
    #If no non.x.terms ignore single & multiple
    if (n.non.x == 0)
    { 
      pred.plot <-  pred.plot + 
                       aes_string(x = x.var, y = y) + 
                       scale_colour_manual(values=cbPalette) + 
                       scale_shape_manual(values=symb) + 
                       geom_point(shape = symb[7])
      if (scheme.opt == "black")
        pred.plot <-  pred.plot + geom_line(colour = "black") 
      else
        pred.plot <-  pred.plot + geom_line(colour = cbPalette[1])
      if (intervals)
      { 
        if (scheme.opt == "black")
          pred.plot <-  pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),  
                                      linetype = "solid", colour = "black", width=int.width) 
        else
          pred.plot <-  pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),  
                                      linetype = "solid", colour = cbPalette[5], width=int.width) 
        pred.plot <- pred.plot + 
                       annotate("text", x=Inf, y=-Inf,  hjust=1, vjust=-0.3, size = 2, 
                                label =  paste("Error bars are ", labend, sep=""))
       if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
         pred.plot <- pred.plot + 
                       annotate("text", x=-Inf, y=-Inf,  hjust=-0.01, vjust=-0.3, size = 2, 
                               label = paste("mean LSD = ",signif(meanLSD, digits=3)))
      }
    } else
    if (panel.opt == "single")
    #Single with non.x.terms
    { 
      if (n.non.x == 1)
      { 
        if (scheme.opt == "black")
          pred.plot <-  pred.plot + aes_string(x = x.var, y = y, 
                                      linetype=non.x.terms, shape=non.x.terms)
        else
          pred.plot <-  pred.plot + aes_string(x = x.var, y = y, colour = non.x.terms, 
                                      linetype=non.x.terms, shape=non.x.terms) 
        pred.plot <-  pred.plot + 
                         labs(colour=non.x.terms, linetype=non.x.terms, shape=non.x.terms) +
                        # scale_colour_manual(values=cbPalette) + 
                         scale_shape_manual(values=symb) + 
                         geom_line() + 
                         geom_point()
        if (intervals)
        { 
          pred.plot <- pred.plot + 
                         geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                       linetype = "solid", position = position_dodge(1)) +
                         annotate("text", x=Inf, y=-Inf,  hjust=1, vjust=-0.3, size = 2, 
                                  label =  paste("Error bars are ", labend, sep=""))
          if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
          { pred.plot <- pred.plot + 
                           annotate("text", x=-Inf, y=-Inf,  hjust=-0.01, vjust=-0.3, size = 2, 
                                    label = paste("mean LSD = ",signif(meanLSD, digits=3)))
          }
        }
      }
    }
    else #"multiple"
    { if (n.non.x == 1)
      { 
      pred.plot <- pred.plot + 
                         aes_string(x = x.var, y = y) +
                         scale_colour_manual(values=cbPalette) + 
                         scale_shape_manual(values=symb) + 
                         geom_point(shape = symb[7])  + 
                         facet_wrap(as.formula(paste("~ ",non.x.terms,sep="")))
        if (scheme.opt == "black")
          pred.plot <- pred.plot + geom_line(colour = "black")
        else
          pred.plot <- pred.plot + geom_line(colour = cbPalette[1])
        if (intervals)
        { 
          non.x.lev <- levels(data[[non.x.terms]])
          annot <- data.frame(Inf, -Inf, 
                               factor(non.x.lev[length(non.x.lev)], levels = non.x.lev))
          names(annot) <- c(x.var, y, non.x.terms)
          if (scheme.opt == "black")
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = "black", width=int.width) 
          else
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = cbPalette[5], width=int.width) 
          pred.plot <- pred.plot + 
                          geom_text(data = annot, label = "Error bars are", 
                                    hjust=1, vjust=-1.3, size = 2) +
                          geom_text(data = annot, label = labend, 
                                    hjust=1, vjust=-0.3, size = 2)
          if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
          { annot <- data.frame(-Inf, -Inf, 
                                factor(non.x.lev[1], levels = non.x.lev))
            names(annot) <- c(x.var, y, non.x.terms)
            pred.plot <- pred.plot + 
                          geom_text(data = annot, hjust=-0.01, vjust=-0.3, size = 2, 
                                   label = paste("mean LSD = ",signif(meanLSD, digits=3)))
          }
        }
      }
      if (n.non.x == 2)
      { 
        pred.plot <- pred.plot + 
                         aes_string(x = x.var, y = y) +
                         scale_colour_manual(values=cbPalette) + 
                         scale_shape_manual(values=symb) + 
                         geom_point(shape = symb[7]) +
                         facet_grid(as.formula(paste(vars[2]," ~ ",vars[1],sep="")))
        if (scheme.opt == "black")
          pred.plot <- pred.plot + geom_line(colour = "black")
        else
          pred.plot <- pred.plot + geom_line(colour = cbPalette[1])
        if (nos.lev[1] > 6 || nos.lev[2] > 6)
           pred.plot <- pred.plot +
                         theme(strip.text.x = element_text(size = 8),
                         strip.text.y = element_text(size = 8, angle = -90))
        if (intervals)
        { 
          non.x.lev1 <- levels(data[[vars[1]]])
          non.x.lev2 <- levels(data[[vars[2]]])
          annot <- data.frame(Inf, -Inf, 
                               factor(non.x.lev1[length(non.x.lev1)], levels = non.x.lev1),
                               factor(non.x.lev2[length(non.x.lev2)], levels = non.x.lev2))
          names(annot) <- c(x.var, y, non.x.terms)
          if (scheme.opt == "black")
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = "black", width=int.width) 
          else
            pred.plot <- pred.plot + geom_errorbar(aes_string(ymin=ylow, ymax=yupp),   
                                        linetype = "solid", colour = cbPalette[5], width=int.width) 
          pred.plot <- pred.plot + 
                          geom_text(data = annot, label = "Error bars are", 
                                    hjust=1, vjust=-1.3, size = 2) +
                          geom_text(data = annot, label = labend, 
                                    hjust=1, vjust=-0.3, size = 2)
          if (low.parts[2] == "halfLeastSignificant" && !is.null(meanLSD)) 
          { annot <- data.frame(-Inf, -Inf, 
                                factor(non.x.lev1[1], levels = non.x.lev1),
                                factor(non.x.lev2[length(non.x.lev2)], levels = non.x.lev2))
            names(annot) <- c(x.var, y, non.x.terms)
            pred.plot <- pred.plot + 
                          geom_text(data = annot, hjust=-0.01, vjust=-0.3, size = 2, 
                                   label = paste("mean LSD = ",signif(meanLSD, digits=3)))
          }
        }
      }
    }
  }
  if (!is.null(ggplotFuncs))
    for (f in ggplotFuncs)
      pred.plot <- pred.plot + f
  print(pred.plot)
  #Automate saving of plots in files
  if (!is.null(filestem))
  { 
    filename <- paste(filestem,".",gsub(":",".",classify, fixed= TRUE),sep="")
    if (barplot)
      filename <- paste(filename,"Bar", sep=".")
    else
      filename <- paste(filename,"Line", sep=".")
    if (intervals)
      filename <- paste(filename,abbrev,sep=".")
    filename <- paste(filename,".png",sep="")
    savePlot(filename = filename, type = "png")
    cat("\n#### Plot saved in ", filename,"\n")
  }
  invisible()
}

#Function to calculate the LSDs for combinations of the levels of the by factor(s)
sliceLSDs <- function(alldiffs.obj, by, t.value, alpha = 0.05)
{
  sed <- alldiffs.obj$sed
  denom.df <- attr(alldiffs.obj, which = "tdf")
  if (is.null(denom.df))
  {
    warning(paste("The degrees of freedom of the t-distribtion are not available in alldiffs.obj\n",
                  "- p-values and LSDs not calculated"))
    LSDs <- NULL
  } else
  {
    t.value = qt(1-alpha/2, denom.df)
    #Process the by argument
    if (is.list(by))
    {
      if (any(unlist(lapply(by, function(x) class(x)!="factor"))))
        stop("Some components of the by list are not factors")
      fac.list <- by
    } else
    {
      if (class(by) == "factor")
        fac.list <- list(by)
      else
      {
        if (is.character(by))
          fac.list <- as.list(alldiffs.obj$predictions[by])
        else
          stop("by is not one of the allowed class of inputs")
      }
    }
    #Form levels combination for which a mean LSD is required
    levs <- levels(fac.combine(fac.list, combine.levels = TRUE))
    combs <- strsplit(levs, ",", fixed = TRUE)
    #Get the LSDs
    LSDs <- lapply(combs, 
                   function(comb, sed, t.value)
                   {
                     lapply(comb, function(lev){})
                     krows <- rep(TRUE, nrow(sed))
                     #loop over levels for the current combination 
                     for (lev in comb)
                     {
                       krows <- krows & grepl(lev, rownames(sed), fixed = TRUE)
                     }
                     ksed <- sed[krows, krows]
                     minLSD <- t.value * min(ksed, na.rm = TRUE)
                     maxLSD <- t.value * max(ksed, na.rm = TRUE)
                     meanLSD <- t.value * sqrt(mean(ksed * ksed, na.rm = TRUE))
                     return(cbind(minLSD, meanLSD, maxLSD))
                   }, sed = sed, t.value = t.value)
    if (!is.null(LSDs))
    {
      LSDs <- as.data.frame(do.call(rbind, LSDs))
      rownames(LSDs) <- levs
    }
  }  
  return(LSDs)
}

"predictPresent.asreml" <- function(asreml.obj, terms, 
                                    linear.transformation = NULL, 
                                    wald.tab = NULL, dDF.na = "residual", 
                                    dDF.values = NULL, 
                                    x.num = NULL, x.fac = NULL, nonx.fac.order = NULL, 
                                    x.pred.values = NULL, x.plot.values = NULL, 
                                    plots = "predictions", panels = "multiple", 
                                    graphics.device = NULL, 
                                    error.intervals = "Confidence", meanLSD.type = "overall", 
                                    LSDby = NULL, avsed.tolerance = 0.25, titles = NULL, 
                                    colour.scheme = "colour", save.plots = FALSE, 
                                    transform.power = 1, offset = 0, scale = 1, 
                                    pairwise = TRUE, Vmatrix = FALSE, 
                                    tables = "all", level.length = NA, 
                                    alpha = 0.05, inestimable.rm = TRUE,
                                    sortFactor = NULL, sortWithinVals = NULL, 
                                    sortOrder = NULL, decreasing = FALSE, 
                                    trace = FALSE, ggplotFuncs = NULL, ...)
#This function forms the predictions for each significant term.
#It then presents either a table or a graph based on the predicted values 
# - the decision is based on whether x.fac or x.num is in the term. 
#Might need to supply additional arguments to predict through "..."
#e.g. present
#Must have levels of x.fac in the order in which they are to be plotted
# - with dates, they should be in the form yyyymmdd
#Probably need to supply x.plot.values if x.fac is to be plotted
{ 
  asr4 <- ("asreml4" %in% loadedNamespaces())
  
  AvLSD.options <- c("overall", "factor.combinations", "per.prediction")
  avLSD <- AvLSD.options[check.arg.values(meanLSD.type, AvLSD.options)]
  if (!is.null(LSDby) &&  !is.character(LSDby))
    stop("LSDby must be a character")
  
  tempcall <- list(...)
  if ("levels.length" %in% names(tempcall))
    stop("levels.length has been deprecated - use level.length")
  if ("vcov" %in% names(tempcall))
    stop("Use Vmatrix to request that the vcov matrix be saved")
  
  if (!is.null(wald.tab) & (!is.data.frame(wald.tab) || ncol(wald.tab) != 4))
    stop("wald.tab should be a 4-column data.frame -- perhaps extract Wald component from list")
  if (!is.null(x.pred.values) && !is.null(x.plot.values))
    if (length(x.pred.values) != length(x.plot.values))
    {
      if (asr4)
        stop("In analysing ",asreml.obj$formulae$fixed[[2]],
             ", length of x.pred.values and x.plot.values should be equal")
      else
        stop("In analysing ",asreml.obj$fixed.formula[[2]],
             ", length of x.pred.values and x.plot.values should be equal")
    }
  #Check options
  scheme.options <- c("black", "colour")
  scheme.opt <- scheme.options[check.arg.values(colour.scheme, scheme.options)]
  panel.options <- c("single", "multiple")
  panel.opt <- panel.options[check.arg.values(panels, panel.options)]
  plot.options <- c("none", "predictions", "backtransforms", "both")
  plot.opt <- plot.options[check.arg.values(plots, plot.options)]
  if (!is.na(avsed.tolerance) & (avsed.tolerance <0 | avsed.tolerance > 1))
    stop("avsed.tolerance should be between 0 and 1")
  int.options <- c("none", "Confidence", "StandardError", "halfLeastSignificant")
  int.opt <- int.options[check.arg.values(error.intervals, int.options)]
  
  #Determine if there are any model terms with x.num and any with x.fac
  if (asr4)
    model.terms <- c(attr(terms(asreml.obj$formulae$fixed), which="term.labels"),
                     attr(terms(asreml.obj$formulae$random), which="term.labels"))
  else
    model.terms <- c(attr(terms(asreml.obj$fixed.formula), which="term.labels"),
                     attr(terms(asreml.obj$random.formula), which="term.labels"))
  term.types <- trend.terms.types(terms = model.terms, 
                                  trend.num = x.num , devn.fac = x.fac)
  diff.list <- vector("list", length = length(terms))
  names(diff.list) <- gsub(":", ".", terms, fixed= TRUE)
  for (term in terms) 
  #Get the predictions
  { 
    #Make sure no functions in classify
    factors <- fac.getinTerm(term, rmfunction = TRUE)
    classify.term <- fac.formTerm(factors)
    #Check if current term involves x.num or x.fac
    if ((!is.null(x.num) && x.num %in% factors) || (!is.null(x.fac) && x.fac %in% factors))
      #Check if the set of model terms is mixed for trend and deviations
    { 
      if (term.types$has.trend.num && term.types$has.devn.fac)
      #Mixed
      { if (!(x.num %in% factors))
          classify.term <- paste(classify.term, x.num, sep=":")
        else
          if (!(x.fac %in% factors))
            classify.term <- paste(classify.term, x.fac, sep=":")
    }
      diffs <- predictPlus.asreml(asreml.obj = asreml.obj, 
                                  classify = classify.term, term = term, 
                                  linear.transformation = linear.transformation, 
                                  titles = titles, 
                                  x.num = x.num, x.fac = x.fac,  
                                  x.pred.values = x.pred.values, 
                                  x.plot.values = x.plot.values, 
                                  error.intervals = error.intervals, 
                                  avsed.tolerance = avsed.tolerance, 
                                  meanLSD.type = meanLSD.type, LSDby = LSDby, 
                                  pairwise = pairwise, Vmatrix = Vmatrix, 
                                  tables = tables, 
                                  level.length = level.length, 
                                  transform.power = transform.power, 
                                  offset = offset, scale = scale, 
                                  inestimable.rm = inestimable.rm, 
                                  sortFactor = sortFactor, 
                                  sortWithinVals = sortWithinVals, 
                                  sortOrder = sortOrder, 
                                  decreasing = decreasing, 
                                  wald.tab = wald.tab, dDF.na = dDF.na, 
                                  dDF.values = dDF.values, 
                                  alpha = alpha, trace = trace, ...)
    }
    #Not mixed
    else
      #No need for x.pred.values or to modify term
      diffs <- predictPlus.asreml(asreml.obj = asreml.obj, 
                                  classify = classify.term, 
                                  linear.transformation = linear.transformation, 
                                  titles = titles,   
                                  x.num = x.num, x.fac = x.fac,  
                                  x.plot.values = x.plot.values, 
                                  error.intervals = error.intervals, 
                                  avsed.tolerance = avsed.tolerance, 
                                  meanLSD.type = meanLSD.type, LSDby = LSDby, 
                                  pairwise = pairwise, Vmatrix = Vmatrix, 
                                  tables = tables, 
                                  level.length = level.length, 
                                  transform.power = transform.power, 
                                  offset = offset, scale = scale, 
                                  inestimable.rm = inestimable.rm, 
                                  sortFactor = sortFactor, 
                                  sortWithinVals = sortWithinVals, 
                                  sortOrder = sortOrder, 
                                  decreasing = decreasing, 
                                  wald.tab = wald.tab, dDF.na = dDF.na, 
                                  dDF.values = dDF.values, 
                                  alpha = alpha, trace = trace, ...)
    new.name <- gsub(":", ".", term)
    diff.list[[new.name]] <- diffs
    #check have some predictions
    if (nrow(diffs$predictions) == 0)
      warning("No estimable predicted values")
    else
    {
      #If plot required, set up y.title
      if (plot.opt != "none")
      { 
        #Set y.title
        y.title <- as.character(attr(diffs, which = "response.title"))
        if (is.null(y.title))
          y.title <- as.character(attr(diffs, which = "response"))
        if (save.plots)
          filestem <- as.character(attr(diffs, which = "response"))
        else
          filestem <- NULL
      }
      #Plot predictions if a plot is required and data are not transformed or if 
      #plot of predictions requested
      transformed <- transform.power != 1 | offset != 0 | scale != 1
      if ((!transformed & plot.opt != "none") | plot.opt == "predictions" 
          | plot.opt == "both")
        #Plot predictions
      { 
        plotPredictions(data = diffs$predictions, classify = classify.term, 
                        y = "predicted.value", 
                        x.num = x.num, x.fac = x.fac, 
                        nonx.fac.order = nonx.fac.order, 
                        colour.scheme = colour.scheme, 
                        panels = panel.opt, graphics.device = graphics.device,
                        error.intervals = error.intervals,  
                        titles = titles, y.title = y.title, 
                        filestem = filestem, ggplotFuncs = ggplotFuncs, ...)
      }
      if (transformed & (plot.opt == "backtransforms"  | plot.opt == "both"))
        #Plot backtransforms
      { 
        bty.title <- paste("Backtransform of ",y.title,sep="")
        if (save.plots)
          filestem <- paste(filestem,".back",sep="")
        else
          filestem <- NULL
        plotPredictions(data = diffs$backtransforms, 
                        classify = classify.term, 
                        y = "backtransformed.predictions", 
                        x.num = x.num, x.fac = x.fac,   
                        nonx.fac.order = nonx.fac.order, 
                        colour.scheme = colour.scheme,  
                        panels = panel.opt, graphics.device = graphics.device,
                        error.intervals = error.intervals,
                        titles = titles, y.title = bty.title, 
                        filestem = filestem, ggplotFuncs = ggplotFuncs, ...)
      }
    }
  }
  invisible(diff.list)
}



#Calls for prediction routines:
# - predictPresent.asreml calls predictPlus.asreml & plotPredictions.data.frame
# - predictPlus.asreml calls allDifferences.data.frame