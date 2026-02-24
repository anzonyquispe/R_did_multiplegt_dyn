# Debug placebo residualization with controls
library(haven)
library(data.table)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))

# Check data completeness for controls
cat("=== Data Completeness ===\n")
cat("Total rows:", nrow(wagepan), "\n")
cat("NA in lwage:", sum(is.na(wagepan$lwage)), "\n")
cat("NA in hours:", sum(is.na(wagepan$hours)), "\n")
cat("NA in union:", sum(is.na(wagepan$union)), "\n")

# Create panel-like data to check shift operations
wagepan_dt <- as.data.table(wagepan)
setorder(wagepan_dt, nr, year)

# Check shifts for a sample group
sample_nr <- wagepan_dt[!is.na(lwage) & !is.na(hours)]$nr[1]
sample_data <- wagepan_dt[nr == sample_nr, .(year, lwage, hours, union)]
cat("\nSample group", sample_nr, ":\n")
print(sample_data)

# For placebo 1, we need outcome at t-2 and t-1 (shifts of 2 and 1)
# Check how many groups have complete data for placebo shifts
wagepan_dt[, outcome_shift1 := shift(lwage, 1), by = nr]
wagepan_dt[, outcome_shift2 := shift(lwage, 2), by = nr]
wagepan_dt[, hours_shift1 := shift(hours, 1), by = nr]
wagepan_dt[, hours_shift2 := shift(hours, 2), by = nr]

wagepan_dt[, diff_y_pl_1 := outcome_shift2 - outcome_shift1]
wagepan_dt[, diff_X_pl_1 := hours_shift2 - hours_shift1]

cat("\n=== Placebo 1 Data Completeness ===\n")
cat("diff_y_pl_1 non-NA:", sum(!is.na(wagepan_dt$diff_y_pl_1)), "\n")
cat("diff_X_pl_1 non-NA:", sum(!is.na(wagepan_dt$diff_X_pl_1)), "\n")
cat("Both non-NA:", sum(!is.na(wagepan_dt$diff_y_pl_1) & !is.na(wagepan_dt$diff_X_pl_1)), "\n")

# Check for cases where diff_y_pl_1 is not NA but diff_X_pl_1 is NA
cat("\ndiff_y_pl_1 not NA but diff_X_pl_1 is NA:",
    sum(!is.na(wagepan_dt$diff_y_pl_1) & is.na(wagepan_dt$diff_X_pl_1)), "\n")

# This could cause issues: residualization would produce NA for these rows
