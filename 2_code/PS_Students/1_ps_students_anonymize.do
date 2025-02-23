********************************************************************************
* 1_ps_students_anonymize.do
* 
* Purpose: 
*   - Import **all** PS Students .sav files (finished & unfinished) using a 
*     wildcard approach (PoF_PS_Students*.sav).
*   - Remove test/preliminary responses.
*   - Identify duplicates and produce compliance indicators (email, names).
*   - Save sensitive data (IP, location, email, names) to a separate file.
*   - Save an anonymised version of the data (with sensitive variables dropped).
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 12.02.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

* Conditionally enable trace if debugging is requested
if "${debug}" == "yes" {
    set trace on
} 
else {
    set trace off
}

* Start logging
cap log close
log using "${dodir_log}/ps_students_anonymize.log", replace

********************************************************************************
* 1. LOAD THE DATA
*    - Import and combine all .sav files matching "PoF_PS_Students*.sav"
********************************************************************************

local initial_dir "`c(pwd)'"   // preserve current directory
cd "${raw_data}"

* Identify all matching .sav files
local stufiles : dir . files "PoF_PS_Students*.sav"

* If no files found, throw an error
if `:word count `stufiles'' == 0 {
    di as error "ERROR: No student .sav file found."
    cd "`initial_dir'"
    error 601
}

* Temporary file to hold combined data
tempfile combined
save `combined', emptyok

local Nfiles = `:word count `stufiles''

* Loop through all .sav files and append them
forval i = 1/`Nfiles' {
    local thisfile : word `i' of `stufiles'
    di as txt "Importing file #`i': `thisfile'"
    
    import spss using "`thisfile'", clear
    
    if `i' == 1 {
        save `combined', replace
    }
    else {
        tempfile nextpart
        save `nextpart', replace
        
        use `combined', clear
        append using `nextpart'
        
        save `combined', replace
    }
}

use `combined', clear   // final combined dataset in memory
cd "`initial_dir'"      // revert to original directory

********************************************************************************
* 2. DROP TEST DATA
********************************************************************************

drop if inlist(email, ///
    "daphne.rutnam@econ.uzh.ch", ///
    "hannah.massenbauer@econ.uzh.ch", ///
    "anne.brenoe@econ.uzh.ch", ///
    "gianluca.spina@bluewin.ch", ///
    "cambriadaniele@gmail.com", ///
    "hannah.massenbauer@gmail.com", ///
    "daphne.rutnam@gmail.com") ///
    | strpos(email, "uzh.ch") > 0

drop if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")

* Drop Qualtrics preview (Status == 1)
drop if Status == 1

********************************************************************************
* 3. CHECK DUPLICATES ON ResponseId
********************************************************************************

duplicates tag ResponseId, gen(dup_responseid)
if `r(N)' > 0 {
    di "Dropping `r(N)' duplicates on ResponseId"
    drop if dup_responseid > 0
}
drop dup_responseid

********************************************************************************
* 4. PREPARE DUPLICATES CLEANING
********************************************************************************

gen compl_email      = !missing(email)
gen compl_first_name = !missing(name_child_1)
gen compl_last_name  = !missing(name_child_2)

label var compl_email      "Provided email"
label var compl_first_name "Provided first name"
label var compl_last_name  "Provided last name"

********************************************************************************
* 5. SENSITIVE DATA ONLY
********************************************************************************

preserve
    keep ResponseId IPAddress LocationLatitude LocationLongitude email ///
         name_child_1 name_child_2
    rename (LocationLatitude LocationLongitude name_child_1 name_child_2) ///
           (location_lat location_long stu_first_name stu_last_name)
    destring location_lat location_long, replace
    save "${sensitive_data}/ps_stu_sensitive_only.dta", replace
restore

drop IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2

********************************************************************************
* 6. FINAL HOUSEKEEPING & SAVE
********************************************************************************

save "${processed_data}/PS_Students/ps_stu_all_anon.dta", replace

log close
