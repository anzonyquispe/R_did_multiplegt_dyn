# Benchmark polars version only
library(DIDmultiplegtDYNpolars)

cat("Loading data...\n")
downup <- read.csv("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/downup_data.csv")
cat("Data loaded: ", nrow(downup), " observations\n\n")

cat("Running Polars version...\n")
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

cat("POLARS_TIME:", t_polars["elapsed"], "\n")
