# DIDmultiplegtDYN Optimization Changelog

This document summarizes all performance optimizations applied to the R package.

## Overview

The optimizations focus on:
1. Replacing inefficient base R operations with data.table equivalents
2. Replacing `ifelse()` with `fifelse()` for type-stable, faster conditionals
3. Replacing loops with vectorized operations
4. Adding C++ implementations for critical computational loops
5. Removing unnecessary package dependencies

---

## New Files Created

### `src/did_loops.cpp`

C++ implementations for performance-critical loops using Rcpp:

| Function | Description |
|----------|-------------|
| `cummax_by_group_cpp()` | Cumulative maximum within groups |
| `compute_var_covar_matrix_cpp()` | Variance-covariance matrix computation |
| `compute_U_Gg_global_cpp()` | Weighted combination of U_Gg values |
| `compute_clustered_variance_cpp()` | Clustered variance computation |
| `propagate_treatment_change_cpp()` | Propagate treatment change flag within groups |
| `initialize_effect_columns_cpp()` | Pre-allocate matrix for effect columns |
| `compute_weighted_sum_cpp()` | Weighted sum with mask handling |
| `compute_delta_D_g_cpp()` | Delta_D_g computation |
| `compute_full_vcov_cpp()` | Full variance-covariance matrix for effects and placebos |

### `R/cpp_helpers.R`

R wrapper functions for the C++ implementations:

| Function | Description |
|----------|-------------|
| `propagate_ever_change_cpp_wrapper()` | Wrapper for treatment change propagation |
| `compute_vcov_effects_cpp_wrapper()` | Wrapper for variance-covariance computation |
| `compute_clustered_var_wrapper()` | Wrapper for clustered variance |
| `compute_U_Gg_global_wrapper()` | Wrapper for weighted U_Gg computation |

---

## Modified Files

### `DESCRIPTION`

**Changes:**
- Removed `plm` from Imports
- Added `Rcpp` to Imports
- Added `LinkingTo: Rcpp`

---

### `R/did_multiplegt_main.R`

#### 1. Loop Replacement with `cummax()`
**Before:**
```r
for (i in 2:T_XX) {
    df$ever_change_d_XX <- ifelse(df$time_XX == i & lag(df$ever_change_d_XX) == 1, 1, df$ever_change_d_XX)
}
```
**After:**
```r
setorder(df, group_XX, time_XX)
df[, ever_change_d_XX := as.integer(cummax(as.integer(ever_change_d_XX))), by = group_XX]
```

#### 2. Panel Balancing - `plm::make.pbalanced()` → `CJ()` + `merge()`
**Before:**
```r
df <- plm::make.pbalanced(df, balance.type = "fill", index = c("group_XX", "time_XX"))
```
**After:**
```r
all_groups <- unique(df$group_XX)
all_times <- unique(df$time_XX)
grid <- CJ(group_XX = all_groups, time_XX = all_times)
df <- merge(grid, df, by = c("group_XX", "time_XX"), all.x = TRUE)
```

#### 3. Differencing - `plm::diff()` → `shift()`
**Before:**
```r
df$diff_y_XX <- plm::diff(df$outcome_XX, 1)
df$diff_d_XX <- plm::diff(df$treatment_XX, 1)
```
**After:**
```r
df[, diff_y_XX := outcome_XX - shift(outcome_XX), by = group_XX]
df[, diff_d_XX := treatment_XX - shift(treatment_XX), by = group_XX]
```

#### 4. `ifelse()` → `fifelse()` (~50+ replacements)
**Before:**
```r
df$var <- ifelse(condition, value1, value2)
```
**After:**
```r
df$var <- fifelse(condition, value1, value2)
```

#### 5. `subset()` → data.table `[]` filtering
**Before:**
```r
het_sample <- subset(df, df$condition == TRUE)
```
**After:**
```r
het_sample <- df[condition == TRUE]
```

#### 6. `order()` → `setorder()`
**Before:**
```r
df <- df[order(df$group_XX, df$time_XX), ]
```
**After:**
```r
setorder(df, group_XX, time_XX)
```

#### 7. Batch Column Creation with `set()`
**Before:**
```r
for (i in 1:l_XX) {
    df[[paste0("U_Gg", i, "_plus_XX")]] <- 0
    # ... many more
}
```
**After:**
```r
effect_cols <- c(paste0("U_Gg", 1:l_XX, "_plus_XX"), ...)
for (col in effect_cols) set(df, j = col, value = 0)
```

#### 8. Removed Redundant `data.table()` Conversions
**Before:**
```r
df <- data.table(df)  # when df is already data.table
```
**After:** Removed unnecessary conversions

---

### `R/did_multiplegt_dyn_core.R`

#### 1. Removed Redundant `as.data.table()` and Replaced `order()`
**Before:**
```r
df <- as.data.table(df)
df <- df[order(df$group_XX, df$time_XX), ]
```
**After:**
```r
setorder(df, group_XX, time_XX)
```

#### 2. `ifelse()` → `fifelse()` (~48 replacements)
All active `ifelse()` calls replaced with `fifelse()` for:
- Type stability
- Better performance with data.table
- Proper NA handling

#### 3. `dplyr::lag()` → `data.table::shift()`
**Before:**
```r
df[[paste0("diff_X",count_controls,"_", i, "_XX")]] <- df[[var]] - lag(df[[var]], i)
```
**After:**
```r
df[, paste0("diff_X",count_controls,"_", i, "_XX") := get(var) - shift(get(var), i), by = group_XX]
```

#### 4. Vectorized N Computation Loops
**Before:**
```r
assign(paste0("N",increase_XX,"_",i,"_XX"), 0)
for (t in t_min_XX:T_max_XX) {
    assign(paste0("N",increase_XX,"_",i,"_XX"),
        get(paste0("N",increase_XX,"_",i,"_XX")) +
        mean(df[[paste0("N", increase_XX,"_t_", i, "_XX")]][df$time_XX == t], na.rm = TRUE))
}
```
**After:**
```r
N_col <- paste0("N", increase_XX, "_t_", i, "_XX")
assign(paste0("N",increase_XX,"_",i,"_XX"),
    df[time_XX >= t_min_XX & time_XX <= T_max_XX,
       .(m = mean(get(N_col), na.rm = TRUE)), by = time_XX][, sum(m, na.rm = TRUE)])
```

#### 5. Updated Imports
**Before:**
```r
#' @importFrom dplyr lag n_distinct
```
**After:**
```r
#' @importFrom dplyr n_distinct
```

---

### `R/did_multiplegt_bootstrap.R`

#### 1. `list_to_vec()` - O(n²) → O(n)
**Before:**
```r
list_to_vec <- function(lis) {
    vec <- c()
    for (j in 1:length(lis)) {
        for (i in 1:length(lis[[j]])) {
            vec <- c(vec, lis[[j]][[i]])
        }
    }
    return(vec)
}
```
**After:**
```r
list_to_vec <- function(lis) {
    unlist(lis, use.names = FALSE)
}
```

#### 2. `xtset` Creation - Loop with `subset()` → `split()`
**Before:**
```r
bdf <- data.frame(cbind(df[[bs_group]], 1:nrow(df)))
colnames(bdf) <- c(bs_group, "id")
xtset <- list()
for (l in levels(factor(bdf[[bs_group]]))) {
    xtset[[l]] <- subset(bdf, bdf[[bs_group]] == l)[["id"]]
}
```
**After:**
```r
row_ids <- seq_len(nrow(df))
xtset <- split(row_ids, df[[bs_group]])
```

#### 3. Data Sorting - `order()` → `setorderv()`
**Before:**
```r
df_boot <- df_boot[order(df_boot[[group]], df_boot[[time]]), ]
```
**After:**
```r
if (is.data.table(df_boot)) {
    setorderv(df_boot, c(group_col, time_col))
} else {
    setDT(df_boot)
    setorderv(df_boot, c(group_col, time_col))
}
```

#### 4. Vectorized Result Extraction
**Before:**
```r
for (i in 1:ncol(bresults_effects)) {
    if (i <= nrow(res$Effects)) {
        bresults_effects[j,i] <- res$Effects[i,1]
    }
}
```
**After:**
```r
n_res_effects <- nrow(res$Effects)
if (n_res_effects > 0) {
    n_copy <- min(ncol(bresults_effects), n_res_effects)
    bresults_effects[j, 1:n_copy] <- res$Effects[1:n_copy, 1]
}
```

#### 5. Vectorized SE Computation
**Before:**
```r
for (i in 1:ncol(bresults_effects)) {
    if (!is.null(base$Effects[i,1])) {
        base$Effects[i,2] <- sd(bresults_effects[,i], na.rm = TRUE)
        base$Effects[i,3] <- base$Effects[i,1] - z_level * base$Effects[i,2]
        base$Effects[i,4] <- base$Effects[i,1] + z_level * base$Effects[i,2]
    }
}
```
**After:**
```r
effect_sds <- apply(bresults_effects, 2, sd, na.rm = TRUE)
n_eff <- nrow(base$Effects)
base$Effects[1:n_eff, 2] <- effect_sds[1:n_eff]
base$Effects[1:n_eff, 3] <- base$Effects[1:n_eff, 1] - z_level * base$Effects[1:n_eff, 2]
base$Effects[1:n_eff, 4] <- base$Effects[1:n_eff, 1] + z_level * base$Effects[1:n_eff, 2]
```

#### 6. Replaced `ifelse()` with `if/else`
**Before:**
```r
bs_group <- ifelse(!is.null(cluster), cluster, group)
```
**After:**
```r
bs_group <- if (!is.null(cluster)) cluster else group
```

---

## Performance Impact Summary

| Optimization | Expected Speedup | Files Affected |
|--------------|------------------|----------------|
| `list_to_vec()` with `unlist()` | 10-100x | bootstrap |
| `split()` vs loop+`subset()` | 5-20x | bootstrap |
| `fifelse()` vs `ifelse()` | 2-5x | main, core |
| `setorder()` vs `order()` | 2-3x | all files |
| `shift()` vs `lag()` | 2-3x | core |
| Vectorized loops | 2-10x | all files |
| `CJ()` + `merge()` vs `plm` | 2-5x | main |
| C++ variance computation | 5-20x | main (via cpp_helpers) |

---

## Dependencies Changed

### Removed
- `plm` - replaced with pure data.table operations

### Added
- `Rcpp` - for C++ integration

---

## Future Optimization Opportunities

1. **Parallel Bootstrap**: Add optional parallel processing using `parallel::mclapply()` or `future.apply::future_lapply()` for bootstrap iterations

2. **Additional C++ Functions**: Move more computationally intensive loops to C++

3. **Memory Optimization**: Use in-place modifications more extensively to reduce memory allocations
