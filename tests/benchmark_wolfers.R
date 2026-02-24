# Comprehensive Benchmark: did_multiplegt_dyn
# Comparing R-CRAN, R-Polars packages
# Dataset: wolfers2006_didtextbook.dta
# Specification: did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)

library(haven)
library(DIDmultiplegtDYN)
library(DIDmultiplegtDYNpolars)

# Set timeout (1 hour in seconds)
TIMEOUT_SECONDS <- 3600

# Helper function for separator
sep_line <- function() paste(rep("=", 60), collapse = "")

# Output file for logging
log_file <- "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_wolfers.log"
sink(log_file, split = TRUE)

cat(sep_line(), "\n")
cat("BENCHMARK: did_multiplegt_dyn - Wolfers 2006 Dataset\n")
cat(sep_line(), "\n")
cat("Date:", as.character(Sys.time()), "\n\n")

# Load original data
cat("Loading data...\n")
wolfers <- as.data.frame(read_dta("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/wolfers2006_didtextbook.dta"))
cat("Original data rows:", nrow(wolfers), "\n\n")

# Function to run benchmark with timeout
run_with_timeout <- function(expr, timeout_sec = TIMEOUT_SECONDS) {
  result <- list(time = NA, output = NULL, status = "error")

  tryCatch({
    start_time <- Sys.time()
    result$output <- eval(expr)
    end_time <- Sys.time()
    result$time <- as.numeric(difftime(end_time, start_time, units = "secs"))
    result$status <- "completed"
  }, error = function(e) {
    result$status <- paste("error:", e$message)
  })

  return(result)
}

# Function to create synthetic data by duplicating groups
create_synthetic_data <- function(df, multiplier) {
  if (multiplier == 1) return(df)

  # Get unique states
  unique_states <- unique(df$state)
  n_states <- length(unique_states)

  # Create new dataframe with duplicated groups
  result_list <- list()
  for (i in 1:multiplier) {
    temp_df <- df
    # Create new state IDs for duplicates
    temp_df$state <- temp_df$state + (i - 1) * max(df$state) * 10
    result_list[[i]] <- temp_df
  }

  result <- do.call(rbind, result_list)
  rownames(result) <- NULL
  return(result)
}

# Store all results
results <- data.frame(
  scenario = character(),
  package = character(),
  rows = numeric(),
  time_seconds = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

# Store effect estimates for comparison
effect_estimates <- list()

# ============================================================
# SCENARIO 1: Original Data (1,683 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 1: Original Data (", nrow(wolfers), " rows)\n")
cat(sep_line(), "\n\n")

# R-CRAN
cat("Running R-CRAN...\n")
res_cran_orig <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}))
cat("R-CRAN:", ifelse(res_cran_orig$status == "completed",
                      paste(round(res_cran_orig$time, 2), "seconds"),
                      res_cran_orig$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "R-CRAN",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_cran_orig$status == "completed", res_cran_orig$time, NA),
  status = res_cran_orig$status
))
if (res_cran_orig$status == "completed") {
  effect_estimates[["orig_cran"]] <- res_cran_orig$output
}

# R-Polars
cat("Running R-Polars...\n")
res_polars_orig <- run_with_timeout(quote({
  DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = wolfers,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}))
cat("R-Polars:", ifelse(res_polars_orig$status == "completed",
                        paste(round(res_polars_orig$time, 2), "seconds"),
                        res_polars_orig$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "R-Polars",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_polars_orig$status == "completed", res_polars_orig$time, NA),
  status = res_polars_orig$status
))
if (res_polars_orig$status == "completed") {
  effect_estimates[["orig_polars"]] <- res_polars_orig$output
}

# ============================================================
# SCENARIO 2: Synthetic Data 100x (168,300 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 2: Synthetic Data 100x\n")
cat(sep_line(), "\n\n")

wolfers_100x <- create_synthetic_data(wolfers, 100)
cat("Synthetic data rows:", nrow(wolfers_100x), "\n\n")

# R-CRAN
cat("Running R-CRAN...\n")
res_cran_100x <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers_100x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}))
cat("R-CRAN:", ifelse(res_cran_100x$status == "completed",
                      paste(round(res_cran_100x$time, 2), "seconds"),
                      res_cran_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "R-CRAN",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_cran_100x$status == "completed", res_cran_100x$time, NA),
  status = res_cran_100x$status
))

# R-Polars
cat("Running R-Polars...\n")
res_polars_100x <- run_with_timeout(quote({
  DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = wolfers_100x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}))
cat("R-Polars:", ifelse(res_polars_100x$status == "completed",
                        paste(round(res_polars_100x$time, 2), "seconds"),
                        res_polars_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "R-Polars",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_polars_100x$status == "completed", res_polars_100x$time, NA),
  status = res_polars_100x$status
))

# Clean up
rm(wolfers_100x)
gc()

# ============================================================
# SCENARIO 3: Synthetic Data 10000x (1,683,000 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 3: Synthetic Data 10000x (1 hour timeout)\n")
cat(sep_line(), "\n\n")

wolfers_10000x <- create_synthetic_data(wolfers, 1000)
cat("Synthetic data rows:", nrow(wolfers_10000x), "\n\n")

# R-Polars first (expected to be faster)
cat("Running R-Polars...\n")
res_polars_10000x <- run_with_timeout(quote({
  DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = wolfers_10000x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}), timeout_sec = TIMEOUT_SECONDS)

polars_time_10000x <- ifelse(res_polars_10000x$status == "completed", res_polars_10000x$time, NA)
cat("R-Polars:", ifelse(res_polars_10000x$status == "completed",
                        paste(round(res_polars_10000x$time, 2), "seconds"),
                        res_polars_10000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "10000x (16.8M)",
  package = "R-Polars",
  rows = nrow(wolfers_10000x),
  time_seconds = polars_time_10000x,
  status = res_polars_10000x$status
))

# R-CRAN - run only if polars completed, wait 2x polars time, max 1 hour
cat("Running R-CRAN...\n")
if (!is.na(polars_time_10000x)) {
  cran_timeout <- min(polars_time_10000x * 3, TIMEOUT_SECONDS)
  cat("(timeout set to", round(cran_timeout, 0), "seconds based on Polars time)\n")
} else {
  cran_timeout <- TIMEOUT_SECONDS
}

res_cran_10000x <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers_10000x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}), timeout_sec = cran_timeout)

cran_status_10000x <- res_cran_10000x$status
if (grepl("error", cran_status_10000x) && grepl("memory", cran_status_10000x, ignore.case = TRUE)) {
  cran_status_10000x <- "memory error"
}
cat("R-CRAN:", ifelse(res_cran_10000x$status == "completed",
                      paste(round(res_cran_10000x$time, 2), "seconds"),
                      cran_status_10000x), "\n")
results <- rbind(results, data.frame(
  scenario = "10000x (16.8M)",
  package = "R-CRAN",
  rows = nrow(wolfers_10000x),
  time_seconds = ifelse(res_cran_10000x$status == "completed", res_cran_10000x$time, NA),
  status = cran_status_10000x
))

# Clean up
rm(wolfers_10000x)
gc()

# ============================================================
# SUMMARY
# ============================================================
cat("\n", sep_line(), "\n")
cat("SUMMARY OF RESULTS\n")
cat(sep_line(), "\n\n")

print(results)

# ============================================================
# EFFECT ESTIMATES COMPARISON
# ============================================================
cat("\n", sep_line(), "\n")
cat("EFFECT ESTIMATES COMPARISON (Original Data)\n")
cat(sep_line(), "\n\n")

if (!is.null(effect_estimates[["orig_cran"]]) && !is.null(effect_estimates[["orig_polars"]])) {
  cat("Effects:\n")
  for (i in 1:16) {
    cran_eff <- effect_estimates[["orig_cran"]]$results$Effects[, 'Estimate'][i]
    polars_eff <- effect_estimates[["orig_polars"]]$results$Effects[, 'Estimate'][i]
    cat(sprintf("Effect_%d: CRAN=%.6f, Polars=%.6f, Diff=%.2e\n",
                i, cran_eff, polars_eff, abs(cran_eff - polars_eff)))
  }

  cat("\nPlacebos:\n")
  for (i in 1:9) {
    cran_pl <- effect_estimates[["orig_cran"]]$results$Placebos[, 'Estimate'][i]
    polars_pl <- effect_estimates[["orig_polars"]]$results$Placebos[, 'Estimate'][i]
    cat(sprintf("Placebo_%d: CRAN=%.6f, Polars=%.6f, Diff=%.2e\n",
                i, cran_pl, polars_pl, abs(cran_pl - polars_pl)))
  }
}

# Save results to CSV
write.csv(results, "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_results_r.csv", row.names = FALSE)

cat("\n\nBenchmark completed at:", as.character(Sys.time()), "\n")
sink()

cat("Log saved to:", log_file, "\n")
cat("Results saved to: /Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_results_r.csv\n")
