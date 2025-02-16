********************************************************************************
// 1_ps_students_anonymize.do
// Purpose : Imports raw PS Students data, drops test responses, removes ResponseID duplicates,
//           saves sensitive data, and generates anonymized dataset with compliance indicators.
// Author  : Ugur Diktas, BA Thesis FS25, 12.02.2025
********************************************************************************

clear all
set more off
version 17.0

// Start logging
cap log close
log using "${dodir_log}/ps_students_anonymize.log", replace

// Preserve current directory
local initial_dir "`c(pwd)'"

// Import raw data
cd "${raw_data}"
local stufile : dir . files "PoF_PS_Students*.sav"
if `:word count `stufile'' == 0 {
    di as error "ERROR: No student .sav file found."
    cd "`initial_dir'"
    error 601
}
import spss using "`:word 1 of `stufile''", clear

// Drop test responses
drop if inlist(email, "daphne.rutnam@econ.uzh.ch", "hannah.massenbauer@econ.uzh.ch", "anne.brenoe@econ.uzh.ch", "gianluca.spina@bluewin.ch", "cambriadaniele@gmail.com", "hannah.massenbauer@gmail.com", "daphne.rutnam@gmail.com") | strpos(email, "uzh.ch") > 0
drop if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")

// Check ResponseId duplicates
duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

// Generate compliance indicators
gen compl_email      = !missing(email)
gen compl_first_name = !missing(name_child_1)
gen compl_last_name  = !missing(name_child_2)
label var compl_email      "Provided email"
label var compl_first_name "Provided first name"
label var compl_last_name  "Provided last name"

// Save sensitive data
preserve
    keep ResponseId IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2
    rename (LocationLatitude LocationLongitude name_child_1 name_child_2) (location_lat location_long stu_first_name stu_last_name)
    destring location_lat location_long, replace
    save "${sensitive_data}/ps_stu_sensitive_only.dta", replace
restore

// Drop sensitive vars and save anonymized data
drop IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2
save "${processed_data}/PS_Students/ps_stu_all_anon.dta", replace

// Restore directory and close log
cd "`initial_dir'"
log close