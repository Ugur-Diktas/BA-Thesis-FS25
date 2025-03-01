/**********************************************************************************************
 * 6_ps_parents_clean_other.do
 * --------------------------------------------------------------------------------------------
 * Purpose:
 *   Cleans “other” free‐text responses in the PS Parents dataset (e.g., apprenticeship free‐text).
 *   This includes basic cleaning (removing line breaks, trimming whitespace).
 *   The cleaned data is saved as an intermediate file for subsequent processing.
 *
 * Data Requirements:
 *   - The cleaned parents file (e.g., ps_par_clean_motivations.dta) must exist in 
 *       ${processed_data}/PS_Parents.
 *
 * Globals Needed:
 *   processed_data, dodir_log, debug
 *
 * Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 01.03.2025
 * Version: Stata 18
 **********************************************************************************************/

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
clear all
set more off
version 18.0

// Enable or disable trace based on debug flag
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

// Start logging
cap log close
log using "${dodir_log}/6_ps_parents_clean_other.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD THE CLEANED DATA
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: ps_par_clean_motivations.dta -----"
quietly use "${processed_data}/PS_Parents/ps_par_clean_motivations.dta", clear
di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_clean_motivations.dta."
    error 603
}

//----------------------------------------------------------------------------
// 1.5 Identify and rename the free-text apprenticeship variable
//     (searching for any variable that begins with "plan")
ds plan*
local planvar `r(varlist)'
if "`planvar'" != "" {
    local planvar : word 1 of `planvar'
    di as txt "Using variable `planvar' for apprenticeship free text."
    rename `planvar' plan
}
else {
    di as error "ERROR: No variable matching 'plan*' found."
    exit 198
}

//----------------------------------------------------------------------------
// 2. CLEAN FREE-TEXT FIELDS
//----------------------------------------------------------------------------
di as txt "----- Cleaning the free‐text variable: plan -----"
capture confirm variable plan
if !_rc {
    // Check that plan is a string and remove line breaks and extra spaces
    local t : type plan
    if substr("`t'", 1, 3) == "str" {
        replace plan = subinstr(plan, char(10), " ", .)
        replace plan = strtrim(plan)
        replace plan = stritrim(plan)
    }
    else {
        di as error "ERROR: Variable 'plan' is not a string (type: `t'). Cleaning skipped."
    }
}
else {
    di as error "ERROR: Variable 'plan' not found after renaming."
    exit 198
}

//----------------------------------------------------------------------------
// 3. SAVE INTERMEDIATE DATASET
//----------------------------------------------------------------------------
di as txt "----- Compressing and saving the intermediate dataset -----"
compress
save "${processed_data}/PS_Parents/temp_par_clean_other.dta", replace

timer off 1
timer list
log close
