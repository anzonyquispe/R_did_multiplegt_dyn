# Test with Favara-Imbs dataset - exact match comparison
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"

cat("\n", strrep("=", 80), "\n", "FAVARA-IMBS DATASET COMPARISON\n", strrep("=", 80), "\n\n", sep="")
favara <- read_dta(file.path(data_path, "favara_imbs.dta"))
cat("Data loaded:", nrow(favara), "observations\n\n")

# Run CRAN version first
cat("=== CRAN VERSION ===\n")
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

cat("\nCRAN Effects:\n")
print(result_cran$results$Effects)
cat("\nCRAN Placebos:\n")
print(result_cran$results$Placebos)
cat("\nCRAN Average Effect:\n")
print(result_cran$results$`Average effect`)

# Run Polars version
detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n=== POLARS VERSION ===\n")
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

cat("\nPolars Effects:\n")
print(result_polars$results$Effects)
cat("\nPolars Placebos:\n")
print(result_polars$results$Placebos)
cat("\nPolars Average Effect:\n")
print(result_polars$results$`Average effect`)

# Detailed comparison
cat("\n", strrep("=", 80), "\n", "DETAILED COMPARISON\n", strrep("=", 80), "\n\n", sep="")

cat("EFFECTS:\n")
for (i in 1:5) {
  est_p <- result_polars$results$Effects[i, "Estimate"]
  est_c <- result_cran$results$Effects[i, "Estimate"]
  se_p <- result_polars$results$Effects[i, "SE"]
  se_c <- result_cran$results$Effects[i, "SE"]
  nw_p <- result_polars$results$Effects[i, "N.w"]
  nw_c <- result_cran$results$Effects[i, "N.w"]

  cat(sprintf("Effect %d:\n", i))
  cat(sprintf("  Estimate: Polars=%.10f, CRAN=%.10f, Match=%s\n", est_p, est_c, abs(est_p - est_c) < 1e-10))
  cat(sprintf("  SE:       Polars=%.10f, CRAN=%.10f, Ratio=%.6f\n", se_p, se_c, se_p/se_c))
  cat(sprintf("  N.w:      Polars=%d, CRAN=%d, Match=%s\n", nw_p, nw_c, nw_p == nw_c))
}

cat("\nPLACEBOS:\n")
for (i in 1:3) {
  est_p <- result_polars$results$Placebos[i, "Estimate"]
  est_c <- result_cran$results$Placebos[i, "Estimate"]
  se_p <- result_polars$results$Placebos[i, "SE"]
  se_c <- result_cran$results$Placebos[i, "SE"]

  cat(sprintf("Placebo %d:\n", i))
  cat(sprintf("  Estimate: Polars=%.10f, CRAN=%.10f, Match=%s\n", est_p, est_c, abs(est_p - est_c) < 1e-10))
  cat(sprintf("  SE:       Polars=%.10f, CRAN=%.10f, Ratio=%.6f\n", se_p, se_c, se_p/se_c))
}

cat("\nAVERAGE EFFECT:\n")
avg_p <- result_polars$results$`Average effect`
avg_c <- result_cran$results$`Average effect`
cat(sprintf("  Estimate: Polars=%.10f, CRAN=%.10f, Match=%s\n",
            avg_p[1, "Estimate"], avg_c[1, "Estimate"],
            abs(avg_p[1, "Estimate"] - avg_c[1, "Estimate"]) < 1e-10))
cat(sprintf("  SE:       Polars=%.10f, CRAN=%.10f, Ratio=%.6f\n",
            avg_p[1, "SE"], avg_c[1, "SE"], avg_p[1, "SE"]/avg_c[1, "SE"]))
