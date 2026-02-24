#!/usr/bin/env python3
"""
Comprehensive Benchmark: did_multiplegt_dyn - Python
Dataset: wolfers2006_didtextbook.dta
Specification: did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)
"""

import pandas as pd
import numpy as np
import time
import sys
from datetime import datetime

# Try to import the Python DID package
try:
    from py_did_multiplegt_dyn import did_multiplegt_dyn
    PYTHON_PACKAGE_AVAILABLE = True
except ImportError:
    print("Warning: py_did_multiplegt_dyn not installed")
    PYTHON_PACKAGE_AVAILABLE = False

# Timeout in seconds (1 hour)
TIMEOUT_SECONDS = 3600

# Log file
log_file = "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_wolfers_python.log"

class Logger:
    def __init__(self, filename):
        self.terminal = sys.stdout
        self.log = open(filename, 'w')

    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)

    def flush(self):
        self.terminal.flush()
        self.log.flush()

sys.stdout = Logger(log_file)

print("=" * 60)
print("BENCHMARK: did_multiplegt_dyn - Python")
print("=" * 60)
print(f"Date: {datetime.now()}")
print()

# Load original data
print("Loading data...")
wolfers = pd.read_stata("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/wolfers2006_didtextbook.dta")
print(f"Original data rows: {len(wolfers)}")
print()

def create_synthetic_data(df, multiplier):
    """Create synthetic data by duplicating groups with new IDs."""
    if multiplier == 1:
        return df.copy()

    max_state = df['state'].max()
    dfs = []
    for i in range(multiplier):
        temp_df = df.copy()
        temp_df['state'] = temp_df['state'] + i * max_state * 10
        dfs.append(temp_df)

    return pd.concat(dfs, ignore_index=True)

# Results storage
results = []

if PYTHON_PACKAGE_AVAILABLE:
    # ============================================================
    # SCENARIO 1: Original Data
    # ============================================================
    print()
    print("=" * 60)
    print(f"SCENARIO 1: Original Data ({len(wolfers)} rows)")
    print("=" * 60)
    print()

    print("Running Python...")
    try:
        start_time = time.time()
        res_orig = did_multiplegt_dyn(
            df=wolfers,
            outcome="div_rate",
            group="state",
            time="year",
            treatment="udl",
            effects=16,
            placebo=9,
            weight="stpop"
        )
        elapsed = time.time() - start_time
        print(f"Python: {elapsed:.2f} seconds")
        results.append({
            'scenario': 'Original (1.7K)',
            'package': 'Python',
            'rows': len(wolfers),
            'time_seconds': elapsed,
            'status': 'completed'
        })
    except Exception as e:
        print(f"Python: error - {str(e)}")
        results.append({
            'scenario': 'Original (1.7K)',
            'package': 'Python',
            'rows': len(wolfers),
            'time_seconds': None,
            'status': f'error: {str(e)}'
        })

    # ============================================================
    # SCENARIO 2: Synthetic Data 100x
    # ============================================================
    print()
    print("=" * 60)
    print("SCENARIO 2: Synthetic Data 100x")
    print("=" * 60)
    print()

    wolfers_100x = create_synthetic_data(wolfers, 100)
    print(f"Synthetic data rows: {len(wolfers_100x)}")

    print("Running Python...")
    try:
        start_time = time.time()
        res_100x = did_multiplegt_dyn(
            df=wolfers_100x,
            outcome="div_rate",
            group="state",
            time="year",
            treatment="udl",
            effects=16,
            placebo=9,
            weight="stpop"
        )
        elapsed = time.time() - start_time
        print(f"Python: {elapsed:.2f} seconds")
        results.append({
            'scenario': '100x (168K)',
            'package': 'Python',
            'rows': len(wolfers_100x),
            'time_seconds': elapsed,
            'status': 'completed'
        })
    except Exception as e:
        print(f"Python: error - {str(e)}")
        results.append({
            'scenario': '100x (168K)',
            'package': 'Python',
            'rows': len(wolfers_100x),
            'time_seconds': None,
            'status': f'error: {str(e)}'
        })

    del wolfers_100x

    # ============================================================
    # SCENARIO 3: Synthetic Data 10000x
    # ============================================================
    print()
    print("=" * 60)
    print("SCENARIO 3: Synthetic Data 10000x (1 hour timeout)")
    print("=" * 60)
    print()

    wolfers_10000x = create_synthetic_data(wolfers, 10000)
    print(f"Synthetic data rows: {len(wolfers_10000x)}")

    print("Running Python...")
    try:
        start_time = time.time()
        res_10000x = did_multiplegt_dyn(
            df=wolfers_10000x,
            outcome="div_rate",
            group="state",
            time="year",
            treatment="udl",
            effects=16,
            placebo=9,
            weight="stpop"
        )
        elapsed = time.time() - start_time
        if elapsed > TIMEOUT_SECONDS:
            status = ">= 1 hour"
        else:
            status = "completed"
        print(f"Python: {elapsed:.2f} seconds")
        results.append({
            'scenario': '10000x (16.8M)',
            'package': 'Python',
            'rows': len(wolfers_10000x),
            'time_seconds': elapsed if elapsed <= TIMEOUT_SECONDS else None,
            'status': status
        })
    except MemoryError:
        print("Python: memory error")
        results.append({
            'scenario': '10000x (16.8M)',
            'package': 'Python',
            'rows': len(wolfers_10000x),
            'time_seconds': None,
            'status': 'memory error'
        })
    except Exception as e:
        print(f"Python: error - {str(e)}")
        results.append({
            'scenario': '10000x (16.8M)',
            'package': 'Python',
            'rows': len(wolfers_10000x),
            'time_seconds': None,
            'status': f'error: {str(e)}'
        })

    del wolfers_10000x

else:
    print("py_did_multiplegt_dyn package not available - skipping Python benchmarks")

# ============================================================
# SUMMARY
# ============================================================
print()
print("=" * 60)
print("SUMMARY OF RESULTS - PYTHON")
print("=" * 60)
print()

results_df = pd.DataFrame(results)
print(results_df.to_string(index=False))

# Save results
results_df.to_csv("/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_results_python.csv", index=False)

print()
print(f"Benchmark completed at: {datetime.now()}")
