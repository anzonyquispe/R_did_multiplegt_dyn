# Task: Create 4 Optimized Versions of did_multiplegt_dyn Package

## Project Information
- **Main Package Path**: `/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn`
- **Source Code**: `/Users/anzony.quisperojas/Documents/GitHub/R_did_multiplegt_dyn/R`
- **Package**: Difference-in-differences estimator with dynamic effects
- **Main Issue**: Many loops generating new columns, causing performance bottlenecks

## Objective
Create 4 complete, working R packages, each using a different backend for data manipulation:
1. **DuckDB version** (`did.multiplegt.dyn.duckdb`)
2. **Polars version** (`did.multiplegt.dyn.polars`)
3. **Arrow version** (`did.multiplegt.dyn.arrow`)
4. **Optimized data.table + Rcpp version** (`did.multiplegt.dyn.fast`)

All versions must:
- Maintain identical API and outputs to the original package
- Be installable R packages with proper NAMESPACE, DESCRIPTION, documentation
- Include all original functionality
- Pass all tests (create tests if they don't exist)

## Project Structure to Create
```
R_did_multiplegt_dyn/
├── original/                          # Backup of original code
│   └── R/
├── optimized_versions/
│   ├── did.multiplegt.dyn.duckdb/    # Version 1: DuckDB
│   │   ├── DESCRIPTION
│   │   ├── NAMESPACE
│   │   ├── R/
│   │   │   ├── main_functions.R
│   │   │   ├── helper_functions.R
│   │   │   └── ...
│   │   ├── man/
│   │   └── tests/
│   │
│   ├── did.multiplegt.dyn.polars/    # Version 2: Polars
│   │   ├── DESCRIPTION
│   │   ├── NAMESPACE
│   │   ├── R/
│   │   ├── man/
│   │   └── tests/
│   │
│   ├── did.multiplegt.dyn.arrow/     # Version 3: Arrow
│   │   ├── DESCRIPTION
│   │   ├── NAMESPACE
│   │   ├── R/
│   │   ├── man/
│   │   └── tests/
│   │
│   └── did.multiplegt.dyn.fast/      # Version 4: data.table + Rcpp
│       ├── DESCRIPTION
│       ├── NAMESPACE
│       ├── R/
│       ├── src/                       # C++ code here
│       │   ├── loop_optimization.cpp
│       │   ├── column_generation.cpp
│       │   └── RcppExports.cpp
│       ├── man/
│       └── tests/
│
├── benchmarks/
│   ├── benchmark_all_versions.R
│   ├── benchmark_results/
│   │   ├── small_dataset.csv
│   │   ├── medium_dataset.csv
│   │   └── large_dataset.csv
│   └── visualize_benchmarks.R
│
├── tests/
│   ├── test_correctness.R            # Verify all versions produce identical results
│   └── test_data/
│
└── docs/
    ├── optimization_report.md
    ├── api_documentation.md
    └── migration_guide.md
```

## Version 1: DuckDB Implementation

### Requirements:
```r
# DESCRIPTION dependencies
Imports:
    DBI,
    duckdb,
    dplyr
```

### Implementation Strategy:
1. Convert all data.table operations to DuckDB queries
2. Use `duckdb_register()` to register data.tables as DuckDB tables
3. Perform all loop-based column generations using SQL window functions
4. Use vectorized SQL operations for aggregations
5. Return results as data.tables for compatibility

### Example Pattern:
```r
# Original (data.table with loops)
for(i in 1:n_periods) {
  dt[, paste0("lag_", i) := shift(outcome, i), by = id]
}

# DuckDB version
con <- dbConnect(duckdb::duckdb())
duckdb_register(con, "dt", dt)

result <- dbGetQuery(con, "
  SELECT *,
    LAG(outcome, 1) OVER (PARTITION BY id ORDER BY time) as lag_1,
    LAG(outcome, 2) OVER (PARTITION BY id ORDER BY time) as lag_2,
    ...
  FROM dt
")
dbDisconnect(con)
```

## Version 2: Polars Implementation

### Requirements:
```r
# DESCRIPTION dependencies
Imports:
    polars (>= 0.16.0)
```

### Implementation Strategy:
1. Convert all data.table operations to Polars lazy DataFrames
2. Use `with_columns()` for efficient column generation
3. Utilize lazy evaluation and query optimization
4. Use `group_by()` and `agg()` for grouped operations
5. Call `collect()` only when results are needed

### Example Pattern:
```r
# Original (data.table with loops)
for(i in 1:n_periods) {
  dt[, paste0("lag_", i) := shift(outcome, i), by = id]
}

# Polars version
df_pl <- as_polars_df(dt)$lazy()

lag_exprs <- lapply(1:n_periods, function(i) {
  pl$col("outcome")$shift(i)$over("id")$alias(paste0("lag_", i))
})

result <- df_pl$
  with_columns(lag_exprs)$
  collect()
```

## Version 3: Arrow Implementation

### Requirements:
```r
# DESCRIPTION dependencies
Imports:
    arrow (>= 13.0.0),
    dplyr
```

### Implementation Strategy:
1. Convert data to Arrow Tables
2. Use dplyr verbs with Arrow backend
3. Utilize Arrow's compute functions for window operations
4. Use `to_dplyr()` for dplyr compatibility
5. Collect results with `collect()`

### Example Pattern:
```r
# Original (data.table with loops)
for(i in 1:n_periods) {
  dt[, paste0("lag_", i) := shift(outcome, i), by = id]
}

# Arrow version
df_arrow <- arrow_table(dt)

result <- df_arrow %>%
  group_by(id) %>%
  mutate(
    lag_1 = lag(outcome, 1),
    lag_2 = lag(outcome, 2),
    ...
  ) %>%
  collect()
```

## Version 4: Optimized data.table + Rcpp

### Requirements:
```r
# DESCRIPTION dependencies
Imports:
    data.table (>= 1.14.0),
    Rcpp (>= 1.0.0)
LinkingTo:
    Rcpp,
    RcppArmadillo
```

### Implementation Strategy:
1. Identify all computational bottlenecks (loops, repeated calculations)
2. Write C++ functions for loop-heavy operations
3. Use proper data.table syntax (avoid unnecessary copies)
4. Use `set*` functions for in-place modifications
5. Parallelize where beneficial using OpenMP

### Example Pattern:
```r
# In src/column_generation.cpp
#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
List generate_lags_cpp(NumericVector x, IntegerVector id, int max_lag) {
  int n = x.size();
  List result(max_lag);
  
  for(int lag = 1; lag <= max_lag; lag++) {
    NumericVector lagged(n, NA_REAL);
    
    for(int i = lag; i < n; i++) {
      if(id[i] == id[i - lag]) {
        lagged[i] = x[i - lag];
      }
    }
    
    result[lag - 1] = lagged;
  }
  
  return result;
}

# In R/functions.R
# Use the C++ function
lags <- generate_lags_cpp(dt$outcome, dt$id, n_periods)
for(i in 1:n_periods) {
  dt[, paste0("lag_", i) := lags[[i]]]
}
```

## Critical Requirements for All Versions

### 1. Identical API
All packages must expose the same main functions with identical signatures:
```r
# Main function signature (example - adapt to actual package)
did_multiplegt_dyn(
  df,
  outcome,
  treatment,
  id,
  time,
  controls = NULL,
  ...
)
```

### 2. Identical Outputs
All versions must produce numerically identical results (within floating-point precision):
```r
all.equal(result_original, result_duckdb)
all.equal(result_original, result_polars)
all.equal(result_original, result_arrow)
all.equal(result_original, result_fast)
```

### 3. Proper Package Structure
Each package must have:
- **DESCRIPTION**: Proper dependencies, version, authors
- **NAMESPACE**: Correct exports and imports
- **R/**: All function definitions
- **man/**: Documentation (roxygen2 format)
- **tests/**: Unit tests using testthat
- **README.md**: Installation and usage instructions

## Benchmark Testing Framework

Create `benchmarks/benchmark_all_versions.R`:
```r
library(microbenchmark)
library(ggplot2)
library(data.table)

# Load all package versions
library(did.multiplegt.dyn)           # original
library(did.multiplegt.dyn.duckdb)
library(did.multiplegt.dyn.polars)
library(did.multiplegt.dyn.arrow)
library(did.multiplegt.dyn.fast)

# Generate test datasets
generate_test_data <- function(n_units, n_periods) {
  # Create synthetic panel data
  expand.grid(
    id = 1:n_units,
    time = 1:n_periods
  ) %>%
    mutate(
      treatment = rbinom(n(), 1, 0.3),
      outcome = rnorm(n())
    )
}

# Test scenarios
scenarios <- list(
  small   = list(n_units = 100,   n_periods = 10),
  medium  = list(n_units = 1000,  n_periods = 20),
  large   = list(n_units = 10000, n_periods = 30)
)

# Run benchmarks
results <- list()

for(scenario_name in names(scenarios)) {
  cat(sprintf("\n=== Testing %s dataset ===\n", scenario_name))
  
  data <- generate_test_data(
    scenarios[[scenario_name]]$n_units,
    scenarios[[scenario_name]]$n_periods
  )
  
  # Benchmark
  bench <- microbenchmark(
    original = did_multiplegt_dyn(data, ...),
    duckdb   = did.multiplegt.dyn.duckdb::did_multiplegt_dyn(data, ...),
    polars   = did.multiplegt.dyn.polars::did_multiplegt_dyn(data, ...),
    arrow    = did.multiplegt.dyn.arrow::did_multiplegt_dyn(data, ...),
    fast     = did.multiplegt.dyn.fast::did_multiplegt_dyn(data, ...),
    times = 10,
    unit = "s"
  )
  
  results[[scenario_name]] <- bench
  
  # Print summary
  print(summary(bench))
  
  # Save results
  saveRDS(bench, sprintf("benchmarks/benchmark_results/%s_dataset.rds", scenario_name))
}

# Create comparison visualization
plot_benchmark_results(results)
```

## Correctness Testing

Create `tests/test_correctness.R`:
```r
library(testthat)

test_that("All versions produce identical results", {
  # Generate test data
  data <- generate_test_data(100, 10)
  
  # Run all versions
  result_original <- did_multiplegt_dyn(data, ...)
  result_duckdb   <- did.multiplegt.dyn.duckdb::did_multiplegt_dyn(data, ...)
  result_polars   <- did.multiplegt.dyn.polars::did_multiplegt_dyn(data, ...)
  result_arrow    <- did.multiplegt.dyn.arrow::did_multiplegt_dyn(data, ...)
  result_fast     <- did.multiplegt.dyn.fast::did_multiplegt_dyn(data, ...)
  
  # Test equality
  expect_equal(result_original, result_duckdb, tolerance = 1e-10)
  expect_equal(result_original, result_polars, tolerance = 1e-10)
  expect_equal(result_original, result_arrow, tolerance = 1e-10)
  expect_equal(result_original, result_fast, tolerance = 1e-10)
})
```

## Documentation Requirements

### optimization_report.md
Include:
1. **Overview**: What was optimized and why
2. **Approach**: How each version differs
3. **Performance Results**: Benchmark comparisons with charts
4. **Memory Usage**: Memory profiling results
5. **Trade-offs**: Pros/cons of each approach
6. **Recommendations**: Which version to use when

### migration_guide.md
Include:
1. How to install each version
2. Code examples showing API usage
3. Migration steps from original package
4. Troubleshooting common issues

## Installation Testing

Create `tests/test_installation.R`:
```r
# Test that all packages can be installed and loaded
test_packages <- c(
  "did.multiplegt.dyn.duckdb",
  "did.multiplegt.dyn.polars",
  "did.multiplegt.dyn.arrow",
  "did.multiplegt.dyn.fast"
)

for(pkg in test_packages) {
  cat(sprintf("Testing %s...\n", pkg))
  
  # Install from local source
  devtools::install(sprintf("optimized_versions/%s", pkg))
  
  # Load package
  library(pkg, character.only = TRUE)
  
  # Test main function exists
  expect_true(exists("did_multiplegt_dyn"))
  
  # Unload
  detach(sprintf("package:%s", pkg), character.only = TRUE, unload = TRUE)
}
```

## Performance Expectations

Target speedups compared to original:
- **DuckDB**: 3-10x faster (especially for large aggregations)
- **Polars**: 5-15x faster (especially for column generation)
- **Arrow**: 3-8x faster (especially for I/O operations)
- **data.table + Rcpp**: 10-50x faster (especially for loops)

## Deliverables Checklist

- [ ] 4 complete, installable R packages
- [ ] All packages pass R CMD check
- [ ] Benchmark framework with results
- [ ] Correctness tests showing identical outputs
- [ ] Documentation for each package
- [ ] Optimization report with recommendations
- [ ] Migration guide
- [ ] README with quick start guide

## Notes
- Preserve all original functionality
- Maintain backward compatibility
- Add error handling and input validation
- Include examples in documentation
- Create vignettes showing usage examples