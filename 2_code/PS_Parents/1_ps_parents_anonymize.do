********************************************************************************
* 1_ps_parents_anonymize.do
*
* Purpose:
* - Import raw PS Parents .sav file(s).
* - Remove test/preliminary responses based on test emails, preview status,
*   official start date, etc.
* - Save sensitive data (IP, location, email, child name) separately.
* - Save anonymised version of the dataset.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

* Enable trace if debug mode is on
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

* Start logging
cap log close
log using "${dodir_log}/1_ps_parents_anonymize.log", replace text

********************************************************************************
* 1. LOAD THE DATA
********************************************************************************

local initial_dir "`c(pwd)'"
cd "${raw_data}"

* Find raw PS_Parents .sav file(s). Adjust wildcard if needed
local parfiles : dir . files "PoF_PS_Parents*.sav"
if `:word count `parfiles'' == 0 {
    di as error "ERROR: No PS Parents .sav file found in raw data folder."
    cd "`initial_dir'"
    error 601
}

di as txt "Importing PS Parents file: `:word 1 of `parfiles''"
import spss using "`:word 1 of `parfiles''", clear

cd "`initial_dir'"

********************************************************************************
* 2. DROP TEST RESPONSES
********************************************************************************

* Drop test emails and any containing "uzh.ch"
drop if inlist(email, ///
    "daphne.rutnam@econ.uzh.ch", ///
    "hannah.massenbauer@econ.uzh.ch", ///
    "anne.brenoe@econ.uzh.ch", ///
    "gianluca.spina@bluewin.ch", ///
    "cambriadaniele@gmail.com", ///
    "hannah.massenbauer@gmail.com", ///
    "daphne.rutnam@gmail.com") | ///
    strpos(email, "uzh.ch") > 0

* Drop test responses based on child names
drop if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")

* Drop Qualtrics preview responses
drop if Status == 1

* Drop responses before official start date
format StartDate %tc
drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms")

********************************************************************************
* 3. SENSITIVE DATA & ANONYMISED DATA
********************************************************************************

preserve
keep ResponseId IPAddress LocationLatitude LocationLongitude email ///
     name_child_1 name_child_2
rename (LocationLatitude LocationLongitude name_child_1 name_child_2) ///
       (location_lat location_long child_first_name child_last_name)
destring location_lat location_long, replace
save "${sensitive_data}/ps_par_sensitive_only.dta", replace
restore

* Drop sensitive variables
drop IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2

* Save anonymised data
save "${processed_data}/PS_Parents/ps_par_all_anon.dta", replace

log close
