********************************************************************************
* 6_ps_students_clean_other.do
* ------------------------------------------------------------------------------
* Data needed: 5_ps_students.dta
* Data output: 6_ps_students.dta
* Purpose:
*   - Cleans "other" occupation textboxes and standardizes them using the 
*     clean_apprenticeships.do mapping system.
*   - Performs basic cleaning (removes line breaks, standardizes formatting) 
*   - Exports a review table of unmatched apprenticeship entries for manual review
*   - Updates the crosswalk dataset to include new apprenticeship entries
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
clear all
set more off
version 18.0

// Enable/disable trace based on debug flag
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

// Start logging
cap log close
log using "${dodir_log}/6_ps_students_clean_other.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD DATA & VALIDATE PLAN VARIABLE
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: 5_ps_students.dta -----"
quietly use "${processed_data}/PS_Students/5_ps_students.dta", clear
di as txt "Processing dataset with `c(N)' observations"

// Check that plan variable exists
capture confirm variable plan
if _rc {
    di as error "ERROR: Variable 'plan' not found. Cannot process apprenticeships."
    error 111
}

//----------------------------------------------------------------------------
// 2. BASIC TEXT CLEANING
//----------------------------------------------------------------------------
di as txt "----- Cleaning apprenticeship text data -----"

// Get the variable type
local t : type plan
if substr("`t'", 1, 3) == "str" {
    // Basic text cleaning: remove line breaks, extra spaces, standardize case
    replace plan = subinstr(plan, char(10), " ", .)  // Remove line breaks
    replace plan = strtrim(plan)                    // Remove leading/trailing spaces
    replace plan = stritrim(plan)                   // Replace multiple spaces with one
    
    // Optional: convert first character to uppercase for consistency
    gen __first = substr(plan, 1, 1)
    gen __rest = substr(plan, 2, .)
    replace __first = upper(__first)
    replace plan = __first + __rest if !missing(plan)
    drop __first __rest
}
else {
    di as error "WARNING: Variable 'plan' is not a string (type: `t'). Converting to string."
    tostring plan, replace force
}

//----------------------------------------------------------------------------
// 3. INTEGRATE WITH CLEAN_APPRENTICESHIPS SYSTEM
//----------------------------------------------------------------------------
di as txt "----- Processing apprenticeships with clean_apprenticeships.do -----"

// Prepare for clean_apprenticeships.do
rename plan Apprenticeship

// Save current data before processing
tempfile before_cleaning
save `before_cleaning'

// Execute the apprenticeship cleaning process
qui do "${clean_apprenticeships}/clean apprenticeships.do"

// Merge cleaned apprenticeship data back to main dataset
use `before_cleaning', clear
merge m:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships.dta", ///
    keepusing(labb_code_* app_official_*) nogen

// Rename back to original variable 
rename Apprenticeship plan
rename labb_code_1 plan_code
rename app_official_1 plan_cleaned

//----------------------------------------------------------------------------
// 4. EXPORT REVIEW TABLE
//----------------------------------------------------------------------------
di as txt "----- Creating review table of apprenticeship responses -----"
preserve
    keep ResponseId plan plan_code plan_cleaned
    keep if !missing(plan) & trim(plan) != ""
    order ResponseId plan plan_code plan_cleaned
    
    // Export for review
    export excel using "${processed_data}/PS_Students/apprenticeship_review.xlsx", ///
        firstrow(variables) replace
        
    // Count unmatched entries for reporting
    count if missing(plan_code)
    local unmatched = r(N)
    
    if `unmatched' > 0 {
        di as txt "IMPORTANT: `unmatched' apprenticeship entries need manual review"
        di as txt "Please check ${processed_data}/PS_Students/apprenticeship_review.xlsx"
        di as txt "and update Sheet2 in ${clean_apprenticeships}/clean apprenticeships.xlsx"
    }
    else {
        di as txt "✓ All apprenticeship entries have been successfully matched"
    }
restore

//----------------------------------------------------------------------------
// 5. FINALIZATION & SAVING
//----------------------------------------------------------------------------
// Label the new variables
label var plan_code "LABB code for plan"
label var plan_cleaned "Standardized apprenticeship name"

// Add variable indicating whether the apprenticeship was successfully matched
gen byte plan_matched = !missing(plan_code)
label var plan_matched "Apprenticeship successfully matched to LABB code"

di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Students/6_ps_students.dta", replace

timer off 1
timer list

log close