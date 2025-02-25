********************************************************************************
// 3_ps_parents_clean_beliefs.do
// Purpose : Cleans & processes the belief-related questions in the PS Students 
//           dataset. Includes built-in debug steps to handle naming issues.
// 
// Author  : Ugur Diktas_Jelke Clarysse, BA Thesis FS25, 18.02.2025
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

cap log close
log using "${dodir_log}/ps_parents_clean_beliefs.log", replace text

// Turn on Stata's trace for very detailed debugging (comment out if too verbose).
// set trace on

timer clear
timer on 1

********************************************************************************
// 1. LOAD THE CLEANED DATA
********************************************************************************

di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"

if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 602
}

********************************************************************************
// 2. DEBUG STEP 1: RENAMING ESSENTIAL VARIABLES 
********************************************************************************

