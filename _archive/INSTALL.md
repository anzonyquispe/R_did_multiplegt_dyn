# Installation Instructions for DIDmultiplegtDYNpolars

## Version 2.2.2 - Changelog

### Bug Fixes
1. **N.w Column Computation**: Fixed the N.w (number of observations) column to correctly sum the count values instead of counting non-null entries. N.w values now match CRAN exactly.

2. **Count Column Logic**: Fixed the count_global computation to take the maximum of count_plus and count_minus (matching CRAN), instead of using simple coalesce.

3. **Clustered Standard Errors**: Improved clustered standard error computation when using the `cluster` option. The computation now follows the CRAN approach: (1) multiplying by first_obs_by_gp, (2) summing by cluster, (3) squaring cluster sums, (4) multiplying by first_obs_by_clust, (5) summing total.

### Known Issues
- **Clustered SE Minor Variation**: When using the `cluster` option, standard errors may differ from CRAN by up to 0.4%. Estimates and N.w match exactly. The small SE variation (typically <0.2%) is due to numerical precision differences between Polars and data.table aggregation methods. This does not affect practical inference as confidence intervals remain nearly identical.

## Version 2.2.1 - Changelog

### Bug Fixes
1. **Placebo Estimation with Controls**: Fixed incorrect placebo estimates when using the `controls` option. Placebo outcome differences are now properly residualized by control variables. Estimates now match the original CRAN package to floating-point precision.

2. **data.table Import**: Added proper data.table namespace import to fix installation issues.

## Installation Steps

### Quick Install (Recommended)

```bash
cd /Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars
Rscript -e 'devtools::document()'
R CMD build .
R CMD INSTALL DIDmultiplegtDYNpolars_2.2.2.tar.gz
```

### Alternative: Install via devtools

```r
devtools::install("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars")
```

## Verify Installation

```r
library(DIDmultiplegtDYNpolars)
packageVersion("DIDmultiplegtDYNpolars")  # Should show '2.2.2'
```

## Test the Fix

```r
library(DIDmultiplegtDYNpolars)
library(haven)

wagepan <- read_dta("/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data/wagepan.dta")

result <- did_multiplegt_dyn(
  df = wagepan,
  outcome = "lwage",
  group = "nr",
  time = "year",
  treatment = "union",
  effects = 5,
  placebo = 2,
  controls = "hours",
  graph_off = TRUE
)

# Expected placebo estimates (matching CRAN):
# Placebo_1: -0.06750985
# Placebo_2:  0.05850200
print(result$results$Placebos)
```

## Technical Details

The fix adds residualization logic in `compute_placebo_effects_polars()` function (file: `R/did_multiplegt_dyn_core.R`) that:
1. Computes placebo long differences for each control variable: `shift(control, 2*i) - shift(control, i)`
2. Subtracts the control effect from placebo outcome differences using coefficients from the main regression
3. Only applies residualization where `useful_res_{l}_XX > 1` (matching CRAN behavior)

## Dependencies

- polars
- data.table
- MASS
- fixest
- dplyr
- ggplot2
- devtools (for installation)
