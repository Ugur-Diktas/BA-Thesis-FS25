********************************************************************************
// 1_ps_parents_anonymize.do
// Purpose : Imports raw PS parents data (auto-detect .sav), merges with 
//           sensitive info, drops direct identifiers, saves anonymised.
//
// Author  : Ugur Diktas-Jelke Clarysse
// Project : BA Thesis FS25
// Date    : 12.02.2025
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

// Start logging
cap log close
log using "${dodir_log}/ps_parents_anonymize.log", replace

version 17.0

// 1) Preserve the current working directory in a local macro
local initial_dir "`c(pwd)'"

// Change directory to raw data folder
cd "${raw_data}"

********************************************************************************
// 1.GET DATA
********************************************************************************

// 2) Find file matching PoF_PS_Parents*.sav
local allParFiles: dir . files "*.sav"
local parfiles ""
foreach f of local allParFiles {
    if regexm("`f'", "^PoF_PS_Parents") {
        local parfiles `parfiles' "`f'"
    }
}

if "`parfiles'" == "" {
    di as error "ERROR: No .sav file found that starts with PoF_PS_Parents in `c(pwd)'"
    cd "`initial_dir'"
    error 201
}

// If multiple matches, pick the first
local parfile : word 1 of `parfiles'
di as txt "INFO: Found parent raw file: `parfile'"

// 3) Import from SPSS
import spss using "`parfile'", clear
di as txt "INFO: Imported PS Parents data from `parfile' with `=_N' obs."

********************************************************************************
// 3. ANONYMISING
********************************************************************************

// ----------------------------------------------------------------------------
// 4) Advanced anonymising steps (matching old code by Daphne)
// ----------------------------------------------------------------------------

timer clear
timer on 1

set seed 123

// 4.1 Duplicates on ResponseId (capital R, as in the Qualtrics data)
duplicates report ResponseId, list
duplicates tag ResponseId, gen(dup_ResponseId)
assert dup_ResponseId == 0
drop dup_ResponseId


// 4.2 Drop test responses identified by sensitive data
gen email_sum = ""
replace email_sum = email if email != "" & email_el == ""
replace email_sum = email_el if email_el != "" & email == ""

// Known test e-mails
drop if email_sum == "daphne.rutnam@econ.uzh.ch"
drop if email_sum == "hannah.massenbauer@econ.uzh.ch"
drop if email_sum == "anne.brenoe@econ.uzh.ch"
drop if email_sum == "gianluca.spina@bluewin.ch"
drop if email_sum == "cambriadaniele@gmail.com"
drop if email_sum == "hannah.massenbauer@gmail.com"
drop if email_sum == "daphne.rutnam@gmail.com"
drop if strpos(email_sum, "uzh.ch") >= 0

drop if name_child_1 == "test" | name_child_1 == "Test"
drop if name_child_2 == "test" | name_child_2 == "Test"

// 4.3 Duplicates cleaning
duplicates report email_sum if email_sum != ""
duplicates tag email_sum if !missing(email_sum), gen(dup_email)
egen email_group = group(email_sum) if !missing(email_sum) & dup_email >= 1

duplicates report name_child_1 name_child_2 parent_type_ ///
    if !missing(name_child_1) & !missing(name_child_2) & !missing(parent_type_)
duplicates tag name_child_1 name_child_2 parent_type_, gen(dup_name_parent)
egen name_group = group(name_child_1 name_child_2 parent_type_) ///
    if !missing(name_child_1) & !missing(name_child_2) & !missing(parent_type_) & dup_name_parent >= 1

// Drop no longer needed vars for e-mail
drop email email_el_ email_rep email_rep_el_

// 4.4 Generate indicators
gen compl_email = (email_sum != "")
label variable compl_email "Gave email address"
gen compl_first_name = !missing(name_child_1)
gen compl_last_name  = !missing(name_child_2)

// 4.5 Save sensitive data
local sens_vars "IPAddress LocationLatitude LocationLongitude email_sum name_child_1 name_child_2"

preserve
    keep ResponseId `sens_vars'
    rename LocationLatitude location_lat
    rename LocationLongitude location_long
    rename email_sum email
    rename name_child_1 stu_first_name
    rename name_child_2 stu_last_name

    destring location_lat, replace
    destring location_long, replace

    label var location_lat   "Location: latitude"
    label var location_long  "Location: longitude"
    label var IPAddress      "IP address"
    label var email          "Email"
    label var stu_first_name "Student's first name"
    label var stu_last_name  "Student's last name"
    order ResponseId stu_first_name stu_last_name email IPAddress location_lat location_long

    save "${sensitive_data}/ps_par_sensitive_only", replace
restore

// 4.6 Save anonymised data
drop `sens_vars'
save "${processed_data}/PS_Parents/ps_par_all_anon.dta", replace

di as txt "INFO: Created anonymised dataset for PS_Parents -> ps_par_all_anon.dta."

timer off 1
timer list 1

// 5) Restore the original working directory
cd "`initial_dir'"

log close
