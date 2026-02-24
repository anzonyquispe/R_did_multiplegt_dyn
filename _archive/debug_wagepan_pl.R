# Debug wagepan placebo variance computation
library(haven)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

options(DID_DEBUG_VARIANCE = TRUE)
options(DID_DEBUG_COUNT = TRUE)

library(DIDmultiplegtDYNpolars)

result <- did_multiplegt_dyn(
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

options(DID_DEBUG_VARIANCE = FALSE)
options(DID_DEBUG_COUNT = FALSE)

cat("\n\nPlacebo results:\n")
print(result$results$Placebos)
