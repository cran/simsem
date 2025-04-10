\name{miss}
\alias{miss}
\title{
Specifying the missing template to impose on a dataset
}
\description{
Specifying the missing template (\code{\linkS4class{SimMissing}}) to impose on a dataset. The template will be used in Monte Carlo simulation such that, in the \code{\link{sim}} function, datasets are created and imposed by missing values created by this template. See \code{\link{imposeMissing}} for further details of each argument.
}
\usage{
miss(cov = 0, pmMCAR = 0, pmMAR = 0, logit = "", nforms = 0, itemGroups = list(),
     timePoints = 1, twoMethod = 0, prAttr = 0,
     m = 0, convergentCutoff = 0.8, ignoreCols = 0,
     threshold = 0, covAsAux = TRUE, logical = NULL, ...)
}
\arguments{
	\item{cov}{Column indices of any normally distributed covariates used in the data set.}
    \item{pmMCAR}{Decimal percent of missingness to introduce completely at random on all variables.}
    \item{pmMAR}{Decimal percent of missingness to introduce using the listed covariates as predictors.}
	\item{logit}{The script used for imposing missing values by logistic regression. The script is similar to the specification of regression in \code{lavaan} such that each line begins with a dependent variable, then '~' is used as regression sign, and the formula of a linear combination of independent variable plus constant, such as y1 ~ 0.5 + 0.2*y2. '#' and '!' can be used as a comment (like \code{lavaan}). For the intercept, users may use 'p()' to specify the average proportion of missing, such as y1 ~ p(0.2) + 0.3*y2, which the average missing proportion of y1 is 0.2 and the missing of y1 depends on y2. Users may visualize the missing proportion from the logistic specification by the \code{\link{plotLogitMiss}} function.}
    \item{nforms}{The number of forms for planned missing data designs, not including the shared form.}
    \item{itemGroups}{List of lists of item groupings for planned missing data forms. Without this, items will be divided into groups sequentially (e.g. 1-3,4-6,7-9,10-12)}
    \item{timePoints}{Number of timepoints items were measured over. For longitudinal data, planned missing designs will be implemented within each timepoint.}
    \item{twoMethod}{With missing on one variable: vector of (column index, percent missing). Will put a given percent missing on that column in the matrix to simulate a two method planned missing data research design. With missing on two or more variables: list of (column indices, percent missing). }
	\item{prAttr}{Probability (or vector of probabilities) of an entire case being removed due to attrition at a given time point. See \code{\link{imposeMissing}} for further details.}
  \item{m}{The number of imputations (DEPRECATED). The only currently accepted value is 0, indicating to use full information maximum likelihood estimation.}
  \item{convergentCutoff}{DEPRECATED. If the proportion of convergent results across imputations are greater than the specified value (the default is 80\%), the analysis on the dataset is considered as convergent. Otherwise, the analysis is considered as nonconvergent. This attribute is applied for multiple imputation only (currently not supported). }
  \item{ignoreCols}{The columns not imposed any missing values for any missing data patterns}
	\item{threshold}{The threshold of covariates that divide between the area to impose missing and the area not to impose missing. The default threshold is the mean of the covariate.}
	\item{covAsAux}{If \code{TRUE}, the covariate listed in the object will be used as auxiliary variables when putting in the model object. If \code{FALSE}, the covariate will be included in the analysis.}
	\item{logical}{A matrix of logical values (\code{TRUE/FALSE}). If a value in the dataset is corresponding to the \code{TRUE} in the logical matrix, the value will be missing.}
	\item{\dots}{DEPRECATED. Additional arguments passed to a multiple-imputation function (no longer supported).}
}
\value{
	A missing object that contains missing-data template (\code{\linkS4class{SimMissing}})
}
\author{
	Alexander M. Schoemann (East Carolina University; \email{schoemanna@ecu.edu}),
    Patrick Miller (University of Notre Dame; \email{pmille13@nd.edu}),
	Sunthud Pornprasertmanit (\email{psunthud@gmail.com})}
\seealso{
	\itemize{
		\item \code{\linkS4class{SimMissing}} The resulting missing object
	}
}
\examples{
#Example of imposing 10% MCAR missing in all variables (FIML estimation)
Missing <- miss(pmMCAR=0.1, ignoreCols="group")
summary(Missing)

loading <- matrix(0, 6, 1)
loading[1:6, 1] <- NA
LY <- bind(loading, 0.7)
RPS <- binds(diag(1))
RTE <- binds(diag(6))
CFA.Model <- model(LY = LY, RPS = RPS, RTE = RTE, modelType="CFA")

#Create data
dat <- generate(CFA.Model, n = 20)

#Impose missing
datmiss <- impose(Missing, dat)

#Analyze data
out <- analyze(CFA.Model, datmiss)
summary(out)

#Missing using logistic regression
script <- 'y1 ~ 0.05 + 0.1*y2 + 0.3*y3
	y4 ~ -2 + 0.1*y4
	y5 ~ -0.5'
Missing2 <- miss(logit=script, pmMCAR=0.1, ignoreCols="group")
summary(Missing2)
datmiss2 <- impose(Missing2, dat)

#Missing using logistic regression (2)
script <- 'y1 ~ 0.05 + 0.5*y3
	y2 ~ p(0.2)
	y3 ~ p(0.1) + -1*y1
	y4 ~ p(0.3) + 0.2*y1 + -0.3*y2
	y5 ~ -0.5'
Missing2 <- miss(logit=script)
summary(Missing2)
datmiss2 <- impose(Missing2, dat)

#Example to create simMissing object for 3 forms design at 3 timepoints
Missing <- miss(nforms=3, timePoints=3,
                itemGroups = list(X = 1:3,
                                  A = 4:6,
                                  B = 7:9,
                                  D = 10:12))
}
