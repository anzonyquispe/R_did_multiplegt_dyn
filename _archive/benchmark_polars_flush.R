# Benchmark polars version with flushing
library(DIDmultiplegtDYNpolars)

message("Loading data...")
downup <- read.csv("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/downup_data.csv")
message(paste("Data loaded:", nrow(downup), "observations"))

message("Running Polars version...")
flush.console()

start_time <- Sys.time()
res_polars <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
  df = downup,
  outcome = "count",
  group = "unique_grid_id",
  time = "time",
  treatment = "downup_dummy",
  effects = 5,
  placebo = 1
)
end_time <- Sys.time()

elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
message(paste("POLARS COMPLETED:", round(elapsed, 2), "seconds"))

# Save result to file
writeLines(as.character(round(elapsed, 2)), "/tmp/polars_time.txt")
