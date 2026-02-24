# Debug placebo variance sum computation
library(haven)
library(data.table)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

# First run without controls to get baseline
cat("=== WITHOUT CONTROLS ===\n")
library(DIDmultiplegtDYNpolars)

result_no_ctrl <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  graph_off = TRUE
)

cat("Placebo 1 SE (no controls):", result_no_ctrl$results$Placebos[1, "SE"], "\n")
cat("Placebo 2 SE (no controls):", result_no_ctrl$results$Placebos[2, "SE"], "\n")

# Compute implied var_sum from SE: var_sum = (SE * G)^2
# We need G (number of groups)
G <- length(unique(wagepan$nr))
cat("G (groups):", G, "\n")

var_sum_pl1_no <- (result_no_ctrl$results$Placebos[1, "SE"] * G)^2
var_sum_pl2_no <- (result_no_ctrl$results$Placebos[2, "SE"] * G)^2
cat("Implied var_sum Placebo 1:", var_sum_pl1_no, "\n")
cat("Implied var_sum Placebo 2:", var_sum_pl2_no, "\n")

cat("\n=== WITH CONTROLS ===\n")
result_ctrl <- did_multiplegt_dyn(
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

cat("Placebo 1 SE (with controls):", result_ctrl$results$Placebos[1, "SE"], "\n")
cat("Placebo 2 SE (with controls):", result_ctrl$results$Placebos[2, "SE"], "\n")

# After controls, some groups might be filtered out
# Check number of groups in the result
var_sum_pl1_ctrl <- (result_ctrl$results$Placebos[1, "SE"] * G)^2
var_sum_pl2_ctrl <- (result_ctrl$results$Placebos[2, "SE"] * G)^2
cat("Implied var_sum Placebo 1:", var_sum_pl1_ctrl, "\n")
cat("Implied var_sum Placebo 2:", var_sum_pl2_ctrl, "\n")

cat("\n=== CRAN WITH CONTROLS ===\n")
detach("package:DIDmultiplegtDYNpolars", unload = TRUE)
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

cat("CRAN Placebo 1 SE:", result_cran$results$Placebos[1, "SE"], "\n")
cat("CRAN Placebo 2 SE:", result_cran$results$Placebos[2, "SE"], "\n")

var_sum_pl1_cran <- (result_cran$results$Placebos[1, "SE"] * G)^2
var_sum_pl2_cran <- (result_cran$results$Placebos[2, "SE"] * G)^2
cat("CRAN Implied var_sum Placebo 1:", var_sum_pl1_cran, "\n")
cat("CRAN Implied var_sum Placebo 2:", var_sum_pl2_cran, "\n")

cat("\n=== COMPARISON ===\n")
cat("Placebo 1 var_sum ratio (Polars/CRAN):", var_sum_pl1_ctrl / var_sum_pl1_cran, "\n")
cat("Placebo 2 var_sum ratio (Polars/CRAN):", var_sum_pl2_ctrl / var_sum_pl2_cran, "\n")
cat("Placebo 1 SE ratio:", result_ctrl$results$Placebos[1, "SE"] / result_cran$results$Placebos[1, "SE"], "\n")
cat("Placebo 2 SE ratio:", result_ctrl$results$Placebos[2, "SE"] / result_cran$results$Placebos[2, "SE"], "\n")
