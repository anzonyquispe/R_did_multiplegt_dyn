#' Comparison Test Script for DIDmultiplegtDYN Packages
#'
#' This script compares results from three versions:
#' 1. New polars version (DIDmultiplegtDYNpolars)
#' 2. Original data.table version (local)
#' 3. CRAN version (DIDmultiplegtDYN)
#'
#' Results are exported to Excel with argument specifications,
#' package name, version, and execution time.
#'
#' Run this script from the R_did_multiplegt_dyn_polars directory

# Clear environment
rm(list = ls())

# Install required packages if needed
if (!requireNamespace("writexl", quietly = TRUE)) {
  install.packages("writexl")
}
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

library(writexl)

# =============================================================================
# Configuration
# =============================================================================

# Set paths
polars_pkg_path <- "/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn_polars"
datatable_pkg_path <- "/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn"
output_path <- file.path(polars_pkg_path, "tests/comparison_results.xlsx")

# =============================================================================
# Define Test Cases (based on do files from testing_info)
# =============================================================================

test_cases <- list(
  # Test 1: Favara data - basic test
  list(
    name = "Favara Basic",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "favara_imbs_did_multiplegt_dyn.dta",
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 8,
      placebo = 3,
      cluster = "state_n"
    )
  ),

  # Test 2: Favara data - with trends_lin
  list(
    name = "Favara with trends_lin",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "favara_imbs_did_multiplegt_dyn.dta",
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 8,
      placebo = 3,
      cluster = "state_n",
      trends_lin = TRUE
    )
  ),

  # Test 3: Favara data - smaller effects for quick test
  list(
    name = "Favara Quick",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "favara_imbs_did_multiplegt_dyn.dta",
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 5,
      placebo = 2,
      cluster = "state_n"
    )
  ),

  # Test 4: Downup data - switchers in
  list(
    name = "Downup Switchers In",
    data_file = file.path(polars_pkg_path, "data/downup_data.csv"),
    data_source = "_data_replication.csv (downup)",
    args = list(
      outcome = "count",
      group = "unique_grid_id",
      time = "time",
      treatment = "downup_dummy",
      effects = 6,
      placebo = 6,
      controls = c("wind_direction", "wind_speed"),
      switchers = "in"
    )
  ),

  # Test 5: Bootstrap Favara - 1M observations - Basic (8 effects, 3 placebos)
  list(
    name = "Bootstrap 1M Basic",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "Bootstrap from favara_stata.csv (1M obs)",
    bootstrap = TRUE,
    bootstrap_target_rows = 1000000,
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 8,
      placebo = 3,
      cluster = "state_n"
    )
  ),

  # Test 6: Bootstrap Favara - 1M observations - with trends_lin
  list(
    name = "Bootstrap 1M trends_lin",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "Bootstrap from favara_stata.csv (1M obs)",
    bootstrap = TRUE,
    bootstrap_target_rows = 1000000,
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 8,
      placebo = 3,
      cluster = "state_n",
      trends_lin = TRUE
    )
  ),

  # Test 7: Bootstrap Favara - 1M observations - Quick (5 effects, 2 placebos)
  list(
    name = "Bootstrap 1M Quick",
    data_file = file.path(polars_pkg_path, "data/favara_stata.csv"),
    data_source = "Bootstrap from favara_stata.csv (1M obs)",
    bootstrap = TRUE,
    bootstrap_target_rows = 1000000,
    args = list(
      outcome = "Dl_vloans_b",
      group = "county",
      time = "year",
      treatment = "inter_bra",
      effects = 5,
      placebo = 2,
      cluster = "state_n"
    )
  )
)

# =============================================================================
# Helper Functions
# =============================================================================

#' Format arguments as string for display
format_args <- function(args) {
  arg_strings <- sapply(names(args), function(n) {
    val <- args[[n]]
    if (is.character(val)) {
      if (length(val) > 1) {
        sprintf('%s = c("%s")', n, paste(val, collapse = '", "'))
      } else {
        sprintf('%s = "%s"', n, val)
      }
    } else if (is.logical(val)) {
      sprintf('%s = %s', n, toupper(as.character(val)))
    } else if (is.null(val)) {
      sprintf('%s = NULL', n)
    } else {
      sprintf('%s = %s', n, paste(val, collapse = ", "))
    }
  })
  paste(arg_strings, collapse = ", ")
}

#' Run estimation with a package
run_estimation <- function(pkg_name, did_func, df, args) {
  cat(sprintf("  Running %s...\n", pkg_name))

  tryCatch({
    start_time <- Sys.time()

    # Build the call
    call_args <- c(list(df = df), args)
    result <- do.call(did_func, call_args)

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat(sprintf("    Completed in %.2f seconds\n", elapsed))

    return(list(
      success = TRUE,
      result = result,
      time = elapsed,
      error = NULL
    ))

  }, error = function(e) {
    cat(sprintf("    ERROR: %s\n", e$message))
    return(list(
      success = FALSE,
      result = NULL,
      time = NA,
      error = e$message
    ))
  })
}

#' Extract key results for comparison
extract_results <- function(result) {
  if (is.null(result) || !result$success) {
    return(NULL)
  }

  res <- result$result

  effects <- if (!is.null(res$Effects)) as.numeric(res$Effects[, 1]) else NULL
  effects_se <- if (!is.null(res$Effects) && ncol(res$Effects) >= 2) as.numeric(res$Effects[, 2]) else NULL
  placebos <- if (!is.null(res$Placebos)) as.numeric(res$Placebos[, 1]) else NULL
  placebos_se <- if (!is.null(res$Placebos) && ncol(res$Placebos) >= 2) as.numeric(res$Placebos[, 2]) else NULL
  ate <- if (!is.null(res$ATE)) as.numeric(res$ATE[1]) else NULL
  ate_se <- if (!is.null(res$ATE) && length(res$ATE) >= 2) as.numeric(res$ATE[2]) else NULL

  return(list(
    effects = effects,
    effects_se = effects_se,
    placebos = placebos,
    placebos_se = placebos_se,
    ate = ate,
    ate_se = ate_se
  ))
}

#' Get package version
get_pkg_version <- function(pkg_name) {
  tryCatch({
    as.character(packageVersion(pkg_name))
  }, error = function(e) {
    "unknown"
  })
}

# =============================================================================
# Main Execution
# =============================================================================

cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("DIDmultiplegtDYN Package Comparison Test\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat(sprintf("Timestamp: %s\n\n", Sys.time()))

# Storage for all results
all_results <- list()

# Run each test case
for (tc_idx in seq_along(test_cases)) {
  tc <- test_cases[[tc_idx]]

  cat("\n", "-" |> rep(60) |> paste(collapse = ""), "\n")
  cat(sprintf("TEST CASE %d: %s\n", tc_idx, tc$name))
  cat("-" |> rep(60) |> paste(collapse = ""), "\n")

  # Check if data file exists
  if (!file.exists(tc$data_file)) {
    cat(sprintf("  SKIPPED: Data file not found: %s\n", tc$data_file))
    next
  }

  # Load test data
  cat(sprintf("  Loading data: %s\n", basename(tc$data_file)))
  test_data <- read.csv(tc$data_file)
  cat(sprintf("  Data loaded: %d rows, %d columns\n", nrow(test_data), ncol(test_data)))

  # Bootstrap data if requested
  if (isTRUE(tc$bootstrap) && !is.null(tc$bootstrap_target_rows)) {
    cat(sprintf("  Bootstrapping to %d observations...\n", tc$bootstrap_target_rows))
    set.seed(42)  # For reproducibility

    # Get unique groups (counties)
    original_groups <- unique(test_data[[tc$args$group]])
    n_original_groups <- length(original_groups)

    # Calculate how many times to replicate
    rows_per_group <- nrow(test_data) / n_original_groups
    target_groups <- ceiling(tc$bootstrap_target_rows / rows_per_group)

    # Bootstrap by resampling groups with replacement and creating new group IDs
    bootstrap_list <- list()
    new_group_id <- 0

    for (i in 1:target_groups) {
      # Sample a random original group
      sampled_group <- sample(original_groups, 1)

      # Get data for this group
      group_data <- test_data[test_data[[tc$args$group]] == sampled_group, ]

      # Assign new unique group ID
      new_group_id <- new_group_id + 1
      group_data[[tc$args$group]] <- new_group_id

      # Also update cluster if it exists (to maintain cluster structure)
      if (!is.null(tc$args$cluster) && tc$args$cluster %in% names(group_data)) {
        # Get original cluster for this group
        orig_cluster <- unique(test_data[test_data[[tc$args$group]] == sampled_group, tc$args$cluster])[1]
        # Map to new cluster (based on sampling iteration to maintain some clustering)
        group_data[[tc$args$cluster]] <- ((i - 1) %% 50) + 1  # Create ~50 clusters
      }

      bootstrap_list[[i]] <- group_data
    }

    test_data <- do.call(rbind, bootstrap_list)
    cat(sprintf("  Bootstrap complete: %d rows, %d groups\n", nrow(test_data), new_group_id))
  }

  # Format arguments for display
  args_str <- format_args(tc$args)
  cat(sprintf("  Arguments: %s\n\n", args_str))

  # Initialize result storage for this test case
  tc_results <- list(
    test_name = tc$name,
    data_source = tc$data_source,
    data_rows = nrow(test_data),
    data_cols = ncol(test_data),
    args_string = args_str,
    args = tc$args
  )

  # ----- Test CRAN version -----
  cran_result <- NULL
  cran_version <- NA
  if (requireNamespace("DIDmultiplegtDYN", quietly = TRUE)) {
    cran_version <- get_pkg_version("DIDmultiplegtDYN")
    cran_result <- run_estimation(
      sprintf("CRAN DIDmultiplegtDYN v%s", cran_version),
      DIDmultiplegtDYN::did_multiplegt_dyn,
      test_data,
      tc$args
    )
  } else {
    cat("  CRAN package not installed\n")
  }
  tc_results$cran_version <- cran_version
  tc_results$cran_time <- if (!is.null(cran_result)) cran_result$time else NA
  tc_results$cran_success <- if (!is.null(cran_result)) cran_result$success else FALSE
  tc_results$cran_error <- if (!is.null(cran_result)) cran_result$error else "Not installed"
  tc_results$cran_extracted <- extract_results(cran_result)

  # ----- Test data.table version -----
  datatable_result <- NULL
  datatable_version <- NA
  tryCatch({
    devtools::load_all(datatable_pkg_path, quiet = TRUE)
    datatable_version <- get_pkg_version("DIDmultiplegtDYN")
    datatable_result <- run_estimation(
      sprintf("Local data.table v%s", datatable_version),
      did_multiplegt_dyn,
      test_data,
      tc$args
    )
    detach("package:DIDmultiplegtDYN", unload = TRUE, character.only = TRUE)
  }, error = function(e) {
    cat(sprintf("  data.table version error: %s\n", e$message))
  })
  tc_results$datatable_version <- datatable_version
  tc_results$datatable_time <- if (!is.null(datatable_result)) datatable_result$time else NA
  tc_results$datatable_success <- if (!is.null(datatable_result)) datatable_result$success else FALSE
  tc_results$datatable_error <- if (!is.null(datatable_result)) datatable_result$error else "Failed to load"
  tc_results$datatable_extracted <- extract_results(datatable_result)

  # ----- Test polars version -----
  polars_result <- NULL
  polars_version <- NA
  tryCatch({
    devtools::load_all(polars_pkg_path, quiet = TRUE)
    polars_version <- get_pkg_version("DIDmultiplegtDYNpolars")
    polars_result <- run_estimation(
      sprintf("Polars v%s", polars_version),
      did_multiplegt_dyn,
      test_data,
      tc$args
    )
  }, error = function(e) {
    cat(sprintf("  polars version error: %s\n", e$message))
  })
  tc_results$polars_version <- polars_version
  tc_results$polars_time <- if (!is.null(polars_result)) polars_result$time else NA
  tc_results$polars_success <- if (!is.null(polars_result)) polars_result$success else FALSE
  tc_results$polars_error <- if (!is.null(polars_result)) polars_result$error else "Failed to load"
  tc_results$polars_extracted <- extract_results(polars_result)

  all_results[[tc_idx]] <- tc_results
}

# =============================================================================
# Build Excel Output
# =============================================================================

cat("\n\n", "=" |> rep(70) |> paste(collapse = ""), "\n")
cat("Building Excel Output\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n")

# Sheet 1: Summary
summary_df <- data.frame(
  Test_Case = character(),
  Data_Source = character(),
  Data_Rows = integer(),
  Arguments = character(),
  CRAN_Version = character(),
  CRAN_Time_Sec = numeric(),
  CRAN_Status = character(),
  DataTable_Version = character(),
  DataTable_Time_Sec = numeric(),
  DataTable_Status = character(),
  Polars_Version = character(),
  Polars_Time_Sec = numeric(),
  Polars_Status = character(),
  stringsAsFactors = FALSE
)

for (res in all_results) {
  if (is.null(res)) next
  summary_df <- rbind(summary_df, data.frame(
    Test_Case = res$test_name,
    Data_Source = res$data_source,
    Data_Rows = res$data_rows,
    Arguments = res$args_string,
    CRAN_Version = as.character(res$cran_version),
    CRAN_Time_Sec = res$cran_time,
    CRAN_Status = ifelse(res$cran_success, "SUCCESS", ifelse(is.na(res$cran_time), "NOT RUN", "FAILED")),
    DataTable_Version = as.character(res$datatable_version),
    DataTable_Time_Sec = res$datatable_time,
    DataTable_Status = ifelse(res$datatable_success, "SUCCESS", ifelse(is.na(res$datatable_time), "NOT RUN", "FAILED")),
    Polars_Version = as.character(res$polars_version),
    Polars_Time_Sec = res$polars_time,
    Polars_Status = ifelse(res$polars_success, "SUCCESS", ifelse(is.na(res$polars_time), "NOT RUN", "FAILED")),
    stringsAsFactors = FALSE
  ))
}

# Sheet 2: Effects Comparison
effects_df <- data.frame(
  Test_Case = character(),
  Effect_Number = integer(),
  CRAN_Estimate = numeric(),
  CRAN_SE = numeric(),
  DataTable_Estimate = numeric(),
  DataTable_SE = numeric(),
  Polars_Estimate = numeric(),
  Polars_SE = numeric(),
  Diff_CRAN_Polars = numeric(),
  stringsAsFactors = FALSE
)

for (res in all_results) {
  if (is.null(res)) next

  max_effects <- max(
    length(res$cran_extracted$effects %||% numeric(0)),
    length(res$datatable_extracted$effects %||% numeric(0)),
    length(res$polars_extracted$effects %||% numeric(0))
  )

  if (max_effects > 0) {
    for (i in 1:max_effects) {
      cran_est <- if (!is.null(res$cran_extracted$effects) && i <= length(res$cran_extracted$effects)) res$cran_extracted$effects[i] else NA
      cran_se <- if (!is.null(res$cran_extracted$effects_se) && i <= length(res$cran_extracted$effects_se)) res$cran_extracted$effects_se[i] else NA
      dt_est <- if (!is.null(res$datatable_extracted$effects) && i <= length(res$datatable_extracted$effects)) res$datatable_extracted$effects[i] else NA
      dt_se <- if (!is.null(res$datatable_extracted$effects_se) && i <= length(res$datatable_extracted$effects_se)) res$datatable_extracted$effects_se[i] else NA
      pol_est <- if (!is.null(res$polars_extracted$effects) && i <= length(res$polars_extracted$effects)) res$polars_extracted$effects[i] else NA
      pol_se <- if (!is.null(res$polars_extracted$effects_se) && i <= length(res$polars_extracted$effects_se)) res$polars_extracted$effects_se[i] else NA

      effects_df <- rbind(effects_df, data.frame(
        Test_Case = res$test_name,
        Effect_Number = i,
        CRAN_Estimate = cran_est,
        CRAN_SE = cran_se,
        DataTable_Estimate = dt_est,
        DataTable_SE = dt_se,
        Polars_Estimate = pol_est,
        Polars_SE = pol_se,
        Diff_CRAN_Polars = if (!is.na(cran_est) && !is.na(pol_est)) abs(cran_est - pol_est) else NA,
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Sheet 3: Placebos Comparison
placebos_df <- data.frame(
  Test_Case = character(),
  Placebo_Number = integer(),
  CRAN_Estimate = numeric(),
  CRAN_SE = numeric(),
  DataTable_Estimate = numeric(),
  DataTable_SE = numeric(),
  Polars_Estimate = numeric(),
  Polars_SE = numeric(),
  Diff_CRAN_Polars = numeric(),
  stringsAsFactors = FALSE
)

for (res in all_results) {
  if (is.null(res)) next

  max_placebos <- max(
    length(res$cran_extracted$placebos %||% numeric(0)),
    length(res$datatable_extracted$placebos %||% numeric(0)),
    length(res$polars_extracted$placebos %||% numeric(0))
  )

  if (max_placebos > 0) {
    for (i in 1:max_placebos) {
      cran_est <- if (!is.null(res$cran_extracted$placebos) && i <= length(res$cran_extracted$placebos)) res$cran_extracted$placebos[i] else NA
      cran_se <- if (!is.null(res$cran_extracted$placebos_se) && i <= length(res$cran_extracted$placebos_se)) res$cran_extracted$placebos_se[i] else NA
      dt_est <- if (!is.null(res$datatable_extracted$placebos) && i <= length(res$datatable_extracted$placebos)) res$datatable_extracted$placebos[i] else NA
      dt_se <- if (!is.null(res$datatable_extracted$placebos_se) && i <= length(res$datatable_extracted$placebos_se)) res$datatable_extracted$placebos_se[i] else NA
      pol_est <- if (!is.null(res$polars_extracted$placebos) && i <= length(res$polars_extracted$placebos)) res$polars_extracted$placebos[i] else NA
      pol_se <- if (!is.null(res$polars_extracted$placebos_se) && i <= length(res$polars_extracted$placebos_se)) res$polars_extracted$placebos_se[i] else NA

      placebos_df <- rbind(placebos_df, data.frame(
        Test_Case = res$test_name,
        Placebo_Number = i,
        CRAN_Estimate = cran_est,
        CRAN_SE = cran_se,
        DataTable_Estimate = dt_est,
        DataTable_SE = dt_se,
        Polars_Estimate = pol_est,
        Polars_SE = pol_se,
        Diff_CRAN_Polars = if (!is.na(cran_est) && !is.na(pol_est)) abs(cran_est - pol_est) else NA,
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Sheet 4: ATE Comparison
ate_df <- data.frame(
  Test_Case = character(),
  CRAN_ATE = numeric(),
  CRAN_ATE_SE = numeric(),
  DataTable_ATE = numeric(),
  DataTable_ATE_SE = numeric(),
  Polars_ATE = numeric(),
  Polars_ATE_SE = numeric(),
  Diff_CRAN_Polars = numeric(),
  stringsAsFactors = FALSE
)

for (res in all_results) {
  if (is.null(res)) next

  cran_ate <- res$cran_extracted$ate
  cran_ate_se <- res$cran_extracted$ate_se
  dt_ate <- res$datatable_extracted$ate
  dt_ate_se <- res$datatable_extracted$ate_se
  pol_ate <- res$polars_extracted$ate
  pol_ate_se <- res$polars_extracted$ate_se

  ate_df <- rbind(ate_df, data.frame(
    Test_Case = res$test_name,
    CRAN_ATE = if (!is.null(cran_ate)) cran_ate else NA,
    CRAN_ATE_SE = if (!is.null(cran_ate_se)) cran_ate_se else NA,
    DataTable_ATE = if (!is.null(dt_ate)) dt_ate else NA,
    DataTable_ATE_SE = if (!is.null(dt_ate_se)) dt_ate_se else NA,
    Polars_ATE = if (!is.null(pol_ate)) pol_ate else NA,
    Polars_ATE_SE = if (!is.null(pol_ate_se)) pol_ate_se else NA,
    Diff_CRAN_Polars = if (!is.null(cran_ate) && !is.null(pol_ate)) abs(cran_ate - pol_ate) else NA,
    stringsAsFactors = FALSE
  ))
}

# Sheet 5: Test Configuration Details
config_df <- data.frame(
  Test_Case = character(),
  Parameter = character(),
  Value = character(),
  stringsAsFactors = FALSE
)

for (res in all_results) {
  if (is.null(res)) next

  for (param_name in names(res$args)) {
    param_val <- res$args[[param_name]]
    if (is.null(param_val)) {
      val_str <- "NULL"
    } else if (is.character(param_val)) {
      val_str <- paste(param_val, collapse = ", ")
    } else if (is.logical(param_val)) {
      val_str <- as.character(param_val)
    } else {
      val_str <- paste(param_val, collapse = ", ")
    }

    config_df <- rbind(config_df, data.frame(
      Test_Case = res$test_name,
      Parameter = param_name,
      Value = val_str,
      stringsAsFactors = FALSE
    ))
  }
}

# Sheet 6: Run Info
run_info_df <- data.frame(
  Field = c("Run Timestamp", "R Version", "Platform", "Output File"),
  Value = c(
    as.character(Sys.time()),
    R.version.string,
    R.version$platform,
    output_path
  ),
  stringsAsFactors = FALSE
)

# Write to Excel
sheets <- list(
  "Summary" = summary_df,
  "Effects" = effects_df,
  "Placebos" = placebos_df,
  "ATE" = ate_df,
  "Test_Config" = config_df,
  "Run_Info" = run_info_df
)

write_xlsx(sheets, output_path)
cat(sprintf("\nResults saved to: %s\n", output_path))

# =============================================================================
# Print Final Summary
# =============================================================================

cat("\n", "=" |> rep(70) |> paste(collapse = ""), "\n")
cat("FINAL SUMMARY\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n\n")

print(summary_df[, c("Test_Case", "CRAN_Time_Sec", "DataTable_Time_Sec", "Polars_Time_Sec",
                     "CRAN_Status", "DataTable_Status", "Polars_Status")])

cat("\n\nTest completed.\n")
cat(sprintf("Excel output: %s\n", output_path))
