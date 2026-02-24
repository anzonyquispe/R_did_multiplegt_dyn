* Comprehensive Benchmark: did_multiplegt_dyn - Stata
* Dataset: wolfers2006_didtextbook.dta
* Specification: did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)

clear all
set more off
log using "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/tests/benchmark_wolfers_stata.log", replace

display "============================================================"
display "BENCHMARK: did_multiplegt_dyn - Stata"
display "============================================================"
display "Date: $S_DATE $S_TIME"
display ""

* Load original data
use "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/wolfers2006_didtextbook.dta", clear
quietly count
local orig_rows = r(N)
display "Original data rows: `orig_rows'"

* ============================================================
* SCENARIO 1: Original Data
* ============================================================
display ""
display "============================================================"
display "SCENARIO 1: Original Data (`orig_rows' rows)"
display "============================================================"
display ""

timer clear 1
timer on 1
did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)
timer off 1
timer list 1
local time_orig = r(t1)
display "Stata time: `time_orig' seconds"

* Save estimates
matrix effects_orig = e(b)
matrix list effects_orig

* ============================================================
* SCENARIO 2: Synthetic Data 100x
* ============================================================
display ""
display "============================================================"
display "SCENARIO 2: Synthetic Data 100x"
display "============================================================"
display ""

* Create 100x synthetic data
use "/Users/anzony.quisperojas/Documents/GitHub/R_didgt_polars/data/wolfers2006_didtextbook.dta", clear
local max_state = 0
quietly summarize state
local max_state = r(max)

tempfile base
save `base'

forvalues i = 2/100 {
    use `base', clear
    replace state = state + (`i' - 1) * `max_state' * 10
    tempfile temp`i'
    save `temp`i''
}

use `base', clear
forvalues i = 2/100 {
    append using `temp`i''
}

quietly count
local rows_100x = r(N)
display "Synthetic data rows: `rows_100x'"

timer clear 2
timer on 2
did_multiplegt_dyn div_rate state year udl, effects(16) placebo(9) weight(stpop)
timer off 2
timer list 2
local time_100x = r(t2)
display "Stata time (100x): `time_100x' seconds"

* ============================================================
* SCENARIO 3: Synthetic Data 10000x (with 1 hour timeout)
* ============================================================
display ""
display "============================================================"
display "SCENARIO 3: Synthetic Data 10000x (1 hour timeout)"
display "============================================================"
display ""

* Note: Creating 10000x data may take significant memory
* This is for reference - may need to run separately

display "Skipping 10000x scenario in Stata due to memory constraints"
display "For 10000x test, run separately with sufficient memory"

* ============================================================
* SUMMARY
* ============================================================
display ""
display "============================================================"
display "SUMMARY OF RESULTS - STATA"
display "============================================================"
display ""
display "Scenario         | Rows      | Time (seconds)"
display "-----------------+-----------+---------------"
display "Original (1.7K)  | `orig_rows'     | `time_orig'"
display "100x (168K)      | `rows_100x'   | `time_100x'"
display "10000x (16.8M)   | -         | (not run)"
display ""

log close
