# Debug wagepan placebo SE computation
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

# First run CRAN to get the internal values
cat("=== CRAN Internal Values ===\n")
library(DIDmultiplegtDYN)

# Capture the internal computation by modifying the trace
result_cran <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  controls = c("hours"),
  graph_off = TRUE
)

cat("CRAN Placebo 1 SE:", result_cran$results$Placebos[1, "SE"], "\n")
cat("CRAN Placebo 2 SE:", result_cran$results$Placebos[2, "SE"], "\n")
cat("CRAN Placebo 1 N:", result_cran$results$Placebos[1, "N"], "\n")
cat("CRAN Placebo 2 N:", result_cran$results$Placebos[2, "N"], "\n")

detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n=== Polars Internal Values ===\n")
library(DIDmultiplegtDYNpolars)

result_polars <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  controls = c("hours"),
  graph_off = TRUE
)

cat("Polars Placebo 1 SE:", result_polars$results$Placebos[1, "SE"], "\n")
cat("Polars Placebo 2 SE:", result_polars$results$Placebos[2, "SE"], "\n")
cat("Polars Placebo 1 N:", result_polars$results$Placebos[1, "N"], "\n")
cat("Polars Placebo 2 N:", result_polars$results$Placebos[2, "N"], "\n")

cat("\nSE ratio (Polars/CRAN):\n")
cat("Placebo 1:", result_polars$results$Placebos[1, "SE"] / result_cran$results$Placebos[1, "SE"], "\n")
cat("Placebo 2:", result_polars$results$Placebos[2, "SE"] / result_cran$results$Placebos[2, "SE"], "\n")

# Check if N ratio explains SE ratio
cat("\nN ratio (Polars/CRAN):\n")
cat("Placebo 1:", result_polars$results$Placebos[1, "N"] / result_cran$results$Placebos[1, "N"], "\n")
cat("Placebo 2:", result_polars$results$Placebos[2, "N"] / result_cran$results$Placebos[2, "N"], "\n")
