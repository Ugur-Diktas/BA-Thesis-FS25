********************************************************************************
// 2_ps_parents_remove_duplicates.do
// Purpose : Removes duplicates, excludes bad-quality obs, renames key vars, etc.
//           for the PS_Parents anonymised data.
//
// Author  : Ugur Diktas
// Project : BA Thesis FS25
// Date    : 12.02.2025
//
// Steps   :
//    1) Load the anonymised data from ${processed_data}/PS_Parents/ps_par_all_anon.dta
//    2) (Optionally) drop partial/ test obs if "status" or "StartDate" exist
//    3) Check duplicates on ResponseId
//    4) Exclude missing e-mail if needed
//    5) Rename contract -> has_contract
//    6) Save to temp_parents_step2.dta
********************************************************************************

clear all
set more off

// Start logging
cap log close
log using "${dodir_log}/ps_parents_remove_duplicates.log", replace

version 17.0

// Optional timer
timer clear
timer on 1

// 1. Load anonymised data
use "${processed_data}/PS_Parents/ps_par_all_anon.dta", clear
di as txt "INFO: Loaded `=_N' obs from ps_par_all_anon.dta"

// 2. If variable "status" exists, remove partial info
capture confirm variable status
if _rc == 0 {
    quietly count if status == 1
    if r(N) > 0 {
        di as txt "INFO: Dropping `r(N)' obs with status==1"
        drop if status == 1
    }
}

// If "StartDate" exists, drop if < certain date
capture confirm variable StartDate
if _rc == 0 {
    format StartDate %tc
    quietly count if StartDate < clock("2024-11-11 10:00:00", "YMDhms")
    if r(N) > 0 {
        di as txt "INFO: Dropping `r(N)' obs that started before 2024-11-11 10:00"
        drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms")
    }
}

// 3. Remove duplicates based on ResponseId
capture confirm variable ResponseId
if _rc != 0 {
    di as error "ERROR: ResponseId not found. Are you sure you have the right dataset?"
    error 601
}
duplicates report ResponseId
duplicates tag ResponseId, gen(dup_id)
quietly count if dup_id>0
if r(N) > 0 {
    di as txt "INFO: Dropping `r(N)' duplicates on ResponseId"
    drop if dup_id>0
}
drop dup_id

// 4. Exclude missing e-mail if needed
capture confirm variable compl_email
if _rc == 0 {
    quietly count if missing(compl_email)
    if r(N) > 0 {
        di as txt "INFO: Dropping `r(N)' obs that have missing compl_email"
        drop if missing(compl_email)
    }
}

// 5. Rename or relabel key variables if they exist
capture confirm variable contract
if _rc == 0 {
    rename contract has_contract
    label var has_contract "Has an apprenticeship contract"
}

// 6. Save intermediate
save "${processed_data}/PS_Parents/temp_parents_step2.dta", replace
di as txt "INFO: Saved `=_N' obs to temp_parents_step2.dta"

// Timer end
timer off 1
timer list 1
log close
