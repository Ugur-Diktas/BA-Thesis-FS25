********************************************************************************
* 7_ps_parents_clean_parent_occs.do
*
* Purpose:
* - Clean the parent's own occupation text (if any) in the PS Parents dataset.
* - Attempt preliminary occupation coding or string matching.
* - Export uncleaned entries to Excel for manual review.
* - Merge cleaned suggestions back in.
* - Save updated dataset.
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
log using "${dodir_log}/7_ps_parents_clean_parent_occs.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD DATA
********************************************************************************

use "${processed_data}/PS_Parents/temp_par_clean_other.dta", clear
di as txt "Loaded temp_par_clean_other.dta: `c(N)' obs"

********************************************************************************
* 2. PRELIMINARY OCCUPATION CODING (EXAMPLE)
********************************************************************************

* If you have a variable like parent_occ or plan that stores parent's own job
* Example:
capture confirm variable mother_pref_occ_1
if !_rc {
    di as txt "No mother_pref_occ_1 found, skipping occupation cleaning..."
}
else {
    * Possibly rename mother_pref_occ_1 -> mother_occ, etc.
}

********************************************************************************
* 3. EXPORT UNCLEANED OCCUPATIONS FOR MANUAL REVIEW
********************************************************************************

* Example approach:
preserve
keep ResponseId mother_pref_occ_1 mother_pref_occ_2
keep if !missing(mother_pref_occ_1) | !missing(mother_pref_occ_2)
replace mother_pref_occ_1 = lower(mother_pref_occ_1)
replace mother_pref_occ_2 = lower(mother_pref_occ_2)

export excel using "${parental_occupation_cleaning_new}/uncleaned_parent_occ.xlsx", ///
    firstrow(variables) replace

restore

********************************************************************************
* 4. IMPORT MANUAL CLEANING & MERGE BACK
********************************************************************************

* (If you have a "clean occupations.xlsx" with suggestions)
* import excel "${parental_occupation_cleaning_new}/clean occupations.xlsx", ...
* merge m:1 mother_pref_occ_1 using ...
* rename ...
* etc.

********************************************************************************
* 5. SAVE
********************************************************************************

compress
save "${processed_data}/PS_Parents/temp_par_clean_parent_occs.dta", replace

timer off 1
timer list
log close
