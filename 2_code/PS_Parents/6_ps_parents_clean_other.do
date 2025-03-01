********************************************************************************
* 6_ps_parents_clean_other.do
*
* Purpose:
* - Clean “other” free-text responses in the PS Parents dataset (e.g., plan, etc.).
* - Remove line breaks, trim whitespace, etc.
* - Save intermediate dataset for subsequent steps.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/6_ps_parents_clean_other.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_clean_motivations.dta", clear
di as txt "Loaded ps_par_clean_motivations.dta: `c(N)' obs"

********************************************************************************
* 2. CLEAN FREE-TEXT FIELDS
********************************************************************************

* Example: plan or plan_6_TEXT
capture confirm variable plan
if !_rc {
    * If plan is string, remove line breaks
    replace plan = subinstr(plan, char(10), " ", .)
    replace plan = strtrim(plan)
    replace plan = stritrim(plan)
}

********************************************************************************
* 3. SAVE INTERMEDIATE
********************************************************************************

compress
save "${processed_data}/PS_Parents/temp_par_clean_other.dta", replace

timer off 1
timer list
log close
