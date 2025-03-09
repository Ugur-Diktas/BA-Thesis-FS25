********************************************************************************
* 10_ps_students_drop_vars.do
* ------------------------------------------------------------------------------
* Data needed: 9_ps_students.dta
* Data output: ps_stu_final.dta
* Purpose:
*   - Finalise the PS Students dataset by dropping extraneous variables. 
*   - Remove Qualtrics metadata, survey process variables, and text variables.
*   - Remove occupational preference variables and parental input variables.
*   - Recode consent variables.
*   - Order variables for better organization.
*   - Produce the final cleaned file for analysis.
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
// SETUP ENVIRONMENT
********************************************************************************
clear all
version 18.0
set more off

// Enable or disable trace based on debug flag
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/10_ps_students_drop_vars.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Drop Variables"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// LOAD DATA
********************************************************************************

di as txt "----- Loading dataset: 9_ps_students.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Students/9_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/9_ps_students.dta"
    di as error "Run 9_ps_students_clean_parent_occs.do first."
    exit 601
}

use "${processed_data}/PS_Students/9_ps_students.dta", clear
di as txt "Loaded dataset with `c(N)' observations and `c(k)' variables."
local k_orig = c(k)

// Create backup of original dataset
tempfile original_data
save `original_data', replace

********************************************************************************
// VARIABLE CLEANING: DROP UNNEEDED VARIABLES
********************************************************************************

di as txt "----- Dropping unneeded variables -----"

// 1. Metadata and Qualtrics Variables
di as txt "Dropping Qualtrics metadata variables..."
local drop_count = 0
foreach var in StartDate EndDate Status Progress Duration_* Finished RecordedDate ///
               Recipient* ExternalReference* DistributionChannel UserLanguage ///
               _v* contactid* debug_contract* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' metadata variables."

// 2. Survey Process Variables
di as txt "Dropping survey process variables..."
local drop_count = 0
foreach var in duration* feedback* sure consent2 cons_* fut_survey_pof ///
               t_* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' survey process variables."

// 3. Text Variables and Free Responses
di as txt "Dropping text variables and free responses..."
local drop_count = 0
foreach var in *friend_* *Text* *TEXT* *q_text* *concern* *suggest* *reason* ///
               *_merge* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' text and free response variables."

// 4. Occupational Preference Variables
di as txt "Dropping occupational preference variables..."
local drop_count = 0
foreach var in *app_pref_* *offer* *reject* *apply_occs* *ta_occs* *FaGe* *FaBe* ///
               *MPA* *Apotheke* *GesundSoz* *Dent* *school_type* *track_* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' occupational preference variables."

// 5. Parental Input Variables
di as txt "Dropping parental input variables..."
local drop_count = 0
foreach var in *mother_* *father_* *parent_* *child_* *birth* *field_educ* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' parental input variables."

********************************************************************************
// VARIABLE MANAGEMENT: RECODE
********************************************************************************

di as txt "----- Recoding consent variables -----"

// Handle Consent Variables
capture confirm variable consent1
if !_rc {
    di as txt "Creating and recoding consent_1st_time variable..."
    
    gen byte consent_1st_time = (consent1 == 1) if !missing(consent1)
    lab var consent_1st_time "Consent given at first contact"
    
    // Count non-consenting respondents
    count if inlist(consent1, 2, .)
    local non_consent_count = r(N)
    
    if `non_consent_count' > 0 {
        di as txt "Dropping `non_consent_count' non-consenting respondents."
        drop if inlist(consent1, 2, .) // Drop non-consenting respondents
    }
    else {
        di as txt "All respondents gave consent, none dropped."
    }
}
else {
    di as txt "consent1 variable not found, skipping consent recoding."
}

********************************************************************************
// VARIABLE ORDERING (Based on sample structure)
********************************************************************************

di as txt "----- Reordering variables -----"

// Core Identifiers and Demographics
order ResponseId contract female sit age canton 

// Apprenticeship Information
capture confirm variable plan
if !_rc {
    capture confirm variable plan__T
    if !_rc {
        order plan plan__T, after(canton) // Free-text apprenticeship response and cleaned version
    }
    else {
        order plan, after(canton)
    }
}

// Household Characteristics
capture confirm variable home_sit_stu
if !_rc {
    order home_sit_stu, after(plan) // Home situation
}

********************************************************************************
// FINALIZE DATASET
********************************************************************************

di as txt "----- Finalizing dataset -----"

// 1. Compress and Validate
compress
desc, short // Should show ~15-20 variables
di as txt "Final dataset has `c(N)' observations and `c(k)' variables."

// 2. Save Clean Dataset
save "${processed_data}/PS_Students/ps_stu_final.dta", replace

// Report changes from original
di as txt "Original dataset had `k_orig' variables, final dataset has `c(k)' variables."
di as txt "Reduced dataset by `=`k_orig'-c(k)' variables."

********************************************************************************
// WRAP UP
********************************************************************************

di as txt "Final cleaned dataset saved to: ${processed_data}/PS_Students/ps_stu_final.dta"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Drop Variables"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off