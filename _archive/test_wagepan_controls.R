# Test wagepan with controls
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

cat("================================================================================\n")
cat("CRAN PACKAGE OUTPUT\n")
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
  controls = c("hours"),
  graph_off = TRUE
)

print(result_cran)

cat("\nEffects matrix:\n")
print(result_cran$results$Effects)

detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n\n================================================================================\n")
cat("POLARS PACKAGE OUTPUT\n")
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
  controls = c("hours"),
  graph_off = TRUE
)

print(result_polars)

cat("\nEffects matrix:\n")
print(result_polars$results$Effects)

cat("\n\n================================================================================\n")
cat("COMPARISON\n")
cat("================================================================================\n\n")

cat("Effects Comparison:\n")
for (i in 1:5) {
  cran_est <- result_cran$results$Effects[i, "Estimate"]
  cran_se <- result_cran$results$Effects[i, "SE"]
  polars_est <- result_polars$results$Effects[i, "Estimate"]
  polars_se <- result_polars$results$Effects[i, "SE"]

  cat(sprintf("Effect %d: Est diff=%.6f, SE ratio=%.6f (CRAN=%.6f, Polars=%.6f)\n",
              i, polars_est - cran_est, polars_se/cran_se, cran_se, polars_se))
}

cat("\nPlacebos Comparison:\n")
for (i in 1:2) {
  cran_est <- result_cran$results$Placebos[i, "Estimate"]
  cran_se <- result_cran$results$Placebos[i, "SE"]
  polars_est <- result_polars$results$Placebos[i, "Estimate"]
  polars_se <- result_polars$results$Placebos[i, "SE"]

  cat(sprintf("Placebo %d: Est diff=%.6f, SE ratio=%.6f (CRAN=%.6f, Polars=%.6f)\n",
              i, polars_est - cran_est, polars_se/cran_se, cran_se, polars_se))
}
