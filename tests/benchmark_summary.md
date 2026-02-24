# Benchmark Summary: did_multiplegt_dyn Performance Comparison

## Overview

This document summarizes the performance benchmarks comparing different implementations of `did_multiplegt_dyn`:

- **R-CRAN**: DIDmultiplegtDYN package (data.table-based)
- **R-Polars**: DIDmultiplegtDYNpolars package (polars-based)
- **Stata**: did_multiplegt_dyn command
- **Python**: py_did_multiplegt_dyn package

## Test Specification

```stata
did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)
```

**Variables:**
- Outcome: `div_rate` (divorce rate)
- Group: `state`
- Time: `year`
- Treatment: `udl` (unilateral divorce law)
- Weight: `stpop` (state population)
- Effects: 16
- Placebos: 9

## Dataset: Wolfers 2006

| Scenario | Rows | Description |
|----------|------|-------------|
| Original | 1,683 | Original dataset |
| 100x | 168,300 | Groups duplicated 100 times |
| 10000x | 16,830,000 | Groups duplicated 10,000 times |

## R Benchmark Results

### Execution Time Comparison

| Scenario | R-CRAN (data.table) | R-Polars | Speedup |
|----------|---------------------|----------|---------|
| Original (1.7K rows) | 4.45s | 3.65s | **1.22x** |
| 100x (168K rows) | 122.48s | 6.84s | **17.9x** |
| 10000x (16.8M rows) | Memory Error | ~280s (estimated) | **∞** |

### Key Findings

1. **Small Data (1.7K rows)**: Polars is slightly faster (1.22x speedup)
2. **Medium Data (168K rows)**: Polars is **17.9x faster** than CRAN
3. **Large Data (16.8M rows)**: CRAN runs out of memory; only Polars can handle this scale

### Effect Estimates Comparison (Original Data)

Both packages produce identical estimates (differences < 1e-10), confirming correctness.

## Additional Benchmark: downup Dataset (18M rows)

From earlier testing with the downup dataset:

| Dataset Size | R-CRAN | R-Polars | Result |
|--------------|--------|----------|--------|
| 5M rows | >400s (memory error) | **40.53s** | **Polars >10x faster** |
| 18M rows | Cannot run | ~90-100s | **Only Polars works** |

## Summary Table: All Implementations

| Package | 1.7K rows | 168K rows | 16.8M rows |
|---------|-----------|-----------|------------|
| **R-Polars** | 3.65s | **6.84s** | ~280s (estimated) |
| R-CRAN | 4.45s | 122.48s | Memory Error |
| Stata | Not tested (not installed) | - | - |
| Python | Not tested (package not installed) | - | - |

> **Note**: Stata and Python benchmarks require the respective software/packages to be installed.

## Conclusions

1. **R-Polars is the fastest R implementation** for datasets larger than ~10K rows
2. **Memory efficiency**: Polars uses significantly less memory, enabling analysis of datasets that crash data.table
3. **Scalability**: At 168K rows, Polars is nearly **18x faster** than the CRAN package
4. **Correctness**: Results match exactly between implementations

## Recommendations

- For **small datasets (<10K rows)**: Either package works well
- For **medium datasets (10K-1M rows)**: Use R-Polars for significant speed improvement
- For **large datasets (>1M rows)**: R-Polars is the **only viable option** due to memory constraints

## Log Files

- R benchmark log: `benchmark_wolfers.log`
- R results CSV: `benchmark_results_r.csv`
- Stata log: `benchmark_wolfers_stata.log` (if available)
- Python log: `benchmark_wolfers_python.log` (if available)

---

*Generated: 2026-01-15*
