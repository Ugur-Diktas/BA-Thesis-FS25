********************************************************************************
// 2_ps_parents_remove_duplicates.do
// Purpose : Removes duplicates, excludes bad-quality obs, renames key vars, etc.
//           for the PS_Parents anonymised data.
//
// Author  : Ugur Diktas-Jelke Clarysse
// Project : BA Thesis FS25
// Date    : 26.02.2025
//
// Steps   :
//    1) Load the anonymised data from ${processed_data}/PS_Parents/ps_par_all_anon.dta
//    2) (Optionally) drop partial/ test obs if "status" or "StartDate" exist
//    3) Check duplicates on ResponseId
//    4) Exclude missing e-mail if needed
//    5) Rename contract -> has_contract
//    6) Save to temp_parents_step2.dta
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

clear all
version 18.0
set more off

// Start logging
cap log close
log using "${dodir_log}/parents_remove_duplicates.log", replace



// Optional timer
timer clear
timer on 1

********************************************************************************
* 1. LOAD ANONYMIZED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_all_anon.dta", clear
di as txt "INFO: Loaded `=_N' obs from ps_par_all_anon.dta"

duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
* 2. MERGE SENSITIVE DATA FOR DUPLICATE CHECKS
********************************************************************************

merge 1:1 ResponseId using "${sensitive_data}/ps_par_sensitive_only.dta", ///
    keep(match master) keepusing(email stu_first_name stu_last_name) nogen

********************************************************************************
* 3. CHECK DUPLICATES BASED ON EMAIL AND NAMES
********************************************************************************

* Email duplicates
duplicates tag email if !missing(email), gen(dup_email)
egen email_group = group(email) if dup_email >= 1, label

* Name duplicates
duplicates tag stu_first_name stu_last_name if ///
    !missing(stu_first_name, stu_last_name), gen(dup_name)
egen name_group = group(stu_first_name stu_last_name) if dup_name >= 1, label

********************************************************************************
* 4. RANK RESPONSES & DROP NON-LAST
********************************************************************************

* Convert StartDate to a time/c date format for ranking
format StartDate %tc

* Rank responses by StartDate within duplicate groups
bysort email_group : egen email_group_order = rank(-StartDate) if !missing(email_group)
bysort name_group  : egen name_group_order  = rank(-StartDate) if !missing(name_group)

* Drop any non-last responses within email or name groups 
* (assuming the last response is typically the final one)
drop if (email_group_order > 1 & !missing(email_group)) | ///
        (name_group_order > 1 & !missing(name_group))

********************************************************************************
* 5. CLEAN UP AND SAVE
********************************************************************************

drop email stu_first_name stu_last_name dup_email dup_name ///
     email_group name_group *_order

compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

// Timer end
timer off 1
timer list 1
log close
