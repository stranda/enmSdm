#' Velocity of climate relative to set starting locations
#'
#' This function calculates the velocity of climate (distance traversed by a given climate over time divideded by the duration of the time period). Although other 
#' @param x Either a \code{RasterStack}, \code{RasterBrick}, or 3-dimensional array. Values should be either \code{NA} or >= 0.
#' \itemize{
#' 	\item If \code{x} is a \code{RasterStack} or \code{RasterBrick} then each layer is assumed to represent a time slice and the rasters \emph{must} be in an equal-area projection.
#' 	\item If \code{x} is an array then each "layer" in the third dimension is assumed to represent a map at a particular time slice in an equal-area projection. Note that if this is an array you should probably also specify the arguments \code{longitude} and \code{latitude}.
#' }
#' @param times Numeric vector with the same number of layers in \code{x} or \code{NULL} (default). This specifies the time represented by each layer in \code{x} from oldest (top layer) to most recent (bottom layer). Times \emph{must} appear in sequential order. For example, if time periods are 24 kybp, 23 kybp, 22 kybp, use \code{c(-24, -23, -22)}, not \code{c(24, 23, 22)}. If \code{NULL} (default), values are assigned starting at 1 and ending at the total number of layers in \code{x}.
#' @param atTimes Numeric, values of \code{times} across which to calculate biotic velocity. You can use this to calculate biotic velocities across selected time periods (e.g., just the first and last time periods). Note that \code{atTimes} must be the same as or a subset of \code{times}. The default is \code{NULL}, in which case velocity is calculated across all time slices (i.e., between \code{times} 1 and 2, 2 and 3, 3 and 4, etc.).
#' @param longitude Numeric matrix or \code{NULL} (default):
#' \itemize{
#'	\item If \code{x} is a \code{RasterStack} or \code{RasterBrick} then this is ignored (longitude is ascertained directly from the rasters, which \emph{must} be in equal-area projection for velocities to be valid).
#'	\item If \code{x} is an array and \code{longitude} is \code{NULL} (default), then longitude will be ascertained from column numbers in \code{x} and velocities will be in arbitrary spatial units (versus, for example, meters). Alternatively, this can be a two-dimensional matrix whose elements represent the longitude coordinates of the centers of cells of \code{x}. The matrix must have the same number of rows and columns as \code{x}. Coordinates must be from an equal-area projection for results to be valid.
#' }
#' @param latitude Numeric matrix or \code{NULL} (default):
#' \itemize{
#'	\item If \code{x} is a \code{RasterStack} or \code{RasterBrick} then this is ignored (latitude is obtained directly from the rasters, which \emph{must} be in equal-area projection for velocities to be valid).
#'	\item If \code{x} is an array and \code{latitude} is \code{NULL} (default), then latitude will be obtained from row numbers in \code{x} and velocities will be in arbitrary spatial units (versus, for example, meters). Alternatively, this can be a two-dimensional matrix whose elements represent the latitude coordinates of the centers of cells of \code{x}. The matrix must have the same number of rows and columns as \code{x}. Coordinates must be from an equal-area projection for results to be valid.
#' }
#' @param elevation Either \code{NULL} (default) or a raster or matrix representing elevation. If this is supplied, changes in elevation are incorporated into all velocity and speed metrics. Additionally, you can also calculate the metrics \code{elevCentrioid} and \code{elevQuants}.
#' @param metrics Biotic velocity metrics to calculate (default is to calculate them all). All metrics ignore \code{NA} cells in \code{x}. Here "starting time period" represents one layer in \code{x} and "end time period" the next layer.
#' \itemize{
#'  \item \code{summary}: This calculates a series of measures, none of which are measures of velocity:
#'		\itemize{
#'			\item Mean: Mean value across all cells.
#'			\item Sum: Total across all cells.
#'			\item Quantiles: \emph{N}th quantile values across all cells. Quantiles are given by \code{quants}.
#'			\item Prevalence: Number of cells with values > 0.
#'		}
#' 	\item \code{centroid}: Speed of mass-weighted centroid.
#'  \item \code{nsCentroid} or \code{ewCentroid}: Velocity in the north-south or east-west directions of the mass-weighted centroid. For north-south cardinality, positive values represent movement northward and negative southward.
#'  \item \code{nCentroid}, \code{sCentroid}, \code{eCentroid}, and \code{wCentroid}: Speed of mass-weighted centroid of the portion of the raster north/south/east/west of the landscape-wide weighted centroid of the starting time period.
#'  \item \code{nsQuants} or \code{ewQuants}: Velocity of the location of the \emph{N}th quantile of mass in the north-south or east-west directions. The quantiles can be specified in \code{quants}. For example, this could be the movement of the 5th, 50th, and 95th quantiles of population size going from south to north. The 0th quantile would measure the velocity of the southernmost or easternmost cell(s) with values >0, and the 100th quantile the northernmost or westernmost cell(s) with non-zero values.
#'  \item \code{similarity}: Several metrics of similarity between each time period. Some of these make sense only for cases where values in \code{x} are in the range [0, 1], but not if some values are outside this range. See \code{\link{compareNiches}} for more details. The metrics are:
#'		\itemize{
#'			\item Simple mean difference
#'			\item Mean absolute difference
#'			\item Root-mean squared difference
#'			\item Expected Fraction of Shared Presences or ESP (Godsoe 2014)
#'			\item D statistic (Schoener 1968)
#'			\item I statistic (Warren et al. 2008)
#'			\item Pearson correlation
#'			\item Spearman rank correlation
#'		}
#'  \item \code{elevCentroid}: Velocity of the centroid of mass in elevation (up or down). Argument \code{elevation} must be supplied.
#' 	\item \code{elevQuants}: Velocity of the emph{n}th quantile of mass in elevation (up or down). The quantiles to be evaluated are given by \code{quants}. The lowest elevation with mass >0 is the 0th quantile, and the highest elevation with mass >0 is the 100th. Argument \code{elevation} must be supplied.
#' }
#' @param quants Numeric vector indicating the quantiles at which biotic velocity is calculated for the "\code{quant}" and "\code{Quants}" metrics. Default is \code{c(0.05, 0.10, 0.5, 0.9, 0.95)}.
#' @param onlyInSharedCells Logical, if \code{TRUE}, calculate biotic velocity using only those cells that are not \code{NA} in the start and end of each time period. This is useful for controlling for shifting land mass due to sea level rise, for example, when calculating biotic velocity for an ecosystem or a species. The default is \code{FALSE}.
#' @param cores Positive integer. Number of processor cores to use. Note that if the number of time steps at which velocity is calculated is small, using more cores may not always be faster.
#' @param warn Logical, if \code{TRUE} (default) then display function-specific warnings.
#' @param ... Other arguments (not used).
#' @return A data frame with biotic velocities and related values. Fields are as follows:
#' \itemize{
#' 	\item \code{timeFrom}: Start time of interval
#' 	\item \code{timeTo}: End time of interval
#' 	\item \code{timeSpan}: Duration of interval
#' }
#' Depending on \code{metrics} that are specified, additional fields are as follows. All measurements of velocity are in distance units (typically meters) per time unit (which is the same as the units used for \code{times} and \code{atTimes}). For example, if the rasters are in an Albers equal-area projection and \code{times} are in years, then the output will be meters per year.
#' \itemize{
#' 	\item If \code{metrics} contains \code{summary}:
#' 	\itemize{
#'		\item A column named \code{propSharedCellsNotNA}: Proportion of cells that are not \code{NA} in both the "from" and "to" time step.
#'		\item Columns named \code{timeFromPropNotNA} and \code{timeToPropNotNA}: Proportion of cells in the "from" time and "to" steps that are not \code{NA}.
#' 		\item A column named \code{mean}: Mean weight in "timeTo" time step. In the same units as the values of the cells.
#' 		\item Columns named \code{quantile_quant}\emph{N}: The \emph{N}th quantile(s) of weight in the "timeTo" time step. In the same units as the values of the cells.
#' 		\item A column named \code{prevalence}: Proportion of non-\code{NA} cells with weight >0 in the "timeTo" time step relative to all non-\code{NA} cells. Unitless.
#' }
#' 	\item If \code{metrics} has \code{'centroid'}: Columns named \code{centroidVelocity}, \code{centroidLong}, \code{centroidLat} -- Speed of weighted centroid, plus its longitude and latitude (in the "to" time period of each time step). Values are always >= 0.
#' 	\item If \code{metrics} has \code{'nsCentroid'}: Columns named \code{nsCentroid} and \code{nsCentroidLat} -- Velocity of weighted centroid in north-south direction, plus its latitude (in the "to" time period of each time step). Positive values connote movement north, and negative values south.
#' 	\item If \code{metrics} has \code{'ewControid'}: \code{ewCentroid} and \code{ewCentroidLong} -- Velocity of weighted centroid in east-west direction, plus its longitude (in the "to" time period of each time step).  Positive values connote movement east, and negative values west.
#' 	\item If \code{metrics} has \code{'nCentroid'}, \code{'sCentroid'}, \code{'eCentroid'}, and/or \code{'wCentroid'}: Columns named \code{nCentroidVelocity} and \code{nCentroidAbund}, \code{sCentroid} and \code{sCentroidAbund}, \code{eCentroid} and \code{eCentroidAbund}, and/or \code{wCentroid} and \code{wCentroidAbund} -- Speed of weighted centroid of all cells that fall north, south, east, or west of the landscape-wide centroid, plus a column indicating the weight (abundance) of all such populations. Values are always >= 0.
#' 	\item If \code{metrics} contains any of \code{nsQuants} or \code{ewQuants}: Columns named \code{nsQuantVelocity_quant}\emph{N} and \code{nsQuantLat_quant}\emph{N}, or \code{ewQuantVelocity_quant}\emph{N} and \code{ewQuantLat_quant}\emph{N}: Velocity of the \emph{N}th quantile weight in the north-south or east-west directions, plus the latitude or longitude thereof (in the "to" time period of each time step). Quantiles are cumulated starting from the south or the west, so the 0.05th quantile, for example, is in the far south or west of the range and the 0.95th in the far north or east. Positive values connote movement north or east, and negative values movement south or west.
#' \item If \code{metrics} contains \code{similarity}, metrics of similarity are calculated for each pair of successive landscapes, defined below as \code{x1} and \code{x2}, with the number of shared non-\code{NA} cells between them being \code{n}:
#'	\itemize{
#'		\item A column named \code{simpleMeanDiff}: \code{sum(x2 - x1, na.rm=TRUE) / n}
#'		\item A column named \code{meanAbsDiff}: \code{sum(abs(x2 - x1), na.rm=TRUE) / n}
#'		\item A column named \code{rmsd} (root-mean square difference): \code{sqrt(sum((x2 - x1)^2, na.rm=TRUE)) / n}
#'		\item A column named \code{godsoeEsp}: \code{1 - sum(2 * (x1 * x2), na.rm=TRUE) / sum(x1 + x2, na.rm=TRUE)}, values of 1 ==> maximally similar, 0 ==> maximally dissimilar.
#'		\item A column named \code{schoenersD}: \code{1 - (sum(abs(x1 - x2), na.rm=TRUE) / n)}, values of 1 ==> maximally similar, 0 ==> maximally dissimilar.
#'		\item A column named \code{warrensI}: \code{1 - sqrt(sum((sqrt(x1) - sqrt(x2))^2, na.rm=TRUE) / n)}, values of 1 ==> maximally similar, 0 ==> maximally dissimilar.
#'		\item A column named \code{cor}: Pearson correlation between values of \code{x1} and \code{x2}.
#'		\item A column named \code{rankCor}: Spearman rank correlation between values of \code{x1} and \code{x2}.
#'	}
#' 	\item If \code{metrics} contains \code{elevCentroid}: Columns named \code{elevCentroidVelocity} and \code{elevCentroidElev} -- Velocity of the centroid in elevation (up or down) and the elevation in the "to" timestep. Positive values of velocity connote movement upward, and negative values downward.
#' 	\item If \code{metrics} contains \code{elevQuants}: Columns named \code{elevQuantVelocity_quant}\emph{N} and \code{elevQuantVelocityElev_quant}\emph{N} -- Velocity of the \emph{N}th quantile of mass in elevation (up or down) and the elevation of this quantile in the "to" timestep. Positive values of velocity connote movement upward, and negative values downward.
#' }
#' @details
#' \emph{Attention:}  
#'   
#' This function may yield erroneous velocities if the region of interest is near or spans a pole or the international date line. Results using the "Quant" and "quant" metrics may be somewhat counterintuitive if just one cell is >0, or one row or column has the same values with all other values equal to 0 or \code{NA} because defining quantiles in these situations is not intuitive. Results may also be counterintuitive if some cells have negative values because they can "push" a centroid away from what would seem to be the center of mass as assessed by visual examination of a map.  
#'   
#' \emph{Note:}  
#'   
#' For the \code{nsQuants} and \code{ewQuants} metrics it is assumed that the latitude/longitude assigned to a cell is at its exact center. If a desired quantile does not fall exactly on the cell center, it is interpolated linearly between the rows/columns of cells that bracket the given quantile. For quantiles that fall south/westward of the first row/column of cells, the cell border is assumed to be at 0.5 * cell length south/west of the cell center.
#' @examples
#' \dontrun{
#'
#' }
#' @export

climateVelocity <- function(
	x,
	clim,
	times = NULL,
	atTimes = NULL,
	longitude = NULL,
	latitude = NULL,
	...
) {

	
	
}
