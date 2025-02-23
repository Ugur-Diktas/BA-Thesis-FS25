********************************************************************************
// 1_ps_parents_anonymize.do
// Purpose : Imports raw PS parents data (auto-detect .sav), merges with 
//           sensitive info, drops direct identifiers, saves anonymised.
//
// Author  : Ugur Diktas-Jelke Clarysse
// Project : BA Thesis FS25
// Date    : 19.02.2025
//
// Steps   :
//    1) Preserve current working directory and cd into the raw data folder
//    2) Find file matching ^PoF_PS_Parents*.sav
//    3) import spss using that .sav
//    4) Run advanced anonymising steps (duplicates, drops test e-mails, etc.)
//    5) Save sensitive data & anonymised data, then restore the original directory
//
// Requires: 
//    - 2_globals.do must be run beforehand so that ${raw_data}, etc. are defined
//    - A file in the raw folder named PoF_PS_Parents*.sav
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************
clear all
set more off
version 17.0

// Start logging
cap log close
log using "${dodir_log}/ps_parentss_anonymize.log", replace

********************************************************************************
// 1. LOAD THE DATA
********************************************************************************

// Preserve current directory
local initial_dir "`c(pwd)'"

// Import raw data
cd "${raw_data}"
local stufile : dir . files "PoF_PS_Parents*.sav"
if `:word count `stufile'' == 0 {
    di as error "ERROR: No parents .sav file found."
    cd "`initial_dir'"
    error 601
}
import spss using "`:word 1 of `stufile''", clear
********************************************************************************
// 2. DROP TEST DATA 
********************************************************************************

//drop e-mails and tests 
drop if inlist(email, "daphne.rutnam@econ.uzh.ch", "hannah.massenbauer@econ.uzh.ch", "anne.brenoe@econ.uzh.ch", "gianluca.spina@bluewin.ch", "cambriadaniele@gmail.com", "hannah.massenbauer@gmail.com", "daphne.rutnam@gmail.com") | strpos(email, "uzh.ch") > 0
drop if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")

// Drop preview responses

drop if Status == 1

********************************************************************************
// 3. CHECK DUPLICATES
********************************************************************************

duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
// 4. PREPARE DUPLICATES CLEANING
********************************************************************************

// Generate compliance indicators
gen compl_email      = !missing(email)
gen compl_first_name = !missing(name_child_1)
gen compl_last_name  = !missing(name_child_2)
label var compl_email      "Provided email"
label var compl_first_name "Provided first name"
label var compl_last_name  "Provided last name"

********************************************************************************
// 5.SENSITIVE DATA ONLY
********************************************************************************

// Save sensitive data
preserve
    keep ResponseId IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2
    rename (LocationLatitude LocationLongitude name_child_1 name_child_2) (location_lat location_long stu_first_name stu_last_name)
    destring location_lat location_long, replace
    save "${sensitive_data}/ps_par_sensitive_only.dta", replace
restore
// Drop sensitive vars and save anonymized data
drop IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2

********************************************************************************
// 6. FINAL HOUSEKEEPING & SAVE
********************************************************************************
save "${processed_data}/PS_Parents/ps_par_all_anon.dta", replace

// Restore directory and close log
cd "`initial_dir'"
log close
