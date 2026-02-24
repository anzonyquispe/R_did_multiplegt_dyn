# Benchmark with 5M rows subset
library(DIDmultiplegtDYNpolars)
library(DIDmultiplegtDYN)

message("Loading data...")
downup <- read.csv("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/downup_data.csv", nrows = 5000000)
message(paste("Data loaded:", nrow(downup), "observations"))

# Run Polars
message("Running Polars version...")
start_polars <- Sys.time()
res_polars <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
  df = downup,
  outcome = "count",
  group = "unique_grid_id",
  time = "time",
  treatment = "downup_dummy",
  effects = 5,
  placebo = 1
)
end_polars <- Sys.time()
polars_time <- as.numeric(difftime(end_polars, start_polars, units = "secs"))
message(paste("POLARS:", round(polars_time, 2), "seconds"))

# Run CRAN with timeout (3x polars time)
max_cran_time <- polars_time * 3
message(paste("Running CRAN version (max", round(max_cran_time, 0), "seconds)..."))

start_cran <- Sys.time()
res_cran <- DIDmultiplegtDYN::did_multiplegt_dyn(
  df = downup,
  outcome = "count",
  group = "unique_grid_id",
  time = "time",
  treatment = "downup_dummy",
  effects = 5,
  placebo = 1
)
end_cran <- Sys.time()
cran_time <- as.numeric(difftime(end_cran, start_cran, units = "secs"))
message(paste("CRAN:", round(cran_time, 2), "seconds"))

# Summary
message("========== SUMMARY ==========")
message(paste("Dataset: 5M observations"))
message(paste("Polars:", round(polars_time, 2), "s"))
message(paste("CRAN:", round(cran_time, 2), "s"))
message(paste("Speedup:", round(cran_time / polars_time, 2), "x"))

# Save results
results <- data.frame(
  rows = 5000000,
  polars_time = polars_time,
  cran_time = cran_time,
  speedup = cran_time / polars_time
)
write.csv(results, "/tmp/benchmark_results.csv", row.names = FALSE)
