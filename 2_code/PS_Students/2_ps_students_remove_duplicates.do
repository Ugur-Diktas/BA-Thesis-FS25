********************************************************************************
// 2_ps_students_remove_duplicates.do
// Purpose : Merges with sensitive data to identify duplicates based on email/names,
//           removes non-first responses, and saves cleaned dataset.
// Author  : Ugur Diktas, BA Thesis FS25, 12.02.2025
********************************************************************************

clear all
set more off
version 17.0

// Start logging
cap log close
log using "${dodir_log}/ps_students_remove_duplicates.log", replace

// Load anonymized data
use "${processed_data}/PS_Students/ps_stu_all_anon.dta", clear

// Merge with sensitive data for duplicate checks
merge 1:1 ResponseId using "${sensitive_data}/ps_stu_sensitive_only.dta", ///
    keep(match master) keepusing(email stu_first_name stu_last_name) nogen

// Check email duplicates
duplicates tag email if !missing(email), gen(dup_email)
egen email_group = group(email) if dup_email >= 1, label

// Check name duplicates
duplicates tag stu_first_name stu_last_name if !missing(stu_first_name, stu_last_name), gen(dup_name)
egen name_group = group(stu_first_name stu_last_name) if dup_name >= 1, label

// Rank responses by startdate
format StartDate %tc
bysort email_group : egen email_group_order = rank(StartDate) if !missing(email_group)
bysort name_group  : egen name_group_order  = rank(StartDate) if !missing(name_group)

// Drop non-first responses
drop if (email_group_order > 1 & !missing(email_group)) | (name_group_order > 1 & !missing(name_group))

// Drop sensitive vars and groups
drop email stu_first_name stu_last_name dup_email dup_name email_group name_group *_order

// Finalize dataset
compress
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

// Close log
log close