# Profiling script to identify performance bottlenecks
# in the Polars-optimized DID multiplegt_dyn package

library(polars)
library(fixest)
library(MASS)
library(data.table)
library(ggplot2)
library(cowplot)

setwd("/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn_polars")

# Source all R files
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) {
  source(f)
}

# Load data
load("data/favara_imbs.RData")

cat("========== PROFILING DID_MULTIPLEGT_DYN PACKAGE ==========\n\n")

# Run profiling
Rprof("profile_output.out", memory.profiling = TRUE, line.profiling = TRUE)

result <- did_multiplegt_dyn(
  df = favara_imbs,
  outcome = "Dl_vloans_b",
  group = "county",
  time = "year",
  treatment = "inter_bra",
  effects = 5,
  placebo = 2,
  trends_lin = TRUE,
  graph_off = TRUE,
  cluster = "state_n"
)

Rprof(NULL)

# Summarize profiling results
cat("\n========== PROFILING SUMMARY ==========\n")
prof_summary <- summaryRprof("profile_output.out", memory = "both")

cat("\n--- TOP 20 TIME-CONSUMING FUNCTIONS (by total time) ---\n")
print(head(prof_summary$by.total, 20))

cat("\n--- TOP 20 TIME-CONSUMING FUNCTIONS (by self time) ---\n")
print(head(prof_summary$by.self, 20))

cat("\n--- SAMPLING TIME ---\n")
print(prof_summary$sampling.time)

# Clean up
file.remove("profile_output.out")

cat("\n========== PROFILING COMPLETE ==========\n")
