********************************************************************************
* 6_ps_students_clean_other.do
* ------------------------------------------------------------------------------
* Data needed: 5_ps_students.dta
* Data output: 6_ps_students.dta
* Purpose:
*   - Cleans "other" occupation textboxes and standardizes them
*   - Performs basic cleaning (removes line breaks, standardizes formatting) 
*   - Processes the plan variable through the clean_apprenticeships system
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************
clear all
set more off
version 18.0

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

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Other"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// 1. LOAD DATA & VALIDATE PLAN VARIABLE
********************************************************************************
di as txt "----- Loading dataset: 5_ps_students.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Students/5_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/5_ps_students.dta"
    di as error "Run 5_ps_students_clean_motivations.do first."
    exit 601
}

use "${processed_data}/PS_Students/5_ps_students.dta", clear
di as txt "Processing dataset with `c(N)' observations and `c(k)' variables."

// Check that plan variable exists
capture confirm variable plan
if _rc {
    di as error "ERROR: Variable 'plan' not found. Cannot process apprenticeships."
    di as error "Checking alternative plan variable names..."
    
    // Try to find alternative variable names
    foreach var in plan_ apprenticeship apprenticeship_plan {
        capture confirm variable `var'
        if !_rc {
            di as txt "Found alternative plan variable: `var'. Renaming to 'plan'."
            rename `var' plan
            local plan_found = 1
            continue, break
        }
    }
    
    if !`plan_found' {
        di as error "No suitable plan variable found. Exiting."
        exit 111
    }
}

********************************************************************************
// 2. BASIC TEXT CLEANING
********************************************************************************
di as txt "----- Cleaning apprenticeship text data -----"

// Check variable type and convert to string if necessary
capture confirm string variable plan
if _rc {
    di as txt "Converting 'plan' from numeric to string..."
    
    // Try to decode if it's a labeled numeric variable
    capture decode plan, gen(plan_str)
    if _rc {
        // If decode fails, use tostring
        tostring plan, gen(plan_str) force
    }
    drop plan
    rename plan_str plan
    di as txt "  Conversion complete."
}

// Create a backup of the plan variable
tempvar plan_backup
gen `plan_backup' = plan

// Now perform text cleaning on the string variable
di as txt "Performing text cleaning on apprenticeship names..."
// Basic text cleaning: remove line breaks, extra spaces, standardize case
replace plan = subinstr(plan, char(10), " ", .)  // Remove line breaks
replace plan = subinstr(plan, char(13), " ", .)  // Remove carriage returns
replace plan = strtrim(plan)                     // Remove leading/trailing spaces
replace plan = stritrim(plan)                    // Replace multiple spaces with one

// Optional: convert first character to uppercase for consistency
gen __first = substr(plan, 1, 1)
gen __rest = substr(plan, 2, .)
replace __first = upper(__first)
replace plan = __first + __rest if !missing(plan)
drop __first __rest

// Report cleaning results
count if plan != `plan_backup' & !missing(plan) & !missing(`plan_backup')
di as txt "Modified `r(N)' plan values during text cleaning."

else {
    di as error "WARNING: Variable 'plan' is not a string (type: `t'). Converting to string."
    decode plan, gen(plan_str)
    drop plan
    rename plan_str plan
}

********************************************************************************
// 3. INTEGRATE WITH CLEAN_APPRENTICESHIPS SYSTEM
********************************************************************************
di as txt "----- Processing apprenticeships with clean_apprenticeships.do -----"

// Check if clean_apprenticeships directory exists
capture confirm file "${clean_apprenticeships}/."
if _rc {
    di as error "ERROR: clean_apprenticeships directory not found: ${clean_apprenticeships}"
    di as error "Cannot process apprenticeships."
    exit 601
}

// Check if clean apprenticeships.do exists
capture confirm file "${clean_apprenticeships}/clean apprenticeships.do"
if _rc {
    di as error "ERROR: clean apprenticeships.do not found in ${clean_apprenticeships}"
    di as error "Cannot process apprenticeships."
    exit 601
}

// Prepare for clean_apprenticeships.do
di as txt "Renaming 'plan' to 'Apprenticeship' for processing..."
rename plan Apprenticeship

// Save current data before processing
tempfile before_cleaning
save `before_cleaning'

// Execute the apprenticeship cleaning process
di as txt "Executing clean_apprenticeships.do..."
capture noisily do "${clean_apprenticeships}/clean apprenticeships.do"
if _rc {
    di as error "ERROR: Failed to execute clean_apprenticeships.do. Error code: `_rc'"
    di as error "Restoring original data."
    use `before_cleaning', clear
    rename Apprenticeship plan
    local skip_merge = 1
}
else {
    local skip_merge = 0
}

if `skip_merge' == 0 {
    // Merge cleaned apprenticeship data back to main dataset
    di as txt "Merging cleaned apprenticeship data back to main dataset..."
    use `before_cleaning', clear
    
    capture confirm file "${clean_apprenticeships}/clean apprenticeships.dta"
    if _rc {
        di as error "ERROR: clean apprenticeships.dta not found after processing."
        di as error "Skipping merge."
        rename Apprenticeship plan
        local skip_merge = 1
    }
    else {
        merge m:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships.dta", ///
            keepusing(labb_code_* app_official_*)
            
        // Check merge results
        di as txt "Merge results:"
        di as txt "  Matched: `r(N_1)'"
        di as txt "  From master only: `r(N_2)'"
        di as txt "  From using only: `r(N_3)' (dropped)"
        
        // Drop merge indicator
        drop _merge
        
        // Rename back to original variable 
        rename Apprenticeship plan
        rename labb_code_1 plan_code
        rename app_official_1 plan_cleaned
    }
}

********************************************************************************
// 4. FINALIZATION & SAVING
********************************************************************************
if `skip_merge' == 0 {
    // Label the new variables
    label var plan_code "LABB code for plan"
    label var plan_cleaned "Standardized apprenticeship name"

    // Add variable indicating whether the apprenticeship was successfully matched
    gen byte plan_matched = !missing(plan_code)
    label var plan_matched "Apprenticeship successfully matched to LABB code"
    
    // Report matching results
    count if plan_matched == 1
    local matched_count = r(N)
    count if !missing(plan)
    local total_count = r(N)
    if `total_count' > 0 {
        local match_pct = round(`matched_count'/`total_count'*100, 0.1)
    }
    else {
        local match_pct = 0
    }
    di as txt "Successfully matched `matched_count' out of `total_count' apprenticeships (`match_pct'%)."
}

// Compress and save
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Students/6_ps_students.dta", replace

// Final report
di as txt "Cleaned other variables dataset saved to: ${processed_data}/PS_Students/6_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Other"
di as txt "======================================================="

timer off 1
timer list

log close
set trace off