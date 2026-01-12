#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector cummax_by_group_cpp(IntegerVector x, IntegerVector group) {
  // Cumulative maximum within groups (for ever_change_d_XX propagation)
  // Equivalent to: df[, ever_change_d_XX := cummax(ever_change_d_XX), by = group_XX]
  int n = x.size();
  IntegerVector result(n);

  if (n == 0) return result;

  int current_group = group[0];
  int current_max = x[0];
  result[0] = current_max;

  for (int i = 1; i < n; i++) {
    if (group[i] != current_group) {
      current_group = group[i];
      current_max = x[i];
    } else {
      if (x[i] > current_max) {
        current_max = x[i];
      }
    }
    result[i] = current_max;
  }

  return result;
}

// [[Rcpp::export]]
NumericMatrix compute_var_covar_matrix_cpp(NumericMatrix U_Gg_vars,
                                            IntegerVector first_obs,
                                            int l_XX,
                                            double G_XX) {
  // Compute variance-covariance matrix for effects
  // U_Gg_vars: matrix where each column is U_Gg_var_glob_i_XX for i in 1:l_XX
  // first_obs: first_obs_by_gp_XX indicator
  // Returns l_XX x l_XX variance-covariance matrix

  int n = U_Gg_vars.nrow();
  NumericMatrix vcov(l_XX, l_XX);
  double G_XX_sq = G_XX * G_XX;

  // Compute variances (diagonal)
  for (int i = 0; i < l_XX; i++) {
    double sum_sq = 0.0;
    for (int j = 0; j < n; j++) {
      if (first_obs[j] == 1) {
        double val = U_Gg_vars(j, i);
        if (!NumericVector::is_na(val)) {
          sum_sq += val * val;
        }
      }
    }
    vcov(i, i) = sum_sq / G_XX_sq;
  }

  // Compute covariances (off-diagonal)
  for (int i = 0; i < l_XX - 1; i++) {
    for (int k = i + 1; k < l_XX; k++) {
      double sum_combined_sq = 0.0;
      for (int j = 0; j < n; j++) {
        if (first_obs[j] == 1) {
          double val_i = U_Gg_vars(j, i);
          double val_k = U_Gg_vars(j, k);
          if (!NumericVector::is_na(val_i) && !NumericVector::is_na(val_k)) {
            double combined = val_i + val_k;
            sum_combined_sq += combined * combined;
          }
        }
      }
      double var_sum = sum_combined_sq / G_XX_sq;
      double cov = (var_sum - vcov(i, i) - vcov(k, k)) / 2.0;
      vcov(i, k) = cov;
      vcov(k, i) = cov;
    }
  }

  return vcov;
}

// [[Rcpp::export]]
NumericVector compute_U_Gg_global_cpp(NumericVector U_Gg_plus,
                                       NumericVector U_Gg_minus,
                                       double N1_weight,
                                       double N0_weight) {
  // Compute weighted combination of U_Gg for switchers in and out
  int n = U_Gg_plus.size();
  NumericVector result(n);

  double total = N1_weight + N0_weight;
  if (total == 0) {
    std::fill(result.begin(), result.end(), NA_REAL);
    return result;
  }

  double w_plus = N1_weight / total;
  double w_minus = N0_weight / total;

  for (int i = 0; i < n; i++) {
    result[i] = w_plus * U_Gg_plus[i] + w_minus * U_Gg_minus[i];
  }

  return result;
}

// [[Rcpp::export]]
List compute_clustered_variance_cpp(NumericVector U_Gg_var,
                                     IntegerVector first_obs_gp,
                                     IntegerVector first_obs_clust,
                                     IntegerVector cluster,
                                     double G_XX) {
  // Compute clustered variance
  int n = U_Gg_var.size();

  // Step 1: Multiply by first_obs_by_gp_XX
  NumericVector U_masked(n);
  for (int i = 0; i < n; i++) {
    U_masked[i] = U_Gg_var[i] * first_obs_gp[i];
  }

  // Step 2: Sum within clusters
  std::map<int, double> cluster_sums;
  for (int i = 0; i < n; i++) {
    if (!IntegerVector::is_na(cluster[i])) {
      if (!NumericVector::is_na(U_masked[i])) {
        cluster_sums[cluster[i]] += U_masked[i];
      }
    }
  }

  // Step 3: Assign cluster sums back and compute squared sums
  NumericVector clust_sum(n);
  double sum_sq = 0.0;

  for (int i = 0; i < n; i++) {
    if (!IntegerVector::is_na(cluster[i])) {
      clust_sum[i] = cluster_sums[cluster[i]];
      if (first_obs_clust[i] == 1) {
        sum_sq += clust_sum[i] * clust_sum[i];
      }
    }
  }

  double sum_for_var = sum_sq / (G_XX * G_XX);

  return List::create(
    Named("clust_sum") = clust_sum,
    Named("sum_for_var") = sum_for_var
  );
}

// [[Rcpp::export]]
NumericVector propagate_treatment_change_cpp(NumericVector ever_change,
                                              IntegerVector group,
                                              IntegerVector time,
                                              int T_max) {
  // Propagate ever_change_d_XX forward within groups
  // This replaces the loop: for (i in 2:T_XX) { ... }

  int n = ever_change.size();
  NumericVector result = clone(ever_change);

  for (int i = 1; i < n; i++) {
    if (group[i] == group[i-1] && result[i-1] == 1 && time[i] > 1) {
      result[i] = 1;
    }
  }

  return result;
}

// [[Rcpp::export]]
NumericMatrix initialize_effect_columns_cpp(int nrow, int l_XX, bool include_placebo) {
  // Pre-allocate matrix for effect columns
  // Each column represents: U_Gg{i}_plus_XX, U_Gg{i}_minus_XX, count{i}_plus_XX, etc.
  int ncols = l_XX * 8;  // 8 columns per effect
  if (include_placebo) {
    ncols *= 2;  // Double for placebos
  }

  NumericMatrix result(nrow, ncols);
  std::fill(result.begin(), result.end(), 0.0);

  return result;
}

// [[Rcpp::export]]
double compute_weighted_sum_cpp(NumericVector x, IntegerVector mask) {
  // Compute sum of x where mask == 1, handling NAs
  double result = 0.0;
  int n = x.size();

  for (int i = 0; i < n; i++) {
    if (mask[i] == 1 && !NumericVector::is_na(x[i])) {
      result += x[i];
    }
  }

  return result;
}

// [[Rcpp::export]]
NumericVector compute_delta_D_g_cpp(NumericMatrix delta_plus,
                                     NumericMatrix delta_minus,
                                     IntegerVector switchers_tag,
                                     int l_XX) {
  // Compute delta_D_g_XX by combining plus and minus matrices
  int n = delta_plus.nrow();
  NumericVector result(n, 0.0);

  for (int i = 0; i < n; i++) {
    int tag = switchers_tag[i];
    if (!IntegerVector::is_na(tag) && tag >= 1 && tag <= l_XX) {
      int col = tag - 1;  // 0-indexed
      double val_plus = delta_plus(i, col);
      double val_minus = delta_minus(i, col);

      double val = (val_plus != 0) ? val_plus : val_minus;
      if (val != 0) {
        result[i] = val;
      }
    }
  }

  return result;
}

// [[Rcpp::export]]
List compute_full_vcov_cpp(NumericMatrix U_Gg_vars_effects,
                           NumericMatrix U_Gg_vars_placebos,
                           IntegerVector first_obs,
                           NumericVector se_effects,
                           NumericVector se_placebos,
                           double G_XX) {
  // Compute full variance-covariance matrix for effects and placebos
  int l_XX = U_Gg_vars_effects.ncol();
  int l_placebo_XX = U_Gg_vars_placebos.ncol();
  int l_tot = l_XX + l_placebo_XX;
  int n = U_Gg_vars_effects.nrow();

  NumericMatrix vcov(l_tot, l_tot);
  double G_XX_sq = G_XX * G_XX;

  // Fill diagonal with squared SEs
  for (int i = 0; i < l_XX; i++) {
    vcov(i, i) = se_effects[i] * se_effects[i];
  }
  for (int i = 0; i < l_placebo_XX; i++) {
    vcov(l_XX + i, l_XX + i) = se_placebos[i] * se_placebos[i];
  }

  // Compute covariances
  for (int i = 0; i < l_tot; i++) {
    for (int j = i + 1; j < l_tot; j++) {
      double sum_sq = 0.0;

      for (int k = 0; k < n; k++) {
        if (first_obs[k] == 1) {
          double val_i = (i < l_XX) ? U_Gg_vars_effects(k, i) :
                                       U_Gg_vars_placebos(k, i - l_XX);
          double val_j = (j < l_XX) ? U_Gg_vars_effects(k, j) :
                                       U_Gg_vars_placebos(k, j - l_XX);

          if (!NumericVector::is_na(val_i) && !NumericVector::is_na(val_j)) {
            double combined = val_i + val_j;
            sum_sq += combined * combined;
          }
        }
      }

      double var_temp = sum_sq / G_XX_sq;
      double cov = (var_temp - vcov(i, i) - vcov(j, j)) / 2.0;
      vcov(i, j) = cov;
      vcov(j, i) = cov;
    }
  }

  return List::create(Named("vcov") = vcov);
}
