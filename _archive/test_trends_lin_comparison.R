# Test script comparing Polars-optimized package with CRAN version
# Using favara_imbs data with trends_lin option

library(openxlsx)

# Set working directory
setwd("/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn_polars")

# Load the favara_imbs data
load("data/favara_imbs.RData")

cat("\n========== FAVARA-IMBS DATA SUMMARY ==========\n")
cat("Dimensions:", dim(favara_imbs), "\n")
cat("Columns:", paste(names(favara_imbs), collapse = ", "), "\n")
cat("Time range:", range(favara_imbs$year), "\n")
cat("Unique states:", length(unique(favara_imbs$state)), "\n")
cat("Unique counties:", length(unique(favara_imbs$county)), "\n\n")

# ============ RUN CRAN PACKAGE ============
cat("========== RUNNING CRAN PACKAGE (DIDmultiplegtDYN) ==========\n")
library(DIDmultiplegtDYN)

start_cran <- Sys.time()
result_cran <- tryCatch({
  did_multiplegt_dyn(
    df = favara_imbs,
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 2,
    trends_lin = TRUE,
    graph_off = TRUE,
    cluster = "state_n"
  )
}, error = function(e) {
  cat("CRAN package error:", e$message, "\n")
  NULL
})
end_cran <- Sys.time()
time_cran <- as.numeric(difftime(end_cran, start_cran, units = "secs"))

cat("CRAN package execution time:", round(time_cran, 2), "seconds\n\n")

# Unload CRAN package
detach("package:DIDmultiplegtDYN", unload = TRUE)

# ============ RUN POLARS-OPTIMIZED PACKAGE ============
cat("========== RUNNING POLARS-OPTIMIZED PACKAGE ==========\n")

# Load required libraries for polars package
library(polars)
library(fixest)
library(MASS)
library(data.table)  # For fifelse and other data.table utilities
library(ggplot2)     # For plotting
library(cowplot)     # For theme_minimal_grid

# Source all R files from the optimized package
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) {
  source(f)
}

start_polars <- Sys.time()
result_polars <- tryCatch({
  did_multiplegt_dyn(
    df = favara_imbs,
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 2,
    trends_lin = TRUE,
    graph_off = TRUE,
    cluster = "state_n"
  )
}, error = function(e) {
  cat("Polars package error:", e$message, "\n")
  print(traceback())
  NULL
})
end_polars <- Sys.time()
time_polars <- as.numeric(difftime(end_polars, start_polars, units = "secs"))

cat("Polars package execution time:", round(time_polars, 2), "seconds\n\n")

# ============ COMPARE RESULTS ============
cat("========== COMPARISON RESULTS ==========\n\n")

# Function to extract estimates from result structure
extract_estimates <- function(result, pkg_name) {
  if (is.null(result)) {
    return(NULL)
  }

  # The estimates are stored in result$results$Effects and result$results$Placebos
  effects <- result$results$Effects
  placebos <- result$results$Placebos

  result_df <- data.frame()

  if (!is.null(effects)) {
    effects_df <- data.frame(
      Package = pkg_name,
      Effect = rownames(effects),
      Estimate = as.numeric(effects[, "Estimate"]),
      StdError = as.numeric(effects[, "SE"]),
      CI_Lower = as.numeric(effects[, "LB CI"]),
      CI_Upper = as.numeric(effects[, "UB CI"]),
      N = as.numeric(effects[, "N"]),
      Switchers = as.numeric(effects[, "Switchers"])
    )
    result_df <- rbind(result_df, effects_df)
  }

  if (!is.null(placebos)) {
    placebos_df <- data.frame(
      Package = pkg_name,
      Effect = rownames(placebos),
      Estimate = as.numeric(placebos[, "Estimate"]),
      StdError = as.numeric(placebos[, "SE"]),
      CI_Lower = as.numeric(placebos[, "LB CI"]),
      CI_Upper = as.numeric(placebos[, "UB CI"]),
      N = as.numeric(placebos[, "N"]),
      Switchers = as.numeric(placebos[, "Switchers"])
    )
    result_df <- rbind(result_df, placebos_df)
  }

  if (nrow(result_df) > 0) {
    return(result_df)
  }
  return(NULL)
}

# Extract results
df_cran <- extract_estimates(result_cran, "CRAN")
df_polars <- extract_estimates(result_polars, "Polars")

# Print results
cat("CRAN Package Results:\n")
if (!is.null(result_cran)) {
  cat("Result structure: ", names(result_cran), "\n")
  if (!is.null(result_cran$estimates)) {
    print(result_cran$estimates)
  } else {
    # Try printing the result directly
    print(result_cran)
  }
} else {
  cat("No results available (NULL)\n")
}

cat("\n\nPolars-Optimized Package Results:\n")
if (!is.null(result_polars)) {
  cat("Result structure: ", names(result_polars), "\n")
  if (!is.null(result_polars$estimates)) {
    print(result_polars$estimates)
  } else {
    # Try printing the result directly
    print(result_polars)
  }
} else {
  cat("No results available (NULL)\n")
}

# ============ CREATE COMPARISON SUMMARY ============
comparison_summary <- data.frame(
  Metric = c("Execution Time (seconds)", "Speedup Factor"),
  CRAN = c(round(time_cran, 2), 1.0),
  Polars = c(round(time_polars, 2), round(time_cran / time_polars, 2))
)

cat("\n\n========== PERFORMANCE COMPARISON ==========\n")
print(comparison_summary)

# ============ SAVE TO EXCEL ============
output_file <- "data/trends_lin_test_results.xlsx"

wb <- createWorkbook()

addWorksheet(wb, "CRAN_Results")
if (!is.null(df_cran)) {
  writeData(wb, "CRAN_Results", df_cran)
}

addWorksheet(wb, "Polars_Results")
if (!is.null(df_polars)) {
  writeData(wb, "Polars_Results", df_polars)
}

addWorksheet(wb, "Performance")
writeData(wb, "Performance", comparison_summary)

# Add comparison if both extracted data frames exist
if (!is.null(df_cran) && !is.null(df_polars)) {
  # Combine results
  combined <- rbind(df_cran, df_polars)
  addWorksheet(wb, "Combined_Estimates")
  writeData(wb, "Combined_Estimates", combined)

  # Calculate differences by merging on Effect
  merged <- merge(
    df_cran[, c("Effect", "Estimate", "StdError")],
    df_polars[, c("Effect", "Estimate", "StdError")],
    by = "Effect",
    suffixes = c("_CRAN", "_Polars")
  )
  merged$Difference <- merged$Estimate_Polars - merged$Estimate_CRAN
  merged$AbsDiff <- abs(merged$Difference)
  merged$SE_Diff <- merged$StdError_Polars - merged$StdError_CRAN

  addWorksheet(wb, "Estimate_Differences")
  writeData(wb, "Estimate_Differences", merged)

  cat("\n\n========== ESTIMATE DIFFERENCES (CRAN vs Polars) ==========\n")
  print(merged)

  # Summary of match
  cat("\n========== MATCH SUMMARY ==========\n")
  cat("Max absolute difference in estimates:", max(merged$AbsDiff), "\n")
  cat("Max absolute difference in SE:", max(abs(merged$SE_Diff)), "\n")
  if (max(merged$AbsDiff) < 1e-6 && max(abs(merged$SE_Diff)) < 1e-6) {
    cat("RESULT: Polars package produces IDENTICAL results!\n")
  } else if (max(merged$AbsDiff) < 1e-3) {
    cat("RESULT: Polars package produces NEARLY IDENTICAL results (within 0.001).\n")
  } else {
    cat("RESULT: There are small differences between packages.\n")
  }
}

saveWorkbook(wb, output_file, overwrite = TRUE)
cat("\n\nResults saved to:", output_file, "\n")

cat("\n========== TEST COMPLETE ==========\n")
