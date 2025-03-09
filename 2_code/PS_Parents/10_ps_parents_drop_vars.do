********************************************************************************
* 10_ps_parents_drop_vars.do
* ------------------------------------------------------------------------------
* Data needed: temp_par_clean_parent_occs.dta
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

// LOAD MERGED DATA
// -----------------------------------------------------------------------------
di as txt "----- Loading dataset: ps_par_merge_chars.dta -----"
use "${processed_data}/PS_Parents/9_ps_parents.dta", clear
di as txt "Observations: `c(N)', Variables: `c(k)'"

// DROP UNNEEDED VARIABLES
// -----------------------------------------------------------------------------

// 1. Qualtrics Metadata
capture drop StartDate EndDate Status Progress Duration_* Finished RecordedDate
capture drop Recipient* ExternalReference* DistributionChannel UserLanguage
capture drop _v* contactid*

// 2. Timing Variables and Additional Consent Variables
capture drop t_*  // Drop all timing variables
capture drop sure consent2

// 3. Free Text and Repeated Fields (tailor as required)
capture drop *Text* *TEXT* *concern* *suggest* *reason* *q_text* 

// 4. Occupational Preference Expansions Not Needed
capture drop *offers* *reject_ta* *apply_occs* *ta_occs* *FaGe* *FaBe*
capture drop *MPA* *Apotheke* *GesundSoz* *Dent* *school_type*

// VARIABLE MANAGEMENT: RECODE
// -----------------------------------------------------------------------------

// Create final consent variable
gen byte consent_1st_time = (consent1 == 1)
label var consent_1st_time "Consent given at first contact"
drop if inlist(consent1, 2, .)

// REORDER VARIABLES
order ResponseId contract female consent_1st_time

// FINALISE DATASET
// -----------------------------------------------------------------------------

compress
desc, short

save "${processed_data}/PS_Parents/ps_parents_final.dta", replace

timer off 1
timer list
log close
