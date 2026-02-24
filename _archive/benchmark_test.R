# Benchmark test for optimized polars package
library(DIDmultiplegtDYN)  # CRAN version
library(DIDmultiplegtDYNpolars)  # Optimized polars version

# Load favara dataset
load("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/favara_imbs.RData")
favara <- favara_imbs

cat("\n========== BENCHMARK TEST ==========\n")
cat("Testing optimized polars version vs CRAN version\n\n")

# Test 1: Original data size
cat("Test 1: Original Data (", nrow(favara), " observations)\n", sep = "")
cat(strrep("-", 40), "\n")

t1_cran <- system.time({
  res_cran <- DIDmultiplegtDYN::did_multiplegt_dyn(
    df = as.data.frame(favara),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

t1_polars <- system.time({
  res_polars <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = as.data.frame(favara),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

cat("CRAN version: ", round(t1_cran["elapsed"], 2), "s\n")
cat("Polars version: ", round(t1_polars["elapsed"], 2), "s\n")
cat("Speedup: ", round(t1_cran["elapsed"] / t1_polars["elapsed"], 2), "x\n\n")

# Test 2: Bootstrapped to 100,000 observations
cat("Test 2: Bootstrapped Data (~100,000 observations)\n")
cat(strrep("-", 40), "\n")

# Bootstrap the data
set.seed(42)
n_target <- 100000
n_original <- nrow(favara)
sample_indices <- sample(1:n_original, n_target, replace = TRUE)
favara_boot <- favara[sample_indices, ]
# Update row indices
rownames(favara_boot) <- NULL

cat("Actual size: ", nrow(favara_boot), " observations\n")

t2_cran <- system.time({
  res_cran_boot <- DIDmultiplegtDYN::did_multiplegt_dyn(
    df = as.data.frame(favara_boot),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

t2_polars <- system.time({
  res_polars_boot <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = as.data.frame(favara_boot),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

cat("CRAN version: ", round(t2_cran["elapsed"], 2), "s\n")
cat("Polars version: ", round(t2_polars["elapsed"], 2), "s\n")
cat("Speedup: ", round(t2_cran["elapsed"] / t2_polars["elapsed"], 2), "x\n\n")

# Test 2b: Bootstrapped to 1,000,000 observations
cat("Test 2b: Bootstrapped Data (~1,000,000 observations)\n")
cat(strrep("-", 40), "\n")

set.seed(42)
n_target <- 1000000
sample_indices <- sample(1:n_original, n_target, replace = TRUE)
favara_1m <- favara[sample_indices, ]
rownames(favara_1m) <- NULL

cat("Actual size: ", nrow(favara_1m), " observations\n")

t2b_cran <- system.time({
  res_cran_1m <- DIDmultiplegtDYN::did_multiplegt_dyn(
    df = as.data.frame(favara_1m),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

t2b_polars <- system.time({
  res_polars_1m <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = as.data.frame(favara_1m),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1
  )
})

cat("CRAN version: ", round(t2b_cran["elapsed"], 2), "s\n")
cat("Polars version: ", round(t2b_polars["elapsed"], 2), "s\n")
cat("Speedup: ", round(t2b_cran["elapsed"] / t2b_polars["elapsed"], 2), "x\n\n")

# Test 3: With trends_lin option
cat("Test 3: With trends_lin option\n")
cat(strrep("-", 40), "\n")

t3_cran <- system.time({
  res_cran_tl <- DIDmultiplegtDYN::did_multiplegt_dyn(
    df = as.data.frame(favara),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1,
    trends_lin = TRUE
  )
})

t3_polars <- system.time({
  res_polars_tl <- DIDmultiplegtDYNpolars::did_multiplegt_dyn(
    df = as.data.frame(favara),
    outcome = "Dl_vloans_b",
    group = "county",
    time = "year",
    treatment = "inter_bra",
    effects = 5,
    placebo = 1,
    trends_lin = TRUE
  )
})

cat("CRAN version: ", round(t3_cran["elapsed"], 2), "s\n")
cat("Polars version: ", round(t3_polars["elapsed"], 2), "s\n")
cat("Speedup: ", round(t3_cran["elapsed"] / t3_polars["elapsed"], 2), "x\n\n")

# Results comparison
cat("========== RESULTS COMPARISON ==========\n\n")
cat("Effect_1 CRAN: ", round(res_cran$coef$b["Effect_1"], 6), "\n")
cat("Effect_1 Polars: ", round(res_polars$coef$b["Effect_1"], 6), "\n")
cat("Difference: ", abs(res_cran$coef$b["Effect_1"] - res_polars$coef$b["Effect_1"]), "\n\n")

cat("========== SUMMARY ==========\n")
cat("Original data (1K) speedup: ", round(t1_cran["elapsed"] / t1_polars["elapsed"], 2), "x\n")
cat("Bootstrapped (100K) speedup: ", round(t2_cran["elapsed"] / t2_polars["elapsed"], 2), "x\n")
cat("Bootstrapped (1M) speedup: ", round(t2b_cran["elapsed"] / t2b_polars["elapsed"], 2), "x\n")
cat("With trends_lin speedup: ", round(t3_cran["elapsed"] / t3_polars["elapsed"], 2), "x\n")
