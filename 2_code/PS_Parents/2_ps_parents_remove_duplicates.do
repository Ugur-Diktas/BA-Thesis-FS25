********************************************************************************
* 2_ps_parents_remove_duplicates.do
*
* Purpose:
* - Load anonymised PS Parents data.
* - Remove duplicates based on ResponseId.
* - Merge with sensitive data to check duplicates by email/child name.
* - Keep only the final response within each duplicate group (based on StartDate).
* - Save cleaned dataset.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/2_ps_parents_remove_duplicates.log", replace text

********************************************************************************
* 1. LOAD ANONYMISED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_all_anon.dta", clear
di as txt "Loaded PS Parents anonymised data: `c(N)' obs, `c(k)' vars"

duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di as txt "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
* 2. MERGE WITH SENSITIVE DATA FOR DUPLICATE CHECKS
********************************************************************************

merge 1:1 ResponseId using "${sensitive_data}/ps_par_sensitive_only.dta", ///
    keep(match master) keepusing(email child_first_name child_last_name) nogen

********************************************************************************
* 3. CHECK DUPLICATES BASED ON EMAIL AND CHILD NAME
********************************************************************************

duplicates tag email if !missing(email), gen(dup_email)
egen email_group = group(email) if dup_email >= 1, label

duplicates tag child_first_name child_last_name if ///
    !missing(child_first_name, child_last_name), gen(dup_name)
egen name_group = group(child_first_name child_last_name) if dup_name >= 1, label

********************************************************************************
* 4. RANK & DROP NON-FINAL RESPONSES
********************************************************************************

format StartDate %tc

bysort email_group: egen email_group_order = rank(-StartDate) if !missing(email_group)
bysort name_group:  egen name_group_order  = rank(-StartDate) if !missing(name_group)

drop if (email_group_order > 1 & !missing(email_group)) | ///
        (name_group_order > 1 & !missing(name_group))

********************************************************************************
* 5. CLEAN UP AND SAVE
********************************************************************************

drop email child_first_name child_last_name dup_email dup_name ///
    email_group name_group *_order

compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

log close
