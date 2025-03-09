********************************************************************************
* 10_ps_parents_drop_vars.do
* ------------------------------------------------------------------------------
* Data needed: 9_ps_parents.dta
* Data output: ps_parents_final.dta
* Purpose:
*   - Finalise the PS Parents dataset by dropping extraneous variables.
*   - Reorder key variables for better readability and analysis.
*   - Remove Qualtrics metadata, timing variables, and additional consent variables.
*   - Remove free-text and repeated fields that are no longer needed.
*   - Create final consent variable.
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

if ("${debug}" == "yes") {
    set trace on
} 
else {
    set trace off
}

cap log close
log using "${dodir_log}/10_ps_parents_drop_vars.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Drop Variables"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// LOAD DATA
********************************************************************************

di as txt "----- Loading dataset: 9_ps_parents.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/9_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/9_ps_parents.dta"
    di as error "Run 9_ps_parents_clean_parent_occs.do first."
    exit 601
}

use "${processed_data}/PS_Parents/9_ps_parents.dta", clear
di as txt "Loaded dataset with `c(N)' observations and `c(k)' variables."
local k_orig = c(k)

// Create backup of original dataset
tempfile original_data
save `original_data', replace

********************************************************************************
// DROP UNNEEDED VARIABLES
********************************************************************************

di as txt "----- Dropping unneeded variables -----"

// 1. Qualtrics Metadata
di as txt "Dropping Qualtrics metadata variables..."
local drop_count = 0
foreach var in StartDate EndDate Status Progress Duration_* Finished RecordedDate ///
               Recipient* ExternalReference* DistributionChannel UserLanguage ///
               _v* contactid* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' metadata variables."

// 2. Timing Variables and Additional Consent Variables
di as txt "Dropping survey process variables..."
local drop_count = 0
foreach var in t_* sure consent2 {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' survey process variables."

// 3. Free Text and Repeated Fields
di as txt "Dropping text variables and free responses..."
local drop_count = 0
foreach var in *Text* *TEXT* *concern* *suggest* *reason* *q_text* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' text and free response variables."

// 4. Occupational Preference Expansions
di as txt "Dropping occupational preference variables..."
local drop_count = 0
foreach var in *offers* *reject_ta* *apply_occs* *ta_occs* *FaGe* *FaBe* ///
               *MPA* *Apotheke* *GesundSoz* *Dent* *school_type* {
    capture drop `var'
    if !_rc {
        local drop_count = `drop_count' + 1
    }
}
di as txt "  Dropped `drop_count' occupational preference variables."

********************************************************************************
// VARIABLE MANAGEMENT: RECODE
********************************************************************************

di as txt "----- Recoding consent variables -----"

// Create final consent variable
capture confirm variable consent1
if !_rc {
    gen byte consent_1st_time = (consent1 == 1)
    label var consent_1st_time "Consent given at first contact"
    
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
// REORDER VARIABLES
********************************************************************************

di as txt "----- Reordering variables -----"

// Check that key variables exist before ordering
local key_vars_exist = 1
foreach var in ResponseId contract female {
    capture confirm variable `var'
    if _rc {
        local key_vars_exist = 0
        di as error "WARNING: Key variable `var' not found."
    }
}

if `key_vars_exist' {
    // Core identifiers come first
    order ResponseId contract female
    
    // Move consent variable near the front if present
    capture confirm variable consent_1st_time
    if !_rc {
        order consent_1st_time, after(female)
    }
}
else {
    di as txt "Skipping variable ordering due to missing key variables."
}

********************************************************************************
// FINALISE DATASET
********************************************************************************

di as txt "----- Finalizing dataset -----"

// Compress and provide dataset summary
compress
desc, short
di as txt "Final dataset has `c(N)' observations and `c(k)' variables."

// Save final dataset
capture mkdir "${processed_data}/PS_Parents"
save "${processed_data}/PS_Parents/ps_parents_final.dta", replace

// Report changes from original
di as txt "Original dataset had `k_orig' variables, final dataset has `c(k)' variables."
di as txt "Reduced dataset by `=`k_orig'-c(k)' variables."

********************************************************************************
// WRAP UP
********************************************************************************

di as txt "Final cleaned dataset saved to: ${processed_data}/PS_Parents/ps_parents_final.dta"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Drop Variables"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off