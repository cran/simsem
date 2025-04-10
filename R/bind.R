## So one of the tricky things about this function is that we want to infer the
## correct matrices and check input. The interface is designed to eliminate the
## need to create many input matrices. This is done by specifying a free/fixed
## matrix.  Syntax Free/Fixed:

## Parameters that are freed are indicated by 'NA'.  Parameters that are fixed
## are numbers.  Parameters that share the same character label are constrained
## to be equal.  Population Parameters: An element of the matrix can be set to
## a value or distribution. Data will be generated with those values.
## Typically, we are interested in specifying the population value of the free
## parameters in advance.  Misspecification: However, by setting fixed
## parameters to values different from what they were fixed to, we can create
## model misspecification.  Misspecification can also be done by passing a
## value or distribution to the 'misspec' argument, in which all fixed
## parameters will receive that value or distribution.

## Rules: 1. If the free parameters are specified and if only 1 value or
## distribution is passed to popParam, all free parameters have the same value
## or distribution.  2. If the free parameters are specified, and if only 1
## distribution is passed to misspec, all fixed parameters get that
## distribution or value.  3. If equality constraints are specified, labels
## can't be objects already in the environment or function names.  4. Any
## numeric value in popParam or misspec (including 0) will be considered to be
## a parameter value for data generation. Empty values should be either '' or
## NA
##
## Validity checks: 1. Input matrices have the same dimensions or vectors have
## same length 2. Distributions are converted to expressions and are valid 3.
## All character vectors passed to popParam and misspec are able to be
## evaluated 4. If both free and popParam are specified, all free parameters
## have a population value 5. If labels are included in free (specifying
## equality constraints), these labels are valid and at least one pair of the
## labels is the same.


bind <- function(free = NULL, popParam = NULL, misspec = NULL, symmetric = FALSE) {
    ## SimMatrix
    if (is.matrix(free)) {

        if (symmetric) stopifnot(isSymmetric(free))

        ## PopParam Must be either character or numeric
        if (is.character(popParam)) {
            tryCatch(eval(parse(text = popParam)), error = function(e) stop(e))
            if (!is.matrix(popParam)) {
                paramMat <- ifelse(is.free(free), popParam, "")
            }
        } else if (is.numeric(popParam) && !is.matrix(popParam)) {
            paramMat <- ifelse(is.free(free), popParam, "")
        }

        # Can optionally also be a matrix
        if (is.matrix(popParam)) {
            if (symmetric) stopifnot(isSymmetric(popParam))
            if (!all(dim(free) == dim(popParam)))
                stop("Free matrix and popParam are not of same dimension")
			popParam[!is.free(free)] <- ""
            if (any(!is.empty(popParam) != is.free(free))) {
                stop("Please assign a value for any free parameters")
            }
            paramMat <- matrix(as.character(popParam), nrow = nrow(popParam), ncol = ncol(popParam))

        }

        if (is.null(popParam)) {
            paramMat <- matrix(NaN)
        }

        # Misspec - same tests as above, almost.
        if (is.character(misspec)) {
            tryCatch(eval(parse(text = misspec)), error = function(e) stop(e))
            if (!is.matrix(misspec))
                misspecMat <- ifelse(!is.free(free), misspec, "")
        } else if (is.numeric(misspec) && !is.matrix(misspec)) {
            misspecMat <- ifelse(!is.free(free), misspec, "")
        }

        if (is.matrix(misspec)) {
            if (symmetric) stopifnot(isSymmetric(misspec))
            if (!all(dim(free) == dim(misspec)))
                stop("Free matrix and misspec are not of same dimension")
            misspecMat <- matrix(as.character(misspec), nrow = nrow(misspec), ncol = ncol(misspec))

        }
        if (is.null(misspec)) {
            misspecMat <- matrix(NaN)
        }

        ## to prevent errors elsewhere, only use indLab= and facLab=
        dimnames(free) <- NULL
        dimnames(paramMat) <- NULL
        dimnames(misspecMat) <- NULL

        return(new("SimMatrix", free = free, popParam = paramMat, misspec = misspecMat,
            symmetric = symmetric))

        ## SimVector
    } else if (is.vector(free)) {

        if (symmetric) stop("A vector cannot be symmetric")

        # popParam
        if (is.character(popParam) && length(popParam == 1)) {
            tryCatch(eval(parse(text = popParam)), error = function(e) stop(e))
            paramVec <- ifelse(is.free(free), popParam, "")
        } else if (is.numeric(popParam) && length(popParam) == 1) {
            paramVec <- ifelse(is.free(free), popParam, "")
        } else if (is.vector(popParam)) {
            if ((length(free) != length(popParam)) && length(popParam) > 1)
                stop("Free vector and popParam are not the same length")
			popParam[!is.free(free)] <- ""
            if (any(!is.empty(popParam) != is.free(free))) {
                stop("Please assign a value for any free parameters")
            }
            paramVec <- as.character(popParam)
        } else {
            paramVec <- vector()
        }

        # Misspec
        if (is.character(misspec) && length(misspec) == 1) {
            tryCatch(eval(parse(text = misspec)), error = function(e) stop(e))
            misspecVec <- ifelse(!is.free(free), misspec, "")
        } else if (is.numeric(misspec) && length(misspec) == 1) {
            misspecVec <- ifelse(!is.free(free), misspec, "")
        } else if (is.vector(misspec)) {
            if ((length(free) != length(misspec)) && length(misspec) > 1)
                stop("Free vector and misspec are not the same length")
            misspecVec <- as.character(misspec)
        } else {
            misspecVec <- vector()
        }

        ## to prevent errors elsewhere, only use indLab= and facLab=
        names(free) <- NULL
        names(paramVec) <- NULL
        names(misspecVec) <- NULL

        new("SimVector", free = free, popParam = paramVec, misspec = misspecVec)

    } else {
        stop("Please specify a free/fixed parameter matrix or vector.")
    }

}

binds <- function(free = NULL, popParam = NULL, misspec = NULL, symmetric = TRUE) {
    return(bind(free = free, popParam = popParam, misspec = misspec, symmetric = symmetric))
}



# Possible 'empty values': '', or NA
is.empty <- function(dat) {
    if (is.null(dim(dat))) {
        temp <- sapply(dat, FUN = function(x) if (x == "" || is.na(x)) {
            TRUE
        } else {
            FALSE
        })
        names(temp) <- NULL
        return(temp)
    }
    apply(dat, c(1, 2), FUN = function(x) if (x == "" || is.na(x)) {
        TRUE
    } else {
        FALSE
    })

}


# Finds valid labels, checks all combinations of label pairs to make sure at
# least one pair is the same.  Assumes that matrix has at least one character
# label.
validConstraints <- function(mat) {
    if (any(inherits(mat, c("SimMatrix","SimVector"), which = TRUE))) {
        mat <- mat@free
    }

    labels <- is.label(mat)
    combs <- combn(labels[labels], 2)
    res <- combs[1, ] & combs[2, ]

    return(any(res))
}

is.label <- function(mat) {
    flat <- as.vector(mat)
    flat[is.na(flat)] <- 0
    isLabel <- sapply(flat, FUN = function(x) {
        suppressWarnings(is.na(as.numeric(x)))
    })
    return(isLabel)
}

is.free <- function(mat) {
    if (is.character(mat)) {
        isFree <- is.na(mat) | is.label(mat)
    } else {
        isFree <- is.na(mat)
    }
    return(isFree)
}
