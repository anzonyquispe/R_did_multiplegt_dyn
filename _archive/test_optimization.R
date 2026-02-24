# Test script to compare optimized local version vs CRAN version
# Run this script to benchmark the performance improvements

# ============================================================================
# SETUP
# ============================================================================

# First, ensure we have the data
favara_imbs <- fread("/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn/data/favara_stata.csv")

# Check if microbenchmark is installed (for accurate timing)
if (!requireNamespace("microbenchmark", quietly = TRUE)) {
    install.packages("microbenchmark")
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_did_test <- function() {
    result <- did_multiplegt_dyn(
        df = favara_imbs,
        outcome = "Dl_vloans_b",
        group = "county",
        time = "year",
        treatment = "inter_bra",
        effects = 8,
        placebo = 3,
        cluster = "state_n",
        graph_off = TRUE
    )
    return(result)
}

# ============================================================================
# TEST CRAN VERSION
# ============================================================================

cat("\n")
cat("======================================================================\n")
cat("TESTING CRAN VERSION OF DIDmultiplegtDYN\n")
cat("======================================================================\n\n")

# Install CRAN version if not already installed
if (!requireNamespace("DIDmultiplegtDYN", quietly = TRUE)) {
    cat("Installing CRAN version...\n")
    install.packages("DIDmultiplegtDYN")
}

# Load CRAN version
library(DIDmultiplegtDYN)

cat("Running CRAN version...\n")
cran_time <- system.time({
    cran_result <- run_did_test()
})

cat("\nCRAN Version Results:\n")
print(summary(cran_result))

cat("\nCRAN Version Timing:\n")
print(cran_time)

# Store CRAN timing
cran_elapsed <- cran_time["elapsed"]

# Store results for comparison
cran_effects <- cran_result$Effects[, 1]

# Detach CRAN version
detach("package:DIDmultiplegtDYN", unload = TRUE)

# ============================================================================
# TEST OPTIMIZED LOCAL VERSION
# ============================================================================

cat("\n")
cat("======================================================================\n")
cat("TESTING OPTIMIZED LOCAL VERSION OF DIDmultiplegtDYN\n")
cat("======================================================================\n\n")

# Install local version
cat("Installing local optimized version...\n")
install.packages(
    "/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn/DIDmultiplegtDYN_2.2.0.tar.gz",
    repos = NULL,
    type = "source"
)

# Load local version
library(DIDmultiplegtDYN)

cat("Running optimized version...\n")
local_time <- system.time({
    local_result <- run_did_test()
})

cat("\nOptimized Version Results:\n")
print(summary(local_result))

cat("\nOptimized Version Timing:\n")
print(local_time)

# Store local timing
local_elapsed <- local_time["elapsed"]

# ============================================================================
# COMPARISON
# ============================================================================

cat("\n")
cat("======================================================================\n")
cat("PERFORMANCE COMPARISON\n")
cat("======================================================================\n\n")

speedup <- cran_elapsed / local_elapsed

cat(sprintf("CRAN Version Time:      %.2f seconds\n", cran_elapsed))
cat(sprintf("Optimized Version Time: %.2f seconds\n", local_elapsed))
cat(sprintf("Speedup:                %.2fx faster\n", speedup))
cat(sprintf("Time Saved:             %.2f seconds (%.1f%%)\n",
            cran_elapsed - local_elapsed,
            (1 - local_elapsed/cran_elapsed) * 100))

# ============================================================================
# RESULT VALIDATION
# ============================================================================

cat("\n")
cat("======================================================================\n")
cat("RESULT VALIDATION\n")
cat("======================================================================\n\n")

# Compare key results to ensure they match
cat("Comparing effect estimates...\n")

# Extract effects from local result
local_effects <- local_result$Effects[, 1]

# Check if results are numerically equivalent (allowing for small floating point differences)
max_diff <- max(abs(cran_effects - local_effects), na.rm = TRUE)
cat(sprintf("Maximum difference in effect estimates: %.10f\n", max_diff))

if (max_diff < 1e-6) {
    cat("Results MATCH - optimization does not affect numerical results.\n")
} else {
    cat("WARNING: Results differ by more than tolerance.\n")
}

# ============================================================================
# OPTIONAL: MULTIPLE RUNS FOR MORE ACCURATE TIMING
# ============================================================================

cat("\n")
cat("======================================================================\n")
cat("OPTIONAL: RUN MULTIPLE ITERATIONS?\n")
cat("======================================================================\n\n")

cat("To run multiple iterations for more accurate timing, execute:\n\n")
cat("library(microbenchmark)\n")
cat("mb <- microbenchmark(\n")
cat("    optimized = run_did_test(),\n")
cat("    times = 5\n")
cat(")\n")
cat("print(mb)\n")
