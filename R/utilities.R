
#' @importFrom stats complete.cases
#' @importFrom methods is

# error checks for function parameters

check_diagram <- function(d,ret){

  # error checks for a diagram d stored as a data frame, and conversion
  if(is.list(d) && ((length(d) == 1 && names(d) == "diagram" && methods::is(d$diagram,"diagram")) || ((length(d) == 4 && names(d) == c("diagram","birthLocation","deathLocation","cycleLocation") && methods::is(d$diagram,"diagram")))))
  {
    # d is the output from a TDA calculation
    d <- diagram_to_df(d)
  }else
  {
    if(!methods::is(d,"data.frame"))
    {
      stop("Diagrams must either be the output of a TDA computation or data frame.")
    }
  }

  if(nrow(d) == 0)
  {
    stop("Every diagram must be non-empty.")
  }

  if(ncol(d) != 3)
  {
    stop("Every diagram must have three columns.")
  }

  if(!methods::is(d[,1],"numeric") | !methods::is(d[,2],"numeric") | !methods::is(d[,3],"numeric"))
  {
    stop("Diagrams must have numeric columns.")
  }

  if(!all.equal(d[,1],as.integer(d[,1])))
  {
    stop("Homology dimensions must be whole numbers.")
  }

  if(length(which(d[,1] < 0)) > 0)
  {
    stop("Homology dimensions must be >= 0.")
  }

  if(length(which(d[,2] < 0)) > 0 | length(which(d[,3] < 0)) > 0)
  {
    stop("Birth and death radii must be >= 0.")
  }

  if(length(which(stats::complete.cases(d))) != nrow(d))
  {
    stop("Diagrams can't have missing values.")
  }
  
  if(ret == T)
  {
    return(d) 
  }

}

all_diagrams <- function(diagram_groups,inference){

  # function to make sure all diagram groups are lists or vectors of diagrams,
  # to convert the diagrams to data frames and to error check each diagram.
  # diagram_groups is a vector or list of vectors or lists of diagrams
  # inference is a string, either 'difference' for the permutation test or
  # 'independence' for the independence test
  
  if(inference == "difference")
  {
    # compute cumulative sums of groups lengths in order to correctly compute diagram indices
    csum_group_sizes <- cumsum(unlist(lapply(diagram_groups,FUN = length)))
    csum_group_sizes <- c(0,csum_group_sizes)
  }
  
  # loop through all diagram groups
  for(g in 1:length(diagram_groups))
  {
    # loop through each diagram in each group
    for(diag in 1:length(diagram_groups[[g]]))
    {
      # check to make sure each diagram is actually the output of some TDA computation or a data frame
      check_diagram(diagram_groups[[g]][[diag]],ret = F)
      # if of the right form, format into a data frame and store diagram index
      if(methods::is(diagram_groups[[g]][[diag]],"data.frame"))
      {
        if(inference == "difference")
        {
          diagram_groups[[g]][[diag]] <- list(diag = diagram_groups[[g]][[diag]],ind = csum_group_sizes[g] + diag)
        }
      }else
      {
        if(inference == "difference")
        {
          diagram_groups[[g]][[diag]] <- list(diag = diagram_to_df(diagram_groups[[g]][[diag]]),ind = csum_group_sizes[g] + diag)
        }
      }
      
      # make sure the converted diagram has appropriate attributes for further use
      if(inference == "difference")
      {
        check_diagram(diagram_groups[[g]][[diag]]$diag,ret = F)
      }else
      {
        check_diagram(diagram_groups[[g]][[diag]],ret = F) 
      }
      
    }
  }
  
  # return diagram groups with reformatted diagrams
  return(diagram_groups)
  

}

check_param <- function(param_name,param,numeric = T,multiple = F,whole_numbers = F,finite = T,at_least_one = F,positive = F,non_negative = T,min_length = 1){
  
  # check if a single parameter satisfies certain constraints
  if(!is.list(param) & (!is.vector(param) | length(param) == 1))
  {
    if(is.null(param))
    {
      stop(paste0(param_name," must not be NULL."))
    }
    if(is.na(param))
    {
      stop(paste0(param_name," must not be NA/NaN."))
    }
  }
  
  if(param_name == "diagrams" | param_name == "other_diagrams" | param_name == "diagram_groups" | param_name == "new_diagrams")
  {
    if(!is.list(param) | length(param) < min_length)
    {
      stop(paste0(param_name," must be a list of persistence diagrams of length at least ",min_length,"."))
    }
    return()
  }
  
  if(multiple == F & length(param) > 1)
  {
    stop(paste0(param_name," must be a single value."))
  }
  
  if(param_name == "distance")
  {
    if(is.null(param) | length(param) > 1 | (param %in% c("wasserstein","fisher")) == F)
    {
      stop("distance must either be \'wasserstein\' or \'fisher\'.")
    }
    return()
  }
  
  if(numeric == T)
  {
    if(is.numeric(param) == F)
    {
      stop(paste0(param_name," must be numeric."))
    }
  }else
  {
    if(is.logical(param) == F)
    {
      stop(paste0(param_name," must be T or F."))
    }
    
    return()
  }
  
  if(numeric == T & whole_numbers == T & length(which(floor(param) != param)) > 0)
  {
    stop(paste0(param_name," must be whole numbers."))
  }
  
  if(finite == T & length(which(!is.finite(param))) > 0)
  {
    stop(paste0(param_name," must be finite."))
  }
  
  if(non_negative == T & length(which(param < 0)) > 0)
  {
    stop(paste0(param_name," must be non-negative"))
  }
  
  if(positive == T & length(which(param <= 0)) > 0)
  {
    stop(paste0(param_name," must be positive."))
  }
  
  if(at_least_one == T & length(which(param < 1)) > 0)
  {
    stop(paste0(param_name," must be at least one."))
  }
  
}

#### GENERATE TEST DATA FOR TDAML EXAMPLES ####
#' Creates persistence diagrams to test TDAML functions.
#'
#' An internal function which uses three example persistence diagrams,
#' each with points only in dimension 0, to create a list of diagrams for 
#' further analysis. The first diagram (D1) has one point with birth value
#' 2 and death value 3. The second diagram (D2) has two points, the first
#' has birth value 2 and death value 3.3, and the second has birth value
#' 0 and death value 0.5. The third diagram (D3) has one point with birth
#' value 0 and death value 0.5. The function either returns one of these
#' three diagrams, or a list of diagrams which were each generated by one
#' of D1, D2 and D3 but having Gaussian noise added to the birth and death
#' values for each point independently (with variance 0.05^2).
#' 
#' The `num_D1`, `num_D2` and `num_D3` parameters should be the number of desired copies
#' of D1, D2 and D3 respectively. If exactly one of these parameters is 1 and the others
#' are 0 then just return the noiseless diagram corresponding to that parameter.
#'
#' @param num_D1 the number of desired noisy copies of D1.
#' @param num_D2 the number of desired noisy copies of D2.
#' @param num_D3 the number of desired noisy copies of D3.
#' 
#' @return either a single diagram, or a list of `num_D1` copies of D1, 
#' `num_D2` copies of D2 and `num_D3` copies of D3
#' with independent Gaussian noise added to the birth and death values, 
#' each with variance 0.05^2.
#' @export
#' @keywords internal
#' @author Shael Brown - \email{shaelebrown@@gmail.com}
#' @examples
#' 
#' # generate just D1
#' D1 <- generate_TDAML_test_data(1,0,0)
#'
#' # create three copies of each of D1, D2 and D3
#' l <- generate_TDAML_test_data(3,3,3)

generate_TDAML_test_data <- function(num_D1,num_D2,num_D3){
  
  # error check parameters
  check_param("num_D1",num_D1,whole_numbers = T)
  check_param("num_D2",num_D2,whole_numbers = T)
  check_param("num_D3",num_D3,whole_numbers = T)
  
  # create data
  D1 = data.frame(dimension = c(0),birth = c(2),death = c(3))
  D2 = data.frame(dimension = c(0),birth = c(2,0),death = c(3.3,0.5))
  D3 = data.frame(dimension = c(0),birth = c(0),death = c(0.5))
  
  # handle special cases
  num_copies <- num_D1 + num_D2 + num_D3
  if(num_copies == 0)
  {
    return(list())
  }
  if(num_copies == 1)
  {
    if(num_D1 == 1)
    {
      return(D1)
    }
    if(num_D2 == 1)
    {
      return(D2)
    }
    if(num_D3 == 1)
    {
      return(D3)
    }
  }
  
  # otherwise make noisy copies
  noisy_copies <- lapply(X = 1:num_copies,FUN = function(X){
    
    i <- 1
    if(X > num_D1 & X <= num_D1 + num_D2)
    {
      i <- 2
    }
    if(X > num_D1 + num_D2)
    {
      i <- 3
    }
    noisy_copy <- get(paste0("D",i))
    n <- nrow(noisy_copy)
    noisy_copy$dimension <- as.numeric(as.character(noisy_copy$dimension))
    noisy_copy$birth <- noisy_copy$birth + stats::rnorm(n = n,mean = 0,sd = 0.05)
    noisy_copy[which(noisy_copy$birth < 0),2] <- 0
    noisy_copy$death <- noisy_copy$death + stats::rnorm(n = n,mean = 0,sd = 0.05)
    noisy_copy[which(noisy_copy$birth > noisy_copy$death),2] <- noisy_copy[which(noisy_copy$birth > noisy_copy$death),3]
    return(noisy_copy)
    
  })
  
  return(noisy_copies)
  
}
