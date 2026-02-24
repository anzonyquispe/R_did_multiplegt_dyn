# Comprehensive Benchmark: DID Estimators Comparison (Cluster Version)
# Adapted for Notre Dame CRC cluster
# Uses relative paths from project root

# Get project root (assumes script is run from cluster/ or tests/ directory)
get_project_root <- function() {
  # Try to find project root by looking for DESCRIPTION file
  candidates <- c(
    Sys.getenv("PROJECT_ROOT"),
    file.path(Sys.getenv("HOME"), "R_didgt_polars"),
    dirname(getwd()),
    getwd()
  )

  for (path in candidates) {
    if (path != "" && file.exists(file.path(path, "DESCRIPTION"))) {
      return(path)
    }
  }

  # Default fallback
  return(file.path(Sys.getenv("HOME"), "R_didgt_polars"))
}

PROJECT_ROOT <- get_project_root()
cat("Project root:", PROJECT_ROOT, "\n")

# Set paths relative to project root
DATA_PATH <- file.path(PROJECT_ROOT, "data", "wolfers2006_didtextbook.dta")
OUTPUT_DIR <- file.path(PROJECT_ROOT, "tests")
LOG_FILE <- file.path(OUTPUT_DIR, "benchmark_wolfers_complete.log")
RESULTS_FILE <- file.path(OUTPUT_DIR, "benchmark_results_complete.csv")

# Verify data file exists
if (!file.exists(DATA_PATH)) {
  stop("Data file not found: ", DATA_PATH)
}

# Load packages
library(haven)
library(DIDmultiplegtDYN)
library(DIDmultiplegtDYNpolars)
library(dplyr)

# Set timeout (1 hour in seconds)
TIMEOUT_SECONDS <- 3600

# Helper function for separator
sep_line <- function() paste(rep("=", 70), collapse = "")

# Start logging
sink(LOG_FILE, split = TRUE)

cat(sep_line(), "\n")
cat("COMPREHENSIVE BENCHMARK: DID Estimators Comparison\n")
cat(sep_line(), "\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Hostname:", Sys.info()["nodename"], "\n")
cat("R Version:", R.version.string, "\n")
cat("Packages: DIDmultiplegtDYN (CRAN), DIDmultiplegtDYNpolars\n")
cat("Project Root:", PROJECT_ROOT, "\n\n")

# Load original data
cat("Loading data...\n")
wolfers <- as.data.frame(read_dta(DATA_PATH))
cat("Original data rows:", nrow(wolfers), "\n")

# Prepare data
wolfers <- wolfers %>%
  group_by(state) %>%
  mutate(
    first_treat = ifelse(any(udl == 1), min(year[udl == 1]), 0)
  ) %>%
  ungroup() %>%
  as.data.frame()

cat("Unique states:", length(unique(wolfers$state)), "\n")
cat("Year range:", min(wolfers$year), "-", max(wolfers$year), "\n\n")

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

# Function to create synthetic data
create_synthetic_data <- function(df, multiplier) {
  if (multiplier == 1) return(df)

  result_list <- list()
  for (i in 1:multiplier) {
    temp_df <- df
    temp_df$state <- temp_df$state + (i - 1) * max(df$state) * 10
    result_list[[i]] <- temp_df
  }

  result <- do.call(rbind, result_list)
  rownames(result) <- NULL
  return(result)
}

# Store results
results <- data.frame(
  scenario = character(),
  package = character(),
  rows = numeric(),
  time_seconds = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

# =============================================================================
# SCENARIO 1: Original Data
# =============================================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 1: Original Data (", nrow(wolfers), " rows)\n")
cat(sep_line(), "\n\n")

# R-CRAN
cat("1. Running DIDmultiplegtDYN (CRAN)...\n")
res_cran <- run_with_timeout(quote({
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
cat("   Time:", ifelse(res_cran$status == "completed",
                       paste(round(res_cran$time, 2), "seconds"),
                       res_cran$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "DIDmultiplegtDYN-CRAN",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_cran$status == "completed", res_cran$time, NA),
  status = res_cran$status
))

# R-Polars
cat("2. Running DIDmultiplegtDYNpolars...\n")
res_polars <- run_with_timeout(quote({
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
cat("   Time:", ifelse(res_polars$status == "completed",
                       paste(round(res_polars$time, 2), "seconds"),
                       res_polars$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "DIDmultiplegtDYN-Polars",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_polars$status == "completed", res_polars$time, NA),
  status = res_polars$status
))

# =============================================================================
# SCENARIO 2: 100x Data
# =============================================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 2: Synthetic Data 100x\n")
cat(sep_line(), "\n\n")

wolfers_100x <- create_synthetic_data(wolfers, 100)
cat("Synthetic data rows:", nrow(wolfers_100x), "\n\n")

# R-CRAN
cat("1. Running DIDmultiplegtDYN (CRAN)...\n")
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
cat("   Time:", ifelse(res_cran_100x$status == "completed",
                       paste(round(res_cran_100x$time, 2), "seconds"),
                       res_cran_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "DIDmultiplegtDYN-CRAN",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_cran_100x$status == "completed", res_cran_100x$time, NA),
  status = res_cran_100x$status
))

# R-Polars
cat("2. Running DIDmultiplegtDYNpolars...\n")
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
cat("   Time:", ifelse(res_polars_100x$status == "completed",
                       paste(round(res_polars_100x$time, 2), "seconds"),
                       res_polars_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "DIDmultiplegtDYN-Polars",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_polars_100x$status == "completed", res_polars_100x$time, NA),
  status = res_polars_100x$status
))

rm(wolfers_100x)
gc()

# =============================================================================
# SCENARIO 3: 1000x Data
# =============================================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 3: Synthetic Data 1000x\n")
cat(sep_line(), "\n\n")

wolfers_1000x <- create_synthetic_data(wolfers, 1000)
cat("Synthetic data rows:", nrow(wolfers_1000x), "\n\n")

# R-Polars first (expected fastest)
cat("1. Running DIDmultiplegtDYNpolars...\n")
res_polars_1000x <- run_with_timeout(quote({
  DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = wolfers_1000x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}))
cat("   Time:", ifelse(res_polars_1000x$status == "completed",
                       paste(round(res_polars_1000x$time, 2), "seconds"),
                       res_polars_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "DIDmultiplegtDYN-Polars",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_polars_1000x$status == "completed", res_polars_1000x$time, NA),
  status = res_polars_1000x$status
))

# R-CRAN with timeout based on polars time
cat("2. Running DIDmultiplegtDYN (CRAN)...\n")
polars_time_1000x <- ifelse(res_polars_1000x$status == "completed", res_polars_1000x$time, 300)
cran_timeout <- min(polars_time_1000x * 5, TIMEOUT_SECONDS)
cat("   (timeout set to", round(cran_timeout, 0), "seconds)\n")

res_cran_1000x <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers_1000x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 16,
    placebo = 9,
    weight = "stpop"
  )
}), timeout_sec = cran_timeout)
cat("   Time:", ifelse(res_cran_1000x$status == "completed",
                       paste(round(res_cran_1000x$time, 2), "seconds"),
                       res_cran_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "DIDmultiplegtDYN-CRAN",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_cran_1000x$status == "completed", res_cran_1000x$time, NA),
  status = res_cran_1000x$status
))

rm(wolfers_1000x)
gc()

# =============================================================================
# SUMMARY
# =============================================================================
cat("\n", sep_line(), "\n")
cat("SUMMARY OF RESULTS\n")
cat(sep_line(), "\n\n")

print(results)

# Calculate speedups
cat("\n\nSPEEDUP ANALYSIS:\n")
for (scenario in unique(results$scenario)) {
  scenario_data <- results[results$scenario == scenario, ]
  cran_time <- scenario_data$time_seconds[scenario_data$package == "DIDmultiplegtDYN-CRAN"]
  polars_time <- scenario_data$time_seconds[scenario_data$package == "DIDmultiplegtDYN-Polars"]

  if (!is.na(cran_time) && !is.na(polars_time) && polars_time > 0) {
    speedup <- cran_time / polars_time
    cat(sprintf("%s: Polars is %.1fx faster than CRAN\n", scenario, speedup))
  } else if (is.na(cran_time) && !is.na(polars_time)) {
    cat(sprintf("%s: Only Polars completed (CRAN failed)\n", scenario))
  }
}

# Save results
write.csv(results, RESULTS_FILE, row.names = FALSE)

cat("\n\nBenchmark completed at:", as.character(Sys.time()), "\n")
sink()

cat("Log saved to:", LOG_FILE, "\n")
cat("Results saved to:", RESULTS_FILE, "\n")
