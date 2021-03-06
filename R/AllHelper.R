#' @name ClusterExperiment-methods
#' @title Helper methods for the ClusterExperiment class
#'
#' @description This is a collection of helper methods for the ClusterExperiment class.
#' @param ... For \code{addToColData}, arguments passed to \code{colDataClusters}.
#' @param value The value to be substituted in the corresponding slot. See the
#'   slot descriptions in \code{\link{ClusterExperiment}} for details on what
#'   objects may be passed to these functions.
#' @rdname ClusterExperiment-methods
#' @aliases show show,ClusterExperiment-method
#' @export
setMethod(
  f = "show",
  signature = "ClusterExperiment",
  definition = function(object) {
    cat("class:", class(object), "\n")
    cat("dim:", dim(object), "\n")
    cat("reducedDimNames:",if(anyValidReducedDims(object)) reducedDimNames(object) else "no reduced dims stored","\n")
    cat("filterStats:",if(anyValidFilterStats(object)) filterNames(object) else "no valid filtering stats stored","\n")
    cat("-----------\n")
    cat("Primary cluster type:", clusterTypes(object)[primaryClusterIndex(object)],"\n")
    cat("Primary cluster label:", clusterLabels(object)[primaryClusterIndex(object)],"\n")
    cat("Table of clusters (of primary clustering):")
    print(table(primaryClusterNamed(object)))
    cat("Total number of clusterings:", NCOL(clusterMatrix(object)),"\n")
    if(!is.na(dendroClusterIndex(object)) ) cat("Dendrogram run on '",clusterLabels(object)[dendroClusterIndex(object)],"' (cluster index: ", dendroClusterIndex(object),")\n",sep="") else cat("No dendrogram present\n")
    cat("-----------\n")
    cat("Workflow progress:\n")
    typeTab<-names(table(clusterTypes(object)))
    cat("clusterMany run?",if("clusterMany" %in% typeTab) "Yes" else "No","\n")
    cat("makeConsensus run?",if("makeConsensus" %in% typeTab) "Yes" else "No","\n")
    cat("makeDendrogram run?",if(!is.null(object@dendro_samples) & !is.null(object@dendro_clusters) ) "Yes" else "No","\n")
    cat("mergeClusters run?",if("mergeClusters" %in% typeTab) "Yes" else "No","\n")
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{transformation} prints the function used to transform the data
#' prior to clustering.
#' @export
#' @aliases transformation
setMethod(
  f = "transformation",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@transformation)
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @details Note that redefining the transformation function via
#'   \code{transformation(x)<-} will check the validity of the transformation on
#'   the data assay. If the assay is large, this may be time consuming. Consider
#'   using a call to ClusterExperiment, which has the option as to whether to
#'   check the validity of the transformation.
#' @aliases transformation<-
setReplaceMethod(
  f = "transformation",
  signature = signature("ClusterExperiment", "function"),
  definition = function(object, value) {
	checkValidity=TRUE
    object@transformation <- value
    if(checkValidity){
		ch<-.checkTransform(object)
    	if(ch) return(object) else stop(ch)
	}
	else return(object)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nClusterings} returns the number of clusterings (i.e., ncol of
#' clusterMatrix).
#' @export
#' @aliases nClusterings
setMethod(
  f = "nClusterings",
  signature = "ClusterExperiment",
  definition = function(x){
    return(NCOL(clusterMatrix(x)))
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{nClusters} returns the number of clusters per clustering
#' @param ignoreUnassigned logical. If true, ignore the clusters with -1 or -2 assignments in calculating the number of clusters per clustering. 
#' @export
#' @aliases nClusters
setMethod(
  f = "nClusters",
  signature = "ClusterExperiment",
  definition = function(x,ignoreUnassigned=TRUE){
	  if(ignoreUnassigned){
		  return(apply(clusterMatrix(x),2,function(x){length(unique(x[x>0]))}))
	  }
	  else return(apply(clusterMatrix(x),2,function(x){length(unique(x))}))
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nFeatures} returns the number of features (same as `nrow`).
#' @aliases nFeatures
#' @export
setMethod(
  f = "nFeatures",
  signature =  "ClusterExperiment",
  definition = function(x){
    return(NROW(assay(x)))
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nSamples} returns the number of samples (same as `ncol`).
#' @aliases nSamples
#' @export
setMethod(
  f = "nSamples",
  signature = "ClusterExperiment",
  definition = function(x){
    return(NCOL(assay(x)))
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrixNamed} returns a matrix with cluster labels.
#' @export
#' @aliases clusterMatrixNamed
#' @param x,object a ClusterExperiment object.
setMethod(
  f = "clusterMatrixNamed",
  signature = "ClusterExperiment",
  definition = function(x, whichClusters="all") {
    convertClusterLegend(x,output="matrixNames",whichClusters=whichClusters)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrixColors} returns the matrix with all the clusterings, using the internally stored colors for each cluster
#' @export
#' @aliases clusterMatrixColors
setMethod(
  f = "clusterMatrixColors",
  signature = c("ClusterExperiment"),
  definition = function(x,whichClusters) {
    convertClusterLegend(x,output="matrixColors",whichClusters=whichClusters)
  }
)

#' @rdname ClusterExperiment-methods
#' @param whichClusters argument that can be either numeric or character value
#'   indicating the clusters to be used. If numeric, gives the indices of the
#'   \code{clusterMatrix} to return; this can also be used to defined an
#'   ordering for the clusterings (as relevant). \code{whichClusters} can be a
#'   character value identifying the \code{clusterTypes} to be used, or if not
#'   matching \code{clusterTypes} then \code{clusterLabels}; alternatively
#'   \code{whichClusters} can be either 'all' or 'workflow' or 'primary' to
#'   indicate choosing all clusterings or choosing all 
#'   \code{\link{workflowClusters}} clusterings or choosing the 'primary'
#'   clustering, respectively. If missing, the entire matrix of all clusterings
#'   is returned.
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","missing"),
  definition = function(x,whichClusters) {
    wh<-seq_len(ncol(x@clusterMatrix))
    return(clusterMatrix(x,whichClusters=wh))
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","numeric"),
  definition = function(x,whichClusters) {
	  mat<-x@clusterMatrix[,whichClusters,drop=FALSE]
	  rownames(mat)<-colnames(x)
    return(mat)
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","character"),
  definition = function(x,whichClusters) {
	  wh<-.TypeIntoIndices(x,whClusters=whichClusters)
	  return(clusterMatrix(x,whichClusters=wh))
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{primaryCluster} returns the primary clustering (as numeric).
#' @export
#' @aliases primaryCluster
setMethod(
  f = "primaryCluster",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@clusterMatrix[,primaryClusterIndex(x)])
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterIndex} returns/sets the primary clustering index
#' (i.e., which column of clusterMatrix corresponds to the primary clustering).
#' @export
#' @aliases primaryClusterIndex
setMethod(
  f = "primaryClusterIndex",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@primaryIndex)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterIndex} returns/sets the primary clustering index
#' (i.e., which column of clusterMatrix corresponds to the primary clustering).
#' @export
#' @aliases primaryClusterLabel
setMethod(
  f = "primaryClusterLabel",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(clusterLabels(x)[primaryClusterIndex(x)])
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterNamed} returns the primary cluster (using cluster
#' labels).
#' @export
#' @aliases primaryClusterNamed
setMethod(
  f = "primaryClusterNamed",
  signature = "ClusterExperiment",
  definition = function(x) {
    as.vector(clusterMatrixNamed(x,whichCluster="primary"))
  })

#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterIndex} returns/sets the primary clustering index
#' (i.e., which column of clusterMatrix corresponds to the primary clustering).
#' @export
#' @aliases primaryClusterType
setMethod(
  f = "primaryClusterType",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(clusterTypes(x)[primaryClusterIndex(x)])
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{subsetByCluster} subsets the object by clusters in a clustering
#' and returns a ClusterExperiment object with only those samples
#' @param clusterValue values of the cluster to match to for subsetting
#' @param matchTo for subsetting, whether to match to the cluster name
#'   (\code{"name"}) or internal cluster id (\code{"clusterIds"})
#' @export
#' @aliases subsetByCluster
setMethod(
  f = "subsetByCluster",
  signature = "ClusterExperiment",
  definition = function(x,clusterValue,whichCluster="primary",matchTo=c("name","clusterIds")) {
    
		whCl<-.convertSingleWhichCluster(x,whichCluster)
		matchTo<-match.arg(matchTo)
		if(matchTo=="name"){
			cl<-clusterMatrixNamed(x)[,whCl]
		}
		else cl<-clusterMatrix(x)[,whCl]
		return(x[,which(cl %in% clusterValue)])
  }
)


#' @rdname ClusterExperiment-methods
#' @export
#' @aliases primaryClusterIndex<-
setReplaceMethod(
  f = "primaryClusterIndex",
  signature = signature("ClusterExperiment", "numeric"),
  definition = function(object, value) {
    object@primaryIndex <- value
    ch<-.checkPrimaryIndex(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{dendroClusterIndex} returns/sets the clustering index 
#' of the clusters used to create dendrogram
#' (i.e., which column of clusterMatrix corresponds to the clustering).
#' @export
#' @aliases dendroClusterIndex
setMethod(
  f = "dendroClusterIndex",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@dendro_index)
  }
)



#' @rdname ClusterExperiment-methods
#' @return \code{coClustering} returns/sets the co-clustering matrix.
#' @export
#' @aliases coClustering
setMethod(
  f = "coClustering",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@coClustering)
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases coClustering<-
setReplaceMethod(
  f = "coClustering",
  signature = signature(object="ClusterExperiment", value="matrix"),
  definition = function(object, value) {
    object@coClustering <- value
    ch<-.checkCoClustering(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusterTypes} returns/sets the clusterTypes slot.
#' @export
#' @aliases clusterTypes
setMethod(
  f = "clusterTypes",
  signature = "ClusterExperiment",
  definition = function(x) {
    out<-x@clusterTypes
    #names(out)<-clusterLabels(x)
    return(out)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusteringInfo} returns the clusterInfo slot.
#' @aliases clusteringInfo
#' @export
setMethod(
  f = "clusteringInfo",
  signature = "ClusterExperiment",
  definition = function(x) {
    out<-x@clusterInfo
    names(out)<-clusterLabels(x)
    return(out)
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{clusterLabels} returns/sets the column names of the clusterMatrix slot.
#' @export
#' @aliases clusterLabels
setMethod(
  f = "clusterLabels",
  signature = signature(x = "ClusterExperiment"),
  definition = function(x){
    labels<-colnames(clusterMatrix(x))
    if(is.null(labels)) cat("No labels found for clusterings\n")
    return(labels)

  }
)
#' @export
#' @rdname ClusterExperiment-methods
#' @aliases clusterLabels<-
setReplaceMethod( 
  f = "clusterLabels",
  signature = signature(object="ClusterExperiment", value="character"),
  definition = function(object, value) {
    if(length(value)!=NCOL(clusterMatrix(object))) stop("value must be a vector of length equal to NCOL(clusterMatrix(object)):",NCOL(clusterMatrix(object)))
    colnames(object@clusterMatrix) <- value
    ch<-.checkClusterLabels(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterLegend} returns/sets the clusterLegend slot.
#' @export
#' @aliases clusterLegend
setMethod(
    f = "clusterLegend",
    signature = "ClusterExperiment",
    definition = function(x) {
      out<-x@clusterLegend
      names(out)<-clusterLabels(x)
      return(out)
    }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases clusterLegend<-
setReplaceMethod( 
  f = "clusterLegend",
  signature = signature(object="ClusterExperiment", value="list"),
  definition = function(object, value) {
    object@clusterLegend<-unname(value)
    ch<-.checkClusterLegend(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)


.checkMatch<-function(clMat,value,matchTo){
	if(is.null(names(value))){
		clVals<-clMat[,"clusterIds"]
		if(length(value)== nrow(clMat)) names(value)<-clVals
		else if(length(value)==length(clVals[clVals>0])) names(value)<-clMat[clVals>0,"clusterIds"]
		else stop("length of argument 'value' not equal to number of clusters, nor does it have names to identify it to 'clusterIds' of this clustering.")
			matchTo<-"clusterIds"
	} 
	if(matchTo=="name"){
		if(!all(names(value) %in% clMat[,"name"])) stop("'value' must be vector with names that matches the 'name' column of the requested clusterLegend")
			m<-match(names(value),clMat[,"name"])
	}
	else{
		if(!all(names(value) %in% clMat[,"clusterIds"])) stop("'value' must be vector with names that matches the 'clusterIds' column of the requested clusterLegend")
			m<-match(names(value),clMat[,"clusterIds"])
		
	}
	return(m)
}
#' @rdname ClusterExperiment-methods
#' @return \code{renameClusters} changes the names assigned to clusters within a clustering
#' @param whichCluster argument to identify cluster, taking input like 
#' \code{whichClusters}, only requires that only a single clustering can be identified. 
#' @export
#' @aliases renameClusters
setMethod( 
  f = "renameClusters",
  signature = signature(object="ClusterExperiment", value="character"),
  definition = function(object, value,whichCluster="primary",matchTo=c("name","clusterIds")) {
		matchTo<-match.arg(matchTo)
		whCl<-.convertSingleWhichCluster(object,whichCluster)
		mat<-clusterLegend(object)[[whCl]]
		m<-.checkMatch(clMat=mat,value=value,matchTo=matchTo)
		mat[m,"name"]<-value
		clusterLegend(object)[[whCl]]<-mat
		
    ch<-.checkClusterLegend(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{recolorClusters} changes the colors assigned to clusters within a clustering
#' @export
#' @aliases recolorClusters
setMethod( 
  f = "recolorClusters",
  signature = signature(object="ClusterExperiment", value="character"),
  definition = function(object, value,whichCluster="primary",matchTo=c("name","clusterIds")) {
		matchTo<-match.arg(matchTo)
		whCl<-.convertSingleWhichCluster(object,whichCluster)
		mat<-clusterLegend(object)[[whCl]]
		m<-.checkMatch(clMat=mat,value=value,matchTo=matchTo)
		mat[m,"color"]<-value
		clusterLegend(object)[[whCl]]<-mat
		
    ch<-.checkClusterLegend(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{orderSamples} returns/sets the orderSamples slot.
#' @export
#' @aliases orderSamples
setMethod(
  f = "orderSamples",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@orderSamples)
  }
)
#' @rdname ClusterExperiment-methods
#' @export
#' @aliases orderSamples<-
setReplaceMethod( 
  f = "orderSamples",
  signature = signature(object="ClusterExperiment", value="numeric"),
  definition = function(object, value) {
    object@orderSamples<-value
    ch<-.checkOrderSamples(object) 
    if(is.logical(ch) && ch) return(object) else stop(ch)
    
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases clusterTypes<-
setReplaceMethod( 
  f = "clusterTypes",
  signature = signature(object="ClusterExperiment", value="character"),
  definition = function(object,value) {
    object@clusterTypes<-value
    object<-.unnameClusterSlots(object)
    ch<-.checkClusterTypes(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
    
  }
)
#' @rdname ClusterExperiment-methods
#' @export
#' @inheritParams plotClustersTable
#' @aliases addToColData
#' @return \code{addToColData} returns a \code{ClusterExperiment} object
#' with the clusterings in clusterMatrix slot added to the \code{colData} slot
setMethod(
	f="addToColData",
	signature="ClusterExperiment",
	definition=function(object,...){
		colData(object)<-colDataClusters(object,...)
		return(object)
	})
#' @rdname ClusterExperiment-methods
#' @export
#' @param makeFactor logical for \code{colDataClusters}. If TRUE the clustering
#'   will be added to the \code{colData} slot as a factor. If FALSE, the
#'   clustering will be added to the \code{colData} slot as a character vector
#'   if \code{useNames=TRUE} and as a numeric vector if \code{useNames=FALSE}.
#' @aliases colDataClusters
#' @return \code{colDataClusters} returns a \code{DataFrame} object
#' that has the clusterings in clusterMatrix slot added to the 
#' \code{DataFrame} in the \code{colData} slot
#' @importFrom S4Vectors DataFrame
setMethod(
	f="colDataClusters",
	signature="ClusterExperiment",
	definition=function(object,whichClusters="primary",useNames=TRUE,makeFactor=TRUE,...){
		if(useNames){
			cm<-clusterMatrixNamed(object,whichClusters=whichClusters)
			if(!makeFactor) cm<-DataFrame(data.frame(cm,stringsAsFactors=FALSE),check.names=FALSE)
			else cm<-DataFrame(cm,check.names=FALSE)
		}
		else{
			cm<-clusterMatrix(object,whichClusters=whichClusters)
			if(makeFactor){
				cnames<-colnames(cm)
				cm<-do.call("DataFrame",c(lapply(1:ncol(cm),function(i){factor(cm[,i])}),list(check.names=FALSE))) 
				colnames(cm)<-cnames		
			}
			else cm<-DataFrame(cm,check.names=FALSE)
		}
		return(cbind(colData(object),cm))
	})