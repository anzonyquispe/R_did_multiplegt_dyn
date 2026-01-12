#' @useDynLib DIDmultiplegtDYN, .registration = TRUE
#' @importFrom Rcpp sourceCpp
NULL

#' Propagate treatment change flag within groups (C++ optimized)
#'
#' Replaces the R loop that propagates ever_change_d_XX forward within groups
#' @param df data.table with ever_change_d_XX, group_XX, time_XX columns
#' @param T_XX Maximum time value
#' @return Modified data.table with propagated ever_change_d_XX
#' @noRd
propagate_ever_change_cpp_wrapper <- function(df, T_XX) {
  setorder(df, group_XX, time_XX)
  df[, ever_change_d_XX := propagate_treatment_change_cpp(
    as.numeric(ever_change_d_XX),
    as.integer(group_XX),
    as.integer(time_XX),
    as.integer(T_XX)
  )]
  return(df)
}

#' Compute variance-covariance matrix for effects (C++ optimized)
#'
#' Replaces nested R loops for variance-covariance computation
#' @param df data.table containing U_Gg_var columns
#' @param l_XX Number of effects
#' @param G_XX Number of groups
#' @param normalized Whether normalized estimates are used
#' @param delta_D_global Vector of delta_D values for normalization
#' @return Variance-covariance matrix
#' @noRd
compute_vcov_effects_cpp_wrapper <- function(df, l_XX, G_XX, normalized = FALSE, delta_D_global = NULL) {
  cols <- paste0("U_Gg_var_glob_", 1:l_XX, "_XX")
  U_Gg_mat <- as.matrix(df[, ..cols])
  first_obs <- as.integer(df$first_obs_by_gp_XX)

  vcov <- compute_var_covar_matrix_cpp(U_Gg_mat, first_obs, l_XX, G_XX)

  if (normalized && !is.null(delta_D_global)) {
    for (i in 1:l_XX) {
      vcov[i, ] <- vcov[i, ] / delta_D_global[i]
      vcov[, i] <- vcov[, i] / delta_D_global[i]
    }
  }

  return(vcov)
}

#' Compute clustered variance (C++ optimized)
#'
#' @param U_Gg_var Vector of U_Gg_var values
#' @param first_obs_gp first_obs_by_gp_XX indicator
#' @param first_obs_clust first_obs_by_clust_XX indicator
#' @param cluster Cluster variable
#' @param G_XX Number of groups
#' @return List with cluster sums and variance
#' @noRd
compute_clustered_var_wrapper <- function(U_Gg_var, first_obs_gp, first_obs_clust, cluster, G_XX) {
  result <- compute_clustered_variance_cpp(
    as.numeric(U_Gg_var),
    as.integer(first_obs_gp),
    as.integer(first_obs_clust),
    as.integer(cluster),
    as.numeric(G_XX)
  )
  return(result)
}

#' Compute weighted U_Gg global values (C++ optimized)
#'
#' @param U_Gg_plus U_Gg values for switchers in
#' @param U_Gg_minus U_Gg values for switchers out
#' @param N1 Weight for switchers in
#' @param N0 Weight for switchers out
#' @return Weighted combination vector
#' @noRd
compute_U_Gg_global_wrapper <- function(U_Gg_plus, U_Gg_minus, N1, N0) {
  compute_U_Gg_global_cpp(
    as.numeric(U_Gg_plus),
    as.numeric(U_Gg_minus),
    as.numeric(N1),
    as.numeric(N0)
  )
}
