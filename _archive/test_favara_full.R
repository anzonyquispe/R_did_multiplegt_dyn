# Full Favara-Imbs test with 5 effects and 3 placebos
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
favara <- read_dta(file.path(data_path, "favara_imbs.dta"))

cat("=== CRAN Results ===\n\n")
library(DIDmultiplegtDYN)

result_cran <- did_multiplegt_dyn(
  df = favara,
  outcome = "Dl_hpi",
  group = "county",
  time = "year",
  treatment = "inter_bra",
  effects = 5,
  placebo = 3,
  cluster = "state_n",
  graph_off = TRUE
)

print(result_cran$results$Effects)
cat("\n")
print(result_cran$results$Placebos)
cat("\n")
cat("Average Effect:\n")
print(result_cran$results$Average_effects)

detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n\n=== Polars Results ===\n\n")
library(DIDmultiplegtDYNpolars)

result_polars <- did_multiplegt_dyn(
  df = favara,
  outcome = "Dl_hpi",
  group = "county",
  time = "year",
  treatment = "inter_bra",
  effects = 5,
  placebo = 3,
  cluster = "state_n",
  graph_off = TRUE
)

print(result_polars$results$Effects)
cat("\n")
print(result_polars$results$Placebos)
cat("\n")
cat("Average Effect:\n")
print(result_polars$results$Average_effects)

cat("\n\n=== Comparison ===\n\n")

# Compare Effects
cat("Effects Comparison:\n")
for (i in 1:5) {
  cran_est <- result_cran$results$Effects[i, "Estimate"]
  cran_se <- result_cran$results$Effects[i, "SE"]
  polars_est <- result_polars$results$Effects[i, "Estimate"]
  polars_se <- result_polars$results$Effects[i, "SE"]

  cat(sprintf("Effect %d: Est ratio=%.6f, SE ratio=%.6f\n",
              i, polars_est/cran_est, polars_se/cran_se))
}

# Compare Placebos
cat("\nPlacebos Comparison:\n")
for (i in 1:3) {
  cran_est <- result_cran$results$Placebos[i, "Estimate"]
  cran_se <- result_cran$results$Placebos[i, "SE"]
  polars_est <- result_polars$results$Placebos[i, "Estimate"]
  polars_se <- result_polars$results$Placebos[i, "SE"]

  cat(sprintf("Placebo %d: Est ratio=%.6f, SE ratio=%.6f\n",
              i, polars_est/cran_est, polars_se/cran_se))
}

# Compare Average Effect
cat("\nAverage Effect Comparison:\n")
cran_avg <- result_cran$results$Average_effects[1, "Estimate"]
cran_avg_se <- result_cran$results$Average_effects[1, "SE"]
polars_avg <- result_polars$results$Average_effects[1, "Estimate"]
polars_avg_se <- result_polars$results$Average_effects[1, "SE"]

cat(sprintf("Average: Est ratio=%.6f, SE ratio=%.6f\n",
            polars_avg/cran_avg, polars_avg_se/cran_avg_se))

# Expected values from user's test
cat("\n=== Expected Values ===\n")
cat("Expected Av_tot_eff: 0.0041924\n")
cat("Expected SE: 0.0018366\n")
cat("Expected N: 8276\n")

cat("\n=== Actual Average Effect ===\n")
cat("Polars Av_tot_eff:", polars_avg, "\n")
cat("Polars SE:", polars_avg_se, "\n")
cat("Polars N:", result_polars$results$Average_effects[1, "N.w"], "\n")
