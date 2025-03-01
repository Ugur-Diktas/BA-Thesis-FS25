********************************************************************************
* 2_ps_students_remove_duplicates.do
* 
* Purpose : 
*   - Load anonymised PS Students data.
*   - Remove duplicate responses based on ResponseId.
*   - Merge with sensitive data to check duplicates on email or name.
*   - Remove non-first responses in each duplicate group.
*   - Save cleaned dataset.
*
* Author  : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 01.03.2025
* Version : Stata 18
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
log using "${dodir_log}/students_remove_duplicates.log", replace text

********************************************************************************
* 1. LOAD ANONYMIZED DATA
********************************************************************************

use "${processed_data}/PS_Students/ps_stu_all_anon.dta", clear

* Remove duplicate ResponseId records:
duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
* 2. MERGE SENSITIVE DATA FOR DUPLICATE CHECKS
********************************************************************************

merge 1:1 ResponseId using "${sensitive_data}/ps_stu_sensitive_only.dta", ///
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
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

log close
