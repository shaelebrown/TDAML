#### PERSISTENCE FISHER KERNEL ####
#' Calculate persistence Fisher kernel value between a pair of persistence diagrams.
#'
#' Returns the persistence Fisher kernel value between a pair of persistence diagrams
#' in a particular homological dimension, each of which is either the output from a \code{\link{diagram_to_df}} 
#' function call or from a TDA homology calculation like \code{\link[TDA]{ripsDiag}}.
#'
#' The persistence Fisher kernel is calculated from the Fisher information metric according to the formula
#' \eqn{k_{PF}(D_1,D_2) = exp(-t*d_{FIM}(D_1,D_2))}, resembling a radial basis kernel for standard
#' Euclidean spaces.
#'
#' @param D1 the first persistence diagram, either outputted from a TDA calculation like \code{\link[TDA]{ripsDiag}} or from a \code{\link{diagram_to_df}} function call.
#' @param D2 the second persistence diagram, either outputted from a TDA calculation like \code{\link[TDA]{ripsDiag}} or from a \code{\link{diagram_to_df}} function call.
#' @param dim the non-negative integer homological dimension in which the distance is to be computed, default 0.
#' @param sigma a positive number representing the bandwidth for the Fisher information metric, default 1.
#' @param t a positive number representing the scale for the persistence Fisher kernel, default 1.
#'
#' @return the numeric kernel value.
#' @export
#' @author Shael Brown - \email{shaelebrown@@gmail.com}
#' @references
#' Le T, Yamada M (2018). "Persistence fisher kernel: a riemannian manifold kernel for persistence diagrams." \url{https://proceedings.neurips.cc/paper/2018/file/959ab9a0695c467e7caf75431a872e5c-Paper.pdf}.
#' 
#' Murphy, K. "Machine learning: a probabilistic perspective", MIT press (2012).
#' @examples
#'
#' # load three diagrams
#' D1 <- generate_TDAML_test_data(1,0,0)
#' D2 <- generate_TDAML_test_data(0,1,0)
#' D3 <- generate_TDAML_test_data(0,0,1)
#' 
#' # calculate the kernel value between D1 and D2 with sigma = 2, t = 2
#' diagram_kernel(D1,D2,dim = 0,sigma = 2,t = 2)
#' # calculate the kernel value between D1 and D3 with sigma = 2, t = 2
#' diagram_kernel(D1,D3,dim = 0,sigma = 2,t = 2)

diagram_kernel <- function(D1,D2,dim = 0,sigma = 1,t = 1){
  
  # check kernel-specific parameter, other inputs are checked in distance calculation
  check_param("t",t,non_negative = T,positive = F)
  
  # return kernel calculation
  return(exp(-1*t*diagram_distance(D1 = D1,D2 = D2,dim = dim,distance = "fisher",sigma = sigma)))
  
}

#### GRAM MATRIX ####
#' Compute the gram matrix for a group of persistence diagrams.
#' 
#' Calculate the Gram matrix \eqn{K} for either a single list of persistence diagrams \eqn{(D_1,D_2,\dots,D_n)}, i.e. \eqn{K[i,j] = k_{PF}(D_i,D_j)}, 
#' or between two lists of persistence diagrams, \eqn{(D_1,D_2,\dots,D_n)} and \eqn{(D'_1,D'_2,\dots,D'_n)}, \eqn{K[i,j] = k_{PF}(D_i,D'_j)}, in parallel.
#' 
#' Gram matrices are used in downstream analyses, like in the `diagram_kkmeans`, `diagram_nearest_cluster`,`diagram_kpca`, 
#' `predict_diagram_kpca`, `predict_diagram_ksvm` and `independence_test` functions.
#'
#' @param diagrams a list of persistence diagrams, either the output from TDA calculations like \code{\link[TDA]{ripsDiag}} or the \code{\link{diagram_to_df}} function.
#' @param other_diagrams either NULL (default) or another list of persistence diagrams to compute a cross-Gram matrix.
#' @param dim the non-negative integer homological dimension in which the distance is to be computed, default 0.
#' @param sigma a positive number representing the bandwidth for the Fisher information metric, default 1.
#' @param t a positive number representing the scale for the kernel, default 1.
#' @param num_workers the number of cores used for parallel computation, default is one less than the number of cores on the machine.
#'
#' @return the numeric (cross) Gram matrix of class 'kernelMatrix'.
#' @export
#' @author Shael Brown - \email{shaelebrown@@gmail.com}
#' @importFrom foreach foreach %dopar%
#' @importFrom parallel makeCluster stopCluster clusterExport clusterEvalQ
#' @importFrom parallelly availableCores
#' @importFrom doParallel registerDoParallel
#' @importFrom iterators iter
#' @examples
#'
#' # load three diagrams
#' D1 <- generate_TDAML_test_data(1,0,0)
#' D2 <- generate_TDAML_test_data(0,1,0)
#' D3 <- generate_TDAML_test_data(0,0,1)
#' g <- list(D1,D2,D3)
#'
#' # calculate the Gram matrix in dimension 1 with sigma = 2, t = 2
#' G <- gram_matrix(diagrams = g,dim = 1,sigma = 2,t = 2,num_workers = 2)
#' 
#' # calculate cross-Gram matrix, which is the same as G
#' G_cross <- gram_matrix(diagrams = g,other_diagrams = g,dim = 1,sigma = 2,
#'                        t = 2,num_workers = 2)

gram_matrix <- function(diagrams,other_diagrams = NULL,dim = 0,sigma = 1,t = 1,num_workers = parallelly::availableCores(omit = 1)){
  
  # set internal variables to NULL to avoid build issues
  r <- NULL
  X <- NULL
  
  # error check diagrams and other_diagrams arguments
  check_param("diagrams",diagrams,numeric = F,multiple = T)
  diagrams <- all_diagrams(diagram_groups = list(diagrams),inference = "independence")[[1]]
  if(!is.null(other_diagrams))
  {
    check_param("other_diagrams",other_diagrams,numeric = F,multiple = T)
  }
  
  # error check num_workers argument
  check_param("num_workers",num_workers,whole_numbers = T,at_least_one = T)
  if(num_workers > parallelly::availableCores())
  {
    warning("num_workers is greater than the number of available cores - setting to maximum value.")
    num_workers <- parallelly::availableCores()
  }
  
  # compute Gram matrix in parallel
  m = length(diagrams)
  cl <- parallel::makeCluster(num_workers)
  doParallel::registerDoParallel(cl)
  force(check_diagram)
  parallel::clusterExport(cl,c("diagram_distance","diagram_kernel","check_diagram","check_param","diagram_to_df"),envir = environment())
  force(diagrams) # required for parallel computation in this environment
  
  if(is.null(other_diagrams))
  {
    K <- matrix(data = 1,nrow = m,ncol = m)
    k <- foreach::`%dopar%`(obj = foreach::foreach(r = iterators::iter(which(upper.tri(K),arr.ind = T),by = 'row'),.combine = c),ex = {
      
      return(diagram_kernel(D1 = diagrams[[r[[1]]]],D2 = diagrams[[r[[2]]]],dim = dim,sigma = sigma,t = t))
      
    })
    K[upper.tri(K)] <- k
    K[which(upper.tri(K),arr.ind = T)[,c("col","row")]] <- k
    diag(K) <- rep(1,m)
  }else
  {
    if(length(other_diagrams) > length(diagrams))
    {
      K <- foreach::`%dopar%`(obj = foreach::foreach(r = 1:length(other_diagrams),.combine = cbind),ex = {
        
        return(unlist(lapply(X = 1:length(diagrams),FUN = function(X){return(diagram_kernel(D1 = other_diagrams[[r]],D2 = diagrams[[X]],dim = dim,sigma = sigma,t = t))})))
        
      })
    }else
    {
      K <- foreach::`%do%`(obj = foreach::foreach(r = 1:length(other_diagrams),.combine = cbind),ex = {
        
        return(foreach::`%dopar%`(obj = foreach::foreach(X = 1:length(diagrams),.combine = c),ex = {
          
          return(diagram_kernel(D1 = other_diagrams[[r]],D2 = diagrams[[X]],dim = dim,sigma = sigma,t = t))
          
        }))
        
      })
    }
    
  }
  
  parallel::stopCluster(cl)
  
  # update class for interfacing with kernlab package
  class(K) <- "kernelMatrix"
  
  return(K)

}



