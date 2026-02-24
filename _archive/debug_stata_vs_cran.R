# Debug script to compare CRAN R and Stata SE computation
library(haven)
library(data.table)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

cat("================================================================================\n")
cat("Comparing Stata vs CRAN R for placebo SEs with controls\n")
cat("================================================================================\n\n")

# Stata outputs (from user):
# Placebo_1 SE: 0.0417436
# Placebo_2 SE: 0.0586136

# Run CRAN to get detailed output
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

cat("CRAN Placebo SEs:\n")
cat("Placebo 1:", result_cran$results$Placebos[1, "SE"], "\n")
cat("Placebo 2:", result_cran$results$Placebos[2, "SE"], "\n")

cat("\nStata Placebo SEs (from user):\n")
cat("Placebo 1: 0.0417436\n")
cat("Placebo 2: 0.0586136\n")

cat("\nRatios (CRAN/Stata):\n")
cat("Placebo 1:", result_cran$results$Placebos[1, "SE"] / 0.0417436, "\n")
cat("Placebo 2:", result_cran$results$Placebos[2, "SE"] / 0.0586136, "\n")

cat("\nVariance Ratios (CRAN/Stata):\n")
cat("Placebo 1:", (result_cran$results$Placebos[1, "SE"] / 0.0417436)^2, "\n")
cat("Placebo 2:", (result_cran$results$Placebos[2, "SE"] / 0.0586136)^2, "\n")

# G is number of unique groups
G <- length(unique(wagepan$nr))
cat("\nG (number of groups):", G, "\n")

# Implied variance sum from SE
# SE = sqrt(var_sum) / G  =>  var_sum = (SE * G)^2
var_sum_cran_pl1 <- (result_cran$results$Placebos[1, "SE"] * G)^2
var_sum_cran_pl2 <- (result_cran$results$Placebos[2, "SE"] * G)^2
var_sum_stata_pl1 <- (0.0417436 * G)^2
var_sum_stata_pl2 <- (0.0586136 * G)^2

cat("\nImplied variance sums:\n")
cat("CRAN Placebo 1:", var_sum_cran_pl1, "\n")
cat("CRAN Placebo 2:", var_sum_cran_pl2, "\n")
cat("Stata Placebo 1:", var_sum_stata_pl1, "\n")
cat("Stata Placebo 2:", var_sum_stata_pl2, "\n")

cat("\nDifference in variance sum:\n")
cat("Placebo 1 diff:", var_sum_cran_pl1 - var_sum_stata_pl1, "\n")
cat("Placebo 2 diff:", var_sum_cran_pl2 - var_sum_stata_pl2, "\n")
