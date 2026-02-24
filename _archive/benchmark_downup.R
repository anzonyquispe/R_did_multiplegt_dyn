# Benchmark test for downup dataset (18M rows)
library(DIDmultiplegtDYN)  # CRAN version
library(DIDmultiplegtDYNpolars)  # Optimized polars version

# Load downup dataset
cat("\n========== BENCHMARK TEST: DOWNUP DATA ==========\n")
cat("Loading data...\n")
downup <- read.csv("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/downup_data.csv")
cat("Data loaded: ", nrow(downup), " observations\n\n")

# Test polars version first
cat("Test 1: Polars Version\n")
cat(strrep("-", 40), "\n")

t_polars <- system.time({
  res_polars <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = downup,
    outcome = "count",
    group = "unique_grid_id",
    time = "time",
    treatment = "downup_dummy",
    effects = 5,
    placebo = 1
  )
})

cat("Polars version: ", round(t_polars["elapsed"], 2), "s\n\n")

# Calculate timeout for CRAN version (3x polars time)
timeout_seconds <- ceiling(t_polars["elapsed"] * 3)
cat("Test 2: CRAN Version (timeout: ", timeout_seconds, "s)\n")
cat(strrep("-", 40), "\n")

# Run CRAN version with timeout using R.utils
if (requireNamespace("R.utils", quietly = TRUE)) {
  t_cran <- tryCatch({
    system.time({
      res_cran <- R.utils::withTimeout({
        DIDmultiplegtDYN::did_multiplegt_dyn(
          df = downup,
          outcome = "count",
          group = "unique_grid_id",
          time = "time",
          treatment = "downup_dummy",
          effects = 5,
          placebo = 1
        )
      }, timeout = timeout_seconds)
    })
  }, TimeoutException = function(ex) {
    cat("CRAN version TIMED OUT after ", timeout_seconds, "s\n")
    return(NULL)
  }, error = function(e) {
    cat("Error: ", e$message, "\n")
    return(NULL)
  })
} else {
  # Fallback without timeout
  cat("Running without timeout (R.utils not available)...\n")
  t_cran <- system.time({
    res_cran <- DIDmultiplegtDYN::did_multiplegt_dyn(
      df = downup,
      outcome = "count",
      group = "unique_grid_id",
      time = "time",
      treatment = "downup_dummy",
      effects = 5,
      placebo = 1
    )
  })
}

if (!is.null(t_cran)) {
  cat("CRAN version: ", round(t_cran["elapsed"], 2), "s\n")
  cat("Speedup: ", round(t_cran["elapsed"] / t_polars["elapsed"], 2), "x\n\n")
} else {
  cat("CRAN version did not complete within timeout\n\n")
}

cat("========== SUMMARY ==========\n")
cat("Dataset size: ", nrow(downup), " observations\n")
cat("Polars time: ", round(t_polars["elapsed"], 2), "s\n")
if (!is.null(t_cran)) {
  cat("CRAN time: ", round(t_cran["elapsed"], 2), "s\n")
  cat("Speedup: ", round(t_cran["elapsed"] / t_polars["elapsed"], 2), "x\n")
} else {
  cat("CRAN time: TIMEOUT (>", timeout_seconds, "s)\n")
  cat("Speedup: >", round(timeout_seconds / t_polars["elapsed"], 1), "x\n")
}
