/**********************************************************************************************
 * 6_ps_students_clean_other.do
 * --------------------------------------------------------------------------------------------
 * Purpose:
 *   Cleans "other" occupation textboxes and related fields in the PS Students dataset.
 *   This includes basic cleaning (removing line breaks, trimming) and, if applicable, merging 
 *   with external standardized occupation references via the clean_apprenticeships.do file.
 *
 *   In this project the free‐text apprenticeship response is stored in the variable "plan"
 *   (located right after name_class). This do‐file:
 *     1. Loads the cleaned student data.
 *     2. Cleans the "plan" variable.
 *     3. Uses an external cleaning routine (clean_apprenticeships.do) to standardize the text.
 *     4. Exports a review table (showing ResponseId and plan) so you can check the free‐text 
 *        responses.
 *     5. Saves the updated dataset.
 *
 * Data Requirements:
 *   - The cleaned students file "ps_stu_cleaned.dta" must exist in 
 *       ${processed_data}/PS_Students.
 *
 * Globals Needed:
 *   - processed_data, dodir_log, dodir_cleaning, clean_apprenticeships, appchardir, debug
 *
 * Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 25.02.2025
 * Version: Stata 18
 **********************************************************************************************/

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
log using "${dodir_log}/students_clean_other.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD THE CLEANED DATA
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear
di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 603
}

//----------------------------------------------------------------------------
// 2. CLEAN THE APPOINTMENT TEXT (plan)
//----------------------------------------------------------------------------
di as txt "----- Cleaning the apprenticeship free‐text variable: plan -----"
capture confirm variable plan
if !_rc {
    // Get the variable type
    local t : type plan
    if substr("`t'", 1, 3) == "str" {
        // Remove line breaks and extra spaces if plan is a string
        replace plan = subinstr(plan, char(10), "", .)
        replace plan = strtrim(plan)
        replace plan = stritrim(plan)
    }
    else {
        di as error "ERROR: Variable 'plan' is not a string (type: `t'). Cleaning skipped."
    }
}
else {
    di as error "ERROR: Variable 'plan' not found."
    exit 198
}

//----------------------------------------------------------------------------
// 3. MERGE 'OTHER' FIELDS WITH EXTERNAL OCCUPATION REFERENCES
//----------------------------------------------------------------------------
di as txt "Standardizing plan via clean_apprenticeships.do ..."

// Convert Apprenticeship to string BEFORE merging
capture confirm string variable plan
if _rc {
    tostring plan, replace force  // Ensure plan is string before renaming
}
rename plan Apprenticeship        // Now Apprenticeship inherits string type

tempfile keep_original
save `keep_original'
keep Apprenticeship
do "${clean_apprenticeships}/clean apprenticeships.do"
use `keep_original', clear
merge m:1 Apprenticeship using "${clean_apprenticeships}/clean apprenticeships", ///
    nogen keep(master match) keepusing(labb_code_1 app_official_1)
rename Apprenticeship plan
rename labb_code_1   plan_code
rename app_official_1 plan_cleaned

//----------------------------------------------------------------------------
// 4. OUTPUT A REVIEW TABLE OF "OTHER" RESPONSES
//    (This table shows ResponseId and the current value of plan for manual review.)
//----------------------------------------------------------------------------
di as txt "----- Creating review table for 'other' responses -----"
preserve
    keep ResponseId plan
    keep if !missing(plan) & trim(plan)!=""
    order ResponseId plan
    list ResponseId plan, sep(0)
    export excel using "${processed_data}/PS_Students/others_responses.xlsx", ///
        firstrow(variables) replace
restore

//----------------------------------------------------------------------------
// 5. SAVE & WRAP UP
//----------------------------------------------------------------------------
di as txt "----- Compressing and saving the updated dataset -----"
compress
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

log close
