********************************************************************************
* 1_ps_students_anonymize.do
* ------------------------------------------------------------------------------
* Data needed: raw_data files
* Data output: ps_stu_all_anon.dta
* Purpose: 
*   - Import **all** PS Students .sav files (finished & unfinished) using a 
*     wildcard approach (PoF_PS_Students*.sav).
*   - Remove test/preliminary responses (by email, test names, preview status,
*     and official StartDate).
*   - Save sensitive data (IP, location, email, names) to a separate file.
*   - Save an anonymised version of the data (with sensitive variables dropped).
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

* Start logging
cap log close
log using "${dodir_log}/1_ps_students_anonymize.log", replace text

* Conditionally enable trace if debugging is requested
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Anonymization"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE DATA
*    - Import and combine all .sav files matching "PoF_PS_Students*.sav"
********************************************************************************

local initial_dir "`c(pwd)'"   // preserve current directory

* Check raw data directory exists
capture confirm file "${raw_data}/."
if _rc {
    di as error "ERROR: Raw data directory not found: ${raw_data}"
    exit 601
}

cd "${raw_data}"
di as txt "Changed to raw data directory: `c(pwd)'"

* Identify all matching .sav files
local stufiles : dir . files "PoF_PS_Students*.sav"

* If no files found, throw an error
if `:word count `stufiles'' == 0 {
    di as error "ERROR: No student .sav file found. Please check ${raw_data} for files matching PoF_PS_Students*.sav"
    cd "`initial_dir'"
    exit 601
}

* Report files found
di as txt "Found `:word count `stufiles'' files matching pattern:"
foreach file of local stufiles {
    di as txt "  - `file'"
}

* Temporary file to hold combined data
tempfile combined
save `combined', emptyok

local Nfiles = `:word count `stufiles''

* Loop through all .sav files and append them
forval i = 1/`Nfiles' {
    local thisfile : word `i' of `stufiles'
    di as txt "Importing file #`i' of `Nfiles': `thisfile'"
    
    capture noisily import spss using "`thisfile'", clear
    if _rc {
        di as error "ERROR: Could not import file `thisfile'. Error code: `_rc'"
        continue
    }
    
    * Count observations
    local obs = _N
    di as txt "  Imported `obs' observations."
    
    if `i' == 1 {
        save `combined', replace
    }
    else {
        tempfile nextpart
        save `nextpart', replace
        
        use `combined', clear
        capture append using `nextpart'
        if _rc {
            di as error "ERROR: Could not append file #`i'. Error code: `_rc'"
            continue
        }
        
        save `combined', replace
    }
}

use `combined', clear   // final combined dataset in memory
local total_obs = _N
di as txt "Total observations from all files: `total_obs'"

cd "`initial_dir'"      // revert to original directory

********************************************************************************
* 2. DROP TEST ANSWERS
*    - Remove test/preliminary responses based on:
*         a) Email addresses (and domains)
*         b) Test names in name_child_1 and name_child_2
*         c) Qualtrics preview responses (Status == 1)
*         d) Responses before a given StartDate
********************************************************************************

* Count initial observations
local initial_obs = _N
di as txt "Initial observations: `initial_obs'"

* Drop test emails and any responses containing "uzh.ch"
di as txt "Dropping test email addresses..."
capture confirm variable email
if !_rc {
    local drop_count = 0
    count if inlist(email, ///
        "daphne.rutnam@econ.uzh.ch", ///
        "hannah.massenbauer@econ.uzh.ch", ///
        "anne.brenoe@econ.uzh.ch", ///
        "gianluca.spina@bluewin.ch", ///
        "cambriadaniele@gmail.com", ///
        "hannah.massenbauer@gmail.com", ///
        "daphne.rutnam@gmail.com") ///
        | strpos(email, "uzh.ch") > 0
    local drop_count = r(N)
    
    drop if inlist(email, ///
        "daphne.rutnam@econ.uzh.ch", ///
        "hannah.massenbauer@econ.uzh.ch", ///
        "anne.brenoe@econ.uzh.ch", ///
        "gianluca.spina@bluewin.ch", ///
        "cambriadaniele@gmail.com", ///
        "hannah.massenbauer@gmail.com", ///
        "daphne.rutnam@gmail.com") ///
        | strpos(email, "uzh.ch") > 0
        
    di as txt "  Dropped `drop_count' test email addresses."
}
else {
    di as txt "  Email variable not found, skipping email-based filtering."
}

* Drop test responses based on test names
di as txt "Dropping responses with test names..."
capture confirm variable name_child_1
capture confirm variable name_child_2
if !_rc {
    local drop_count = 0
    count if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")
    local drop_count = r(N)
    
    drop if inlist(name_child_1, "test", "Test") | inlist(name_child_2, "test", "Test")
    
    di as txt "  Dropped `drop_count' responses with test names."
}
else {
    di as txt "  Name variables not found, skipping name-based filtering."
}

* Drop Qualtrics preview responses
di as txt "Dropping Qualtrics preview responses..."
capture confirm variable Status
if !_rc {
    local drop_count = 0
    count if Status == 1
    local drop_count = r(N)
    
    drop if Status == 1
    
    di as txt "  Dropped `drop_count' preview responses."
}
else {
    di as txt "  Status variable not found, skipping preview response filtering."
}

* Drop responses before the official start date
di as txt "Dropping responses before the official start date..."
capture confirm variable StartDate
if !_rc {
    format StartDate %tc
    
    local drop_count = 0
    count if StartDate < clock("2024-11-11 10:00:00", "YMDhms")
    local drop_count = r(N)
    
    drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms")
    
    di as txt "  Dropped `drop_count' responses before official start date."
}
else {
    di as txt "  StartDate variable not found, skipping date-based filtering."
}

* Report total dropped
local final_obs = _N
local total_dropped = `initial_obs' - `final_obs'
di as txt "Total observations dropped: `total_dropped' (`=round(`total_dropped'/`initial_obs'*100, 0.1)'% of initial data)"
di as txt "Remaining observations: `final_obs'"

********************************************************************************
* 3. SENSITIVE DATA ONLY
********************************************************************************

di as txt "Extracting sensitive data..."

* Ensure sensitive data directory exists
capture confirm file "${sensitive_data}/."
if _rc {
    mkdir "${sensitive_data}"
}

* Create dataset with sensitive information
preserve
    * Keep only sensitive variables and the ResponseId as key
    keep ResponseId IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2
    
    * Rename for clarity
    rename (LocationLatitude LocationLongitude name_child_1 name_child_2) ///
           (location_lat location_long stu_first_name stu_last_name)
    
    * Convert geographic coordinates to numeric if needed
    capture destring location_lat location_long, replace
    
    * Report counts of non-missing sensitive data
    foreach var of varlist location_lat location_long email stu_first_name stu_last_name {
        count if !missing(`var')
        di as txt "  `var': `r(N)' non-missing values"
    }
    
    * Save sensitive data
    save "${sensitive_data}/ps_stu_sensitive_only.dta", replace
    di as txt "Sensitive data saved to: ${sensitive_data}/ps_stu_sensitive_only.dta"
restore

* Drop sensitive variables from main dataset
drop IPAddress LocationLatitude LocationLongitude email name_child_1 name_child_2
di as txt "Sensitive variables removed from main dataset."

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************

* Ensure processed data directory exists
capture confirm file "${processed_data}/PS_Students/."
if _rc {
    mkdir "${processed_data}/PS_Students"
}

* Compress and save anonymized dataset
compress
save "${processed_data}/PS_Students/1_ps_students.dta", replace

* Final report
di as txt "Anonymized data saved to: ${processed_data}/PS_Students/1_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Anonymization"
di as txt "======================================================="

log close
set trace off