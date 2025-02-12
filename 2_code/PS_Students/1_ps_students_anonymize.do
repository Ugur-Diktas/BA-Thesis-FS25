********************************************************************************
// 1_ps_students_anonymize.do
// Purpose : Imports raw PS students data (auto-detect .sav), merges with 
//           sensitive info, drops direct identifiers, saves anonymised.
//
// Author  : Ugur Diktas
// Project : BA Thesis FS25
// Date    : 12.02.2025
//
// Steps   :
//    1) Preserve current working directory and cd into the raw data folder
//    2) Find file matching ^PoF_PS_Students*.sav
//    3) Import SPSS using that .sav
//    4) Run advanced anonymising steps (incl. remove duplicates)
//    5) Save sensitive data & anonymised data, then restore the original directory
//
// Requires: 
//    - 2_globals.do must be run beforehand so that ${raw_data}, etc. are defined
//    - A file in the raw folder named PoF_PS_Students*.sav
********************************************************************************

clear all
set more off

// Start logging
cap log close
log using "${dodir_log}/ps_students_anonymize.log", replace

version 17.0

// 1) Preserve the current working directory in a local macro
local initial_dir "`c(pwd)'"

// Change directory to raw data folder
cd "${raw_data}"

// 2) Search for any .sav file that starts with PoF_PS_Students
local allsavfiles: dir . files "*.sav"
local stufiles ""
foreach f of local allsavfiles {
    if regexm("`f'", "^PoF_PS_Students") {
        local stufiles `stufiles' "`f'"
    }
}

if "`stufiles'" == "" {
    di as error "ERROR: No .sav file found in `c(pwd)' that starts with PoF_PS_Students"
    cd "`initial_dir'"  // restore original directory before exiting
    error 101
}

// If multiple matches, pick the first file
local stufile : word 1 of `stufiles'
di as txt "INFO: Found student raw file: `stufile'"

// 3) Import from SPSS
import spss using "`stufile'", clear
di as txt "INFO: Imported PS Students data from `stufile' with `=_N' obs."

// ----------------------------------------------------------------------------
// 4) Advanced anonymising steps
// ----------------------------------------------------------------------------

// 4.1 Timer (optional)
timer clear
timer on 1

// 4.2 Set seed if randomisation is used
set seed 123

// 4.3 Check duplicates on ResponseId (from second file's approach)
//     Replace the original "assert" mechanism with the drop-based approach.
duplicates report ResponseId, list
duplicates tag ResponseId, gen(dup_ResponseId)

quietly count if dup_ResponseId > 0
if r(N) > 0 {
    di as txt "INFO: Dropping `r(N)' duplicates on ResponseId"
    drop if dup_ResponseId > 0
}
else {
    di as txt "INFO: No duplicates found on ResponseId"
}
drop dup_ResponseId

// 4.4 (Optional) Exclude missing e-mail if needed (from second file's approach)
//     This is only done if you truly want to drop any obs that have missing email.
capture confirm variable compl_email
if _rc == 0 {
    quietly count if missing(compl_email)
    if r(N) > 0 {
        di as txt "INFO: Dropping `r(N)' obs that have missing compl_email"
        drop if missing(compl_email)
    }
}

// 4.5 Drop test responses identified by known e-mails or names
drop if email == "daphne.rutnam@econ.uzh.ch"
drop if email == "hannah.massenbauer@econ.uzh.ch"
drop if email == "anne.brenoe@econ.uzh.ch"
drop if email == "gianluca.spina@bluewin.ch"
drop if email == "cambriadaniele@gmail.com"
drop if email == "hannah.massenbauer@gmail.com"
drop if email == "daphne.rutnam@gmail.com"
drop if strpos(email, "uzh.ch") >= 0

drop if name_child_1 == "test" | name_child_1 == "Test"
drop if name_child_2 == "test" | name_child_2 == "Test"

// 4.6 Identify duplicates or grouping on email and name (the existing mechanism)
quietly count if !missing(email)
if r(N) > 0 {
    duplicates report email if !missing(email)
    duplicates tag email if !missing(email), gen(dup_email)
    egen email_group = group(email) if !missing(email) & dup_email >= 1
}
else {
    di as txt "NOTE: No non-missing emails to check for duplicates"
    gen dup_email = .
    gen email_group = .
}

quietly count if !missing(name_child_1) & !missing(name_child_2)
if r(N) > 0 {
    duplicates report name_child_1 name_child_2 if !missing(name_child_1) & !missing(name_child_2)
    duplicates tag name_child_1 name_child_2 if !missing(name_child_1) & !missing(name_child_2), gen(dup_name)
    egen name_group = group(name_child_1 name_child_2) if !missing(name_child_1) & !missing(name_child_2) & dup_name >= 1
}
else {
    di as txt "NOTE: No complete name pairs to check for duplicates"
    gen dup_name = .
    gen name_group = .
}

// 4.7 Generate indicators (unchanged)
gen compl_email = (email != "")             if !_rc
label variable compl_email "Gave email address"

gen compl_first_name = !missing(name_child_1)
gen compl_last_name  = !missing(name_child_2)

// 4.8 Save sensitive data only
local sens_vars "IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2"

preserve
    keep ResponseId `sens_vars'
    rename LocationLatitude location_lat
    rename LocationLongitude location_long
    rename name_child_1 stu_first_name
    rename name_child_2 stu_last_name
    
    destring location_lat, replace
    destring location_long, replace
    
    lab var location_lat   "Location: latitude"
    lab var location_long  "Location: longitude"
    lab var IPAddress      "IP address"
    lab var email          "Email"
    lab var stu_first_name "Student's first name"
    lab var stu_last_name  "Student's last name"
    order ResponseId stu_first_name stu_last_name email IPAddress location_lat location_long
    
    save "${sensitive_data}/ps_stu_sensitive_only", replace
restore

// 4.9 Save anonymised data
drop `sens_vars'
save "${processed_data}/PS_Students/ps_stu_all_anon.dta", replace
di as txt "INFO: Created anonymised dataset for PS_Students -> ps_stu_all_anon.dta."

// 4.10 Timer end
timer off 1
timer list 1

// 5) Restore the original working directory
cd "`initial_dir'"

log close
