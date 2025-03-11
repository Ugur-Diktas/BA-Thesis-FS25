********************************************************************************
* 1_ps_parents_anonymize.do
* ------------------------------------------------------------------------------
* Data needed: raw_data files
* Data output: ps_par_all_anon.dta
* Purpose:
*   - Import **all** PS Parents .sav files (finished & unfinished) using a 
*     wildcard approach (PoF_PS_Parents*.sav).
*   - Remove test/preliminary responses (by email, test names, preview status,
*     and official StartDate).
*   - Save sensitive data (IP, location, parent email and names) to a separate file.
*   - Save an anonymised version of the data (with sensitive variables dropped).
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 10.03.2025
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
log using "${dodir_log}/1_ps_parents_anonymize.log", replace text

* Conditionally enable trace if debugging is requested
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Anonymization"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE DATA
*    a. Import and combine all .sav files matching "PoF_PS_Parents*.sav"
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
local parfiles : dir . files "PoF_PS_Parents*.sav"

* If no files found, throw an error
if `:word count `parfiles'' == 0 {
    di as error "ERROR: No PS Parents .sav file found. Please check ${raw_data} for files matching PoF_PS_Parents*.sav"
    cd "`initial_dir'"
    exit 601
}

* Report files found
di as txt "Found `:word count `parfiles'' files matching pattern:"
foreach file of local parfiles {
    di as txt "  - `file'"
}

* Temporary file to hold combined data
tempfile combined
save `combined', emptyok

local Nfiles = `:word count `parfiles''

* Loop through all .sav files and append them
forval i = 1/`Nfiles' {
    local thisfile : word `i' of `parfiles'
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
* 2. DROP TEST RESPONSES
*    - Remove test/preliminary responses based on:
*         a) Parent email addresses (and domains)
*         b) Test names in RecipientFirstName / RecipientLastName (if applicable)
*         c) Qualtrics preview responses (Status == 1)
*         d) Responses before the official StartDate
********************************************************************************

* Count initial observations
local initial_obs = _N
di as txt "Initial observations: `initial_obs'"

* Drop test emails and any responses containing "uzh.ch" based on RecipientEmail
di as txt "Dropping test email addresses..."
capture confirm variable RecipientEmail
if !_rc {
    local drop_count = 0
    count if inlist(RecipientEmail, ///
        "daphne.rutnam@econ.uzh.ch", ///
        "hannah.massenbauer@econ.uzh.ch", ///
        "anne.brenoe@econ.uzh.ch", ///
        "gianluca.spina@bluewin.ch", ///
        "cambriadaniele@gmail.com", ///
        "hannah.massenbauer@gmail.com", ///
        "daphne.rutnam@gmail.com") ///
        | strpos(RecipientEmail, "uzh.ch") > 0
    local drop_count = r(N)
    
    drop if inlist(RecipientEmail, ///
        "daphne.rutnam@econ.uzh.ch", ///
        "hannah.massenbauer@econ.uzh.ch", ///
        "anne.brenoe@econ.uzh.ch", ///
        "gianluca.spina@bluewin.ch", ///
        "cambriadaniele@gmail.com", ///
        "hannah.massenbauer@gmail.com", ///
        "daphne.rutnam@gmail.com") ///
        | strpos(RecipientEmail, "uzh.ch") > 0
        
    di as txt "  Dropped `drop_count' test email addresses."
}
else {
    di as txt "  RecipientEmail variable not found, skipping email-based filtering."
}

* Drop test responses based on parent names if needed:
di as txt "Dropping responses with test names..."
local name_vars_exist = 1
foreach var in RecipientFirstName RecipientLastName {
    capture confirm variable `var'
    if _rc {
        local name_vars_exist = 0
    }
}

if `name_vars_exist' {
    local drop_count = 0
    count if inlist(RecipientFirstName, "test", "Test") | inlist(RecipientLastName, "test", "Test")
    local drop_count = r(N)
    
    drop if inlist(RecipientFirstName, "test", "Test") | inlist(RecipientLastName, "test", "Test")
    
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
local drop_pct = round(`total_dropped'/`initial_obs'*100, 0.1)
di as txt "Total observations dropped: `total_dropped' (`drop_pct'% of initial data)"
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

preserve
    * Keep parent's sensitive information: ResponseId, IPAddress, location, 
    * RecipientEmail, RecipientFirstName, RecipientLastName
    keep ResponseId IPAddress LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName
    rename (LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName) ///
           (location_lat location_long par_email par_first_name par_last_name)
    
    * Convert geographic coordinates to numeric if needed
    capture destring location_lat location_long, replace
    
    * Report counts of non-missing sensitive data
    foreach var of varlist location_lat location_long par_email par_first_name par_last_name {
        count if !missing(`var')
        di as txt "  `var': `r(N)' non-missing values"
    }
    
    * Save sensitive data
    save "${sensitive_data}/ps_par_sensitive_only.dta", replace
    di as txt "Sensitive data saved to: ${sensitive_data}/ps_par_sensitive_only.dta"
restore

* Drop sensitive variables from main dataset
drop IPAddress LocationLatitude LocationLongitude RecipientEmail RecipientFirstName RecipientLastName
di as txt "Sensitive variables removed from main dataset."

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************

* Ensure processed data directory exists
capture confirm file "${processed_data}/PS_Parents/."
if _rc {
    mkdir "${processed_data}/PS_Parents"
}

* Compress and save anonymized dataset
compress
save "${processed_data}/PS_Parents/1_ps_parents.dta", replace

* Final report
di as txt "Anonymized data saved to: ${processed_data}/PS_Parents/1_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Anonymization"
di as txt "======================================================="

log close
set trace off
