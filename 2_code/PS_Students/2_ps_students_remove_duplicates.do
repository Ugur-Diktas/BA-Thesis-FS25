********************************************************************************
* 2_ps_students_remove_duplicates.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_all_anon.dta
* Data output: ps_stu_cleaned.dta
* Purpose: 
*   - Load anonymised PS Students data.
*   - Remove duplicate responses based on ResponseId.
*   - Merge with sensitive data to check duplicates on email or name.
*   - Remove non-final responses in each duplicate group.
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

* Conditionally enable or disable trace using global `debug`
if "${debug}" == "yes" {
    set trace on
} 
else {
    set trace off
}

* Start logging
cap log close
log using "${dodir_log}/2_ps_students_remove_duplicates.log", replace text

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Remove Duplicates"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD ANONYMIZED DATA
********************************************************************************

* Check if input file exists
capture confirm file "${processed_data}/PS_Students/1_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/1_ps_students.dta"
    di as error "Run 1_ps_students_anonymize.do first."
    exit 601
}

use "${processed_data}/PS_Students/1_ps_students.dta", clear
di as txt "Loaded anonymized data with `c(N)' observations and `c(k)' variables."

* Remove duplicate ResponseId records:
capture confirm variable ResponseId
if _rc {
    di as error "ERROR: ResponseId variable not found in dataset. Cannot identify duplicates."
    exit 111
}

duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di as txt "Found `r(N)' duplicate ResponseId records."
    drop if dup_responseid > 0
    di as txt "Dropped duplicates, `c(N)' observations remaining."
}
else {
    di as txt "No duplicate ResponseId records found."
}
drop dup_responseid

********************************************************************************
* 2. MERGE SENSITIVE DATA FOR DUPLICATE CHECKS
********************************************************************************

* Check if sensitive data file exists
capture confirm file "${sensitive_data}/ps_stu_sensitive_only.dta"
if _rc {
    di as error "WARNING: Sensitive data file not found: ${sensitive_data}/ps_stu_sensitive_only.dta"
    di as error "Cannot check for duplicates based on email or names."
    
    * Create temporary backup in case merge fails
    tempfile no_sensitive_backup
    save `no_sensitive_backup'
    
    * Continue without sensitive data merge
    local skip_sensitive_merge = 1
}
else {
    local skip_sensitive_merge = 0
}

if `skip_sensitive_merge' == 0 {
    * Save a backup of current data before merge
    tempfile before_merge
    save `before_merge'
    
    * Merge with sensitive data for duplicate checks
    merge 1:1 ResponseId using "${sensitive_data}/ps_stu_sensitive_only.dta", ///
        keep(match master) keepusing(email stu_first_name stu_last_name)
        
    * Check merge results
    di as txt "Merge results:"
    di as txt "  Matched: `r(N_1)'"
    di as txt "  From master only: `r(N_2)'"
    di as txt "  From using only: `r(N_3)' (dropped)"
    
    * Drop merge indicator
    drop _merge
    
    * Check if we have any observations after merge
    if _N == 0 {
        di as error "ERROR: No observations after merging sensitive data. Restoring original data."
        use `before_merge', clear
        local skip_sensitive_merge = 1
    }
}

********************************************************************************
* 3. CHECK DUPLICATES BASED ON EMAIL AND NAMES
********************************************************************************

if `skip_sensitive_merge' == 0 {
    * Email duplicates
    capture confirm variable email
    if !_rc & !missing(email[1]) {
        di as txt "Checking for duplicate email addresses..."
        duplicates tag email if !missing(email), gen(dup_email)
        
        count if dup_email > 0
        if r(N) > 0 {
            di as txt "Found `r(N)' observations with duplicate email addresses."
            egen email_group = group(email) if dup_email >= 1, label
            di as txt "Created `r(max)' email duplicate groups."
        }
        else {
            di as txt "No duplicate email addresses found."
        }
    }
    else {
        di as txt "Email variable not available or empty. Skipping email duplicate check."
    }

    * Name duplicates
    capture confirm variable stu_first_name
    capture confirm variable stu_last_name
    if !_rc & (!missing(stu_first_name[1]) | !missing(stu_last_name[1])) {
        di as txt "Checking for duplicate names..."
        duplicates tag stu_first_name stu_last_name if ///
            !missing(stu_first_name, stu_last_name), gen(dup_name)
            
        count if dup_name > 0
        if r(N) > 0 {
            di as txt "Found `r(N)' observations with duplicate names."
            egen name_group = group(stu_first_name stu_last_name) if dup_name >= 1, label
            di as txt "Created `r(max)' name duplicate groups."
        }
        else {
            di as txt "No duplicate names found."
        }
    }
    else {
        di as txt "Name variables not available or empty. Skipping name duplicate check."
    }
}

********************************************************************************
* 4. RANK RESPONSES & DROP NON-LAST
********************************************************************************

if `skip_sensitive_merge' == 0 {
    * Convert StartDate to a proper time/c format for ranking
    capture confirm variable StartDate
    if !_rc {
        format StartDate %tc
    }
    else {
        di as error "WARNING: StartDate variable not found. Cannot rank responses by time."
    }
    
    * Initialize counters for dropped observations
    local email_dropped = 0
    local name_dropped = 0
    
    * Rank responses within email duplicate groups
    capture confirm variable email_group
    if !_rc {
        di as txt "Ranking responses by time within email duplicate groups..."
        bysort email_group : egen email_group_order = rank(-StartDate) if !missing(email_group)
        
        * Count and drop non-last responses from email groups
        count if email_group_order > 1 & !missing(email_group)
        local email_dropped = r(N)
        
        if `email_dropped' > 0 {
            drop if email_group_order > 1 & !missing(email_group)
            di as txt "Dropped `email_dropped' older responses from email duplicate groups."
        }
        else {
            di as txt "No older responses to drop from email duplicate groups."
        }
    }
    
    * Rank responses within name duplicate groups
    capture confirm variable name_group
    if !_rc {
        di as txt "Ranking responses by time within name duplicate groups..."
        bysort name_group : egen name_group_order = rank(-StartDate) if !missing(name_group)
        
        * Count and drop non-last responses from name groups
        count if name_group_order > 1 & !missing(name_group)
        local name_dropped = r(N)
        
        if `name_dropped' > 0 {
            drop if name_group_order > 1 & !missing(name_group)
            di as txt "Dropped `name_dropped' older responses from name duplicate groups."
        }
        else {
            di as txt "No older responses to drop from name duplicate groups."
        }
    }
    
    * Total dropped
    local total_dropped = `email_dropped' + `name_dropped'
    if `total_dropped' > 0 {
        di as txt "Total responses dropped due to duplicates: `total_dropped'"
    }
    else {
        di as txt "No responses dropped due to duplicates."
    }
}

********************************************************************************
* 5. CLEAN UP AND SAVE
********************************************************************************

* Remove sensitive variables and duplicate helper variables (safely)
foreach var in email stu_first_name stu_last_name dup_email dup_name ///
               email_group name_group email_group_order name_group_order {
    capture drop `var'
}

* Compress and save
compress
save "${processed_data}/PS_Students/2_ps_students.dta", replace

* Final report
di as txt "Final cleaned dataset saved to: ${processed_data}/PS_Students/2_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Remove Duplicates"
di as txt "======================================================="

log close
set trace off