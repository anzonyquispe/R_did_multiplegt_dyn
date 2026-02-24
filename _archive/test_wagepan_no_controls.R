# Test wagepan without controls
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

cat("================================================================================\n")
cat("CRAN PACKAGE OUTPUT (no controls)\n")
cat("================================================================================\n\n")
library(DIDmultiplegtDYN)

result_cran <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  graph_off = TRUE
)

cat("CRAN Placebos:\n")
print(result_cran$results$Placebos)

detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n\n================================================================================\n")
cat("POLARS PACKAGE OUTPUT (no controls)\n")
cat("================================================================================\n\n")
library(DIDmultiplegtDYNpolars)

result_polars <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  graph_off = TRUE
)

cat("Polars Placebos:\n")
print(result_polars$results$Placebos)

cat("\n\n================================================================================\n")
cat("COMPARISON\n")
cat("================================================================================\n\n")

cat("Placebos Comparison:\n")
for (i in 1:2) {
  cran_se <- result_cran$results$Placebos[i, "SE"]
  polars_se <- result_polars$results$Placebos[i, "SE"]
  cat(sprintf("Placebo %d: SE ratio=%.6f (CRAN=%.6f, Polars=%.6f)\n",
              i, polars_se/cran_se, cran_se, polars_se))
}
