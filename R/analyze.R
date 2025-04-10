### Sunthud Pornprasertmanit & Terrence D. Jorgensen (anyone else?)
### Last updated: 1 April 2025
### functions to fit a model (lavaan, OpenMx, SimSem, or custom function) to data

analyze <- function(model, data, package = "lavaan", miss = NULL,
                    aux = NULL, group = NULL, mxMixture = FALSE, ...) {
	mc <- match.call()
	args <- list(...)
	if (is(model, "SimSem")) {
		if(!("group" %in% names(args)) & "group" %in% names(mc)) args$group <- group
		args <- c(list(model = model, data = data, package = package, miss = miss, aux = aux), args)
		out <- do.call("analyzeSimSem", args)
	} else if (is(model, "MxModel")) {
		out <- analyzeMx(object = model, data = data, groupLab = group, mxMixture = mxMixture, ...)
	} else {
		stop("Please specify an appropriate object for the 'model' argument: ",
		     "simsem model template or OpenMx object. If users wish to analyze ",
		     "the lavaan script, please use the functions in the lavaan package ",
		     "directly (e.g., sem, cfa, growth, or lavaan).")
	}
	return(out)
}

analyzeSimSem <- function(model, data, package = "lavaan",
                          miss = NULL, aux = NULL, ...) {
  Output <- NULL
  groupLab <- model@groupLab
  args <- list(...)
  if (is(data, "list")) {
    if ("data" %in% names(data)) {
      data <- data$data
    } else {
      stop("The list does not contain any 'data' slot.")
    }
  }
  if (is.null(colnames(data)))
    colnames(data) <- paste0("x", 1:ncol(data))
  if (is.null(aux)) {
    if (!is.null(miss) && !(length(miss@cov) == 1 && miss@cov == 0) && miss@covAsAux)
      aux <- miss@cov
  }
  if (length(unique(model@pt$group[model@pt$op %in% c("=~", "~~", "~", "~1", "|")])) == 1) {
    args$group <- NULL
    groupLab <- NULL
  }
  ## TDJ 2 June 2016: lavaan >= 0.6-1 requires a ParTable to have "block"
  if (is.null(model@pt$block)) model@pt$block <- model@pt$group

  ##FIXME: without runMI(), no sustainable way to automate imputation
  # if (!is.null(miss) && length(miss@package) != 0 && miss@package %in% c("Amelia", "mice")) {
  #   miArgs <- miss@args
  #   if (miss@package == "Amelia") {
  #     if (model@groupLab %in% colnames(data)) {
  #       if (!is.null(miArgs$idvars)) {
  #         miArgs$idvars <- c(miArgs$idvars, model@groupLab)
  #       } else {
  #         miArgs <- c(miArgs, list(idvars = model@groupLab))
  #       }
  #     }
  #   }
  #   Output <- lavaan.mi::runMI(model@pt, data, fun = "lavaan", ..., m = miss@m,
  #                             miArgs = miArgs, miPackage = miss@package)
  # } else {
    ## If the missing argument is not specified and data have NAs, the default is fiml.
    if (is.null(args$missing)) {
      missing <- "default"
      if (any(is.na(data))) missing <- "fiml"
    } else {
      missing <- args$missing
      args$missing <- NULL
    }
    model.type <- if (tolower(model@modelType) == "sem") "sem" else "cfa"
    if (!is.null(aux)) {
      if (is.numeric(aux)) aux <- colnames(data)[aux]
      attribute <- list(model=model@pt, aux = aux, data = data, group = groupLab,
                        model.type = model.type, missing = missing, fun = "lavaan")
      attribute <- c(attribute, args)
      Output <- do.call(semTools::auxiliary, attribute)
    } else {
      attribute <- list(model = model@pt, data = data, group = groupLab,
                        model.type = model.type, missing = missing)
      attribute <- c(attribute, args)
      Output <- do.call(lavaan::lavaan, attribute)
    }
#  }
  return(Output)
}

# To be used internally
anal <- function(model, data, package = "lavaan", ...) {
	groupLab <- model@groupLab
	if (length(unique(model@pt$group[model@pt$op %in% c("=~", "~~", "~", "~1", "|")])) == 1L) {
		groupLab <- NULL
	}
	## synchronize model@modelType with lavaan's model.type
	model.type <- if (tolower(model@modelType) == "sem") "sem" else "cfa"

  Output <- lavaan::lavaan(model@pt, data = data, group = groupLab,
                           model.type = model.type, ...)
  return(Output)
}

analyzeLavaan <- function(args, fun = "lavaan", miss = NULL, aux = NULL) {
  Output <- NULL
  if (is.null(aux)) {
    if (!is.null(miss) && !(length(miss@cov) == 1 && miss@cov == 0) && miss@covAsAux)
      aux <- miss@cov
  }
  ##FIXME: without runMI(), no sustainable way to automate imputation
  # if (!is.null(miss) && length(miss@package) != 0 && miss@package %in% c("Amelia", "mice")) {
  #   miArgs <- miss@args
  #   if (miss@package == "Amelia") {
  #     if (!is.null(args$group)) {
  #       if (args$group %in% colnames(data)) {
  #         if (!is.null(miArgs$idvars)) {
  #           miArgs$idvars <- c(miArgs$idvars, args$group)
  #         } else {
  #           miArgs <- c(miArgs, list(idvars = args$group))
  #         }
  #       }
  #     }
  #   }
  #   args$fun <- fun
  #   args$m <- miss@m
  #   args$miArgs <- miArgs
  #   args$miPackage <- miss@package
  #   Output <- do.call(semTools::runMI, args)
  # } else {
    ## If the missing argument is not specified and data have NAs, the default is fiml.
    if(is.null(args$missing)) {
      args$missing <- "default"
      if ((!is.null(miss) && (miss@m == 0)) || any(is.na(args$data))) {
        args$missing <- "fiml"
      }
    }
    if (!is.null(aux)) {
      if (is.numeric(aux)) aux <- colnames(model$data)[aux]
      args$aux <- aux
      args$fun <- fun
      Output <- do.call(semTools::auxiliary, args)
    } else {
      Output <- do.call(fun, args)
    }
#  }
  return(Output)
}
