********************************************************************************
* 2_ps_parents_remove_duplicates.do
* ------------------------------------------------------------------------------
* Data needed: ps_par_all_anon.dta
* Data output: ps_par_cleaned.dta
* Purpose:
*   - Load anonymised PS Parents data.
*   - Remove duplicate responses based on ResponseId.
*   - Merge with sensitive data to check duplicates by parent email and names.
*   - Keep only the final (latest) response within each duplicate group (based on StartDate).
*   - Save cleaned dataset.
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
* 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

* Conditionally enable or disable trace using global `debug'
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

* Start logging
cap log close
log using "${dodir_log}/2_ps_parents_remove_duplicates.log", replace text

********************************************************************************
* 1. LOAD ANONYMALISED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_all_anon.dta", clear
di as txt "Loaded PS Parents anonymised data: `c(N)' obs, `c(k)' vars"

* Remove duplicate ResponseId records:
duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di as txt "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
* 2. MERGE WITH SENSITIVE DATA FOR DUPLICATE CHECKS
********************************************************************************

* Save a backup of the current master dataset
tempfile master_copy
save `master_copy', replace

* Merge with sensitive data that contains parent's email and names
merge 1:1 ResponseId using "${sensitive_data}/ps_par_sensitive_only.dta", ///
    keep(match master) keepusing(par_email par_first_name par_last_name) nogen

* If merge resulted in no observations, restore original master data
if _N == 0 {
    di as error "No observations after merging sensitive data. Restoring original master dataset."
    use `master_copy', clear
}

********************************************************************************
* 3. CHECK DUPLICATES BASED ON PARENT EMAIL AND NAMES
********************************************************************************

* Check duplicates on parent's email (with safety checks)
capture confirm variable par_email
if _rc == 0 & !missing(par_email[1]) {  // Only proceed if par_email exists & has at least one non-missing value
    duplicates tag par_email if !missing(par_email), gen(dup_email)
    capture confirm variable dup_email
    if _rc == 0 {
        egen email_group = group(par_email) if dup_email >= 1, label
    }
}

* Check duplicates on parent's names (with safety checks)
capture confirm variable par_first_name par_last_name
if _rc == 0 & (!missing(par_first_name[1]) | !missing(par_last_name[1])) {
    duplicates tag par_first_name par_last_name if ///
        !missing(par_first_name, par_last_name), gen(dup_name)
    capture confirm variable dup_name
    if _rc == 0 {
        egen name_group = group(par_first_name par_last_name) if dup_name >= 1, label
    }
}

********************************************************************************
* 4. RANK RESPONSES & DROP NON-FINAL RESPONSES
********************************************************************************

* Ensure StartDate is in proper time/c format
format StartDate %tc

* Initialize grouping variables if missing
foreach group in email name {
    capture confirm variable `group'_group
    if _rc != 0 {
        gen `group'_group = .
    }
}

* Rank responses using safe conditional execution
foreach group in email name {
    capture confirm variable dup_`group'
    if _rc == 0 {
        capture noisily bysort `group'_group: egen `group'_group_order = rank(-StartDate) if !missing(`group'_group)
    }
    else {
        gen `group'_group_order = .
    }
}

* Drop non-final responses using safe conditions
foreach group in email name {
    capture confirm variable `group'_group_order
    if _rc == 0 {
        drop if `group'_group_order > 1 & !missing(`group'_group)
    }
}

********************************************************************************
* 5. CLEAN UP AND SAVE
********************************************************************************

* Remove sensitive variables and duplicate helper variables (with existence checks)
capture drop par_email par_first_name par_last_name
capture drop dup_email dup_name
capture drop email_group name_group
capture drop email_group_order name_group_order

* Alternative: Safer explicit list with wildcard protection
foreach var in par_email par_first_name par_last_name dup_email dup_name ///
               email_group name_group email_group_order name_group_order {
    capture drop `var'
}

compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

log close
