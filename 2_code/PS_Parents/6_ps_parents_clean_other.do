********************************************************************************
* 6_ps_parents_clean_other.do
* ------------------------------------------------------------------------------
* Data needed: 5_ps_parents.dta
* Data output: 6_ps_parents.dta
* Purpose:
*   - Cleans "other" free-text responses in the PS Parents dataset
*   - Standardizes apprenticeship names using the clean_apprenticeships system
*   - Performs basic cleaning (removing line breaks, trimming whitespace)
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 13.03.2025
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
// 1. LOAD DATA AND IDENTIFY PLAN VARIABLE
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: 5_ps_parents.dta -----"
quietly use "${processed_data}/PS_Parents/5_ps_parents.dta", clear
di as txt "Observations: `c(N)'"

// Identify the plan variable (may have different names in parent dataset)
ds plan*
local planvars `r(varlist)'
if "`planvars'" == "" {
    di as error "ERROR: No variable matching 'plan*' found. Cannot process apprenticeships."
    error 111
}
else {
    local planvar : word 1 of `planvars'
    di as txt "Using variable `planvar' for apprenticeship free text."
    rename `planvar' plan
}

//----------------------------------------------------------------------------
// 2. CLEAN FREE-TEXT FIELDS
//----------------------------------------------------------------------------
di as txt "----- Cleaning apprenticeship free-text data -----"

// Check that plan is a string and perform basic text cleaning
local t : type plan
if substr("`t'", 1, 3) == "str" {
    // Remove line breaks and extra spaces
    replace plan = subinstr(plan, char(10), " ", .)
    replace plan = strtrim(plan)
    replace plan = stritrim(plan)
    
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
save "${processed_data}/PS_Parents/6_ps_parents.dta", replace

timer off 1
timer list

log close