# Print full output for both packages
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
favara <- read_dta(file.path(data_path, "favara_imbs.dta"))

cat("\n", strrep("=", 80), "\n", "CRAN PACKAGE OUTPUT\n", strrep("=", 80), "\n\n", sep="")
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

print(result_cran)

detach("package:DIDmultiplegtDYN", unload = TRUE)

cat("\n\n", strrep("=", 80), "\n", "POLARS PACKAGE OUTPUT\n", strrep("=", 80), "\n\n", sep="")
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

print(result_polars)
